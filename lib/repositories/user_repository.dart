import 'package:mongo_dart/mongo_dart.dart';
import '../core/db/mongo_client.dart';
import '../models/model_helpers.dart';
import '../models/occupation.dart';
import '../models/user.dart';
import '../models/user_category_permission.dart';

/// Repository for User, CategoryPermissions, and Occupation database queries.
class UserRepository {
  UserRepository({MongoClient? mongoClient})
      : _mongoClient = mongoClient ?? MongoClient.instance;

  final MongoClient _mongoClient;

  static UserRepository? _instance;
  static UserRepository get instance => _instance ??= UserRepository();

  DbCollection get _usersCollection => _mongoClient.collection('users');
  DbCollection get _categoriesCollection => _mongoClient.collection('user_category_permissions');
  DbCollection get _restrictionsCollection => _mongoClient.collection('category_restrictions');
  DbCollection get _occupationsCollection => _mongoClient.collection('occupations');

  Future<User?> findByEmailAndCategory(String email, String userCategory) async {
    final doc = await _usersCollection.findOne(
      where.eq('email', email.trim()).eq('userCategory', userCategory.trim()),
    );
    if (doc == null) return null;
    return User.fromBson(doc);
  }

  Future<User?> findByPhoneAndCategory(String phone, String userCategory) async {
    final doc = await _usersCollection.findOne(
      where.oneFrom('phone', [phone.trim()]).eq('userCategory', userCategory.trim()),
    );
    if (doc == null) return null;
    return User.fromBson(doc);
  }

  Future<User?> findByEmailOrPhone(String identifier, {String? userCategory}) async {
    final clean = identifier.trim();
    final selector = userCategory != null
        ? where.eq('userCategory', userCategory).and(
            where.eq('email', clean).or(where.oneFrom('phone', [clean])),
          )
        : where.eq('email', clean).or(where.oneFrom('phone', [clean]));

    final doc = await _usersCollection.findOne(selector);
    if (doc == null) return null;
    return User.fromBson(doc);
  }

  Future<User?> findById(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;
    final doc = await _usersCollection.findOne(where.id(objId));
    if (doc == null) return null;
    return User.fromBson(doc);
  }

  Future<int> getNextUserNo() async {
    final count = await _usersCollection.count();
    return count + 1001;
  }

  Future<User> create(User user) async {
    final doc = user.toBson();
    doc['createdAt'] = DateTime.now();
    doc['updatedAt'] = DateTime.now();

    final result = await _usersCollection.insertOne(doc);
    return User.fromBson({...doc, '_id': result.id});
  }

  Future<User?> update(String id, Map<String, dynamic> updateData) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;

    final sanitized = <String, dynamic>{...updateData}
      ..remove('_id')
      ..['updatedAt'] = DateTime.now();

    for (final entry in sanitized.entries) {
      await _usersCollection.updateOne(
        where.id(objId),
        modify.set(entry.key, entry.value),
      );
    }

    return findById(id);
  }

  Future<List<UserCategoryPermission>> getPublicUserCategories() async {
    final cursor = _categoriesCollection.find(where.eq('isActive', true));
    final list = await cursor.toList();
    return list.map(UserCategoryPermission.fromBson).toList();
  }

  Future<UserCategoryPermission?> getCategoryByKey(String categoryKey) async {
    final doc = await _categoriesCollection.findOne(where.eq('categoryKey', categoryKey));
    if (doc == null) return null;
    return UserCategoryPermission.fromBson(doc);
  }

  Future<({List<String> read, List<String> write})> getUserPermissions(String userId) async {
    final user = await findById(userId);
    if (user == null || user.userCategory == null) {
      return (read: <String>[], write: <String>[]);
    }

    final category = await getCategoryByKey(user.userCategory!);
    if (category == null) {
      return (read: <String>[], write: <String>[]);
    }

    return (read: category.read, write: category.write);
  }

  Future<List<String>> getAllowedProductTypes(String userId) async {
    final user = await findById(userId);
    if (user == null || user.userCategory == null) return [];

    final restriction = await _restrictionsCollection.findOne(
      where.eq('userCategory', user.userCategory),
    );

    if (restriction != null) {
      final allowed = restriction['allowedProductTypes'] as List?;
      if (allowed != null) {
        return allowed.map((e) => ModelHelpers.idToString(e) ?? e.toString()).toList();
      }
    }

    return [];
  }

  Future<List<Occupation>> getOccupations() async {
    final cursor = _occupationsCollection.find(where.sortBy('name'));
    final list = await cursor.toList();
    return list.map(Occupation.fromBson).toList();
  }
}
