import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/app_version_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final service = AppVersionService.instance;
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
}
