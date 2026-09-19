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
      return b.shiftStart.isAfter(now);
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
          return _buildList(_bookingsForTab(index));
        }),
      ),
    );
  }

  Widget _buildList(List<Booking> list, int tab) {
    if (list.isEmpty) {
      final titles = ['لا توجد حجوزات منتهية', 'لا توجد حجوزات اليوم', 'لا توجد حجوزات قادمة'];
      final subtitles = [
        'الحجوزات التي انتهت وتم تأكيد دفعها ستظهر هنا.',
        'أي حجز موعده اليوم سيظهر هنا تلقائيًا.',
        'الحجوزات التي لم يبدأ موعدها بعد ستظهر هنا.',
      ];
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 90),
          CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.primary.withValues(alpha: 0.10),
            child: Icon(
              tab == 0 ? Icons.history_rounded :
              tab == 1 ? Icons.medical_services_outlined :
              Icons.event_available_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Center(child: Text(titles[tab],
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          Center(child: Text(subtitles[tab], textAlign: TextAlign.center)),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = list[index];
        final now = DateTime.now();
        final live = tab == 1 &&
            booking.shiftStart.isBefore(now) &&
            booking.shiftEnd.isAfter(now) &&
            booking.status != 'completed';
        final shortId = booking.id.length <= 6
            ? booking.id.toUpperCase()
            : booking.id.substring(0, 6).toUpperCase();

        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push('/client/booking-details/' + booking.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.medical_services_outlined,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('حجز #' + shortId,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(_dateLabel(booking.shiftStart),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        label: tab == 0 ? 'منتهٍ' :
                            live ? 'جاري الآن' :
                            tab == 1 ? 'اليوم' : 'قادم',
                        color: tab == 0 ? Colors.green :
                            live ? Colors.orange :
                            tab == 1 ? Colors.blue : AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _InfoItem(Icons.access_time_rounded, 'الموعد',
                            DateFormat('hh:mm a', 'ar').format(booking.shiftStart) +
                                ' - ' + DateFormat('hh:mm a', 'ar').format(booking.shiftEnd)),
                        _InfoDivider(),
                        _InfoItem(Icons.schedule_rounded, 'المدة',
                            booking.shiftHours.toString() + ' ساعة'),
                        _InfoDivider(),
                        _InfoItem(Icons.payments_outlined, 'الإجمالي',
                            booking.totalAmount.toStringAsFixed(0) + ' ج.م'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(_paymentIcon(booking.paymentStatus), size: 18,
                          color: _paymentColor(booking.paymentStatus)),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(_paymentLabel(booking.paymentStatus),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _paymentColor(booking.paymentStatus))),
                      ),
                      const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
                    ],
                  ),
                  if (tab == 1) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: (live ? Colors.orange : AppColors.primary)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        live
                            ? '●  الرعاية جارية الآن'
                            : 'موعد الرعاية اليوم في ' +
                                DateFormat('hh:mm a', 'ar').format(booking.shiftStart),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: live ? Colors.orange : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    if (_sameDay(date, now)) {
      return 'اليوم • ' + DateFormat('dd MMMM', 'ar').format(date);
    }
    return DateFormat('EEEE • dd MMMM yyyy', 'ar').format(date);
  }

  IconData _paymentIcon(String status) {
    switch (status) {
      case 'verified': return Icons.verified_rounded;
      case 'awaiting_verification': return Icons.hourglass_top_rounded;
      case 'rejected': return Icons.error_outline_rounded;
      default: return Icons.payments_outlined;
    }
  }

  Color _paymentColor(String status) {
    switch (status) {
      case 'verified': return Colors.green;
      case 'awaiting_verification': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _paymentLabel(String status) {
    switch (status) {
      case 'verified': return 'تم الدفع وتأكيد العملية';
      case 'awaiting_verification': return 'الدفع قيد المراجعة';
      case 'rejected': return 'الدفع مرفوض — راجع تفاصيل الحجز';
      default: return 'الدفع لم يتم تأكيده بعد';
    }
  }

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoItem(this.icon, this.title, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _InfoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 34,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(label, style: TextStyle(
      color: color, fontSize: 11, fontWeight: FontWeight.w800,
    )),
  );
}
