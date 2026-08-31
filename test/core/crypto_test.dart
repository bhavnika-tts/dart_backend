import 'package:dart_frog_backend/core/security/crypto.dart';
import 'package:test/test.dart';

void main() {
  group('CryptoService', () {
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoService(
        encryptionKeyHex:
            '7e7cab408c1264034f3fbb6bec9ef8dc01fa8a53832e45d97823bee9fbad0c96',
        passwordPepperHex:
            'fc4364b86ed45734c748b08fe40673d18d51f9d889903b4a4dbdff1f278b8d65',
      );
    });

    test('AES-256-GCM encryption & decryption round-trip', () {
      const sensitiveData = '987654321098';
      final encrypted = cryptoService.encrypt(sensitiveData);

      expect(encrypted, isNotEmpty);
      expect(encrypted.split(':').length, equals(3));

      final decrypted = cryptoService.decrypt(encrypted);
      expect(decrypted, equals(sensitiveData));
    });

    test('AES-256-GCM decrypt returns legacy plaintext as-is', () {
      const plaintext = 'unencrypted_legacy_data';
      final result = cryptoService.decrypt(plaintext);
      expect(result, equals(plaintext));
    });

    test('Argon2id password hashing and verification', () async {
      const password = 'mySecretPassword!2026';
      final hash = await cryptoService.hashPassword(password);

      expect(hash, startsWith(r'$argon2id$v=19$m=65536,t=3,p=4$'));

      final isMatch = await cryptoService.verifyPassword(password, hash);
      expect(isMatch, isTrue);

      final isWrongMatch =
          await cryptoService.verifyPassword('wrongPassword', hash);
      expect(isWrongMatch, isFalse);
    });

    test('Aadhaar masking handles various formats correctly', () {
      expect(
        CryptoService.maskAadhaar('123456789012'),
        equals('XXXX-XXXX-9012'),
      );
      expect(
        CryptoService.maskAadhaar('1234 5678 9012'),
        equals('XXXX-XXXX-9012'),
      );
      expect(
        CryptoService.maskAadhaar('1234-5678-9012'),
        equals('XXXX-XXXX-9012'),
      );
      expect(CryptoService.maskAadhaar('12'), equals('XXXX-XXXX-****'));
      expect(CryptoService.maskAadhaar(''), equals(''));
    });
  });
}
