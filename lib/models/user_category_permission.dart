import 'model_helpers.dart';

/// User category permission entity model.
class UserCategoryPermission {
  UserCategoryPermission({
    this.id,
    required this.categoryKey,
    required this.label,
    this.displayName,
    this.read = const [],
    this.write = const [],
    this.requiresAdminVerification = false,
    this.verificationType = 'none',
    this.isHidden = false,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory UserCategoryPermission.fromBson(Map<String, dynamic> bson) {
    return UserCategoryPermission(
      id: ModelHelpers.idToString(bson['_id']),
      categoryKey: bson['categoryKey']?.toString() ?? '',
      label: bson['label']?.toString() ?? '',
      displayName: bson['displayName']?.toString(),
      read: ModelHelpers.parseStringList(bson['read']),
      write: ModelHelpers.parseStringList(bson['write']),
      requiresAdminVerification:
          ModelHelpers.parseBool(bson['requiresAdminVerification']),
      verificationType: bson['verificationType']?.toString() ?? 'none',
      isHidden: ModelHelpers.parseBool(bson['isHidden']),
      updatedBy: ModelHelpers.idToString(bson['updatedBy']),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory UserCategoryPermission.fromJson(Map<String, dynamic> json) =>
      UserCategoryPermission.fromBson(json);

  final String? id;
  final String categoryKey;
  final String label;
  final String? displayName;
  final List<String> read;
  final List<String> write;
  final bool requiresAdminVerification;
  final String verificationType;
  final bool isHidden;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'categoryKey': categoryKey,
        'label': label,
        'displayName': (label.isNotEmpty ? label : (displayName ?? categoryKey)),
        'read': read,
        'write': write,
        'requiresAdminVerification': requiresAdminVerification,
        'verificationType': verificationType,
        'isHidden': isHidden,
        if (updatedBy != null) 'updatedBy': updatedBy,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'categoryKey': categoryKey,
        'label': label,
        if (displayName != null) 'displayName': displayName,
        'read': read.map((e) => ModelHelpers.toObjectId(e) ?? e).toList(),
        'write': write.map((e) => ModelHelpers.toObjectId(e) ?? e).toList(),
        'requiresAdminVerification': requiresAdminVerification,
        'verificationType': verificationType,
        'isHidden': isHidden,
        if (updatedBy != null)
          'updatedBy': ModelHelpers.toObjectId(updatedBy) ?? updatedBy,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
