import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final authHeader = context.request.headers['authorization'];
  final claims = JwtService.instance.verifyAuthHeader(authHeader);
  if (claims == null ||
      (claims.role != 'superadmin' && claims.role != 'subadmin' && claims.role != 'admin')) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Admin access required'},
    );
  }

  final col = MongoClient.instance.collection('productcategories');
  final objId = ModelHelpers.toObjectId(id);
  if (objId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'Invalid ID'},
    );
  }

  if (context.request.method == HttpMethod.put) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final label = body['label']?.toString().trim() ?? '';
      if (label.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'id and label are required'},
        );
      }

      final existing = await col.findOne({
        'label': label,
        '_id': {'\$ne': objId},
      });

      if (existing != null) {
        return Response.json(
          statusCode: HttpStatus.conflict,
          body: {'message': 'Bucket "$label" already exists.'},
        );
      }

      await col.updateOne(
        where.id(objId),
        modify.set('label', label).set('updatedAt', DateTime.now()),
      );

      final updated = await col.findOne(where.id(objId));
      if (updated == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'Bucket not found'},
        );
      }

      return Response.json(
        body: {
          'success': true,
          'message': 'Bucket renamed to "$label" successfully',
          'category': {
            '_id': id,
            'label': updated['label'],
            'sortOrder': updated['sortOrder'],
            if (updated['createdAt'] != null)
              'createdAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(updated['createdAt'])),
            if (updated['updatedAt'] != null)
              'updatedAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(updated['updatedAt'])),
          },
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Server error', 'error': e.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
