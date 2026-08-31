import 'model_helpers.dart';

/// Brand and model hierarchy entity model.
class BrandModel {
  BrandModel({
    this.id,
    required this.productType,
    required this.brand,
    this.models = const [],
    this.displayOrder = 999,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory BrandModel.fromBson(Map<String, dynamic> bson) {
    return BrandModel(
      id: ModelHelpers.idToString(bson['_id']),
      productType: bson['productType']?.toString().toLowerCase().trim() ?? '',
      brand: bson['brand']?.toString().trim() ?? '',
      models: ModelHelpers.parseStringList(bson['models']),
      displayOrder: ModelHelpers.parseInt(bson['displayOrder']) ?? 999,
      isActive: ModelHelpers.parseBool(bson['isActive'], defaultValue: true),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory BrandModel.fromJson(Map<String, dynamic> json) =>
      BrandModel.fromBson(json);

  final String? id;
  final String productType;
  final String brand;
  final List<String> models;
  final int displayOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'productType': productType,
        'brand': brand,
        'models': models,
        'displayOrder': displayOrder,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'productType': productType,
        'brand': brand,
        'models': models,
        'displayOrder': displayOrder,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
