import 'package:mongo_dart/mongo_dart.dart';
import '../core/db/mongo_client.dart';
import '../models/form_metadata.dart';
import '../models/model_helpers.dart';
import '../models/product.dart';
import '../models/product_type.dart';
import '../models/sub_product_type.dart';
import '../models/user.dart';

/// Repository handling MongoDB operations for Products, FormMetadata, ProductTypes, and Favorites.
class ProductRepository {
  ProductRepository({MongoClient? mongoClient})
      : _mongoClient = mongoClient ?? MongoClient.instance;

  final MongoClient _mongoClient;

  static ProductRepository? _instance;
  static ProductRepository get instance => _instance ??= ProductRepository();

  DbCollection get _productsCollection => _mongoClient.collection('products');
  DbCollection get _usersCollection => _mongoClient.collection('users');
  DbCollection get _productTypesCollection => _mongoClient.collection('producttypes');
  DbCollection get _subProductTypesCollection => _mongoClient.collection('subproducttypes');
  DbCollection get _formMetadataCollection => _mongoClient.collection('formmetadatas');

  Future<Product?> findById(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;

    final doc = await _productsCollection.findOne(where.id(objId));
    if (doc == null) return null;

    final product = Product.fromBson(doc);

    // Populate user details
    if (product.userId.isNotEmpty) {
      final userObjId = ModelHelpers.toObjectId(product.userId);
      if (userObjId != null) {
        final userDoc = await _usersCollection.findOne(
          where.id(userObjId).fields(['fName', 'lName', 'mName', 'email', 'phone', 'profileImage', 'state', 'district', 'country', 'area', 'userCategory']),
        );
        if (userDoc != null) {
          final u = User.fromBson(userDoc);
          return Product.fromBson({
            ...doc,
            'user': {
              'userId': u.id,
              'fName': u.fName,
              'lName': u.lName,
              'mName': u.mName,
              'email': u.email,
              'phone': u.phone,
              'profileImage': u.profileImage,
              'state': u.state,
              'district': u.district,
              'country': u.country,
              'area': u.area,
              'userCategory': u.userCategory,
            },
          });
        }
      }
    }

    return product;
  }

  Future<Product> create(Product product) async {
    final doc = product.toBson();
    doc['createdAt'] = DateTime.now();
    doc['updatedAt'] = DateTime.now();

    final result = await _productsCollection.insertOne(doc);
    return Product.fromBson({...doc, '_id': result.id});
  }

  Future<Product?> update(String id, Map<String, dynamic> updateData) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;

    final sanitized = <String, dynamic>{...updateData}
      ..remove('_id')
      ..['updatedAt'] = DateTime.now();

    for (final entry in sanitized.entries) {
      await _productsCollection.updateOne(
        where.id(objId),
        modify.set(entry.key, entry.value),
      );
    }

