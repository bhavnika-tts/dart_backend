import 'model_helpers.dart';

/// Image metadata model.
class ImageModel {
  ImageModel({
    this.id,
    required this.url,
    required this.fileId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ImageModel.fromBson(Map<String, dynamic> bson) {
    return ImageModel(
      id: ModelHelpers.idToString(bson['_id']),
      url: bson['url']?.toString() ?? '',
      fileId: bson['fileId']?.toString() ?? '',
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
    );
  }

  factory ImageModel.fromJson(Map<String, dynamic> json) =>
      ImageModel.fromBson(json);

  final String? id;
  final String url;
  final String fileId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'url': url,
        'fileId': fileId,
        'createdAt': ModelHelpers.toIsoString(createdAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'url': url,
        'fileId': fileId,
        'createdAt': createdAt,
      };
}
