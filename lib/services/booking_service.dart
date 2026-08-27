import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/shared/models/booking.dart';

class BookingService {
  final CollectionReference _bookingsCollection = FirebaseFirestore.instance.collection('bookings');

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
    await _bookingsCollection.doc(bookingId).update({
      'status': 'in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> checkOutShift(String bookingId) async {
    await _bookingsCollection.doc(bookingId).update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
