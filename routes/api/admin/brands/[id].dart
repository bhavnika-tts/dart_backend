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

  final col = MongoClient.instance.collection('brandmodels');
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
      final entry = await col.findOne(where.id(objId));
      if (entry == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'Brand not found'},
        );
      }

      final modifier = modify.set('updatedAt', DateTime.now());
      if (body.containsKey('brand')) modifier.set('brand', body['brand']);
      if (body.containsKey('models')) modifier.set('models', body['models']);
      if (body.containsKey('displayOrder')) {
        modifier.set('displayOrder', int.tryParse(body['displayOrder'].toString()) ?? 999);
      }
      if (body.containsKey('isActive')) modifier.set('isActive', body['isActive'] == true || body['isActive'] == 'true');

      await col.updateOne(where.id(objId), modifier);
      final updated = await col.findOne(where.id(objId));

      final cleanDoc = <String, dynamic>{};
      updated?.forEach((k, v) {
        if (k == '_id') {
          cleanDoc['_id'] = ModelHelpers.idToString(v);
        } else if (v is DateTime) {
          cleanDoc[k] = ModelHelpers.toIsoString(v);
        } else {
          cleanDoc[k] = v;
        }
      });

      return Response.json(
        body: {
          'message': 'Brand updated successfully',
          'entry': cleanDoc,
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Server error', 'error': e.toString()},
      );
    }
  }

  if (context.request.method == HttpMethod.delete) {
    try {
      final entry = await col.findOne(where.id(objId));
      if (entry == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'Brand not found'},
        );
      }

      await col.updateOne(
        where.id(objId),
        modify.set('isActive', false).set('updatedAt', DateTime.now()),
      );

      return Response.json(
        body: {'message': 'Brand deactivated successfully'},
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
