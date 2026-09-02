import 'package:mongo_dart/mongo_dart.dart';
import '../core/db/mongo_client.dart';
import '../models/about_us.dart';

/// Repository for AboutUs collection queries and mutations.
class AboutUsRepository {
  AboutUsRepository({MongoClient? mongoClient})
      : _mongoClient = mongoClient ?? MongoClient.instance;

  final MongoClient _mongoClient;

  static AboutUsRepository? _instance;
  static AboutUsRepository get instance => _instance ??= AboutUsRepository();

  DbCollection get _collection => _mongoClient.collection('about_us');

  Future<AboutUs?> findAboutUs() async {
    final doc = await _collection.findOne();
    if (doc == null) return null;
    return AboutUs.fromBson(doc);
  }

  Future<AboutUs> createAboutUs(Map<String, dynamic> data) async {
    final aboutUs = AboutUs.fromBson(data);
    final doc = aboutUs.toBson();
    doc['createdAt'] = DateTime.now();
    doc['updatedAt'] = DateTime.now();

    final result = await _collection.insertOne(doc);
    return AboutUs.fromBson({...doc, '_id': result.id});
  }

  Future<AboutUs?> updateAboutUs(Map<String, dynamic> data) async {
    final existing = await _collection.findOne();
    if (existing == null) {
      return createAboutUs(data);
    }

    final sanitized = <String, dynamic>{...data}
      ..remove('_id')
      ..['updatedAt'] = DateTime.now();

    for (final entry in sanitized.entries) {
      await _collection.updateOne(
        where.eq('_id', existing['_id']),
        modify.set(entry.key, entry.value),
      );
    }

    return findAboutUs();
  }
}
