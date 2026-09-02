import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/admin_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final chatId = body['chatId']?.toString().trim() ?? '';
    var senderId = body['senderId']?.toString().trim();
    final text = body['text']?.toString().trim() ?? body['message']?.toString().trim() ?? '';
    final mediaUrl = body['mediaUrl']?.toString().trim();

    var senderType = 'user';
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims != null) {
      senderId = claims.userId;
      if (claims.role == 'superadmin' || claims.role == 'subadmin' || claims.role == 'admin') {
        senderType = 'admin';
      }
    }

    if (chatId.isEmpty || senderId == null || senderId.isEmpty || text.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'chatId, senderId, and text are required'},
      );
    }

    final result = await AdminService.instance.sendSupportMessage(
      chatId: chatId,
      senderId: senderId,
      senderRole: senderType,
      text: text,
      mediaUrl: mediaUrl,
    );

    return Response.json(body: result);
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to send support message', 'error': error.toString()},
    );
  }
}
