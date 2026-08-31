import 'model_helpers.dart';

/// Admin entity model.
class Admin {
  Admin({
    this.id,
    required this.username,
    required this.email,
    this.password,
    this.fName = '',
    this.lName = '',
    this.mName = '',
    this.phone = '',
    this.profileImage = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.area = '',
    this.street1 = '',
    this.street2 = '',
    this.pinCode = '',
    this.gender = '',
    this.dob = '',
    this.role = 'subadmin',
    this.deviceToken = '',
    this.referralCode,
    this.tokenVersion = 0,
    this.passwordChangedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Admin.fromBson(Map<String, dynamic> bson) {
    return Admin(
      id: ModelHelpers.idToString(bson['_id']),
      username: bson['username']?.toString() ?? '',
      email: bson['email']?.toString() ?? '',
      password: bson['password']?.toString(),
      fName: bson['fName']?.toString() ?? '',
      lName: bson['lName']?.toString() ?? '',
      mName: bson['mName']?.toString() ?? '',
      phone: bson['phone']?.toString() ?? '',
      profileImage: bson['profileImage']?.toString() ?? '',
      country: bson['country']?.toString() ?? '',
      state: bson['state']?.toString() ?? '',
      city: bson['city']?.toString() ?? '',
      area: bson['area']?.toString() ?? '',
      street1: bson['street1']?.toString() ?? '',
      street2: bson['street2']?.toString() ?? '',
      pinCode: bson['pinCode']?.toString() ?? '',
      gender: bson['gender']?.toString() ?? '',
      dob: bson['DOB']?.toString() ?? '',
      role: bson['role']?.toString() ?? 'subadmin',
      deviceToken: bson['deviceToken']?.toString() ?? '',
      referralCode: bson['referralCode']?.toString(),
      tokenVersion: ModelHelpers.parseInt(bson['tokenVersion']) ?? 0,
      passwordChangedAt: ModelHelpers.parseDateTime(bson['passwordChangedAt']),
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory Admin.fromJson(Map<String, dynamic> json) => Admin.fromBson(json);

  final String? id;
  final String username;
  final String email;
  final String? password;
  final String fName;
  final String lName;
  final String mName;
  final String phone;
  final String profileImage;
  final String country;
  final String state;
  final String city;
  final String area;
  final String street1;
  final String street2;
  final String pinCode;
  final String gender;
  final String dob;
  final String role;
  final String deviceToken;
  final String? referralCode;
  final int tokenVersion;
  final DateTime? passwordChangedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isSuperAdmin => role == 'superadmin';

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'username': username,
        'email': email,
        'fName': fName,
        'lName': lName,
        'mName': mName,
        'phone': phone,
        'profileImage': profileImage,
        'country': country,
        'state': state,
        'city': city,
        'area': area,
        'street1': street1,
        'street2': street2,
        'pinCode': pinCode,
        'gender': gender,
        'DOB': dob,
        'role': role,
        'deviceToken': deviceToken,
        if (referralCode != null) 'referralCode': referralCode,
        'tokenVersion': tokenVersion,
        if (passwordChangedAt != null)
          'passwordChangedAt': ModelHelpers.toIsoString(passwordChangedAt),
        if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
        if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
      };

  Map<String, dynamic> toBson() => {
        if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
        'username': username,
        'email': email,
        if (password != null) 'password': password,
        'fName': fName,
        'lName': lName,
        'mName': mName,
        'phone': phone,
        'profileImage': profileImage,
        'country': country,
        'state': state,
        'city': city,
        'area': area,
        'street1': street1,
        'street2': street2,
        'pinCode': pinCode,
        'gender': gender,
        'DOB': dob,
        'role': role,
        'deviceToken': deviceToken,
        if (referralCode != null) 'referralCode': referralCode,
        'tokenVersion': tokenVersion,
        if (passwordChangedAt != null) 'passwordChangedAt': passwordChangedAt,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
