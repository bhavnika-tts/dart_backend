import 'dart:async';
import 'package:dart_frog_backend/core/config/env.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// Resilient MongoDB connection manager wrapping `mongo_dart`.
class MongoClient {
  MongoClient({String? uri}) : _uri = uri ?? EnvConfig.instance.mongoDbUrl;

  final String _uri;
  Db? _db;
  bool _isConnecting = false;

  Db get db {
    final currentDb = _db;
    if (currentDb == null || !currentDb.isConnected) {
      throw StateError('MongoDB is not connected. Call connect() first.');
    }
    return currentDb;
  }

  bool get isConnected => _db?.isConnected ?? false;

  /// Connect to MongoDB with timeout and retry logic
  Future<Db> connect() async {
    if (_db != null && _db!.isConnected) {
      return _db!;
    }

    if (_isConnecting) {
      // Wait for in-flight connection attempt
      while (_isConnecting) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (_db != null && _db!.isConnected) return _db!;
    }

    _isConnecting = true;
    try {
      print('🔄 Connecting to MongoDB: ${_sanitizeUri(_uri)}');
      final db = await Db.create(_uri);
      await db.open();
      _db = db;
      print('✅ Connected to MongoDB successfully.');
      return db;
    } catch (e) {
      print('💥 MongoDB connection error: $e');
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  /// Get a collection by name
  DbCollection collection(String name) {
    return db.collection(name);
  }

  /// Disconnect cleanly
  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      _db = null;
      print('🔌 Closed MongoDB connection.');
    }
  }

  /// Sanitize URI for logging to avoid leaking password
  static String _sanitizeUri(String uri) {
    try {
      final parsed = Uri.parse(uri);
      if (parsed.userInfo.isNotEmpty) {
        return uri.replaceFirst(parsed.userInfo, '***:***');
      }
    } catch (_) {}
    return uri;
  }

  static MongoClient? _instance;
  static MongoClient get instance => _instance ??= MongoClient();
}
