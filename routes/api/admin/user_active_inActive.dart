import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:dart_frog_backend/utils/mongo_sanitizer.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin' && claims.role != 'admin')) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    final query = context.request.uri.queryParameters;
    String userId = query['userId']?.toString().trim() ?? '';
    if (userId.isEmpty) {
      try {
        final body = await context.request.json() as Map<String, dynamic>;
        userId = body['userId']?.toString().trim() ?? '';
      } catch (_) {}
    }

    if (userId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'User ID is required'},
      );
    }

    final userCol = MongoClient.instance.collection('users');
    final userObjId = ModelHelpers.toObjectId(userId);
    final user = await userCol.findOne(userObjId != null ? where.id(userObjId) : where.eq('_id', userId));

    if (user == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'User not found'},
      );
    }

    final currentActive = user['isActive'] == true;
    final newActive = !currentActive;

    await userCol.updateOne(
      where.id(user['_id'] as ObjectId),
      modify.set('isActive', newActive).set('updatedAt', DateTime.now().toUtc()),
    );

    final updated = await userCol.findOne(where.id(user['_id'] as ObjectId));
    final sanitizedUser = sanitizeMongoData(updated ?? user) as Map<String, dynamic>;

    return Response.json(
      body: {
        'message': 'User ${newActive ? "activated" : "deactivated"} successfully',
        'user': sanitizedUser,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error', 'error': error.toString()},
    );
  }
}
