import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
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
      appBar: AppBar(title: const Text('تفاصيل الحجز')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null || _booking == null
              ? Center(child: Text(_errorMessage ?? 'غير موجود'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_booking!.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_getStatusLabel(_booking!.status),
                            style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('رقم الحجز', _booking!.id),
                      _buildInfoRow('الممرض', _nurse?.name ?? 'غير معروف'),
                      _buildInfoRow('التاريخ',
                          DateFormat.yMMMd().format(_booking!.shiftStart)),
                      _buildInfoRow('الوقت',
                          DateFormat.jm().format(_booking!.shiftStart)),
                      _buildInfoRow('المدة', '${_booking!.shiftHours} ساعة'),
                      _buildInfoRow('السعر', '${_booking!.totalAmount} ج.م'),
                      _buildInfoRow('حالة الدفع', _booking!.paymentStatus),
                      const Spacer(),
                      if (_booking!.status == 'confirmed' ||
                          _booking!.status == 'in_progress')
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.go('/client/chat/${_booking!.id}'),
                          icon: const Icon(Icons.chat),
                          label: const Text('التواصل مع الممرض'),
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50)),
                        ),
                      if (_booking!.status == 'completed')
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.go('/client/rating/${_booking!.id}'),
                          icon: const Icon(Icons.star_rate),
                          label: const Text('تقييم الممرض'),
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50)),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, textAlign: TextAlign.end)),
      ]),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'في انتظار الدفع';
      case 'confirmed':
        return 'مؤكد';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}
