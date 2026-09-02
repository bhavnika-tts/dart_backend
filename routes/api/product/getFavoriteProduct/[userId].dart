import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/product_service.dart';

Future<Response> onRequest(RequestContext context, String userId) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final service = ProductService.instance;
    final products = await service.getFavoriteProducts(userId);

    return Response.json(
      body: {
        'message': 'Favorite products fetched successfully.',
        'products': products,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch favorite products', 'error': error.toString()},
    );
  }
}
