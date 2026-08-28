import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/care_request_service.dart';
import '../../shared/models/care_request.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  bool _loading = true;
  String? _error;
  List<CareRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final uid = AuthService().currentUser?.uid;
      if (uid == null) throw Exception('auth');
      final requests = await CareRequestService().getClientRequests(uid);
      if (mounted) setState(() { _requests = requests; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'تعذر تحميل طلبات الرعاية'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الرعاية'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _requests.isEmpty
                      ? _empty()
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _card(_requests[i]),
                        ),
                ),
    );
  }

  Widget _card(CareRequest request) {
    final shortId = request.id.length > 6 ? request.id.substring(0, 6) : request.id;
    final status = _status(request.status);
    final canSeeOffers = request.status == 'open';
    final hasSelectedNurse = request.status == 'booked' ||
        request.status == 'in_progress' ||
        request.status == 'completed';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/client/request-details/${request.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.medical_services_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('طلب #$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _Badge(text: status.$1, color: status.$2),
            ]),
            const SizedBox(height: 12),
            Text(request.careType, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 7),
            Text(
              '${request.shiftHours} ساعة × ${request.daysCount} يوم • ${request.governorate} - ${request.area}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 5),
            Text(
              DateFormat('d/M/yyyy', 'ar').format(request.startDate),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (canSeeOffers)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/client/request-offers/${request.id}'),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('عرض الممرضين والعروض'),
                ),
              )
            else if (hasSelectedNurse)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/client/request-offers/${request.id}'),
                  icon: const Icon(Icons.person_search_outlined),
                  label: const Text('عرض الممرض المختار والحجز'),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _empty() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 110),
          const Icon(Icons.post_add_outlined, size: 64),
          const SizedBox(height: 14),
          const Center(child: Text('لا توجد طلبات رعاية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 30), child: Text('أنشئ طلب رعاية ليبدأ الممرضون بتقديم عروضهم.', textAlign: TextAlign.center))),
          const SizedBox(height: 20),
          Center(child: FilledButton.icon(onPressed: () => context.push('/client/create-request'), icon: const Icon(Icons.add), label: const Text('إنشاء طلب رعاية'))),
        ],
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_outlined, size: 52, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
          ]),
        ),
      );

  (String, Color) _status(String value) {
    switch (value) {
      case 'open': return ('مفتوح', AppColors.primary);
      case 'booked': return ('تم اختيار ممرض', Colors.blue);
      case 'in_progress': return ('جاري', Colors.orange);
      case 'completed': return ('مكتمل', Colors.green);
      case 'cancelled': return ('ملغي', AppColors.error);
      default: return ('قيد المراجعة', Colors.grey);
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      );
}
