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
    var userId = body['userId']?.toString().trim();
    final productId = body['productId']?.toString().trim() ?? body['id']?.toString().trim();

    if (userId == null || userId.isEmpty) {
      final authHeader = context.request.headers['authorization'];
      final claims = JwtService.instance.verifyAuthHeader(authHeader);
      if (claims != null) {
        userId = claims.userId;
      }
    }

    if (userId == null || userId.isEmpty || productId == null || productId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'userId and productId are required'},
      );
    }

    final service = ProductService.instance;
    final result = await service.toggleFavorite(userId, productId);

    return Response.json(body: result);
  } catch (error) {
    final msg = error is StateError ? error.message : error.toString();
    final status = msg.contains('not found') ? HttpStatus.notFound : HttpStatus.internalServerError;
    return Response.json(
      statusCode: status,
      body: {'message': msg},
    );
  }
}
