import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/booking.dart';
import '../../shared/models/app_user.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String bookingId;
  const BookingConfirmationScreen({super.key, required this.bookingId});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  Booking? _booking;
  AppUser? _nurse;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final booking = await BookingService().getBooking(widget.bookingId);
      if (booking == null) {
        setState(() {
          _errorMessage = 'الحجز غير موجود';
        });
        return;
      }
      setState(() {
        _booking = booking;
      });

      final nurse = await UserService().getUser(booking.nurseId);
      setState(() {
        _nurse = nurse;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ';
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
      appBar: AppBar(title: const Text('تأكيد الحجز')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null || _booking == null
              ? Center(child: Text(_errorMessage ?? 'غير موجود'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                          child: Icon(Icons.check_circle,
                              color: AppColors.success, size: 80)),
                      const SizedBox(height: 16),
                      Center(
                          child: Text('تم إنشاء الحجز بنجاح',
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      const SizedBox(height: 24),
                      _buildInfoRow('الممرض', _nurse?.name ?? 'غير معروف'),
                      _buildInfoRow(
                          'عدد الساعات', '${_booking!.shiftHours} ساعة'),
                      _buildInfoRow(
                          'سعر الساعة', '${_booking!.pricePerHour} ج.م'),
                      _buildInfoRow(
                          'رسوم الخدمة', '${_booking!.platformFee} ج.م'),
                      Divider(thickness: 2, color: Colors.grey.shade300),
                      _buildInfoRow('الإجمالي', '${_booking!.totalAmount} ج.م',
                          isTotal: true),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => context
                            .go('/client/booking-details/${_booking!.id}'),
                        icon: const Icon(Icons.visibility),
                        label: const Text('عرض تفاصيل الحجز'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50)),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 16)),
        ],
      ),
    );
  }
}
