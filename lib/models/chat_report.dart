import 'model_helpers.dart';

/// Chat report entity model.
class ChatReport {
  ChatReport({
    this.id,
    required this.reportedBy,
    required this.reportedUser,
    this.conversationId,
    required this.description,
    this.image,
    this.status = 'pending',
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatReport.fromBson(Map<String, dynamic> bson) {
    return ChatReport(
      id: ModelHelpers.idToString(bson['_id']),
      reportedBy: ModelHelpers.idToString(bson['reportedBy']) ?? '',
      reportedUser: ModelHelpers.idToString(bson['reportedUser']) ?? '',
      conversationId: ModelHelpers.idToString(bson['conversationId']),
      description: bson['description']?.toString() ?? '',
      image: bson['image']?.toString(),
      status: bson['status']?.toString() ?? 'pending',
      note: bson['note']?.toString(),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory ChatReport.fromJson(Map<String, dynamic> json) =>
      ChatReport.fromBson(json);

  final String? id;
  final String reportedBy;
  final String reportedUser;
  final String? conversationId;
  final String description;
  final String? image;
  final String status;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'reportedBy': reportedBy,
        'reportedUser': reportedUser,
        if (conversationId != null) 'conversationId': conversationId,
        'description': description,
        if (image != null) 'image': image,
        'status': status,
        if (note != null) 'note': note,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'reportedBy':
            ModelHelpers.toObjectId(reportedBy) ?? reportedBy,
        'reportedUser':
            ModelHelpers.toObjectId(reportedUser) ?? reportedUser,
        if (conversationId != null)
          'conversationId':
              ModelHelpers.toObjectId(conversationId) ?? conversationId,
        'description': description,
        if (image != null) 'image': image,
        'status': status,
        if (note != null) 'note': note,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
