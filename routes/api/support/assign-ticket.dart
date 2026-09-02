import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/admin_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final chatId = body['chatId']?.toString().trim() ?? '';
    final assignedAdminId = body['assignedAdminId']?.toString().trim() ?? claims.userId;

    if (chatId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'chatId is required'},
      );
    }

    await AdminService.instance.assignSupportTicket(
      chatId,
      assignedAdminId,
      adminId: claims.userId,
    );

    return Response.json(
      body: {'success': true, 'message': 'Ticket assigned successfully'},
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to assign ticket', 'error': error.toString()},
    );
  }
}
