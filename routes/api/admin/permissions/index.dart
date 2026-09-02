import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/repositories/admin_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);

    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Unauthorized'},
      );
    }

    final admin = await AdminRepository.instance.findAdminById(claims.userId);
    if (admin == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Admin not found'},
      );
    }

    if (admin.role == 'superadmin') {
      return Response.json(
        body: {
          'message': 'Permissions fetched successfully',
          'role': 'superadmin',
          'username': admin.username,
          'email': admin.email,
          'passwordChangedAt': admin.passwordChangedAt?.toIso8601String(),
          'permissions': null,
        },
      );
    }

    final permDoc = await AdminRepository.instance.getAdminPermissions(admin.id!);
    return Response.json(
      body: {
        'message': 'Permissions fetched successfully',
        'role': admin.role,
        'username': admin.username,
        'email': admin.email,
        'passwordChangedAt': admin.passwordChangedAt?.toIso8601String(),
        'permissions': permDoc != null
            ? {
                ...permDoc.permissions.map((k, v) => MapEntry(k, v.toMap())),
                'assigned_access_codes': permDoc.assignedAccessCodes,
              }
            : <String, dynamic>{},
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error', 'error': error.toString()},
    );
  }
}
