import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dart_frog_backend/utils/mongo_sanitizer.dart';

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
    final Map<String, dynamic> body = {};
    String imageUrl = '';

    if (contentType.contains('multipart/form-data')) {
      final formData = await context.request.formData();
      for (final field in formData.fields.entries) {
        body[field.key] = field.value;
      }
      for (final file in formData.files.entries) {
        // Save file or construct image URL
        final bytes = await file.value.readAsBytes();
        final filename = '${DateTime.now().millisecondsSinceEpoch}_${file.value.name}';
        final uploadDir = Directory('public/banners');
        if (!uploadDir.existsSync()) {
          uploadDir.createSync(recursive: true);
        }
        final targetPath = 'public/banners/$filename';
        await File(targetPath).writeAsBytes(bytes);
        imageUrl = '/banners/$filename';
        break;
      }
    } else {
      final jsonBody = await context.request.json() as Map<String, dynamic>;
      body.addAll(jsonBody);
    }

    if (imageUrl.isEmpty) {
      imageUrl = body['imageUrl']?.toString() ?? '';
    }

    if (imageUrl.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Image is required'},
      );
    }

    final startDateStr = body['startDate']?.toString();
    final endDateStr = body['endDate']?.toString();
    DateTime? startDate;
    DateTime? endDate;
    if (startDateStr != null && startDateStr.isNotEmpty) {
      startDate = DateTime.tryParse(startDateStr)?.toUtc();
    }
    if (endDateStr != null && endDateStr.isNotEmpty) {
      endDate = DateTime.tryParse(endDateStr)?.toUtc();
    }

    final col = MongoClient.instance.collection('banners');
    final docId = ObjectId();

    final newDoc = <String, dynamic>{
      '_id': docId,
      'imageUrl': imageUrl,
      'title': body['title'] ?? '',
      'description': body['description'] ?? '',
      'categoryName': body['categoryName'] ?? '',
      'productType': body['productType'] ?? '',
      'order': int.tryParse(body['order']?.toString() ?? '0') ?? 0,
      'startDate': startDate,
      'endDate': endDate,
      'area': body['area'] ?? '',
      'city': body['city'] ?? '',
      'state': body['state'] ?? '',
      'country': body['country'] ?? '',
      'actionType': body['actionType'] ?? 'NONE',
      'actionData': body['actionData'] ?? '',
      'allowedUserPlans': [],
      'scheduleTimezoneMigrationVersion': 2,
      'isActive': body['isActive'] != null ? (body['isActive'] == true || body['isActive'] == 'true') : true,
      'createdBy': ModelHelpers.toObjectId(claims.userId) ?? claims.userId,
      'history': [
        {
          'updatedBy': ModelHelpers.toObjectId(claims.userId) ?? claims.userId,
          'updatedAt': DateTime.now().toUtc(),
        }
      ],
      'scheduleHistory': [],
      'scheduleQueue': [],
      'clickCount': 0,
      'repostCount': 0,
      'createdAt': DateTime.now().toUtc(),
      'updatedAt': DateTime.now().toUtc(),
      '__v': 0,
    };

    await col.insertOne(newDoc);

    final sanitized = sanitizeMongoData(newDoc) as Map<String, dynamic>;

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'message': 'Banner added successfully',
        'banner': sanitized,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to add banner', 'error': error.toString()},
    );
  }
}
