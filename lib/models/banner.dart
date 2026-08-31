import 'model_helpers.dart';

/// Banner schedule entry.
class BannerScheduleItem {
  BannerScheduleItem({
    required this.startDate,
    required this.endDate,
    this.scheduledAt,
    this.scheduledBy,
  });

  factory BannerScheduleItem.fromBson(Map<String, dynamic> bson) {
    return BannerScheduleItem(
      startDate: ModelHelpers.parseDateTime(bson['startDate']) ?? DateTime.now(),
      endDate: ModelHelpers.parseDateTime(bson['endDate']) ?? DateTime.now(),
      scheduledAt: ModelHelpers.parseDateTime(bson['scheduledAt']),
      scheduledBy: ModelHelpers.idToString(bson['scheduledBy']),
    );
  }

  final DateTime startDate;
  final DateTime endDate;
  final DateTime? scheduledAt;
  final String? scheduledBy;

  Map<String, dynamic> toJson() => {
        'startDate': ModelHelpers.toIsoString(startDate),
        'endDate': ModelHelpers.toIsoString(endDate),
        if (scheduledAt != null)
          'scheduledAt': ModelHelpers.toIsoString(scheduledAt),
        if (scheduledBy != null) 'scheduledBy': scheduledBy,
      };

  Map<String, dynamic> toBson() => {
        'startDate': startDate,
        'endDate': endDate,
        if (scheduledAt != null) 'scheduledAt': scheduledAt,
        if (scheduledBy != null)
          'scheduledBy':
              ModelHelpers.toObjectId(scheduledBy) ?? scheduledBy,
      };
}

/// Banner entity model.
class BannerModel {
  BannerModel({
    this.id,
    required this.imageUrl,
    this.title,
    this.description,
    this.categoryName,
    this.productType,
    this.startDate,
    this.endDate,
    this.area,
    this.city,
    this.state,
    this.country,
    this.actionType = 'NONE',
    this.actionData,
    this.allowedUserPlans = const [],
    this.clickCount = 0,
    this.scheduleTimezoneMigrationVersion = 0,
    this.scheduleTimezoneMigratedAt,
    this.isActive = true,
    this.order = 0,
    this.createdBy,
    this.repostCount = 0,
    this.scheduleQueue = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory BannerModel.fromBson(Map<String, dynamic> bson) {
    return BannerModel(
      id: ModelHelpers.idToString(bson['_id']),
      imageUrl: bson['imageUrl']?.toString() ?? '',
      title: bson['title']?.toString(),
      description: bson['description']?.toString(),
      categoryName: bson['categoryName']?.toString(),
      productType: ModelHelpers.idToString(bson['productType']),
      startDate: ModelHelpers.parseDateTime(bson['startDate']),
      endDate: ModelHelpers.parseDateTime(bson['endDate']),
      area: bson['area']?.toString(),
      city: bson['city']?.toString(),
      state: bson['state']?.toString(),
      country: bson['country']?.toString(),
      actionType: bson['actionType']?.toString() ?? 'NONE',
      actionData: bson['actionData']?.toString(),
      allowedUserPlans: ModelHelpers.parseStringList(bson['allowedUserPlans']),
      clickCount: ModelHelpers.parseInt(bson['clickCount']) ?? 0,
      scheduleTimezoneMigrationVersion:
          ModelHelpers.parseInt(bson['scheduleTimezoneMigrationVersion']) ?? 0,
      scheduleTimezoneMigratedAt:
          ModelHelpers.parseDateTime(bson['scheduleTimezoneMigratedAt']),
      isActive: ModelHelpers.parseBool(bson['isActive'], defaultValue: true),
      order: ModelHelpers.parseInt(bson['order']) ?? 0,
      createdBy: ModelHelpers.idToString(bson['createdBy']),
      repostCount: ModelHelpers.parseInt(bson['repostCount']) ?? 0,
      scheduleQueue: (bson['scheduleQueue'] as List?)
              ?.map(
                (e) =>
                    BannerScheduleItem.fromBson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      BannerModel.fromBson(json);

  final String? id;
  final String imageUrl;
  final String? title;
  final String? description;
  final String? categoryName;
  final String? productType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? area;
  final String? city;
  final String? state;
  final String? country;
  final String actionType;
  final String? actionData;
  final List<String> allowedUserPlans;
  final int clickCount;
  final int scheduleTimezoneMigrationVersion;
  final DateTime? scheduleTimezoneMigratedAt;
  final bool isActive;
  final int order;
  final String? createdBy;
  final int repostCount;
  final List<BannerScheduleItem> scheduleQueue;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'imageUrl': imageUrl,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (categoryName != null) 'categoryName': categoryName,
        if (productType != null) 'productType': productType,
        if (startDate != null) 'startDate': ModelHelpers.toIsoString(startDate),
        if (endDate != null) 'endDate': ModelHelpers.toIsoString(endDate),
        if (area != null) 'area': area,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
        'actionType': actionType,
        if (actionData != null) 'actionData': actionData,
        'allowedUserPlans': allowedUserPlans,
        'clickCount': clickCount,
        'isActive': isActive,
        'order': order,
        if (createdBy != null) 'createdBy': createdBy,
        'repostCount': repostCount,
        'scheduleQueue': scheduleQueue.map((e) => e.toJson()).toList(),
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'imageUrl': imageUrl,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (categoryName != null) 'categoryName': categoryName,
        if (productType != null)
          'productType': ModelHelpers.toObjectId(productType) ?? productType,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (area != null) 'area': area,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
        'actionType': actionType,
        if (actionData != null) 'actionData': actionData,
        'allowedUserPlans': allowedUserPlans,
        'clickCount': clickCount,
        'isActive': isActive,
        'order': order,
        if (createdBy != null)
          'createdBy': ModelHelpers.toObjectId(createdBy) ?? createdBy,
        'repostCount': repostCount,
        'scheduleQueue': scheduleQueue.map((e) => e.toBson()).toList(),
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
