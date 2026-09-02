import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/app_guide_video_repository.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final visibility = body['visibility'];

    if (visibility is! bool) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'visibility must be a boolean'},
      );
    }

    final repository = AppGuideVideoRepository.instance;
    final updated = await repository.update(id, {'visibility': visibility});

    if (updated == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Video not found'},
      );
    }

    return Response.json(
      body: {
        'message': 'Video visibility updated',
        'data': updated.toJson(),
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to update visibility', 'error': error.toString()},
    );
  }
}
