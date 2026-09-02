import 'dart:typed_data';
import '../core/security/crypto.dart';
import '../repositories/user_repository.dart';
import 'imagekit_service.dart';

/// Business logic service for User Profile, Permissions, Categories, and FCM tokens.
class UserService {
  UserService({
    UserRepository? userRepository,
    CryptoService? cryptoService,
    ImageKitService? imageKitService,
  })  : _userRepo = userRepository ?? UserRepository.instance,
        _crypto = cryptoService ?? CryptoService.instance,
        _imageKit = imageKitService ?? ImageKitService.instance;

  final UserRepository _userRepo;
  final CryptoService _crypto;
  final ImageKitService _imageKit;

  static UserService? _instance;
  static UserService get instance => _instance ??= UserService();

  /// Retrieves user profile by ID with decrypted/masked Aadhaar and signed URLs.
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final user = await _userRepo.findById(userId);
    if (user == null) {
      throw StateError('User not found');
    }

    final userJson = user.toJson();
    final rawAadhaar = user.aadharNumber.isNotEmpty ? user.aadharNumber.last : '';
    final decryptedAadhaar = _crypto.decryptAesGcm(rawAadhaar);
    final maskedAadhaar = CryptoService.maskAadhaar(decryptedAadhaar);
    userJson['aadharNumber'] = maskedAadhaar;

    final signedUser = _imageKit.signImageKitUrls(userJson) as Map<String, dynamic>;
    return {
      'success': true,
      'user': signedUser,
    };
  }

  /// Updates user profile fields and uploads new photos if supplied.
  Future<Map<String, dynamic>> updateUserProfile(
    String userId,
    Map<String, dynamic> updateFields, {
    Uint8List? profileBytes,
    String? profileName,
    Uint8List? aadhaar1Bytes,
    String? aadhaar1Name,
    Uint8List? aadhaar2Bytes,
    String? aadhaar2Name,
  }) async {
    final user = await _userRepo.findById(userId);
    if (user == null) {
      throw StateError('User not found');
    }

    if (user.verifiedByAdmin && user.updateCount >= 3) {
      throw StateError('Your profile has been updated more than 3 times. Please contact customer support.');
    }

    final sanitizedUpdates = <String, dynamic>{...updateFields};

    // Handle Aadhaar update protection if verified
    final newAadhaarStr = sanitizedUpdates['aadharNumber']?.toString().trim();
    if (newAadhaarStr != null) {
      if (newAadhaarStr.contains('X') || newAadhaarStr.contains('*')) {
        sanitizedUpdates.remove('aadharNumber');
      } else {
        if (user.verifiedByAdmin) {
          throw StateError('Verified Aadhaar details cannot be updated.');
        }
        final encrypted = _crypto.encryptAesGcm(newAadhaarStr);
        final list = List<String>.from(user.aadharNumber)..add(encrypted);
        sanitizedUpdates['aadharNumber'] = list;
      }
    }

    // Upload replacement profile photo
    if (profileBytes != null && profileBytes.isNotEmpty) {
      final path = await _imageKit.uploadBytes(
        bytes: profileBytes,
        fileName: profileName ?? 'profile_update.jpg',
        folder: '/profiles',
        prefix: 'profile',
      );
      final list = List<String>.from(user.profileImage)..add(path);
      sanitizedUpdates['profileImage'] = list;
    }

    // Upload replacement Aadhaar front photo
    if (aadhaar1Bytes != null && aadhaar1Bytes.isNotEmpty) {
      if (user.verifiedByAdmin) {
        throw StateError('Verified Aadhaar details cannot be updated.');
      }
      final path = await _imageKit.uploadBytes(
        bytes: aadhaar1Bytes,
        fileName: aadhaar1Name ?? 'aadhaar_front_update.jpg',
        folder: '/aadharcardImages',
        prefix: 'aadhaar_front',
      );
      final list = List<String>.from(user.aadhaarCardImage1)..add(path);
      sanitizedUpdates['aadhaarCardImage1'] = list;
    }

    // Upload replacement Aadhaar back photo
    if (aadhaar2Bytes != null && aadhaar2Bytes.isNotEmpty) {
      if (user.verifiedByAdmin) {
        throw StateError('Verified Aadhaar details cannot be updated.');
      }
      final path = await _imageKit.uploadBytes(
        bytes: aadhaar2Bytes,
        fileName: aadhaar2Name ?? 'aadhaar_back_update.jpg',
        folder: '/aadharcardImages',
        prefix: 'aadhaar_back',
      );
      final list = List<String>.from(user.aadhaarCardImage2)..add(path);
      sanitizedUpdates['aadhaarCardImage2'] = list;
    }

    if (user.verifiedByAdmin) {
      sanitizedUpdates['updateCount'] = user.updateCount + 1;
    }

    final updated = await _userRepo.update(userId, sanitizedUpdates);
    final userJson = updated!.toJson();

    final rawAadhaar = updated.aadharNumber.isNotEmpty ? updated.aadharNumber.last : '';
    final decryptedAadhaar = _crypto.decryptAesGcm(rawAadhaar);
    final maskedAadhaar = CryptoService.maskAadhaar(decryptedAadhaar);
    userJson['aadharNumber'] = maskedAadhaar;

    final signedUser = _imageKit.signImageKitUrls(userJson) as Map<String, dynamic>;

    return {
      'message': 'User updated successfully',
      'user': signedUser,
    };
  }

  /// Updates FCM Push Notification device token for user.
  Future<void> updateDeviceToken(String userId, String deviceToken) async {
    await _userRepo.update(userId, {'deviceToken': deviceToken.trim()});
  }

  /// Returns public registration user categories.
  Future<List<Map<String, dynamic>>> getPublicCategories() async {
    final list = await _userRepo.getPublicUserCategories();
    return list.map((c) => c.toJson()).toList();
  }

  /// Returns read/write category permissions for user.
  Future<Map<String, dynamic>> getUserPermissions(String userId) async {
    final perms = await _userRepo.getUserPermissions(userId);
    return {
      'success': true,
      'read': perms.read,
      'write': perms.write,
    };
  }

  /// Returns allowed productType IDs for listing creations.
  Future<Map<String, dynamic>> getAllowedProductTypes(String userId) async {
    final allowed = await _userRepo.getAllowedProductTypes(userId);
    return {
      'success': true,
      'allowedProductTypes': allowed,
    };
  }

  /// Returns active occupations list.
  Future<List<Map<String, dynamic>>> getOccupations() async {
    final list = await _userRepo.getOccupations();
    return list.map((o) => o.toJson()).toList();
  }
}
