import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/about_us_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final service = AboutUsService.instance;
  final method = context.request.method;

  if (method == HttpMethod.get) {
    try {
      final aboutUs = await service.getAboutUsData();
      if (aboutUs == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'About Us information not found'},
        );
      }
      return Response.json(body: aboutUs.toJson());
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Internal server error', 'error': error.toString()},
      );
    }
  } else if (method == HttpMethod.post) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final created = await service.createAboutUsData(body);
      return Response.json(
        statusCode: HttpStatus.created,
        body: created.toJson(),
      );
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to create About Us', 'error': error.toString()},
      );
    }
  } else if (method == HttpMethod.put) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final updated = await service.updateAboutUsData(body);
      if (updated == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'About Us information not found'},
        );
      }
      return Response.json(body: updated.toJson());
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to update About Us', 'error': error.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
