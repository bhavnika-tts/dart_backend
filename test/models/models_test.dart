import 'package:dart_frog_backend/models/models.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Data Models & BSON Mappers (Phase 2)', () {
    test('User BSON <-> Model <-> JSON serialization', () {
      final id = ObjectId();
      final userCatId = ObjectId();
      final now = DateTime.now().toUtc();

      final bson = <String, dynamic>{
        '_id': id,
        'phone': ['9876543210'],
        'fName': ['Rahul'],
        'lName': ['Sharma'],
        'email': 'rahul@example.com',
        'role': 'user',
        'status': 'Active',
        'userNo': 1001,
        'userCategoryId': userCatId,
        'isVerified': true,
        'isActive': true,
        'createdAt': now,
      };

      final user = User.fromBson(bson);
      expect(user.id, equals(id.$oid));
      expect(user.phone, equals(['9876543210']));
      expect(user.fName, equals(['Rahul']));
      expect(user.email, equals('rahul@example.com'));
      expect(user.userNo, equals(1001));
      expect(user.isVerified, isTrue);

      final json = user.toJson();
      expect(json['_id'], equals(id.$oid));
      expect(json['userCategoryId'], equals(userCatId.$oid));
      expect(json['createdAt'], equals(now.toIso8601String()));

      final roundTripBson = user.toBson();
      expect(roundTripBson['_id'], isA<ObjectId>());
      expect((roundTripBson['_id'] as ObjectId).$oid, equals(id.$oid));
    });

    test('Product with GeoJSON location & dynamic specs serialization', () {
      final prodId = ObjectId();
      final userId = ObjectId();
      final prodTypeId = ObjectId();

      final bson = <String, dynamic>{
        '_id': prodId,
        'userId': userId,
        'title': 'Honda City 2022',
        'price': 850000.0,
        'productType': prodTypeId,
        'location': {
          'type': 'Point',
          'coordinates': [72.5714, 23.0225],
        },
        'specs': {
          'fuel': 'Petrol',
          'transmission': 'Manual',
          'year': 2022,
          'km_driven': 25000,
        },
        'images': ['https://ik.imagekit.io/qa9gwdtkh/car1.jpg'],
        'searchTags': ['honda', 'city', 'sedan'],
      };

      final product = Product.fromBson(bson);
      expect(product.id, equals(prodId.$oid));
      expect(product.title, equals('Honda City 2022'));
      expect(product.price, equals(850000.0));
      expect(product.location.longitude, equals(72.5714));
      expect(product.location.latitude, equals(23.0225));
      expect(product.specs['fuel'], equals('Petrol'));
      expect(product.specs['year'], equals(2022));

      final json = product.toJson();
      final locJson = json['location'] as Map<String, dynamic>;
      expect(locJson['coordinates'], equals([72.5714, 23.0225]));
      final specsJson = json['specs'] as Map<String, dynamic>;
      expect(specsJson['transmission'], equals('Manual'));
    });

    test('FormMetadata with dropdown options and validations', () {
      final formId = ObjectId();
      final prodTypeId = ObjectId();

      final bson = <String, dynamic>{
        '_id': formId,
        'productType': prodTypeId,
        'key': 'fuel_type',
        'label': 'Fuel Type',
        'type': 'dropdown',
        'isOptional': false,
        'options': [
          {'label': 'Petrol', 'value': 'petrol'},
          {'label': 'Diesel', 'value': 'diesel'},
          {'label': 'Electric', 'value': 'electric'},
        ],
        'validation': {
          'pattern': r'^[a-z]+$',
        },
      };

      final meta = FormMetadata.fromBson(bson);
      expect(meta.id, equals(formId.$oid));
      expect(meta.key, equals('fuel_type'));
      expect(meta.isOptional, isFalse);
      expect(meta.options.length, equals(3));
      expect(meta.options[0].label, equals('Petrol'));
      expect(meta.options[0].value, equals('petrol'));

      final json = meta.toJson();
      final optionsJson = json['options'] as List;
      expect(optionsJson.length, equals(3));
      final valJson = json['validation'] as Map<String, dynamic>;
      expect(valJson['pattern'], equals(r'^[a-z]+$'));
    });

    test('ChatMessage with metadata and status', () {
      final msgId = ObjectId();
      final chatId = ObjectId();
      final senderId = ObjectId();

      final bson = <String, dynamic>{
        '_id': msgId,
        'chatId': chatId,
        'senderId': senderId,
        'type': 'text',
        'content': 'Hello, is this product available?',
        'metaData': {
          'clientMessageId': 'client_msg_123',
        },
        'status': 'sent',
      };

      final msg = ChatMessage.fromBson(bson);
      expect(msg.id, equals(msgId.$oid));
      expect(msg.chatId, equals(chatId.$oid));
      expect(msg.content, equals('Hello, is this product available?'));
      expect(msg.metaData.clientMessageId, equals('client_msg_123'));
      expect(msg.status, equals('sent'));
    });

    test('Banner with schedule queue and actions', () {
      final bannerId = ObjectId();
      final start = DateTime.now().toUtc();
      final end = start.add(const Duration(days: 7));

      final bson = <String, dynamic>{
        '_id': bannerId,
        'imageUrl': 'https://ik.imagekit.io/qa9gwdtkh/banner1.png',
        'title': 'Diwali Offer',
        'actionType': 'CATEGORY',
        'actionData': 'Cars',
        'startDate': start,
        'endDate': end,
        'scheduleQueue': [
          {
            'startDate': start,
            'endDate': end,
          },
        ],
      };

      final banner = BannerModel.fromBson(bson);
      expect(banner.id, equals(bannerId.$oid));
      expect(banner.actionType, equals('CATEGORY'));
      expect(banner.actionData, equals('Cars'));
      expect(banner.scheduleQueue.length, equals(1));
    });

    test('Admin & AdminPermission models', () {
      final adminId = ObjectId();
      final adminBson = <String, dynamic>{
        '_id': adminId,
        'username': 'superadmin',
        'email': 'super@classical.com',
        'role': 'superadmin',
      };

      final admin = Admin.fromBson(adminBson);
      expect(admin.id, equals(adminId.$oid));
      expect(admin.isSuperAdmin, isTrue);

      final permBson = <String, dynamic>{
        '_id': ObjectId(),
        'adminId': adminId,
        'permissions': {
          'product': {'read': true, 'write': true, 'assign_pin': false},
          'user': {'read': true, 'write': false, 'assign_pin': true},
        },
      };

      final perm = AdminPermission.fromBson(permBson);
      expect(perm.adminId, equals(adminId.$oid));
      expect(perm.permissions['product']?.read, isTrue);
      expect(perm.permissions['product']?.write, isTrue);
      expect(perm.permissions['user']?.write, isFalse);
      expect(perm.permissions['user']?.assignPin, isTrue);
    });

    test('Common models: Location, Pin, AppVersion, AboutUs, Rating, Image', () {
      final loc = LocationModel.fromBson({
        'Country_Code': 'IN',
        'Postal_Code': '380001',
        'Location_Name': 'Ahmedabad',
        'State': 'Gujarat',
        'State_Code': 'GJ',
        'District': 'Ahmedabad',
        'Sub_district_Code': '01',
        'Sub_district_Name': 'City',
      });
      expect(loc.postalCode, equals('380001'));
      expect(loc.state, equals('Gujarat'));

      final pin = PinModel.fromBson({
        'code': 'JP123',
        'use_count': 5,
        'max_count': 50,
      });
      expect(pin.code, equals('JP123'));
      expect(pin.useCount, equals(5));

      final version = AppVersion.fromBson({
        'version': '1.0.8',
        'versionName': 'V1.0.8',
        'apkLink': 'https://example.com/app.apk',
        'changes': 'Bug fixes and performance improvements',
      });
      expect(version.version, equals('1.0.8'));

      final about = AboutUs.fromBson({
        'our_mission': 'To build the best marketplace',
        'our_story': 'Started in 2026',
        'name': 'Classicale',
        'tag_line': 'Quality & Trust',
      });
      expect(about.name, equals('Classicale'));

      final rating = RatingModel.fromBson({
        'user': ObjectId(),
        'rating': 4.5,
        'comment': 'Great experience!',
      });
      expect(rating.rating, equals(4.5));

      final img = ImageModel.fromBson({
        'url': 'https://ik.imagekit.io/file1.png',
        'fileId': 'file_123',
      });
      expect(img.fileId, equals('file_123'));
    });
  });
}
