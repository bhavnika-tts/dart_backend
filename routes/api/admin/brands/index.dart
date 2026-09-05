import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/brand_model.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
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
          'entries': mapped,
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
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin' && claims.role != 'admin')) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final productType = body['productType']?.toString().trim().toLowerCase() ?? '';
      final brand = body['brand']?.toString().trim() ?? '';
      final models = (body['models'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final displayOrder = int.tryParse(body['displayOrder']?.toString() ?? '999') ?? 999;

      if (productType.isEmpty || brand.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'productType and brand are required'},
        );
      }

      final existing = await col.findOne({
        'productType': productType,
        'brand': brand,
      });

      if (existing != null) {
        return Response.json(
          statusCode: HttpStatus.conflict,
          body: {'message': "Brand '$brand' already exists for type '$productType'."},
        );
      }

      final doc = <String, dynamic>{
        'productType': productType,
        'brand': brand,
        'models': models,
        'displayOrder': displayOrder,
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      final res = await col.insertOne(doc);

      return Response.json(
        statusCode: HttpStatus.created,
        body: {
          'message': 'Brand created successfully',
          'entry': {
            '_id': res.id.toString(),
            ...doc,
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

