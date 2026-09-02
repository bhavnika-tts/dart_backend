import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:dart_frog_backend/services/imagekit_service.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final query = context.request.uri.queryParameters;
    final productTypeId = query['productTypeId'];
    final category = query['category'];
    final showDeleted = query['showDeleted'] == 'true';

    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);

    var selector = showDeleted ? where.eq('isDeleted', true) : where.ne('isDeleted', true);

    if (claims?.role == 'subadmin') {
      final usersCol = MongoClient.instance.collection('users');
      final subadminObjId = ModelHelpers.toObjectId(claims!.userId);
      final managedUsers = await usersCol.find(where.eq('assignedByAdmin', subadminObjId)).toList();
      final userIds = managedUsers.map((u) => u['_id']).toList();
      selector = selector.oneFrom('userId', userIds);
    }

    if (productTypeId != null && productTypeId.isNotEmpty) {
      final ptObjId = ModelHelpers.toObjectId(productTypeId);
      if (ptObjId != null) {
        selector = selector.eq('productType', ptObjId);
      }
    }

    if (category != null && category.isNotEmpty) {
      selector = selector.eq('categories', category);
    }

    final prodCol = MongoClient.instance.collection('products');
    final usersCol = MongoClient.instance.collection('users');
    final prodTypeCol = MongoClient.instance.collection('producttypes');
    final subProdTypeCol = MongoClient.instance.collection('subproducttypes');

    final rawProducts = await prodCol.find(selector.sortBy('createdAt', descending: true)).toList();
    final allProdTypes = await prodTypeCol.find().toList();
    final allSubTypes = await subProdTypeCol.find().toList();

    final prodTypeMap = <String, Map<String, dynamic>>{};
    for (final pt in allProdTypes) {
      final id = ModelHelpers.idToString(pt['_id']);
      if (id != null) {
        prodTypeMap[id] = {
          '_id': id,
          'name': pt['name']?.toString() ?? '',
          'modelName': pt['modelName']?.toString() ?? '',
        };
      }
    }

    final subTypeMap = <String, Map<String, dynamic>>{};
    for (final st in allSubTypes) {
      final id = ModelHelpers.idToString(st['_id']);
      if (id != null) {
        subTypeMap[id] = {
          '_id': id,
          'name': st['name']?.toString() ?? '',
        };
      }
    }

    final userIdsToFetch = rawProducts.map((p) => p['userId']).whereType<ObjectId>().toList();
    final userMap = <String, Map<String, dynamic>>{};
    if (userIdsToFetch.isNotEmpty) {
      final users = await usersCol.find(where.oneFrom('_id', userIdsToFetch)).toList();
      for (final u in users) {
        final id = ModelHelpers.idToString(u['_id']);
        if (id != null) {
          userMap[id] = {
            '_id': id,
            'fName': u['fName']?.toString() ?? '',
            'lName': u['lName']?.toString() ?? '',
            'mName': u['mName']?.toString() ?? '',
            'email': u['email']?.toString() ?? '',
            'phone': u['phone']?.toString() ?? '',
            'profileImage': u['profileImage']?.toString() ?? '',
            'state': u['state']?.toString() ?? '',
            'district': u['district']?.toString() ?? '',
            'country': u['country']?.toString() ?? '',
            'area': u['area']?.toString() ?? '',
            'userCategory': u['userCategory']?.toString() ?? '',
          };
        }
      }
    }

    final groupedProducts = <String, Map<String, dynamic>>{};

    for (final p in rawProducts) {
      final ptId = ModelHelpers.idToString(p['productType']) ?? '';
      final ptData = prodTypeMap[ptId];
      final modelName = ptData?['modelName']?.toString() ?? 'other';

      groupedProducts.putIfAbsent(modelName, () => {'count': 0, 'items': <dynamic>[]});

      final stId = ModelHelpers.idToString(p['subProductType']);
      final stData = stId != null ? subTypeMap[stId] : null;

      final uId = ModelHelpers.idToString(p['userId']);
      final uData = uId != null ? userMap[uId] : null;

      final rawSpecs = p['specs'] is Map ? (p['specs'] as Map<String, dynamic>) : <String, dynamic>{};
      final specsObj = Map<String, dynamic>.from(rawSpecs);

      final price = p['price'];
      final title = p['title']?.toString() ?? '';
      final desc = p['description']?.toString() ?? '';
      final viewList = p['view_count'] is List ? (p['view_count'] as List) : <dynamic>[];

      final productObj = <String, dynamic>{
        ...specsObj,
        '_id': ModelHelpers.idToString(p['_id']),
        'productId': ModelHelpers.idToString(p['_id']),
        'title': title.isNotEmpty ? [title] : <dynamic>[],
        'adTitle': title.isNotEmpty ? [title] : <dynamic>[],
        'description': desc.isNotEmpty ? [desc] : <dynamic>[],
        'price': price != null ? [price] : <dynamic>[],
        'images': p['images'] ?? <dynamic>[],
        'categories': p['categories']?.toString() ?? '',
        'productType': ptData ?? ptId,
        'subProductType': stData ?? stId,
        'userId': uData ?? uId,
        'viewCount': viewList.length,
        'modelName': modelName,
        'isCustomModel': false,
        'isDeleted': ModelHelpers.parseBool(p['isDeleted']),
        if (p['createdAt'] != null)
          'createdAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(p['createdAt'])),
        if (p['updatedAt'] != null)
          'updatedAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(p['updatedAt'])),
      };

      final signedObj = ImageKitService.instance.signImageKitUrls(productObj);
      (groupedProducts[modelName]!['items'] as List<dynamic>).add(signedObj);
      groupedProducts[modelName]!['count'] = (groupedProducts[modelName]!['count'] as int) + 1;
    }

    return Response.json(
      body: {
        'message': 'Filtered products fetched successfully',
        'products': groupedProducts,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch products', 'error': error.toString()},
    );
  }
}
