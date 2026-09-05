import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/crypto.dart';
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
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Unauthorized'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final oldPassword = body['oldPassword']?.toString();
    final newPassword = body['newPassword']?.toString();

    if (oldPassword == null || oldPassword.isEmpty || newPassword == null || newPassword.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Old and new passwords are required'},
      );
    }

    final adminCol = MongoClient.instance.collection('admins');
    final adminObjId = ModelHelpers.toObjectId(claims.userId);
    final admin = await adminCol.findOne(
      adminObjId != null ? where.id(adminObjId) : where.eq('_id', claims.userId),
    );

    if (admin == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Admin not found'},
      );
    }

    final isMatch = await CryptoService.instance.verifyPassword(oldPassword, admin['password'].toString());
    if (!isMatch) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Incorrect old password'},
      );
    }

    final hashedPassword = await CryptoService.instance.hashPassword(newPassword);
    final curVersion = (admin['tokenVersion'] as num?)?.toInt() ?? 0;

    await adminCol.updateOne(
      where.id(admin['_id'] as ObjectId),
      modify
          .set('password', hashedPassword)
          .set('tokenVersion', curVersion + 1)
          .set('passwordChangedAt', DateTime.now().toUtc())
          .set('updatedAt', DateTime.now().toUtc()),
    );

    return Response.json(
      body: {'message': 'Password changed successfully'},
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error'},
    );
  }
}
