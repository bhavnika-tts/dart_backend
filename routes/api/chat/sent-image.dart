import 'dart:io';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/chat_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final formData = await context.request.formData();
    final fields = formData.fields;

    var senderId = fields['senderId']?.trim();
    final receiverId = fields['receiverId']?.trim() ?? '';
    final conversationId = fields['conversationId']?.trim() ?? fields['chatId']?.trim() ?? '';
    final productId = fields['productId']?.trim();

    if (senderId == null || senderId.isEmpty) {
      final authHeader = context.request.headers['authorization'];
      final claims = JwtService.instance.verifyAuthHeader(authHeader);
      if (claims != null) {
        senderId = claims.userId;
      }
    }

    final imageFile = formData.files['image'] ?? formData.files['file'];
    if (imageFile == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'image file is required'},
      );
    }

    if (senderId == null || senderId.isEmpty || receiverId.isEmpty || conversationId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'senderId, receiverId, and conversationId are required'},
      );
    }

    final imageBytes = Uint8List.fromList(await imageFile.readAsBytes());
    final service = ChatService.instance;

    final result = await service.sendImageMessage(
      senderId: senderId,
      receiverId: receiverId,
      conversationId: conversationId,
      imageBytes: imageBytes,
      fileName: imageFile.name,
      productId: productId,
    );

    return Response.json(body: result);
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to send image', 'error': error.toString()},
    );
  }
}
