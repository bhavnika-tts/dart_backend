import 'model_helpers.dart';

/// App guide video entity model.
class AppGuideVideo {
  AppGuideVideo({
    this.id,
    required this.title,
    this.description = '',
    required this.videoName,
    required this.videoSize,
    required this.videoExtension,
    this.videoDuration = 0,
    this.visibility = false,
    this.createdAt,
    this.updatedAt,
  });

  factory AppGuideVideo.fromBson(Map<String, dynamic> bson) {
    return AppGuideVideo(
      id: ModelHelpers.idToString(bson['_id']),
      title: bson['title']?.toString().trim() ?? '',
      description: bson['description']?.toString().trim() ?? '',
      videoName: bson['videoName']?.toString() ?? '',
      videoSize: ModelHelpers.parseInt(bson['videoSize']) ?? 0,
      videoExtension: bson['videoExtension']?.toString() ?? '',
      videoDuration: ModelHelpers.parseInt(bson['videoDuration']) ?? 0,
      visibility: ModelHelpers.parseBool(bson['visibility']),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory AppGuideVideo.fromJson(Map<String, dynamic> json) =>
      AppGuideVideo.fromBson(json);

  final String? id;
  final String title;
  final String description;
  final String videoName;
  final int videoSize;
  final String videoExtension;
  final int videoDuration;
  final bool visibility;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'title': title,
        'description': description,
        'videoName': videoName,
        'videoSize': videoSize,
        'videoExtension': videoExtension,
        'videoDuration': videoDuration,
        'visibility': visibility,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'title': title,
        'description': description,
        'videoName': videoName,
        'videoSize': videoSize,
        'videoExtension': videoExtension,
        'videoDuration': videoDuration,
        'visibility': visibility,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
