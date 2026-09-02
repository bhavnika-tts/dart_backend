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
    final productId = body['productId']?.toString().trim() ?? body['id']?.toString().trim();
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
    await service.toggleProductVisibility(productId, userId ?? '');

    return Response.json(
      body: {'message': 'Product status updated successfully'},
    );
  } catch (error) {
    final msg = error is StateError ? error.message : error.toString();
    final status = msg.contains('not found') ? HttpStatus.notFound : HttpStatus.internalServerError;
    return Response.json(
      statusCode: status,
      body: {'message': msg},
    );
  }
}
