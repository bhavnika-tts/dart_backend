import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/repositories/admin_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
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

    final query = context.request.uri.queryParameters;
    final limit = int.tryParse(query['limit'] ?? '20') ?? 20;
    final page = int.tryParse(query['page'] ?? '1') ?? 1;

    final col = MongoClient.instance.collection('adminauditlogs');
    final total = await col.count();
    final totalPages = (total / limit).ceil();

    final logs = await AdminRepository.instance.getAuditLogs(limit: limit, page: page);

    return Response.json(
      body: {
        'success': true,
        'logs': logs.map((l) => l.toJson()).toList(),
        'pagination': {
          'total': total,
          'page': page,
          'limit': limit,
          'totalPages': totalPages,
        },
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch audit logs', 'error': error.toString()},
    );
  }
}
