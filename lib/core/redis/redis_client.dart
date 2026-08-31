import 'dart:async';
import 'package:dart_frog_backend/core/config/env.dart';
import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';
import 'package:resp_client/resp_server.dart';

/// Redis client service supporting distributed caching, TTL expiration,
/// and automatic in-memory fallback if Redis is unreachable.
class RedisService {
  RedisService({String? url}) : _url = url ?? EnvConfig.instance.redisUrl;

  final String _url;
  RespCommandsTier2? _client;
  bool _isConnected = false;

  // In-memory fallback cache with TTL expiration
  final Map<String, _CacheEntry> _memoryCache = {};

  bool get isConnected => _isConnected;

  /// Connect to Redis instance
  Future<void> connect() async {
    try {
      final uri = Uri.parse(_url);
      final host = uri.host.isNotEmpty ? uri.host : 'localhost';
      final port = uri.port != 0 ? uri.port : 6379;

      final connection = await connectSocket(
        host,
        port: port,
        timeout: const Duration(seconds: 3),
      );
      final respClient = RespClient(connection);
      _client = RespCommandsTier2(respClient);
      _isConnected = true;
      print('✅ Redis Client Connected ($host:$port)');
    } catch (e) {
      _isConnected = false;
      print('⚠️ Could not connect to Redis at startup (falling back to in-memory store): $e');
    }
  }

  /// Get value by key
  Future<String?> get(String key) async {
    if (_isConnected && _client != null) {
      try {
        final result = await _client!.get(key);
        return result?.toString();
      } catch (_) {
        // Fall through to in-memory on error
      }
    }

    final entry = _memoryCache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }
    return entry.value;
  }

  /// Set value with optional TTL duration
  Future<void> set(String key, String value, {Duration? ttl}) async {
    if (_isConnected && _client != null) {
      try {
        if (ttl != null) {
          await _client!.set(key, value, expire: ExpireMode.time(ttl));
        } else {
          await _client!.set(key, value);
        }
        return;
      } catch (_) {
        // Fall through to in-memory on error
      }
    }

    _memoryCache[key] = _CacheEntry(
      value: value,
      expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
    );
  }

  /// Delete key
  Future<void> del(String key) async {
    if (_isConnected && _client != null) {
      try {
        await _client!.del([key]);
      } catch (_) {}
    }
    _memoryCache.remove(key);
  }

  /// Check if key exists
  Future<bool> exists(String key) async {
    if (_isConnected && _client != null) {
      try {
        final count = await _client!.exists([key]);
        return count > 0;
      } catch (_) {}
    }
    final entry = _memoryCache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _memoryCache.remove(key);
      return false;
    }
    return true;
  }

  /// Flush in-memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
  }

  static RedisService? _instance;
  static RedisService get instance => _instance ??= RedisService();
}

class _CacheEntry {
  _CacheEntry({required this.value, this.expiresAt});

  final String value;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
