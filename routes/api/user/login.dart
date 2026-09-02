import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final phone = body['phone']?.toString().trim();
    final email = body['email']?.toString().trim();
    final password = body['password']?.toString() ?? '';
    final userCategory = body['userCategory']?.toString().trim();

    final identifier = (phone != null && phone.isNotEmpty) ? phone : (email ?? '');

    if (identifier.isEmpty || password.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Phone/Email and password are required'},
      );
    }

    final service = AuthService.instance;
    final result = await service.login(
      identifier: identifier,
      password: password,
      userCategory: userCategory,
    );

    return Response.json(body: result);
  } catch (error) {
    final msg = error is StateError ? error.message : error.toString();
    final status = msg.contains('not found') || msg.contains('Invalid')
        ? HttpStatus.badRequest
        : msg.contains('blocked')
            ? HttpStatus.forbidden
            : HttpStatus.internalServerError;

    return Response.json(
      statusCode: status,
      body: {'message': msg},
    );
  }
}
