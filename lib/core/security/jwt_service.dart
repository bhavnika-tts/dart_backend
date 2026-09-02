import 'package:dart_frog_backend/core/config/env.dart';
import 'package:dart_frog_backend/core/errors/app_error.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// User authentication claims extracted from verified JWT token.
class UserAuth {
  UserAuth({
    required this.id,
    required this.role,
    this.tokenVersion,
    this.phone,
    this.userNo,
    this.email,
    this.sessionToken,
    this.rawClaims = const {},
  });

  factory UserAuth.fromJwtPayload(Map<String, dynamic> payload) {
    final id = payload['id']?.toString() ?? payload['_id']?.toString();
    final role = payload['role']?.toString();

    if (id == null || role == null) {
      throw AppError.unauthorized('Invalid token data.');
    }

    return UserAuth(
      id: id,
      role: role,
      tokenVersion: payload['tokenVersion'] is int
          ? payload['tokenVersion'] as int
          : int.tryParse(payload['tokenVersion']?.toString() ?? ''),
      phone: payload['phone']?.toString(),
      userNo: payload['userNo']?.toString(),
      email: payload['email']?.toString(),
      sessionToken: payload['sessionToken']?.toString(),
      rawClaims: payload,
    );
  }

  final String id;
  final String role;
  final int? tokenVersion;
  final String? phone;
  final String? userNo;
  final String? email;
  final String? sessionToken;
  final Map<String, dynamic> rawClaims;

  String get userId => id;
  bool get isAdmin =>
      role == 'superadmin' || role == 'admin' || role == 'subadmin';
  bool get isSuperAdmin => role == 'superadmin';
  bool get isUser => role == 'user';
}

/// JWT Token generation and verification service.
class JwtService {
  JwtService({String? secret}) : _secret = secret ?? EnvConfig.instance.jwtSecret;

  final String _secret;

  /// Generate a signed JWT token
  String sign({
    required String id,
    required String role,
    Map<String, dynamic>? extraClaims,
    Duration expiresIn = const Duration(days: 7),
  }) {
    final payload = <String, dynamic>{
      'id': id,
      'role': role,
      if (extraClaims != null) ...extraClaims,
    };

    final jwt = JWT(payload);
    return jwt.sign(
      SecretKey(_secret),
      expiresIn: expiresIn,
    );
  }

  /// Generate token with user claims
  String signToken({
    required String userId,
    required String email,
    required String role,
    String? sessionToken,
    int? tokenVersion,
  }) {
    return sign(
      id: userId,
      role: role,
      extraClaims: {
        'email': email,
        if (sessionToken != null) 'sessionToken': sessionToken,
        if (tokenVersion != null) 'tokenVersion': tokenVersion,
      },
    );
  }

  /// Verify and decode a JWT token string
  UserAuth verify(String tokenString) {
    var rawToken = tokenString.trim();
    if (rawToken.startsWith('Bearer ')) {
      rawToken = rawToken.substring(7).trim();
    }

    if (rawToken.isEmpty) {
      throw AppError.unauthorized('Invalid or missing Authorization token.');
    }

    try {
      final jwt = JWT.verify(rawToken, SecretKey(_secret));
      final payload = jwt.payload;
      if (payload is Map<String, dynamic>) {
        return UserAuth.fromJwtPayload(payload);
      } else if (payload is Map) {
        return UserAuth.fromJwtPayload(Map<String, dynamic>.from(payload));
      }
      throw AppError.unauthorized('Invalid token payload structure.');
    } on JWTExpiredException {
      throw AppError.unauthorized(
        'Token has expired. Please log in again.',
        code: 'TOKEN_EXPIRED',
      );
    } on JWTException catch (e) {
      throw AppError.unauthorized('Invalid token: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unauthorized('Authentication failed.');
    }
  }

  /// Safely verifies Authorization header string, returning null if invalid or missing.
  UserAuth? verifyAuthHeader(String? authHeader) {
    if (authHeader == null || authHeader.isEmpty) return null;
    try {
      return verify(authHeader);
    } catch (_) {
      return null;
    }
  }

  static JwtService? _instance;
  static JwtService get instance => _instance ??= JwtService();
}
