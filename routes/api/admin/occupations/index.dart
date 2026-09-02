import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/occupation.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  final col = MongoClient.instance.collection('occupations');

  if (context.request.method == HttpMethod.get) {
    try {
      final list = await col.find(where.sortBy('name')).toList();
      final mapped = list.map((doc) => Occupation.fromBson(doc).toJson()).toList();
      return Response.json(
        body: {
          'success': true,
          'data': mapped,
          'occupations': mapped,
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to fetch occupations', 'error': e.toString()},
      );
    }
  }

  if (context.request.method == HttpMethod.post) {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null || claims.role != 'superadmin') {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Superadmin access required'},
      );
    }

    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final result = await col.insertOne(body);
      return Response.json(
        body: {
          'success': true,
          'message': 'Occupation created',
          'id': result.id.toString(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to create occupation', 'error': e.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
