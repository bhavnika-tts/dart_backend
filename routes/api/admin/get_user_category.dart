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

    final usersCol = MongoClient.instance.collection('users');
    final userCatPermCol = MongoClient.instance.collection('usercategorypermissions');

    final catPerms = await userCatPermCol.find().toList();
    final allCategoryKeys = catPerms.map((c) => c['categoryKey']?.toString()).whereType<String>().toSet();

    final userList = await usersCol.find(
      claims.role == 'subadmin'
          ? where.eq('assignedByAdmin', ModelHelpers.toObjectId(claims.userId))
          : where.eq('isDeleted', false),
    ).toList();

    final countMap = <String, int>{};
    for (final key in allCategoryKeys) {
      countMap[key] = 0;
    }

    for (final u in userList) {
      final cat = u['userCategory']?.toString();
      if (cat != null && cat.isNotEmpty) {
        countMap[cat] = (countMap[cat] ?? 0) + 1;
      }
    }

    final userCategoriesWithCount = countMap.entries
        .map((e) => {'category': e.key, 'count': e.value})
        .toList();

    return Response.json(
      body: {
        'message': 'User categories fetched successfully',
        'userCategories': userCategoriesWithCount,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error', 'error': error.toString()},
    );
  }
}
