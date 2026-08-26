import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/shared/models/message.dart';

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
    });
    return docRef.id;
  }

  Future<void> sendMessage(
      String chatId, String senderId, String receiverId, String text) async {
    final msgRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();
    final message = Message(
      id: msgRef.id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: DateTime.now(),
    );
    await msgRef.set(message.toMap());
    // Update chat last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  Future<void> markMessagesAsSeen(String chatId, String userId) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('seen', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({'seen': true});
    }
  }
}
