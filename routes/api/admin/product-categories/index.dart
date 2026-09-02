import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
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
          'data': mapped,
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
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final result = await col.insertOne(body);
      return Response.json(
        body: {
          'success': true,
          'message': 'Product category created',
          'id': result.id.toString(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to create product category', 'error': e.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
