import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
import '../../../services/auth_service.dart';
import '../../shared/models/booking.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (mounted) setState(() => _errorMessage = 'يرجى تسجيل الدخول');
        return;
      }

      final bookings = await BookingService().getClientBookings(user.uid);
      if (mounted) setState(() => _bookings = bookings);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'حدث خطأ في تحميل الحجوزات');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Booking> _bookingsForTab(int index) {
    final now = DateTime.now();
    final result = _bookings.where((b) {
      if (b.status == 'cancelled') return false;
      if (index == 0) {
        return b.shiftEnd.isBefore(now) && b.paymentStatus == 'verified';
      }
      if (index == 1) return _sameDay(b.shiftStart, now);
      if (index == 2) return b.shiftStart.isAfter(now);
      return false;
    }).toList();

    result.sort((a, b) => index == 0
        ? b.shiftEnd.compareTo(a.shiftEnd)
        : a.shiftStart.compareTo(b.shiftStart));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('حجوزاتي'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'منتهية'),
            Tab(text: 'جارية'),
            Tab(text: 'قادمة'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: TabBarView(
        controller: _tabController,
        children: List.generate(3, (index) {
          return _buildList(_bookingsForTab(index), index);
        }),
      ),
    );
  }

  Widget _buildList(List<Booking> list, int tab) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.event_busy_outlined, size: 60),
          SizedBox(height: 14),
          Center(
            child: Text(
              'لا توجد حجوزات هنا',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(height: 6),
          Center(child: Text('عند وجود حجز سيظهر هنا.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final booking = list[index];
        final shortId = booking.id.length <= 6
            ? booking.id
            : booking.id.substring(0, 6);

        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () =>
                context.push('/client/booking-details/${booking.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.medical_services_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حجز #$shortId',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${DateFormat('dd/MM/yyyy – hh:mm a', 'ar').format(booking.shiftStart)}\n${booking.totalAmount.toStringAsFixed(2)} ج.م',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
                    label: tab == 0 ? 'منتهٍ' : tab == 1 ? 'اليوم' : 'قادم',
                    color: tab == 0
                        ? Colors.green
                        : tab == 1
                            ? Colors.blue
                            : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_left),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
