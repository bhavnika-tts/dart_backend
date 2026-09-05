import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Unauthorized'},
      );
    }

    final contentType = context.request.headers['content-type'] ?? '';
    final Map<String, dynamic> fields = {};
    String finalVideoUrl = '';
    int sizeBytes = 0;
    String ext = 'mp4';

    if (contentType.contains('multipart/form-data')) {
      final formData = await context.request.formData();
      for (final field in formData.fields.entries) {
        fields[field.key] = field.value;
      }
      for (final file in formData.files.entries) {
        final bytes = await file.value.readAsBytes();
        sizeBytes = bytes.length;
        ext = file.value.name.split('.').last.toLowerCase();
        final filename = '${DateTime.now().millisecondsSinceEpoch}_${file.value.name}';
        final uploadDir = Directory('public/videos/app-guide');
        if (!uploadDir.existsSync()) {
          uploadDir.createSync(recursive: true);
        }
        final targetPath = 'public/videos/app-guide/$filename';
        await File(targetPath).writeAsBytes(bytes);
        finalVideoUrl = '/public/videos/app-guide/$filename';
        break;
      }
    } else {
      final jsonBody = await context.request.json() as Map<String, dynamic>;
      fields.addAll(jsonBody);
    }

    final title = fields['title']?.toString();
    if (title == null || title.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Missing required field: title'},
      );
    }

    if (finalVideoUrl.isEmpty) {
      if (fields['videoUrl'] != null && fields['videoUrl'].toString().isNotEmpty) {
        finalVideoUrl = fields['videoUrl'].toString();
        sizeBytes = int.tryParse(fields['videoSize']?.toString() ?? '0') ?? 0;
        ext = finalVideoUrl.split('.').last.split('?').first.toLowerCase();
      } else {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {
            'message': "No video file or video URL received. Use multipart/form-data with 'video' or send JSON with 'videoUrl'."
          },
        );
      }
    }

    final col = MongoClient.instance.collection('appguidevideos');
    final newId = ObjectId();
    final newVideo = <String, dynamic>{
      '_id': newId,
      'title': title,
      'description': fields['description']?.toString() ?? '',
      'videoName': finalVideoUrl,
      'videoSize': sizeBytes,
      'videoExtension': ext,
      'videoDuration': int.tryParse(fields['videoDuration']?.toString() ?? '0') ?? 0,
      'isVisible': false,
      'createdAt': DateTime.now().toUtc(),
      'updatedAt': DateTime.now().toUtc(),
      '__v': 0,
    };

    await col.insertOne(newVideo);

    final sanitized = Map<String, dynamic>.from(newVideo);
    sanitized['_id'] = ModelHelpers.idToString(sanitized['_id']);
    if (sanitized['createdAt'] is DateTime) {
      sanitized['createdAt'] = (sanitized['createdAt'] as DateTime).toIso8601String();
    }
    if (sanitized['updatedAt'] is DateTime) {
      sanitized['updatedAt'] = (sanitized['updatedAt'] as DateTime).toIso8601String();
    }

    return Response.json(
      body: {
        'message': 'Video saved successfully',
        'data': sanitized,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to save video', 'error': error.toString()},
    );
  }
}
