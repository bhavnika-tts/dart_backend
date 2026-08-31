import 'package:dart_frog_backend/core/redis/redis_client.dart';
import 'package:test/test.dart';

void main() {
  group('RedisService (In-Memory Fallback & TTL)', () {
    late RedisService redis;

    setUp(() {
      redis = RedisService(url: 'redis://localhost:9999')
        ..clearMemoryCache();
    });

    test('get, set, and exists in memory cache', () async {
      await redis.set('test_key', 'hello_world');
      expect(await redis.exists('test_key'), isTrue);
      expect(await redis.get('test_key'), equals('hello_world'));
    });

    test('del removes key', () async {
      await redis.set('key_to_delete', 'value');
      await redis.del('key_to_delete');
      expect(await redis.exists('key_to_delete'), isFalse);
      expect(await redis.get('key_to_delete'), isNull);
    });

    test('TTL expiration in memory cache', () async {
      await redis.set(
        'expiring_key',
        'temp_value',
        ttl: const Duration(milliseconds: 50),
      );
      expect(await redis.get('expiring_key'), equals('temp_value'));

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(await redis.get('expiring_key'), isNull);
      expect(await redis.exists('expiring_key'), isFalse);
    });
  });
}
