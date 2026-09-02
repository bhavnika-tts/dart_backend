import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:dart_frog_backend/models/sub_product_type.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  final subCol = MongoClient.instance.collection('subproducttypes');
  final prodTypeCol = MongoClient.instance.collection('producttypes');

  if (context.request.method == HttpMethod.get) {
    try {
      final query = context.request.uri.queryParameters;
      final all = query['all'] == 'true';

      var selector = where.ne('isDeleted', true);

      if (!all) {
        final otherType = await prodTypeCol.findOne(where.match('modelName', r'^other$', caseInsensitive: true));
        if (otherType != null) {
          selector = selector.eq('productType', otherType['_id']);
        }
      }

      final list = await subCol.find(selector).toList();
      final prodTypes = await prodTypeCol.find().toList();
      final prodTypeMap = <String, Map<String, dynamic>>{};

      for (final pt in prodTypes) {
        final id = ModelHelpers.idToString(pt['_id']);
        if (id != null) {
          prodTypeMap[id] = {
            '_id': id,
            'name': pt['name']?.toString() ?? '',
            'modelName': pt['modelName']?.toString() ?? '',
          };
        }
      }

      final mapped = list.map((doc) {
        final sub = SubProductType.fromBson(doc);
        final json = sub.toJson();
        final ptId = sub.productType;
        if (prodTypeMap.containsKey(ptId)) {
          json['productType'] = prodTypeMap[ptId];
        }
        return json;
      }).toList();

      return Response.json(
        body: {
          'success': true,
          'data': mapped,
          'sub_product_types': mapped,
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to fetch sub-product types', 'error': e.toString()},
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
      final result = await subCol.insertOne(body);
      return Response.json(
        body: {
          'success': true,
          'message': 'Sub product type created',
          'id': result.id.toString(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to create sub product type', 'error': e.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
