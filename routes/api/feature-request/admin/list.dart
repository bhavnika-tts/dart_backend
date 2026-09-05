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
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin' && claims.role != 'admin')) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    final col = MongoClient.instance.collection('featurerequests');
    final userCol = MongoClient.instance.collection('users');

    final list = await col.find(where.sortBy('createdAt', descending: true)).toList();

    final populatedList = <Map<String, dynamic>>[];
    for (final doc in list) {
      final uVal = doc['userId'];
      ObjectId? uObjId;
      if (uVal is ObjectId) {
        uObjId = uVal;
      } else if (uVal is String) {
        try {
          uObjId = ObjectId.fromHexString(uVal);
        } catch (_) {}
      }

      Map<String, dynamic>? userMap;
      if (uObjId != null) {
        final uDoc = await userCol.findOne(
          where.eq('_id', uObjId).fields(['name', 'email', 'fName', 'lName', 'mName', 'profileImage']),
        );
        if (uDoc != null) {
          userMap = {
            '_id': ModelHelpers.idToString(uDoc['_id']),
            'name': uDoc['name'] ?? '',
            'email': uDoc['email'] is List ? (uDoc['email'] as List).last : (uDoc['email'] ?? ''),
            'fName': uDoc['fName'] is List ? (uDoc['fName'] as List).last : (uDoc['fName'] ?? ''),
            'lName': uDoc['lName'] is List ? (uDoc['lName'] as List).last : (uDoc['lName'] ?? ''),
            'mName': uDoc['mName'] is List ? (uDoc['mName'] as List).last : (uDoc['mName'] ?? ''),
            'profileImage': uDoc['profileImage'] is List
                ? (uDoc['profileImage'] as List).last
                : (uDoc['profileImage'] ?? ''),
          };
        }
      }

      populatedList.add({
        '_id': ModelHelpers.idToString(doc['_id']),
        'title': doc['title'] ?? '',
        'description': doc['description'] ?? '',
        'status': doc['status'] ?? 'pending',
        'statusMessage': doc['statusMessage'] ?? '',
        'userId': userMap ?? (uVal?.toString()),
        if (doc['createdAt'] != null)
          'createdAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(doc['createdAt'])),
        if (doc['updatedAt'] != null)
          'updatedAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(doc['updatedAt'])),
      });
    }

    return Response.json(
      body: {
        'success': true,
        'data': populatedList,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error', 'error': error.toString()},
    );
  }
}
