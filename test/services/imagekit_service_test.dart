import 'package:dart_frog_backend/core/config/env.dart';
import 'package:dart_frog_backend/services/imagekit_service.dart';
import 'package:test/test.dart';

void main() {
  group('ImageKitService', () {
    late ImageKitService service;

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
        imageKitPrivateKey: 'private_test_key_123',
        imageKitUrlEndpoint: 'https://ik.imagekit.io/qa9gwdtkh',
      );
      service = ImageKitService(config: config);
    });

    test('getSignedUrl appends HMAC-SHA1 signature and expiry parameters', () {
      const rawUrl = 'https://ik.imagekit.io/qa9gwdtkh/products/car1.jpg';
      final signed = service.getSignedUrl(rawUrl, expiresIn: 3600);

      expect(signed, contains('ik-s='));
      expect(signed, contains('ik-t='));
      expect(signed, startsWith('https://ik.imagekit.io/qa9gwdtkh/products/car1.jpg?'));
    });

    test('stripSignature removes signature query params', () {
      const signedUrl = 'https://ik.imagekit.io/qa9gwdtkh/products/car1.jpg?ik-s=abcdef123456&ik-t=1700000000';
      final clean = service.stripSignature(signedUrl);

      expect(clean, equals('https://ik.imagekit.io/qa9gwdtkh/products/car1.jpg'));
    });

    test('signImageKitUrls recursively signs maps and lists', () {
      final payload = {
        'title': 'Honda City',
        'images': [
          'https://ik.imagekit.io/qa9gwdtkh/products/car1.jpg',
          'https://ik.imagekit.io/qa9gwdtkh/products/car2.jpg',
        ],
        'user': {
          'profile': 'https://ik.imagekit.io/qa9gwdtkh/users/u1.jpg',
          'name': 'Rahul',
        },
      };

      final signed = service.signImageKitUrls(payload) as Map<String, dynamic>;

      final images = signed['images'] as List;
      expect(images[0], contains('ik-s='));
      expect(images[1], contains('ik-s='));

      final user = signed['user'] as Map;
      expect(user['profile'], contains('ik-s='));
      expect(user['name'], equals('Rahul'));
    });
  });
}
