import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/shared/models/booking.dart';

class BookingService {
  final CollectionReference<Map<String, dynamic>> _bookingsCollection =
      FirebaseFirestore.instance.collection('bookings');

  static const Set<String> activeStatuses = {
    'pending_payment',
    'confirmed',
    'in_progress',
  };

  Future<String> createBooking(Booking booking) async {
    if (booking.nurseId.trim().isEmpty) {
      throw StateError('بيانات الممرض غير مكتملة.');
    }
    if (booking.status != 'confirmed') {
      throw StateError('لا يمكن إنشاء حجز غير مؤكد.');
    }

    final docRef = _bookingsCollection.doc();
    final lockRef = FirebaseFirestore.instance
        .collection('nurseBookingLocks')
        .doc(booking.nurseId);
    final newBooking = booking.copyWith(id: docRef.id);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final lockSnap = await tx.get(lockRef);
      if (lockSnap.exists && lockSnap.data()?['active'] == true) {
        throw StateError('هذا الممرض لديه حجز نشط بالفعل.');
      }

      tx.set(docRef, newBooking.toMap());
      tx.set(lockRef, {
        'nurseId': booking.nurseId,
        'bookingId': docRef.id,
        'careRequestId': booking.careRequestId,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return docRef.id;
  }

  Future<String> createDirectBooking({
    required String clientId,
    required String nurseId,
    required DateTime shiftStart,
  }) async {
    final db = FirebaseFirestore.instance;
    final bookingRef = _bookingsCollection.doc();
    final profileRef = db.collection('nurseProfiles').doc(nurseId);
    final userRef = db.collection('users').doc(nurseId);
    final lockRef = db.collection('nurseBookingLocks').doc(nurseId);

    await db.runTransaction((tx) async {
      final profileSnap = await tx.get(profileRef);
      final userSnap = await tx.get(userRef);
      final lockSnap = await tx.get(lockRef);

      if (!profileSnap.exists || !userSnap.exists) {
        throw StateError('بيانات الممرض غير موجودة.');
      }

      final profile = profileSnap.data()!;
      final user = userSnap.data()!;

      if (user['role'] != 'nurse' ||
          user['isActive'] != true ||
          user['isVerified'] != true) {
        throw StateError('الممرض غير متاح للحجز المباشر.');
      }

      final shiftPrice =
          (profile['expectedPrice'] as num?)?.toDouble() ?? 0;
      final shiftHours =
          (profile['shiftHours'] as num?)?.toInt() ?? 12;

      if (shiftPrice <= 0 || ![6, 12, 24].contains(shiftHours)) {
        throw StateError('الممرض لم يحدد سعر الشيفت بشكل صحيح.');
      }

      if (shiftStart.isBefore(DateTime.now())) {
        throw StateError('اختار موعدًا قادمًا.');
      }

      if (lockSnap.exists && lockSnap.data()?['active'] == true) {
        throw StateError('الممرض لديه حجز نشط حاليًا.');
      }

      final platformFee = shiftPrice * 0.15;
      final nurseEarnings = shiftPrice - platformFee;

      tx.set(bookingRef, {
        'clientId': clientId,
        'nurseId': nurseId,
        'careRequestId': '',
        'bookingType': 'direct_nurse_hire',
        'shiftStart': Timestamp.fromDate(shiftStart),
        'shiftEnd': Timestamp.fromDate(
          shiftStart.add(Duration(hours: shiftHours)),
        ),
        'shiftHours': shiftHours,
        'pricePerHour': shiftPrice / shiftHours,
        'pricePerShift': shiftPrice,
        'platformFee': platformFee,
        'totalAmount': shiftPrice,
        'nurseEarnings': nurseEarnings,
        'status': 'confirmed',
        'paymentStatus': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(lockRef, {
        'nurseId': nurseId,
        'bookingId': bookingRef.id,
        'careRequestId': '',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return bookingRef.id;
  }

  Future<Booking?> getBooking(String id) async {
    final doc = await _bookingsCollection.doc(id).get();
    if (!doc.exists) return null;
    return Booking.fromFirestore(doc);
  }

  Future<void> submitPaymentForVerification({
    required String bookingId,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    await _bookingsCollection.doc(bookingId).update({
      'paymentStatus': 'awaiting_verification',
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference?.trim().isEmpty == true
          ? null
          : paymentReference?.trim(),
      'paymentSubmittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBookingStatus(String id, String status) async {
    await _bookingsCollection.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Booking>> getClientBookings(String clientId) async {
    final snapshot = await _bookingsCollection
        .where('clientId', isEqualTo: clientId)
        .limit(100)
        .get();
    final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  Future<List<Booking>> getNurseBookings(String nurseId) async {
    final snapshot = await _bookingsCollection
        .where('nurseId', isEqualTo: nurseId)
        .limit(100)
        .get();
    final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  Future<void> checkInShift(String bookingId) async {
    final bookingRef = _bookingsCollection.doc(bookingId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(bookingRef);
      if (!snap.exists) throw StateError('الحجز غير موجود.');

      final data = snap.data()!;
      if (data['status']?.toString() != 'confirmed') {
        throw StateError('لا يمكن تسجيل الحضور لهذا الحجز الآن.');
      }

      tx.update(bookingRef, {
        'status': 'in_progress',
        'checkInAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> cancelBookingAsNurse(String bookingId) async {
    final db = FirebaseFirestore.instance;
    final bookingRef = _bookingsCollection.doc(bookingId);

    final bookingBefore = await bookingRef.get();
    if (!bookingBefore.exists) throw StateError('الحجز غير موجود.');

    final bookingData = bookingBefore.data()!;
    final nurseId = bookingData['nurseId']?.toString() ?? '';
    final requestId = bookingData['careRequestId']?.toString() ?? '';
    final bookingType = bookingData['bookingType']?.toString() ?? '';

    if (nurseId.isEmpty) {
      throw StateError('بيانات الحجز غير مكتملة.');
    }

    final lockRef = db.collection('nurseBookingLocks').doc(nurseId);

    if (bookingType == 'direct_nurse_hire') {
      await db.runTransaction((tx) async {
        final bookingSnap = await tx.get(bookingRef);
        final lockSnap = await tx.get(lockRef);

        if (!bookingSnap.exists) {
          throw StateError('الحجز غير موجود.');
        }

        final data = bookingSnap.data()!;
        if (data['nurseId']?.toString() != nurseId) {
          throw StateError('الحجز لا يخص هذا الممرض.');
        }

        if (data['status']?.toString() != 'confirmed') {
          throw StateError('لا يمكن إلغاء الحجز بعد بدء الرعاية.');
        }

        if (!lockSnap.exists ||
            lockSnap.data()?['bookingId']?.toString() != bookingId ||
            lockSnap.data()?['active'] != true) {
          throw StateError(
            'حجز الممرض النشط غير متزامن. حدّث الصفحة وحاول مرة أخرى.',
          );
        }

        tx.update(bookingRef, {
          'status': 'cancelled',
          'cancelledBy': 'nurse',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.delete(lockRef);
      });
      return;
    }

    if (requestId.isEmpty) {
      throw StateError('بيانات الحجز غير مكتملة.');
    }

    final requestRef = db.collection('careRequests').doc(requestId);

    await db.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      final requestSnap = await tx.get(requestRef);
      final lockSnap = await tx.get(lockRef);

      if (!bookingSnap.exists || !requestSnap.exists) {
        throw StateError('الحجز أو طلب الرعاية غير موجود.');
      }

      final data = bookingSnap.data()!;
      if (data['nurseId']?.toString() != nurseId) {
        throw StateError('الحجز لا يخص هذا الممرض.');
      }
      if (data['status']?.toString() != 'confirmed') {
        throw StateError('لا يمكن إلغاء الحجز بعد بدء الرعاية.');
      }
      if (!lockSnap.exists ||
          lockSnap.data()?['bookingId']?.toString() != bookingId ||
          lockSnap.data()?['active'] != true) {
        throw StateError(
          'حجز الممرض النشط غير متزامن. حدّث الصفحة وحاول مرة أخرى.',
        );
      }

      final requestData = requestSnap.data()!;
      if (requestData['status']?.toString() != 'booked' ||
          requestData['selectedNurseId']?.toString() != nurseId) {
        throw StateError('طلب الرعاية لم يعد مرتبطًا بهذا الحجز.');
      }

      final selectedOfferId =
          data['offerId']?.toString().trim().isNotEmpty == true
              ? data['offerId'].toString()
              : requestData['selectedOfferId']?.toString() ?? '';

      tx.update(bookingRef, {
        'status': 'cancelled',
        'cancelledBy': 'nurse',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(requestRef, {
        'status': 'open',
        'selectedNurseId': null,
        'selectedOfferId': null,
        'reopenedFromBookingId': bookingId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (selectedOfferId.isNotEmpty) {
        tx.update(db.collection('careOffers').doc(selectedOfferId), {
          'status': 'cancelled',
          'reopenedFromBookingId': bookingId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      tx.delete(lockRef);
    });
  }
  Future<void> checkOutShift(String bookingId) async {
    final db = FirebaseFirestore.instance;
    final bookingRef = _bookingsCollection.doc(bookingId);

    await db.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) throw StateError('الحجز غير موجود.');

      final data = bookingSnap.data()!;
      final nurseId = data['nurseId']?.toString() ?? '';
      if (nurseId.isEmpty) throw StateError('بيانات الممرض غير مكتملة.');
      if (!['confirmed', 'in_progress'].contains(data['status']?.toString())) {
        throw StateError('الحجز ليس نشطًا.');
      }

      tx.update(bookingRef, {
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.delete(db.collection('nurseBookingLocks').doc(nurseId));
    });
  }
}
