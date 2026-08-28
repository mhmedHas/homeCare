import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/review_service.dart';
import '../../shared/models/booking.dart';

class RatingScreen extends StatefulWidget {
  final String bookingId;
  const RatingScreen({super.key, required this.bookingId});
  @override State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _loading = true, _submitting = false;
  String? _error;
  Booking? _booking;

  @override void initState() { super.initState(); _loadBooking(); }
  Future<void> _loadBooking() async {
    try {
      final booking = await BookingService().getBooking(widget.bookingId);
      if (!mounted) return;
      setState(() { _booking = booking; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'تعذر تحميل الحجز'; _loading = false; });
    }
  }
  Future<void> _submitRating() async {
    if (_rating == 0) { setState(() => _error = 'اختر عدد النجوم أولاً'); return; }
    final user = AuthService().currentUser;
    final booking = _booking;
    if (user == null || booking == null) { setState(() => _error = 'بيانات الحجز غير مكتملة'); return; }
    if (booking.status != 'completed') { setState(() => _error = 'يمكن تقييم الممرض بعد انتهاء الرعاية'); return; }
    setState(() { _submitting = true; _error = null; });
    try {
      await ReviewService().submitReview(bookingId: booking.id, clientId: user.uid, nurseId: booking.nurseId, rating: _rating, comment: _commentController.text);
      if (mounted) context.go('/client/my-bookings');
    } catch (e) {
      if (mounted) setState(() => _error = e is StateError ? e.message : 'تعذر حفظ التقييم');
    } finally { if (mounted) setState(() => _submitting = false); }
  }
  @override void dispose() { _commentController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('تقييم الممرض')),
      body: _booking == null ? Center(child: Text(_error ?? 'الحجز غير موجود')) : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.workspace_premium_outlined, size: 64, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text('كيف كانت تجربتك مع الممرض؟', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
            tooltip: '${i + 1} نجوم', icon: Icon(i < _rating ? Icons.star : Icons.star_border, size: 42, color: AppColors.primary),
            onPressed: _submitting ? null : () => setState(() { _rating = i + 1; _error = null; }),
          ))),
          if (_rating > 0) Center(child: Text('$_rating من 5 نجوم', style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 20),
          TextField(controller: _commentController, maxLines: 4, maxLength: 500, decoration: const InputDecoration(labelText: 'تعليقك (اختياري)', hintText: 'اكتب تجربتك مع الممرض', border: OutlineInputBorder())),
          if (_error != null) ...[const SizedBox(height: 8), Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error))],
          const SizedBox(height: 18),
          SizedBox(height: 52, child: FilledButton(onPressed: _submitting ? null : _submitRating, child: _submitting ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('إرسال التقييم'))),
        ],
      ),
    );
  }
}
