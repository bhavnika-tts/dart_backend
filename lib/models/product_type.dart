import 'model_helpers.dart';

/// Form configuration for product type.
class FormConfig {
  FormConfig({
    this.showTitle = true,
    this.isTitleRequired = true,
    this.showDescription = true,
    this.isDescriptionRequired = false,
    this.titleTemplate = '',
  });

  factory FormConfig.fromMap(dynamic map) {
    if (map is! Map) return FormConfig();
    return FormConfig(
      showTitle: ModelHelpers.parseBool(map['showTitle'], defaultValue: true),
      isTitleRequired:
          ModelHelpers.parseBool(map['isTitleRequired'], defaultValue: true),
      showDescription:
          ModelHelpers.parseBool(map['showDescription'], defaultValue: true),
      isDescriptionRequired: ModelHelpers.parseBool(
        map['isDescriptionRequired'],
      ),
      titleTemplate: map['titleTemplate']?.toString() ?? '',
    );
  }

  final bool showTitle;
  final bool isTitleRequired;
  final bool showDescription;
  final bool isDescriptionRequired;
  final String titleTemplate;

  Map<String, dynamic> toMap() => {
        'showTitle': showTitle,
        'isTitleRequired': isTitleRequired,
        'showDescription': showDescription,
        'isDescriptionRequired': isDescriptionRequired,
        'titleTemplate': titleTemplate,
      };
}

/// ProductType entity model.
class ProductType {
  ProductType({
    this.id,
    required this.name,
    required this.modelName,
    FormConfig? formConfig,
    this.createTime,
  }) : formConfig = formConfig ?? FormConfig();

  factory ProductType.fromBson(Map<String, dynamic> bson) {
    return ProductType(
      id: ModelHelpers.idToString(bson['_id']),
      name: bson['name']?.toString() ?? '',
      modelName: bson['modelName']?.toString() ?? '',
      formConfig: FormConfig.fromMap(bson['formConfig']),
      createTime: ModelHelpers.parseDateTime(bson['createTime']),
    );
  }

  factory ProductType.fromJson(Map<String, dynamic> json) =>
      ProductType.fromBson(json);

  final String? id;
  final String name;
  final String modelName;
  final FormConfig formConfig;
  final DateTime? createTime;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'name': name,
        'modelName': modelName,
        'formConfig': formConfig.toMap(),
        if (createTime != null)
          'createTime': ModelHelpers.toIsoString(createTime),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'name': name,
        'modelName': modelName,
        'formConfig': formConfig.toMap(),
        if (createTime != null) 'createTime': createTime,
      };
}
