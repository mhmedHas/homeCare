import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/care_request_service.dart';
import '../../../services/auth_service.dart';
import '../../shared/models/care_request.dart';

class RequestDetailsScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailsScreen({super.key, required this.requestId});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  CareRequest? _request;
  bool _isLoading = true;
  String? _errorMessage;

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
      if (req == null || req.clientId != AuthService().currentUser?.uid) {
        setState(() {
          _errorMessage = 'الطلب غير موجود';
        });
      } else {
        setState(() {
          _request = req;
        });
      }
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
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_request!.status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_getStatusLabel(_request!.status),
                                style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: 16),
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
                          _buildInfoRow('العنوان', _request!.address),
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
                          if (_request!.status == 'open')
                            ElevatedButton.icon(
                              onPressed: () {
                                // Go to nurse search
                                context.go(
                                    '/client/nurse-results/${_request!.id}');
                              },
                              icon: const Icon(Icons.search),
                              label: const Text('البحث عن ممرض'),
                            ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'matching':
        return Colors.orange;
      case 'booked':
        return Colors.green;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'مفتوح';
      case 'matching':
        return 'جاري البحث';
      case 'booked':
        return 'محجوز';
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
