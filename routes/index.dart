import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  print('Hello, World!');
  return Response(body: 'Hello, World!');
}
