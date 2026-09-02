import 'dart:async';
import 'package:dart_frog_backend/core/config/env.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// Resilient MongoDB connection manager wrapping `mongo_dart`.
class MongoClient {
  MongoClient({String? uri}) : _rawUri = uri ?? EnvConfig.instance.mongoDbUrl {
    _uri = _normalizeUri(_rawUri);
  }

  final String _rawUri;
  late final String _uri;
  Db? _db;
  Completer<Db>? _connectCompleter;

  static String _normalizeUri(String uri) {
    if (uri.isEmpty) return uri;
    var result = uri;
    final isAtlas = uri.contains('mongodb+srv://') || uri.contains('mongodb.net');
    if (isAtlas) {
      if (!result.contains('safeAtlas=')) {
        final sep = result.contains('?') ? '&' : '?';
        result = '$result${sep}safeAtlas=true';
      }
      if (!result.contains('tls=') && !result.contains('ssl=')) {
        final sep = result.contains('?') ? '&' : '?';
        result = '$result${sep}tls=true';
      }
    }
    return result;
  }

  Db get db {
    final currentDb = _db;
    if (currentDb == null || !currentDb.isConnected) {
      throw StateError('MongoDB is not connected. Call connect() first.');
    }
    return currentDb;
  }

  bool get isConnected => _db?.isConnected ?? false;

  /// Connect to MongoDB with singleton completer to serialize concurrent connections
  Future<Db> connect() async {
    if (_db != null && _db!.isConnected) {
      return _db!;
    }

    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      return _connectCompleter!.future;
    }

    final completer = Completer<Db>();
    _connectCompleter = completer;

    try {
      print('🔄 Connecting to MongoDB: ${_sanitizeUri(_uri)}');
      if (_db != null) {
        try {
          await _db!.close();
        } catch (_) {}
        _db = null;
      }

      final db = await Db.create(_uri);
      final isSecure = _uri.contains('mongodb+srv://') ||
          _uri.contains('tls=true') ||
          _uri.contains('ssl=true');
      await db.open(secure: isSecure);
      _db = db;
      print('✅ Connected to MongoDB successfully.');
      completer.complete(db);
      return db;
    } catch (e) {
      print('💥 MongoDB connection error: $e');
      completer.completeError(e);
      _connectCompleter = null;
      rethrow;
    }
  }

  /// Get a collection by name
  DbCollection collection(String name) {
    return db.collection(name);
  }

  /// Disconnect cleanly
  Future<void> close() async {
    if (_db != null) {
      try {
        await _db!.close();
      } catch (_) {}
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
