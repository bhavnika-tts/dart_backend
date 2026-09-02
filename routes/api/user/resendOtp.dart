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

    if (userId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'userId is required'},
      );
    }

    final service = AuthService.instance;
    await service.resendOtp(userId: userId);

    return Response.json(
      body: {'message': 'OTP resent successfully'},
    );
  } catch (error) {
    final msg = error is StateError ? error.message : error.toString();
    final status = msg.contains('wait')
        ? HttpStatus.tooManyRequests
        : msg.contains('not found')
            ? HttpStatus.notFound
            : HttpStatus.internalServerError;

    return Response.json(
      statusCode: status,
      body: {'message': msg},
    );
  }
}
