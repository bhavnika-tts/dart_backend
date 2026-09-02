import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/admin_service.dart';

Future<Response> onRequest(RequestContext context, String chatId) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final messages = await AdminService.instance.getSupportMessages(chatId);

    return Response.json(
      body: {
        'success': true,
        'messages': messages,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch messages', 'error': error.toString()},
    );
  }
}
