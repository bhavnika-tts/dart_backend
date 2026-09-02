import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/chat_service.dart';

Future<Response> onRequest(RequestContext context, String userId) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final service = ChatService.instance;
    final conversations = await service.getUserConversations(userId);

    return Response.json(
      body: {
        'success': true,
        'message': 'Conversations fetched successfully',
        'conversations': conversations,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch conversations', 'error': error.toString()},
    );
  }
}
