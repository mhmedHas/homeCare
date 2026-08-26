import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
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

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nurseId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .get();

      final bookings =
          snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
      setState(() {
        _transactions = bookings;
        _totalShifts = bookings.length;
        _totalEarnings = bookings.fold(0, (sum, b) => sum + b.totalAmount);

        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final weekStart = now.subtract(Duration(days: now.weekday - 1));

        _monthEarnings = bookings
            .where((b) => b.createdAt.isAfter(monthStart))
            .fold(0, (sum, b) => sum + b.totalAmount);

        _weekEarnings = bookings
            .where((b) => b.createdAt.isAfter(weekStart))
            .fold(0, (sum, b) => sum + b.totalAmount);
      });
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
      appBar: AppBar(title: const Text('الأرباح')),
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
                          onPressed: _loadEarnings,
                          child: const Text('إعادة المحاولة')),
                    ]))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                              child: _buildSummaryCard(
                                  'الإجمالي',
                                  '${_totalEarnings.toStringAsFixed(0)} ج.م',
                                  Colors.blue)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildSummaryCard(
                                  'هذا الشهر',
                                  '${_monthEarnings.toStringAsFixed(0)} ج.م',
                                  Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _buildSummaryCard(
                                  'هذا الأسبوع',
                                  '${_weekEarnings.toStringAsFixed(0)} ج.م',
                                  Colors.orange)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildSummaryCard('عدد الشيفتات',
                                  '$_totalShifts', Colors.purple)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('سجل المعاملات',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _transactions.isEmpty
                            ? const Center(child: Text('لا توجد معاملات'))
                            : ListView.builder(
                                itemCount: _transactions.length,
                                itemBuilder: (context, index) {
                                  final t = _transactions[index];
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      title:
                                          Text('شيفت #${t.id.substring(0, 6)}'),
                                      subtitle: Text(DateFormat.yMMMd()
                                          .format(t.createdAt)),
                                      trailing: Text(
                                        '+${t.totalAmount.toStringAsFixed(0)} ج.م',
                                        style: const TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold),
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

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
