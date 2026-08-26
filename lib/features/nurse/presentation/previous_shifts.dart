import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/models/booking.dart';

class PreviousShiftsScreen extends StatefulWidget {
  const PreviousShiftsScreen({super.key});

  @override
  State<PreviousShiftsScreen> createState() => _PreviousShiftsScreenState();
}

class _PreviousShiftsScreenState extends State<PreviousShiftsScreen> {
  List<Booking> _shifts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'all'; // all, completed, cancelled

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
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
          .where('status', whereIn: ['completed', 'cancelled', 'disputed'])
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _shifts =
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
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

  List<Booking> get _filteredShifts {
    if (_filter == 'all') return _shifts;
    return _shifts.where((b) => b.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الشيفتات السابقة'),
        bottom: TabBar(
          tabs: [
            const Tab(text: 'الكل'),
            const Tab(text: 'مكتملة'),
            const Tab(text: 'ملغاة'),
          ],
          onTap: (index) {
            setState(() {
              if (index == 0)
                _filter = 'all';
              else if (index == 1)
                _filter = 'completed';
              else if (index == 2) _filter = 'cancelled';
            });
          },
        ),
      ),
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
                          onPressed: _loadShifts,
                          child: const Text('إعادة المحاولة')),
                    ]))
              : _filteredShifts.isEmpty
                  ? const Center(child: Text('لا توجد شيفتات'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredShifts.length,
                      itemBuilder: (context, index) {
                        final shift = _filteredShifts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text('شيفت #${shift.id.substring(0, 6)}'),
                            subtitle: Text(
                              '${DateFormat.yMMMd().format(shift.shiftStart)} | ${shift.totalAmount} ج.م',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: shift.status == 'completed'
                                    ? AppColors.success
                                    : AppColors.error,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                shift.status == 'completed' ? 'مكتمل' : 'ملغي',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                            onTap: () {
                              context.go('/client/booking-details/${shift.id}');
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
