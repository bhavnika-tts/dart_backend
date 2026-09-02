import 'package:mongo_dart/mongo_dart.dart';
import '../core/db/mongo_client.dart';
import '../models/chat.dart';
import '../models/conversation.dart';
import '../models/model_helpers.dart';
import '../models/product.dart';
import '../models/user.dart';

/// Repository handling MongoDB operations for Conversations and Messages.
class ChatRepository {
  ChatRepository({MongoClient? mongoClient})
      : _mongoClient = mongoClient ?? MongoClient.instance;

  final MongoClient _mongoClient;

  static ChatRepository? _instance;
  static ChatRepository get instance => _instance ??= ChatRepository();

  DbCollection get _conversationsCollection => _mongoClient.collection('conversations');
  DbCollection get _messagesCollection => _mongoClient.collection('chat_messages');
  DbCollection get _usersCollection => _mongoClient.collection('users');
  DbCollection get _productsCollection => _mongoClient.collection('products');

  /// Finds existing conversation between two users (and optionally for a product) or creates one.
  Future<Conversation> findOrCreateConversation({
    required String senderId,
    required String receiverId,
    String? productId,
  }) async {
    final senderObj = ModelHelpers.toObjectId(senderId);
    final receiverObj = ModelHelpers.toObjectId(receiverId);

    if (senderObj == null || receiverObj == null) {
      throw ArgumentError('Invalid sender or receiver ID');
    }

    var selector = where.all('participants', [senderObj, receiverObj]);
    if (productId != null && productId.isNotEmpty) {
      final prodObj = ModelHelpers.toObjectId(productId);
      if (prodObj != null) {
        selector = selector.eq('product', prodObj);
      }
    }

    final existing = await _conversationsCollection.findOne(selector);
    if (existing != null) {
      return Conversation.fromBson(existing);
    }

    final newConv = Conversation(
      participants: [senderId, receiverId],
      product: productId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final doc = newConv.toBson();
    final result = await _conversationsCollection.insertOne(doc);
    return Conversation.fromBson({...doc, '_id': result.id});
  }

  /// Finds a single conversation by ID.
  Future<Conversation?> findConversationById(String conversationId) async {
    final objId = ModelHelpers.toObjectId(conversationId);
    if (objId == null) return null;

    final doc = await _conversationsCollection.findOne(where.id(objId));
    if (doc == null) return null;
    return Conversation.fromBson(doc);
  }

  /// Retrieves full inbox conversations for user with populated recipient and product cards.
  Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    final userObj = ModelHelpers.toObjectId(userId);
    if (userObj == null) return [];

    final stream = _conversationsCollection.find(
      where.oneFrom('participants', [userObj]).nin('deletedBy', [userObj]).sortBy('updatedAt', descending: true),
    );

    final convDocs = await stream.toList();
    final result = <Map<String, dynamic>>[];

    for (final doc in convDocs) {
      final conv = Conversation.fromBson(doc);
      final otherUserId = conv.participants.firstWhere(
        (id) => id != userId,
        orElse: () => userId,
      );

      // Populate other user
      Map<String, dynamic>? otherUserMap;
      final otherUserObj = ModelHelpers.toObjectId(otherUserId);
      if (otherUserObj != null) {
        final uDoc = await _usersCollection.findOne(where.id(otherUserObj));
        if (uDoc != null) {
          final u = User.fromBson(uDoc);
          otherUserMap = {
            'userId': u.id,
            '_id': u.id,
            'fName': u.fName,
            'lName': u.lName,
            'profileImage': u.profileImage,
          };
        }
      }

      // Populate product if attached
      Map<String, dynamic>? productMap;
      final prodId = conv.product;
      if (prodId != null && prodId.isNotEmpty) {
        final prodObj = ModelHelpers.toObjectId(prodId);
        if (prodObj != null) {
          final pDoc = await _productsCollection.findOne(where.id(prodObj));
          if (pDoc != null) {
            final p = Product.fromBson(pDoc);
            productMap = {
              'productId': p.id,
              '_id': p.id,
              'title': p.title,
              'price': p.price,
              'images': p.images,
            };
          }
        }
      }

      // Get last message
      final convId = conv.id;
      final convObj = convId != null ? ModelHelpers.toObjectId(convId) : null;
      ChatMessage? lastMsg;
      if (convObj != null) {
        final lastDoc = await _messagesCollection.findOne(
          where.eq('chatId', convObj).sortBy('createdAt', descending: true),
        );
        if (lastDoc != null) {
          lastMsg = ChatMessage.fromBson(lastDoc);
        }
      }

      // Count unread messages
      var unreadCount = 0;
      if (convObj != null) {
        unreadCount = await _messagesCollection.count(
          where.eq('chatId', convObj).ne('senderId', userObj).ne('status', 'read'),
        );
      }

      result.add({
        ...conv.toJson(),
        'otherUser': otherUserMap,
        'productDetails': productMap,
        'lastMessage': lastMsg?.toJson(),
        'unreadCount': unreadCount,
      });
    }

    return result;
  }

