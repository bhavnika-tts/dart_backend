import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:dart_frog_backend/utils/mongo_sanitizer.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
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

    final body = await context.request.json() as Map<String, dynamic>;
    final productId = body['productId']?.toString();

    if (productId == null || productId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Product ID is required'},
      );
    }

    final prodCol = MongoClient.instance.collection('products');
    final prodObjId = ModelHelpers.toObjectId(productId);
    final product = await prodCol.findOne(
      prodObjId != null ? where.id(prodObjId) : where.eq('_id', productId),
    );

    if (product == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Product not found'},
      );
    }

    // Update fields
    final mod = modify.set('updatedAt', DateTime.now().toUtc());

    final commonKeys = ['title', 'description', 'price', 'status', 'isActive', 'isDeleted', 'featured', 'city', 'state', 'country', 'pincode', 'area'];
    for (final k in commonKeys) {
      if (body.containsKey(k) && body[k] != null) {
        mod.set(k, body[k]);
      }
    }

    // Update specs Map
    final currentSpecs = product['specs'] is Map ? Map<String, dynamic>.from(product['specs'] as Map) : <String, dynamic>{};
    for (final entry in body.entries) {
      if (['productId', 'userId', 'productType', 'subProductType', 'images', 'productImages', ...commonKeys].contains(entry.key)) {
        continue;
      }
      currentSpecs[entry.key] = entry.value;
    }
    mod.set('specs', currentSpecs);

    await prodCol.updateOne(where.id(product['_id'] as ObjectId), mod);

    final updatedProduct = await prodCol.findOne(where.id(product['_id'] as ObjectId));
    final ptCol = MongoClient.instance.collection('producttypes');
    final sptCol = MongoClient.instance.collection('subproducttypes');
    final userCol = MongoClient.instance.collection('users');

    Map<String, dynamic>? ptMap;
    if (updatedProduct?['productType'] != null) {
      final ptObjId = ModelHelpers.toObjectId(updatedProduct!['productType'].toString());
      final ptDoc = await ptCol.findOne(ptObjId != null ? where.id(ptObjId) : where.eq('_id', updatedProduct['productType']));
      if (ptDoc != null) {
        ptMap = Map<String, dynamic>.from(ptDoc);
        ptMap['_id'] = ModelHelpers.idToString(ptMap['_id']);
      }
    }

    Map<String, dynamic>? sptMap;
    if (updatedProduct?['subProductType'] != null) {
      final sptObjId = ModelHelpers.toObjectId(updatedProduct!['subProductType'].toString());
      final sptDoc = await sptCol.findOne(sptObjId != null ? where.id(sptObjId) : where.eq('_id', updatedProduct['subProductType']));
      if (sptDoc != null) {
        sptMap = Map<String, dynamic>.from(sptDoc);
        sptMap['_id'] = ModelHelpers.idToString(sptMap['_id']);
      }
    }

    Map<String, dynamic>? userMap;
    if (updatedProduct?['userId'] != null) {
      final uObjId = ModelHelpers.toObjectId(updatedProduct!['userId'].toString());
      final uDoc = await userCol.findOne(uObjId != null ? where.id(uObjId) : where.eq('_id', updatedProduct['userId']));
      if (uDoc != null) {
        userMap = {
          '_id': ModelHelpers.idToString(uDoc['_id']),
          'fName': uDoc['fName'],
          'lName': uDoc['lName'],
          'mName': uDoc['mName'],
          'email': uDoc['email'],
          'phone': uDoc['phone'],
          'profileImage': uDoc['profileImage'],
          'country': uDoc['country'],
          'state': uDoc['state'],
          'area': uDoc['area'],
          'userCategory': uDoc['userCategory'],
        };
      }
    }

    final sanitized = Map<String, dynamic>.from(updatedProduct ?? product);
    sanitized['_id'] = ModelHelpers.idToString(sanitized['_id']);
    sanitized['userId'] = userMap ?? sanitized['userId'];
    sanitized['productType'] = ptMap ?? sanitized['productType'];
    sanitized['subProductType'] = sptMap ?? sanitized['subProductType'];

    if (sanitized['createdAt'] is DateTime) {
      sanitized['createdAt'] = (sanitized['createdAt'] as DateTime).toIso8601String();
    }
    if (sanitized['updatedAt'] is DateTime) {
      sanitized['updatedAt'] = (sanitized['updatedAt'] as DateTime).toIso8601String();
    }

    final formattedProduct = <String, dynamic>{
      ...currentSpecs,
      ...sanitized,
      'productId': ModelHelpers.idToString(sanitized['_id']),
      'price': sanitized['price'] != null ? [sanitized['price']] : [],
      'adTitle': sanitized['title'] != null ? [sanitized['title']] : [],
      'title': sanitized['title'] != null ? [sanitized['title']] : [],
      'description': sanitized['description'] != null ? [sanitized['description']] : [],
    };

    final sanitizedProduct = sanitizeMongoData(formattedProduct) as Map<String, dynamic>;
    final typeName = ptMap?['name']?.toString() ?? 'Product';
    return Response.json(
      body: {
        'message': '$typeName updated successfully',
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
