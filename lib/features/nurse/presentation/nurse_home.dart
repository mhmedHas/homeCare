import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/user_service.dart';
import '../../shared/models/care_request.dart';
import '../../shared/models/booking.dart';

class NurseHomeScreen extends StatefulWidget {
  const NurseHomeScreen({super.key});

  @override
  State<NurseHomeScreen> createState() => _NurseHomeScreenState();
}

class _NurseHomeScreenState extends State<NurseHomeScreen> {
  String _userName = 'الممرض';
  bool _isLoading = true;
  bool _isVerified = false;

  int _pendingRequestsCount = 0;
  int _todayShiftsCount = 0;
  double _totalEarnings = 0;
  double _averageRating = 0;
  List<CareRequest> _availableRequests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Each section is loaded independently: a problem in one query (for
    // example a missing Firestore index for the "today's shifts" query)
    // should never blank out the rest of the dashboard.
    try {
      final appUser = await UserService().getUser(user.uid);
      if (appUser != null && mounted) {
        setState(() {
          _userName = appUser.name.trim().isNotEmpty ? appUser.name.trim() : 'الممرض';
          _isVerified = appUser.isVerified;
        });
      }
    } catch (e) {
      debugPrint('nurse_home: failed to load user profile: $e');
    }

    try {
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('careRequests')
          .where('status', isEqualTo: 'open')
          .limit(20)
          .get();
      final requests = requestsSnapshot.docs.map(CareRequest.fromFirestore).toList();
      if (mounted) {
        setState(() {
          _availableRequests = requests;
          _pendingRequestsCount = requests.length;
        });
      }
    } catch (e) {
      debugPrint('nurse_home: failed to load open requests: $e');
    }

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final shiftsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nurseId', isEqualTo: user.uid)
          .where('status', whereIn: ['confirmed', 'in_progress'])
          .where('shiftStart', isGreaterThanOrEqualTo: todayStart)
          .where('shiftStart', isLessThan: todayEnd)
          .get();
      if (mounted) setState(() => _todayShiftsCount = shiftsSnapshot.docs.length);
    } catch (e) {
      debugPrint('nurse_home: failed to load today\'s shifts (needs a Firestore composite index): $e');
    }

    try {
      final completedSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nurseId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();
      final completedShifts = completedSnapshot.docs.map(Booking.fromFirestore);
      if (mounted) {
        setState(() {
          _totalEarnings = completedShifts.fold(0.0, (sum, b) => sum + b.totalAmount);
        });
      }
    } catch (e) {
      debugPrint('nurse_home: failed to load earnings: $e');
    }

    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('nurseId', isEqualTo: user.uid)
          .get();
      if (reviewsSnapshot.docs.isNotEmpty && mounted) {
        final sum = reviewsSnapshot.docs.fold<double>(
          0.0,
          (s, doc) => s + ((doc.data()['rating'] ?? 0) as num).toDouble(),
        );
        setState(() => _averageRating = sum / reviewsSnapshot.docs.length);
      }
    } catch (e) {
      debugPrint('nurse_home: failed to load reviews: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('nurse_home_title')),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                    'أهلاً، $_userName 🩺',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (!_isVerified)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/nurse/settings'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppStrings.t('nurse_complete_verification'),
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  if (!_isVerified) const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(AppStrings.t('nurse_new_requests'), '$_pendingRequestsCount', Icons.request_page, Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(AppStrings.t('nurse_today_shifts'), '$_todayShiftsCount', Icons.today, Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(AppStrings.t('nurse_earnings'), '${_totalEarnings.toStringAsFixed(0)} ${AppStrings.t('currency_egp')}', Icons.account_balance_wallet_outlined, Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          AppStrings.t('nurse_rating'),
                          _averageRating > 0 ? '${_averageRating.toStringAsFixed(1)} ⭐' : AppStrings.t('none'),
                          Icons.star_rounded,
                          Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.t('nurse_available_requests'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => context.push('/nurse/available-requests'),
                        child: Text(AppStrings.t('view_all')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_availableRequests.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(Icons.search_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(AppStrings.t('nurse_no_requests'), style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(
                      _availableRequests.length > 3 ? 3 : _availableRequests.length,
                      (index) {
                        final request = _availableRequests[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                request.patientName.isNotEmpty ? request.patientName[0] : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(request.patientName),
                            subtitle: Text(
                              '${request.careType} • ${request.shiftHours} ${AppStrings.t('hours_short')} • ${request.governorate}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => context.push('/nurse/request-details/${request.id}'),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: .08),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
