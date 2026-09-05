import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final query = context.request.uri.queryParameters;
    final showDeleted = query['showDeleted'] == 'true';

    final prodTypeCol = MongoClient.instance.collection('producttypes');
    final prodCol = MongoClient.instance.collection('products');
    final userCatCol = MongoClient.instance.collection('usercategorypermissions');

    final rawTypes = await prodTypeCol.find(where.sortBy('name')).toList();
    final categories = await userCatCol.find().toList();
    final knownCategories = categories
        .map((c) => c['categoryKey']?.toString().toUpperCase())
        .whereType<String>()
        .toList()
      ..sort();

    final matchSelector = showDeleted ? where.eq('isDeleted', true) : where.ne('isDeleted', true);
    final allProducts = await prodCol.find(matchSelector).toList();

    final typeCountsMap = <String, int>{};
    final categoryCountsMap = <String, Map<String, int>>{};
    final allCategoryCounts = <String, int>{};

    for (final p in allProducts) {
      final typeId = ModelHelpers.idToString(p['productType']);
      final cat = p['categories']?.toString().toUpperCase();

      if (typeId != null && typeId.isNotEmpty) {
        typeCountsMap[typeId] = (typeCountsMap[typeId] ?? 0) + 1;

        if (cat != null && cat.isNotEmpty) {
          categoryCountsMap.putIfAbsent(typeId, () => {});
          categoryCountsMap[typeId]![cat] = (categoryCountsMap[typeId]![cat] ?? 0) + 1;
          allCategoryCounts[cat] = (allCategoryCounts[cat] ?? 0) + 1;
        }
      }
    }

    final mergedAllCategoryCounts = <String, int>{};
    for (final cat in knownCategories) {
      mergedAllCategoryCounts[cat] = allCategoryCounts[cat] ?? 0;
    }
    for (final entry in allCategoryCounts.entries) {
      mergedAllCategoryCounts.putIfAbsent(entry.key, () => entry.value);
    }

    final productTypesWithCount = rawTypes.map((pt) {
      final typeId = ModelHelpers.idToString(pt['_id']) ?? '';
      final typeCounts = categoryCountsMap[typeId] ?? {};
      final mergedTypeCounts = <String, int>{};

      for (final cat in knownCategories) {
        mergedTypeCounts[cat] = typeCounts[cat] ?? 0;
      }
      for (final entry in typeCounts.entries) {
        mergedTypeCounts.putIfAbsent(entry.key, () => entry.value);
      }

      return {
        '_id': typeId,
        'name': pt['name']?.toString() ?? '',
        'modelName': pt['modelName']?.toString() ?? '',
        'formConfig': pt['formConfig'] ?? <String, dynamic>{},
        'count': typeCountsMap[typeId] ?? 0,
        'categories': mergedTypeCounts,
        if (pt['createTime'] != null)
          'createTime': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(pt['createTime'])),
      };
    }).toList();

    var totalCount = 0;
    for (final c in typeCountsMap.values) {
      totalCount += c;
    }

    final finalData = [
      {
        '_id': '',
        'name': 'All',
        'modelName': '',
        'count': totalCount,
        'categories': mergedAllCategoryCounts,
      },
      ...productTypesWithCount,
    ];

    return Response.json(
      body: {
        'message': 'Product types fetched successfully',
        'data': finalData,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch product types', 'error': error.toString()},
    );
  }
}
