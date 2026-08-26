import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/user_service.dart';
import '../../../services/care_request_service.dart';
import '../../../services/booking_service.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/booking.dart';

class NurseProfileScreen extends StatefulWidget {
  final String nurseId;
  final String requestId;
  const NurseProfileScreen(
      {super.key, required this.nurseId, required this.requestId});

  @override
  State<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  AppUser? _nurse;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNurse();
  }

  Future<void> _loadNurse() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await UserService().getUser(widget.nurseId);
      if (user == null || user.role != 'nurse') {
        setState(() {
          _errorMessage = 'الممرض غير موجود';
        });
      } else {
        setState(() {
          _nurse = user;
        });
      }
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

  Future<void> _bookNow() async {
    // For MVP: Create a booking directly with dummy price
    try {
      final request = await CareRequestService().getRequest(widget.requestId);
      if (request == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('الطلب غير موجود')));
        return;
      }

      final pricePerHour = 100.0; // Placeholder
      final total = pricePerHour * request.shiftHours * request.daysCount;
      final fee = total * 0.10;

      final booking = Booking(
        id: '',
        clientId: request.clientId,
        nurseId: widget.nurseId,
        careRequestId: request.id,
        shiftStart: request.startDate,
        shiftEnd: request.startDate.add(Duration(hours: request.shiftHours)),
        shiftHours: request.shiftHours,
        pricePerHour: pricePerHour,
        platformFee: fee,
        totalAmount: total + fee,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bookingId = await BookingService().createBooking(booking);
      await CareRequestService().updateRequestStatus(request.id, 'booked');

      if (mounted) {
        context.go('/client/booking-confirmation/$bookingId');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملف الممرض')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null || _nurse == null
              ? Center(child: Text(_errorMessage ?? 'غير موجود'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary,
                        child: Text(
                            _nurse!.name.isNotEmpty ? _nurse!.name[0] : '?',
                            style: const TextStyle(
                                fontSize: 40, color: Colors.white)),
                      ),
                      const SizedBox(height: 8),
                      Text(_nurse!.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      if (_nurse!.isVerified)
                        const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified, color: AppColors.success),
                              SizedBox(width: 4),
                              Text('موثق',
                                  style: TextStyle(color: AppColors.success)),
                            ]),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('⭐⭐⭐', '4.5'),
                          _buildStat('🕒', '5 سنوات'),
                          _buildStat('💰', '١٠٠ ج/س'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('الخدمات:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Wrap(
                        children: [
                          Chip(label: Text('متابعة الحالة')),
                          Chip(label: Text('إعطاء الأدوية')),
                          Chip(label: Text('قياس الضغط')),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _bookNow,
                        icon: const Icon(Icons.book_online),
                        label: const Text('احجز معاه'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50)),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStat(String icon, String value) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 24)),
      Text(value)
    ]);
  }
}
