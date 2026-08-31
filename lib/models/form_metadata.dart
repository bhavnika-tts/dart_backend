import 'model_helpers.dart';

/// Dropdown option for dynamic form fields.
class DropdownOption {
  DropdownOption({required this.label, required this.value});

  factory DropdownOption.fromMap(dynamic map) {
    if (map is! Map) return DropdownOption(label: '', value: '');
    return DropdownOption(
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
    );
  }

  final String label;
  final String value;

  Map<String, dynamic> toMap() => {
        'label': label,
        'value': value,
      };
}

/// Field validation rules.
class FieldValidation {
  FieldValidation({
    this.min,
    this.max,
    this.minLength,
    this.maxLength,
    this.pattern = '',
  });

  factory FieldValidation.fromMap(dynamic map) {
    if (map is! Map) return FieldValidation();
    return FieldValidation(
      min: ModelHelpers.parseDouble(map['min']),
      max: ModelHelpers.parseDouble(map['max']),
      minLength: ModelHelpers.parseInt(map['minLength']),
      maxLength: ModelHelpers.parseInt(map['maxLength']),
      pattern: map['pattern']?.toString() ?? '',
    );
  }

  final double? min;
  final double? max;
  final int? minLength;
  final int? maxLength;
  final String pattern;

  Map<String, dynamic> toMap() => {
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        if (minLength != null) 'minLength': minLength,
        if (maxLength != null) 'maxLength': maxLength,
        'pattern': pattern,
      };
}

/// Dynamic Form Metadata entity model.
class FormMetadata {
  FormMetadata({
    this.id,
    required this.productType,
    this.subProductType,
    this.subProductTypes = const [],
    required this.key,
    required this.label,
    required this.type,
    this.isOptional = true,
    this.isHidden = false,
    this.isSystemField = false,
    this.unit = '',
    this.options = const [],
    this.defaultValue = '',
    this.displayOrder = 0,
    this.groupName = 'Specifications',
    this.isHighlight = false,
    this.cardDisplayOrder = 0,
    this.isFilterable = true,
    FieldValidation? validation,
    this.placeholder = '',
    this.helpText = '',
    this.createdAt,
    this.updatedAt,
  }) : validation = validation ?? FieldValidation();

  factory FormMetadata.fromBson(Map<String, dynamic> bson) {
    return FormMetadata(
      id: ModelHelpers.idToString(bson['_id']),
      productType: ModelHelpers.idToString(bson['productType']) ?? '',
      subProductType: ModelHelpers.idToString(bson['subProductType']),
      subProductTypes: ModelHelpers.parseStringList(bson['subProductTypes']),
      key: bson['key']?.toString() ?? '',
      label: bson['label']?.toString() ?? '',
      type: bson['type']?.toString() ?? 'text',
      isOptional: ModelHelpers.parseBool(bson['isOptional'], defaultValue: true),
      isHidden: ModelHelpers.parseBool(bson['isHidden']),
      isSystemField: ModelHelpers.parseBool(bson['isSystemField']),
      unit: bson['unit']?.toString() ?? '',
      options: (bson['options'] as List?)
              ?.map(DropdownOption.fromMap)
              .toList() ??
          [],
      defaultValue: bson['defaultValue']?.toString() ?? '',
      displayOrder: ModelHelpers.parseInt(bson['displayOrder']) ?? 0,
      groupName: bson['groupName']?.toString() ?? 'Specifications',
      isHighlight: ModelHelpers.parseBool(bson['isHighlight']),
      cardDisplayOrder: ModelHelpers.parseInt(bson['cardDisplayOrder']) ?? 0,
      isFilterable: ModelHelpers.parseBool(bson['isFilterable'], defaultValue: true),
      validation: FieldValidation.fromMap(bson['validation']),
      placeholder: bson['placeholder']?.toString() ?? '',
      helpText: bson['helpText']?.toString() ?? '',
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory FormMetadata.fromJson(Map<String, dynamic> json) =>
      FormMetadata.fromBson(json);

  final String? id;
  final String productType;
  final String? subProductType;
  final List<String> subProductTypes;
  final String key;
  final String label;
  final String type;
  final bool isOptional;
  final bool isHidden;
  final bool isSystemField;
  final String unit;
  final List<DropdownOption> options;
  final String defaultValue;
  final int displayOrder;
  final String groupName;
  final bool isHighlight;
  final int cardDisplayOrder;
  final bool isFilterable;
  final FieldValidation validation;
  final String placeholder;
  final String helpText;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'productType': productType,
        if (subProductType != null) 'subProductType': subProductType,
        'subProductTypes': subProductTypes,
        'key': key,
        'label': label,
        'type': type,
        'isOptional': isOptional,
        'isHidden': isHidden,
        'isSystemField': isSystemField,
        'unit': unit,
        'options': options.map((e) => e.toMap()).toList(),
        'defaultValue': defaultValue,
        'displayOrder': displayOrder,
        'groupName': groupName,
        'isHighlight': isHighlight,
        'cardDisplayOrder': cardDisplayOrder,
        'isFilterable': isFilterable,
        'validation': validation.toMap(),
        'placeholder': placeholder,
        'helpText': helpText,
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'productType': ModelHelpers.toObjectId(productType) ?? productType,
        if (subProductType != null)
          'subProductType':
              ModelHelpers.toObjectId(subProductType) ?? subProductType,
        'subProductTypes': subProductTypes
            .map((e) => ModelHelpers.toObjectId(e) ?? e)
            .toList(),
        'key': key,
        'label': label,
        'type': type,
        'isOptional': isOptional,
        'isHidden': isHidden,
        'isSystemField': isSystemField,
        'unit': unit,
        'options': options.map((e) => e.toMap()).toList(),
        'defaultValue': defaultValue,
        'displayOrder': displayOrder,
        'groupName': groupName,
        'isHighlight': isHighlight,
        'cardDisplayOrder': cardDisplayOrder,
        'isFilterable': isFilterable,
        'validation': validation.toMap(),
        'placeholder': placeholder,
        'helpText': helpText,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
