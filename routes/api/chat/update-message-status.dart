import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/chat_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final conversationId = body['conversationId']?.toString().trim() ?? body['chatId']?.toString().trim() ?? '';
    var userId = body['userId']?.toString().trim();

    if (userId == null || userId.isEmpty) {
      final authHeader = context.request.headers['authorization'];
      final claims = JwtService.instance.verifyAuthHeader(authHeader);
      if (claims != null) {
        userId = claims.userId;
      }
    }

    if (conversationId.isEmpty || userId == null || userId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'conversationId and userId are required'},
      );
    }

    await ChatService.instance.updateAllMessagesStatus(conversationId, userId);

    return Response.json(
      body: {'success': true, 'message': 'Message status updated to read'},
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to update message status', 'error': error.toString()},
    );
  }
}
