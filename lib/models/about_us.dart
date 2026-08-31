import 'model_helpers.dart';

/// Value item in AboutUs section.
class OurValue {
  OurValue({
    required this.icon,
    required this.title,
    required this.description,
  });

  factory OurValue.fromMap(dynamic map) {
    if (map is! Map) {
      return OurValue(icon: 'trust', title: '', description: '');
    }
    return OurValue(
      icon: map['icon']?.toString() ?? 'trust',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
    );
  }

  final String icon;
  final String title;
  final String description;

  Map<String, dynamic> toMap() => {
        'icon': icon,
        'title': title,
        'description': description,
      };
}

/// AboutUs entity model.
class AboutUs {
  AboutUs({
    this.id,
    required this.ourMission,
    required this.ourStory,
    this.happyCustomer = 0,
    this.products = 0,
    this.satisfaction = 0,
    this.ourValues = const [],
    required this.name,
    required this.tagLine,
    this.createdAt,
    this.updatedAt,
  });

  factory AboutUs.fromBson(Map<String, dynamic> bson) {
    return AboutUs(
      id: ModelHelpers.idToString(bson['_id']),
      ourMission: bson['our_mission']?.toString() ?? '',
      ourStory: bson['our_story']?.toString() ?? '',
      happyCustomer: ModelHelpers.parseInt(bson['happy_customer']) ?? 0,
      products: ModelHelpers.parseInt(bson['products']) ?? 0,
      satisfaction: ModelHelpers.parseInt(
            bson['statisfaction'] ?? bson['satisfaction'],
          ) ??
          0,
      ourValues: (bson['our_values'] as List?)
              ?.map(OurValue.fromMap)
              .toList() ??
          [],
      name: bson['name']?.toString() ?? '',
      tagLine: bson['tag_line']?.toString() ?? '',
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory AboutUs.fromJson(Map<String, dynamic> json) =>
      AboutUs.fromBson(json);

  final String? id;
  final String ourMission;
  final String ourStory;
  final int happyCustomer;
  final int products;
  final int satisfaction;
  final List<OurValue> ourValues;
  final String name;
  final String tagLine;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'our_mission': ourMission,
        'our_story': ourStory,
        'happy_customer': happyCustomer,
        'products': products,
        'statisfaction': satisfaction,
        'our_values': ourValues.map((e) => e.toMap()).toList(),
        'name': name,
        'tag_line': tagLine,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'our_mission': ourMission,
        'our_story': ourStory,
        'happy_customer': happyCustomer,
        'products': products,
        'statisfaction': satisfaction,
        'our_values': ourValues.map((e) => e.toMap()).toList(),
        'name': name,
        'tag_line': tagLine,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
