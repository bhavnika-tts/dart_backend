import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/db/mongo_client.dart';
import '../models/image_model.dart';

/// Service for ImageKit CDN operations: URL signing, file uploads, and deletion.
class ImageKitService {
  ImageKitService({
    EnvConfig? config,
    MongoClient? mongoClient,
    http.Client? httpClient,
  })  : _config = config ?? EnvConfig.instance,
        _mongoClient = mongoClient ?? MongoClient.instance,
        _httpClient = httpClient ?? http.Client();

  final EnvConfig _config;
  final MongoClient _mongoClient;
  final http.Client _httpClient;

  static ImageKitService? _instance;
  static ImageKitService get instance => _instance ??= ImageKitService();

  String get _privateKey => _config.imageKitPrivateKey ?? '';

  /// Generates an HMAC-SHA1 time-limited signed URL for an ImageKit asset.
  String getSignedUrl(String url, {int expiresIn = 3600}) {
    if (url.isEmpty || !url.contains('ik.imagekit.io')) return url;
    if (_privateKey.isEmpty) return url;

    try {
      final uri = Uri.parse(url);
      final cleanUrl = '${uri.scheme}://${uri.host}${uri.path}';
      
      final expiry = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + expiresIn;
      final expiryStr = expiry.toString();

      // ImageKit signature: HMAC-SHA1(privateKey, path + expiryTimestamp)
      // Path includes leading slash after the endpoint domain
      final pathPart = uri.path;
      final stringToSign = '$pathPart$expiryStr';

      final hmac = Hmac(sha1, utf8.encode(_privateKey));
      final digest = hmac.convert(utf8.encode(stringToSign));
      final signature = digest.toString();

      final separator = uri.queryParameters.isEmpty ? '?' : '&';
      return '$cleanUrl$separator ik-s=$signature&ik-t=$expiryStr'.replaceAll(' ', '');
    } catch (_) {
      return url;
    }
  }

  /// Strips ImageKit signatures and query parameters from a CDN URL.
  String stripSignature(String url) {
    if (url.isEmpty || !url.contains('ik.imagekit.io')) return url;
    return url.split('?').first;
  }

  /// Recursively signs all ImageKit URLs in any Map, List, or String in-place.
  dynamic signImageKitUrls(dynamic obj, {int expiresIn = 3600}) {
    if (obj == null) return null;

    if (obj is String) {
      if (obj.contains('ik.imagekit.io')) {
        return getSignedUrl(obj, expiresIn: expiresIn);
      }
      return obj;
    }

    if (obj is List) {
      return obj.map((item) => signImageKitUrls(item, expiresIn: expiresIn)).toList();
    }

    if (obj is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final entry in obj.entries) {
        result[entry.key] = signImageKitUrls(entry.value, expiresIn: expiresIn);
      }
      return result;
    }

    if (obj is Map) {
      final result = <dynamic, dynamic>{};
      for (final entry in obj.entries) {
        result[entry.key] = signImageKitUrls(entry.value, expiresIn: expiresIn);
      }
      return result;
    }

    return obj;
  }

  /// Uploads binary bytes directly to ImageKit REST API.
  /// Also registers the file in the MongoDB `ImageModel` registry.
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    String prefix = 'file',
  }) async {
    if (bytes.isEmpty) {
      throw Exception('File bytes are empty (0 bytes).');
    }

    final cleanFileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$fileName';

    final uri = Uri.parse('https://upload.imagekit.io/api/v1/files/upload');
    final request = http.MultipartRequest('POST', uri);

    final basicAuth = base64Encode(utf8.encode('$_privateKey:'));
    request.headers['Authorization'] = 'Basic $basicAuth';

    request.fields['fileName'] = cleanFileName;
    request.fields['folder'] = folder.startsWith('/') ? folder : '/$folder';
    request.fields['useUniqueFileName'] = 'false';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: cleanFileName,
      ),
    );

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final cdnUrl = data['url'] as String? ?? '';
      final fileId = data['fileId'] as String? ?? '';

      // Register file in MongoDB Image collection
      try {
        final collection = _mongoClient.collection('images');
        await collection.insertOne(
          ImageModel(
            url: cdnUrl,
            fileId: fileId,
          ).toBson(),
        );
      } catch (dbErr) {
        // Non-blocking log
      }

      return cdnUrl;
    } else {
      throw Exception('ImageKit upload failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Permanently deletes an asset from ImageKit using its file registry record.
  Future<bool> deleteFile(String url) => deleteFromImageKit(url);

  /// Permanently deletes an asset from ImageKit using its file registry record.
  Future<bool> deleteFromImageKit(String url) async {
    if (url.isEmpty || !url.contains('ik.imagekit.io')) return false;

    try {
      final collection = _mongoClient.collection('images');
      final cleanUrl = stripSignature(url);
      final record = await collection.findOne({'url': cleanUrl});

      if (record == null) return false;

      final fileId = record['fileId'] as String?;
      if (fileId != null && fileId.isNotEmpty) {
        final uri = Uri.parse('https://api.imagekit.io/v1/files/$fileId');
        final basicAuth = base64Encode(utf8.encode('$_privateKey:'));
        await _httpClient.delete(
          uri,
          headers: {'Authorization': 'Basic $basicAuth'},
        );
      }

      await collection.deleteOne({'_id': record['_id']});
      return true;
    } catch (_) {
      return false;
    }
  }
}
