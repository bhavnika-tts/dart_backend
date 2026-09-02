import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/repositories/location_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final repository = LocationRepository.instance;
    final query = context.request.uri.queryParameters['search'];

    if (query != null && query.isNotEmpty) {
      final results = await repository.searchLocations(query);
      return Response.json(body: {'locations': results});
    }

    final data = await repository.getUniqueLocations();
    return Response.json(body: data);
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Internal server error', 'error': error.toString()},
    );
  }
}
