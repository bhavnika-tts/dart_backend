import 'dart:convert';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';

/// Hub managing real-time WebSocket connections, room subscriptions, presence, and event broadcasting.
class SocketService {
  static SocketService? _instance;
  static SocketService get instance => _instance ??= SocketService();

  // Socket channels mapped by socket ID
  final Map<String, WebSocketChannel> _sockets = {};

  // User rooms: userId -> Set of socket IDs
  final Map<String, Set<String>> _userSockets = {};

  // Custom rooms (e.g. conversationId, "admin", "admin-support"): roomName -> Set of socket IDs
  final Map<String, Set<String>> _roomMembers = {};

  // Socket ID -> userId
  final Map<String, String> _socketUsers = {};

  // Online users set
  final Set<String> _onlineUserIds = {};

  bool isUserOnline(String userId) => _onlineUserIds.contains(userId);

  /// Registers a newly connected WebSocket client.
  void handleConnection(WebSocketChannel channel, {String? userId}) {
    final socketId = 'sock_${DateTime.now().microsecondsSinceEpoch}';
    _sockets[socketId] = channel;

    if (userId != null && userId.isNotEmpty) {
      _socketUsers[socketId] = userId;
      _userSockets.putIfAbsent(userId, () => {}).add(socketId);
      _onlineUserIds.add(userId);

      // Automatically join user's private notification room
      joinRoom(socketId, 'user-$userId');

      // Broadcast presence change
      broadcastEvent('user_status_change', {
        'userId': userId,
        'status': 'online',
        'lastSeen': DateTime.now().toIso8601String(),
      });
    }

    channel.stream.listen(
      (data) => _handleSocketMessage(socketId, data),
      onDone: () => _handleDisconnection(socketId),
      onError: (err) => _handleDisconnection(socketId),
    );
  }

  void _handleSocketMessage(String socketId, dynamic data) {
    try {
      final raw = data is String ? data : utf8.decode(data as List<int>);
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final event = payload['event']?.toString() ?? payload['type']?.toString();
      final body = payload['data'] ?? payload['body'] ?? payload;

      if (event == null) return;

      switch (event) {
        case 'joinRoom' || 'join_room':
          final room = body is Map ? body['conversationId']?.toString() : body.toString();
          if (room != null && room.isNotEmpty) {
            joinRoom(socketId, room);
            sendToSocket(socketId, 'joinRoom', {
              'message': 'User successfully registered to Room',
              'conversationId': room,
            });
          }

        case 'exitRoom' || 'leave_room':
          final room = body is Map ? body['conversationId']?.toString() : body.toString();
          if (room != null && room.isNotEmpty) {
            leaveRoom(socketId, room);
            sendToSocket(socketId, 'exitRoomSuccess', {
              'message': 'User successfully exited from Room',
            });
          }

        case 'typing':
          if (body is Map) {
            final chatId = body['chatId']?.toString() ?? '';
            final recipientId = body['recipientId']?.toString() ?? '';
            final userId = _socketUsers[socketId] ?? body['userId']?.toString() ?? '';
            if (recipientId.isNotEmpty) {
              emitToUser(recipientId, 'typing', {'chatId': chatId, 'userId': userId});
            }
          }

        case 'stop_typing':
          if (body is Map) {
            final chatId = body['chatId']?.toString() ?? '';
            final recipientId = body['recipientId']?.toString() ?? '';
            final userId = _socketUsers[socketId] ?? body['userId']?.toString() ?? '';
            if (recipientId.isNotEmpty) {
              emitToUser(recipientId, 'stop_typing', {'chatId': chatId, 'userId': userId});
            }
          }
      }
    } catch (_) {
      // Ignored non-json packet
    }
  }

  void _handleDisconnection(String socketId) {
    final channel = _sockets.remove(socketId);
    channel?.sink.close();

    final userId = _socketUsers.remove(socketId);
    if (userId != null) {
      final userSet = _userSockets[userId];
      userSet?.remove(socketId);
      if (userSet == null || userSet.isEmpty) {
        _userSockets.remove(userId);
        _onlineUserIds.remove(userId);

        broadcastEvent('user_status_change', {
          'userId': userId,
          'status': 'offline',
          'lastSeen': DateTime.now().toIso8601String(),
        });
      }
    }

    for (final room in _roomMembers.values) {
      room.remove(socketId);
    }
  }

  /// Adds a socket to a room.
  void joinRoom(String socketId, String roomName) {
    _roomMembers.putIfAbsent(roomName, () => {}).add(socketId);
  }

  /// Removes a socket from a room.
  void leaveRoom(String socketId, String roomName) {
    _roomMembers[roomName]?.remove(socketId);
  }

  /// Emits an event to all sockets in a room.
  void emitToRoom(String roomName, String event, dynamic data) {
    final members = _roomMembers[roomName];
    if (members == null || members.isEmpty) return;

    final message = jsonEncode({
      'event': event,
      'data': data,
      'room': roomName,
    });

    for (final socketId in members) {
      final sock = _sockets[socketId];
      sock?.sink.add(message);
    }
  }

  /// Emits an event to all connected sockets for a specific user.
  void emitToUser(String userId, String event, dynamic data) {
    emitToRoom('user-$userId', event, data);
  }

  /// Emits an event to admin channels.
  void emitToAdmin(String event, dynamic data) {
    emitToRoom('admin', event, data);
    emitToRoom('admin-support', event, data);
  }

  /// Sends direct event message to a specific socket ID.
  void sendToSocket(String socketId, String event, dynamic data) {
    final sock = _sockets[socketId];
    if (sock != null) {
      sock.sink.add(jsonEncode({
        'event': event,
        'data': data,
      }));
    }
  }

  /// Broadcasts an event to all connected clients.
  void broadcastEvent(String event, dynamic data) {
    final message = jsonEncode({
      'event': event,
      'data': data,
    });

    for (final sock in _sockets.values) {
      sock.sink.add(message);
    }
  }
}
