import 'dart:typed_data';
import '../models/chat.dart';
import '../models/conversation.dart';
import '../repositories/chat_repository.dart';
import '../repositories/user_repository.dart';
import 'fcm_service.dart';
import 'imagekit_service.dart';
import 'socket_service.dart';

/// Business logic service for Real-time Chat, Inbox, Message History, and Push Notifications.
class ChatService {
  ChatService({
    ChatRepository? chatRepository,
    UserRepository? userRepository,
    ImageKitService? imageKitService,
    SocketService? socketService,
    FcmService? fcmService,
  })  : _chatRepo = chatRepository ?? ChatRepository.instance,
        _userRepo = userRepository ?? UserRepository.instance,
        _imageKit = imageKitService ?? ImageKitService.instance,
        _socket = socketService ?? SocketService.instance,
        _fcm = fcmService ?? FcmService.instance;

  final ChatRepository _chatRepo;
  final UserRepository _userRepo;
  final ImageKitService _imageKit;
  final SocketService _socket;
  final FcmService _fcm;

  static ChatService? _instance;
  static ChatService get instance => _instance ??= ChatService();

  /// Gets existing or creates new conversation ID between two users.
  Future<Conversation> fetchConversationId({
    required String senderId,
    required String receiverId,
    String? productId,
  }) async {
    return _chatRepo.findOrCreateConversation(
      senderId: senderId,
      receiverId: receiverId,
      productId: productId,
    );
  }

  /// Sends a text message, emits socket events, and sends FCM notification if recipient is offline.
  Future<Map<String, dynamic>> sendMessage({
    required String senderId,
    required String receiverId,
    required String conversationId,
    required String text,
    String type = 'text',
    String? productId,
  }) async {
    if (text.trim().isEmpty) {
      throw ArgumentError('Message text cannot be empty');
    }

    final message = ChatMessage(
      chatId: conversationId,
      senderId: senderId,
      productId: productId,
      type: type,
      content: text.trim(),
      status: 'sent',
    );

    final created = await _chatRepo.createMessage(message);
    final msgJson = _imageKit.signImageKitUrls(created.toJson()) as Map<String, dynamic>;

    // Real-time socket emission to recipient and conversation room
    _socket
      ..emitToUser(receiverId, 'new_message', msgJson)
      ..emitToRoom(conversationId, 'new_message', msgJson)
      ..emitToUser(senderId, 'message_sent', msgJson);

    // FCM Notification fallback if recipient is offline
    if (!_socket.isUserOnline(receiverId)) {
      final sender = await _userRepo.findById(senderId);
      final receiver = await _userRepo.findById(receiverId);

      if (receiver != null && receiver.deviceToken.isNotEmpty) {
        final senderName = sender != null && sender.fName.isNotEmpty
            ? '${sender.fName.first} ${sender.lName.isNotEmpty ? sender.lName.first : ''}'.trim()
            : 'New Message';

        await _fcm.sendToDevice(
          deviceToken: receiver.deviceToken,
          title: senderName,
          body: text,
          data: {
            'type': 'chat',
            'conversationId': conversationId,
            'senderId': senderId,
          },
        );
      }
    }

    return {
      'message': 'Message sent successfully',
      'data': msgJson,
    };
  }

  /// Uploads image to ImageKit and sends image message.
  Future<Map<String, dynamic>> sendImageMessage({
    required String senderId,
    required String receiverId,
    required String conversationId,
    required Uint8List imageBytes,
    required String fileName,
    String? productId,
  }) async {
    if (imageBytes.isEmpty) {
      throw ArgumentError('Image file is empty');
    }

    final imageUrl = await _imageKit.uploadBytes(
      bytes: imageBytes,
      fileName: fileName,
      folder: '/chatImages',
      prefix: 'chat',
    );

    final message = ChatMessage(
      chatId: conversationId,
      senderId: senderId,
      productId: productId,
      type: 'image',
      content: imageUrl,
      status: 'sent',
    );

    final created = await _chatRepo.createMessage(message);
    final msgJson = _imageKit.signImageKitUrls(created.toJson()) as Map<String, dynamic>;

    // Real-time socket emission
    _socket
      ..emitToUser(receiverId, 'new_message', msgJson)
      ..emitToRoom(conversationId, 'new_message', msgJson)
      ..emitToUser(senderId, 'message_sent', msgJson);

    // FCM Notification
    if (!_socket.isUserOnline(receiverId)) {
      final sender = await _userRepo.findById(senderId);
      final receiver = await _userRepo.findById(receiverId);

      if (receiver != null && receiver.deviceToken.isNotEmpty) {
        final senderName = sender != null && sender.fName.isNotEmpty
            ? '${sender.fName.first} ${sender.lName.isNotEmpty ? sender.lName.first : ''}'.trim()
            : 'New Message';

        await _fcm.sendToDevice(
          deviceToken: receiver.deviceToken,
          title: senderName,
          body: '📷 Sent a photo',
          data: {
            'type': 'chat',
            'conversationId': conversationId,
            'senderId': senderId,
          },
        );
      }
    }

    return {
      'message': 'Image message sent successfully',
      'data': msgJson,
    };
  }

  /// Retrieves all messages in a conversation with signed ImageKit URLs.
  Future<List<Map<String, dynamic>>> getAllMessages(String conversationId, {String? userId}) async {
    final messages = await _chatRepo.getMessages(conversationId, userId: userId);
    final list = messages.map((m) => m.toJson()).toList();
    return List<Map<String, dynamic>>.from(_imageKit.signImageKitUrls(list) as List);
  }

  /// Retrieves user's inbox conversations with signed URLs.
  Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    final list = await _chatRepo.getUserConversations(userId);
    return List<Map<String, dynamic>>.from(_imageKit.signImageKitUrls(list) as List);
  }

  /// Marks all unread messages as read and emits real-time event.
  Future<void> updateAllMessagesStatus(String conversationId, String userId) async {
    final modified = await _chatRepo.markMessagesRead(conversationId, userId);
    if (modified > 0) {
      _socket.emitToRoom(conversationId, 'messages_read', {
        'chatId': conversationId,
        'readByUserId': userId,
      });
    }
  }

  /// Gets total unread message count for a user.
  Future<int> getUnreadMessageCount(String userId) async {
    return _chatRepo.getUnreadCount(userId);
  }

  /// Soft deletes a conversation for user.
  Future<void> deleteConversation(String conversationId, String userId) async {
    await _chatRepo.deleteConversationForUser(conversationId, userId);
  }

  /// Soft deletes a message for user.
  Future<void> deleteMessage(String messageId, String userId) async {
    await _chatRepo.deleteMessage(messageId, userId);
  }
}
