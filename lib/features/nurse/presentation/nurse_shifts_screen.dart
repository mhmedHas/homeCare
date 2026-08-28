import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/models/booking.dart';

class NurseShiftsScreen extends StatefulWidget {
  const NurseShiftsScreen({super.key});

  @override
  State<NurseShiftsScreen> createState() => _NurseShiftsScreenState();
}

class _NurseShiftsScreenState extends State<NurseShiftsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _upcomingShifts = [];
  List<Booking> _pastShifts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadShifts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nurseId', isEqualTo: user.uid)
          .orderBy('shiftStart', descending: false)
          .get();

      final allBookings =
          snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();

      final now = DateTime.now();

      // تقسيم الشيفتات إلى قادمة وسابقة
      final upcoming = allBookings
          .where((b) =>
              b.status == 'confirmed' ||
              b.status == 'in_progress' ||
              (b.status == 'pending_payment' &&
                  b.shiftStart.isAfter(now.subtract(const Duration(hours: 1)))))
          .toList();

      final past = allBookings
          .where((b) =>
              b.status == 'completed' ||
              b.status == 'cancelled' ||
              b.status == 'disputed' ||
              (b.status == 'pending_payment' &&
                  b.shiftStart
                      .isBefore(now.subtract(const Duration(hours: 1)))))
          .toList();

      setState(() {
        _upcomingShifts = upcoming;
        _pastShifts = past;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في تحميل الشيفتات';
        _isLoading = false;
      });
    }
  }

  String _getTimeRemaining(Booking shift) {
    final now = DateTime.now();
    if (shift.shiftStart.isBefore(now)) {
      return 'بدأت منذ ${_getDuration(now.difference(shift.shiftStart))}';
    } else {
      return 'تبدأ بعد ${_getDuration(shift.shiftStart.difference(now))}';
    }
  }

  String _getDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} يوم';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ساعة';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} دقيقة';
    } else {
      return 'أقل من دقيقة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الشيفتات'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShifts,
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
                        onPressed: _loadShifts,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // TabBar
                    Container(
                      color: AppColors.primary,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.event_available),
                            text: 'القادمة',
                          ),
                          Tab(
                            icon: Icon(Icons.history),
                            text: 'السابقة',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildShiftList(_upcomingShifts, isUpcoming: true),
                          _buildShiftList(_pastShifts, isUpcoming: false),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildShiftList(List<Booking> shifts, {required bool isUpcoming}) {
    if (shifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_busy : Icons.history,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'لا توجد شيفتات قادمة' : 'لا توجد شيفتات سابقة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming
                  ? 'ستظهر هنا الشيفتات المؤكدة والقادمة'
                  : 'ستظهر هنا الشيفتات المكتملة والملغاة',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: shifts.length,
      itemBuilder: (context, index) {
        final shift = shifts[index];
        final isPast = !isUpcoming;
        final isPendingPayment = shift.status == 'pending_payment';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // ✅ عند الضغط على البطاقة، انتقل إلى تفاصيل الحجز
              context.go('/client/booking-details/${shift.id}');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الصف العلوي: الرقم والحالة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isUpcoming ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'شيفت #${shift.id.substring(0, 6)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(shift.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _getStatusColor(shift.status).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getStatusLabel(shift.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(shift.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // التاريخ والوقت
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE، d MMM yyyy').format(shift.shiftStart),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat.jm().format(shift.shiftStart)} - ${DateFormat.jm().format(shift.shiftEnd)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${shift.shiftHours} ساعة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // الصف السفلي: السعر + الوقت المتبقي (للقادمة) أو زر التفاصيل
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isPendingPayment)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.shade200,
                            ),
                          ),
                          child: const Text(
                            'في انتظار الدفع',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (!isPendingPayment)
                        Text(
                          '${shift.totalAmount.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      if (isUpcoming && !isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getTimeRemaining(shift),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      case 'disputed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'انتظار دفع';
      case 'confirmed':
        return 'مؤكد';
      case 'in_progress':
        return 'جاري';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'disputed':
        return 'نزاع';
      default:
        return status;
    }
  }
}
