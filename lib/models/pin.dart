import 'model_helpers.dart';

/// Pin/Access Code model.
class PinModel {
  PinModel({
    this.id,
    required this.code,
    this.useCount = 0,
    this.maxCount = 100,
    this.createdAt,
    this.updatedAt,
  });

  factory PinModel.fromBson(Map<String, dynamic> bson) {
    return PinModel(
      id: ModelHelpers.idToString(bson['_id']),
      code: bson['code']?.toString() ?? '',
      useCount: ModelHelpers.parseInt(bson['use_count']) ?? 0,
      maxCount: ModelHelpers.parseInt(bson['max_count']) ?? 100,
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory PinModel.fromJson(Map<String, dynamic> json) =>
      PinModel.fromBson(json);

  final String? id;
  final String code;
  final int useCount;
  final int maxCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'code': code,
        'use_count': useCount,
        'max_count': maxCount,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'code': code,
        'use_count': useCount,
        'max_count': maxCount,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
