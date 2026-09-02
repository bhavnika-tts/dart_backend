import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/app_version_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final service = AppVersionService.instance;
  final method = context.request.method;

  if (method == HttpMethod.get) {
    try {
      final versions = await service.getAllVersions();
      return Response.json(
        body: {
          'data': versions.map((v) => v.toJson()).toList(),
          'message': 'All versions fetched successfully',
        },
      );
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Internal server error', 'error': error.toString()},
      );
    }
  } else if (method == HttpMethod.post) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final newVersion = await service.createAppVersion(body);
      return Response.json(
        statusCode: HttpStatus.created,
        body: newVersion.toJson(),
      );
    } catch (error) {
      if (error is ArgumentError) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': error.message},
        );
      }
      if (error is StateError) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': error.message},
        );
      }
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to create version', 'error': error.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
