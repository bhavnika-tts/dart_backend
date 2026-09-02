import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/chat_repository.dart';
import 'package:dart_frog_backend/services/imagekit_service.dart';

Future<Response> onRequest(RequestContext context, String conversationId) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final conv = await ChatRepository.instance.findConversationById(conversationId);
    if (conv == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Conversation not found'},
      );
    }

    final signed = ImageKitService.instance.signImageKitUrls(conv.toJson());

    return Response.json(
      body: {
        'success': true,
        'conversation': signed,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch conversation', 'error': error.toString()},
    );
  }
}
