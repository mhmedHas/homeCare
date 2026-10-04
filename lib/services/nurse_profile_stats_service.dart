import 'package:cloud_firestore/cloud_firestore.dart';

class NurseProfileStats {
  final int completedBookings;

  const NurseProfileStats({
    required this.completedBookings,
  });
}

class NurseProfileStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<NurseProfileStats> getStats(String nurseId) async {
    final snapshot = await _db
        .collection('bookings')
        .where('nurseId', isEqualTo: nurseId)
        .limit(500)
        .get();

    final completedBookings = snapshot.docs
        .where((doc) => doc.data()['status']?.toString() == 'completed')
        .length;

    return NurseProfileStats(
      completedBookings: completedBookings,
    );
  }
}
