import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/models/booking.dart';

class NurseProScreen extends StatefulWidget {
  const NurseProScreen({super.key});

  @override
  State<NurseProScreen> createState() => _NurseProScreenState();
}

class _NurseProScreenState extends State<NurseProScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int _completedShifts = 0;
  double _averageRating = 0;
  String _currentLevel = 'Bronze';
  double _progressToNextLevel = 0;
  int _nextLevelTarget = 20;

  final Map<String, LevelData> _levels = {
    'Bronze': LevelData(
        label: '🟢 برونز',
        minShifts: 0,
        minRating: 0,
        benefits: ['الطلبات العادية']),
    'Silver': LevelData(
        label: '🔵 فضي',
        minShifts: 20,
        minRating: 4.5,
        benefits: ['أولوية بسيطة في الطلبات']),
    'Gold': LevelData(
        label: '🟣 ذهبي',
        minShifts: 50,
        minRating: 4.7,
        benefits: ['طلبات أفضل', 'عمولة أقل']),
    'Platinum': LevelData(
        label: '🟡 بلاتينيوم',
        minShifts: 100,
        minRating: 4.9,
        benefits: ['أولوية قصوى', 'عمولة منخفضة']),
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول';
        });
        return;
      }

      // Get completed shifts
      final shiftsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nurseId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      _completedShifts = shiftsSnapshot.docs.length;

      // Get average rating
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('nurseId', isEqualTo: user.uid)
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        final sum = reviewsSnapshot.docs.fold<double>(
          0.0,
          (s, doc) =>
            s + ((doc.data()['rating'] as num?)?.toDouble() ?? 0.0));
        _averageRating = sum / reviewsSnapshot.docs.length;
      }

      // Determine level
      _currentLevel = 'Bronze';
      for (var entry in _levels.entries) {
        if (_completedShifts >= entry.value.minShifts &&
            _averageRating >= entry.value.minRating) {
          _currentLevel = entry.key;
        }
      }

      // Calculate progress to next level
      final levelKeys = _levels.keys.toList();
      final currentIndex = levelKeys.indexOf(_currentLevel);
      if (currentIndex < levelKeys.length - 1) {
        final nextLevel = levelKeys[currentIndex + 1];
        final next = _levels[nextLevel]!;
        _nextLevelTarget = next.minShifts;
        final current = _levels[_currentLevel]!;
        final range = _nextLevelTarget - current.minShifts;
        _progressToNextLevel =
            ((_completedShifts - current.minShifts) / range).clamp(0.0, 1.0);
      } else {
        _progressToNextLevel = 1.0;
        _nextLevelTarget = _completedShifts;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nurse Pro')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text(_errorMessage!,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadStats,
                          child: const Text('إعادة المحاولة')),
                    ]))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Level
                      Center(
                        child: Column(
                          children: [
                            Text(
                              _levels[_currentLevel]!.label,
                              style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_completedShifts} شيفت مكتمل • ${_averageRating.toStringAsFixed(1)} ⭐',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Progress
                      if (_currentLevel != 'Platinum') ...[
                        const Text('التقدم إلى المستوى التالي',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _progressToNextLevel,
                          backgroundColor: Colors.grey.shade200,
                          color: AppColors.primary,
                          minHeight: 12,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_completedShifts} شيفت',
                                style: const TextStyle(fontSize: 12)),
                            Text('$_nextLevelTarget شيفت',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text('المزايا',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._levels.entries.map((entry) {
                        final isActive =
                            _levels.keys.toList().indexOf(entry.key) <=
                                _levels.keys.toList().indexOf(_currentLevel);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              isActive ? Icons.check_circle : Icons.lock,
                              color: isActive ? AppColors.success : Colors.grey,
                            ),
                            title: Text(entry.value.label),
                            subtitle: Text(entry.value.benefits.join(' • ')),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }
}

class LevelData {
  final String label;
  final int minShifts;
  final double minRating;
  final List<String> benefits;

  LevelData({
    required this.label,
    required this.minShifts,
    required this.minRating,
    required this.benefits,
  });
}
