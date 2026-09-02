import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/product_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final types = await ProductRepository.instance.getProductTypes();
    return Response.json(
      body: {
        'success': true,
        'message': 'Product types fetched successfully',
        'data': types.map((t) => t.toJson()).toList(),
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch product types', 'error': error.toString()},
    );
  }
}
