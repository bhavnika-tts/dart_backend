import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/feature_request.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  final collection = MongoClient.instance.collection('feature_requests');

  if (context.request.method == HttpMethod.post) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      var userId = body['userId']?.toString();
      final title = body['title']?.toString() ?? body['featureTitle']?.toString() ?? '';
      final description = body['description']?.toString() ?? '';

      final authHeader = context.request.headers['authorization'];
      final claims = JwtService.instance.verifyAuthHeader(authHeader);
      if (claims != null) {
        userId = claims.userId;
      }

      if (title.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'title is required'},
        );
      }

      final req = FeatureRequest(
        userId: userId ?? 'anonymous',
        title: title,
        description: description,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final doc = req.toBson();
      final res = await collection.insertOne(doc);

      return Response.json(
        body: {
          'success': true,
          'message': 'Feature request submitted successfully',
          'id': res.id.toString(),
        },
      );
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to submit feature request', 'error': error.toString()},
      );
    }
  }

  if (context.request.method == HttpMethod.get) {
    try {
      final stream = collection.find(where.sortBy('createdAt', descending: true).limit(50));
      final list = await stream.toList();
      return Response.json(
        body: {
          'success': true,
          'feature_requests': list.map(FeatureRequest.fromBson).map((f) => f.toJson()).toList(),
        },
      );
    } catch (error) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to fetch feature requests', 'error': error.toString()},
      );
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