  /// Retrieves messages history for a conversation.
  Future<List<ChatMessage>> getMessages(String conversationId, {String? userId, int limit = 100}) async {
    final convObj = ModelHelpers.toObjectId(conversationId);
    if (convObj == null) return [];

    var selector = where.eq('chatId', convObj);
    if (userId != null) {
      final uObj = ModelHelpers.toObjectId(userId);
      if (uObj != null) {
        selector = selector.nin('deletedBy', [uObj]);
      }
    }

    selector = selector.sortBy('createdAt', descending: false).limit(limit);
    final stream = _messagesCollection.find(selector);
    final list = await stream.toList();
    return list.map(ChatMessage.fromBson).toList();
  }

  /// Creates a new chat message and touches conversation updatedAt.
  Future<ChatMessage> createMessage(ChatMessage message) async {
    final doc = message.toBson();
    doc['createdAt'] = DateTime.now();
    doc['updatedAt'] = DateTime.now();

    final result = await _messagesCollection.insertOne(doc);

    // Touch conversation
    final convObj = ModelHelpers.toObjectId(message.chatId);
    if (convObj != null) {
      await _conversationsCollection.updateOne(
        where.id(convObj),
        modify.set('updatedAt', DateTime.now()),
      );
    }

    return ChatMessage.fromBson({...doc, '_id': result.id});
  }

  /// Marks unread messages in conversation as read.
  Future<int> markMessagesRead(String conversationId, String readByUserId) async {
    final convObj = ModelHelpers.toObjectId(conversationId);
    final userObj = ModelHelpers.toObjectId(readByUserId);
    if (convObj == null || userObj == null) return 0;

    final result = await _messagesCollection.updateMany(
      where.eq('chatId', convObj).ne('senderId', userObj).ne('status', 'read'),
      modify.set('status', 'read').set('updatedAt', DateTime.now()),
    );

    return result.nModified;
  }

  /// Updates status for a single message.
  Future<void> updateMessageStatus(String messageId, String status) async {
    final msgObj = ModelHelpers.toObjectId(messageId);
    if (msgObj == null) return;

    await _messagesCollection.updateOne(
      where.id(msgObj),
      modify.set('status', status).set('updatedAt', DateTime.now()),
    );
  }

  /// Counts total unread messages across all conversations for user.
  Future<int> getUnreadCount(String userId) async {
    final userObj = ModelHelpers.toObjectId(userId);
    if (userObj == null) return 0;

    final convStream = _conversationsCollection.find(
      where.oneFrom('participants', [userObj]).nin('deletedBy', [userObj]),
    );
    final convs = await convStream.toList();
    final convIds = convs.map((c) => c['_id'] as ObjectId).toList();

    if (convIds.isEmpty) return 0;

    return _messagesCollection.count(
      where.oneFrom('chatId', convIds).ne('senderId', userObj).ne('status', 'read'),
    );
  }

  /// Soft deletes a conversation for user.
  Future<bool> deleteConversationForUser(String conversationId, String userId) async {
    final convObj = ModelHelpers.toObjectId(conversationId);
    final userObj = ModelHelpers.toObjectId(userId);
    if (convObj == null || userObj == null) return false;

    final result = await _conversationsCollection.updateOne(
      where.id(convObj),
      modify.addToSet('deletedBy', userObj),
    );
    return result.nModified > 0;
  }

  /// Soft deletes a single message for user.
  Future<bool> deleteMessage(String messageId, String userId) async {
    final msgObj = ModelHelpers.toObjectId(messageId);
    final userObj = ModelHelpers.toObjectId(userId);
    if (msgObj == null || userObj == null) return false;

    final result = await _messagesCollection.updateOne(
      where.id(msgObj),
      modify.addToSet('deletedBy', userObj),
    );
    return result.nModified > 0;
  }
}
