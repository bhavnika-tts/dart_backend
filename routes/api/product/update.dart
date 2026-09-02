import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/product_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);

    final contentType = context.request.headers['content-type'] ?? '';
    final body = <String, dynamic>{};
    final newImageBytes = <Uint8List>[];
    final newImageNames = <String>[];

    if (contentType.contains('multipart/form-data')) {
      final formData = await context.request.formData();
      body.addAll(formData.fields);

      if (formData.fields['data'] != null) {
        try {
          final parsed = jsonDecode(formData.fields['data']!) as Map<String, dynamic>;
          body.addAll(parsed);
        } catch (_) {}
      }

      for (final entry in formData.files.entries) {
        if (entry.key == 'images' || entry.key.startsWith('images[')) {
          newImageBytes.add(Uint8List.fromList(await entry.value.readAsBytes()));
          newImageNames.add(entry.value.name);
        }
      }
    } else {
      final json = await context.request.json() as Map<String, dynamic>;
      body.addAll(json);
    }

    final productId = body['productId']?.toString().trim() ?? body['id']?.toString().trim() ?? '';
    if (productId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Product ID is required'},
      );
    }

    if (claims != null && (body['userId'] == null || body['userId'].toString().isEmpty)) {
      body['userId'] = claims.userId;
    }

    final service = ProductService.instance;
    final result = await service.updateProduct(
      productId: productId,
      rawData: body,
      newImageBytesList: newImageBytes,
      newImageNames: newImageNames,
    );

    return Response.json(body: result);
  } catch (error) {
    final msg = error is StateError ? error.message : error.toString();
    final status = msg.contains('not found') ? HttpStatus.notFound : HttpStatus.badRequest;
    return Response.json(
      statusCode: status,
      body: {'message': msg},
    );
  }
}
