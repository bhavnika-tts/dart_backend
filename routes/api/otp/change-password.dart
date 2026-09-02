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
    final newPassword = body['newPassword']?.toString() ?? '';
    final confirmPassword = body['confirmPassword']?.toString() ?? '';
    final category = body['category']?.toString().trim() ?? '';

    if (email.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Email is required to reset password.'},
      );
    }
    if (category.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'User category is required to reset password.'},
      );
    }
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Both password fields are required.'},
      );
    }

    final service = AuthService.instance;
    await service.changePassword(
      email: email,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
      category: category,
    );

    return Response.json(
      body: {'message': 'Password reset successfully.'},
    );
  } catch (error) {
    final msg = error is ArgumentError
        ? error.message.toString()
        : error is StateError
            ? error.message
            : error.toString();
    final status = msg.contains('not found') ? HttpStatus.notFound : HttpStatus.badRequest;
    return Response.json(
      statusCode: status,
      body: {'message': msg},
    );
  }
}
