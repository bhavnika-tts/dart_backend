import 'model_helpers.dart';

/// User entity model with 100% field parity with `new_backend/src/models/user.model.js`.
class User {
  User({
    this.id,
    this.uuid,
    this.token,
    this.userCategoryId,
    this.phone = const [],
    this.assignedPins,
    this.assignedByAdmin,
    this.referCode,
    this.fName = const [],
    this.lName = const [],
    this.mName = const [],
    this.email,
    this.password,
    this.gender = const [],
    this.dob = const [],
    this.occupationId,
    this.country = const [],
    this.state = const [],
    this.city = const [],
    this.area = const [],
    this.street1 = const [],
    this.street2 = const [],
    this.pinCode = const [],
    this.uIdNumber = const [],
    this.profileImage = const [],
    this.aadhaarCardImage1 = const [],
    this.aadhaarCardImage2 = const [],
    this.aadharNumber = const [],
    this.role = 'user',
    this.deviceToken = '',
    this.status = 'Active',
    this.userCategory,
    this.userNo,
    this.isVerified = false,
    this.isDeleted = false,
    this.isBlocked = false,
    this.isPinVerified = false,
    this.isOtpVerified = false,
    this.verifiedByAdmin = false,
    this.aadhaarRejectionReason = '',
    this.oneTimePin,
    this.isActive = true,
    this.otp,
    this.otpExpire,
    this.otpRequested = false,
    this.otpRequestedAt,
    this.otpRequestCount = 0,
    this.updateCount = 0,
    this.sessionToken,
    this.tokenVersion = 0,
    this.passwordChangedAt,
    this.isOnline = false,
    this.lastSeen,
    this.favorite = const [],
    this.createdAt,
    this.updatedAt,
    this.readPermissions = const [],
    this.writePermissions = const [],
  });

