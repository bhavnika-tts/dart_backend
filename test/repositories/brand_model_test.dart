import 'package:dart_frog_backend/repositories/brand_model_repository.dart';
import 'package:test/test.dart';

void main() {
  group('BrandModelRepository', () {
    test('normalizeProductType standardizes inputs correctly', () {
      expect(BrandModelRepository.normalizeProductType('Car'), equals('car'));
      expect(BrandModelRepository.normalizeProductType('four_wheeler'), equals('four wheeler'));
      expect(BrandModelRepository.normalizeProductType('  ELECTRIC_CAR  '), equals('electric car'));
      expect(BrandModelRepository.normalizeProductType(null), equals(''));
    });
  });
}
