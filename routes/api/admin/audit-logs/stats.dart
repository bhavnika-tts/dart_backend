import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null || claims.role != 'superadmin') {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Superadmin privileges required'},
      );
    }

    final col = MongoClient.instance.collection('adminauditlogs');

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final totalLogs = await col.count();
    final todayLogs = await col.count({
      'createdAt': {'\$gte': todayStart},
    });
    final failedLogs = await col.count({'status': 'FAILED'});

    final actionAggregation = await col.aggregateToStream([
      {
        '\$group': {
          '_id': '\$action',
          'count': {'\$sum': 1},
        }
      },
      {'\$sort': {'count': -1}},
      {'\$limit': 10},
    ]).toList();

    return Response.json(
      body: {
        'success': true,
        'stats': {
          'totalLogs': totalLogs,
          'todayLogs': todayLogs,
          'failedLogs': failedLogs,
          'topActions': actionAggregation,
        },
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error', 'error': error.toString()},
    );
  }
}
