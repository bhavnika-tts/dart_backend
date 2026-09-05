import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
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
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin' && claims.role != 'admin')) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final name = body['name']?.toString().trim() ?? '';
      if (name.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'Name is required'},
        );
      }

      final existing = await col.findOne({'name': {'\$regex': '^$name\$', '\$options': 'i'}});
      if (existing != null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'Occupation already exists'},
        );
      }

      final doc = <String, dynamic>{
        'name': name,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      if (claims.userId.isNotEmpty) {
        doc['createdBy'] = ModelHelpers.toObjectId(claims.userId);
      }

      final res = await col.insertOne(doc);
      return Response.json(
        statusCode: HttpStatus.created,
        body: {
          'success': true,
          'message': 'Occupation created',
          'data': {
            '_id': res.id.toString(),
            'name': name,
            if (doc['createdBy'] != null) 'createdBy': doc['createdBy'].toString(),
            'createdAt': ModelHelpers.toIsoString(doc['createdAt'] as DateTime),
            'updatedAt': ModelHelpers.toIsoString(doc['updatedAt'] as DateTime),
          },
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Server error!', 'error': e.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
