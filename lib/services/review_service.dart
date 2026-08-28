import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/shared/models/review.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> submitReview({
    required String bookingId,
    required String clientId,
    required String nurseId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) throw ArgumentError('rating');
    final reviewRef = _db.collection('reviews').doc(bookingId);
    final profileRef = _db.collection('nurseProfiles').doc(nurseId);
    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) throw StateError('الحجز غير موجود');
      final booking = bookingSnap.data() as Map<String, dynamic>;
      if (booking['clientId'] != clientId || booking['nurseId'] != nurseId) {
        throw StateError('غير مسموح بتقييم هذا الحجز');
      }
      if (booking['status'] != 'completed') {
        throw StateError('يمكن التقييم بعد انتهاء الرعاية');
      }
      final existing = await tx.get(reviewRef);
      if (existing.exists) throw StateError('تم تقييم هذا الحجز بالفعل');

      tx.set(reviewRef, {
        'bookingId': bookingId,
        'clientId': clientId,
        'nurseId': nurseId,
        'rating': rating,
        'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final profileSnap = await tx.get(profileRef);
      final data = profileSnap.data() ?? <String, dynamic>{};
      final oldCount = (data['totalReviews'] as num?)?.toInt() ?? 0;
      final oldAverage = (data['averageRating'] as num?)?.toDouble() ?? 0;
      final newCount = oldCount + 1;
      final newAverage = ((oldAverage * oldCount) + rating) / newCount;
      final distribution = Map<String, dynamic>.from(
        (data['ratingDistribution'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {},
      );
      distribution['$rating'] = ((distribution['$rating'] as num?)?.toInt() ?? 0) + 1;

      tx.set(profileRef, {
        'averageRating': double.parse(newAverage.toStringAsFixed(2)),
        'totalReviews': newCount,
        'ratingDistribution': distribution,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<List<Review>> getNurseReviews(String nurseId, {int limit = 20}) async {
    final snap = await _db.collection('reviews')
        .where('nurseId', isEqualTo: nurseId)
        .limit(limit)
        .get();
    final reviews = snap.docs.map(Review.fromFirestore).toList();
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }
}
