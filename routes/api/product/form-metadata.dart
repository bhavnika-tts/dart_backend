import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/product_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final query = context.request.uri.queryParameters;
    final productTypeId = query['productTypeId'] ?? query['productType'];
    final subProductTypeId = query['subProductTypeId'] ?? query['subProductType'];

    if (productTypeId == null || productTypeId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'productTypeId is required'},
      );
    }

    final meta = await ProductService.instance.getFormMetadata(
      productTypeId,
      subProductTypeId: subProductTypeId,
    );

    if (meta == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Form metadata not found'},
      );
    }

    return Response.json(
      body: {
        'success': true,
        'metadata': meta,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch form metadata', 'error': error.toString()},
    );
  }
}
