import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/user_service.dart';
import '../../shared/models/booking.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  List<Booking> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _balance = 0;
  double _totalEarnings = 0;
  double _monthEarnings = 0;
  double _weekEarnings = 0;
  int _totalShifts = 0;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('يرجى تسجيل الدخول');

      final appUser = await UserService().getUser(user.uid);

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nurseId', isEqualTo: user.uid)
          .where('paymentStatus', isEqualTo: 'verified')
          .limit(100)
          .get();

      final bookings = snapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final completed = bookings.where((b) => b.status == 'completed').toList();

      if (!mounted) return;

      setState(() {
        _balance = appUser?.balance ?? 0;
        _transactions = bookings;
        _totalShifts = completed.length;
        _totalEarnings = completed.fold(0, (sum, b) => sum + b.nurseEarnings);

        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final weekStart = now.subtract(Duration(days: now.weekday - 1));

        _monthEarnings = completed
            .where((b) => !b.createdAt.isBefore(monthStart))
            .fold(0, (sum, b) => sum + b.nurseEarnings);

        _weekEarnings = completed
            .where((b) => !b.createdAt.isBefore(weekStart))
            .fold(0, (sum, b) => sum + b.nurseEarnings);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is StateError ? e.message : 'حدث خطأ أثناء تحميل الأرباح.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأرباح'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadEarnings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEarnings,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        color: AppColors.primaryLight,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                'الرصيد المتاح',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_balance.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'يتم تحديث الرصيد فقط بعد تأكيد الدفع من الإدارة.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'إجمالي الشيفتات المكتملة',
                              '${_totalEarnings.toStringAsFixed(0)} ج.م',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'عدد الشيفتات',
                              '${_totalShifts}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'هذا الشهر',
                              '${_monthEarnings.toStringAsFixed(0)} ج.م',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'هذا الأسبوع',
                              '${_weekEarnings.toStringAsFixed(0)} ج.م',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'عمليات الأرباح الموثقة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _transactions.isEmpty
                            ? const Center(child: Text('لا توجد أرباح موثقة حتى الآن'))
                            : ListView.builder(
                                itemCount: _transactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = _transactions[index];
                                  final shortId = transaction.id.length > 8
                                      ? transaction.id.substring(0, 8)
                                      : transaction.id;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      title: Text('طلب #${shortId}'),
                                      subtitle: Text(
                                        DateFormat.yMMMd().format(transaction.createdAt),
                                      ),
                                      trailing: Text(
                                        '+${transaction.nurseEarnings.toStringAsFixed(0)} ج.م',
                                        style: const TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
