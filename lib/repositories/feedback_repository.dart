import 'package:mongo_dart/mongo_dart.dart';
import '../core/db/mongo_client.dart';
import '../models/feature_request.dart';
import '../models/model_helpers.dart';

/// Repository for FeatureRequest / Feedback collection operations.
class FeedbackRepository {
  FeedbackRepository({MongoClient? mongoClient})
      : _mongoClient = mongoClient ?? MongoClient.instance;

  final MongoClient _mongoClient;

  static FeedbackRepository? _instance;
  static FeedbackRepository get instance => _instance ??= FeedbackRepository();

  DbCollection get _collection => _mongoClient.collection('featurerequests');

  Future<FeatureRequest> create(FeatureRequest request) async {
    final doc = request.toBson();
    doc['createdAt'] = DateTime.now();
    doc['updatedAt'] = DateTime.now();
    final result = await _collection.insertOne(doc);
    return FeatureRequest.fromBson({...doc, '_id': result.id});
  }

  Future<List<FeatureRequest>> findAll() async {
    final cursor = _collection.find(where.sortBy('createdAt', descending: true));
    final list = await cursor.toList();
    return list.map(FeatureRequest.fromBson).toList();
  }

  Future<FeatureRequest?> findById(String id) async {
    final objId = ModelHelpers.toObjectId(id);
    if (objId == null) return null;
    final doc = await _collection.findOne(where.id(objId));
    if (doc == null) return null;
    return FeatureRequest.fromBson(doc);
  }

  Future<FeatureRequest?> update(String id, Map<String, dynamic> updateData) async {
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
