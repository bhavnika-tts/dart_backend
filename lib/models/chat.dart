import 'model_helpers.dart';

/// Chat message metadata for attachments and optimistic sync.
class ChatMetadata {
  ChatMetadata({
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.clientMessageId,
  });

  factory ChatMetadata.fromMap(dynamic map) {
    if (map is! Map) return ChatMetadata();
    return ChatMetadata(
      fileName: map['fileName']?.toString(),
      fileSize: map['fileSize']?.toString(),
      mimeType: map['mimeType']?.toString(),
      clientMessageId: map['clientMessageId']?.toString(),
    );
  }

  final String? fileName;
  final String? fileSize;
  final String? mimeType;
  final String? clientMessageId;

  Map<String, dynamic> toMap() => {
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        if (mimeType != null) 'mimeType': mimeType,
        if (clientMessageId != null) 'clientMessageId': clientMessageId,
      };
}

/// Chat message entity model.
class ChatMessage {
  ChatMessage({
    this.id,
    required this.chatId,
    required this.senderId,
    this.productId,
    this.type = 'text',
    required this.content,
    ChatMetadata? metaData,
    this.status = 'sent',
    this.deletedBy = const [],
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  }) : metaData = metaData ?? ChatMetadata();

  factory ChatMessage.fromBson(Map<String, dynamic> bson) {
    return ChatMessage(
      id: ModelHelpers.idToString(bson['_id']),
      chatId: ModelHelpers.idToString(bson['chatId']) ?? '',
      senderId: ModelHelpers.idToString(bson['senderId']) ?? '',
      productId: ModelHelpers.idToString(bson['productId']),
      type: bson['type']?.toString() ?? 'text',
      content: bson['content']?.toString() ?? '',
      metaData: ChatMetadata.fromMap(bson['metaData']),
      status: bson['status']?.toString() ?? 'sent',
      deletedBy: ModelHelpers.parseStringList(bson['deletedBy']),
      isDeleted: ModelHelpers.parseBool(bson['isDeleted']),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      ChatMessage.fromBson(json);

  final String? id;
  final String chatId;
  final String senderId;
  final String? productId;
  final String type;
  final String content;
  final ChatMetadata metaData;
  final String status;
  final List<String> deletedBy;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'chatId': chatId,
        'senderId': senderId,
        if (productId != null) 'productId': productId,
        'type': type,
        'content': content,
        'metaData': metaData.toMap(),
        'status': status,
        'deletedBy': deletedBy,
        'isDeleted': isDeleted,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'chatId': ModelHelpers.toObjectId(chatId) ?? chatId,
        'senderId': ModelHelpers.toObjectId(senderId) ?? senderId,
        if (productId != null)
          'productId': ModelHelpers.toObjectId(productId) ?? productId,
        'type': type,
        'content': content,
        'metaData': metaData.toMap(),
        'status': status,
        'deletedBy':
            deletedBy.map((e) => ModelHelpers.toObjectId(e) ?? e).toList(),
        'isDeleted': isDeleted,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
