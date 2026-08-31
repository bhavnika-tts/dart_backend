import 'model_helpers.dart';

/// Support message entity model.
class SupportMessage {
  SupportMessage({
    this.id,
    required this.chatId,
    this.senderId,
    this.adminSenderId,
    this.senderRole = 'user',
    required this.content,
    this.type = 'text',
    this.status = 'sent',
    this.createdAt,
    this.updatedAt,
  });

  factory SupportMessage.fromBson(Map<String, dynamic> bson) {
    return SupportMessage(
      id: ModelHelpers.idToString(bson['_id']),
      chatId: ModelHelpers.idToString(bson['chatId']) ?? '',
      senderId: ModelHelpers.idToString(bson['senderId']),
      adminSenderId: ModelHelpers.idToString(bson['adminSenderId']),
      senderRole: bson['senderRole']?.toString() ?? 'user',
      content: bson['content']?.toString() ?? '',
      type: bson['type']?.toString() ?? 'text',
      status: bson['status']?.toString() ?? 'sent',
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory SupportMessage.fromJson(Map<String, dynamic> json) =>
      SupportMessage.fromBson(json);

  final String? id;
  final String chatId;
  final String? senderId;
  final String? adminSenderId;
  final String senderRole;
  final String content;
  final String type;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'chatId': chatId,
        if (senderId != null) 'senderId': senderId,
        if (adminSenderId != null) 'adminSenderId': adminSenderId,
        'senderRole': senderRole,
        'content': content,
        'type': type,
        'status': status,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'chatId': ModelHelpers.toObjectId(chatId) ?? chatId,
        if (senderId != null)
          'senderId': ModelHelpers.toObjectId(senderId) ?? senderId,
        if (adminSenderId != null)
          'adminSenderId':
              ModelHelpers.toObjectId(adminSenderId) ?? adminSenderId,
        'senderRole': senderRole,
        'content': content,
        'type': type,
        'status': status,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
