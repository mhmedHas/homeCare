import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
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

    _tabController = TabController(
      length: 3,
      vsync: this,
    );

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
        if (mounted) {
          setState(() {
            _errorMessage = 'يرجى تسجيل الدخول أولاً';
          });
        }
        return;
      }

      final bookings = await BookingService().getClientBookings(user.uid);

      if (mounted) {
        setState(() {
          _bookings = bookings;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء تحميل الحجوزات';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isCurrentlyRunning(Booking booking) {
    final now = DateTime.now();

    return booking.shiftStart.isBefore(now) &&
        booking.shiftEnd.isAfter(now) &&
        booking.status != 'cancelled';
  }

  bool _isUpcoming(Booking booking) {
    final now = DateTime.now();

    return booking.shiftStart.isAfter(now) && booking.status != 'cancelled';
  }

  bool _isFinished(Booking booking) {
    final now = DateTime.now();

    return booking.shiftEnd.isBefore(now) && booking.status != 'cancelled';
  }

  List<Booking> _getBookingsForTab(int index) {
    final result = <Booking>[];

    for (final booking in _bookings) {
      if (booking.status == 'cancelled') {
        continue;
      }

      if (index == 0 && _isUpcoming(booking)) {
        result.add(booking);
      } else if (index == 1 && _isCurrentlyRunning(booking)) {
        result.add(booking);
      } else if (index == 2 && _isFinished(booking)) {
        result.add(booking);
      }
    }

    if (index == 0) {
      result.sort(
        (a, b) => a.shiftStart.compareTo(b.shiftStart),
      );
    } else if (index == 1) {
      result.sort(
        (a, b) => a.shiftStart.compareTo(b.shiftStart),
      );
    } else {
      result.sort(
        (a, b) => b.shiftEnd.compareTo(a.shiftEnd),
      );
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'حجوزاتي',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          // ألوان صريحة حتى يظل النص واضحًا مع أي ثيم أو لون للخلفية.
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey.shade700,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.event_available_outlined),
              text: 'قادمة',
            ),
            Tab(
              icon: Icon(Icons.play_circle_outline),
              text: 'جارية',
            ),
            Tab(
              icon: Icon(Icons.check_circle_outline),
              text: 'منتهية',
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(
            _getBookingsForTab(0),
            BookingCategory.upcoming,
          ),
          _buildBookingsList(
            _getBookingsForTab(1),
            BookingCategory.running,
          ),
          _buildBookingsList(
            _getBookingsForTab(2),
            BookingCategory.finished,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 60,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'تعذر تحميل الحجوزات',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
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

  Widget _buildBookingsList(
    List<Booking> bookings,
    BookingCategory category,
  ) {
    if (bookings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 80,
        ),
        children: [
          Icon(
            _emptyIcon(category),
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 18),
          Text(
            _emptyTitle(category),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _emptySubtitle(category),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        30,
      ),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _BookingCard(
          booking: bookings[index],
          category: category,
          onTap: () {
            context.push(
              '/client/booking-details/${bookings[index].id}',
            );
          },
        );
      },
    );
  }

  IconData _emptyIcon(BookingCategory category) {
    switch (category) {
      case BookingCategory.upcoming:
        return Icons.event_available_outlined;
      case BookingCategory.running:
        return Icons.medical_services_outlined;
      case BookingCategory.finished:
        return Icons.history;
    }
  }

  String _emptyTitle(BookingCategory category) {
    switch (category) {
      case BookingCategory.upcoming:
        return 'لا توجد حجوزات قادمة';
      case BookingCategory.running:
        return 'لا توجد رعاية جارية';
      case BookingCategory.finished:
        return 'لا توجد حجوزات منتهية';
    }
  }

  String _emptySubtitle(BookingCategory category) {
    switch (category) {
      case BookingCategory.upcoming:
        return 'أي حجز قادم ستجده هنا.';
      case BookingCategory.running:
        return 'الحجوزات التي بدأت بالفعل ستظهر هنا.';
      case BookingCategory.finished:
        return 'بعد انتهاء مواعيد الرعاية ستظهر الحجوزات هنا.';
    }
  }
}

enum BookingCategory {
  upcoming,
  running,
  finished,
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final BookingCategory category;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE، d MMMM', 'ar');

    final timeFormat = DateFormat('hh:mm a', 'ar');

    final shortId =
        booking.id.length <= 6 ? booking.id : booking.id.substring(0, 6);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(shortId),
              const SizedBox(height: 16),
              _buildDateSection(
                dateFormat,
                timeFormat,
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _buildDetailsRow(),
              const SizedBox(height: 14),
              _buildStatusSection(),
              const SizedBox(height: 14),
              _buildBottomRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(String shortId) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.medical_services_outlined,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'حجز رعاية منزلية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'رقم الحجز #$shortId',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        _CategoryBadge(category: category),
      ],
    );
  }

  Widget _buildDateSection(
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(booking.shiftStart),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 15,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${timeFormat.format(booking.shiftStart)} → '
                      '${timeFormat.format(booking.shiftEnd)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsRow() {
    return Row(
      children: [
        Expanded(
          child: _InfoItem(
            icon: Icons.schedule_outlined,
            title: 'المدة',
            value: '${booking.shiftHours} ساعة',
          ),
        ),
        Container(
          width: 1,
          height: 42,
          color: Colors.grey.shade200,
        ),
        Expanded(
          child: _InfoItem(
            icon: Icons.payments_outlined,
            title: 'الإجمالي',
            value: '${booking.totalAmount.toStringAsFixed(0)} ج.م',
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      children: [
        _StatusRow(
          icon: _careStatusIcon(),
          title: 'حالة الرعاية',
          value: _careStatusText(),
          color: _careStatusColor(),
        ),
        const SizedBox(height: 9),
        _StatusRow(
          icon: _paymentStatusIcon(),
          title: 'حالة الدفع',
          value: _paymentStatusText(),
          color: _paymentStatusColor(),
        ),
      ],
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _bottomMessage(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'التفاصيل',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_back_ios_new,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _careStatusIcon() {
    if (booking.status == 'completed') {
      return Icons.check_circle_outline;
    }

    if (booking.status == 'in_progress') {
      return Icons.play_circle_outline;
    }

    if (booking.status == 'confirmed') {
      return Icons.verified_outlined;
    }

    return Icons.info_outline;
  }

  String _careStatusText() {
    if (booking.status == 'completed') {
      return 'انتهت الرعاية';
    }

    if (booking.status == 'in_progress') {
      return 'الرعاية جارية الآن';
    }

    if (booking.status == 'confirmed') {
      if (category == BookingCategory.upcoming) {
        return 'الحجز مؤكد';
      }

      return 'الرعاية بدأت';
    }

    return _translateBookingStatus(booking.status);
  }

  Color _careStatusColor() {
    if (booking.status == 'completed') {
      return Colors.green;
    }

    if (booking.status == 'in_progress') {
      return Colors.blue;
    }

    if (booking.status == 'confirmed') {
      return AppColors.primary;
    }

    return Colors.orange;
  }

  IconData _paymentStatusIcon() {
    switch (booking.paymentStatus) {
      case 'verified':
        return Icons.check_circle_outline;
      case 'awaiting_verification':
        return Icons.hourglass_top_outlined;
      case 'rejected':
        return Icons.error_outline;
      default:
        return Icons.payments_outlined;
    }
  }

  String _paymentStatusText() {
    switch (booking.paymentStatus) {
      case 'verified':
        return 'تم الدفع بنجاح';

      case 'awaiting_verification':
        return 'الدفع قيد المراجعة';

      case 'rejected':
        return 'الدفع مرفوض - يحتاج إعادة الدفع';

      case 'unpaid':
      default:
        if (booking.status == 'completed') {
          return 'لم يتم الدفع بعد';
        }

        return 'الدفع بعد انتهاء الرعاية';
    }
  }

  Color _paymentStatusColor() {
    switch (booking.paymentStatus) {
      case 'verified':
        return Colors.green;

      case 'awaiting_verification':
        return Colors.orange;

      case 'rejected':
        return Colors.red;

      case 'unpaid':
      default:
        return Colors.grey.shade700;
    }
  }

  String _translateBookingStatus(String status) {
    switch (status) {
      case 'pending_payment':
        return 'في انتظار الدفع';

      case 'confirmed':
        return 'الحجز مؤكد';

      case 'in_progress':
        return 'جارية';

      case 'completed':
        return 'منتهية';

      case 'cancelled':
        return 'ملغى';

      default:
        return 'حالة الحجز';
    }
  }

  String _bottomMessage() {
    if (booking.paymentStatus == 'verified') {
      return 'تم تأكيد الدفع والمبلغ مسجل بنجاح.';
    }

    if (booking.paymentStatus == 'awaiting_verification') {
      return 'تم إرسال الدفع وفي انتظار مراجعة الإدارة.';
    }

    if (booking.paymentStatus == 'rejected') {
      return 'يمكنك إعادة إرسال إثبات الدفع.';
    }

    if (booking.status == 'completed') {
      return 'الرعاية انتهت ويمكنك دفع المستحقات.';
    }

    if (booking.status == 'in_progress') {
      return 'تابع تفاصيل الرعاية من صفحة الحجز.';
    }

    return 'الحجز مؤكد وسيظهر الدفع بعد انتهاء الرعاية.';
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Icon(
          icon,
          size: 21,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Text(
            '$title:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final BookingCategory category;

  const _CategoryBadge({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    late final String text;
    late final Color color;
    late final IconData icon;

    switch (category) {
      case BookingCategory.upcoming:
        text = 'قادم';
        color = AppColors.primary;
        icon = Icons.event_available_outlined;
        break;

      case BookingCategory.running:
        text = 'جاري';
        color = Colors.blue;
        icon = Icons.play_circle_outline;
        break;

      case BookingCategory.finished:
        text = 'منتهي';
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
