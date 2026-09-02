import 'package:mongo_dart/mongo_dart.dart';

/// Helper utilities for JSON and BSON serialization across all models.
class ModelHelpers {
  /// Converts any ID representation (ObjectId, String, Map) to a standard 24-hex string.
  static String? idToString(dynamic id) {
    if (id == null) return null;
    if (id is ObjectId) return id.toHexString();
    if (id is String) {
      if (id.isEmpty) return null;
      if (id.startsWith('ObjectId("') && id.endsWith('")')) {
        return id.substring(10, id.length - 2);
      }
      return id;
    }
    if (id is Map && id.containsKey(r'$oid')) {
      return id[r'$oid']?.toString();
    }
    return id.toString();
  }

  /// Converts a hex string or ObjectId into a mongo_dart ObjectId.
  static ObjectId? toObjectId(dynamic id) {
    if (id == null) return null;
    if (id is ObjectId) return id;
    if (id is String) {
      if (id.length != 24) return null;
      try {
        return ObjectId.fromHexString(id);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Parses date values from DateTime, ISO string, or milliseconds timestamp.
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    if (value is Map && value.containsKey(r'$date')) {
      final dateVal = value[r'$date'];
      if (dateVal is int) return DateTime.fromMillisecondsSinceEpoch(dateVal);
      if (dateVal is String) return DateTime.tryParse(dateVal);
    }
    return null;
  }

  /// Converts DateTime to standard ISO-8601 string matching JavaScript toISOString().
  static String? toIsoString(DateTime? dt) {
    return dt?.toUtc().toIso8601String();
  }

  /// Safely parse numbers (int, double, string) to double
  static double? parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String && val.isNotEmpty) return double.tryParse(val);
    return null;
  }

  /// Safely parse numbers (int, double, string) to int
  static int? parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String && val.isNotEmpty) return int.tryParse(val);
    return null;
  }

  /// Safely parse boolean values
  static bool parseBool(dynamic val, {bool defaultValue = false}) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final s = val.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return defaultValue;
  }

  /// Safely parse string list
  static List<String> parseStringList(dynamic list) {
    if (list == null) return [];
    if (list is List) {
      return list
          .map((e) => idToString(e) ?? e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (list is String && list.isNotEmpty) {
      final s = idToString(list) ?? list;
      return [s];
    }
    return [];
  }
}
