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
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    final query = context.request.uri.queryParameters;
    final limit = int.tryParse(query['limit'] ?? '100') ?? 100;

    final ratings = await AdminRepository.instance.getAllRatings(limit: limit);

    return Response.json(
      body: {
        'success': true,
        'count': ratings.length,
        'ratings': ratings.map((r) => r.toJson()).toList(),
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch ratings', 'error': error.toString()},
    );
  }
}
