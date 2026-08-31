import 'model_helpers.dart';

/// Category restriction entity model.
class CategoryRestriction {
  CategoryRestriction({
    this.id,
    required this.userCategory,
    required this.writeCategory,
    this.allowedProductTypes = const [],
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryRestriction.fromBson(Map<String, dynamic> bson) {
    return CategoryRestriction(
      id: ModelHelpers.idToString(bson['_id']),
      userCategory: ModelHelpers.idToString(bson['userCategory']) ?? '',
      writeCategory: ModelHelpers.idToString(bson['writeCategory']) ?? '',
      allowedProductTypes:
          ModelHelpers.parseStringList(bson['allowedProductTypes']),
      updatedBy: ModelHelpers.idToString(bson['updatedBy']),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory CategoryRestriction.fromJson(Map<String, dynamic> json) =>
      CategoryRestriction.fromBson(json);

  final String? id;
  final String userCategory;
  final String writeCategory;
  final List<String> allowedProductTypes;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'userCategory': userCategory,
        'writeCategory': writeCategory,
        'allowedProductTypes': allowedProductTypes,
        if (updatedBy != null) 'updatedBy': updatedBy,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'userCategory':
            ModelHelpers.toObjectId(userCategory) ?? userCategory,
        'writeCategory':
            ModelHelpers.toObjectId(writeCategory) ?? writeCategory,
        'allowedProductTypes': allowedProductTypes
            .map((e) => ModelHelpers.toObjectId(e) ?? e)
            .toList(),
        if (updatedBy != null)
          'updatedBy': ModelHelpers.toObjectId(updatedBy) ?? updatedBy,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
