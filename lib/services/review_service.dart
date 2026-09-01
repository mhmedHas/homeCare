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
    if (rating < 1 || rating > 5) {
      throw ArgumentError('rating');
    }

    final reviewRef = _db.collection('reviews').doc(bookingId);
    final profileRef = _db.collection('nurseProfiles').doc(nurseId);
    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((tx) async {
      // Firestore transactions require all reads to happen before writes.
      // The previous code read profileRef after tx.set(reviewRef), which could
      // make the native Firestore transaction future complete more than once.
      final bookingSnap = await tx.get(bookingRef);
      final existingReviewSnap = await tx.get(reviewRef);
      final profileSnap = await tx.get(profileRef);

      if (!bookingSnap.exists) {
        throw StateError('الحجز غير موجود');
      }

      final booking = bookingSnap.data() as Map<String, dynamic>;

      if (booking['clientId'] != clientId || booking['nurseId'] != nurseId) {
        throw StateError('غير مسموح بتقييم هذا الحجز');
      }

      if (booking['status'] != 'completed') {
        throw StateError('يمكن التقييم بعد انتهاء الرعاية');
      }

      if (existingReviewSnap.exists) {
        throw StateError('تم تقييم هذا الحجز بالفعل');
      }

      final data = profileSnap.data() ?? <String, dynamic>{};
      final oldCount = (data['totalReviews'] as num?)?.toInt() ?? 0;
      final oldAverage = (data['averageRating'] as num?)?.toDouble() ?? 0;
      final newCount = oldCount + 1;
      final newAverage = ((oldAverage * oldCount) + rating) / newCount;

      final distribution = Map<String, dynamic>.from(
        (data['ratingDistribution'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v),
            ) ??
            {},
      );
      distribution['$rating'] =
          ((distribution['$rating'] as num?)?.toInt() ?? 0) + 1;

      // All writes happen after all required reads.
      tx.set(reviewRef, {
        'bookingId': bookingId,
        'clientId': clientId,
        'nurseId': nurseId,
        'rating': rating,
        'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        profileRef,
        {
          'averageRating': double.parse(newAverage.toStringAsFixed(2)),
          'totalReviews': newCount,
          'ratingDistribution': distribution,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<List<Review>> getNurseReviews(
    String nurseId, {
    int limit = 20,
  }) async {
    final snap = await _db
        .collection('reviews')
        .where('nurseId', isEqualTo: nurseId)
        .limit(limit)
        .get();

    final reviews = snap.docs.map(Review.fromFirestore).toList();
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }
}
