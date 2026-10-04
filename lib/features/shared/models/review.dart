import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String bookingId;
  final String clientId;
  final String nurseId;
  final int rating;
  final Map<String, int> ratings;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.nurseId,
    required this.rating,
    this.ratings = const {},
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookingId': bookingId,
        'clientId': clientId,
        'nurseId': nurseId,
        'rating': rating,
        'ratings': ratings,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawRatings = data['ratings'];

    return Review(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      clientId: data['clientId'] ?? '',
      nurseId: data['nurseId'] ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      ratings: rawRatings is Map
          ? rawRatings.map(
              (key, value) => MapEntry(
                key.toString(),
                (value as num?)?.toInt() ?? 0,
              ),
            )
          : const {},
      comment: data['comment']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }
}
