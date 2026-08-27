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

  @override
  void initState() { super.initState(); _loadRequest(); }

  Future<void> _loadRequest() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final req = await CareRequestService().getRequest(widget.requestId);
      if (req == null || req.clientId != AuthService().currentUser?.uid) throw Exception('not found');
      final offers = await FirebaseFirestore.instance.collection('careOffers').where('requestId', isEqualTo: widget.requestId).where('status', isEqualTo: 'pending').limit(50).get();
      if (mounted) setState(() { _request = req; _offerCount = offers.docs.length; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _errorMessage = 'تعذر تحميل الطلب'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _errorMessage != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_errorMessage!, style: const TextStyle(color: AppColors.error)), const SizedBox(height: 12), FilledButton(onPressed: _loadRequest, child: const Text('إعادة المحاولة'))]))
          : _request == null ? const Center(child: Text('الطلب غير موجود'))
          : ListView(padding: const EdgeInsets.all(16), children: [
              _statusCard(_request!.status),
              const SizedBox(height: 12),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row('الحالة', _request!.patientName), _row('العمر', '${_request!.patientAge} سنة'),
                _row('الجنس', _request!.patientGender == 'male' ? 'ذكر' : 'أنثى'),
                _row('نوع الرعاية', _request!.careType), _row('الشيفت', '${_request!.shiftHours} ساعة × ${_request!.daysCount} يوم'),
                _row('التاريخ', DateFormat('d/M/yyyy').format(_request!.startDate)),
                _row('الوقت', '${_request!.startTime.hour.toString().padLeft(2,'0')}:${_request!.startTime.minute.toString().padLeft(2,'0')}'),
                _row('المحافظة', _request!.governorate), _row('المنطقة', _request!.area), _row('العنوان', _request!.address),
                const SizedBox(height: 8), const Text('الخدمات', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6),
                Wrap(spacing: 6, children: _request!.services.map((s) => Chip(label: Text(s))).toList()),
                if (_request!.notes?.isNotEmpty == true) ...[const SizedBox(height: 8), const Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold)), Text(_request!.notes!)],
              ]))),
              const SizedBox(height: 14),
              if (_request!.status == 'open' || _request!.status == 'matching')
                SizedBox(height: 52, child: FilledButton.icon(onPressed: () => context.push('/client/request-offers/${_request!.id}'), icon: const Icon(Icons.people_outline), label: Text(_offerCount == 0 ? 'انتظار عروض الممرضين' : 'عرض $_offerCount من عروض الممرضين'))),
              if (_request!.status == 'open') ...[const SizedBox(height: 10), OutlinedButton.icon(onPressed: () => context.push('/client/nurse-results/${_request!.id}'), icon: const Icon(Icons.search), label: const Text('استعراض الممرضين'))],
            ]),
    );
  }

  Widget _statusCard(String status) => Card(color: AppColors.primaryLight, child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [const Icon(Icons.info_outline, color: AppColors.primary), const SizedBox(width: 10), Text(_statusLabel(status), style: const TextStyle(fontWeight: FontWeight.bold,color:AppColors.primary))])));
  String _statusLabel(String status) { switch(status) { case 'open': return 'الطلب مفتوح لاستقبال عروض الممرضين'; case 'matching': return 'جاري استقبال عروض الممرضين'; case 'booked': return 'تم اختيار ممرض لهذا الطلب'; case 'in_progress': return 'الرعاية جارية'; case 'completed': return 'تم إكمال الطلب'; case 'cancelled': return 'تم إلغاء الطلب'; default: return status; } }
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width:100, child: Text(label, style: const TextStyle(fontWeight:FontWeight.bold))), Expanded(child: Text(value))]));
}
