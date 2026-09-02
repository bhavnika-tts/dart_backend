import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/app_guide_video_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final repository = AppGuideVideoRepository.instance;
    final videos = await repository.findAll();

    return Response.json(
      body: {
        'data': videos.map((v) => v.toJson()).toList(),
        'message': 'App guide videos fetched successfully',
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch videos', 'error': error.toString()},
    );
  }
}
