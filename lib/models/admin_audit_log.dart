import 'model_helpers.dart';

/// Admin audit log entity model.
class AdminAuditLog {
  AdminAuditLog({
    this.id,
    required this.adminId,
    this.adminUsername = '',
    this.adminEmail = '',
    this.role = '',
    required this.action,
    required this.method,
    required this.endpoint,
    this.details,
    this.ipAddress = '',
    this.userAgent = '',
    this.status = 'SUCCESS',
    this.failureReason = '',
    this.createdAt,
    this.updatedAt,
  });

  factory AdminAuditLog.fromBson(Map<String, dynamic> bson) {
    return AdminAuditLog(
      id: ModelHelpers.idToString(bson['_id']),
      adminId: ModelHelpers.idToString(bson['adminId']) ?? '',
      adminUsername: bson['adminUsername']?.toString() ?? '',
      adminEmail: bson['adminEmail']?.toString() ?? '',
      role: bson['role']?.toString() ?? '',
      action: bson['action']?.toString() ?? '',
      method: bson['method']?.toString() ?? '',
      endpoint: bson['endpoint']?.toString() ?? '',
      details: bson['details'],
      ipAddress: bson['ipAddress']?.toString() ?? '',
      userAgent: bson['userAgent']?.toString() ?? '',
      status: bson['status']?.toString() ?? 'SUCCESS',
      failureReason: bson['failureReason']?.toString() ?? '',
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) =>
      AdminAuditLog.fromBson(json);

  final String? id;
  final String adminId;
  final String adminUsername;
  final String adminEmail;
  final String role;
  final String action;
  final String method;
  final String endpoint;
  final dynamic details;
  final String ipAddress;
  final String userAgent;
  final String status;
  final String failureReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'adminId': adminId,
        'adminUsername': adminUsername,
        'adminEmail': adminEmail,
        'role': role,
        'action': action,
        'method': method,
        'endpoint': endpoint,
        if (details != null) 'details': details,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'status': status,
        'failureReason': failureReason,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'adminId': ModelHelpers.toObjectId(adminId) ?? adminId,
        'adminUsername': adminUsername,
        'adminEmail': adminEmail,
        'role': role,
        'action': action,
        'method': method,
        'endpoint': endpoint,
        if (details != null) 'details': details,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'status': status,
        'failureReason': failureReason,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
