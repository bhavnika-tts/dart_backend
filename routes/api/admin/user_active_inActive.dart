import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/repositories/admin_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin' && claims.role != 'admin')) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final userId = body['userId']?.toString().trim() ?? '';
    final isActive = body['isActive'] == true || body['active'] == true || body['status'] == 'Active';

    if (userId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'userId is required'},
      );
    }

    await AdminRepository.instance.toggleUserActive(userId, isActive: isActive);

    return Response.json(
      body: {
        'success': true,
        'message': isActive ? 'User activated successfully' : 'User deactivated successfully',
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Operation failed', 'error': error.toString()},
    );
  }
}
