import 'model_helpers.dart';

/// Conversation entity model.
class Conversation {
  Conversation({
    this.id,
    this.participants = const [],
    this.product,
    this.productTypeId,
    this.deletedBy = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromBson(Map<String, dynamic> bson) {
    return Conversation(
      id: ModelHelpers.idToString(bson['_id']),
      participants: ModelHelpers.parseStringList(bson['participants']),
      product: ModelHelpers.idToString(bson['product']),
      productTypeId: ModelHelpers.idToString(bson['productTypeId']),
      deletedBy: ModelHelpers.parseStringList(bson['deletedBy']),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      Conversation.fromBson(json);

  final String? id;
  final List<String> participants;
  final String? product;
  final String? productTypeId;
  final List<String> deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'participants': participants,
        if (product != null) 'product': product,
        if (productTypeId != null) 'productTypeId': productTypeId,
        'deletedBy': deletedBy,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'participants':
            participants.map((e) => ModelHelpers.toObjectId(e) ?? e).toList(),
        if (product != null)
          'product': ModelHelpers.toObjectId(product) ?? product,
        if (productTypeId != null)
          'productTypeId':
              ModelHelpers.toObjectId(productTypeId) ?? productTypeId,
        'deletedBy':
            deletedBy.map((e) => ModelHelpers.toObjectId(e) ?? e).toList(),
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
