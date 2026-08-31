import 'model_helpers.dart';

/// App version entity model.
class AppVersion {
  AppVersion({
    this.id,
    required this.version,
    required this.versionName,
    DateTime? releaseDate,
    required this.apkLink,
    required this.changes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  }) : releaseDate = releaseDate ?? DateTime.now();

  factory AppVersion.fromBson(Map<String, dynamic> bson) {
    return AppVersion(
      id: ModelHelpers.idToString(bson['_id']),
      version: bson['version']?.toString() ?? '',
      versionName: bson['versionName']?.toString() ?? '',
      releaseDate: ModelHelpers.parseDateTime(bson['releaseDate']),
      apkLink: bson['apkLink']?.toString() ?? '',
      changes: bson['changes']?.toString() ?? '',
      isActive: ModelHelpers.parseBool(bson['isActive'], defaultValue: true),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory AppVersion.fromJson(Map<String, dynamic> json) =>
      AppVersion.fromBson(json);

  final String? id;
  final String version;
  final String versionName;
  final DateTime releaseDate;
  final String apkLink;
  final String changes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'version': version,
        'versionName': versionName,
        'releaseDate': ModelHelpers.toIsoString(releaseDate),
        'apkLink': apkLink,
        'changes': changes,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'version': version,
        'versionName': versionName,
        'releaseDate': releaseDate,
        'apkLink': apkLink,
        'changes': changes,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
