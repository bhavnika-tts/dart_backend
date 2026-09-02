import 'dart:math';
import 'dart:typed_data';
import '../core/config/env.dart';
import '../core/security/crypto.dart';
import '../core/security/jwt_service.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import 'email_service.dart';
import 'imagekit_service.dart';
import 'otp_service.dart';

/// Business logic service for User Authentication, Sign-up, Passwords, and OTP.
class AuthService {
  AuthService({
    UserRepository? userRepository,
    CryptoService? cryptoService,
    JwtService? jwtService,
    OtpService? otpService,
    EmailService? emailService,
    ImageKitService? imageKitService,
    EnvConfig? config,
  })  : _userRepo = userRepository ?? UserRepository.instance,
        _crypto = cryptoService ?? CryptoService.instance,
        _jwt = jwtService ?? JwtService.instance,
        _otp = otpService ?? OtpService.instance,
        _email = emailService ?? EmailService.instance,
        _imageKit = imageKitService ?? ImageKitService.instance,
        _config = config ?? EnvConfig.instance;

  final UserRepository _userRepo;
  final CryptoService _crypto;
  final JwtService _jwt;
  final OtpService _otp;
  final EmailService _email;
  final ImageKitService _imageKit;
  final EnvConfig _config;

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService();

  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  String _generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Authenticates user and returns JWT token + full profile.
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String? userCategory,
  }) async {
    final user = await _userRepo.findByEmailOrPhone(identifier, userCategory: userCategory);
    if (user == null) {
      throw StateError('Invalid credentials or user not found.');
    }

    if (user.isBlocked) {
      throw StateError('Your account has been blocked. Please contact support.');
    }

    if (user.isDeleted) {
      throw StateError('Account does not exist.');
    }

    final isValidPassword = await _crypto.verifyPassword(password, user.password ?? '');
    if (!isValidPassword) {
      throw StateError('Invalid email/phone or password.');
    }

    final sessionToken = _generateSessionToken();
    await _userRepo.update(user.id!, {
      'sessionToken': sessionToken,
    });

    final token = _jwt.signToken(
      userId: user.id!,
      email: user.email ?? '',
      role: user.role,
      sessionToken: sessionToken,
      tokenVersion: user.tokenVersion,
    );

    // Populate category verification details
    var verificationType = 'none';
    var requiresVerification = false;
    if (user.userCategory != null) {
      final categoryDoc = await _userRepo.getCategoryByKey(user.userCategory!);
      if (categoryDoc != null) {
        verificationType = categoryDoc.verificationType;
        requiresVerification = categoryDoc.requiresAdminVerification;
      }
    }

    final userJson = user.toJson();
    final rawAadhaar = user.aadharNumber.isNotEmpty ? user.aadharNumber.last : '';
    final decryptedAadhaar = _crypto.decryptAesGcm(rawAadhaar);
    final maskedAadhaar = CryptoService.maskAadhaar(decryptedAadhaar);
    userJson['aadharNumber'] = maskedAadhaar;

    // Sign ImageKit URLs
    final signedUser = _imageKit.signImageKitUrls(userJson) as Map<String, dynamic>;
    signedUser['verificationType'] = verificationType;
    signedUser['requiresVerification'] = requiresVerification;

    return {
      'message': 'Login successful',
      'token': token,
      'user': signedUser,
    };
  }

  /// Registers a new user with personal details, addresses, and images.
  Future<Map<String, dynamic>> signup({
    required Map<String, dynamic> body,
    Uint8List? profileImageBytes,
    String? profileImageName,
    Uint8List? aadhaarFrontBytes,
    String? aadhaarFrontName,
    Uint8List? aadhaarBackBytes,
    String? aadhaarBackName,
  }) async {
    final email = body['email']?.toString().trim() ?? '';
    final userCategory = body['userCategory']?.toString().trim() ?? 'individual';
    final password = body['password']?.toString() ?? '';
    final phone = body['phone']?.toString().trim() ?? '';

    if (!_emailRegex.hasMatch(email)) {
      throw ArgumentError('Please enter a valid email address!');
    }

    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters long.');
    }

    final existing = await _userRepo.findByEmailAndCategory(email, userCategory);
    if (existing != null) {
      throw StateError('Already exists Email');
    }

    final hashedPassword = await _crypto.hashPassword(password);

    // Upload images to ImageKit
    var profilePath = '';
    var aadhaarFrontPath = '';
    var aadhaarBackPath = '';

    if (profileImageBytes != null && profileImageBytes.isNotEmpty) {
      profilePath = await _imageKit.uploadBytes(
        bytes: profileImageBytes,
        fileName: profileImageName ?? 'profile.jpg',
        folder: '/profiles',
        prefix: 'profile',
      );
    }

    if (aadhaarFrontBytes != null && aadhaarFrontBytes.isNotEmpty) {
      aadhaarFrontPath = await _imageKit.uploadBytes(
        bytes: aadhaarFrontBytes,
        fileName: aadhaarFrontName ?? 'aadhaar_front.jpg',
        folder: '/aadharcardImages',
        prefix: 'aadhaar_front',
      );
    }

    if (aadhaarBackBytes != null && aadhaarBackBytes.isNotEmpty) {
      aadhaarBackPath = await _imageKit.uploadBytes(
        bytes: aadhaarBackBytes,
        fileName: aadhaarBackName ?? 'aadhaar_back.jpg',
        folder: '/aadharcardImages',
        prefix: 'aadhaar_back',
      );
    }

    final rawAadhaarNumber = body['aadharNumber']?.toString().trim() ?? '';
    final encryptedAadhaar = rawAadhaarNumber.isNotEmpty
        ? _crypto.encryptAesGcm(rawAadhaarNumber)
        : '';

    final userNo = await _userRepo.getNextUserNo();

    final newUser = User(
      fName: [body['fName']?.toString().trim() ?? ''],
      mName: [body['mName']?.toString().trim() ?? ''],
      lName: [body['lName']?.toString().trim() ?? ''],
      phone: [phone],
      email: email,
      password: hashedPassword,
      gender: [body['gender']?.toString().trim() ?? ''],
      dob: [body['DOB']?.toString().trim() ?? ''],
      occupationId: body['occupationId']?.toString().trim(),
      country: [body['country']?.toString().trim() ?? 'India'],
      state: [body['state']?.toString().trim() ?? ''],
      city: [body['city']?.toString().trim() ?? ''],
      area: [body['area']?.toString().trim() ?? ''],
      street1: [body['street1']?.toString().trim() ?? ''],
      street2: [body['street2']?.toString().trim() ?? ''],
      pinCode: [body['pinCode']?.toString().trim() ?? ''],
      uIdNumber: [body['uIdNumber']?.toString().trim() ?? ''],
      referCode: body['referCode']?.toString().trim(),
      profileImage: profilePath.isNotEmpty ? [profilePath] : [],
      aadhaarCardImage1: aadhaarFrontPath.isNotEmpty ? [aadhaarFrontPath] : [],
      aadhaarCardImage2: aadhaarBackPath.isNotEmpty ? [aadhaarBackPath] : [],
      aadharNumber: encryptedAadhaar.isNotEmpty ? [encryptedAadhaar] : [],
      userCategory: userCategory,
      userNo: userNo,
      status: 'Active',
      isVerified: false,
    );

    final createdUser = await _userRepo.create(newUser);

    return {
      'success': true,
      'message': 'User registered successfully. Verification pending by admin.',
      'userId': createdUser.id,
    };
  }

  /// Verifies OTP for user login session.
  Future<Map<String, dynamic>> verifyOtpUser({
    required String userId,
    required String otp,
  }) async {
    final user = await _userRepo.findById(userId);
    if (user == null) {
      throw StateError('User not found');
    }

    final verification = await _otp.verifyOtp(
      identifier: userId,
      purpose: 'login_verify',
      otp: otp,
    );

    if (!verification.isValid) {
      throw StateError(verification.message);
    }

    final sessionToken = _generateSessionToken();
    await _userRepo.update(userId, {
      'isOtpVerified': true,
      'sessionToken': sessionToken,
    });

    final token = _jwt.signToken(
      userId: user.id!,
      email: user.email ?? '',
      role: user.role,
      sessionToken: sessionToken,
      tokenVersion: user.tokenVersion,
    );

    final userJson = user.toJson();
    final rawAadhaar = user.aadharNumber.isNotEmpty ? user.aadharNumber.last : '';
    final decryptedAadhaar = _crypto.decryptAesGcm(rawAadhaar);
    final maskedAadhaar = CryptoService.maskAadhaar(decryptedAadhaar);
    userJson['aadharNumber'] = maskedAadhaar;
    userJson['isOtpVerified'] = true;

    final signedUser = _imageKit.signImageKitUrls(userJson) as Map<String, dynamic>;

    return {
      'message': 'OTP verified successfully',
      'token': token,
      'user': signedUser,
    };
  }

  /// Sends a new alphanumeric OTP to user email.
  Future<void> resendOtp({required String userId}) async {
    final user = await _userRepo.findById(userId);
    if (user == null) {
      throw StateError('User not found');
    }

    final cooldown = await _otp.checkCooldown(identifier: userId, purpose: 'login_verify');
    if (cooldown.inCooldown) {
      throw StateError('Please wait ${cooldown.remainingSeconds} seconds before requesting a new OTP.');
    }

    final fName = user.fName.isNotEmpty ? user.fName.first : '';
    final lName = user.lName.isNotEmpty ? user.lName.first : '';
    final otp = _otp.generateAlphanumericOtp(fName: fName, lName: lName);

    await _otp.saveOtp(
      identifier: userId,
      purpose: 'login_verify',
      otp: otp,
      ttlSeconds: 180,
      cooldownSeconds: 45,
    );

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      await _email.sendEmail(
        toEmail: email,
        subject: '${_config.appName} Verification Code',
        text: 'Your verification OTP is: $otp\nThis code is valid for 3 minutes.',
        otpCode: otp,
      );
    }
  }

  /// Forgot password initiation: sends 6-digit OTP to user's registered email.
  Future<void> forgotPassword({
    required String email,
    required String category,
  }) async {
    final user = await _userRepo.findByEmailAndCategory(email, category);
    if (user == null) {
      throw StateError('User with this email does not exist');
    }

    final cooldown = await _otp.checkCooldown(identifier: email, purpose: 'forgot_password');
    if (cooldown.inCooldown) {
      throw StateError('Please wait ${cooldown.remainingSeconds} seconds before requesting a new OTP.');
    }

    final otp = _otp.generateNumericOtp(length: 6);

    await _otp.saveOtp(
      identifier: email,
      purpose: 'forgot_password',
      otp: otp,
      ttlSeconds: 600,
      cooldownSeconds: 60,
      maxAttempts: 5,
    );

    await _email.sendEmail(
      toEmail: user.email!,
      subject: 'Password Reset OTP',
      text: 'Your OTP for resetting the password is: $otp\nThis OTP is valid for 10 minutes.',
      otpCode: otp,
    );
  }

  /// Verifies recovery OTP and stores verified state in Redis for 10 minutes.
  Future<void> verifyForgotPasswordOtp({
    required String email,
    required String otp,
    required String category,
  }) async {
    final user = await _userRepo.findByEmailAndCategory(email, category);
    if (user == null) {
      throw StateError('User not found.');
    }

    final verification = await _otp.verifyOtp(
      identifier: email,
      purpose: 'forgot_password',
      otp: otp,
    );

    if (!verification.isValid) {
      throw StateError(verification.message);
    }

    await _otp.markOtpVerified(
      identifier: email,
      purpose: 'forgot_password',
      ttlSeconds: 600,
    );
  }

  /// Changes user password following verified OTP session.
  Future<void> changePassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
    required String category,
  }) async {
    if (newPassword != confirmPassword) {
      throw ArgumentError('Passwords do not match.');
    }

    final isVerified = await _otp.isOtpVerified(
      identifier: email,
      purpose: 'forgot_password',
    );

    if (!isVerified) {
      throw StateError('OTP verification required or session expired before resetting password.');
    }

    final user = await _userRepo.findByEmailAndCategory(email, category);
    if (user == null) {
      throw StateError('User not found.');
    }

    final hashedPassword = await _crypto.hashPassword(newPassword);

    await _userRepo.update(user.id!, {
      'password': hashedPassword,
      'tokenVersion': user.tokenVersion + 1,
      'passwordChangedAt': DateTime.now(),
    });

    await _otp.consumeOtpVerification(
      identifier: email,
      purpose: 'forgot_password',
    );
  }

  /// Verifies assigned PIN code for privileged user categories.
  Future<void> verifyPin({required String userId, required String pin}) async {
    final user = await _userRepo.findById(userId);
    if (user == null) {
      throw StateError('User not found');
    }

    if (user.assignedPins != null && user.assignedPins != pin.trim()) {
      throw StateError('Invalid PIN. Please enter the PIN assigned to you.');
    }

    await _userRepo.update(userId, {
      'isPinVerified': true,
    });
  }

  /// Invalidate user session on logout.
  Future<void> logout({required String userId}) async {
    await _userRepo.update(userId, {
      'sessionToken': null,
    });
  }
}
