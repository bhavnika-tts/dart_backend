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

  final col = MongoClient.instance.collection('occupations');
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
      final name = body['name']?.toString().trim() ?? '';
      if (name.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'ID and Name are required'},
        );
      }

      final existing = await col.findOne({
        'name': {'\$regex': '^$name\$', '\$options': 'i'},
        '_id': {'\$ne': objId},
      });

      if (existing != null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'Occupation already exists'},
        );
      }

      final updateModifier = modify
          .set('name', name)
          .set('updatedAt', DateTime.now());

      if (claims.userId.isNotEmpty) {
        final adminObj = ModelHelpers.toObjectId(claims.userId);
        updateModifier
            .set('updatedBy', adminObj)
            .push('history', {'updatedBy': adminObj, 'updatedAt': DateTime.now()});
      }

      await col.updateOne(where.id(objId), updateModifier);

      final updated = await col.findOne(where.id(objId));
      if (updated == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'Occupation not found'},
        );
      }

      return Response.json(
        body: {
          'success': true,
          'message': 'Occupation updated',
          'data': {
            '_id': id,
            'name': updated['name'],
            if (updated['createdBy'] != null) 'createdBy': updated['createdBy'].toString(),
            if (updated['updatedBy'] != null) 'updatedBy': updated['updatedBy'].toString(),
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
        body: {'message': 'Server error!', 'error': e.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
