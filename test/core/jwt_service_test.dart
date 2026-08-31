import 'package:dart_frog_backend/core/errors/app_error.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:test/test.dart';

void main() {
  group('JwtService', () {
    late JwtService jwtService;

    setUp(() {
      jwtService = JwtService(secret: 'test_jwt_secret_key_123456');
    });

    test('sign and verify valid user JWT token', () {
      final token = jwtService.sign(
        id: '65a8e1234567890abcdef123',
        role: 'user',
        extraClaims: {
          'phone': '9876543210',
          'userNo': 'U1001',
        },
      );

      expect(token, isNotEmpty);

      final auth = jwtService.verify(token);
      expect(auth.id, equals('65a8e1234567890abcdef123'));
      expect(auth.role, equals('user'));
      expect(auth.phone, equals('9876543210'));
      expect(auth.userNo, equals('U1001'));
      expect(auth.isUser, isTrue);
      expect(auth.isAdmin, isFalse);
    });

    test('sign and verify admin JWT token with Bearer prefix', () {
      final token = jwtService.sign(
        id: '65a8e9999999999abcdef999',
        role: 'superadmin',
        extraClaims: {'tokenVersion': 1},
      );

      final auth = jwtService.verify('Bearer $token');
      expect(auth.id, equals('65a8e9999999999abcdef999'));
      expect(auth.role, equals('superadmin'));
      expect(auth.tokenVersion, equals(1));
      expect(auth.isAdmin, isTrue);
      expect(auth.isSuperAdmin, isTrue);
    });

    test('throws AppError for invalid or tampered token', () {
      expect(
        () => jwtService.verify('invalid.token.here'),
        throwsA(isA<AppError>()),
      );
    });

    test('throws AppError for expired token', () {
      final expiredToken = jwtService.sign(
        id: '65a8e1234567890abcdef123',
        role: 'user',
        expiresIn: const Duration(milliseconds: -100),
      );

      expect(
        () => jwtService.verify(expiredToken),
        throwsA(
          predicate<AppError>(
            (e) => e.statusCode == 401 && e.code == 'TOKEN_EXPIRED',
          ),
        ),
      );
    });
  });
}
