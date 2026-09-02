import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/product_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final query = context.request.uri.queryParameters;
    final productId = query['productId'] ?? query['id'] ?? query['_id'];

    if (productId == null || productId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'productId is required'},
      );
    }

    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);

    final service = ProductService.instance;
    final result = await service.getProductById(productId, currentUserId: claims?.userId);

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
