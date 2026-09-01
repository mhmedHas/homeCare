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
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (_, i) => _requestCard(_requests[i]),
                        ),
                ),
    );
  }

  Widget _requestCard(CareRequest request) {
    final shortId = request.id.length > 6 ? request.id.substring(0, 6) : request.id;
    final status = _status(request.status);
    final canSeeOffers = request.status == 'open';
    final hasSelectedNurse = request.status == 'booked' ||
        request.status == 'in_progress' ||
        request.status == 'completed';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .55)),
      ),
      child: InkWell(
        onTap: () => context.push('/client/request-details/${request.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.medical_services_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.careType, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text('طلب #$shortId', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              _Badge(text: status.$1, color: status.$2),
            ]),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Icons.location_on_outlined, text: request.governorate),
                _InfoChip(icon: Icons.schedule_outlined, text: '${request.shiftHours} ساعة'),
                _InfoChip(icon: Icons.calendar_today_outlined, text: '${request.daysCount} أيام'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 17, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('تبدأ ${DateFormat('d MMMM yyyy', 'ar').format(request.startDate)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            _ProgressTimeline(status: request.status),
            const SizedBox(height: 14),
            if (canSeeOffers)
              _PrimaryAction(
                icon: Icons.people_outline,
                label: 'عرض الممرضين والعروض',
                onPressed: () => context.push('/client/request-offers/${request.id}'),
              )
            else if (hasSelectedNurse)
              _SecondaryAction(
                icon: Icons.person_search_outlined,
                label: 'عرض الممرض المختار والحجز',
                onPressed: () => context.push('/client/request-offers/${request.id}'),
              )
            else
              _SecondaryAction(
                icon: Icons.visibility_outlined,
                label: 'عرض تفاصيل الطلب',
                onPressed: () => context.push('/client/request-details/${request.id}'),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _empty() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 95),
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .10), shape: BoxShape.circle),
              child: Icon(Icons.assignment_outlined, size: 46, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 18),
          const Center(child: Text('لا توجد طلبات رعاية', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 32), child: Text('أنشئ طلب رعاية ليبدأ الممرضون بتقديم عروضهم.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.5)))),
          const SizedBox(height: 22),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 1),
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _ProgressTimeline extends StatelessWidget {
  final String status;
  const _ProgressTimeline({required this.status});

  int get currentStep {
    switch (status) {
      case 'open': return 1;
      case 'booked': return 2;
      case 'in_progress': return 3;
      case 'completed': return 4;
      case 'cancelled': return -1;
      default: return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: .07), borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [Icon(Icons.cancel_outlined, size: 18, color: AppColors.error), SizedBox(width: 8), Text('تم إلغاء الطلب', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error))]),
      );
    }

    const labels = ['إنشاء الطلب', 'استقبال العروض', 'اختيار الممرض', 'بدء الرعاية', 'إتمام الطلب'];
    return Column(
      children: [
        Row(children: List.generate(labels.length, (index) {
          final step = index + 0;
          final done = step < currentStep;
          final active = step == currentStep;
          final reached = done || active;
          return Expanded(
            child: Row(children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reached ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(color: reached ? AppColors.primary : Theme.of(context).dividerColor),
                ),
                child: Icon(done ? Icons.check : Icons.circle, size: done ? 14 : 7, color: reached ? Colors.white : AppColors.textSecondary),
              ),
              if (index < labels.length - 1)
                Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 3), color: index < currentStep ? AppColors.primary : Theme.of(context).dividerColor)),
            ]),
          );
        })),
        const SizedBox(height: 6),
        Row(children: List.generate(labels.length, (index) => Expanded(child: Text(labels[index], textAlign: index == 0 ? TextAlign.right : index == labels.length - 1 ? TextAlign.left : TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: index <= currentStep ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: index == currentStep ? FontWeight.w700 : FontWeight.normal))))),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _PrimaryAction({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label)),
      );
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _SecondaryAction({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label)),
      );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      );
}
