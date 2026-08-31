import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/docs/api_catalog.dart';
import 'package:dart_frog_backend/docs/api_docs_html.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final acceptHeader = context.request.headers['accept'] ?? '';
  final queryParams = context.request.uri.queryParameters;
  final wantsJson = queryParams['format'] == 'json' ||
      (acceptHeader.contains('application/json') &&
          !acceptHeader.contains('text/html'));

  if (wantsJson) {
    return Response.json(
      body: {
        'status': 'ok',
        'message': 'Classicale Backend API is running',
        'totalEndpoints': ApiCatalog.endpoints.length,
        'docs': ApiCatalog.endpoints
            .map((e) => {
                  'index': e.index,
                  'method': e.method,
                  'path': e.path,
                  'category': e.category,
                  'title': e.title,
                  'description': e.description,
                  'requiresAuth': e.requiresAuth,
                  'requiresAdmin': e.requiresAdmin,
                })
            .toList(),
      },
    );
  }

  return Response(
    body: ApiDocsRenderer.render(),
    headers: {
      'content-type': 'text/html; charset=utf-8',
    },
  );
}
