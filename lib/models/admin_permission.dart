import 'model_helpers.dart';

/// Module permission flags (read, write, assign_pin).
class ModulePermission {
  ModulePermission({
    this.read = false,
    this.write = false,
    this.assignPin = false,
  });

  factory ModulePermission.fromMap(dynamic map) {
    if (map is! Map) return ModulePermission();
    return ModulePermission(
      read: ModelHelpers.parseBool(map['read']),
      write: ModelHelpers.parseBool(map['write']),
      assignPin: ModelHelpers.parseBool(map['assign_pin']),
    );
  }

  final bool read;
  final bool write;
  final bool assignPin;

  Map<String, dynamic> toMap() => {
        'read': read,
        'write': write,
        'assign_pin': assignPin,
      };
}

/// Admin permission entity model.
class AdminPermission {
  AdminPermission({
    this.id,
    required this.adminId,
    required this.permissions,
    this.assignedAccessCodes = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory AdminPermission.fromBson(Map<String, dynamic> bson) {
    final permsMap = bson['permissions'] as Map? ?? {};
    final permissions = <String, ModulePermission>{};

    final standardModules = [
      'dashboard',
      'product',
      'user',
      'access_code',
      'reports',
      'chat_reports',
      'app_versions',
      'feature_request',
      'reviews',
      'support_chat',
      'about_us',
      'app_guide',
      'banners',
      'occupation',
      'sub_product_types',
    ];

    for (final module in standardModules) {
      permissions[module] = ModulePermission.fromMap(permsMap[module]);
    }

    return AdminPermission(
      id: ModelHelpers.idToString(bson['_id']),
      adminId: ModelHelpers.idToString(bson['adminId']) ?? '',
      permissions: permissions,
      assignedAccessCodes:
          ModelHelpers.parseStringList(bson['assigned_access_codes']),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory AdminPermission.fromJson(Map<String, dynamic> json) =>
      AdminPermission.fromBson(json);

  final String? id;
  final String adminId;
  final Map<String, ModulePermission> permissions;
  final List<String> assignedAccessCodes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'adminId': adminId,
        'permissions': permissions.map((k, v) => MapEntry(k, v.toMap())),
        'assigned_access_codes': assignedAccessCodes,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'adminId': ModelHelpers.toObjectId(adminId) ?? adminId,
        'permissions': permissions.map((k, v) => MapEntry(k, v.toMap())),
        'assigned_access_codes': assignedAccessCodes,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