  factory User.fromBson(Map<String, dynamic> bson) {
    return User(
      id: ModelHelpers.idToString(bson['_id']),
      uuid: bson['uuid']?.toString(),
      token: bson['token']?.toString(),
      userCategoryId: ModelHelpers.idToString(bson['userCategoryId']),
      phone: ModelHelpers.parseStringList(bson['phone']),
      assignedPins: bson['assignedPins']?.toString(),
      assignedByAdmin: ModelHelpers.idToString(bson['assignedByAdmin']),
      referCode: bson['referCode']?.toString(),
      fName: ModelHelpers.parseStringList(bson['fName']),
      lName: ModelHelpers.parseStringList(bson['lName']),
      mName: ModelHelpers.parseStringList(bson['mName']),
      email: bson['email']?.toString(),
      password: bson['password']?.toString(),
      gender: ModelHelpers.parseStringList(bson['gender']),
      dob: ModelHelpers.parseStringList(bson['DOB']),
      occupationId: ModelHelpers.idToString(bson['occupationId']),
      country: ModelHelpers.parseStringList(bson['country']),
      state: ModelHelpers.parseStringList(bson['state']),
      city: ModelHelpers.parseStringList(bson['city']),
      area: ModelHelpers.parseStringList(bson['area']),
      street1: ModelHelpers.parseStringList(bson['street1']),
      street2: ModelHelpers.parseStringList(bson['street2']),
      pinCode: ModelHelpers.parseStringList(bson['pinCode']),
      uIdNumber: ModelHelpers.parseStringList(bson['uIdNumber']),
      profileImage: ModelHelpers.parseStringList(bson['profileImage']),
      aadhaarCardImage1: ModelHelpers.parseStringList(bson['aadhaarCardImage1']),
      aadhaarCardImage2: ModelHelpers.parseStringList(bson['aadhaarCardImage2']),
      aadharNumber: ModelHelpers.parseStringList(bson['aadharNumber']),
      role: bson['role']?.toString() ?? 'user',
      deviceToken: bson['deviceToken']?.toString() ?? '',
      status: bson['status']?.toString() ?? 'Active',
      userCategory: bson['userCategory']?.toString(),
      userNo: ModelHelpers.parseInt(bson['userNo']),
      isVerified: ModelHelpers.parseBool(bson['isVerified']),
      isDeleted: ModelHelpers.parseBool(bson['isDeleted']),
      isBlocked: ModelHelpers.parseBool(bson['isBlocked']),
      isPinVerified: ModelHelpers.parseBool(bson['isPinVerified']),
      isOtpVerified: ModelHelpers.parseBool(bson['isOtpVerified']),
      verifiedByAdmin: ModelHelpers.parseBool(bson['verified_by_admin']),
      aadhaarRejectionReason: bson['aadhaarRejectionReason']?.toString() ?? '',
      oneTimePin: bson['oneTimePin']?.toString(),
      isActive: ModelHelpers.parseBool(bson['isActive'], defaultValue: true),
      otp: bson['otp']?.toString(),
      otpExpire: ModelHelpers.parseDateTime(bson['otpExpire']),
      otpRequested: ModelHelpers.parseBool(bson['otpRequested']),
      otpRequestedAt: ModelHelpers.parseDateTime(bson['otpRequestedAt']),
      otpRequestCount: ModelHelpers.parseInt(bson['otpRequestCount']) ?? 0,
      updateCount: ModelHelpers.parseInt(bson['updateCount']) ?? 0,
      sessionToken: bson['sessionToken']?.toString(),
      tokenVersion: ModelHelpers.parseInt(bson['tokenVersion']) ?? 0,
      passwordChangedAt: ModelHelpers.parseDateTime(bson['passwordChangedAt']),
      isOnline: ModelHelpers.parseBool(bson['isOnline']),
      lastSeen: ModelHelpers.parseDateTime(bson['lastSeen']),
      favorite: (bson['favorite'] as List?)
              ?.map((e) => UserFavorite.fromBson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: ModelHelpers.parseDateTime(bson['createdAt']),
      updatedAt: ModelHelpers.parseDateTime(bson['updatedAt']),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User.fromBson(json);

  final String? id;
  final String? uuid;
  final String? token;
  final String? userCategoryId;
  final List<String> phone;
  final String? assignedPins;
  final String? assignedByAdmin;
  final String? referCode;
  final List<String> fName;
  final List<String> lName;
  final List<String> mName;
  final String? email;
  final String? password;
  final List<String> gender;
  final List<String> dob;
  final String? occupationId;
  final List<String> country;
  final List<String> state;
  final List<String> city;
  List<String> get district => city;
  final List<String> area;
  final List<String> street1;
  final List<String> street2;
  final List<String> pinCode;
  final List<String> uIdNumber;
  final List<String> profileImage;
  final List<String> aadhaarCardImage1;
  final List<String> aadhaarCardImage2;
  final List<String> aadharNumber;
  final String role;
  final String deviceToken;
  final String status;
  final String? userCategory;
  final int? userNo;
  final bool isVerified;
  final bool isDeleted;
  final bool isBlocked;
  final bool isPinVerified;
  final bool isOtpVerified;
  final bool verifiedByAdmin;
  final String aadhaarRejectionReason;
  final String? oneTimePin;
  final bool isActive;
  final String? otp;
  final DateTime? otpExpire;
  final bool otpRequested;
  final DateTime? otpRequestedAt;
  final int otpRequestCount;
  final int updateCount;
  final String? sessionToken;
  final int tokenVersion;
  final DateTime? passwordChangedAt;
  final bool isOnline;
  final DateTime? lastSeen;
  final List<UserFavorite> favorite;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> readPermissions;
  final List<String> writePermissions;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (uuid != null) 'uuid': uuid,
      if (token != null) 'token': token,
      if (userCategoryId != null) 'userCategoryId': userCategoryId,
      'phone': phone,
      if (assignedPins != null) 'assignedPins': assignedPins,
      if (assignedByAdmin != null) 'assignedByAdmin': assignedByAdmin,
      if (referCode != null) 'referCode': referCode,
      'fName': fName,
      'lName': lName,
      'mName': mName,
      if (email != null) 'email': email,
      'gender': gender,
      'DOB': dob,
      if (occupationId != null) 'occupationId': occupationId,
      'country': country,
      'state': state,
      'city': city,
      'area': area,
      'street1': street1,
      'street2': street2,
      'pinCode': pinCode,
      'uIdNumber': uIdNumber,
      'profileImage': profileImage,
      'aadhaarCardImage1': aadhaarCardImage1,
      'aadhaarCardImage2': aadhaarCardImage2,
      'aadharNumber': aadharNumber,
      'role': role,
      'deviceToken': deviceToken,
      'status': status,
      if (userCategory != null) 'userCategory': userCategory,
      if (userNo != null) 'userNo': userNo,
      'isVerified': isVerified,
      'isDeleted': isDeleted,
      'isBlocked': isBlocked,
      'isPinVerified': isPinVerified,
      'isOtpVerified': isOtpVerified,
      'verified_by_admin': verifiedByAdmin,
      'aadhaarRejectionReason': aadhaarRejectionReason,
      'isActive': isActive,
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': ModelHelpers.toIsoString(lastSeen),
      'favorite': favorite.map((e) => e.toJson()).toList(),
      if (readPermissions.isNotEmpty) 'read': readPermissions,
      if (writePermissions.isNotEmpty) 'write': writePermissions,
      if (createdAt != null) 'createdAt': ModelHelpers.toIsoString(createdAt),
      if (updatedAt != null) 'updatedAt': ModelHelpers.toIsoString(updatedAt),
    };
  }

  Map<String, dynamic> toBson() {
    return {
      if (id != null) '_id': ModelHelpers.toObjectId(id) ?? id,
      if (uuid != null) 'uuid': uuid,
      if (token != null) 'token': token,
      if (userCategoryId != null)
        'userCategoryId': ModelHelpers.toObjectId(userCategoryId) ?? userCategoryId,
      'phone': phone,
      if (assignedPins != null) 'assignedPins': assignedPins,
      if (assignedByAdmin != null)
        'assignedByAdmin':
            ModelHelpers.toObjectId(assignedByAdmin) ?? assignedByAdmin,
      if (referCode != null) 'referCode': referCode,
      'fName': fName,
      'lName': lName,
      'mName': mName,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      'gender': gender,
      'DOB': dob,
      if (occupationId != null)
        'occupationId': ModelHelpers.toObjectId(occupationId) ?? occupationId,
      'country': country,
      'state': state,
      'city': city,
      'area': area,
      'street1': street1,
      'street2': street2,
      'pinCode': pinCode,
      'uIdNumber': uIdNumber,
      'profileImage': profileImage,
      'aadhaarCardImage1': aadhaarCardImage1,
      'aadhaarCardImage2': aadhaarCardImage2,
      'aadharNumber': aadharNumber,
      'role': role,
      'deviceToken': deviceToken,
      'status': status,
      if (userCategory != null) 'userCategory': userCategory,
      if (userNo != null) 'userNo': userNo,
      'isVerified': isVerified,
      'isDeleted': isDeleted,
      'isBlocked': isBlocked,
      'isPinVerified': isPinVerified,
      'isOtpVerified': isOtpVerified,
      'verified_by_admin': verifiedByAdmin,
      'aadhaarRejectionReason': aadhaarRejectionReason,
      if (oneTimePin != null) 'oneTimePin': oneTimePin,
      'isActive': isActive,
      if (otp != null) 'otp': otp,
      if (otpExpire != null) 'otpExpire': otpExpire,
      'otpRequested': otpRequested,
      if (otpRequestedAt != null) 'otpRequestedAt': otpRequestedAt,
      'otpRequestCount': otpRequestCount,
      'updateCount': updateCount,
      if (sessionToken != null) 'sessionToken': sessionToken,
      'tokenVersion': tokenVersion,
      if (passwordChangedAt != null) 'passwordChangedAt': passwordChangedAt,
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': lastSeen,
      'favorite': favorite.map((e) => e.toBson()).toList(),
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

class UserFavorite {
  UserFavorite({this.productId, this.modelName});

  factory UserFavorite.fromBson(Map<String, dynamic> bson) {
    return UserFavorite(
      productId: ModelHelpers.idToString(bson['productId']),
      modelName: bson['modelName']?.toString(),
    );
  }

  final String? productId;
  final String? modelName;

  Map<String, dynamic> toJson() => {
        if (productId != null) 'productId': productId,
        if (modelName != null) 'modelName': modelName,
      };

  Map<String, dynamic> toBson() => {
        if (productId != null)
          'productId': ModelHelpers.toObjectId(productId) ?? productId,
        if (modelName != null) 'modelName': modelName,
      };
}
