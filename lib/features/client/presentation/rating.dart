import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingScreen extends StatefulWidget {
  final String bookingId;
  const RatingScreen({super.key, required this.bookingId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _nurseId;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final booking = await BookingService().getBooking(widget.bookingId);
    if (booking != null) {
      setState(() {
        _nurseId = booking.nurseId;
      });
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      setState(() {
        _errorMessage = 'يرجى اختيار تقييم';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = AuthService().currentUser;
      if (user == null || _nurseId == null)
        throw Exception('بيانات غير مكتملة');

      final review = Review(
        id: '',
        bookingId: widget.bookingId,
        clientId: user.uid,
        nurseId: _nurseId!,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('reviews')
          .add(review.toMap());
      // Update booking status if needed
      if (mounted) context.go('/client/my-bookings');
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في حفظ التقييم';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقييم الممرض')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 60, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('كيف كانت تجربتك مع الممرض؟',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(index < _rating ? Icons.star : Icons.star_border,
                        size: 40, color: AppColors.primary),
                    onPressed: () => setState(() {
                      _rating = index + 1;
                      _errorMessage = null;
                    }),
                  );
                })),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'اكتب تعليقاً (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(_errorMessage!,
                  style: const TextStyle(color: AppColors.error)),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRating,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('إرسال التقييم'),
            ),
          ],
        ),
      ),
    );
  }
}
