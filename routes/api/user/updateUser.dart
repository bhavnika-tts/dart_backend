import 'dart:io';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/user_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final contentType = context.request.headers['content-type'] ?? '';
    final body = <String, dynamic>{};
    Uint8List? profileBytes;
    String? profileName;
    Uint8List? aadhaar1Bytes;
    String? aadhaar1Name;
    Uint8List? aadhaar2Bytes;
    String? aadhaar2Name;

    if (contentType.contains('multipart/form-data')) {
      final formData = await context.request.formData();
      body.addAll(formData.fields);

      final profileFile = formData.files['profileImage'];
      if (profileFile != null) {
        profileBytes = Uint8List.fromList(await profileFile.readAsBytes());
        profileName = profileFile.name;
      }

      final a1File = formData.files['aadhaarImage1'];
      if (a1File != null) {
        aadhaar1Bytes = Uint8List.fromList(await a1File.readAsBytes());
        aadhaar1Name = a1File.name;
      }

      final a2File = formData.files['aadhaarImage2'];
      if (a2File != null) {
        aadhaar2Bytes = Uint8List.fromList(await a2File.readAsBytes());
        aadhaar2Name = a2File.name;
      }
    } else {
      final json = await context.request.json() as Map<String, dynamic>;
      body.addAll(json);
    }

    var userId = body['userId']?.toString().trim();
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

    final service = UserService.instance;
    final result = await service.updateUserProfile(
      userId,
      body,
      profileBytes: profileBytes,
      profileName: profileName,
      aadhaar1Bytes: aadhaar1Bytes,
      aadhaar1Name: aadhaar1Name,
      aadhaar2Bytes: aadhaar2Bytes,
      aadhaar2Name: aadhaar2Name,
    );

    return Response.json(body: result);
  } catch (error) {
    final msg = error is StateError ? error.message : error.toString();
    final status = msg.contains('not found')
        ? HttpStatus.notFound
        : msg.contains('contact customer support')
            ? HttpStatus.forbidden
            : HttpStatus.badRequest;

    return Response.json(
      statusCode: status,
      body: {'message': msg},
    );
  }
}
