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

class _PreviousShiftsScreenState extends State<PreviousShiftsScreen>
    with SingleTickerProviderStateMixin {
  List<Booking> _shifts = [];
  bool _isLoading = true;
  String? _errorMessage;
  late final TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadShifts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShifts() async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('unauthenticated');

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nurseId', isEqualTo: uid)
          .where('status', whereIn: ['completed', 'cancelled', 'disputed'])
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      if (!mounted) return;
      setState(() {
        _shifts = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحميل الشيفتات السابقة. حاول مرة أخرى.';
          _isLoading = false;
        });
      }
    }
  }

  List<Booking> get _filteredShifts {
    if (_selectedTab == 0) return _shifts;
    final status = _selectedTab == 1 ? 'completed' : 'cancelled';
    return _shifts.where((shift) => shift.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الشيفتات السابقة'),
        actions: [
          IconButton(onPressed: _loadShifts, icon: const Icon(Icons.refresh_outlined)),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() => _selectedTab = index),
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'مكتملة'),
            Tab(text: 'ملغاة'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _errorState()
              : _filteredShifts.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadShifts,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 130),
                          Icon(Icons.event_busy_outlined, size: 60),
                          SizedBox(height: 14),
                          Center(child: Text('لا توجد شيفتات سابقة')),
                          SizedBox(height: 6),
                          Center(child: Text('الشيفتات المكتملة أو الملغاة ستظهر هنا.')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadShifts,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _filteredShifts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _shiftCard(_filteredShifts[index]),
                      ),
                    ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _loadShifts, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }

  Widget _shiftCard(Booking shift) {
    final shortId = shift.id.length > 6 ? shift.id.substring(0, 6) : shift.id;
    final completed = shift.status == 'completed';
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (completed ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
          child: Icon(completed ? Icons.check_circle_outline : Icons.cancel_outlined, color: completed ? AppColors.success : AppColors.error),
        ),
        title: Text('شيفت #$shortId', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${DateFormat('dd/MM/yyyy – hh:mm a', 'ar').format(shift.shiftStart)}\n${shift.totalAmount.toStringAsFixed(2)} ج.م'),
        isThreeLine: true,
        trailing: Text(completed ? 'مكتمل' : 'ملغي', style: TextStyle(color: completed ? AppColors.success : AppColors.error, fontWeight: FontWeight.w700)),
        onTap: shift.careRequestId.isEmpty
            ? null
            : () => context.push('/nurse/request-details/${shift.careRequestId}'),
      ),
    );
  }
}
