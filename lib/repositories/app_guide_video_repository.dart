import 'package:mongo_dart/mongo_dart.dart';
import '../core/db/mongo_client.dart';
import '../models/app_guide_video.dart';
import '../models/model_helpers.dart';

/// Repository for AppGuideVideo collection operations.
class AppGuideVideoRepository {
  AppGuideVideoRepository({MongoClient? mongoClient})
      : _mongoClient = mongoClient ?? MongoClient.instance;

  final MongoClient _mongoClient;

  static AppGuideVideoRepository? _instance;
  static AppGuideVideoRepository get instance => _instance ??= AppGuideVideoRepository();

  DbCollection get _collection => _mongoClient.collection('appguidevideos');

  Future<AppGuideVideo?> findVisible() async {
    final doc = await _collection.findOne(
      where.eq('visibility', true).sortBy('createdAt', descending: true),
    );
    if (doc == null) return null;
    return AppGuideVideo.fromBson(doc);
  }

  Future<List<AppGuideVideo>> findAll() async {
    final cursor = _collection.find(where.sortBy('createdAt', descending: true));
    final list = await cursor.toList();
    return list.map(AppGuideVideo.fromBson).toList();
  }

  Future<AppGuideVideo?> findById(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;
    final doc = await _collection.findOne(where.id(objId));
    if (doc == null) return null;
    return AppGuideVideo.fromBson(doc);
  }

  Future<AppGuideVideo> create(AppGuideVideo video) async {
    final doc = video.toBson();
    doc['createdAt'] = DateTime.now();
    doc['updatedAt'] = DateTime.now();
    final result = await _collection.insertOne(doc);
    return AppGuideVideo.fromBson({...doc, '_id': result.id});
  }

  Future<AppGuideVideo?> update(String id, Map<String, dynamic> updateData) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;

    final sanitized = <String, dynamic>{...updateData}
      ..remove('_id')
      ..['updatedAt'] = DateTime.now();

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
