import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/shared/models/message.dart';
import 'notification_service.dart';

/// Page size for the live message window in a chat, and for "load older
/// messages" pagination. Kept small on purpose: a chat can grow to
/// thousands of messages over time, so we never listen to or fetch more
/// than one page's worth at once.
const int kChatMessagePageSize = 30;

/// Number of conversations fetched per page in the inbox (messages list).
const int kChatListPageSize = 20;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getOrCreateChat(
      String bookingId, String clientId, String nurseId) async {
    // Check if chat exists
    final existing = await _firestore
        .collection('chats')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    // Create new chat
    final docRef = _firestore.collection('chats').doc();
    await docRef.set({
      'id': docRef.id,
      'bookingId': bookingId,
      'clientId': clientId,
      'nurseId': nurseId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // Cached unread counters per side, so the inbox can show a badge
      // without ever having to count messages.
      'unreadForClient': 0,
      'unreadForNurse': 0,
    });
    return docRef.id;
  }

  Future<void> sendMessage(
      String chatId, String senderId, String receiverId, String text) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();
    final message = Message(
      id: msgRef.id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: DateTime.now(),
    );

    final chatSnap = await chatRef.get();
    final chatData = chatSnap.data();
    final receiverIsClient = chatData?['clientId'] == receiverId;
    final unreadField = receiverIsClient ? 'unreadForClient' : 'unreadForNurse';

    final batch = _firestore.batch();
    batch.set(msgRef, message.toMap());
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      unreadField: FieldValue.increment(1),
    });
    await batch.commit();

    // The message is already safely stored in Firestore. A notification
    // failure must never make the chat message appear to have failed.
    try {
      await NotificationService.sendChatNotification(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
      );
    } catch (_) {
      // Ignore notification failures; Firestore remains the source of truth.
    }
  }

  /// Streams only the most recent [kChatMessagePageSize] messages, newest
  /// first. This is the live window shown at the bottom of the chat — it
  /// never grows unbounded, so opening an old, very long conversation stays
  /// fast and cheap regardless of its total history.
  Stream<List<Message>> getRecentMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(kChatMessagePageSize)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  /// Fetches one page of older messages, strictly before [before] (the
  /// oldest message currently loaded). Used for "load older messages" —
  /// a one-time fetch, not a live listener, so scrolling back through a
  /// huge history never opens more Firestore listeners.
  Future<List<Message>> getOlderMessages(
    String chatId, {
    required DateTime before,
    int limit = kChatMessagePageSize,
  }) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(before)])
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
  }

  /// Marks all unseen messages addressed to [userId] as seen, and clears
  /// that side's unread counter — in a single batch instead of one write
  /// per message, so a long backlog of unread messages costs one round
  /// trip, not dozens.
  Future<void> markMessagesAsSeen(String chatId, String userId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messages = await chatRef
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('seen', isEqualTo: false)
        .limit(200)
        .get();

    if (messages.docs.isEmpty) return;

    final chatSnap = await chatRef.get();
    final isClient = chatSnap.data()?['clientId'] == userId;
    final unreadField = isClient ? 'unreadForClient' : 'unreadForNurse';

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.update(doc.reference, {'seen': true});
    }
    batch.update(chatRef, {unreadField: 0});
    await batch.commit();
  }

  /// One page of a user's conversations, most recently updated first.
  /// [startAfter] is the last document from the previous page, for
  /// "load more" pagination instead of ever fetching the whole inbox.
  Future<QuerySnapshot<Map<String, dynamic>>> getChatsPage({
    required String fieldName, // 'clientId' or 'nurseId'
    required String userId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = kChatListPageSize,
  }) {
    var query = _firestore
        .collection('chats')
        .where(fieldName, isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }
}
