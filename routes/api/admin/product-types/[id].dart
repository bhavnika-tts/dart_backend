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

  final col = MongoClient.instance.collection('producttypes');
  final subCol = MongoClient.instance.collection('subproducttypes');
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
          body: {'message': 'A category with this name already exists'},
        );
      }

      await col.updateOne(
        where.id(objId),
        modify.set('name', name).set('updatedAt', DateTime.now()),
      );

      final updated = await col.findOne(where.id(objId));
      if (updated == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'Category not found'},
        );
      }

      return Response.json(
        body: {
          'message': 'Category updated successfully',
          'success': true,
          'data': {
            '_id': id,
            'name': updated['name'],
            'modelName': updated['modelName'],
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

  if (context.request.method == HttpMethod.delete) {
    try {
      final subcats = await subCol.find({
        'productType': objId,
        'isDeleted': {'\$ne': true},
      }).toList();

      if (subcats.isNotEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {
            'message':
                'Cannot delete a category that contains active sub-categories. Please delete or move them first.',
          },
        );
      }

      final target = await col.findOne(where.id(objId));
      if (target == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'Category not found'},
        );
      }

      await col.deleteOne(where.id(objId));

      return Response.json(
        body: {
          'message': 'Category deleted successfully',
          'success': true,
          'data': {
            '_id': id,
            'name': target['name'],
            'modelName': target['modelName'],
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
