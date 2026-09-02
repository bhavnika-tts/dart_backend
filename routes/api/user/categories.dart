import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/services/user_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final categories = await UserService.instance.getPublicCategories();
    return Response.json(
      body: {
        'success': true,
        'categories': categories,
        'data': categories,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'message': 'Internal server error', 'error': error.toString()},
    );
  }
}
