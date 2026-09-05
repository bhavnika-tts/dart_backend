import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dart_frog_backend/utils/mongo_sanitizer.dart';

Future<Response> onRequest(RequestContext context, String id, String queueId) async {
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

    final queueList = (banner['scheduleQueue'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final now = DateTime.now().toUtc();
    final historyList = (banner['history'] as List?)?.toList() ?? [];
    historyList.add({
      'updatedBy': ModelHelpers.toObjectId(claims.userId) ?? claims.userId,
      'updatedAt': now,
    });

    if (context.request.method == HttpMethod.delete) {
      final updatedQueue = queueList.where((item) => ModelHelpers.idToString(item['_id']) != queueId).toList();
      await col.updateOne(
        where.id(banner['_id'] as ObjectId),
        modify.set('scheduleQueue', updatedQueue).set('history', historyList).set('updatedAt', now),
      );

      final updated = await col.findOne(where.id(banner['_id'] as ObjectId));
      final sanitized = sanitizeMongoData(updated ?? banner) as Map<String, dynamic>;

      return Response.json(
        body: {
          'message': 'Queued schedule deleted successfully',
          'banner': sanitized,
        },
      );
    }

    // PUT
    final body = await context.request.json() as Map<String, dynamic>;
    final startDateStr = body['startDate']?.toString();
    final endDateStr = body['endDate']?.toString();
    final startDate = startDateStr != null ? DateTime.tryParse(startDateStr)?.toUtc() : null;
    final endDate = endDateStr != null ? DateTime.tryParse(endDateStr)?.toUtc() : null;

    final queueIndex = queueList.indexWhere((item) => ModelHelpers.idToString(item['_id']) == queueId);
    if (queueIndex == -1) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Queued schedule not found'},
      );
    }

    queueList[queueIndex]['startDate'] = startDate;
    queueList[queueIndex]['endDate'] = endDate;

    await col.updateOne(
      where.id(banner['_id'] as ObjectId),
      modify.set('scheduleQueue', queueList).set('history', historyList).set('updatedAt', now),
    );

    final updated = await col.findOne(where.id(banner['_id'] as ObjectId));
    final sanitized = sanitizeMongoData(updated ?? banner) as Map<String, dynamic>;

    return Response.json(
      body: {
        'message': 'Queued schedule updated successfully',
        'banner': sanitized,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to process queued schedule', 'error': error.toString()},
    );
  }
}
