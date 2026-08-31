import 'model_helpers.dart';

/// Location entity model matching `new_backend/src/models/location.model.js`.
class LocationModel {
  LocationModel({
    this.id,
    required this.countryCode,
    required this.postalCode,
    required this.locationName,
    required this.state,
    required this.stateCode,
    required this.district,
    required this.subDistrictCode,
    required this.subDistrictName,
  });

  factory LocationModel.fromBson(Map<String, dynamic> bson) {
    return LocationModel(
      id: ModelHelpers.idToString(bson['_id']),
      countryCode:
          bson['Country_Code']?.toString() ?? bson['countryCode']?.toString() ?? '',
      postalCode:
          bson['Postal_Code']?.toString() ?? bson['postalCode']?.toString() ?? '',
      locationName:
          bson['Location_Name']?.toString() ?? bson['locationName']?.toString() ?? '',
      state: bson['State']?.toString() ?? bson['state']?.toString() ?? '',
      stateCode:
          bson['State_Code']?.toString() ?? bson['stateCode']?.toString() ?? '',
      district:
          bson['District']?.toString() ?? bson['district']?.toString() ?? '',
      subDistrictCode: bson['Sub_district_Code']?.toString() ??
          bson['subDistrictCode']?.toString() ??
          '',
      subDistrictName: bson['Sub_district_Name']?.toString() ??
          bson['subDistrictName']?.toString() ??
          '',
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      LocationModel.fromBson(json);

  final String? id;
  final String countryCode;
  final String postalCode;
  final String locationName;
  final String state;
  final String stateCode;
  final String district;
  final String subDistrictCode;
  final String subDistrictName;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'Country_Code': countryCode,
        'Postal_Code': postalCode,
        'Location_Name': locationName,
        'State': state,
        'State_Code': stateCode,
        'District': district,
        'Sub_district_Code': subDistrictCode,
        'Sub_district_Name': subDistrictName,
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'Country_Code': countryCode,
        'Postal_Code': postalCode,
        'Location_Name': locationName,
        'State': state,
        'State_Code': stateCode,
        'District': district,
        'Sub_district_Code': subDistrictCode,
        'Sub_district_Name': subDistrictName,
      };
}
