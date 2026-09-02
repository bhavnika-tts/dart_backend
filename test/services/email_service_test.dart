import 'package:dart_frog_backend/core/config/env.dart';
import 'package:dart_frog_backend/services/email_service.dart';
import 'package:test/test.dart';

void main() {
  group('EmailService', () {
    late EmailService service;

    setUp(() {
      final config = EnvConfig(
        appName: 'Classicale',
        port: 3000,
        nodeEnv: 'test',
        mongoDbUrl: 'mongodb://localhost:27017/test',
        jwtSecret: 'test_secret',
        encryptionKeyHex: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        passwordPepperHex: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        redisUrl: 'redis://localhost:6379',
        uploadsRoot: './public',
        emailUser: 'support@classicale.com',
        emailPass: 'app_secret_pass',
      );
      service = EmailService(config: config);
    });

    test('buildPremiumTemplate renders branded responsive HTML with OTP card', () {
      final html = service.buildPremiumTemplate(
        subject: 'Your Verification Code',
        contentHtml: '<p>Please enter this code to verify your account.</p>',
        otpCode: 'A4B7C9',
      );

      expect(html, contains('Classicale'));
      expect(html, contains('A4B7C9'));
      expect(html, contains('This code is valid for 10 minutes.'));
      expect(html, contains('support@classicale.com'));
    });

    test('buildPremiumTemplate renders optional CTA button when provided', () {
      final html = service.buildPremiumTemplate(
        subject: 'Welcome to Classicale',
        contentHtml: '<p>Click below to get started.</p>',
        ctaText: 'Verify Account',
        ctaUrl: 'https://classicale.com/verify?token=123',
      );

      expect(html, contains('Verify Account'));
      expect(html, contains('https://classicale.com/verify?token=123'));
    });
  });
}
