import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}
class _MockRequest extends Mock implements Request {}

void main() {
  group('GET / (Index Page & API Docs)', () {
    test('responds with 200 and interactive HTML API documentation for browser', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.headers).thenReturn({'accept': 'text/html,application/xhtml+xml'});
      when(() => request.uri).thenReturn(Uri.parse('http://localhost:8080/'));
      when(() => context.request).thenReturn(request);

      final response = route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.headers['content-type'], contains('text/html'));

      final bodyString = await response.body();
      expect(bodyString, contains('Classicale Backend API Explorer'));
      expect(bodyString, contains('Quick Jump to API Index'));
      expect(bodyString, contains('/api/user/login'));
    });

    test('responds with 200 and JSON metadata when Accept: application/json requested', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.headers).thenReturn({'accept': 'application/json'});
      when(() => request.uri).thenReturn(Uri.parse('http://localhost:8080/'));
      when(() => context.request).thenReturn(request);

      final response = route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));

      final bodyString = await response.body();
      final json = jsonDecode(bodyString) as Map<String, dynamic>;

      expect(json['status'], equals('ok'));
      expect(json['message'], equals('Classicale Backend API is running'));
      expect(json['totalEndpoints'], isPositive);
    });
  });
}
