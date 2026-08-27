import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  int _offerCount = 0;
  String? _bookingId;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final uid = AuthService().currentUser?.uid;
      final req = await CareRequestService().getRequest(widget.requestId);
      if (req == null || req.clientId != uid) throw Exception('not found');

      final db = FirebaseFirestore.instance;
      final offers = await db.collection('careOffers')
          .where('requestId', isEqualTo: widget.requestId)
          .where('status', isEqualTo: 'pending')
          .limit(50)
          .get();

      String? bookingId;
      if (req.status == 'booked' || req.status == 'in_progress' || req.status == 'completed') {
        final bookings = await db.collection('bookings')
            .where('careRequestId', isEqualTo: widget.requestId)
            .limit(5)
            .get();
        for (final doc in bookings.docs) {
          if (doc.data()['clientId'] == uid) {
            bookingId = doc.id;
            break;
          }
        }
      }

      if (mounted) setState(() {
        _request = req;
        _offerCount = offers.docs.length;
        _bookingId = bookingId;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _errorMessage = 'تعذر تحميل الطلب'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب'), actions: [IconButton(onPressed: _loadRequest, icon: const Icon(Icons.refresh))]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_errorMessage!, style: const TextStyle(color: AppColors.error)), const SizedBox(height: 12), FilledButton(onPressed: _loadRequest, child: const Text('إعادة المحاولة'))]))
              : request == null
                  ? const Center(child: Text('الطلب غير موجود'))
                  : RefreshIndicator(onRefresh: _loadRequest, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
                      _statusCard(request.status),
                      const SizedBox(height: 12),
                      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _row('الحالة', request.patientName),
                        _row('العمر', '${request.patientAge} سنة'),
                        _row('الجنس', request.patientGender == 'male' ? 'ذكر' : 'أنثى'),
                        _row('نوع الرعاية', request.careType),
                        _row('الشيفت', '${request.shiftHours} ساعة × ${request.daysCount} يوم'),
                        _row('التاريخ', DateFormat('d/M/yyyy', 'ar').format(request.startDate)),
                        _row('الوقت', '${request.startTime.hour.toString().padLeft(2, '0')}:${request.startTime.minute.toString().padLeft(2, '0')}'),
                        _row('المحافظة', request.governorate),
                        _row('المنطقة', request.area),
                        _row('العنوان', request.address),
                        const SizedBox(height: 8),
                        const Text('الخدمات', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 6, children: request.services.map((s) => Chip(label: Text(s))).toList()),
                        if (request.notes?.isNotEmpty == true) ...[const SizedBox(height: 8), const Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold)), Text(request.notes!)],
                      ]))),
                      const SizedBox(height: 14),
                      if (request.status == 'open' || request.status == 'matching')
                        SizedBox(height: 52, child: FilledButton.icon(onPressed: () => context.push('/client/request-offers/${request.id}'), icon: const Icon(Icons.people_outline), label: Text(_offerCount == 0 ? 'انتظار عروض الممرضين' : 'عرض $_offerCount من عروض الممرضين'))),
                      if (request.status == 'open') ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(onPressed: () => context.push('/client/nurse-results/${request.id}'), icon: const Icon(Icons.search), label: const Text('استعراض الممرضين')),
                      ],
                      if (_bookingId != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(height: 52, child: FilledButton.icon(onPressed: () => context.push('/client/booking-details/$_bookingId'), icon: const Icon(Icons.calendar_month_outlined), label: const Text('فتح الحجز'))),
                      ],
                    ]),
    );
  }

  Widget _statusCard(String status) => Card(
        color: AppColors.primaryLight,
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [const Icon(Icons.info_outline, color: AppColors.primary), const SizedBox(width: 10), Expanded(child: Text(_statusLabel(status), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)))])),
      );

  String _statusLabel(String status) {
    switch (status) {
      case 'open': return 'الطلب مفتوح لاستقبال عروض الممرضين';
      case 'matching': return 'جاري استقبال عروض الممرضين';
      case 'booked': return 'تم اختيار ممرض لهذا الطلب';
      case 'in_progress': return 'الرعاية جارية';
      case 'completed': return 'تم إكمال الطلب';
      case 'cancelled': return 'تم إلغاء الطلب';
      default: return status;
    }
  }

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))), Expanded(child: Text(value))]));
}
