import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/product_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);

    final contentType = context.request.headers['content-type'] ?? '';
    final body = <String, dynamic>{};
    final imageBytes = <Uint8List>[];
    final imageNames = <String>[];

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
          imageBytes.add(Uint8List.fromList(await entry.value.readAsBytes()));
          imageNames.add(entry.value.name);
        }
      }
    } else {
      final json = await context.request.json() as Map<String, dynamic>;
      body.addAll(json);
    }

    if (claims != null && (body['userId'] == null || body['userId'].toString().isEmpty)) {
      body['userId'] = claims.userId;
    }

    final service = ProductService.instance;
    final result = await service.addProduct(
      rawData: body,
      imageBytesList: imageBytes,
      imageNames: imageNames,
    );

    return Response.json(
      statusCode: HttpStatus.created,
      body: result,
    );
  } catch (error) {
    final msg = error is ArgumentError
        ? error.message.toString()
        : error is StateError
            ? error.message
            : error.toString();

    final status = msg.contains('not found') ? HttpStatus.notFound : HttpStatus.badRequest;
    return Response.json(
      statusCode: status,
      body: {'message': msg},
    );
  }
}
