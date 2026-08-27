import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/models/care_request.dart';

class AvailableRequestsScreen extends StatefulWidget {
  const AvailableRequestsScreen({super.key});
  @override
  State<AvailableRequestsScreen> createState() => _AvailableRequestsScreenState();
}

class _AvailableRequestsScreenState extends State<AvailableRequestsScreen> {
  List<CareRequest> _requests = [];
  List<String> _areas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('auth');
      final profile = await FirebaseFirestore.instance.collection('nurseProfiles').doc(uid).get();
      final values = profile.data()?['preferredGovernorates'];
      _areas = values is List ? values.map((e) => e.toString()).toList() : [];

      if (_areas.isEmpty) {
        setState(() { _requests = []; _loading = false; });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('careRequests')
          .where('status', isEqualTo: 'open')
          .where('governorate', whereIn: _areas.take(30).toList())
          .limit(50)
          .get();
      final requests = snapshot.docs.map(CareRequest.fromFirestore).toList();
      requests.sort((a, b) => a.startDate.compareTo(b.startDate));
      if (mounted) setState(() { _requests = requests; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'تعذر تحميل الطلبات المناسبة لمناطق عملك'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات مناسبة لي'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) return _state(Icons.error_outline, _error!, 'إعادة المحاولة', _load);
    if (_areas.isEmpty) return _state(Icons.location_city, 'حدد محافظة واحدة على الأقل من إعدادات العمل أولاً', 'إعدادات العمل', () => context.push('/nurse/settings'));
    if (_requests.isEmpty) return _state(Icons.search_off, 'لا توجد طلبات مفتوحة في المحافظات التي اخترتها حالياً', 'تعديل المحافظات', () => context.push('/nurse/settings'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _requestCard(_requests[i]),
      ),
    );
  }

  Widget _requestCard(CareRequest request) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/nurse/request-details/${request.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.person_outline, color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: Text('طلب رعاية #${request.id.substring(0, request.id.length > 6 ? 6 : request.id.length)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              const Icon(Icons.chevron_left),
            ]),
            const SizedBox(height: 12),
            Text(request.careType, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 8, children: [
              _info(Icons.location_on_outlined, '${request.governorate} - ${request.area}'),
              _info(Icons.schedule, '${request.shiftHours} ساعة'),
              _info(Icons.calendar_today_outlined, DateFormat('d/M/yyyy').format(request.startDate)),
            ]),
            if (request.services.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(request.services.take(3).join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: AppColors.textSecondary), const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))]);

  Widget _state(IconData icon, String title, String button, VoidCallback action) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 56, color: AppColors.textSecondary), const SizedBox(height: 14), Text(title, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: action, icon: const Icon(Icons.arrow_back), label: Text(button))])));
}
