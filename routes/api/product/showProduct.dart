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
    var userId = query['userId'];
    if (userId == null || userId.isEmpty) {
      final authHeader = context.request.headers['authorization'];
      final claims = JwtService.instance.verifyAuthHeader(authHeader);
      if (claims != null) {
        userId = claims.userId;
      }
    }

    final result = await ProductService.instance.getAllProducts(
      userId: userId ?? 'anonymous',
      search: query['search'],
      state: query['state'],
      district: query['district'],
      locationName: query['locationName'],
    );

    final products = result['products'] as List? ?? [];
    if (products.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'No products found'},
      );
    }

    return Response.json(body: products);
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Internal Server Error', 'error': error.toString()},
    );
  }
}
