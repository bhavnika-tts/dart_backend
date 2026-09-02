import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/brand_model_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final productType = context.request.uri.queryParameters['productType'];
    if (productType == null || productType.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'productType query param is required'},
      );
    }

    final repository = BrandModelRepository.instance;
    final result = await repository.getBrandsForType(productType);

    return Response.json(
      body: {
        'brands': result.brands,
        'fromCache': result.fromCache,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error', 'error': error.toString()},
    );
  }
}
