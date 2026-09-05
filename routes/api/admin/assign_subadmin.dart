import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
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

    final body = await context.request.json() as Map<String, dynamic>;
    final userId = body['userId']?.toString();
    final subadminId = body['subadminId']?.toString();

    if (userId == null || userId.isEmpty || subadminId == null || subadminId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'userId and subadminId are required'},
      );
    }

    final userCol = MongoClient.instance.collection('users');
    final adminCol = MongoClient.instance.collection('admins');

    final userObjId = ModelHelpers.toObjectId(userId);
    final user = await userCol.findOne(userObjId != null ? where.id(userObjId) : where.eq('_id', userId));
    if (user == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'User not found'},
      );
    }

    final subadminObjId = ModelHelpers.toObjectId(subadminId);
    final subadmin = await adminCol.findOne(
      subadminObjId != null
          ? where.id(subadminObjId).eq('role', 'subadmin')
          : where.eq('_id', subadminId).eq('role', 'subadmin'),
    );
    if (subadmin == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Subadmin not found'},
      );
    }

    await userCol.updateOne(
      where.id(user['_id'] as ObjectId),
      modify.set('assignedByAdmin', subadmin['_id']).set('updatedAt', DateTime.now().toUtc()),
    );

    return Response.json(
      body: {
        'message': 'Subadmin assigned to user successfully',
        'user': {
          'id': ModelHelpers.idToString(user['_id']),
          'name': user['name'],
          'email': user['email'],
          'assignedByAdmin': ModelHelpers.idToString(subadmin['_id']),
        },
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error'},
    );
  }
}
