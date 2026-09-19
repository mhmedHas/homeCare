import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/user_service.dart';
import '../../shared/models/booking.dart';
import '../../shared/models/app_user.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  AppUser? _nurse;
  bool _loadingNurse = true;

  @override
  void initState() {
    super.initState();
    _loadNurse();
  }

  Future<void> _loadNurse() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).get();
      if (!snap.exists) return;
      final booking = Booking.fromFirestore(snap);
      final nurse = await UserService().getUser(booking.nurseId);
      if (!mounted) return;
      setState(() {
        _nurse = nurse;
        _loadingNurse = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingNurse = false);
    }
  }

  Stream<Booking?> _bookingStream() {
    return FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots()
        .map((snap) => snap.exists ? Booking.fromFirestore(snap) : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرعاية الحالية')),
      body: StreamBuilder<Booking?>(
        stream: _bookingStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final booking = snapshot.data;
          if (booking == null) return const Center(child: Text('الحجز غير موجود'));

          final photoUrl = _nurse?.photoUrl?.trim() ?? '';
          final nurseName = _nurse?.name.trim().isNotEmpty == true ? _nurse!.name.trim() : 'الممرض';

          return RefreshIndicator(
            onRefresh: () async {
              await _loadNurse();
              if (mounted) setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildCareStatus(booking),
                const SizedBox(height: 14),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty ? const Icon(Icons.person_outline, color: AppColors.primary) : null,
                    ),
                    title: Text(
                      _loadingNurse && _nurse == null ? 'جارٍ تحميل الممرض...' : nurseName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('الممرض المسؤول عن الرعاية'),
                    trailing: IconButton(
                      tooltip: 'مراسلة الممرض',
                      onPressed: () => context.push('/client/chat/${booking.id}'),
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow('رقم الحجز', _shortId(booking.id)),
                        _buildInfoRow('التاريخ', DateFormat.yMMMd('ar').format(booking.shiftStart)),
                        _buildInfoRow('الوقت', DateFormat.jm('ar').format(booking.shiftStart)),
                        _buildInfoRow('المدة', '${booking.shiftHours} ساعة'),
                        _buildInfoRow('المستحقات', '${booking.totalAmount.toStringAsFixed(2)} ج.م'),
                        _buildInfoRow('حالة الدفع', _paymentLabel(booking.paymentStatus)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (booking.status == 'completed' &&
                    (booking.paymentStatus == 'unpaid' || booking.paymentStatus == 'rejected'))
                  _buildActionCard(
                    icon: Icons.payment,
                    color: Colors.orange,
                    title: booking.paymentStatus == 'rejected' ? 'تم رفض الدفع، يمكنك إعادة السداد' : 'الممرض أنهى طلب الرعاية',
                    message: booking.paymentStatus == 'rejected'
                        ? 'راجع بيانات التحويل وأرسل إثبات الدفع مرة أخرى.'
                        : 'يرجى سداد المستحقات لإتمام الطلب.',
                    buttonText: booking.paymentStatus == 'rejected' ? 'إعادة دفع المستحقات' : 'دفع المستحقات',
                    onPressed: () => context.push('/client/payment/${booking.id}'),
                  ),
                if (booking.status == 'completed' && booking.paymentStatus == 'awaiting_verification')
                  _buildActionCard(
                    icon: Icons.hourglass_top,
                    color: Colors.orange,
                    title: 'الدفع قيد المراجعة',
                    message: 'تم إرسال إثبات الدفع. انتظر مراجعة الإدارة.',
                  ),
                if (booking.status == 'completed' && booking.paymentStatus == 'verified')
                  _buildActionCard(
                    icon: Icons.check_circle,
                    color: AppColors.success,
                    title: 'تم الدفع بنجاح',
                    message: 'تم تأكيد الدفع من الإدارة وإتمام الرعاية.',
                  ),
                if (booking.status != 'completed')
                  _buildActionCard(
                    icon: Icons.medical_services_outlined,
                    color: AppColors.primary,
                    title: _careStatusLabel(booking.status),
                    message: 'عند انتهاء الممرض من الرعاية سيظهر هنا زر دفع المستحقات.',
                  ),
                if (booking.status == 'completed') ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/client/rating/${booking.id}'),
                    icon: const Icon(Icons.star_rate),
                    label: const Text('تقييم الممرض'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCareStatus(Booking booking) {
    final Color color;
    final IconData icon;
    switch (booking.status) {
      case 'completed':
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'in_progress':
        color = Colors.purple;
        icon = Icons.medical_services;
        break;
      case 'confirmed':
        color = Colors.blue;
        icon = Icons.event_available;
        break;
      default:
        color = Colors.orange;
        icon = Icons.schedule;
    }

    return Card(
      color: color.withValues(alpha: .10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _careStatusLabel(booking.status),
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 17)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(buttonText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);

  String _careStatusLabel(String status) {
    switch (status) {
      case 'confirmed': return 'تم اختيار الممرض والحجز مؤكد';
      case 'in_progress': return 'الرعاية جارية الآن';
      case 'completed': return 'الممرض أنهى طلب الرعاية';
      default: return 'حالة الرعاية: $status';
    }
  }

  String _paymentLabel(String status) {
    switch (status) {
      case 'unpaid': return 'لم يتم الدفع بعد';
      case 'awaiting_verification': return 'قيد المراجعة';
      case 'verified': return 'تم الدفع بنجاح';
      case 'rejected': return 'مرفوض - يحتاج إعادة السداد';
      default: return status;
    }
  }
}
