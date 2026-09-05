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
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin' && claims.role != 'admin')) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final name = body['name']?.toString() ?? '';
      final productType = body['productType']?.toString() ?? '';

      if (name.isEmpty || productType.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'Name and Category (productType ID) are required'},
        );
      }

      final ptObjId = ModelHelpers.toObjectId(productType) ?? productType;
      final existing = await subCol.findOne({
        'name': {'\$regex': '^$name\$', '\$options': 'i'},
        'productType': ptObjId,
        'isDeleted': {'\$ne': true},
      });

      if (existing != null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'A sub-category with this name already exists under this category'},
        );
      }

      final doc = <String, dynamic>{
        'name': name,
        'productType': ptObjId,
        'isDeleted': false,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      if (claims.userId.isNotEmpty) {
        final adminObj = ModelHelpers.toObjectId(claims.userId);
        doc['lastEditedBy'] = adminObj;
        doc['history'] = [
          {'updatedBy': adminObj, 'updatedAt': DateTime.now()}
        ];
      }

      final insertRes = await subCol.insertOne(doc);
      final newId = insertRes.id;

      final ptDoc = await prodTypeCol.findOne(where.eq('_id', ptObjId));
      final populated = <String, dynamic>{
        '_id': ModelHelpers.idToString(newId),
        'name': name,
        'productType': ptDoc != null
            ? {
                '_id': ModelHelpers.idToString(ptDoc['_id']),
                'name': ptDoc['name']?.toString() ?? '',
                'modelName': ptDoc['modelName']?.toString() ?? '',
              }
            : productType,
        'isDeleted': false,
        'createdAt': ModelHelpers.toIsoString(doc['createdAt'] as DateTime),
        'updatedAt': ModelHelpers.toIsoString(doc['updatedAt'] as DateTime),
      };

      return Response.json(
        statusCode: HttpStatus.created,
        body: {
          'message': 'Sub-category created successfully',
          'success': true,
          'data': populated,
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
