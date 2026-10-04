import 'package:cloud_firestore/cloud_firestore.dart';

class NurseProfileStats {
  final int completedBookings;
  final double onTimeRate;
  final double averageResponseMinutes;

  const NurseProfileStats({
    required this.completedBookings,
    required this.onTimeRate,
    required this.averageResponseMinutes,
  });

  String get onTimeRateLabel {
    if (onTimeRate <= 0) return '—';
    return onTimeRate.toStringAsFixed(onTimeRate >= 99 ? 0 : 1) + '%';
  }

  String get responseTimeLabel {
    if (averageResponseMinutes <= 0) return '—';
    final rounded = averageResponseMinutes.round();
    if (rounded < 1) return 'أقل من دقيقة';
    if (rounded == 1) return 'دقيقة واحدة';
    if (rounded == 2) return 'دقيقتان';
    if (rounded < 11) return rounded.toString() + ' دقائق';
    return rounded.toString() + ' دقيقة';
  }
}

class NurseProfileStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<NurseProfileStats> getStats(String nurseId) async {
    final results = await Future.wait([
      _db.collection('bookings').where('nurseId', isEqualTo: nurseId).limit(500).get(),
      _db.collection('careOffers').where('nurseId', isEqualTo: nurseId).limit(500).get(),
    ]);

    final bookings = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final offers = results[1] as QuerySnapshot<Map<String, dynamic>>;

    final completedBookings = bookings.docs
        .where((doc) => doc.data()['status']?.toString() == 'completed')
        .length;

    var checkIns = 0;
    var onTimeCheckIns = 0;

    for (final doc in bookings.docs) {
      final data = doc.data();
      final checkIn = _timestamp(data['checkInAt']);
      final shiftStart = _timestamp(data['shiftStart']);
      if (checkIn == null || shiftStart == null) continue;

      checkIns++;
      final deadline = shiftStart.add(const Duration(minutes: 15));
      if (!checkIn.isAfter(deadline)) {
        onTimeCheckIns++;
      }
    }

    final onTimeRate = checkIns == 0 ? 0.0 : (onTimeCheckIns / checkIns) * 100;

    final requestIds = offers.docs
        .map((doc) => doc.data()['requestId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final requestCreatedAt = <String, DateTime>{};
    for (var i = 0; i < requestIds.length; i += 30) {
      final chunk = requestIds.sublist(
        i,
        i + 30 > requestIds.length ? requestIds.length : i + 30,
      );
      final snap = await _db
          .collection('careRequests')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snap.docs) {
        final createdAt = _timestamp(doc.data()['createdAt']);
        if (createdAt != null) requestCreatedAt[doc.id] = createdAt;
      }
    }

    var responseSamples = 0;
    var totalResponseMinutes = 0.0;

    for (final offerDoc in offers.docs) {
      final data = offerDoc.data();
      final requestId = data['requestId']?.toString() ?? '';
      final offerCreatedAt = _timestamp(data['createdAt']);
      final requestTime = requestCreatedAt[requestId];
      if (offerCreatedAt == null || requestTime == null) continue;

      final minutes = offerCreatedAt.difference(requestTime).inSeconds / 60;
      if (minutes < 0 || minutes > 60 * 24 * 30) continue;

      totalResponseMinutes += minutes;
      responseSamples++;
    }

    final averageResponseMinutes = responseSamples == 0
        ? 0.0
        : totalResponseMinutes / responseSamples;

    return NurseProfileStats(
      completedBookings: completedBookings,
      onTimeRate: onTimeRate,
      averageResponseMinutes: averageResponseMinutes,
    );
  }

  DateTime? _timestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}