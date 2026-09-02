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
    final productId = body['productId']?.toString().trim();

    if (senderId == null || senderId.isEmpty) {
      final authHeader = context.request.headers['authorization'];
      final claims = JwtService.instance.verifyAuthHeader(authHeader);
      if (claims != null) {
        senderId = claims.userId;
      }
    }

    if (senderId == null || senderId.isEmpty || receiverId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'senderId and receiverId are required'},
      );
    }

    final service = ChatService.instance;
    final conv = await service.fetchConversationId(
      senderId: senderId,
      receiverId: receiverId,
      productId: productId,
    );

    return Response.json(
      body: {
        'success': true,
        'conversationId': conv.id,
        'conversation': conv.toJson(),
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch conversation ID', 'error': error.toString()},
    );
  }
}
