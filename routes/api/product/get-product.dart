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
    final limit = int.tryParse(query['limit'] ?? '20') ?? 20;
    final page = int.tryParse(query['page'] ?? '1') ?? 1;
    final cursor = query['cursor'];
    final cursorId = query['cursorId'];
    final search = query['search'];
    final category = query['category'] ?? query['categories'];
    final state = query['state'] ?? context.request.headers['state'];
    final district = query['district'] ?? context.request.headers['district'];
    final locationName = query['locationName'] ?? context.request.headers['area'];

    final service = ProductService.instance;
    final result = await service.getAllProducts(
      userId: userId,
      limit: limit,
      page: page,
      cursor: cursor,
      cursorId: cursorId,
      search: search,
      category: category,
      state: state,
      district: district,
      locationName: locationName,
    );

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
