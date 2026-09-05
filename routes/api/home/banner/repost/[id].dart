import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dart_frog_backend/utils/mongo_sanitizer.dart';

Future<Response> onRequest(RequestContext context, String id) async {
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

    final objId = ModelHelpers.toObjectId(id);
    final col = MongoClient.instance.collection('banners');
    final banner = await col.findOne(objId != null ? where.id(objId) : where.eq('_id', id));

    if (banner == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Banner not found'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final startDateStr = body['startDate']?.toString();
    final endDateStr = body['endDate']?.toString();
    final startDate = startDateStr != null ? DateTime.tryParse(startDateStr)?.toUtc() : null;
    final endDate = endDateStr != null ? DateTime.tryParse(endDateStr)?.toUtc() : null;

    final now = DateTime.now().toUtc();
    final bannerEndDate = banner['endDate'] is DateTime ? banner['endDate'] as DateTime : null;
    final hasActiveOrUpcoming = banner['isActive'] == true &&
        (bannerEndDate == null || bannerEndDate.isAfter(now) || bannerEndDate.isAtSameMomentAs(now));

    final historyList = (banner['history'] as List?)?.toList() ?? [];
    historyList.add({
      'updatedBy': ModelHelpers.toObjectId(claims.userId) ?? claims.userId,
      'updatedAt': now,
    });

    final mod = modify.set('updatedAt', now).set('history', historyList);
    String responseMessage;

    if (hasActiveOrUpcoming) {
      final queueList = (banner['scheduleQueue'] as List?)?.toList() ?? [];
      queueList.add({
        '_id': ObjectId(),
        'startDate': startDate,
        'endDate': endDate,
        'scheduledAt': now,
        'scheduledBy': ModelHelpers.toObjectId(claims.userId) ?? claims.userId,
      });
      mod.set('scheduleQueue', queueList);
      responseMessage = 'Banner schedule queued successfully';
    } else {
      final schedHistory = (banner['scheduleHistory'] as List?)?.toList() ?? [];
      if (banner['startDate'] != null || banner['endDate'] != null) {
        schedHistory.add({
          '_id': ObjectId(),
          'startDate': banner['startDate'],
          'endDate': banner['endDate'],
          'repostedAt': now,
          'repostedBy': ModelHelpers.toObjectId(claims.userId) ?? claims.userId,
        });
        mod.set('scheduleHistory', schedHistory);
      }
      mod.set('startDate', startDate);
      mod.set('endDate', endDate);
      mod.set('isActive', true);
      final curRepost = (banner['repostCount'] as num?)?.toInt() ?? 0;
      mod.set('repostCount', curRepost + 1);
      responseMessage = 'Banner reposted successfully';
    }

    await col.updateOne(where.id(banner['_id'] as ObjectId), mod);
    final updated = await col.findOne(where.id(banner['_id'] as ObjectId));

    final sanitized = sanitizeMongoData(updated ?? banner) as Map<String, dynamic>;

    return Response.json(
      body: {
        'message': responseMessage,
        'banner': sanitized,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to repost banner', 'error': error.toString()},
    );
  }
}
