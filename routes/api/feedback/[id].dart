import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/feedback_repository.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final repository = FeedbackRepository.instance;
  final method = context.request.method;

  if (method == HttpMethod.get) {
    try {
      final item = await repository.findById(id);
      if (item == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'success': false, 'message': 'Feature request not found'},
        );
      }
      return Response.json(
        body: {
          'success': true,
          'data': item.toJson(),
        },
      );
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'message': 'Internal server error', 'error': error.toString()},
      );
    }
  } else if (method == HttpMethod.delete) {
    try {
      final ok = await repository.delete(id);
      if (!ok) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'success': false, 'message': 'Feature request not found'},
        );
      }
      return Response.json(
        body: {
          'success': true,
          'data': <String, dynamic>{},
        },
      );
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'message': 'Failed to delete feedback', 'error': error.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
