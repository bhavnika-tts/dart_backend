import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:dart_frog_backend/utils/mongo_sanitizer.dart';
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

    final query = context.request.uri.queryParameters;
    final userId = query['userId'];

    if (userId == null || userId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'userId is required'},
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

    if (claims.role == 'subadmin') {
      final assigned = user['assignedByAdmin']?.toString();
      if (assigned != claims.userId) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'message': 'Access denied. You do not manage this user.'},
        );
      }
    }

    final userMap = Map<String, dynamic>.from(user);
    userMap.remove('password');
    userMap.remove('otp');
    userMap.remove('otpExpire');

    if (userMap['occupationId'] != null) {
      final occCol = MongoClient.instance.collection('occupations');
      final occObjId = ModelHelpers.toObjectId(userMap['occupationId'].toString());
      final occDoc = await occCol.findOne(occObjId != null ? where.id(occObjId) : where.eq('_id', userMap['occupationId']));
      if (occDoc != null) {
        userMap['occupationId'] = occDoc;
      }
    }

    final sanitizedUser = sanitizeMongoData(userMap) as Map<String, dynamic>;

    return Response.json(
      body: {
        'success': true,
        'user': sanitizedUser,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server Error', 'error': error.toString()},
    );
  }
}
