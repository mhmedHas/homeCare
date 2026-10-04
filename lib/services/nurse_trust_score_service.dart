import 'package:cloud_firestore/cloud_firestore.dart';

class NurseTrustScore {
  final String nurseId;
  final double score;
  final double averageRating;
  final int completedBookings;
  final int cancelledBookings;
  final int experienceYears;
  final double expectedPrice;

  const NurseTrustScore({
    required this.nurseId,
    required this.score,
    required this.averageRating,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.experienceYears,
    required this.expectedPrice,
  });

  String get scoreLabel {
    if (score <= 0) return 'جديد';
    return score.round().toString() + '/100';
  }

  double get cancellationReliability {
    final outcomes = completedBookings + cancelledBookings;
    if (outcomes == 0) return 0;
    return completedBookings / outcomes;
  }
}

class NurseTrustScoreService {
  static const double _ratingWeight = 60;
  static const double _completedWeight = 25;
  static const double _reliabilityWeight = 15;
  static const int _completedCap = 50;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, NurseTrustScore>> getScores(List<String> nurseIds) async {
    final ids = nurseIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) return {};

    final profiles = <String, Map<String, dynamic>>{};
    final bookingsByNurse = <String, List<Map<String, dynamic>>>{};

    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(
        i,
        i + 30 > ids.length ? ids.length : i + 30,
      );

      final results = await Future.wait([
        _db
            .collection('nurseProfiles')
            .where(FieldPath.documentId, whereIn: chunk)
            .get(),
        _db.collection('bookings').where('nurseId', whereIn: chunk).get(),
      ]);

      final profileSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final bookingSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;

      for (final doc in profileSnap.docs) {
        profiles[doc.id] = doc.data();
      }

      for (final doc in bookingSnap.docs) {
        final data = doc.data();
        final nurseId = data['nurseId']?.toString() ?? '';
        if (nurseId.isEmpty) continue;
        bookingsByNurse.putIfAbsent(nurseId, () => []).add(data);
      }
    }

    final scores = <String, NurseTrustScore>{};

    for (final nurseId in ids) {
      final profile = profiles[nurseId] ?? {};
      final bookings = bookingsByNurse[nurseId] ?? [];
      scores[nurseId] = _buildScore(nurseId, profile, bookings);
    }

    return scores;
  }

  Future<NurseTrustScore> getScore(
    String nurseId, {
    Map<String, dynamic>? profileData,
  }) async {
    final profile = profileData ??
        (await _db.collection('nurseProfiles').doc(nurseId).get()).data() ??
        <String, dynamic>{};

    final bookings = await _db
        .collection('bookings')
        .where('nurseId', isEqualTo: nurseId)
        .get();

    return _buildScore(
      nurseId,
      profile,
      bookings.docs.map((doc) => doc.data()).toList(),
    );
  }

  NurseTrustScore _buildScore(
    String nurseId,
    Map<String, dynamic> profile,
    List<Map<String, dynamic>> bookings,
  ) {
    final averageRating =
        (profile['averageRating'] as num?)?.toDouble() ?? 0;

    final completedBookings = bookings.where(
      (booking) => booking['status']?.toString() == 'completed',
    ).length;

    final cancelledBookings = bookings.where(
      (booking) =>
          booking['status']?.toString() == 'cancelled' &&
          booking['cancelledBy']?.toString() == 'nurse',
    ).length;

    final ratingPart = (averageRating.clamp(0, 5) / 5) * _ratingWeight;
    final completedPart =
        (completedBookings.clamp(0, _completedCap) / _completedCap) *
            _completedWeight;

    final outcomes = completedBookings + cancelledBookings;
    final reliabilityPart = outcomes == 0
        ? 0.0
        : (completedBookings / outcomes) * _reliabilityWeight;

    return NurseTrustScore(
      nurseId: nurseId,
      score: (ratingPart + completedPart + reliabilityPart)
          .clamp(0, 100)
          .toDouble(),
      averageRating: averageRating,
      completedBookings: completedBookings,
      cancelledBookings: cancelledBookings,
      experienceYears:
          (profile['experienceYears'] as num?)?.toInt() ?? 0,
      expectedPrice:
          (profile['expectedPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}