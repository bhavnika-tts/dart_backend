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
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Unauthorized'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final orders = body['orders'];
    if (orders == null || orders is! List) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'orders array is required'},
      );
    }

    final col = MongoClient.instance.collection('formmetadatas');
    for (final item in orders) {
      if (item is Map) {
        final idStr = item['id']?.toString() ?? item['_id']?.toString();
        final displayOrder = item['displayOrder'];
        if (idStr != null && displayOrder != null) {
          final objId = ModelHelpers.toObjectId(idStr);
          if (objId != null) {
            await col.updateOne(
              where.id(objId),
              modify.set('displayOrder', displayOrder).set('updatedAt', DateTime.now().toUtc()),
            );
          }
        }
      }
    }

    return Response.json(
      body: {'message': 'Fields reordered successfully'},
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error!', 'error': error.toString()},
    );
  }
}
