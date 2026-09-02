import 'dart:math';
import '../core/redis/redis_client.dart';

/// Service managing numeric and alphanumeric OTP generation, verification, cooldowns, and Redis TTL storage.
class OtpService {
  OtpService({RedisService? redisService})
      : _redis = redisService ?? RedisService.instance;

  final RedisService _redis;

  static OtpService? _instance;
  static OtpService get instance => _instance ??= OtpService();

  final _random = Random.secure();

  /// Generates a 6-digit numeric OTP that doesn't start with 0.
  String generateNumericOtp({int length = 6}) {
    final min = pow(10, length - 1).toInt();
    final max = pow(10, length).toInt() - 1;
    return (min + _random.nextInt(max - min + 1)).toString();
  }

  /// Generates a 6-character alphanumeric OTP derived from first/last name.
  String generateAlphanumericOtp({String fName = '', String lName = ''}) {
    final prefix = ((fName.length >= 2 ? fName.substring(0, 2) : fName) +
            (lName.length >= 2 ? lName.substring(0, 2) : lName))
        .toUpperCase();
    final letters = prefix.isNotEmpty ? prefix : 'AB';
    const digits = '0123456789';
    const allChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    final chars = <String>[
      letters[_random.nextInt(letters.length)],
      digits[_random.nextInt(digits.length)],
    ];

    for (var i = 0; i < 4; i++) {
      chars.add(allChars[_random.nextInt(allChars.length)]);
    }

    chars.shuffle(_random);
    return chars.join();
  }

  /// Checks if resend cooldown is active.
  Future<({bool inCooldown, int remainingSeconds})> checkCooldown({
    required String identifier,
    String purpose = 'auth',
  }) async {
    final norm = identifier.toLowerCase().trim();
    final cooldownKey = 'otp_cooldown:$purpose:$norm';
    final remaining = await _redis.ttl(cooldownKey);

    if (remaining > 0) {
      return (inCooldown: true, remainingSeconds: remaining);
    }
    return (inCooldown: false, remainingSeconds: 0);
  }

  /// Saves an OTP to Redis with TTL, attempt tracking, and cooldown.
  Future<void> saveOtp({
    required String identifier,
    String purpose = 'auth',
    required String otp,
    int ttlSeconds = 300,
    int cooldownSeconds = 60,
    int maxAttempts = 5,
  }) async {
    final norm = identifier.toLowerCase().trim();
    final otpKey = 'otp:$purpose:$norm';
    final cooldownKey = 'otp_cooldown:$purpose:$norm';

    final payload = {
      'otp': otp.trim(),
      'attempts': 0,
      'maxAttempts': maxAttempts,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _redis.setExJson(otpKey, payload, ttlSeconds);

    if (cooldownSeconds > 0) {
      await _redis.setEx(cooldownKey, '1', cooldownSeconds);
    }
  }

  /// Verifies an OTP against Redis, tracks attempts, and consumes on success.
  Future<({bool isValid, String message, int remainingAttempts})> verifyOtp({
    required String identifier,
    String purpose = 'auth',
    required String otp,
  }) async {
    final norm = identifier.toLowerCase().trim();
    final otpKey = 'otp:$purpose:$norm';

    final record = await _redis.getJson<Map<String, dynamic>>(otpKey);
    if (record == null) {
      return (
        isValid: false,
        message: 'OTP has expired or is invalid. Please request a new one.',
        remainingAttempts: 0,
      );
    }

    final savedOtp = record['otp']?.toString().trim() ?? '';
    final suppliedOtp = otp.trim();

    if (savedOtp != suppliedOtp) {
      final attempts = (record['attempts'] as int? ?? 0) + 1;
      final maxAttempts = record['maxAttempts'] as int? ?? 5;
      final remaining = max(0, maxAttempts - attempts);

      if (remaining == 0) {
        await _redis.del(otpKey);
        return (
          isValid: false,
          message: 'Maximum OTP attempts exceeded. Please request a new OTP.',
          remainingAttempts: 0,
        );
      }

      final ttl = await _redis.ttl(otpKey);
      if (ttl > 0) {
        record['attempts'] = attempts;
        await _redis.setExJson(otpKey, record, ttl);
      }

      return (
        isValid: false,
        message: 'Invalid OTP. $remaining attempt${remaining == 1 ? '' : 's'} remaining.',
        remainingAttempts: remaining,
      );
    }

    // Success -> consume OTP
    await _redis.del(otpKey);
    return (
      isValid: true,
      message: 'OTP verified successfully.',
      remainingAttempts: 5,
    );
  }

  /// Marks an identifier as verified in Redis for subsequent password resets.
  Future<void> markOtpVerified({
    required String identifier,
    String purpose = 'forgot_password',
    int ttlSeconds = 600,
  }) async {
    final norm = identifier.toLowerCase().trim();
    final verifiedKey = 'otp_verified:$purpose:$norm';
    await _redis.setEx(verifiedKey, 'true', ttlSeconds);
  }

  /// Checks if an identifier has completed OTP verification.
  Future<bool> isOtpVerified({
    required String identifier,
    String purpose = 'forgot_password',
  }) async {
    final norm = identifier.toLowerCase().trim();
    final verifiedKey = 'otp_verified:$purpose:$norm';
    final val = await _redis.get(verifiedKey);
    return val == 'true';
  }

  /// Consumes verified token after password has been changed.
  Future<void> consumeOtpVerification({
    required String identifier,
    String purpose = 'forgot_password',
  }) async {
    final norm = identifier.toLowerCase().trim();
    final verifiedKey = 'otp_verified:$purpose:$norm';
    await _redis.del(verifiedKey);
  }
}
