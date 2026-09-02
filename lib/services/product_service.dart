import 'dart:typed_data';
import '../models/model_helpers.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../repositories/user_repository.dart';
import 'imagekit_service.dart';

/// Business logic service for Products, Multi-type Listings, ImageKit Uploads, and Favorites.
class ProductService {
  ProductService({
    ProductRepository? productRepository,
    UserRepository? userRepository,
    ImageKitService? imageKitService,
  })  : _productRepo = productRepository ?? ProductRepository.instance,
        _userRepo = userRepository ?? UserRepository.instance,
        _imageKit = imageKitService ?? ImageKitService.instance;

  final ProductRepository _productRepo;
  final UserRepository _userRepo;
  final ImageKitService _imageKit;

  static ProductService? _instance;
  static ProductService get instance => _instance ??= ProductService();

  /// Adds a new product listing with image uploads to ImageKit.
  Future<Map<String, dynamic>> addProduct({
    required Map<String, dynamic> rawData,
    List<Uint8List>? imageBytesList,
    List<String>? imageNames,
  }) async {
    final userId = rawData['userId']?.toString().trim() ?? '';
    final productType = rawData['productType']?.toString().trim() ?? '';

    if (userId.isEmpty) {
      throw ArgumentError('UserId is required');
    }
    if (productType.isEmpty) {
      throw ArgumentError('Product Type is required');
    }

    final user = await _userRepo.findById(userId);
    if (user == null) {
      throw StateError('User not found');
    }

    // Upload images to ImageKit
    final uploadedUrls = <String>[];
    if (imageBytesList != null && imageBytesList.isNotEmpty) {
      for (var i = 0; i < imageBytesList.length; i++) {
        final bytes = imageBytesList[i];
        final name = (imageNames != null && i < imageNames.length)
            ? imageNames[i]
            : 'product_$i.jpg';

        final url = await _imageKit.uploadBytes(
          bytes: bytes,
          fileName: name,
          folder: '/productImages',
          prefix: 'product',
        );
        uploadedUrls.add(url);
      }
    }

    // Extract title & price
    final title = rawData['productName']?.toString().trim() ??
        rawData['title']?.toString().trim() ??
        rawData['adTitle']?.toString().trim() ??
        'Product';

    final price = ModelHelpers.parseDouble(rawData['price']) ?? 0.0;
    final description = rawData['description']?.toString().trim();
    final categories = rawData['categories']?.toString().trim() ??
        rawData['category']?.toString().trim() ??
        'other';

    // Parse coordinates and location
    var coords = [0.0, 0.0];
    final rawCoords = rawData['location'] is Map ? rawData['location']['coordinates'] : rawData['coordinates'];
    if (rawCoords is List) {
      final parsed = rawCoords.map(ModelHelpers.parseDouble).whereType<double>().toList();
      if (parsed.length >= 2) coords = parsed;
    }

    final state = rawData['stateLatest']?.toString().trim() ??
        (rawData['location'] is Map ? rawData['location']['state']?.toString() : null) ??
        (user.state.isNotEmpty ? user.state.first : '');

    final district = rawData['district']?.toString().trim() ??
        (rawData['location'] is Map ? rawData['location']['district']?.toString() : null) ??
        (user.district.isNotEmpty ? user.district.first : '');

    final locationName = rawData['locationName']?.toString().trim() ??
        (rawData['location'] is Map ? rawData['location']['locationName']?.toString() : null) ??
        (user.area.isNotEmpty ? user.area.first : '');

    // Search tags
    final tags = <String>[
      title,
      categories,
      if (description != null) description,
      state,
      district,
      locationName,
    ];

    final product = Product(
      userId: userId,
      title: title,
      description: description,
      price: price,
      images: uploadedUrls,
      categories: categories,
      productType: productType,
      subProductType: rawData['subProductType']?.toString().trim(),
      specs: rawData['specs'] is Map ? Map<String, dynamic>.from(rawData['specs'] as Map) : rawData,
      location: LocationPoint(coordinates: coords),
      stateLatest: state,
      cityLatest: district,
      areaLatest: locationName,
      countryLatest: 'India',
      searchTags: tags,
    );

    final created = await _productRepo.create(product);
    final signed = _imageKit.signImageKitUrls(created.toJson()) as Map<String, dynamic>;

    return {
      'message': 'Product added successfully',
      'product': signed,
    };
  }

  /// Updates an existing product listing.
  Future<Map<String, dynamic>> updateProduct({
    required String productId,
    required Map<String, dynamic> rawData,
    List<Uint8List>? newImageBytesList,
    List<String>? newImageNames,
  }) async {
    final existing = await _productRepo.findById(productId);
    if (existing == null) {
      throw StateError('Product not found');
    }

    final imagesList = List<String>.from(
      existing.images.map(_imageKit.stripSignature),
    );

    // Upload new images to ImageKit if provided
    if (newImageBytesList != null && newImageBytesList.isNotEmpty) {
      for (var i = 0; i < newImageBytesList.length; i++) {
        final bytes = newImageBytesList[i];
        final name = (newImageNames != null && i < newImageNames.length)
            ? newImageNames[i]
            : 'product_update_$i.jpg';

        final url = await _imageKit.uploadBytes(
          bytes: bytes,
          fileName: name,
          folder: '/productImages',
          prefix: 'product',
        );
        imagesList.add(url);
      }
    }

    final updates = <String, dynamic>{
      ...rawData,
      'images': imagesList,
    };

    final updated = await _productRepo.update(productId, updates);
    final signed = _imageKit.signImageKitUrls(updated!.toJson()) as Map<String, dynamic>;

    return {
      'message': 'Product updated successfully',
      'product': signed,
    };
  }

