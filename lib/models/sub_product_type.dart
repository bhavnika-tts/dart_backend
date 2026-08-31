import 'model_helpers.dart';

/// SubProductType history entry.
class SubProductTypeHistory {
  SubProductTypeHistory({this.updatedBy, this.updatedAt});

  factory SubProductTypeHistory.fromBson(Map<String, dynamic> bson) {
    return SubProductTypeHistory(
      updatedBy: ModelHelpers.idToString(bson['updatedBy']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  final String? updatedBy;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (updatedBy != null) 'updatedBy': updatedBy,
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (updatedBy != null)
          'updatedBy': ModelHelpers.toObjectId(updatedBy) ?? updatedBy,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}

/// SubProductType entity model.
class SubProductType {
  SubProductType({
    this.id,
    required this.name,
    required this.productType,
    this.lastEditedBy,
    this.isDeleted = false,
    this.history = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory SubProductType.fromBson(Map<String, dynamic> bson) {
    return SubProductType(
      id: ModelHelpers.idToString(bson['_id']),
      name: bson['name']?.toString() ?? '',
      productType: ModelHelpers.idToString(bson['productType']) ?? '',
      lastEditedBy: ModelHelpers.idToString(bson['lastEditedBy']),
      isDeleted: ModelHelpers.parseBool(bson['isDeleted']),
      history: (bson['history'] as List?)
              ?.map(
                (e) =>
                    SubProductTypeHistory.fromBson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory SubProductType.fromJson(Map<String, dynamic> json) =>
      SubProductType.fromBson(json);

  final String? id;
  final String name;
  final String productType;
  final String? lastEditedBy;
  final bool isDeleted;
  final List<SubProductTypeHistory> history;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'name': name,
        'productType': productType,
        if (lastEditedBy != null) 'lastEditedBy': lastEditedBy,
        'isDeleted': isDeleted,
        'history': history.map((e) => e.toJson()).toList(),
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'name': name,
        'productType': ModelHelpers.toObjectId(productType) ?? productType,
        if (lastEditedBy != null)
          'lastEditedBy':
              ModelHelpers.toObjectId(lastEditedBy) ?? lastEditedBy,
        'isDeleted': isDeleted,
        'history': history.map((e) => e.toBson()).toList(),
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
