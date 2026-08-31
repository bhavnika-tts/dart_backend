import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:argon2/argon2.dart';
import 'package:convert/convert.dart';
import 'package:dart_frog_backend/core/config/env.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';

/// Cryptography and hashing service with 100% byte-level compatibility
/// with Node.js `utils/crypto.js`.
class CryptoService {
  CryptoService({
    String? encryptionKeyHex,
    String? passwordPepperHex,
  })  : _encryptionKeyBytes = Uint8List.fromList(
          hex.decode(
            encryptionKeyHex ?? EnvConfig.instance.encryptionKeyHex,
          ),
        ),
        _passwordPepper =
            passwordPepperHex ?? EnvConfig.instance.passwordPepperHex;

  final Uint8List _encryptionKeyBytes;
  final String _passwordPepper;
  final Random _random = Random.secure();

  // ──────────────────────────────────────────────────────────────────────────
  // AES-256-GCM Field Encryption & Decryption
  // Format: "<iv_hex>:<authTag_hex>:<ciphertext_hex>"
  // ──────────────────────────────────────────────────────────────────────────

  /// Encrypts plaintext using AES-256-GCM.
  /// Returns `<iv_hex>:<authTag_hex>:<ciphertext_hex>`
  String encrypt(String? plaintext) {
    if (plaintext == null || plaintext.isEmpty) return plaintext ?? '';

    // Generate 16-byte random IV
    final iv = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      iv[i] = _random.nextInt(256);
    }

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(_encryptionKeyBytes), 128, iv, Uint8List(0)),
      );

    final plainBytes = Uint8List.fromList(utf8.encode(plaintext));
    final outBytes = cipher.process(plainBytes);

    // PointyCastle appends 16-byte auth tag at the end of output
    final ciphertextBytes = outBytes.sublist(0, outBytes.length - 16);
    final authTagBytes = outBytes.sublist(outBytes.length - 16);

    final ivHex = hex.encode(iv);
    final authTagHex = hex.encode(authTagBytes);
    final cipherHex = hex.encode(ciphertextBytes);

    return '$ivHex:$authTagHex:$cipherHex';
  }

  /// Decrypts ciphertext produced by `encrypt()` or Node.js crypto.
  /// Returns the original plaintext, or the ciphertext unchanged if not encrypted.
  String decrypt(String? ciphertext) {
    if (ciphertext == null || ciphertext.isEmpty) return ciphertext ?? '';

    final parts = ciphertext.split(':');
    if (parts.length != 3) return ciphertext;

    try {
      final iv = Uint8List.fromList(hex.decode(parts[0]));
      final authTag = Uint8List.fromList(hex.decode(parts[1]));
      final cipher = Uint8List.fromList(hex.decode(parts[2]));

      // Concatenate ciphertext + auth tag for PointyCastle GCM decryption
      final input = Uint8List(cipher.length + authTag.length)
        ..setAll(0, cipher)
        ..setAll(cipher.length, authTag);

      final decCipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(KeyParameter(_encryptionKeyBytes), 128, iv, Uint8List(0)),
        );

      final decryptedBytes = decCipher.process(input);
      return utf8.decode(decryptedBytes);
    } catch (_) {
      // Decryption failed — return ciphertext to prevent data loss (matching Node.js)
      return ciphertext;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Aadhaar Masking Utility
  // ──────────────────────────────────────────────────────────────────────────

  /// Masks an Aadhaar number to show only the last 4 digits.
  /// Returns "XXXX-XXXX-1234"
  static String maskAadhaar(String? aadhaar) {
    if (aadhaar == null || aadhaar.isEmpty) return '';
    final digits = aadhaar.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return 'XXXX-XXXX-****';
    final last4 = digits.substring(digits.length - 4);
    return 'XXXX-XXXX-$last4';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Argon2id + Pepper Password Hashing
  // PHC Format: "$argon2id$v=19$m=65536,t=3,p=4$<salt_b64>$<hash_b64>"
  // ──────────────────────────────────────────────────────────────────────────

  /// Hashes a plaintext password with Argon2id + pepper.
  Future<String> hashPassword(String plaintext) async {
    if (plaintext.isEmpty) throw ArgumentError('Plaintext is required');
    final peppered = plaintext + _passwordPepper;

    // Generate 16-byte random salt
    final salt = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      salt[i] = _random.nextInt(256);
    }

    const memory = 65536; // 64 MB
    const iterations = 3;
    const parallelism = 4;
    const hashLength = 32;

    final params = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      version: Argon2Parameters.ARGON2_VERSION_13,
      iterations: iterations,
      memory: memory,
      lanes: parallelism,
    );

    final generator = Argon2BytesGenerator()..init(params);
    final passwordBytes = Uint8List.fromList(utf8.encode(peppered));
    final hashBytes = Uint8List(hashLength);
    generator.generateBytes(passwordBytes, hashBytes, 0, hashLength);

    final saltB64 = base64.encode(salt).replaceAll('=', '');
    final hashB64 = base64.encode(hashBytes).replaceAll('=', '');

    return '\$argon2id\$v=19\$m=$memory,t=$iterations,p=$parallelism\$$saltB64\$$hashB64';
  }

  /// Verifies a plaintext password against an Argon2id PHC hash.
  Future<bool> verifyPassword(String plaintext, String storedHash) async {
    if (plaintext.isEmpty || storedHash.isEmpty) return false;
    try {
      final parts = storedHash.split(r'$');
      if (parts.length < 6) return false;

      // Extract parameters from parts[3] (e.g. "m=65536,t=3,p=4")
      var memory = 65536;
      var iterations = 3;
      var parallelism = 4;

      final paramPairs = parts[3].split(',');
      for (final pair in paramPairs) {
        final kv = pair.split('=');
        if (kv.length == 2) {
          if (kv[0] == 'm') memory = int.tryParse(kv[1]) ?? memory;
          if (kv[0] == 't') iterations = int.tryParse(kv[1]) ?? iterations;
          if (kv[0] == 'p') parallelism = int.tryParse(kv[1]) ?? parallelism;
        }
      }

      String normalizeBase64(String str) {
        var s = str;
        while (s.length % 4 != 0) {
          s += '=';
        }
        return s;
      }

      final saltBytes =
          Uint8List.fromList(base64.decode(normalizeBase64(parts[4])));
      final expectedHashBytes =
          Uint8List.fromList(base64.decode(normalizeBase64(parts[5])));

      final peppered = plaintext + _passwordPepper;
      final params = Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        saltBytes,
        version: Argon2Parameters.ARGON2_VERSION_13,
        iterations: iterations,
        memory: memory,
        lanes: parallelism,
      );

      final generator = Argon2BytesGenerator()..init(params);
      final passwordBytes = Uint8List.fromList(utf8.encode(peppered));
      final calculatedHashBytes = Uint8List(expectedHashBytes.length);
      generator.generateBytes(
        passwordBytes,
        calculatedHashBytes,
        0,
        calculatedHashBytes.length,
      );

      // Constant time equality check
      if (calculatedHashBytes.length != expectedHashBytes.length) return false;
      var result = 0;
      for (var i = 0; i < calculatedHashBytes.length; i++) {
        result |= calculatedHashBytes[i] ^ expectedHashBytes[i];
      }
      return result == 0;
    } catch (_) {
      return false;
    }
  }

  static CryptoService? _instance;
  static CryptoService get instance => _instance ??= CryptoService();
}
