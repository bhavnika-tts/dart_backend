import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/repositories/admin_repository.dart';

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
    final reportId = body['reportId']?.toString().trim() ?? body['id']?.toString().trim() ?? '';
    final status = body['status']?.toString().trim() ?? 'resolved';

    if (reportId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'reportId is required'},
      );
    }

    final updated = await AdminRepository.instance.updateChatReportStatus(reportId, status);

    return Response.json(
      body: {'success': updated, 'message': 'Chat report status updated successfully'},
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to update chat report', 'error': error.toString()},
    );
  }
}
