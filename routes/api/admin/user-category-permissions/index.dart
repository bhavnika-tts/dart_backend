import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  final authHeader = context.request.headers['authorization'];
  final claims = JwtService.instance.verifyAuthHeader(authHeader);
  if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Admin access required'},
    );
  }

  final col = MongoClient.instance.collection('usercategorypermissions');
  final prodCatCol = MongoClient.instance.collection('productcategories');

  if (context.request.method == HttpMethod.get) {
    try {
      final list = await col.find(where.sortBy('categoryKey')).toList();
      final prodCats = await prodCatCol.find().toList();
      final prodCatMap = <String, Map<String, dynamic>>{};

      for (final pc in prodCats) {
        final id = ModelHelpers.idToString(pc['_id']);
        if (id != null) {
          prodCatMap[id] = {
            '_id': id,
            'label': pc['label']?.toString() ?? '',
          };
        }
      }

      final transformed = list.map((doc) {
        final id = ModelHelpers.idToString(doc['_id']) ?? '';
        final rawRead = doc['read'] is List ? (doc['read'] as List) : <dynamic>[];
        final rawWrite = doc['write'] is List ? (doc['write'] as List) : <dynamic>[];

        final populatedRead = rawRead.map((item) {
          final sId = ModelHelpers.idToString(item) ?? '';
          return prodCatMap[sId] ?? {'_id': sId, 'label': sId};
        }).toList();

        final populatedWrite = rawWrite.map((item) {
          final sId = ModelHelpers.idToString(item) ?? '';
          return prodCatMap[sId] ?? {'_id': sId, 'label': sId};
        }).toList();

        return {
          '_id': id,
          'categoryKey': doc['categoryKey']?.toString() ?? '',
          'label': doc['label']?.toString() ?? '',
          'displayName': doc['displayName']?.toString() ?? doc['label']?.toString() ?? doc['categoryKey']?.toString() ?? '',
          'read': populatedRead,
          'write': populatedWrite,
          'readOrder': populatedRead,
          'writeOrder': populatedWrite,
          'requiresAdminVerification': ModelHelpers.parseBool(doc['requiresAdminVerification']),
          'verificationType': doc['verificationType']?.toString() ?? 'none',
          'isHidden': ModelHelpers.parseBool(doc['isHidden']),
          'updatedBy': ModelHelpers.idToString(doc['updatedBy']),
          'createdAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(doc['createdAt'])),
          'updatedAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(doc['updatedAt'])),
        };
      }).toList();

      return Response.json(
        body: {
          'success': true,
          'permissions': transformed,
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to fetch user category permissions', 'error': e.toString()},
      );
    }
  }

  if (context.request.method == HttpMethod.post) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final result = await col.insertOne(body);
      return Response.json(
        body: {
          'success': true,
          'message': 'User category permission created',
          'id': result.id.toString(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to create user category permission', 'error': e.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
