import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/app_guide_video_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final repository = AppGuideVideoRepository.instance;
    final video = await repository.findVisible();

    if (video == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'No visible video found', 'data': null},
      );
    }

    return Response.json(
      body: {
        'message': 'Visible video fetched',
        'data': video.toJson(),
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch visible video', 'error': error.toString()},
    );
  }
}
