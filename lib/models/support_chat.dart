import 'model_helpers.dart';

/// Support chat thread entity model.
class SupportChat {
  SupportChat({
    this.id,
    required this.userId,
    this.lastMessage,
    this.unreadCount = 0,
    this.userUnreadCount = 0,
    this.assignedTo,
    this.status = 'open',
    this.createdAt,
    this.updatedAt,
  });

  factory SupportChat.fromBson(Map<String, dynamic> bson) {
    return SupportChat(
      id: ModelHelpers.idToString(bson['_id']),
      userId: ModelHelpers.idToString(bson['userId']) ?? '',
      lastMessage: ModelHelpers.idToString(bson['lastMessage']),
      unreadCount: ModelHelpers.parseInt(bson['unreadCount']) ?? 0,
      userUnreadCount: ModelHelpers.parseInt(bson['userUnreadCount']) ?? 0,
      assignedTo: ModelHelpers.idToString(bson['assignedTo']),
      status: bson['status']?.toString() ?? 'open',
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory SupportChat.fromJson(Map<String, dynamic> json) =>
      SupportChat.fromBson(json);

  final String? id;
  final String userId;
  final String? lastMessage;
  final int unreadCount;
  final int userUnreadCount;
  final String? assignedTo;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'userId': userId,
        if (lastMessage != null) 'lastMessage': lastMessage,
        'unreadCount': unreadCount,
        'userUnreadCount': userUnreadCount,
        if (assignedTo != null) 'assignedTo': assignedTo,
        'status': status,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'userId': ModelHelpers.toObjectId(userId) ?? userId,
        if (lastMessage != null)
          'lastMessage':
              ModelHelpers.toObjectId(lastMessage) ?? lastMessage,
        'unreadCount': unreadCount,
        'userUnreadCount': userUnreadCount,
        if (assignedTo != null)
          'assignedTo': ModelHelpers.toObjectId(assignedTo) ?? assignedTo,
        'status': status,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
