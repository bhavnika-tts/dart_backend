import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:dart_frog_backend/utils/mongo_sanitizer.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.delete) {
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

    final query = context.request.uri.queryParameters;
    final userId = query['userId'];

    if (userId == null || userId.isEmpty) {
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

    final isDeleted = user['isDeleted'] == true;
    final newDeleted = !isDeleted;

    await userCol.updateOne(
      where.id(user['_id'] as ObjectId),
      modify.set('isDeleted', newDeleted).set('updatedAt', DateTime.now().toUtc()),
    );

    final updated = await userCol.findOne(where.id(user['_id'] as ObjectId));
    final updatedMap = Map<String, dynamic>.from(updated ?? user);
    updatedMap.remove('password');
    updatedMap.remove('otp');
    updatedMap.remove('otpExpire');

    final sanitizedUser = sanitizeMongoData(updatedMap) as Map<String, dynamic>;

    return Response.json(
      body: {
        'message': 'User soft-deleted successfully',
        'user': sanitizedUser,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error!', 'error': error.toString()},
    );
  }
}
