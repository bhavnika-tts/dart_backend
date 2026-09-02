import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/app_guide_video_repository.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final repository = AppGuideVideoRepository.instance;

    final updated = await repository.update(id, body);
    if (updated == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Video not found'},
      );
    }

    return Response.json(
      body: {
        'message': 'Video details updated successfully',
        'data': updated.toJson(),
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to update video details', 'error': error.toString()},
    );
  }
}
