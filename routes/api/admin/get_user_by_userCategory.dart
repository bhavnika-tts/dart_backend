import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/crypto.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:dart_frog_backend/models/user.dart';
import 'package:dart_frog_backend/services/imagekit_service.dart';
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
    final userCategory = query['userCategory'];
    final assignedByAdmin = query['assignedByAdmin'];

    var selector = where.eq('isDeleted', false);

    if (claims.role == 'subadmin') {
      final subadminObjId = ModelHelpers.toObjectId(claims.userId);
      if (subadminObjId != null) {
        selector = selector.eq('assignedByAdmin', subadminObjId);
      }
    } else if (assignedByAdmin != null && assignedByAdmin.isNotEmpty) {
      final adminObjId = ModelHelpers.toObjectId(assignedByAdmin);
      if (adminObjId != null) {
        selector = selector.eq('assignedByAdmin', adminObjId);
      }
    }

    if (userCategory != null && userCategory.isNotEmpty) {
      selector = selector.eq('userCategory', userCategory);
    }

    final usersCol = MongoClient.instance.collection('users');
    final stream = usersCol.find(selector.sortBy('createdAt', descending: true));
    final rawUsers = await stream.toList();

    final users = rawUsers.map((bson) {
      final u = User.fromBson(bson);
      final json = u.toJson();

      final rawAadhaar = u.aadharNumber.isNotEmpty ? u.aadharNumber.last : '';
      final decrypted = CryptoService.instance.decryptAesGcm(rawAadhaar);
      json['aadharNumber'] = CryptoService.maskAadhaar(decrypted);

      return ImageKitService.instance.signImageKitUrls(json);
    }).toList();

    return Response.json(
      body: {
        'success': true,
        'users': users,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error', 'error': error.toString()},
    );
  }
}