  /// Fetches products feed with permissions check, pagination, and favorites.
  Future<Map<String, dynamic>> getAllProducts({
    required String userId,
    int limit = 20,
    int page = 1,
    String? cursor,
    String? cursorId,
    String? search,
    String? category,
    String? productType,
    String? subProductType,
    String? state,
    String? district,
    String? locationName,
  }) async {
    final user = await _userRepo.findById(userId);

    final userPerms = userId != 'admin' && user != null
        ? await _userRepo.getUserPermissions(userId)
        : null;
    final allowedCategories = (user == null || user.role == 'superadmin' || user.role == 'admin')
        ? null
        : userPerms?.read;

    final products = await _productRepo.findProducts(
      search: search,
      category: category,
      productType: productType,
      subProductType: subProductType,
      state: state,
      district: district,
      locationName: locationName,
      excludeUserId: user?.role == 'user' ? userId : null,
      allowedCategories: allowedCategories,
      limit: limit,
      page: page,
      cursor: cursor,
      cursorId: cursorId,
    );

    // Compute favorites set
    final favProducts = await _productRepo.getFavoriteProducts(userId);
    final favSet = favProducts.map((p) => p.id).toSet();

    final resultList = products.map((p) {
      final json = p.toJson();
      json['isFavorite'] = favSet.contains(p.id);
      json['productId'] = p.id;
      json['category'] = p.categories ?? '';
      return json;
    }).toList();

    final signedList = _imageKit.signImageKitUrls(resultList) as List;

    return {
      'success': true,
      'message': 'All product fetch successfully.',
      'products': signedList,
    };
  }

  /// Fetches single product details by ID.
  Future<Map<String, dynamic>> getProductById(String productId, {String? currentUserId}) async {
    final product = await _productRepo.findById(productId);
    if (product == null) {
      throw StateError('Product not found');
    }

    final json = product.toJson();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      final favProducts = await _productRepo.getFavoriteProducts(currentUserId);
      json['isFavorite'] = favProducts.any((f) => f.id == product.id);
    }

    final signed = _imageKit.signImageKitUrls(json) as Map<String, dynamic>;
    return {
      'success': true,
      'message': 'Product fetched successfully',
      'product': signed,
    };
  }

  /// Fetches products uploaded by a specific user.
  Future<List<Map<String, dynamic>>> getProductsByUser(String targetUserId) async {
    final products = await _productRepo.findProducts(
      userId: targetUserId,
      limit: 100,
    );
    final list = products.map((p) => p.toJson()).toList();
    return List<Map<String, dynamic>>.from(_imageKit.signImageKitUrls(list) as List);
  }

  /// Soft deletes a product listing.
  Future<void> deleteProduct(String productId, String requesterUserId) async {
    final product = await _productRepo.findById(productId);
    if (product == null) {
      throw StateError('Product not found');
    }

    if (product.userId != requesterUserId) {
      throw StateError('You can only delete your own products.');
    }

    await _productRepo.softDelete(productId);
  }

  /// Deletes a specific image from product.
  Future<void> deleteProductImage(String productId, String imageUrl) async {
    final product = await _productRepo.findById(productId);
    if (product == null) {
      throw StateError('Product not found');
    }

    final cleanUrl = _imageKit.stripSignature(imageUrl);
    final updatedImages = product.images
        .map(_imageKit.stripSignature)
        .where((u) => u != cleanUrl)
        .toList();

    await _productRepo.update(productId, {'images': updatedImages});
    await _imageKit.deleteFile(cleanUrl);
  }

  /// Toggles visibility of a product.
  Future<bool> toggleProductVisibility(String productId, String userId) async {
    final product = await _productRepo.findById(productId);
    if (product == null) {
      throw StateError('Product not found');
    }

    return _productRepo.toggleVisibility(productId);
  }

  /// Toggles favorite status for a product.
  Future<Map<String, dynamic>> toggleFavorite(String userId, String productId) async {
    final user = await _userRepo.findById(userId);
    if (user == null) {
      throw StateError('User not found');
    }

    final favs = await _productRepo.getFavoriteProducts(userId);
    final isFav = favs.any((f) => f.id == productId);

    if (isFav) {
      await _productRepo.removeFavorite(userId, productId);
      return {'message': 'Product removed from favorites', 'isFavorite': false};
    } else {
      await _productRepo.addFavorite(userId, productId);
      return {'message': 'Product added to favorites', 'isFavorite': true};
    }
  }

  /// Retrieves user's favorite products list.
  Future<List<Map<String, dynamic>>> getFavoriteProducts(String userId) async {
    final products = await _productRepo.getFavoriteProducts(userId);
    final list = products.map((p) {
      final json = p.toJson();
      json['isFavorite'] = true;
      json['productId'] = p.id;
      return json;
    }).toList();

    return List<Map<String, dynamic>>.from(_imageKit.signImageKitUrls(list) as List);
  }

  /// Tracks a unique view on a product.
  Future<void> trackProductView(String productId, String viewerUserId) async {
    await _productRepo.trackView(productId, viewerUserId);
  }

  /// Retrieves active product types and sub-categories.
  Future<List<Map<String, dynamic>>> getProductTypesWithSubCategories() async {
    return _productRepo.getProductTypesWithSubCategories();
  }

  /// Retrieves form metadata schema for dynamic listing forms.
  Future<Map<String, dynamic>?> getFormMetadata(String productTypeId, {String? subProductTypeId}) async {
    final meta = await _productRepo.getFormMetadata(productTypeId, subProductTypeId: subProductTypeId);
    return meta?.toJson();
  }

  /// Retrieves active product counts grouped by category.
  Future<Map<String, int>> getProductCountsByCategory() async {
    return _productRepo.getProductCountsByCategory();
  }
}
