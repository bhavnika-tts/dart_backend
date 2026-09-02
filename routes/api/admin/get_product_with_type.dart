import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/product_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final query = context.request.uri.queryParameters;
    final productTypeId = query['productTypeId'];
    final category = query['category'];
    final limit = int.tryParse(query['limit'] ?? '50') ?? 50;
    final page = int.tryParse(query['page'] ?? '1') ?? 1;

    final result = await ProductService.instance.getAllProducts(
      userId: 'admin',
      category: category,
      productType: productTypeId,
      limit: limit,
      page: page,
    );

    final products = result['products'] as List? ?? [];

    return Response.json(
      body: {
        'success': true,
        'count': products.length,
        'products': products,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch products', 'error': error.toString()},
    );
  }
}
