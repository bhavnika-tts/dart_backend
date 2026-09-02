import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/product_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final productId = body['productId']?.toString().trim();
    var userId = body['userId']?.toString().trim();

    if (userId == null || userId.isEmpty) {
      final authHeader = context.request.headers['authorization'];
      final claims = JwtService.instance.verifyAuthHeader(authHeader);
      if (claims != null) {
        userId = claims.userId;
      }
    }

    if (productId == null || productId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'productId is required'},
      );
    }

    final service = ProductService.instance;
    await service.trackProductView(productId, userId ?? 'anonymous');

    return Response.json(
      body: {'success': true, 'message': 'View tracked successfully'},
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to track view', 'error': error.toString()},
    );
  }
}
