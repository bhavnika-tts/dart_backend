import 'package:mongo_dart/mongo_dart.dart';
import '../core/db/mongo_client.dart';
import '../models/brand_model.dart';
import '../models/model_helpers.dart';

class _CacheEntry<T> {
  _CacheEntry(this.data, this.expiresAt);
  final T data;
  final DateTime expiresAt;
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// Repository for BrandModel collection with 1-hour in-memory cache and Levenshtein cascade helpers.
class BrandModelRepository {
  BrandModelRepository({MongoClient? mongoClient})
      : _mongoClient = mongoClient ?? MongoClient.instance;

  final MongoClient _mongoClient;

  static BrandModelRepository? _instance;
  static BrandModelRepository get instance => _instance ??= BrandModelRepository();

  DbCollection get _collection => _mongoClient.collection('brandmodels');

  static const _cacheTtl = Duration(hours: 1);
  final _brandsCache = <String, _CacheEntry<List<String>>>{};
  final _modelsCache = <String, _CacheEntry<List<String>>>{};

  static String normalizeProductType(String? productType) {
    if (productType == null) return '';
    return productType.toLowerCase().replaceAll('_', ' ').trim();
  }

  void invalidateCacheForType(String productType) {
    final normType = normalizeProductType(productType);
    _brandsCache.remove(normType);
    _modelsCache.removeWhere((key, _) => key.startsWith('$normType::'));
  }

  void clearAllCache() {
    _brandsCache.clear();
    _modelsCache.clear();
  }

  /// Returns sorted brand list for product type with in-memory caching and "Other" fallback.
  Future<({List<String> brands, bool fromCache})> getBrandsForType(String productType) async {
    final type = normalizeProductType(productType);
    if (type.isEmpty) return (brands: <String>[], fromCache: false);

    final cached = _brandsCache[type];
    if (cached != null && cached.isValid) {
      return (brands: cached.data, fromCache: true);
    }

    final cursor = _collection.find(
      where.eq('productType', type).eq('isActive', true).sortBy('displayOrder').sortBy('brand'),
    );

    final list = await cursor.toList();
    final brands = list.map((e) => e['brand']?.toString().trim() ?? '').where((b) => b.isNotEmpty).toList();

    if (!brands.contains('Other')) {
      brands.add('Other');
    }

    _brandsCache[type] = _CacheEntry(brands, DateTime.now().add(_cacheTtl));
    return (brands: brands, fromCache: false);
  }

  /// Returns models list for a specific brand in product type with in-memory caching.
  Future<({List<String> models, bool fromCache})> getModelsForBrand(String productType, String brand) async {
    final type = normalizeProductType(productType);
    final brandName = brand.trim();
    final cacheKey = '$type::$brandName';

    final cached = _modelsCache[cacheKey];
    if (cached != null && cached.isValid) {
      return (models: cached.data, fromCache: true);
    }

    final doc = await _collection.findOne(
      where.eq('productType', type).eq('brand', brandName).eq('isActive', true),
    );

    final models = (doc?['models'] as List?)?.map((e) => e.toString().trim()).where((m) => m.isNotEmpty).toList() ?? <String>[];

    _modelsCache[cacheKey] = _CacheEntry(models, DateTime.now().add(_cacheTtl));
    return (models: models, fromCache: false);
  }

  Future<List<BrandModel>> getAllBrandsAdmin({String? productType}) async {
    var selector = where.eq('isActive', true);
    if (productType != null && productType.isNotEmpty) {
      if (productType.contains(',')) {
        final types = productType.split(',').map(normalizeProductType).where((t) => t.isNotEmpty).toList();
        selector = where.oneFrom('productType', types);
      } else {
        selector = where.eq('productType', normalizeProductType(productType));
      }
    }

    final cursor = _collection.find(selector.sortBy('productType').sortBy('displayOrder').sortBy('brand'));
    final list = await cursor.toList();
    return list.map(BrandModel.fromBson).toList();
  }

  Future<BrandModel> createBrand(BrandModel model) async {
    final normType = normalizeProductType(model.productType);
    final brandName = model.brand.trim();

    final existing = await _collection.findOne(
      where.eq('productType', normType).eq('brand', brandName),
    );

    if (existing != null) {
      throw StateError("Brand '$brandName' already exists for type '$normType'.");
    }

    final doc = model.toBson();
    doc['productType'] = normType;
    doc['brand'] = brandName;
    doc['createdAt'] = DateTime.now();
    doc['updatedAt'] = DateTime.now();

    final result = await _collection.insertOne(doc);
    invalidateCacheForType(normType);

    return BrandModel.fromBson({...doc, '_id': result.id});
  }

  Future<BrandModel?> updateBrand(String id, Map<String, dynamic> data) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;

    final existing = await _collection.findOne(where.id(objId));
    if (existing == null) return null;

    final sanitized = <String, dynamic>{...data}
      ..remove('_id')
      ..['updatedAt'] = DateTime.now();
    if (sanitized['productType'] != null) {
      sanitized['productType'] = normalizeProductType(sanitized['productType'].toString());
    }

    for (final entry in sanitized.entries) {
      await _collection.updateOne(
        where.id(objId),
        modify.set(entry.key, entry.value),
      );
    }

    final updated = await _collection.findOne(where.id(objId));
    if (updated != null) {
      final brandModel = BrandModel.fromBson(updated);
      invalidateCacheForType(brandModel.productType);
      return brandModel;
    }
    return null;
  }

  Future<bool> deleteBrand(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return false;

    final existing = await _collection.findOne(where.id(objId));
    if (existing == null) return false;

    await _collection.updateOne(
      where.id(objId),
      modify.set('isActive', false).set('updatedAt', DateTime.now()),
    );

    invalidateCacheForType(existing['productType']?.toString() ?? '');
    return true;
  }
}
