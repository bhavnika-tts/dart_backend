import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid or missing Authorization token.'},
      );
    }
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid token data.'},
      );
    }

    final query = context.request.uri.queryParameters;
    final productType = query['productType'] ?? query['productTypeId'];
    final subProductType = query['subProductType'] ?? query['subProductTypeId'];
    final all = query['all'];

    if (productType == null || productType.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'productType is required'},
      );
    }

    final ptObjId = ModelHelpers.toObjectId(productType);
    final ptCol = MongoClient.instance.collection('producttypes');
    final metaCol = MongoClient.instance.collection('formmetadatas');

    Map<String, dynamic>? ptDoc;
    if (ptObjId != null) {
      ptDoc = await ptCol.findOne(where.id(ptObjId));
    }
    ptDoc ??= await ptCol.findOne(where.eq('_id', productType));

    final formConfig = (ptDoc != null && ptDoc['formConfig'] is Map)
        ? ptDoc['formConfig']
        : {
            'showTitle': true,
            'isTitleRequired': false,
            'showDescription': true,
            'isDescriptionRequired': false,
          };

    List<Map<String, dynamic>> rawFields = [];

    if (subProductType != null && subProductType.isNotEmpty) {
      final allowedSubTypes = <String>[subProductType];

      final modelName = ptDoc?['modelName']?.toString().toLowerCase() ?? '';
      final name = ptDoc?['name']?.toString().toLowerCase() ?? '';
      if (modelName == 'other' || name == 'other') {
        final subCol = MongoClient.instance.collection('subproducttypes');
        final defaultOtherSub = await subCol.findOne(
          where.eq('productType', ptObjId ?? productType).match('name', r'^other$', caseInsensitive: true),
        );
        if (defaultOtherSub != null) {
          final otherId = ModelHelpers.idToString(defaultOtherSub['_id']);
          if (otherId != null && otherId != subProductType) {
            allowedSubTypes.add(otherId);
          }
        }
      }

      // Fetch fields for category
      final allDocs = await metaCol.find(where.eq('productType', productType)).toList();
      final filteredDocs = allDocs.where((doc) {
        if (all != 'true' && doc['isHidden'] == true) return false;
        final docSubTypes = (doc['subProductTypes'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final docSub = doc['subProductType']?.toString();
        final hasSub = docSubTypes.any((st) => allowedSubTypes.contains(st)) ||
            (docSub != null && allowedSubTypes.contains(docSub));
        return hasSub;
      }).toList();

      filteredDocs.sort((a, b) => ((a['displayOrder'] as num?) ?? 0).compareTo((b['displayOrder'] as num?) ?? 0));

      final fieldMap = <String, Map<String, dynamic>>{};
      for (final doc in filteredDocs) {
        final key = doc['key']?.toString() ?? '';
        final docSub = doc['subProductType']?.toString();
        final docSubTypes = (doc['subProductTypes'] as List?) ?? [];
        final isSubSpecific = (docSub != null && docSub.isNotEmpty) || docSubTypes.isNotEmpty;

        if (!fieldMap.containsKey(key) || isSubSpecific) {
          fieldMap[key] = doc;
        }
      }

      rawFields = fieldMap.values.toList()
        ..sort((a, b) => ((a['displayOrder'] as num?) ?? 0).compareTo((b['displayOrder'] as num?) ?? 0));
    } else {
      final allDocs = await metaCol.find(where.eq('productType', productType)).toList();
      rawFields = allDocs.where((doc) {
        if (all != 'true') {
          if (doc['isHidden'] == true) return false;
          if (doc['subProductType'] != null && doc['subProductType'].toString().isNotEmpty) return false;
        }
        return true;
      }).toList()
        ..sort((a, b) => ((a['displayOrder'] as num?) ?? 0).compareTo((b['displayOrder'] as num?) ?? 0));
    }

    final sanitizedFields = rawFields.map((doc) {
      final d = Map<String, dynamic>.from(doc);
      d['_id'] = ModelHelpers.idToString(d['_id']);
      if (d['productType'] != null) {
        d['productType'] = ModelHelpers.idToString(d['productType']);
      }
      if (d['subProductType'] != null) {
        d['subProductType'] = ModelHelpers.idToString(d['subProductType']);
      }
      if (d['subProductTypes'] is List) {
        d['subProductTypes'] = (d['subProductTypes'] as List).map((e) => ModelHelpers.idToString(e)).toList();
      }
      if (d['createdAt'] is DateTime) {
        d['createdAt'] = (d['createdAt'] as DateTime).toIso8601String();
      }
      if (d['updatedAt'] is DateTime) {
        d['updatedAt'] = (d['updatedAt'] as DateTime).toIso8601String();
      }
      return d;
    }).toList();

    return Response.json(
      body: {
        'formConfig': formConfig,
        'fields': sanitizedFields,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error!', 'error': error.toString()},
    );
  }
}
