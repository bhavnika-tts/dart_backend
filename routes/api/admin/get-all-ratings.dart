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
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    final query = context.request.uri.queryParameters;
    final page = int.tryParse(query['page'] ?? '1') ?? 1;
    final limit = int.tryParse(query['limit'] ?? '10') ?? 10;
    final skip = (page - 1) * limit;

    final ratingsCol = MongoClient.instance.collection('ratings');
    final usersCol = MongoClient.instance.collection('users');

    final totalCount = await ratingsCol.count();

    final ratingsDocs = await ratingsCol
        .find(where.sortBy('createdAt', descending: true).skip(skip).limit(limit))
        .toList();

    final totalPages = (totalCount / limit).ceil();

    if (ratingsDocs.isEmpty) {
      return Response.json(
        statusCode: 201,
        body: {
          'status': 201,
          'data': <dynamic>[],
          'message': 'No ratings found',
          'pagination': {
            'totalItems': 0,
            'currentPage': page,
            'totalPages': 0,
            'pageSize': limit,
          },
        },
      );
    }

    final transformedRatings = <Map<String, dynamic>>[];
    for (final r in ratingsDocs) {
      final ratingMap = <String, dynamic>{
        '_id': ModelHelpers.idToString(r['_id']),
        'rating': ModelHelpers.parseDouble(r['rating']) ?? 0.0,
        if (r['comment'] != null) 'comment': r['comment'],
        if (r['createdAt'] != null)
          'createdAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(r['createdAt'])),
        if (r['updatedAt'] != null)
          'updatedAt': ModelHelpers.toIsoString(ModelHelpers.parseDateTime(r['updatedAt'])),
      };

      final userVal = r['user'];
      ObjectId? userObjId;
      if (userVal is ObjectId) {
        userObjId = userVal;
      } else if (userVal is String) {
        try {
          userObjId = ObjectId.fromHexString(userVal);
        } catch (_) {}
      }

      if (userObjId != null) {
        final userDoc = await usersCol.findOne(
          where.eq('_id', userObjId).fields(['fName', 'lName', 'mName', 'email', 'profileImage']),
        );
        if (userDoc != null) {
          final uMap = <String, dynamic>{
            '_id': ModelHelpers.idToString(userDoc['_id']),
            'fName': userDoc['fName'] is List ? (userDoc['fName'] as List).last : userDoc['fName'],
            'lName': userDoc['lName'] is List ? (userDoc['lName'] as List).last : userDoc['lName'],
            'mName': userDoc['mName'] is List ? (userDoc['mName'] as List).last : userDoc['mName'],
            'email': userDoc['email'] is List ? (userDoc['email'] as List).last : userDoc['email'],
            'profileImage': userDoc['profileImage'] is List
                ? (userDoc['profileImage'] as List).last
                : userDoc['profileImage'],
          };
          ratingMap['user'] = uMap;
        } else {
          ratingMap['user'] = userVal?.toString();
        }
      } else {
        ratingMap['user'] = userVal?.toString();
      }

      transformedRatings.add(ratingMap);
    }

    return Response.json(
      body: {
        'status': 200,
        'data': transformedRatings,
        'message': 'Ratings fetched successfully',
        'pagination': {
          'totalItems': totalCount,
          'currentPage': page,
          'totalPages': totalPages,
          'pageSize': limit,
          'hasNextPage': page < totalPages,
          'hasPrevPage': page > 1,
        },
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'status': 500, 'message': 'Server error', 'error': error.toString()},
    );
  }
}

