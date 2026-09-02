import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email']?.toString().trim() ?? '';
    final category = body['category']?.toString().trim() ?? '';

    if (email.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Email is required'},
      );
    }

    if (category.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'User category is required'},
      );
    }

    final service = AuthService.instance;
    await service.forgotPassword(email: email, category: category);

    return Response.json(
      body: {'message': 'OTP sent successfully to your email'},
    );
  } catch (error) {
    final msg = error is StateError ? error.message : error.toString();
    final status = msg.contains('wait')
        ? HttpStatus.tooManyRequests
        : msg.contains('not exist')
            ? HttpStatus.notFound
            : HttpStatus.internalServerError;

    return Response.json(
      statusCode: status,
      body: {'message': msg},
    );
  }
}
