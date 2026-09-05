import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin' && claims.role != 'admin')) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Invalid ID'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final status = body['status']?.toString().toLowerCase() ?? '';
    final statusMessage = body['statusMessage']?.toString() ?? '';

    if (!['pending', 'accepted', 'declined'].contains(status)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': "Invalid status. Must be 'pending', 'accepted', or 'declined'"},
      );
    }

    final col = MongoClient.instance.collection('featurerequests');
    await col.updateOne(
      where.id(objId),
      modify
          .set('status', status)
          .set('statusMessage', statusMessage)
          .set('updatedAt', DateTime.now()),
    );

    final updated = await col.findOne(where.id(objId));
    if (updated == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Feature request not found'},
      );
    }

    return Response.json(
      body: {
        'success': true,
        'data': {
          '_id': id,
          'title': updated['title'],
          'description': updated['description'],
          'status': updated['status'],
          'statusMessage': updated['statusMessage'],
          'userId': updated['userId']?.toString(),
          if (updated['createdAt'] != null)
            'createdAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(updated['createdAt'])),
          if (updated['updatedAt'] != null)
            'updatedAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(updated['updatedAt'])),
        },
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error', 'error': error.toString()},
    );
  }
}
