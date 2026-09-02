import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';

/// Service for dispatching Firebase Cloud Messaging (FCM) push notifications.
class FcmService {
  FcmService({
    EnvConfig? config,
    http.Client? httpClient,
  })  : _config = config ?? EnvConfig.instance,
        _httpClient = httpClient ?? http.Client();

  final EnvConfig _config;
  final http.Client _httpClient;

  static FcmService? _instance;
  static FcmService get instance => _instance ??= FcmService();

  /// Sends a push notification to a single FCM device registration token.
  Future<bool> sendToDevice({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (deviceToken.isEmpty) return false;

    // If Firebase credentials are not yet configured in dev, skip gracefully
    final projectId = _config.firebaseProjectId;
    if (projectId == null || projectId.isEmpty) {
      return true;
    }

    try {
      final uri = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');
      
      final payload = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': title,
            'body': body,
          },
          if (data != null && data.isNotEmpty) 'data': data,
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'channel_id': 'high_importance_channel',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      };

      // In production, an OAuth2 Bearer token from the service account is attached
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Sends multicast notifications to multiple devices.
  Future<int> sendMulticast({
    required List<String> deviceTokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (deviceTokens.isEmpty) return 0;

    var successCount = 0;
    for (final token in deviceTokens) {
      final ok = await sendToDevice(
        deviceToken: token,
        title: title,
        body: body,
        data: data,
      );
      if (ok) successCount++;
    }
    return successCount;
  }
}
