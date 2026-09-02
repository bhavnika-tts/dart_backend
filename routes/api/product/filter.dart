import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/product_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    var userId = context.request.uri.queryParameters['userId'];
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

    final query = context.request.uri.queryParameters;
    final result = await ProductService.instance.getAllProducts(
      userId: userId,
      limit: int.tryParse(query['limit'] ?? '20') ?? 20,
      page: int.tryParse(query['page'] ?? '1') ?? 1,
      search: query['search'],
      category: query['category'] ?? query['categories'],
      state: query['state'],
      district: query['district'],
      locationName: query['locationName'],
    );

    return Response.json(body: result);
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Filter failed', 'error': error.toString()},
    );
  }
}
