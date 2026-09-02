import 'package:mongo_dart/mongo_dart.dart';
import '../core/db/mongo_client.dart';
import '../models/admin.dart';
import '../models/admin_audit_log.dart';
import '../models/admin_permission.dart';
import '../models/chat_report.dart';
import '../models/model_helpers.dart';
import '../models/product_report.dart';
import '../models/rating.dart';
import '../models/support_chat.dart';
import '../models/support_message.dart';
import '../models/user.dart';

/// Repository for Admin, Subadmin, RBAC, Reports, Auditing, and Support.
class AdminRepository {
  AdminRepository({MongoClient? mongoClient})
      : _mongoClient = mongoClient ?? MongoClient.instance;

  final MongoClient _mongoClient;

  static AdminRepository? _instance;
  static AdminRepository get instance => _instance ??= AdminRepository();

  DbCollection get _adminsCollection => _mongoClient.collection('admins');
  DbCollection get _permissionsCollection => _mongoClient.collection('admin_permissions');
  DbCollection get _auditLogsCollection => _mongoClient.collection('admin_audit_logs');
  DbCollection get _usersCollection => _mongoClient.collection('users');
  DbCollection get _productReportsCollection => _mongoClient.collection('report_products');
  DbCollection get _chatReportsCollection => _mongoClient.collection('chat_reports');
  DbCollection get _ratingsCollection => _mongoClient.collection('ratings');
  DbCollection get _supportChatsCollection => _mongoClient.collection('support_chats');
  DbCollection get _supportMessagesCollection => _mongoClient.collection('support_messages');

  // ── Admin & Subadmin Queries ───────────────────────────────────────────────

  Future<Admin?> findAdminByEmail(String email) async {
    final doc = await _adminsCollection.findOne(where.eq('email', email.trim()));
    if (doc == null) return null;
    return Admin.fromBson(doc);
  }

  Future<Admin?> findAdminById(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;
    final doc = await _adminsCollection.findOne(where.id(objId));
    if (doc == null) return null;
    return Admin.fromBson(doc);
  }

  Future<List<Admin>> getAllSubadmins() async {
    final stream = _adminsCollection.find(where.ne('role', 'superadmin'));
    final list = await stream.toList();
    return list.map(Admin.fromBson).toList();
  }

  Future<Admin> createAdmin(Admin admin) async {
    final doc = admin.toBson();
    doc['createdAt'] = DateTime.now();
    doc['updatedAt'] = DateTime.now();
    final result = await _adminsCollection.insertOne(doc);
    return Admin.fromBson({...doc, '_id': result.id});
  }

  Future<Admin?> updateAdmin(String id, Map<String, dynamic> data) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;

    final sanitized = <String, dynamic>{...data}
      ..remove('_id')
      ..['updatedAt'] = DateTime.now();

    for (final entry in sanitized.entries) {
      await _adminsCollection.updateOne(
        where.id(objId),
        modify.set(entry.key, entry.value),
      );
    }

