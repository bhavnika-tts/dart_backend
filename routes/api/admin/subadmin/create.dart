import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/admin_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null || claims.role != 'superadmin') {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Superadmin privileges required'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email']?.toString() ?? '';
    final password = body['password']?.toString() ?? '';
    final fName = body['fName']?.toString() ?? '';
    final lName = body['lName']?.toString() ?? '';
    final phone = body['phone']?.toString();
    final permissions = body['permissions'] as Map<String, dynamic>?;

    if (email.isEmpty || password.isEmpty || fName.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'email, password, and fName are required'},
      );
    }

    final created = await AdminService.instance.createSubadmin(
      email: email,
      password: password,
      fName: fName,
      lName: lName,
      phone: phone,
      permissions: permissions,
      creatorAdminId: claims.userId,
    );

    return Response.json(
      body: {
        'success': true,
        'message': 'Subadmin created successfully',
        'subadmin': created.toJson(),
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': error.toString()},
    );
  }
}
