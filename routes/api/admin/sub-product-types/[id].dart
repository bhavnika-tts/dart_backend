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

  final subCol = MongoClient.instance.collection('subproducttypes');
  final prodTypeCol = MongoClient.instance.collection('producttypes');
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
      final name = body['name']?.toString() ?? '';
      if (name.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'ID and Name are required'},
        );
      }

      final updateModifier = modify
          .set('name', name)
          .set('updatedAt', DateTime.now());

      if (claims.userId.isNotEmpty) {
        final adminObj = ModelHelpers.toObjectId(claims.userId);
        updateModifier
            .set('lastEditedBy', adminObj)
            .push('history', {'updatedBy': adminObj, 'updatedAt': DateTime.now()});
      }

      final updateRes = await subCol.updateOne(where.id(objId), updateModifier);
      if (updateRes.nModified == 0) {
        final check = await subCol.findOne(where.id(objId));
        if (check == null) {
          return Response.json(
            statusCode: HttpStatus.notFound,
            body: {'message': 'Sub product type not found'},
          );
        }
      }

      final updatedDoc = await subCol.findOne(where.id(objId));
      if (updatedDoc == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'Sub product type not found'},
        );
      }

      final ptVal = updatedDoc['productType'];
      final ptObj = ptVal is ObjectId ? ptVal : ModelHelpers.toObjectId(ptVal?.toString());
      final ptDoc = ptObj != null ? await prodTypeCol.findOne(where.id(ptObj)) : null;

      final data = <String, dynamic>{
        '_id': id,
        'name': updatedDoc['name'],
        'productType': ptDoc != null
            ? {
                '_id': ModelHelpers.idToString(ptDoc['_id']),
                'name': ptDoc['name'],
                'modelName': ptDoc['modelName'],
              }
            : ptVal?.toString(),
        'isDeleted': updatedDoc['isDeleted'] ?? false,
        if (updatedDoc['createdAt'] != null)
          'createdAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(updatedDoc['createdAt'])),
        if (updatedDoc['updatedAt'] != null)
          'updatedAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(updatedDoc['updatedAt'])),
      };

      return Response.json(
        body: {
          'message': 'Sub product type name updated successfully',
          'success': true,
          'data': data,
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
      final updateModifier = modify
          .set('isDeleted', true)
          .set('updatedAt', DateTime.now());

      if (claims.userId.isNotEmpty) {
        final adminObj = ModelHelpers.toObjectId(claims.userId);
        updateModifier
            .set('lastEditedBy', adminObj)
            .push('history', {'updatedBy': adminObj, 'updatedAt': DateTime.now()});
      }

      await subCol.updateOne(where.id(objId), updateModifier);
      final doc = await subCol.findOne(where.id(objId));
      if (doc == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'Sub product type not found'},
        );
      }

      final data = <String, dynamic>{
        '_id': id,
        'name': doc['name'],
        'isDeleted': true,
        if (doc['createdAt'] != null)
          'createdAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(doc['createdAt'])),
        if (doc['updatedAt'] != null)
          'updatedAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(doc['updatedAt'])),
      };

      return Response.json(
        body: {
          'message': 'Sub product type soft-deleted successfully',
          'success': true,
          'data': data,
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
