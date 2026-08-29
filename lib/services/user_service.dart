import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/shared/models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<AppUser?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<void> createUser(AppUser user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).update(data);
  }

  // For Splash: Fetch user role safely
  Future<String?> getUserRole(String uid) async {
    final user = await getUser(uid);
    return user?.role;
  }

  /// Fetches multiple users by uid in as few reads as possible.
  /// Used by the chat/messages screens to resolve the other side's
  /// display name (client sees the nurse's name, nurse sees the client's).
  Future<Map<String, AppUser>> getUsersByIds(Iterable<String> uids) async {
    final ids = uids.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};
    final result = <String, AppUser>{};
    // Firestore whereIn supports up to 30 values per query.
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        result[doc.id] = AppUser.fromFirestore(doc);
      }
    }
    return result;
  }
}
