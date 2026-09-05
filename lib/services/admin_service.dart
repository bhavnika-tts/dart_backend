import '../core/config/env.dart';
import '../core/security/crypto.dart';
import '../core/security/jwt_service.dart';
import '../models/admin.dart';
import '../models/admin_audit_log.dart';
import '../models/support_chat.dart';
import '../models/support_message.dart';
import '../repositories/admin_repository.dart';
import '../repositories/user_repository.dart';
import 'email_service.dart';
import 'imagekit_service.dart';
import 'socket_service.dart';

/// Business logic service for Admin authentication, RBAC, User verifications, Audits, and Support Tickets.
class AdminService {
  AdminService({
    AdminRepository? adminRepository,
    UserRepository? userRepository,
    CryptoService? cryptoService,
    JwtService? jwtService,
    EmailService? emailService,
    ImageKitService? imageKitService,
    SocketService? socketService,
    EnvConfig? config,
  })  : _adminRepo = adminRepository ?? AdminRepository.instance,
        _userRepo = userRepository ?? UserRepository.instance,
        _crypto = cryptoService ?? CryptoService.instance,
        _jwt = jwtService ?? JwtService.instance,
        _email = emailService ?? EmailService.instance,
        _imageKit = imageKitService ?? ImageKitService.instance,
        _socket = socketService ?? SocketService.instance,
        _config = config ?? EnvConfig.instance;

  final AdminRepository _adminRepo;
  final UserRepository _userRepo;
  final CryptoService _crypto;
  final JwtService _jwt;
  final EmailService _email;
  final ImageKitService _imageKit;
  final SocketService _socket;
  final EnvConfig _config;

  static AdminService? _instance;
  static AdminService get instance => _instance ??= AdminService();

  /// Authenticates admin or subadmin user.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final admin = await _adminRepo.findAdminByEmail(email);
    if (admin == null) {
      throw StateError('Invalid email or password');
    }

    final adminPassword = admin.password;
    if (adminPassword == null || adminPassword.isEmpty) {
      throw StateError('Password not set for account');
    }

    final isValid = await _crypto.verifyPassword(password, adminPassword);
    if (!isValid) {
      throw StateError('Invalid email or password');
    }

    final token = _jwt.signToken(
      userId: admin.id!,
      email: admin.email,
      role: admin.role,
      tokenVersion: admin.tokenVersion,
    );

    dynamic permissions;
    if (admin.role == 'subadmin') {
      final perms = await _adminRepo.getAdminPermissions(admin.id!);
      permissions = perms != null
          ? {
              ...perms.permissions.map((k, v) => MapEntry(k, v.toMap())),
              'assigned_access_codes': perms.assignedAccessCodes,
            }
          : null;
    }

