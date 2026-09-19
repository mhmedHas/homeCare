import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/shared/models/booking.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> isAdmin([String? uid]) async {
    final id = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (id == null) return false;

    final doc = await _db.collection('admins').doc(id).get();
    return doc.exists && doc.data()?['active'] == true;
  }

  Future<List<Booking>> getPendingPayments() async {
    final snapshot = await _db
        .collection('bookings')
        .where('paymentStatus', isEqualTo: 'awaiting_verification')
        .limit(100)
        .get();

    final bookings = snapshot.docs.map(Booking.fromFirestore).toList();
    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  Future<bool> verifyPayment(String bookingId) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) {
      throw StateError('يجب تسجيل الدخول بحساب الإدارة.');
    }

    final bookingRef = _db.collection('bookings').doc(bookingId);

    return _db.runTransaction<bool>((tx) async {
      final bookingSnap = await tx.get(bookingRef);

      if (!bookingSnap.exists) {
        throw StateError('الحجز غير موجود.');
      }

      final data = bookingSnap.data() as Map<String, dynamic>;
      final nurseId = data['nurseId']?.toString() ?? '';
      if (nurseId.isEmpty) {
        throw StateError('بيانات الممرض غير مكتملة.');
      }

      final nurseBalanceRef = _db.collection('nurseBalances').doc(nurseId);
      final ledgerRef = _db.collection('nurseTransactions').doc(bookingId);

      final balanceSnap = await tx.get(nurseBalanceRef);
      final ledgerSnap = await tx.get(ledgerRef);

      if (data['paymentStatus'] == 'verified' || ledgerSnap.exists) {
        return false;
      }

      if (data['paymentStatus'] != 'awaiting_verification') {
        throw StateError('الحجز ليس في انتظار تأكيد الدفع.');
      }

      final nurseEarnings = _number(data['nurseEarnings']);
      if (nurseEarnings <= 0) {
        throw StateError('صافي الممرض غير صالح.');
      }

      final balanceData = balanceSnap.data() ?? <String, dynamic>{};
      final currentBalance = _number(balanceData['balance']);
      final newBalance = currentBalance + nurseEarnings;

      tx.update(bookingRef, {
        'paymentStatus': 'verified',
        'status': 'completed',
        'paymentVerifiedAt': FieldValue.serverTimestamp(),
        'paymentVerifiedBy': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        nurseBalanceRef,
        {
          'nurseId': nurseId,
          'balance': newBalance,
          'lastBookingId': bookingId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.set(ledgerRef, {
        'bookingId': bookingId,
        'nurseId': nurseId,
        'amount': nurseEarnings,
        'type': 'earning',
        'paymentStatus': 'verified',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': adminUid,
      });

      return true;
    });
  }

  Future<void> rejectPayment({
    required String bookingId,
    String? reason,
  }) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) {
      throw StateError('يجب تسجيل الدخول بحساب الإدارة.');
    }

    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) {
        throw StateError('الحجز غير موجود.');
      }

      final data = bookingSnap.data() as Map<String, dynamic>;
      if (data['paymentStatus'] != 'awaiting_verification') {
        throw StateError('الحجز ليس في انتظار تأكيد الدفع.');
      }

      tx.update(bookingRef, {
        'paymentStatus': 'rejected',
        'paymentRejectedAt': FieldValue.serverTimestamp(),
        'paymentRejectedBy': adminUid,
        'paymentRejectionReason':
            reason?.trim().isEmpty == true ? null : reason?.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
