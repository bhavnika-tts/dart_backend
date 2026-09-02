import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final userId = body['userId']?.toString().trim() ?? '';
    final pin = body['pin']?.toString().trim() ?? '';

    if (userId.isEmpty || pin.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'User ID and PIN are required'},
      );
    }

    final service = AuthService.instance;
    await service.verifyPin(userId: userId, pin: pin);

    return Response.json(
      body: {'message': 'PIN verified successfully'},
    );
  } catch (error) {
    final msg = error is StateError ? error.message : error.toString();
    final status = msg.contains('not found') ? HttpStatus.notFound : HttpStatus.badRequest;
    return Response.json(
      statusCode: status,
      body: {'message': msg},
    );
  }
}
