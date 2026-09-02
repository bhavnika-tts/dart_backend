import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/models/feature_request.dart';
import 'package:dart_frog_backend/repositories/feedback_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  final repository = FeedbackRepository.instance;
  final method = context.request.method;

  if (method == HttpMethod.get) {
    try {
      final list = await repository.findAll();
      return Response.json(
        body: {
          'success': true,
          'data': list.map((f) => f.toJson()).toList(),
        },
      );
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'message': 'Internal server error', 'error': error.toString()},
      );
    }
  } else if (method == HttpMethod.post) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final title = body['title']?.toString().trim() ?? '';
      final description = body['description']?.toString().trim() ?? '';
      final userId = body['userId']?.toString().trim() ?? 'anonymous';

      if (title.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'message': 'title is required'},
        );
      }

      final created = await repository.create(
        FeatureRequest(
          title: title,
          description: description,
          userId: userId,
        ),
      );

      return Response.json(
        body: {
          'success': true,
          'data': created.toJson(),
        },
      );
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'message': 'Failed to create feedback', 'error': error.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
