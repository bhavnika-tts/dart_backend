import 'package:mongo_dart/mongo_dart.dart';
import '../core/db/mongo_client.dart';
import '../models/app_version.dart';
import '../models/model_helpers.dart';

/// Repository for AppVersion collection operations.
class AppVersionRepository {
  AppVersionRepository({MongoClient? mongoClient})
      : _mongoClient = mongoClient ?? MongoClient.instance;

  final MongoClient _mongoClient;

  static AppVersionRepository? _instance;
  static AppVersionRepository get instance => _instance ??= AppVersionRepository();

  DbCollection get _collection => _mongoClient.collection('app_versions');

  Future<AppVersion?> findByVersionNumber(String version) async {
    final doc = await _collection.findOne(where.eq('version', version));
    if (doc == null) return null;
    return AppVersion.fromBson(doc);
  }

  Future<AppVersion?> findByVersionName(String versionName) async {
    final doc = await _collection.findOne(where.eq('versionName', versionName));
    if (doc == null) return null;
    return AppVersion.fromBson(doc);
  }

  Future<AppVersion> create(AppVersion version) async {
    final doc = version.toBson();
    doc['createdAt'] = DateTime.now();
    doc['updatedAt'] = DateTime.now();
    final result = await _collection.insertOne(doc);
    final insertedId = result.id;
    return AppVersion.fromBson({...doc, '_id': insertedId});
  }

  Future<List<AppVersion>> findAllSorted() async {
    final cursor = _collection.find(where.sortBy('version', descending: true));
    final list = await cursor.toList();
    return list.map(AppVersion.fromBson).toList();
  }

  Future<AppVersion?> findLatestActive() async {
    final doc = await _collection.findOne(
      where.eq('isActive', true).sortBy('version', descending: true),
    );
    if (doc == null) return null;
    return AppVersion.fromBson(doc);
  }

  Future<AppVersion?> findById(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;
    final doc = await _collection.findOne(where.id(objId));
    if (doc == null) return null;
    return AppVersion.fromBson(doc);
  }

  Future<AppVersion?> update(String id, Map<String, dynamic> updateData) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;

    final sanitized = <String, dynamic>{...updateData}
      ..remove('_id')
      ..['updatedAt'] = DateTime.now();

    await _collection.updateOne(
      where.id(objId),
      modify.set('updatedAt', DateTime.now()),
    );

    for (final entry in sanitized.entries) {
      await _collection.updateOne(
        where.id(objId),
        modify.set(entry.key, entry.value),
      );
    }

    return findById(id);
  }

  Future<bool> delete(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return false;
    final result = await _collection.deleteOne(where.id(objId));
    return result.isSuccess;
  }
}
