import 'model_helpers.dart';

/// Product category entity model.
class ProductCategory {
  ProductCategory({
    this.id,
    required this.label,
    String? sortOrder,
    this.createdAt,
    this.updatedAt,
  }) : sortOrder = sortOrder ?? label.toLowerCase();

  factory ProductCategory.fromBson(Map<String, dynamic> bson) {
    final label = bson['label']?.toString() ?? '';
    return ProductCategory(
      id: ModelHelpers.idToString(bson['_id']),
      label: label,
      sortOrder: bson['sortOrder']?.toString() ?? label.toLowerCase(),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory.fromBson(json);

  final String? id;
  final String label;
  final String sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'label': label,
        'sortOrder': sortOrder,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'label': label,
        'sortOrder': sortOrder,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
