import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.put && context.request.method != HttpMethod.delete) {
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

    final objId = ModelHelpers.toObjectId(id);
    final col = MongoClient.instance.collection('formmetadatas');

    Map<String, dynamic>? existing;
    if (objId != null) {
      existing = await col.findOne(where.id(objId));
    }
    existing ??= await col.findOne(where.eq('_id', id));

    if (existing == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Field metadata not found'},
      );
    }

    if (context.request.method == HttpMethod.delete) {
      if (existing['isSystemField'] == true) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'Cannot delete a locked field. Please unlock it from the admin panel first.'},
        );
      }
      final key = existing['key']?.toString();
      if (key == 'title' || key == 'description' || key == 'price') {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'Cannot delete core fields (title, description, price).'},
        );
      }

      await col.deleteOne(where.id(existing['_id'] as ObjectId));
      return Response.json(
        body: {'message': 'Field metadata deleted successfully'},
      );
    }

    // PUT
    final updates = await context.request.json() as Map<String, dynamic>;

    if (existing['isSystemField'] == true) {
      final keys = updates.keys.where((k) => k != 'id' && k != '_id').toList();
      final isUnlockingOnly = keys.length == 1 && keys[0] == 'isSystemField' && updates['isSystemField'] == false;
      if (!isUnlockingOnly) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {
            'message': 'Field is currently locked. Please unlock it from the admin panel first to modify its configurations.',
          },
        );
      }
    }

    final mod = modify.set('updatedAt', DateTime.now().toUtc());
    for (final entry in updates.entries) {
      if (entry.key == 'id' || entry.key == '_id') continue;
      if (entry.key == 'subProductType') {
        if (entry.value == '' || entry.value == 'null' || entry.value == null) {
          mod.set('subProductType', null);
        } else {
          mod.set('subProductType', entry.value);
        }
      } else {
        mod.set(entry.key, entry.value);
      }
    }

    await col.updateOne(where.id(existing['_id'] as ObjectId), mod);

    final updated = await col.findOne(where.id(existing['_id'] as ObjectId));
    final sanitized = Map<String, dynamic>.from(updated ?? existing);
    sanitized['_id'] = ModelHelpers.idToString(sanitized['_id']);
    if (sanitized['createdAt'] is DateTime) {
      sanitized['createdAt'] = (sanitized['createdAt'] as DateTime).toIso8601String();
    }
    if (sanitized['updatedAt'] is DateTime) {
      sanitized['updatedAt'] = (sanitized['updatedAt'] as DateTime).toIso8601String();
    }

    return Response.json(
      body: {
        'message': 'Field metadata updated successfully',
        'field': sanitized,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error!', 'error': error.toString()},
    );
  }
}
