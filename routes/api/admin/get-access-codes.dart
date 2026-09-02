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
    final claims = JwtService.instance.verifyAuthHeader(authHeader);

    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Unauthorized'},
      );
    }

    final codesCol = MongoClient.instance.collection('codes');
    final userCatCol = MongoClient.instance.collection('usercategorypermissions');
    final usersCol = MongoClient.instance.collection('users');

    var pins = await codesCol.find().toList();

    if (claims.role == 'subadmin') {
      final permsCol = MongoClient.instance.collection('adminpermissions');
      final adminObjId = ModelHelpers.toObjectId(claims.userId);
      final permDoc = await permsCol.findOne(where.eq('adminId', adminObjId));
      final assignedCodes = permDoc?['assigned_access_codes'] as List?;
      if (assignedCodes != null && assignedCodes.isNotEmpty) {
        final assignedSet = assignedCodes.map((e) => e.toString()).toSet();
        pins = pins.where((p) => assignedSet.contains(p['code']?.toString())).toList();
      }
    }

    final catDocs = await userCatCol.find().toList();
    final allCategories = catDocs.map((c) => {
          '_id': ModelHelpers.idToString(c['_id']),
          'categoryKey': c['categoryKey']?.toString() ?? '',
          'label': c['label']?.toString() ?? c['displayName']?.toString() ?? c['categoryKey']?.toString() ?? '',
        }).toList();

    // Fetch user counts breakdown per pin code and user category
    final allUsers = await usersCol.find(where.eq('isDeleted', false)).toList();
    final breakdownMap = <String, Map<String, int>>{};

    for (final u in allUsers) {
      final pinList = u['assignedPins'] is List ? (u['assignedPins'] as List) : [u['assignedPins']];
      final cat = u['userCategory']?.toString() ?? '';
      for (final p in pinList) {
        final code = p?.toString();
        if (code != null && code.isNotEmpty) {
          breakdownMap.putIfAbsent(code, () => {});
          breakdownMap[code]![cat] = (breakdownMap[code]![cat] ?? 0) + 1;
        }
      }
    }

    final enrichedPins = pins.map((p) {
      final code = p['code']?.toString() ?? '';
      final cBreakdown = <String, int>{};
      for (final cat in allCategories) {
        final catKey = cat['categoryKey']?.toString() ?? '';
        cBreakdown[catKey] = breakdownMap[code]?[catKey] ?? 0;
      }

      return {
        '_id': ModelHelpers.idToString(p['_id']),
        'code': code,
        'categoryBreakdown': cBreakdown,
        if (p['createdAt'] != null)
          'createdAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(p['createdAt'])),
      };
    }).toList();

    return Response.json(
      body: {
        'message': 'Code is valid',
        'data': enrichedPins,
        'categories': allCategories,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error', 'error': error.toString()},
    );
  }
}
