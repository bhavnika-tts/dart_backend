import 'dart:io';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final contentType = context.request.headers['content-type'] ?? '';
    final body = <String, dynamic>{};
    Uint8List? profileBytes;
    String? profileName;
    Uint8List? aadhaarFrontBytes;
    String? aadhaarFrontName;
    Uint8List? aadhaarBackBytes;
    String? aadhaarBackName;

    if (contentType.contains('multipart/form-data')) {
      final formData = await context.request.formData();
      body.addAll(formData.fields);

      final profileFile = formData.files['profileImage'];
      if (profileFile != null) {
        profileBytes = Uint8List.fromList(await profileFile.readAsBytes());
        profileName = profileFile.name;
      }

      final frontFile = formData.files['aadhaarFront'];
      if (frontFile != null) {
        aadhaarFrontBytes = Uint8List.fromList(await frontFile.readAsBytes());
        aadhaarFrontName = frontFile.name;
      }

      final backFile = formData.files['aadhaarBack'];
      if (backFile != null) {
        aadhaarBackBytes = Uint8List.fromList(await backFile.readAsBytes());
        aadhaarBackName = backFile.name;
      }
    } else {
      final json = await context.request.json() as Map<String, dynamic>;
      body.addAll(json);
    }

    final service = AuthService.instance;
    final result = await service.signup(
      body: body,
      profileImageBytes: profileBytes,
      profileImageName: profileName,
      aadhaarFrontBytes: aadhaarFrontBytes,
      aadhaarFrontName: aadhaarFrontName,
      aadhaarBackBytes: aadhaarBackBytes,
      aadhaarBackName: aadhaarBackName,
    );

    return Response.json(
      statusCode: HttpStatus.created,
      body: result,
    );
  } catch (error) {
    final msg = error is ArgumentError
        ? error.message.toString()
        : error is StateError
            ? error.message
            : error.toString();

    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': msg},
    );
  }
}
