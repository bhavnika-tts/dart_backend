import 'package:dart_frog_backend/models/model_helpers.dart';
import 'package:mongo_dart/mongo_dart.dart';

dynamic sanitizeMongoData(dynamic value) {
  if (value is DateTime) {
    return value.toIso8601String();
  }
  if (value is ObjectId) {
    return ModelHelpers.idToString(value);
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), sanitizeMongoData(v)));
  }
  if (value is List) {
    return value.map(sanitizeMongoData).toList();
  }
  return value;
}
