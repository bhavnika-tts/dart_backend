import 'package:dart_frog_backend/models/chat.dart';
import 'package:dart_frog_backend/models/conversation.dart';
import 'package:dart_frog_backend/services/socket_service.dart';
import 'package:test/test.dart';

void main() {
  group('Chat & WebSocket Hub', () {
    test('ChatMessage correctly serializes content and metadata', () {
      final msg = ChatMessage(
        chatId: '507f1f77bcf86cd799439011',
        senderId: '507f1f77bcf86cd799439022',
        productId: '507f1f77bcf86cd799439033',
        content: 'Is this car still available?',
        metaData: ChatMetadata(
          clientMessageId: 'temp_uuid_123',
        ),
      );

      final json = msg.toJson();
      expect(json['content'], equals('Is this car still available?'));
      expect(json['metaData']['clientMessageId'], equals('temp_uuid_123'));
      expect(json['status'], equals('sent'));
    });

    test('Conversation preserves participants list and product linkage', () {
      final conv = Conversation(
        participants: ['user1', 'user2'],
        product: 'prod123',
      );

      final json = conv.toJson();
      expect(json['participants'], equals(['user1', 'user2']));
      expect(json['product'], equals('prod123'));
    });

    test('SocketService presence tracking', () {
      final socketService = SocketService.instance;
      expect(socketService.isUserOnline('unknown_user_999'), isFalse);
    });
  });
}
