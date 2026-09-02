import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/user_repository.dart';

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

    final userRepo = UserRepository.instance;
    final user = await userRepo.findById(userId);

    if (user == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'User not found'},
      );
    }

    await userRepo.update(userId, {
      'otpRequested': true,
      'otpRequestedAt': DateTime.now(),
      'otpRequestCount': user.otpRequestCount + 1,
    });

    return Response.json(
      body: {'message': 'OTP requested from admin. Please wait for approval.'},
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to request OTP', 'error': error.toString()},
    );
  }
}
