import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
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
    if (claims == null || (claims.role != 'superadmin' && claims.role != 'subadmin')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Unauthorized'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final productType = body['productType']?.toString();
    final key = body['key']?.toString();
    final label = body['label']?.toString();
    final type = body['type']?.toString();

    if (productType == null || productType.isEmpty ||
        key == null || key.isEmpty ||
        label == null || label.isEmpty ||
        type == null || type.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'productType, key, label, and type are required'},
      );
    }

    final subProductType = body['subProductType']?.toString();
    final col = MongoClient.instance.collection('formmetadatas');

    final existing = await col.findOne(
      where
          .eq('productType', productType)
          .eq('subProductType', (subProductType != null && subProductType.isNotEmpty) ? subProductType : null)
          .eq('key', key),
    );

    if (existing != null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': "Field with key '$key' already exists in this category."},
      );
    }

    var subTypes = (body['subProductTypes'] as List?)?.map((e) => e.toString()).toList() ?? [];
    if (subTypes.isEmpty && subProductType != null && subProductType.isNotEmpty) {
      subTypes = [subProductType];
    }

    final newDoc = <String, dynamic>{
      '_id': ObjectId(),
      'productType': productType,
      'subProductType': (subProductType != null && subProductType.isNotEmpty) ? subProductType : null,
      'subProductTypes': subTypes,
      'key': key,
      'label': label,
      'type': type,
      'isOptional': body['isOptional'] ?? true,
      'isHidden': body['isHidden'] ?? false,
      'isSystemField': body['isSystemField'] ?? false,
      'unit': body['unit'] ?? '',
      'options': body['options'] ?? [],
      'defaultValue': body['defaultValue'] ?? '',
      'displayOrder': body['displayOrder'] ?? 0,
      'groupName': body['groupName'] ?? 'Specifications',
      'isHighlight': body['isHighlight'] ?? false,
      'cardDisplayOrder': body['cardDisplayOrder'] ?? 0,
      'isFilterable': body['isFilterable'] ?? true,
      'validation': body['validation'] ?? {},
      'placeholder': body['placeholder'] ?? '',
      'helpText': body['helpText'] ?? '',
      'createdAt': DateTime.now().toUtc(),
      'updatedAt': DateTime.now().toUtc(),
      '__v': 0,
    };

    await col.insertOne(newDoc);

    final sanitized = Map<String, dynamic>.from(newDoc);
    sanitized['_id'] = ModelHelpers.idToString(sanitized['_id']);
    sanitized['createdAt'] = (sanitized['createdAt'] as DateTime).toIso8601String();
    sanitized['updatedAt'] = (sanitized['updatedAt'] as DateTime).toIso8601String();

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'message': 'Field metadata created successfully',
        'field': sanitized,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Server error!', 'error': error.toString()},
    );
  }
}
