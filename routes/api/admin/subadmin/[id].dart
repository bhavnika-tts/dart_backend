import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/repositories/admin_repository.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final authHeader = context.request.headers['authorization'];
  final claims = JwtService.instance.verifyAuthHeader(authHeader);
  if (claims == null || claims.role != 'superadmin') {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Superadmin privileges required'},
    );
  }

  final repo = AdminRepository.instance;

  if (context.request.method == HttpMethod.get) {
    final subadmin = await repo.findAdminById(id);
    if (subadmin == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Subadmin not found'},
      );
    }
    return Response.json(
      body: {'success': true, 'subadmin': subadmin.toJson()},
    );
  }

  if (context.request.method == HttpMethod.put) {
    final body = await context.request.json() as Map<String, dynamic>;
    final updated = await repo.updateAdmin(id, body);
    return Response.json(
      body: {'success': true, 'message': 'Subadmin updated', 'subadmin': updated?.toJson()},
    );
  }

  if (context.request.method == HttpMethod.delete) {
    final success = await repo.deleteAdmin(id);
    return Response.json(
      body: {'success': success, 'message': 'Subadmin deleted successfully'},
    );
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
