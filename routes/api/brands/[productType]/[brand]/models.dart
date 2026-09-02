import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/brand_model_repository.dart';

Future<Response> onRequest(
  RequestContext context,
  String productType,
  String brand,
) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    if (productType.isEmpty || brand.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'productType and brand are required'},
      );
    }

    final repository = BrandModelRepository.instance;
    final result = await repository.getModelsForBrand(productType, brand);

    return Response.json(
      body: {
        'models': result.models,
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
