import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/admin_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email']?.toString() ?? '';
    final password = body['password']?.toString() ?? '';

    if (email.isEmpty || password.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Email and password are required'},
      );
    }

    final service = AdminService.instance;
    final result = await service.login(email: email, password: password);

    return Response.json(body: result);
  } catch (error) {
    final msg = error is StateError ? error.message : error.toString();
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'message': msg},
    );
  }
}
