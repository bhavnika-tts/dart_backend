import 'dart:io';
import 'dart:math';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/crypto.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
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

    final body = await context.request.json() as Map<String, dynamic>;
    final username = body['username']?.toString() ?? '';
    final email = body['email']?.toString() ?? '';
    final password = body['password']?.toString() ?? '';

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'All fields are required'},
      );
    }

    final adminCol = MongoClient.instance.collection('admins');
    final existingAdmin = await adminCol.findOne(where.eq('email', email));
    if (existingAdmin != null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'Admin with this email already exists'},
      );
    }

    final hashedPassword = await CryptoService.instance.hashPassword(password);

    // Generate unique 4-digit referral code
    final rnd = Random();
    String? referralCode;
    var isUnique = false;
    while (!isUnique) {
      referralCode = (1000 + rnd.nextInt(9000)).toString();
      final existingCode = await adminCol.findOne(where.eq('referralCode', referralCode));
      if (existingCode == null) {
        isUnique = true;
      }
    }

    final newSubadminId = ObjectId();
    final newSubadmin = <String, dynamic>{
      '_id': newSubadminId,
      'username': username,
      'email': email,
      'password': hashedPassword,
      'role': 'subadmin',
      'fName': body['fName']?.toString() ?? '',
      'lName': body['lName']?.toString() ?? '',
      'mName': body['mName']?.toString() ?? '',
      'phone': body['phone']?.toString() ?? '',
      'country': body['country']?.toString() ?? '',
      'state': body['state']?.toString() ?? '',
      'city': body['city']?.toString() ?? '',
      'area': body['area']?.toString() ?? '',
      'street1': body['street1']?.toString() ?? '',
      'street2': body['street2']?.toString() ?? '',
      'pinCode': body['pinCode']?.toString() ?? '',
      'gender': body['gender']?.toString() ?? '',
      'DOB': body['DOB']?.toString() ?? '',
      'profileImage': body['profileImage']?.toString() ?? '',
      'referralCode': referralCode,
      'createdAt': DateTime.now().toUtc(),
      'updatedAt': DateTime.now().toUtc(),
      '__v': 0,
    };

    await adminCol.insertOne(newSubadmin);

    // Default permissions
    final permCol = MongoClient.instance.collection('adminpermissions');
    await permCol.insertOne({
      '_id': ObjectId(),
      'adminId': newSubadminId,
      'permissions': {
        'dashboard': {'read': false, 'write': false},
        'product': {'read': false, 'write': false},
        'user': {'read': false, 'write': false},
        'access_code': {'read': false, 'write': false},
        'reports': {'read': false, 'write': false},
        'chat_reports': {'read': false, 'write': false},
        'app_versions': {'read': false, 'write': false},
        'feature_request': {'read': false, 'write': false},
        'reviews': {'read': false, 'write': false},
        'support_chat': {'read': false, 'write': false},
        'about_us': {'read': false, 'write': false},
        'app_guide': {'read': false, 'write': false},
        'banners': {'read': false, 'write': false},
        'occupation': {'read': false, 'write': false},
        'sub_product_types': {'read': false, 'write': false},
      },
      'createdAt': DateTime.now().toUtc(),
      'updatedAt': DateTime.now().toUtc(),
      '__v': 0,
    });

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'message': 'Subadmin created successfully',
        'subadmin': {
          'id': ModelHelpers.idToString(newSubadminId),
          'username': username,
          'email': email,
          'role': 'subadmin',
        },
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error'},
    );
  }
}
