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
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin' && claims.role != 'admin')) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    final query = context.request.uri.queryParameters;
    String userId = query['userId']?.toString().trim() ?? '';
    String? rejectionReason;

    try {
      final body = await context.request.json() as Map<String, dynamic>;
      if (userId.isEmpty) {
        userId = body['userId']?.toString().trim() ?? '';
      }
      rejectionReason = body['rejectionReason']?.toString();
    } catch (_) {}

    if (userId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'User ID is required'},
      );
    }

    final userCol = MongoClient.instance.collection('users');
    final userObjId = ModelHelpers.toObjectId(userId);
    final user = await userCol.findOne(userObjId != null ? where.id(userObjId) : where.eq('_id', userId));

    if (user == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'User not found'},
      );
    }

    bool newVerified;
    String finalReason = '';

    if (rejectionReason != null && rejectionReason.trim().isNotEmpty) {
      newVerified = false;
      finalReason = rejectionReason;
    } else {
      final curVerified = user['verified_by_admin'] == true;
      newVerified = !curVerified;
      if (newVerified) {
        finalReason = '';
      }
    }

    await userCol.updateOne(
      where.id(user['_id'] as ObjectId),
      modify
          .set('verified_by_admin', newVerified)
          .set('isVerified', newVerified)
          .set('aadhaarRejectionReason', finalReason)
          .set('updatedAt', DateTime.now().toUtc()),
    );

    return Response.json(
      body: {
        'success': true,
        'message': (rejectionReason != null && rejectionReason.trim().isNotEmpty)
            ? 'User Aadhaar rejected successfully'
            : 'User ${newVerified ? 'verified' : 'unverified'} successfully',
        'verified_by_admin': newVerified,
        'aadhaarRejectionReason': finalReason,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'message': 'Server Error', 'error': error.toString()},
    );
  }
}
