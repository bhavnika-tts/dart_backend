import 'dart:io';
import 'package:dotenv/dotenv.dart';

/// Central validated environment configuration for the Dart Frog backend.
class EnvConfig {
  EnvConfig({
    required this.appName,
    required this.port,
    required this.nodeEnv,
    required this.mongoDbUrl,
    required this.jwtSecret,
    required this.encryptionKeyHex,
    required this.passwordPepperHex,
    required this.redisUrl,
    required this.uploadsRoot,
    this.emailUser,
    this.emailPass,
    this.emailService = 'gmail',
    this.imageKitPublicKey,
    this.imageKitPrivateKey,
    this.imageKitUrlEndpoint,
    this.firebaseProjectId,
    this.firebaseClientEmail,
    this.firebasePrivateKey,
  });

  /// Factory to load from .env file and process environment variables
  factory EnvConfig.load() {
    final dotEnv = DotEnv(includePlatformEnvironment: true);

    // Check possible .env file locations
    final possiblePaths = [
      '.env',
      '../new_backend/.env',
      '/var/www/backend/classicale_backend_production.env',
      '/var/www/backend/classicale_backend.env',
    ];

    for (final path in possiblePaths) {
      if (File(path).existsSync()) {
        try {
          dotEnv.load([path]);
          break;
        } catch (_) {}
      }
    }

    String getVar(String key, {String defaultValue = ''}) {
      return dotEnv[key] ?? Platform.environment[key] ?? defaultValue;
    }

    final nodeEnv = getVar('NODE_ENV', defaultValue: 'dev');
    final mongoDbUrlDev = getVar('MONGODB_URL_DEV');
    final mongoDbUrlProd = getVar('MONGODB_URL');
    final mongoDbUrl = nodeEnv == 'prod'
        ? (mongoDbUrlProd.isNotEmpty ? mongoDbUrlProd : mongoDbUrlDev)
        : (mongoDbUrlDev.isNotEmpty ? mongoDbUrlDev : mongoDbUrlProd);

    return EnvConfig(
      appName: getVar('APP_NAME', defaultValue: 'JP'),
      port: int.tryParse(getVar('PORT', defaultValue: '3000')) ?? 3000,
      nodeEnv: nodeEnv,
      mongoDbUrl: mongoDbUrl.isNotEmpty
          ? mongoDbUrl
          : 'mongodb://localhost:27017/classical',
      jwtSecret: getVar('JWT_SECRET', defaultValue: 'classicalProject'),
      encryptionKeyHex: getVar(
        'ENCRYPTION_KEY',
        defaultValue:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      ),
      passwordPepperHex: getVar(
        'PASSWORD_PEPPER',
        defaultValue:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      ),
      redisUrl: getVar('REDIS_URL', defaultValue: 'redis://localhost:6379'),
      uploadsRoot: getVar('UPLOADS_ROOT', defaultValue: './public'),
      emailUser: getVar('EMAIL_USER'),
      emailPass: getVar('EMAIL_PASS'),
      emailService: getVar('EMAIL_SERVICE', defaultValue: 'gmail'),
      imageKitPublicKey: getVar('IMAGEKIT_PUBLIC_KEY'),
      imageKitPrivateKey: getVar('IMAGEKIT_PRIVATE_KEY'),
      imageKitUrlEndpoint: getVar('IMAGEKIT_URL_ENDPOINT'),
      firebaseProjectId: getVar('FIREBASE_PROJECT_ID'),
      firebaseClientEmail: getVar('FIREBASE_CLIENT_EMAIL'),
      firebasePrivateKey: getVar('FIREBASE_PRIVATE_KEY'),
    );
  }

  final String appName;
  final int port;
  final String nodeEnv;
  final String mongoDbUrl;
  final String jwtSecret;
  final String encryptionKeyHex;
  final String passwordPepperHex;
  final String redisUrl;
  final String uploadsRoot;
  final String? emailUser;
  final String? emailPass;
  final String emailService;
  final String? imageKitPublicKey;
  final String? imageKitPrivateKey;
  final String? imageKitUrlEndpoint;
  final String? firebaseProjectId;
  final String? firebaseClientEmail;
  final String? firebasePrivateKey;

  bool get isProduction => nodeEnv == 'prod' || nodeEnv == 'production';
  bool get isDevelopment => !isProduction;

  static EnvConfig? _instance;
  static EnvConfig get instance => _instance ??= EnvConfig.load();
}