    return findById(id);
  }

  Future<bool> softDelete(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return false;

    final result = await _productsCollection.updateOne(
      where.id(objId),
      modify.set('isDeleted', true).set('updatedAt', DateTime.now()),
    );
    return result.nModified > 0;
  }

  Future<bool> toggleVisibility(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return false;

    final doc = await _productsCollection.findOne(where.id(objId));
    if (doc == null) return false;

    final current = doc['isActive'] != false;
    final result = await _productsCollection.updateOne(
      where.id(objId),
      modify.set('isActive', !current).set('updatedAt', DateTime.now()),
    );
    return result.nModified > 0;
  }

  Future<void> trackView(String productId, String viewerUserId) async {
    final objId = ModelHelpers.toObjectId(productId);
    if (objId == null) return;

    await _productsCollection.updateOne(
      where.id(objId),
      modify.addToSet('view_count', viewerUserId),
    );
  }

  Future<List<Product>> findProducts({
    String? search,
    String? category,
    String? state,
    String? district,
    String? locationName,
    String? productType,
    String? subProductType,
    String? userId,
    String? excludeUserId,
    List<String>? allowedCategories,
    int limit = 20,
    int page = 1,
    String? cursor,
    String? cursorId,
  }) async {
    var selector = where.eq('isDeleted', false).eq('isActive', true);

    if (excludeUserId != null && excludeUserId.isNotEmpty) {
      final excObjId = ModelHelpers.toObjectId(excludeUserId);
      if (excObjId != null) {
        selector = selector.ne('userId', excObjId);
      }
    }

    if (userId != null && userId.isNotEmpty) {
      final userObjId = ModelHelpers.toObjectId(userId);
      if (userObjId != null) {
        selector = selector.eq('userId', userObjId);
      }
    }

    if (category != null && category.isNotEmpty) {
      selector = selector.eq('categories', category);
    } else if (allowedCategories != null && allowedCategories.isNotEmpty) {
      selector = selector.oneFrom('categories', allowedCategories);
    }

    if (productType != null && productType.isNotEmpty) {
      final ptObjId = ModelHelpers.toObjectId(productType);
      if (ptObjId != null) {
        selector = selector.eq('productType', ptObjId);
      }
    }

    if (subProductType != null && subProductType.isNotEmpty) {
      final sptObjId = ModelHelpers.toObjectId(subProductType);
      if (sptObjId != null) {
        selector = selector.eq('subProductType', sptObjId);
      }
    }

    if (state != null && state.isNotEmpty) {
      selector = selector.match('location.state', state, caseInsensitive: true);
    }
    if (district != null && district.isNotEmpty) {
      selector = selector.match('location.district', district, caseInsensitive: true);
    }
    if (locationName != null && locationName.isNotEmpty) {
      selector = selector.match('location.locationName', locationName, caseInsensitive: true);
    }

    if (search != null && search.isNotEmpty) {
      final regex = RegExp(search, caseSensitive: false);
      selector = selector.or(
        where.match('title', regex.pattern, caseInsensitive: true)
            .match('description', regex.pattern, caseInsensitive: true)
            .match('searchTags', regex.pattern, caseInsensitive: true),
      );
    }

    // Cursor pagination or offset
    if (cursor != null && cursor.isNotEmpty) {
      final date = DateTime.tryParse(cursor);
      if (date != null) {
        selector = selector.lt('createdAt', date);
      }
    }

    selector = selector.sortBy('createdAt', descending: true);
    final skip = (page - 1) * limit;
    final stream = _productsCollection.find(selector.skip(skip).limit(limit));

    final list = await stream.toList();
    return list.map(Product.fromBson).toList();
  }

  Future<List<Product>> getFavoriteProducts(String userId) async {
    final userObjId = ModelHelpers.toObjectId(userId);
    if (userObjId == null) return [];

    final userDoc = await _usersCollection.findOne(where.id(userObjId));
    if (userDoc == null) return [];

    final favs = userDoc['favorite'] as List?;
    if (favs == null || favs.isEmpty) return [];

    final productIds = favs
        .map((f) => f is Map ? f['productId'] : f)
        .map((id) => ModelHelpers.toObjectId(id?.toString()))
        .whereType<ObjectId>()
        .toList();

    if (productIds.isEmpty) return [];

    final stream = _productsCollection.find(
      where.oneFrom('_id', productIds).eq('isDeleted', false),
    );

    final list = await stream.toList();
    return list.map(Product.fromBson).toList();
  }

  Future<bool> addFavorite(String userId, String productId) async {
    final userObjId = ModelHelpers.toObjectId(userId);
    final prodObjId = ModelHelpers.toObjectId(productId);
    if (userObjId == null || prodObjId == null) return false;

    final result = await _usersCollection.updateOne(
      where.id(userObjId),
      modify.addToSet('favorite', {'productId': prodObjId, 'createdAt': DateTime.now()}),
    );
    return result.nModified > 0;
  }

  Future<bool> removeFavorite(String userId, String productId) async {
    final userObjId = ModelHelpers.toObjectId(userId);
    final prodObjId = ModelHelpers.toObjectId(productId);
    if (userObjId == null || prodObjId == null) return false;

    final result = await _usersCollection.updateOne(
      where.id(userObjId),
      modify.pull('favorite', {'productId': prodObjId}),
    );
    return result.nModified > 0;
  }

  Future<List<ProductType>> getProductTypes() async {
    final stream = _productTypesCollection.find(where.sortBy('name'));
    final list = await stream.toList();
    return list.map(ProductType.fromBson).toList();
  }

  Future<List<SubProductType>> getSubProductTypes(String productTypeId) async {
    final ptObjId = ModelHelpers.toObjectId(productTypeId);
    if (ptObjId == null) return [];

    final stream = _subProductTypesCollection.find(
      where.eq('productType', ptObjId).ne('isDeleted', true).sortBy('name'),
    );
    final list = await stream.toList();
    return list.map(SubProductType.fromBson).toList();
  }

  Future<List<Map<String, dynamic>>> getProductTypesWithSubCategories() async {
    final types = await getProductTypes();
    final result = <Map<String, dynamic>>[];

    for (final t in types) {
      final subs = await getSubProductTypes(t.id!);
      result.add({
        ...t.toJson(),
        'subProductTypes': subs.map((s) => s.toJson()).toList(),
      });
    }

    return result;
  }

  Future<FormMetadata?> getFormMetadata(String productTypeId, {String? subProductTypeId}) async {
    final ptObjId = ModelHelpers.toObjectId(productTypeId);
    if (ptObjId == null) return null;

    var selector = where.eq('productType', ptObjId).eq('isActive', true);
    if (subProductTypeId != null && subProductTypeId.isNotEmpty) {
      final sptObjId = ModelHelpers.toObjectId(subProductTypeId);
      if (sptObjId != null) {
        selector = selector.eq('subProductType', sptObjId);
      }
    }

    final doc = await _formMetadataCollection.findOne(selector);
    if (doc == null) return null;
    return FormMetadata.fromBson(doc);
  }

  Future<Map<String, int>> getProductCountsByCategory() async {
    final pipeline = [
      {
        r'$match': {
          'isDeleted': false,
          'isActive': true,
        },
      },
      {
        r'$group': {
          '_id': r'$categories',
          'count': {r'$sum': 1},
        },
      },
    ];

    final results = await _productsCollection.aggregateToStream(pipeline).toList();
    final counts = <String, int>{};
    for (final r in results) {
      final cat = r['_id']?.toString() ?? 'other';
      final c = r['count'] as int? ?? 0;
      counts[cat] = c;
    }
    return counts;
  }
}
