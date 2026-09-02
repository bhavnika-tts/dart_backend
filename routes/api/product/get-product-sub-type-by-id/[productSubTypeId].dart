import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/product_repository.dart';

Future<Response> onRequest(RequestContext context, String productSubTypeId) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final subTypes = await ProductRepository.instance.getSubProductTypes(productSubTypeId);
    return Response.json(
      body: {
        'success': true,
        'message': 'sub product type fetch successfully.',
        'sub_product_types': subTypes.map((s) => s.toJson()).toList(),
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'message': 'Internal server error', 'error': error.toString()},
    );
  }
}
