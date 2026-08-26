import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/shared/models/booking.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _bookingsCollection =
      FirebaseFirestore.instance.collection('bookings');

  Future<String> createBooking(Booking booking) async {
    final docRef = _bookingsCollection.doc();
    final newBooking = booking.copyWith(id: docRef.id);
    await docRef.set(newBooking.toMap());
    return docRef.id;
  }

  Future<Booking?> getBooking(String id) async {
    final doc = await _bookingsCollection.doc(id).get();
    if (!doc.exists) return null;
    return Booking.fromFirestore(doc);
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
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }

  Future<List<Booking>> getNurseBookings(String nurseId) async {
    final snapshot = await _bookingsCollection
        .where('nurseId', isEqualTo: nurseId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }

  Future<void> checkInShift(String bookingId) async {
    await _bookingsCollection.doc(bookingId).update({
      'status': 'in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Also update attendance sub-collection if needed
  }

  Future<void> checkOutShift(String bookingId) async {
    await _bookingsCollection.doc(bookingId).update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

extension BookingCopyWith on Booking {
  Booking copyWith({String? id}) {
    return Booking(
      id: id ?? this.id,
      clientId: clientId,
      nurseId: nurseId,
      careRequestId: careRequestId,
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      shiftHours: shiftHours,
      pricePerHour: pricePerHour,
      platformFee: platformFee,
      totalAmount: totalAmount,
      status: status,
      paymentStatus: paymentStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
