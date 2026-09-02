import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/app_guide_video_repository.dart';
import 'package:dart_frog_backend/services/imagekit_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final repository = AppGuideVideoRepository.instance;
    final video = await repository.findById(id);

    if (video == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Video not found'},
      );
    }

    if (video.videoName.isNotEmpty) {
      await ImageKitService.instance.deleteFromImageKit(video.videoName);
    }

    await repository.delete(id);
    return Response.json(body: {'message': 'Video deleted successfully'});
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to delete video', 'error': error.toString()},
    );
  }
}
