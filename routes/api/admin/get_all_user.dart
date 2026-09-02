import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/admin_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
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

    final query = context.request.uri.queryParameters;
    final limit = int.tryParse(query['limit'] ?? '100') ?? 100;
    final page = int.tryParse(query['page'] ?? '1') ?? 1;
    final category = query['userCategory'] ?? query['category'];

    final users = await AdminService.instance.getAllUsers(
      limit: limit,
      page: page,
      category: category,
    );

    return Response.json(
      body: {
        'success': true,
        'count': users.length,
        'users': users,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch users', 'error': error.toString()},
    );
  }
}
