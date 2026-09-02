import 'dart:async';
import 'dart:convert';
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

  /// Get JSON parsed value
  Future<T?> getJson<T>(String key) async {
    final raw = await get(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as T;
    } catch (_) {
      return null;
    }
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

  /// Set value with TTL in seconds
  Future<void> setEx(String key, String value, int seconds) async {
    await set(key, value, ttl: Duration(seconds: seconds));
  }

  /// Set JSON value with TTL in seconds
  Future<void> setExJson(String key, Object value, int seconds) async {
    await set(key, jsonEncode(value), ttl: Duration(seconds: seconds));
  }

  /// Returns remaining TTL in seconds (or 0 if expired/not found)
  Future<int> ttl(String key) async {
    final entry = _memoryCache[key];
    if (entry != null) {
      if (entry.expiresAt == null) return -1;
      final remainingMs = entry.expiresAt!.difference(DateTime.now()).inMilliseconds;
      return remainingMs > 0 ? (remainingMs / 1000).ceil() : 0;
    }
    return 0;
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