    return {
      'token': token,
      'name': admin.username,
      'email': admin.email,
      'role': admin.role,
      'permissions': permissions,
    };
  }

  /// Creates a new subadmin account with optional RBAC module permissions.
  Future<Admin> createSubadmin({
    required String email,
    required String password,
    required String fName,
    required String lName,
    String? phone,
    Map<String, dynamic>? permissions,
    required String creatorAdminId,
  }) async {
    final existing = await _adminRepo.findAdminByEmail(email);
    if (existing != null) {
      throw StateError('Admin with this email already exists');
    }

    final hashedPassword = await _crypto.hashPassword(password);
    final subadmin = Admin(
      username: email.split('@').first,
      email: email.trim(),
      password: hashedPassword,
      fName: fName.trim(),
      lName: lName.trim(),
      phone: phone?.trim() ?? '',
      role: 'subadmin',
    );

    final created = await _adminRepo.createAdmin(subadmin);

    if (permissions != null && permissions.isNotEmpty) {
      await _adminRepo.updateAdminPermissions(created.id!, {'permissions': permissions});
    }

    await _adminRepo.logAudit(
      AdminAuditLog(
        adminId: creatorAdminId,
        action: 'CREATE_SUBADMIN',
        method: 'POST',
        endpoint: '/api/admin/subadmin/create',
        details: {'email': email, 'fName': fName, 'lName': lName, 'targetId': created.id},
      ),
    );

    return created;
  }

  /// Reviews user verification status and notifies user via SMTP email.
  Future<void> verifyUser({
    required String userId,
    required bool isApproved,
    String? rejectionReason,
    required String adminId,
  }) async {
    final user = await _userRepo.findById(userId);
    if (user == null) {
      throw StateError('User not found');
    }

    await _adminRepo.verifyUserByAdmin(
      userId,
      isApproved: isApproved,
      rejectionReason: rejectionReason,
    );

    await _adminRepo.logAudit(
      AdminAuditLog(
        adminId: adminId,
        action: isApproved ? 'APPROVE_USER' : 'REJECT_USER',
        method: 'POST',
        endpoint: '/api/admin/verify_by_admin',
        details: {'targetId': userId, 'isApproved': isApproved, if (rejectionReason != null) 'reason': rejectionReason},
      ),
    );

    _socket.emitToUser(userId, 'user_status_change', {
      'status': isApproved ? 'Active' : 'Rejected',
      'verified_by_admin': isApproved,
    });

    // Send notification email
    final userEmail = user.email;
    if (userEmail != null && userEmail.isNotEmpty) {
      final subject = isApproved
          ? 'Account Verified - Welcome to ${_config.appName}'
          : 'Account Verification Update - ${_config.appName}';

      final content = isApproved
          ? '<p>Congratulations! Your account has been verified by admin. You can now create listings and access all features.</p>'
          : '<p>Your account verification could not be completed at this time.</p><p><strong>Reason:</strong> ${rejectionReason ?? 'Incomplete or unreadable documents'}</p><p>Please update your details and submit again.</p>';

      await _email.sendEmail(
        toEmail: userEmail,
        subject: subject,
        html: _email.buildPremiumTemplate(subject: subject, contentHtml: content),
      );
    }
  }

  /// Toggles user block status.
  Future<void> toggleUserBlock(String userId, {required bool isBlocked, required String adminId}) async {
    await _adminRepo.toggleUserBlock(userId, isBlocked: isBlocked);
    await _adminRepo.logAudit(
      AdminAuditLog(
        adminId: adminId,
        action: isBlocked ? 'BLOCK_USER' : 'UNBLOCK_USER',
        method: 'POST',
        endpoint: '/api/admin/user_block_unblock',
        details: {'targetId': userId, 'isBlocked': isBlocked},
      ),
    );

    _socket.emitToUser(userId, 'user_status_change', {
      'isBlocked': isBlocked,
    });
  }

  /// Retrieves all users with masked Aadhaar and signed URLs.
  Future<List<Map<String, dynamic>>> getAllUsers({int limit = 100, int page = 1, String? category}) async {
    final users = await _adminRepo.getAllUsers(limit: limit, page: page, category: category);
    final list = users.map((u) {
      final json = u.toJson();
      final rawAadhaar = u.aadharNumber.isNotEmpty ? u.aadharNumber.last : '';
      final decrypted = _crypto.decryptAesGcm(rawAadhaar);
      json['aadharNumber'] = CryptoService.maskAadhaar(decrypted);
      return json;
    }).toList();

    return List<Map<String, dynamic>>.from(_imageKit.signImageKitUrls(list) as List);
  }

  // ── Support Chat System ────────────────────────────────────────────────────

  Future<SupportChat> createOrGetSupportChat(String userId) async {
    return _adminRepo.findOrCreateSupportChat(userId);
  }

  Future<Map<String, dynamic>> sendSupportMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String text,
    String? mediaUrl,
  }) async {
    final msg = SupportMessage(
      chatId: chatId,
      senderId: senderRole == 'user' ? senderId : null,
      adminSenderId: senderRole == 'admin' ? senderId : null,
      senderRole: senderRole,
      content: text,
      type: mediaUrl != null && mediaUrl.isNotEmpty ? 'image' : 'text',
      createdAt: DateTime.now(),
    );

    final created = await _adminRepo.createSupportMessage(msg);
    final msgJson = _imageKit.signImageKitUrls(created.toJson()) as Map<String, dynamic>;

    _socket
      ..emitToRoom(chatId, 'support_message', msgJson)
      ..emitToAdmin('support_message', msgJson);

    return {
      'success': true,
      'message': 'Support message sent',
      'data': msgJson,
    };
  }

  Future<List<Map<String, dynamic>>> getSupportMessages(String chatId) async {
    final list = await _adminRepo.getSupportMessages(chatId);
    final raw = list.map((m) => m.toJson()).toList();
    return List<Map<String, dynamic>>.from(_imageKit.signImageKitUrls(raw) as List);
  }

  Future<List<Map<String, dynamic>>> getAllSupportChats({String? status}) async {
    final list = await _adminRepo.getAllSupportChats(status: status);
    return list.map((c) => c.toJson()).toList();
  }

  Future<void> updateSupportTicketStatus(String chatId, String status, {required String adminId}) async {
    await _adminRepo.updateSupportTicketStatus(chatId, status);
    await _adminRepo.logAudit(
      AdminAuditLog(
        adminId: adminId,
        action: 'UPDATE_SUPPORT_STATUS',
        method: 'PUT',
        endpoint: '/api/support/update-status',
        details: {'chatId': chatId, 'status': status},
      ),
    );

    _socket.emitToRoom(chatId, 'support_ticket_status_change', {
      'chatId': chatId,
      'status': status,
    });
  }

  Future<void> assignSupportTicket(String chatId, String assignedAdminId, {required String adminId}) async {
    await _adminRepo.assignSupportTicket(chatId, assignedAdminId);
    await _adminRepo.logAudit(
      AdminAuditLog(
        adminId: adminId,
        action: 'ASSIGN_SUPPORT_TICKET',
        method: 'PUT',
        endpoint: '/api/support/assign-ticket',
        details: {'chatId': chatId, 'assignedAdminId': assignedAdminId},
      ),
    );

    _socket.emitToRoom(chatId, 'ticket_assigned', {
      'chatId': chatId,
      'assignedAdminId': assignedAdminId,
    });
  }
}
