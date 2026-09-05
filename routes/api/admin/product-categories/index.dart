import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:dart_frog_backend/models/product_category.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  final authHeader = context.request.headers['authorization'];
  final claims = JwtService.instance.verifyAuthHeader(authHeader);
  if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Admin access required'},
    );
  }

  final col = MongoClient.instance.collection('productcategories');

  if (context.request.method == HttpMethod.get) {
    try {
      final list = await col.find(where.sortBy('sortOrder')).toList();
      final mapped = list.map((doc) => ProductCategory.fromBson(doc).toJson()).toList();
      return Response.json(
        body: {
          'success': true,
          'categories': mapped,
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to fetch product categories', 'error': e.toString()},
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
      final label = (body['label'] ?? body['name'])?.toString().trim() ?? '';
      if (label.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'label is required'},
        );
      }

      final existing = await col.findOne({'label': label});
      if (existing != null) {
        return Response.json(
          statusCode: HttpStatus.conflict,
          body: {
            'message': 'Bucket "$label" already exists.',
            'category': ProductCategory.fromBson(existing).toJson(),
          },
        );
      }

      final count = await col.count();
      final doc = <String, dynamic>{
        'label': label,
        'sortOrder': count + 1,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      final res = await col.insertOne(doc);

      return Response.json(
        statusCode: HttpStatus.created,
        body: {
          'success': true,
          'message': 'Bucket "$label" created successfully',
          'category': {
            '_id': res.id.toString(),
            'label': label,
            'sortOrder': doc['sortOrder'],
            'createdAt': ModelHelpers.toIsoString(doc['createdAt'] as DateTime),
            'updatedAt': ModelHelpers.toIsoString(doc['updatedAt'] as DateTime),
          },
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Server error', 'error': e.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
