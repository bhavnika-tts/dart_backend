import 'model_helpers.dart';

/// Rating entity model.
class RatingModel {
  RatingModel({
    this.id,
    required this.user,
    required this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory RatingModel.fromBson(Map<String, dynamic> bson) {
    return RatingModel(
      id: ModelHelpers.idToString(bson['_id']),
      user: ModelHelpers.idToString(bson['user']) ?? '',
      rating: ModelHelpers.parseDouble(bson['rating']) ?? 0.0,
      comment: bson['comment']?.toString(),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory RatingModel.fromJson(Map<String, dynamic> json) =>
      RatingModel.fromBson(json);

  final String? id;
  final String user;
  final double rating;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'user': user,
        'rating': rating,
        if (comment != null) 'comment': comment,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'user': ModelHelpers.toObjectId(user) ?? user,
        'rating': rating,
        if (comment != null) 'comment': comment,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
