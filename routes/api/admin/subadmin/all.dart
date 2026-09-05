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
    if (claims == null || claims.role != 'superadmin') {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Superadmin privileges required'},
      );
    }

    final adminCol = MongoClient.instance.collection('admins');
    final permCol = MongoClient.instance.collection('adminpermissions');
    final userCol = MongoClient.instance.collection('users');

    final subadminDocs = await adminCol
        .find(where.eq('role', 'subadmin').sortBy('createdAt', descending: true))
        .toList();

    final subadminsWithPermissions = <Map<String, dynamic>>[];
    for (final doc in subadminDocs) {
      final subadminId = doc['_id'];
      final userCount = await userCol.count({'assignedByAdmin': subadminId});

      Map<String, dynamic>? permissions;
      if (subadminId != null) {
        final permDoc = await permCol.findOne(where.eq('adminId', subadminId));
        if (permDoc != null) {
          final permsMap = permDoc['permissions'] is Map ? Map<String, dynamic>.from(permDoc['permissions'] as Map) : <String, dynamic>{};
          permissions = {
            ...permsMap,
            'assigned_access_codes': permDoc['assigned_access_codes'] ?? [],
          };
        }
      }

      final cleanDoc = <String, dynamic>{};
      doc.forEach((k, v) {
        if (k == 'password') return;
        if (k == '_id') {
          cleanDoc['_id'] = ModelHelpers.idToString(v);
        } else if (v is DateTime) {
          cleanDoc[k] = ModelHelpers.toIsoString(v);
        } else {
          cleanDoc[k] = v;
        }
      });
      cleanDoc['userCount'] = userCount;
      cleanDoc['permissions'] = permissions;

      subadminsWithPermissions.add(cleanDoc);
    }

    return Response.json(
      body: {
        'message': 'Subadmins fetched successfully',
        'subadmins': subadminsWithPermissions,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch subadmins', 'error': error.toString()},
    );
  }
}