    return findAdminById(id);
  }

  Future<bool> deleteAdmin(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return false;
    final res = await _adminsCollection.deleteOne(where.id(objId));
    return res.nRemoved > 0;
  }

  // ── Admin Permissions ──────────────────────────────────────────────────────

  Future<AdminPermission?> getAdminPermissions(String adminId) async {
    final objId = ModelHelpers.toObjectId(adminId);
    if (objId == null) return null;
    final doc = await _permissionsCollection.findOne(where.eq('adminId', objId));
    if (doc == null) return null;
    return AdminPermission.fromBson(doc);
  }

  Future<AdminPermission> updateAdminPermissions(String adminId, Map<String, dynamic> perms) async {
    final objId = ModelHelpers.toObjectId(adminId);
    if (objId == null) throw ArgumentError('Invalid admin ID');

    final existing = await _permissionsCollection.findOne(where.eq('adminId', objId));
    final rawPerms = perms['permissions'] ?? perms['modules'] ?? perms;

    if (existing == null) {
      final newDoc = <String, dynamic>{
        'adminId': objId,
        'permissions': rawPerms,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      final res = await _permissionsCollection.insertOne(newDoc);
      return AdminPermission.fromBson({...newDoc, '_id': res.id});
    }

    await _permissionsCollection.updateOne(
      where.eq('adminId', objId),
      modify.set('permissions', rawPerms).set('updatedAt', DateTime.now()),
    );

    final updated = await _permissionsCollection.findOne(where.eq('adminId', objId));
    return AdminPermission.fromBson(updated!);
  }

  // ── User Verification & Management ─────────────────────────────────────────

  Future<List<User>> getAllUsers({int limit = 100, int page = 1, String? category}) async {
    var selector = where.eq('isDeleted', false);
    if (category != null && category.isNotEmpty) {
      selector = selector.eq('userCategory', category);
    }
    selector = selector.sortBy('createdAt', descending: true);
    final skip = (page - 1) * limit;
    final stream = _usersCollection.find(selector.skip(skip).limit(limit));
    final list = await stream.toList();
    return list.map(User.fromBson).toList();
  }

  Future<bool> verifyUserByAdmin(String userId, {required bool isApproved, String? rejectionReason}) async {
    final objId = ModelHelpers.toObjectId(userId);
    if (objId == null) return false;

    final result = await _usersCollection.updateOne(
      where.id(objId),
      modify.set('verified_by_admin', isApproved)
          .set('isVerified', isApproved)
          .set('status', isApproved ? 'Active' : 'Rejected')
          .set('aadhaarRejectionReason', rejectionReason ?? '')
          .set('updatedAt', DateTime.now()),
    );

    return result.nModified > 0;
  }

  Future<bool> toggleUserBlock(String userId, {required bool isBlocked}) async {
    final objId = ModelHelpers.toObjectId(userId);
    if (objId == null) return false;

    final result = await _usersCollection.updateOne(
      where.id(objId),
      modify.set('isBlocked', isBlocked).set('updatedAt', DateTime.now()),
    );
    return result.nModified > 0;
  }

  Future<bool> toggleUserActive(String userId, {required bool isActive}) async {
    final objId = ModelHelpers.toObjectId(userId);
    if (objId == null) return false;

    final result = await _usersCollection.updateOne(
      where.id(objId),
      modify.set('isActive', isActive).set('updatedAt', DateTime.now()),
    );
    return result.nModified > 0;
  }

  // ── Reports & Feedback ─────────────────────────────────────────────────────

  Future<List<ProductReport>> getAllProductReports({int limit = 50}) async {
    final stream = _productReportsCollection.find(where.sortBy('createdAt', descending: true).limit(limit));
    final list = await stream.toList();
    return list.map(ProductReport.fromBson).toList();
  }

  Future<ProductReport?> getProductReportById(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;
    final doc = await _productReportsCollection.findOne(where.id(objId));
    if (doc == null) return null;
    return ProductReport.fromBson(doc);
  }

  Future<bool> updateProductReportStatus(String reportId, String status) async {
    final objId = ModelHelpers.toObjectId(reportId);
    if (objId == null) return false;

    final res = await _productReportsCollection.updateOne(
      where.id(objId),
      modify.set('status', status).set('updatedAt', DateTime.now()),
    );
    return res.nModified > 0;
  }

  Future<List<ChatReport>> getAllChatReports({int limit = 50}) async {
    final stream = _chatReportsCollection.find(where.sortBy('createdAt', descending: true).limit(limit));
    final list = await stream.toList();
    return list.map(ChatReport.fromBson).toList();
  }

  Future<ChatReport?> getChatReportById(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;
    final doc = await _chatReportsCollection.findOne(where.id(objId));
    if (doc == null) return null;
    return ChatReport.fromBson(doc);
  }

  Future<bool> updateChatReportStatus(String reportId, String status) async {
    final objId = ModelHelpers.toObjectId(reportId);
    if (objId == null) return false;

    final res = await _chatReportsCollection.updateOne(
      where.id(objId),
      modify.set('status', status).set('updatedAt', DateTime.now()),
    );
    return res.nModified > 0;
  }

  Future<List<RatingModel>> getAllRatings({int limit = 100}) async {
    final stream = _ratingsCollection.find(where.sortBy('createdAt', descending: true).limit(limit));
    final list = await stream.toList();
    return list.map(RatingModel.fromBson).toList();
  }

  // ── Audit Logging ──────────────────────────────────────────────────────────

  Future<void> logAudit(AdminAuditLog auditLog) async {
    final doc = auditLog.toBson();
    doc['createdAt'] = DateTime.now();
    await _auditLogsCollection.insertOne(doc);
  }

  Future<List<AdminAuditLog>> getAuditLogs({int limit = 100, int page = 1}) async {
    final skip = (page - 1) * limit;
    final stream = _auditLogsCollection.find(where.sortBy('createdAt', descending: true).skip(skip).limit(limit));
    final list = await stream.toList();
    return list.map(AdminAuditLog.fromBson).toList();
  }

  // ── Support Tickets ────────────────────────────────────────────────────────

  Future<SupportChat> findOrCreateSupportChat(String userId) async {
    final userObj = ModelHelpers.toObjectId(userId);
    if (userObj == null) throw ArgumentError('Invalid user ID');

    final existing = await _supportChatsCollection.findOne(where.eq('userId', userObj));
    if (existing != null) {
      return SupportChat.fromBson(existing);
    }

    final newChat = SupportChat(
      userId: userId,
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final doc = newChat.toBson();
    final res = await _supportChatsCollection.insertOne(doc);
    return SupportChat.fromBson({...doc, '_id': res.id});
  }

  Future<List<SupportChat>> getAllSupportChats({String? status, int limit = 50}) async {
    var selector = where.sortBy('updatedAt', descending: true).limit(limit);
    if (status != null && status.isNotEmpty) {
      selector = where.eq('status', status).sortBy('updatedAt', descending: true).limit(limit);
    }
    final stream = _supportChatsCollection.find(selector);
    final list = await stream.toList();
    return list.map(SupportChat.fromBson).toList();
  }

  Future<SupportMessage> createSupportMessage(SupportMessage msg) async {
    final doc = msg.toBson();
    doc['createdAt'] = DateTime.now();
    doc['updatedAt'] = DateTime.now();
    final res = await _supportMessagesCollection.insertOne(doc);

    // Touch support chat
    final chatObj = ModelHelpers.toObjectId(msg.chatId);
    if (chatObj != null) {
      await _supportChatsCollection.updateOne(
        where.id(chatObj),
        modify.set('updatedAt', DateTime.now()),
      );
    }

    return SupportMessage.fromBson({...doc, '_id': res.id});
  }

  Future<List<SupportMessage>> getSupportMessages(String chatId) async {
    final chatObj = ModelHelpers.toObjectId(chatId);
    if (chatObj == null) return [];

    final stream = _supportMessagesCollection.find(
      where.eq('chatId', chatObj).sortBy('createdAt', descending: false),
    );
    final list = await stream.toList();
    return list.map(SupportMessage.fromBson).toList();
  }

  Future<bool> updateSupportTicketStatus(String chatId, String status) async {
    final chatObj = ModelHelpers.toObjectId(chatId);
    if (chatObj == null) return false;

    final res = await _supportChatsCollection.updateOne(
      where.id(chatObj),
      modify.set('status', status).set('updatedAt', DateTime.now()),
    );
    return res.nModified > 0;
  }

  Future<bool> assignSupportTicket(String chatId, String assignedAdminId) async {
    final chatObj = ModelHelpers.toObjectId(chatId);
    final adminObj = ModelHelpers.toObjectId(assignedAdminId);
    if (chatObj == null || adminObj == null) return false;

    final res = await _supportChatsCollection.updateOne(
      where.id(chatObj),
      modify.set('assignedAdminId', adminObj).set('updatedAt', DateTime.now()),
    );
    return res.nModified > 0;
  }
}
