import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
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

    final reportsCol = MongoClient.instance.collection('report_products');
    var count = 0;

    if (claims.role == 'subadmin') {
      final subadminObjId = ModelHelpers.toObjectId(claims.userId);
      final usersCol = MongoClient.instance.collection('users');
      final managedUsers = await usersCol.find(where.eq('assignedByAdmin', subadminObjId)).toList();
      final userIds = managedUsers.map((u) => u['_id']).toList();

      count = await reportsCol.count(where.oneFrom('userId', userIds));
    } else {
      count = await reportsCol.count();
    }

    return Response.json(
      body: {
        'message': 'Report count fetched successfully',
        'count': count,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error', 'error': error.toString()},
    );
  }
}
