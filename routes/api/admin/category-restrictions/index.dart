import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  final authHeader = context.request.headers['authorization'];
  final claims = JwtService.instance.verifyAuthHeader(authHeader);
  if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin' && claims.role != 'admin')) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Admin access required'},
    );
  }

  final col = MongoClient.instance.collection('categoryrestrictions');
  final userCatCol = MongoClient.instance.collection('usercategorypermissions');
  final writeCatCol = MongoClient.instance.collection('productcategories');
  final prodTypeCol = MongoClient.instance.collection('producttypes');
  final adminCol = MongoClient.instance.collection('admins');

  if (context.request.method == HttpMethod.get) {
    try {
      final list = await col.find().toList();

      final userCats = await userCatCol.find().toList();
      final userCatMap = <String, Map<String, dynamic>>{};
      for (final uc in userCats) {
        final id = ModelHelpers.idToString(uc['_id']);
        if (id != null) {
          userCatMap[id] = {
            '_id': id,
            'categoryKey': uc['categoryKey']?.toString() ?? '',
            'label': uc['label']?.toString() ?? '',
          };
        }
      }

      final writeCats = await writeCatCol.find().toList();
      final writeCatMap = <String, Map<String, dynamic>>{};
      for (final wc in writeCats) {
        final id = ModelHelpers.idToString(wc['_id']);
        if (id != null) {
          writeCatMap[id] = {
            '_id': id,
            'label': wc['label']?.toString() ?? '',
          };
        }
      }

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

      final restrictions = list.map((doc) {
        final uId = ModelHelpers.idToString(doc['userCategory']);
        final wId = ModelHelpers.idToString(doc['writeCategory']);
        final rawAllowed = doc['allowedProductTypes'] as List? ?? [];

        final allowedPopulated = <Map<String, dynamic>>[];
        for (final item in rawAllowed) {
          final id = ModelHelpers.idToString(item);
          if (id != null && prodTypeMap.containsKey(id)) {
            allowedPopulated.add(prodTypeMap[id]!);
          }
        }

        return {
          '_id': ModelHelpers.idToString(doc['_id']),
          'userCategory': uId != null && userCatMap.containsKey(uId) ? userCatMap[uId] : null,
          'writeCategory': wId != null && writeCatMap.containsKey(wId) ? writeCatMap[wId] : null,
          'allowedProductTypes': allowedPopulated,
          if (doc['createdAt'] != null)
            'createdAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(doc['createdAt'])),
          if (doc['updatedAt'] != null)
            'updatedAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(doc['updatedAt'])),
          'updatedBy': null,
        };
      }).toList();

      return Response.json(
        body: {
          'success': true,
          'restrictions': restrictions,
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to fetch category restrictions', 'error': e.toString()},
      );
    }
  }

  if (context.request.method == HttpMethod.put || context.request.method == HttpMethod.post) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final userCategory = body['userCategory']?.toString() ?? '';
      final writeCategory = body['writeCategory']?.toString() ?? '';
      final rawAllowed = body['allowedProductTypes'] as List? ?? [];

      if (userCategory.isEmpty || writeCategory.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'userCategory and writeCategory are required'},
        );
      }

      final uObj = ModelHelpers.toObjectId(userCategory) ?? userCategory;
      final wObj = ModelHelpers.toObjectId(writeCategory) ?? writeCategory;
      final allowedObjs = rawAllowed.map((e) => ModelHelpers.toObjectId(e.toString()) ?? e).toList();

      final existing = await col.findOne({
        'userCategory': uObj,
        'writeCategory': wObj,
      });

      ObjectId? updatedByObj;
      if (claims.userId.isNotEmpty) {
        updatedByObj = ModelHelpers.toObjectId(claims.userId);
      }

      if (existing != null) {
        await col.updateOne(
          where.eq('_id', existing['_id']),
          modify
              .set('allowedProductTypes', allowedObjs)
              .set('updatedBy', updatedByObj)
              .set('updatedAt', DateTime.now()),
        );
      } else {
        await col.insertOne({
          'userCategory': uObj,
          'writeCategory': wObj,
          'allowedProductTypes': allowedObjs,
          'updatedBy': updatedByObj,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });
      }

      final saved = await col.findOne({
        'userCategory': uObj,
        'writeCategory': wObj,
      });

      return Response.json(
        body: {
          'success': true,
          'message': 'Category restriction updated successfully',
          'restriction': {
            '_id': ModelHelpers.idToString(saved?['_id']),
            'userCategory': userCategory,
            'writeCategory': writeCategory,
            'allowedProductTypes': rawAllowed,
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
