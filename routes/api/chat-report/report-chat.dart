import 'dart:io';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/models/chat_report.dart';
import 'package:dart_frog_backend/services/imagekit_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    String? reporterId;
    String? reportedUserId;
    String? conversationId;
    String? reason;
    String? description;
    String? screenshotUrl;

    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims != null) {
      reporterId = claims.userId;
    }

    final contentType = context.request.headers['content-type'] ?? '';
    if (contentType.contains('multipart/form-data')) {
      final formData = await context.request.formData();
      reporterId ??= formData.fields['reporterId'] ?? formData.fields['userId'];
      reportedUserId = formData.fields['reportedUserId'] ?? formData.fields['reportedUser'];
      conversationId = formData.fields['conversationId'] ?? formData.fields['chatId'];
      reason = formData.fields['reason'];
      description = formData.fields['description'];

      final file = formData.files['screenshot'] ?? formData.files['image'];
      if (file != null) {
        final bytes = Uint8List.fromList(await file.readAsBytes());
        screenshotUrl = await ImageKitService.instance.uploadBytes(
          bytes: bytes,
          fileName: file.name,
          folder: '/reports/chat',
        );
      }
    } else {
      final body = await context.request.json() as Map<String, dynamic>;
      reporterId ??= body['reporterId']?.toString() ?? body['userId']?.toString();
      reportedUserId = body['reportedUserId']?.toString() ?? body['reportedUser']?.toString();
      conversationId = body['conversationId']?.toString() ?? body['chatId']?.toString();
      reason = body['reason']?.toString();
      description = body['description']?.toString();
      screenshotUrl = body['screenshot']?.toString();
    }

    if (reportedUserId == null || reportedUserId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'message': 'reportedUserId is required'},
      );
    }

    final report = ChatReport(
      reportedBy: reporterId ?? 'anonymous',
      reportedUser: reportedUserId,
      conversationId: conversationId,
      description: description ?? reason ?? 'Inappropriate message',
      image: screenshotUrl,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final collection = MongoClient.instance.collection('chat_reports');
    final doc = report.toBson();
    final res = await collection.insertOne(doc);

    return Response.json(
      body: {
        'success': true,
        'message': 'Chat reported successfully',
        'reportId': res.id.toString(),
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to report chat', 'error': error.toString()},
    );
  }
}
