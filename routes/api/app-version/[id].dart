import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/app_version_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final service = AppVersionService.instance;
  final method = context.request.method;

  if (method == HttpMethod.get) {
    try {
      final version = await service.getVersionById(id);
      if (version == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'Version not found'},
        );
      }
      return Response.json(body: version.toJson());
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Internal server error', 'error': error.toString()},
      );
    }
  } else if (method == HttpMethod.put) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final updated = await service.updateVersion(id, body);
      if (updated == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'Version not found'},
        );
      }
      return Response.json(body: updated.toJson());
    } catch (error) {
      if (error is ArgumentError) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': error.message},
        );
      }
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to update version', 'error': error.toString()},
      );
    }
  } else if (method == HttpMethod.delete) {
    try {
      final ok = await service.deleteVersion(id);
      if (!ok) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'message': 'Version not found'},
        );
      }
      return Response.json(body: {'message': 'Version deleted successfully'});
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to delete version', 'error': error.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
