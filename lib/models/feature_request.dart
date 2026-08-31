import 'model_helpers.dart';

/// Feature request entity model.
class FeatureRequest {
  FeatureRequest({
    this.id,
    required this.title,
    required this.description,
    required this.userId,
    this.status = 'pending',
    this.statusMessage = '',
    this.createdAt,
    this.updatedAt,
  });

  factory FeatureRequest.fromBson(Map<String, dynamic> bson) {
    return FeatureRequest(
      id: ModelHelpers.idToString(bson['_id']),
      title: bson['title']?.toString() ?? '',
      description: bson['description']?.toString() ?? '',
      userId: ModelHelpers.idToString(bson['userId']) ?? '',
      status: bson['status']?.toString() ?? 'pending',
      statusMessage: bson['statusMessage']?.toString() ?? '',
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory FeatureRequest.fromJson(Map<String, dynamic> json) =>
      FeatureRequest.fromBson(json);

  final String? id;
  final String title;
  final String description;
  final String userId;
  final String status;
  final String statusMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'title': title,
        'description': description,
        'userId': userId,
        'status': status,
        'statusMessage': statusMessage,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'title': title,
        'description': description,
        'userId': ModelHelpers.toObjectId(userId) ?? userId,
        'status': status,
        'statusMessage': statusMessage,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
