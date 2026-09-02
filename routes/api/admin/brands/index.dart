import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/brand_model.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  final col = MongoClient.instance.collection('brandmodels');

  if (context.request.method == HttpMethod.get) {
    try {
      final query = context.request.uri.queryParameters;
      final productType = query['productType'];

      var selector = where.sortBy('displayOrder').sortBy('brand');
      if (productType != null && productType.isNotEmpty) {
        if (productType.contains(',')) {
          final types = productType.split(',').map((t) => t.trim().toLowerCase()).toList();
          selector = where.oneFrom('productType', types).sortBy('displayOrder').sortBy('brand');
        } else {
          selector = where.eq('productType', productType.trim().toLowerCase()).sortBy('displayOrder').sortBy('brand');
        }
      }

      final list = await col.find(selector).toList();
      final mapped = list.map((doc) => BrandModel.fromBson(doc).toJson()).toList();
      return Response.json(
        body: {
          'success': true,
          'entries': mapped,
          'data': mapped,
          'brands': mapped,
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to fetch brands', 'error': e.toString()},
      );
    }
  }

  if (context.request.method == HttpMethod.post) {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final result = await col.insertOne(body);
      return Response.json(
        body: {
          'success': true,
          'message': 'Brand created',
          'id': result.id.toString(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to create brand', 'error': e.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
