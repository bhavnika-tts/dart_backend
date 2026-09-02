import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/product_service.dart';

Future<Response> onRequest(RequestContext context, String productId, String productType) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);

    var userId = context.request.uri.queryParameters['userId'] ?? context.request.uri.queryParameters['addProductUserId'];
    if (userId == null || userId.isEmpty) {
      if (claims != null) {
        userId = claims.userId;
      }
    }

    if (userId == null || userId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'userId is required'},
      );
    }

    final service = ProductService.instance;
    await service.deleteProduct(productId, userId);

    return Response.json(
      body: {'message': 'Product successfully deleted'},
    );
  } catch (error) {
    final msg = error is StateError ? error.message : error.toString();
    final status = msg.contains('not found')
        ? HttpStatus.notFound
        : msg.contains('only delete your own')
            ? HttpStatus.forbidden
            : HttpStatus.internalServerError;

    return Response.json(
      statusCode: status,
      body: {'message': msg},
    );
  }
}
