import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/product_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final query = context.request.uri.queryParameters;
    var productId = query['productId'] ?? query['id'];
    var imageUrl = query['imageUrl'] ?? query['image'];

    if (productId == null || imageUrl == null) {
      try {
        final body = await context.request.json() as Map<String, dynamic>;
        productId ??= body['productId']?.toString();
        imageUrl ??= body['imageUrl']?.toString() ?? body['image']?.toString();
      } catch (_) {}
    }

    if (productId == null || imageUrl == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'productId and imageUrl are required'},
      );
    }

    final service = ProductService.instance;
    await service.deleteProductImage(productId, imageUrl);

    return Response.json(
      body: {'message': 'Image deleted successfully'},
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to delete image', 'error': error.toString()},
    );
  }
}
