import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/crypto.dart';
import 'package:dart_frog_backend/repositories/user_repository.dart';
import 'package:dart_frog_backend/services/otp_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email']?.toString().trim() ?? '';
    final category = body['category']?.toString().trim() ?? body['userCategory']?.toString().trim() ?? '';
    final password = body['password']?.toString() ?? body['newPassword']?.toString() ?? '';

    if (email.isEmpty || password.isEmpty || category.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Email, password, and userCategory are required'},
      );
    }

    final userRepo = UserRepository.instance;
    final user = await userRepo.findByEmailAndCategory(email, category);

    if (user == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'User not found'},
      );
    }

    final isVerifiedInRedis = await OtpService.instance.isOtpVerified(
      identifier: email,
      purpose: 'forgot_password',
    );

    if (!isVerifiedInRedis) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'OTP verification required or session expired.'},
      );
    }

    final hashedPassword = CryptoService.instance.hashPassword(password);
    await userRepo.update(user.id!, {
      'password': hashedPassword,
      'tokenVersion': user.tokenVersion + 1,
      'passwordChangedAt': DateTime.now(),
    });

    await OtpService.instance.consumeOtpVerification(
      identifier: email,
      purpose: 'forgot_password',
    );

    return Response.json(
      body: {'message': 'Password updated successfully'},
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to update password', 'error': error.toString()},
    );
  }
}
