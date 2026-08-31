import 'model_helpers.dart';

/// History item for occupation updates.
class OccupationHistory {
  OccupationHistory({this.updatedBy, this.updatedAt});

  factory OccupationHistory.fromBson(Map<String, dynamic> bson) {
    return OccupationHistory(
      updatedBy: ModelHelpers.idToString(bson['updatedBy']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  final String? updatedBy;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (updatedBy != null) 'updatedBy': updatedBy,
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (updatedBy != null)
          'updatedBy': ModelHelpers.toObjectId(updatedBy) ?? updatedBy,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}

/// Occupation entity model.
class Occupation {
  Occupation({
    this.id,
    required this.name,
    this.createdBy,
    this.updatedBy,
    this.history = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Occupation.fromBson(Map<String, dynamic> bson) {
    return Occupation(
      id: ModelHelpers.idToString(bson['_id']),
      name: bson['name']?.toString() ?? '',
      createdBy: ModelHelpers.idToString(bson['createdBy']),
      updatedBy: ModelHelpers.idToString(bson['updatedBy']),
      history: (bson['history'] as List?)
              ?.map((e) => OccupationHistory.fromBson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory Occupation.fromJson(Map<String, dynamic> json) =>
      Occupation.fromBson(json);

  final String? id;
  final String name;
  final String? createdBy;
  final String? updatedBy;
  final List<OccupationHistory> history;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'name': name,
        if (createdBy != null) 'createdBy': createdBy,
        if (updatedBy != null) 'updatedBy': updatedBy,
        'history': history.map((e) => e.toJson()).toList(),
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'name': name,
        if (createdBy != null)
          'createdBy': ModelHelpers.toObjectId(createdBy) ?? createdBy,
        if (updatedBy != null)
          'updatedBy': ModelHelpers.toObjectId(updatedBy) ?? updatedBy,
        'history': history.map((e) => e.toBson()).toList(),
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
