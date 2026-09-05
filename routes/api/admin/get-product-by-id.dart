import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:dart_frog_backend/utils/mongo_sanitizer.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Unauthorized'},
      );
    }

    final query = context.request.uri.queryParameters;
    final productId = query['productId'];

    if (productId == null || productId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Product ID is required'},
      );
    }

    final prodCol = MongoClient.instance.collection('products');
    final userCol = MongoClient.instance.collection('users');
    final ptCol = MongoClient.instance.collection('producttypes');
    final sptCol = MongoClient.instance.collection('subproducttypes');
    final brandCol = MongoClient.instance.collection('brandmodelentries');

    final prodObjId = ModelHelpers.toObjectId(productId);
    final baseProduct = await prodCol.findOne(prodObjId != null ? where.id(prodObjId) : where.eq('_id', productId));

    if (baseProduct == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Product not found'},
      );
    }

    // Populate userId
    Map<String, dynamic>? userMap;
    if (baseProduct['userId'] != null) {
      final uId = baseProduct['userId'];
      final uObjId = ModelHelpers.toObjectId(uId.toString());
      final uDoc = await userCol.findOne(uObjId != null ? where.id(uObjId) : where.eq('_id', uId));
      if (uDoc != null) {
        userMap = {
          '_id': ModelHelpers.idToString(uDoc['_id']),
          'fName': uDoc['fName'],
          'lName': uDoc['lName'],
          'mName': uDoc['mName'],
          'email': uDoc['email'],
          'phone': uDoc['phone'],
          'profileImage': uDoc['profileImage'],
          'state': uDoc['state'],
          'district': uDoc['district'],
          'country': uDoc['country'],
          'area': uDoc['area'],
          'userCategory': uDoc['userCategory'],
        };
      }
    }

    // Populate productType
    Map<String, dynamic>? ptMap;
    if (baseProduct['productType'] != null) {
      final ptId = baseProduct['productType'];
      final ptObjId = ModelHelpers.toObjectId(ptId.toString());
      final ptDoc = await ptCol.findOne(ptObjId != null ? where.id(ptObjId) : where.eq('_id', ptId));
      if (ptDoc != null) {
        ptMap = Map<String, dynamic>.from(ptDoc);
        ptMap['_id'] = ModelHelpers.idToString(ptMap['_id']);
        if (ptMap['createdAt'] is DateTime) ptMap['createdAt'] = (ptMap['createdAt'] as DateTime).toIso8601String();
        if (ptMap['updatedAt'] is DateTime) ptMap['updatedAt'] = (ptMap['updatedAt'] as DateTime).toIso8601String();
      }
    }

    // Populate subProductType
    Map<String, dynamic>? sptMap;
    if (baseProduct['subProductType'] != null) {
      final sptId = baseProduct['subProductType'];
      final sptObjId = ModelHelpers.toObjectId(sptId.toString());
      final sptDoc = await sptCol.findOne(sptObjId != null ? where.id(sptObjId) : where.eq('_id', sptId));
      if (sptDoc != null) {
        sptMap = Map<String, dynamic>.from(sptDoc);
        sptMap['_id'] = ModelHelpers.idToString(sptMap['_id']);
        if (sptMap['createdAt'] is DateTime) sptMap['createdAt'] = (sptMap['createdAt'] as DateTime).toIso8601String();
        if (sptMap['updatedAt'] is DateTime) sptMap['updatedAt'] = (sptMap['updatedAt'] as DateTime).toIso8601String();
      }
    }

    final specsObj = baseProduct['specs'] is Map ? Map<String, dynamic>.from(baseProduct['specs'] as Map) : <String, dynamic>{};

    final brand = specsObj['brand']?.toString();
    final model = specsObj['model']?.toString();
    var isCustomModel = false;

    if (brand != null && model != null && model != 'Other' && model != 'Not Listed / Other') {
      var typeStr = '';
      if (sptMap != null && sptMap['name'] != null) {
        typeStr = sptMap['name'].toString();
      } else if (ptMap != null && (ptMap['modelName'] != null || ptMap['name'] != null)) {
        typeStr = (ptMap['modelName'] ?? ptMap['name']).toString();
      }

      final normalizedType = typeStr.trim().toLowerCase();
      final brandEntry = await brandCol.findOne(
        where
            .match('productType', '^$normalizedType\$', caseInsensitive: true)
            .match('brand', '^${RegExp.escape(brand.trim())}\$', caseInsensitive: true)
            .eq('isActive', true),
      );

      if (brandEntry == null) {
        isCustomModel = true;
      } else {
        final models = (brandEntry['models'] as List?)?.map((m) => m.toString().toLowerCase().trim()).toList() ?? [];
        isCustomModel = !models.contains(model.toLowerCase().trim());
      }
    }

    final sanitizedBase = Map<String, dynamic>.from(baseProduct);
    sanitizedBase['_id'] = ModelHelpers.idToString(sanitizedBase['_id']);
    sanitizedBase['userId'] = userMap ?? sanitizedBase['userId'];
    sanitizedBase['productType'] = ptMap ?? sanitizedBase['productType'];
    sanitizedBase['subProductType'] = sptMap ?? sanitizedBase['subProductType'];

    if (sanitizedBase['createdAt'] is DateTime) {
      sanitizedBase['createdAt'] = (sanitizedBase['createdAt'] as DateTime).toIso8601String();
    }
    if (sanitizedBase['updatedAt'] is DateTime) {
      sanitizedBase['updatedAt'] = (sanitizedBase['updatedAt'] as DateTime).toIso8601String();
    }

    final productToShow = <String, dynamic>{
      ...specsObj,
      ...sanitizedBase,
      'productId': ModelHelpers.idToString(sanitizedBase['_id']),
      'modelName': ptMap?['modelName'] ?? 'other',
      'price': sanitizedBase['price'] != null ? [sanitizedBase['price']] : [],
      'title': sanitizedBase['title'] != null ? [sanitizedBase['title']] : [],
      'adTitle': sanitizedBase['title'] != null ? [sanitizedBase['title']] : [],
      'description': sanitizedBase['description'] != null ? [sanitizedBase['description']] : [],
      'viewCount': (sanitizedBase['view_count'] as List?)?.length ?? 0,
      'isCustomModel': isCustomModel,
    };

    final sanitizedProduct = sanitizeMongoData(productToShow) as Map<String, dynamic>;

    return Response.json(
      body: {
        'message': 'Product fetched successfully',
        'product': sanitizedProduct,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error!', 'error': error.toString()},
    );
  }
}
