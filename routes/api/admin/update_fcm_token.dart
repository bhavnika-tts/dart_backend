import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
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
    final deviceToken = body['deviceToken']?.toString() ?? body['fcmToken']?.toString();

    if (deviceToken == null || deviceToken.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Device token is required'},
      );
    }

    final adminObjId = ModelHelpers.toObjectId(claims.userId);
    if (adminObjId != null) {
      final col = MongoClient.instance.collection('admins');
      await col.updateOne(
        where.id(adminObjId),
        modify.set('deviceToken', deviceToken),
      );
    }

    return Response.json(
      body: {
        'message': 'FCM token updated successfully',
        'success': true,
        'data': {
          'deviceToken': deviceToken,
        },
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Internal server error', 'error': error.toString()},
    );
  }
}
