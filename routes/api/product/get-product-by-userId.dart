import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/product_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    var userId = context.request.uri.queryParameters['userId'] ?? context.request.uri.queryParameters['addProductUserId'];
    if (userId == null || userId.isEmpty) {
      final authHeader = context.request.headers['authorization'];
      final claims = JwtService.instance.verifyAuthHeader(authHeader);
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
    final products = await service.getProductsByUser(userId);

    return Response.json(
      body: {
        'success': true,
        'message': 'User products fetched successfully',
        'products': products,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch user products', 'error': error.toString()},
    );
  }
}
