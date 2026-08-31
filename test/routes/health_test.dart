import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/health.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}
class _MockRequest extends Mock implements Request {}

void main() {
  group('GET /health', () {
    test('responds with 200 and OK string', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => context.request).thenReturn(request);

      final response = route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(await response.body(), equals('OK'));
    });
  });
}
