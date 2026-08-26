import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/care_request_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/auth_service.dart';
import '../../shared/models/care_request.dart';
import '../../shared/models/booking.dart';

class RequestDetailsNurseScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailsNurseScreen({super.key, required this.requestId});

  @override
  State<RequestDetailsNurseScreen> createState() =>
      _RequestDetailsNurseScreenState();
}

class _RequestDetailsNurseScreenState extends State<RequestDetailsNurseScreen> {
  CareRequest? _request;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final req = await CareRequestService().getRequest(widget.requestId);
      if (req == null) {
        setState(() {
          _errorMessage = 'الطلب غير موجود';
        });
        return;
      }
      if (req.status != 'open') {
        setState(() {
          _errorMessage = 'هذا الطلب غير متاح حالياً';
        });
        return;
      }
      setState(() {
        _request = req;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في تحميل الطلب';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest() async {
    setState(() {
      _isAccepting = true;
      _errorMessage = null;
    });
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول';
        });
        return;
      }

      // Check if still open using transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docRef = FirebaseFirestore.instance
            .collection('careRequests')
            .doc(widget.requestId);
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data()!['status'] != 'open') {
          throw Exception('الطلب غير متاح حالياً');
        }

        // Update request status
        transaction.update(docRef, {
          'status': 'matching',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Create booking
      final pricePerHour =
          100.0; // Placeholder - should come from nurse profile
      final total = pricePerHour * _request!.shiftHours * _request!.daysCount;
      final fee = total * 0.10;

      final booking = Booking(
        id: '',
        clientId: _request!.clientId,
        nurseId: user.uid,
        careRequestId: _request!.id,
        shiftStart: _request!.startDate,
        shiftEnd:
            _request!.startDate.add(Duration(hours: _request!.shiftHours)),
        shiftHours: _request!.shiftHours,
        pricePerHour: pricePerHour,
        platformFee: fee,
        totalAmount: total + fee,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await BookingService().createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم قبول الطلب بنجاح')));
        context.go('/nurse/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isAccepting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text(_errorMessage!,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadRequest,
                          child: const Text('إعادة المحاولة')),
                    ]))
              : _request == null
                  ? const Center(child: Text('الطلب غير موجود'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('الحالة', _request!.patientName),
                          _buildInfoRow('العمر', '${_request!.patientAge} سنة'),
                          _buildInfoRow(
                              'الجنس',
                              _request!.patientGender == 'male'
                                  ? 'ذكر'
                                  : 'أنثى'),
                          _buildInfoRow('نوع الرعاية', _request!.careType),
                          _buildInfoRow(
                              'عدد الساعات', '${_request!.shiftHours} ساعة'),
                          _buildInfoRow(
                              'عدد الأيام', '${_request!.daysCount} يوم'),
                          _buildInfoRow('التاريخ',
                              DateFormat.yMMMd().format(_request!.startDate)),
                          _buildInfoRow('الوقت',
                              '${_request!.startTime.hour}:${_request!.startTime.minute}'),
                          _buildInfoRow('المحافظة', _request!.governorate),
                          _buildInfoRow('المنطقة', _request!.area),
                          const SizedBox(height: 8),
                          const Text('الخدمات:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Wrap(
                            children: _request!.services
                                .map((s) => Chip(label: Text(s)))
                                .toList(),
                          ),
                          if (_request!.notes != null) ...[
                            const SizedBox(height: 8),
                            const Text('ملاحظات:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(_request!.notes!),
                          ],
                          const Spacer(),
                          if (_errorMessage != null)
                            Text(_errorMessage!,
                                style: const TextStyle(color: AppColors.error)),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isAccepting ? null : _acceptRequest,
                              child: _isAccepting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text('قبول الطلب'),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
