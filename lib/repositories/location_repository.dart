import '../core/db/mongo_client.dart';

/// Repository for Location aggregation and pincode lookups.
class LocationRepository {
  LocationRepository({MongoClient? mongoClient})
      : _mongoClient = mongoClient ?? MongoClient.instance;

  final MongoClient _mongoClient;

  static LocationRepository? _instance;
  static LocationRepository get instance => _instance ??= LocationRepository();

  /// Fetches unique states, districts, and location names across active products.
  Future<Map<String, dynamic>> getUniqueLocations() async {
    try {
      final collection = _mongoClient.collection('products');
      final pipeline = [
        {
          r'$project': {
            'state': r'$location.state',
            'district': r'$location.district',
            'locationName': r'$location.locationName',
          },
        },
        {r'$unwind': r'$state'},
        {r'$unwind': r'$district'},
        {r'$unwind': r'$locationName'},
        {
          r'$group': {
            '_id': null,
            'states': {r'$addToSet': r'$state'},
            'districts': {r'$addToSet': r'$district'},
            'locationNames': {r'$addToSet': r'$locationName'},
          },
        },
      ];

      final results = await collection.aggregateToStream(pipeline).toList();
      if (results.isNotEmpty) {
        final doc = results.first;
        return {
          'states': doc['states'] as List? ?? [],
          'districts': doc['districts'] as List? ?? [],
          'locationNames': doc['locationNames'] as List? ?? [],
        };
      }
    } catch (_) {
      // Fallback
    }

    return {
      'states': <String>[],
      'districts': <String>[],
      'locationNames': <String>[],
    };
  }

  /// Searches location entries by query (pincode, location name, district, or state).
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    try {
      final collection = _mongoClient.collection('locations');
      final regex = RegExp(query, caseSensitive: false);
      final stream = collection.find({
        r'$or': [
          {'Postal_Code': {r'$regex': regex.pattern, r'$options': 'i'}},
          {'Location_Name': {r'$regex': regex.pattern, r'$options': 'i'}},
          {'District': {r'$regex': regex.pattern, r'$options': 'i'}},
          {'State': {r'$regex': regex.pattern, r'$options': 'i'}},
        ],
      }).take(50);

      final results = await stream.toList();
      return results.map(Map<String, dynamic>.from).toList();
    } catch (_) {
      return [];
    }
  }
}
