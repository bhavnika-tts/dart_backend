import 'model_helpers.dart';

/// GeoJSON 2dsphere location point.
class LocationPoint {
  LocationPoint({
    this.type = 'Point',
    this.coordinates = const [0.0, 0.0],
  });

  factory LocationPoint.fromBson(dynamic bson) {
    if (bson is! Map) return LocationPoint();
    final rawCoords = bson['coordinates'];
    final coords = <double>[];
    if (rawCoords is List) {
      for (final c in rawCoords) {
        final d = ModelHelpers.parseDouble(c);
        if (d != null) coords.add(d);
      }
    }
    return LocationPoint(
      type: bson['type']?.toString() ?? 'Point',
      coordinates: coords.length >= 2 ? coords : [0.0, 0.0],
    );
  }

  final String type;
  final List<double> coordinates;

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };

  Map<String, dynamic> toBson() => {
        'type': type,
        'coordinates': coordinates,
      };
}

/// Product entity model matching `new_backend/src/models/product.model.js`.
class Product {
  Product({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    this.price,
    this.images = const [],
    this.categories,
    required this.productType,
    this.subProductType,
    this.isActive = true,
    this.isDeleted = false,
    this.specs = const {},
    LocationPoint? location,
    this.areaLatest,
    this.cityLatest,
    this.stateLatest,
    this.countryLatest,
    this.viewCount = const [],
    this.searchTags = const [],
    this.detailsModel,
    this.detailsId,
    this.createdAt,
    this.updatedAt,
    this.user,
  }) : location = location ?? LocationPoint();

  factory Product.fromBson(Map<String, dynamic> bson) {
    return Product(
      id: ModelHelpers.idToString(bson['_id']),
      userId: ModelHelpers.idToString(bson['userId']) ?? '',
      title: bson['title']?.toString() ?? '',
      description: bson['description']?.toString(),
      price: ModelHelpers.parseDouble(bson['price']),
      images: ModelHelpers.parseStringList(bson['images']),
      categories: bson['categories']?.toString(),
      productType: ModelHelpers.idToString(bson['productType']) ?? '',
      subProductType: ModelHelpers.idToString(bson['subProductType']),
      isActive: ModelHelpers.parseBool(bson['isActive'], defaultValue: true),
      isDeleted: ModelHelpers.parseBool(bson['isDeleted']),
      specs: bson['specs'] is Map ? Map<String, dynamic>.from(bson['specs'] as Map) : {},
      location: LocationPoint.fromBson(bson['location']),
      areaLatest: bson['areaLatest']?.toString(),
      cityLatest: bson['cityLatest']?.toString(),
      stateLatest: bson['stateLatest']?.toString(),
      countryLatest: bson['countryLatest']?.toString(),
      viewCount: ModelHelpers.parseStringList(bson['view_count']),
      searchTags: ModelHelpers.parseStringList(bson['searchTags']),
      detailsModel: bson['detailsModel']?.toString(),
      detailsId: ModelHelpers.idToString(bson['detailsId']),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
      user: bson['user'] is Map ? Map<String, dynamic>.from(bson['user'] as Map) : null,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product.fromBson(json);

  final String? id;
  final String userId;
  final String title;
  final String? description;
  final double? price;
  final List<String> images;
  final String? categories;
  final String productType;
  final String? subProductType;
  final bool isActive;
  final bool isDeleted;
  final Map<String, dynamic> specs;
  final LocationPoint location;
  final String? areaLatest;
  final String? cityLatest;
  final String? stateLatest;
  final String? countryLatest;
  final List<String> viewCount;
  final List<String> searchTags;
  final String? detailsModel;
  final String? detailsId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? user;

  Map<String, dynamic> toJson({bool isListProjection = false}) {
    final map = <String, dynamic>{
      if (id != null) '_id': id,
      'userId': userId,
      'title': title,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      'images': images,
      if (categories != null) 'categories': categories,
      'productType': productType,
      if (subProductType != null) 'subProductType': subProductType,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'specs': specs,
      'location': location.toJson(),
      if (areaLatest != null) 'areaLatest': areaLatest,
      if (cityLatest != null) 'cityLatest': cityLatest,
      if (stateLatest != null) 'stateLatest': stateLatest,
      if (countryLatest != null) 'countryLatest': countryLatest,
      if (!isListProjection) 'view_count': viewCount,
      'searchTags': searchTags,
      if (detailsModel != null) 'detailsModel': detailsModel,
      if (detailsId != null) 'detailsId': detailsId,
      if (user != null) 'user': user,
      if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
      if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
    };
    return map;
  }

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'userId': ModelHelpers.toObjectId(userId) ?? userId,
        'title': title,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        'images': images,
        if (categories != null) 'categories': categories,
        'productType': ModelHelpers.toObjectId(productType) ?? productType,
        if (subProductType != null)
          'subProductType':
              ModelHelpers.toObjectId(subProductType) ?? subProductType,
        'isActive': isActive,
        'isDeleted': isDeleted,
        'specs': specs,
        'location': location.toBson(),
        if (areaLatest != null) 'areaLatest': areaLatest,
        if (cityLatest != null) 'cityLatest': cityLatest,
        if (stateLatest != null) 'stateLatest': stateLatest,
        if (countryLatest != null) 'countryLatest': countryLatest,
        'view_count':
            viewCount.map((e) => ModelHelpers.toObjectId(e) ?? e).toList(),
        'searchTags': searchTags,
        if (detailsModel != null) 'detailsModel': detailsModel,
        if (detailsId != null)
          'detailsId': ModelHelpers.toObjectId(detailsId) ?? detailsId,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
