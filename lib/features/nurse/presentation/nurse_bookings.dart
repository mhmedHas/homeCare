import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../shared/models/booking.dart';

class NurseBookingsScreen extends StatefulWidget {
  const NurseBookingsScreen({super.key});

  @override
  State<NurseBookingsScreen> createState() => _NurseBookingsScreenState();
}

class _NurseBookingsScreenState extends State<NurseBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final user = AuthService().currentUser;
      if (user == null) throw StateError('auth');
      final data = await BookingService().getNurseBookings(user.uid);
      if (!mounted) return;
      setState(() => _bookings = data);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحميل الحجوزات. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Booking> _forTab(int index) {
    if (index == 1) {
      return _bookings.where((b) => b.status == 'pending_payment' || b.status == 'confirmed' || b.status == 'in_progress').toList();
    }
    if (index == 2) return _bookings.where((b) => b.status == 'completed').toList();
    if (index == 3) return _bookings.where((b) => b.status == 'cancelled').toList();
    return _bookings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجوزاتي'),
        automaticallyImplyLeading: false,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [Tab(text: 'الكل'), Tab(text: 'القادمة'), Tab(text: 'السابقة'), Tab(text: 'الملغاة')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: List.generate(4, (i) => _BookingList(bookings: _forTab(i))),
                ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Booking> bookings;
  const _BookingList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {},
        child: ListView(children: const [
          SizedBox(height: 120),
          Icon(Icons.calendar_month_outlined, size: 60),
          SizedBox(height: 12),
          Center(child: Text('لا توجد حجوزات هنا', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          SizedBox(height: 6),
          Center(child: Text('ستظهر الحجوزات التي تخصك هنا.')),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final b = bookings[index];
        final id = b.id.length > 6 ? b.id.substring(0, 6) : b.id;
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: const CircleAvatar(child: Icon(Icons.medical_services_outlined)),
            title: Text('حجز #$id', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${_date(b.shiftStart)}\n${b.totalAmount.toStringAsFixed(0)} ج.م'),
            ),
            trailing: _Status(status: b.status),
            onTap: () => context.push('/nurse/current-shift'),
          ),
        );
      },
    );
  }

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _Status extends StatelessWidget {
  final String status;
  const _Status({required this.status});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    switch (status) {
      case 'pending_payment': text = 'انتظار الدفع'; color = Colors.orange; break;
      case 'confirmed': text = 'مؤكد'; color = Colors.blue; break;
      case 'in_progress': text = 'جاري'; color = Colors.purple; break;
      case 'completed': text = 'مكتمل'; color = AppColors.success; break;
      case 'cancelled': text = 'ملغي'; color = AppColors.error; break;
      default: text = 'غير معروف'; color = Colors.grey; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 52),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
      ]),
    ),
  );
}
