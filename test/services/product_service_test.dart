import 'package:dart_frog_backend/models/product.dart';
import 'package:test/test.dart';

void main() {
  group('ProductModel & LocationPoint', () {
    test('LocationPoint correctly parses GeoJSON coordinates', () {
      final point = LocationPoint.fromBson({
        'type': 'Point',
        'coordinates': [72.5714, 23.0225],
      });

      expect(point.longitude, equals(72.5714));
      expect(point.latitude, equals(23.0225));
    });

    test('Product serialization preserves fields and specs Map', () {
      final product = Product(
        userId: '507f1f77bcf86cd799439011',
        title: 'Honda City VX',
        price: 850000,
        categories: 'car',
        productType: '507f1f77bcf86cd799439022',
        specs: {
          'fuel': 'Petrol',
          'transmission': 'Manual',
          'kmDriven': 45000,
        },
      );

      final json = product.toJson();
      expect(json['title'], equals('Honda City VX'));
      expect(json['price'], equals(850000.0));
      expect(json['specs']['fuel'], equals('Petrol'));

      final restored = Product.fromJson(json);
      expect(restored.title, equals('Honda City VX'));
      expect(restored.specs['kmDriven'], equals(45000));
    });
  });
}
