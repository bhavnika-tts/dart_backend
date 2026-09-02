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
    final otp = body['otp']?.toString().trim() ?? '';
    final category = body['category']?.toString().trim() ?? '';

    if (email.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Email is required for OTP verification.'},
      );
    }
    if (category.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'User category is required for OTP verification.'},
      );
    }
    if (otp.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'OTP is required for verification.'},
      );
    }

    final service = AuthService.instance;
    await service.verifyForgotPasswordOtp(
      email: email,
      otp: otp,
      category: category,
    );

    return Response.json(
      body: {'message': 'OTP verified successfully.'},
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
