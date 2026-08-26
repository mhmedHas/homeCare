import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
import '../../shared/models/booking.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Booking? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String _selectedMethod = 'card';

  final List<PaymentMethod> _methods = [
    PaymentMethod(
        id: 'card', label: 'بطاقة ائتمان/خصم', icon: Icons.credit_card),
    PaymentMethod(id: 'fawry', label: 'فوري', icon: Icons.qr_code),
    PaymentMethod(id: 'cash', label: 'كاش عند الحضور', icon: Icons.money),
  ];

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
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

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      // For MVP, we'll simulate payment and update booking status
      await Future.delayed(const Duration(seconds: 2));

      // Update booking to confirmed
      await BookingService().updateBookingStatus(widget.bookingId, 'confirmed');

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الدفع بنجاح')));
        context.go('/client/booking-details/${_booking!.id}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل الدفع. حاول مرة أخرى.';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدفع')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null || _booking == null
              ? Center(child: Text(_errorMessage ?? 'غير موجود'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تفاصيل الدفع',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildSummaryRow('سعر الخدمة',
                          '${_booking!.totalAmount - _booking!.platformFee} ج.م'),
                      _buildSummaryRow(
                          'رسوم المنصة', '${_booking!.platformFee} ج.م'),
                      const Divider(),
                      _buildSummaryRow(
                          'الإجمالي', '${_booking!.totalAmount} ج.م',
                          isTotal: true),
                      const SizedBox(height: 24),
                      const Text('طريقة الدفع',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._methods.map((method) => RadioListTile<String>(
                            title: Row(
                              children: [
                                Icon(method.icon, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(method.label),
                              ],
                            ),
                            value: method.id,
                            groupValue: _selectedMethod,
                            onChanged: (v) =>
                                setState(() => _selectedMethod = v!),
                          )),
                      const Spacer(),
                      if (_errorMessage != null)
                        Text(_errorMessage!,
                            style: const TextStyle(color: AppColors.error)),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _processPayment,
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('دفع الآن'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

class PaymentMethod {
  final String id;
  final String label;
  final IconData icon;
  PaymentMethod({required this.id, required this.label, required this.icon});
}
