import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/chat_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    var senderId = body['senderId']?.toString().trim();
    final receiverId = body['receiverId']?.toString().trim() ?? '';
    final conversationId = body['conversationId']?.toString().trim() ?? body['chatId']?.toString().trim() ?? '';
    final text = body['text']?.toString() ?? body['content']?.toString() ?? '';
    final type = body['messageType']?.toString() ?? body['type']?.toString() ?? 'text';
    final productId = body['productId']?.toString().trim();

    if (senderId == null || senderId.isEmpty) {
      final authHeader = context.request.headers['authorization'];
      final claims = JwtService.instance.verifyAuthHeader(authHeader);
      if (claims != null) {
        senderId = claims.userId;
      }
    }

    if (senderId == null || senderId.isEmpty || receiverId.isEmpty || conversationId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'senderId, receiverId, and conversationId are required'},
      );
    }

    final service = ChatService.instance;
    final result = await service.sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      conversationId: conversationId,
      text: text,
      type: type,
      productId: productId,
    );

    return Response.json(body: result);
  } catch (error) {
    final msg = error is ArgumentError ? error.message.toString() : error.toString();
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': msg},
    );
  }
}
