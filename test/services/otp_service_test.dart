import 'package:dart_frog_backend/core/redis/redis_client.dart';
import 'package:dart_frog_backend/services/otp_service.dart';
import 'package:test/test.dart';

void main() {
  group('OtpService', () {
    late OtpService otpService;

    setUp(() {
      otpService = OtpService(redisService: RedisService.instance);
    });

    test('generateNumericOtp produces 6-digit numeric string not starting with 0', () {
      for (var i = 0; i < 50; i++) {
        final otp = otpService.generateNumericOtp(length: 6);
        expect(otp.length, equals(6));
        expect(RegExp(r'^[1-9]\d{5}$').hasMatch(otp), isTrue);
      }
    });

    test('generateAlphanumericOtp produces 6-character alphanumeric string containing letters and digits', () {
      for (var i = 0; i < 50; i++) {
        final otp = otpService.generateAlphanumericOtp(fName: 'Rahul', lName: 'Sharma');
        expect(otp.length, equals(6));
        expect(RegExp(r'^[A-Z0-9]{6}$').hasMatch(otp), isTrue);
      }
    });

    test('saveOtp, verifyOtp, and cooldown flow in fallback in-memory mode', () async {
      const email = 'test_user@example.com';
      final otp = otpService.generateNumericOtp();

      await otpService.saveOtp(
        identifier: email,
        purpose: 'forgot_password',
        otp: otp,
        ttlSeconds: 60,
        cooldownSeconds: 30,
      );

      final cooldown = await otpService.checkCooldown(
        identifier: email,
        purpose: 'forgot_password',
      );
      expect(cooldown.inCooldown, isTrue);

      final wrongVerify = await otpService.verifyOtp(
        identifier: email,
        purpose: 'forgot_password',
        otp: '000000',
      );
      expect(wrongVerify.isValid, isFalse);

      final correctVerify = await otpService.verifyOtp(
        identifier: email,
        purpose: 'forgot_password',
        otp: otp,
      );
      expect(correctVerify.isValid, isTrue);
    });
  });
}
