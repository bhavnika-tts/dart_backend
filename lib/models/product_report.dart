import 'model_helpers.dart';

/// Product report entity model.
class ProductReport {
  ProductReport({
    this.id,
    this.userId,
    this.productId,
    this.description,
    this.image,
    this.modelName,
    this.isActive = true,
    this.status = 'pending',
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductReport.fromBson(Map<String, dynamic> bson) {
    return ProductReport(
      id: ModelHelpers.idToString(bson['_id']),
      userId: ModelHelpers.idToString(bson['userId']),
      productId: ModelHelpers.idToString(bson['productId']),
      description:
          bson['description']?.toString() ?? bson['desctiption']?.toString(),
      image: bson['image']?.toString(),
      modelName: bson['modelName']?.toString(),
      isActive: ModelHelpers.parseBool(bson['isActive'], defaultValue: true),
      status: bson['status']?.toString() ?? 'pending',
      note: bson['note']?.toString(),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory ProductReport.fromJson(Map<String, dynamic> json) =>
      ProductReport.fromBson(json);

  final String? id;
  final String? userId;
  final String? productId;
  final String? description;
  final String? image;
  final String? modelName;
  final bool isActive;
  final String status;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (userId != null) 'userId': userId,
        if (productId != null) 'productId': productId,
        if (description != null) 'description': description,
        if (image != null) 'image': image,
        if (modelName != null) 'modelName': modelName,
        'isActive': isActive,
        'status': status,
        if (note != null) 'note': note,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        if (userId != null)
          'userId': ModelHelpers.toObjectId(userId) ?? userId,
        if (productId != null)
          'productId': ModelHelpers.toObjectId(productId) ?? productId,
        if (description != null) 'description': description,
        if (image != null) 'image': image,
        if (modelName != null) 'modelName': modelName,
        'isActive': isActive,
        'status': status,
        if (note != null) 'note': note,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
