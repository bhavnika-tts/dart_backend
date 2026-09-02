import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/chat_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final query = context.request.uri.queryParameters;
    var userId = query['userId'];
    final q = query['q'] ?? query['query'] ?? query['search'] ?? '';

    if (userId == null || userId.isEmpty) {
      final authHeader = context.request.headers['authorization'];
      final claims = JwtService.instance.verifyAuthHeader(authHeader);
      if (claims != null) {
        userId = claims.userId;
      }
    }

    if (userId == null || userId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'userId is required'},
      );
    }

    final list = await ChatService.instance.getUserConversations(userId);
    final filtered = list.where((conv) {
      final other = conv['otherUser'] as Map<String, dynamic>?;
      final fName = other?['fName']?.toString() ?? '';
      final lName = other?['lName']?.toString() ?? '';
      final prod = conv['productDetails'] as Map<String, dynamic>?;
      final title = prod?['title']?.toString() ?? '';

      final target = '$fName $lName $title'.toLowerCase();
      return target.contains(q.toLowerCase());
    }).toList();

    return Response.json(
      body: {
        'success': true,
        'conversations': filtered,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Search failed', 'error': error.toString()},
    );
  }
}
