import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/crypto.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final authHeader = context.request.headers['authorization'];
  final claims = JwtService.instance.verifyAuthHeader(authHeader);
  if (claims == null || claims.role != 'superadmin') {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Superadmin privileges required'},
    );
  }

  final objId = ModelHelpers.toObjectId(id);
  final adminCol = MongoClient.instance.collection('admins');
  final permCol = MongoClient.instance.collection('adminpermissions');

  final selector = objId != null
      ? where.id(objId).eq('role', 'subadmin')
      : where.eq('_id', id).eq('role', 'subadmin');

  final subadminDoc = await adminCol.findOne(selector);
  if (subadminDoc == null) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'message': 'Subadmin not found'},
    );
  }

  if (context.request.method == HttpMethod.get) {
    final permDoc = await permCol.findOne(where.eq('adminId', subadminDoc['_id']));
    final subadminMap = Map<String, dynamic>.from(subadminDoc);
    subadminMap.remove('password');
    subadminMap['_id'] = ModelHelpers.idToString(subadminMap['_id']);
    if (subadminMap['createdAt'] is DateTime) {
      subadminMap['createdAt'] = (subadminMap['createdAt'] as DateTime).toIso8601String();
    }
    if (subadminMap['updatedAt'] is DateTime) {
      subadminMap['updatedAt'] = (subadminMap['updatedAt'] as DateTime).toIso8601String();
    }

    if (permDoc != null) {
      final perms = Map<String, dynamic>.from(permDoc['permissions'] as Map? ?? {});
      perms['assigned_access_codes'] = permDoc['assigned_access_codes'];
      subadminMap['permissions'] = perms;
    } else {
      subadminMap['permissions'] = null;
    }

    return Response.json(
      body: {
        'message': 'Subadmin fetched successfully',
        'subadmin': subadminMap,
      },
    );
  }

  if (context.request.method == HttpMethod.put) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final mod = modify.set('updatedAt', DateTime.now().toUtc());

      if (body['username'] != null) mod.set('username', body['username']);
      if (body['email'] != null) {
        final email = body['email'].toString();
        final existingEmail = await adminCol.findOne(
          where.eq('email', email).ne('_id', subadminDoc['_id']),
        );
        if (existingEmail != null) {
          return Response.json(
            statusCode: HttpStatus.badRequest,
            body: {'message': 'Email already in use'},
          );
        }
        mod.set('email', email);
      }
      if (body['password'] != null && body['password'].toString().isNotEmpty) {
        final hashedPassword = await CryptoService.instance.hashPassword(body['password'].toString());
        mod.set('password', hashedPassword);
        final curVersion = (subadminDoc['tokenVersion'] as num?)?.toInt() ?? 0;
        mod.set('tokenVersion', curVersion + 1);
        mod.set('passwordChangedAt', DateTime.now().toUtc());
      }

      for (final field in [
        'fName', 'lName', 'mName', 'phone', 'country', 'state', 'city',
        'area', 'street1', 'street2', 'pinCode', 'gender', 'DOB', 'profileImage'
      ]) {
        if (body.containsKey(field) && body[field] != null) {
          mod.set(field, body[field]);
        }
      }

      await adminCol.updateOne(where.id(subadminDoc['_id'] as ObjectId), mod);
      final updated = await adminCol.findOne(where.id(subadminDoc['_id'] as ObjectId));

      return Response.json(
        body: {
          'message': 'Subadmin updated successfully',
          'subadmin': {
            'id': ModelHelpers.idToString(updated?['_id']),
            'username': updated?['username'],
            'email': updated?['email'],
            'role': updated?['role'],
          },
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Server error'},
      );
    }
  }

  if (context.request.method == HttpMethod.delete) {
    try {
      await adminCol.deleteOne(where.id(subadminDoc['_id'] as ObjectId));
      await permCol.deleteOne(where.eq('adminId', subadminDoc['_id']));

      return Response.json(
        body: {'message': 'Subadmin deleted successfully'},
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Server error'},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
