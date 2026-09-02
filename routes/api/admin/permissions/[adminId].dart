import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/repositories/admin_repository.dart';

Future<Response> onRequest(RequestContext context, String adminId) async {
  final authHeader = context.request.headers['authorization'];
  final claims = JwtService.instance.verifyAuthHeader(authHeader);
  if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Admin privileges required'},
    );
  }

  final repo = AdminRepository.instance;

  if (context.request.method == HttpMethod.get) {
    final perms = await repo.getAdminPermissions(adminId);
    return Response.json(
      body: {
        'success': true,
        'permissions': perms?.permissions.map((k, v) => MapEntry(k, v.toMap())) ?? {},
      },
    );
  }

  if (context.request.method == HttpMethod.put) {
    if (claims.role != 'superadmin') {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Only superadmins can update permissions'},
      );
    }
    final body = await context.request.json() as Map<String, dynamic>;
    final updated = await repo.updateAdminPermissions(adminId, body);
    return Response.json(
      body: {
        'success': true,
        'message': 'Permissions updated',
        'permissions': updated.permissions.map((k, v) => MapEntry(k, v.toMap())),
      },
    );
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
