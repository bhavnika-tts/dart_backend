import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dart_frog_backend/utils/mongo_sanitizer.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.put && context.request.method != HttpMethod.delete) {
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

    final objId = ModelHelpers.toObjectId(id);
    final col = MongoClient.instance.collection('banners');
    final banner = await col.findOne(objId != null ? where.id(objId) : where.eq('_id', id));

    if (banner == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Banner not found'},
      );
    }

    if (context.request.method == HttpMethod.delete) {
      await col.deleteOne(where.id(banner['_id'] as ObjectId));
      return Response.json(
        body: {'message': 'Banner deleted successfully'},
      );
    }

    // PUT
    final contentType = context.request.headers['content-type'] ?? '';
    final Map<String, dynamic> body = {};
    String imageUrl = banner['imageUrl']?.toString() ?? '';

    if (contentType.contains('multipart/form-data')) {
      final formData = await context.request.formData();
      for (final field in formData.fields.entries) {
        body[field.key] = field.value;
      }
      for (final file in formData.files.entries) {
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
      if (body['imageUrl'] != null && body['imageUrl'].toString().isNotEmpty) {
        imageUrl = body['imageUrl'].toString();
      }
    }

    final mod = modify.set('updatedAt', DateTime.now().toUtc()).set('imageUrl', imageUrl);

    for (final k in ['title', 'description', 'categoryName', 'productType', 'area', 'city', 'state', 'country', 'actionType', 'actionData']) {
      if (body.containsKey(k)) {
        mod.set(k, body[k]);
      }
    }

    if (body.containsKey('order')) {
      mod.set('order', int.tryParse(body['order'].toString()) ?? 0);
    }
    if (body.containsKey('isActive')) {
      mod.set('isActive', body['isActive'] == true || body['isActive'] == 'true');
    }
    if (body.containsKey('startDate')) {
      final s = body['startDate']?.toString();
      mod.set('startDate', (s != null && s.isNotEmpty) ? DateTime.tryParse(s)?.toUtc() : null);
    }
    if (body.containsKey('endDate')) {
      final e = body['endDate']?.toString();
      mod.set('endDate', (e != null && e.isNotEmpty) ? DateTime.tryParse(e)?.toUtc() : null);
    }

    final historyList = (banner['history'] as List?)?.toList() ?? [];
    historyList.add({
      'updatedBy': ModelHelpers.toObjectId(claims.userId) ?? claims.userId,
      'updatedAt': DateTime.now().toUtc(),
    });
    mod.set('history', historyList);

    await col.updateOne(where.id(banner['_id'] as ObjectId), mod);
    final updated = await col.findOne(where.id(banner['_id'] as ObjectId));

    final sanitized = sanitizeMongoData(updated ?? banner) as Map<String, dynamic>;

    return Response.json(
      body: {
        'message': 'Banner updated successfully',
        'banner': sanitized,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to update banner', 'error': error.toString()},
    );
  }
}
