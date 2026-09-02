import 'dart:convert';
import 'package:dart_frog_backend/models/sub_product_type.dart';
import 'package:test/test.dart';

void main() {
  test('SubProductType JSON serialization has no unconverted DateTimes', () {
    final sub = SubProductType(
      id: '67e65b4361d9fe71c6ce65cd',
      name: 'Test Sub',
      productType: '67e65b4361d9fe71c6ce65cd',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      history: [
        SubProductTypeHistory(
          updatedBy: '6a66c94b47a8cc75bb96cd85',
          updatedAt: DateTime.now(),
        ),
      ],
    );

    final json = sub.toJson();
    final encoded = jsonEncode(json);
    expect(encoded, isNotEmpty);
    expect(encoded, contains('Test Sub'));
  });
}
