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

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  static const criteria = <String, String>{
    'punctuality': 'الالتزام بالمواعيد',
    'behavior': 'التعامل والأخلاق',
    'cleanliness': 'النظافة',
    'careQuality': 'جودة الرعاية',
    'communication': 'التواصل',
  };

  final ratings = <String, int>{
    'punctuality': 0,
    'behavior': 0,
    'cleanliness': 0,
    'careQuality': 0,
    'communication': 0,
  };

  final _commentController = TextEditingController();
  Booking? _booking;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await BookingService().getBooking(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل الحجز';
        _loading = false;
      });
    }
  }

  bool get _allRated => ratings.values.every((value) => value >= 1 && value <= 5);

  double get _average {
    final total = ratings.values.fold<int>(0, (sum, value) => sum + value);
    return total / ratings.length;
  }

  Future<void> _submitRating() async {
    if (!_allRated) {
      setState(() => _error = 'من فضلك قيّم جميع البنود الخمسة');
      return;
    }

    final user = AuthService().currentUser;
    final booking = _booking;

    if (user == null || booking == null) {
      setState(() => _error = 'بيانات الحجز غير مكتملة');
      return;
    }

    if (booking.status != 'completed') {
      setState(() => _error = 'يمكن تقييم الممرض بعد انتهاء الرعاية');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ReviewService().submitReview(
        bookingId: booking.id,
        clientId: user.uid,
        nurseId: booking.nurseId,
        ratings: ratings,
        comment: _commentController.text,
      );

      if (mounted) context.go('/client/payment/${booking.id}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is StateError ? e.message : 'تعذر حفظ التقييم';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _booking;

    return Scaffold(
      appBar: AppBar(title: const Text('تقييم الممرض')),
      body: booking == null
          ? Center(child: Text(_error ?? 'الحجز غير موجود'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.rate_review_outlined,
                          size: 54,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'كيف كانت تجربتك مع الممرض؟',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'قيّم كل جانب من جوانب تجربة الرعاية.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: criteria.entries
                          .map(
                            (entry) => _CriterionRow(
                              title: entry.value,
                              rating: ratings[entry.key] ?? 0,
                              enabled: !_submitting,
                              onChanged: (value) {
                                setState(() {
                                  ratings[entry.key] = value;
                                  _error = null;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_allRated)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'متوسط تقييمك: ' + _average.toStringAsFixed(1) + ' من 5',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (_allRated) const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'تعليقك (اختياري)',
                        hintText: 'اكتب تجربتك مع الممرض',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submitRating,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'إرسال التقييم',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final String title;
  final int rating;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _CriterionRow({
    required this.title,
    required this.rating,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (index) {
                final value = index + 1;
                return IconButton(
                  onPressed: enabled ? () => onChanged(value) : null,
                  tooltip: value.toString() + ' نجوم',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    value <= rating ? Icons.star : Icons.star_border,
                    size: 32,
                    color: AppColors.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
