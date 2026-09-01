import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/care_request_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/care_request.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});
  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  AppUser? _user;
  List<CareRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final firebaseUser = AuthService().currentUser;
      if (firebaseUser == null) throw Exception('auth');
      final results = await Future.wait([
        UserService().getUser(firebaseUser.uid),
        CareRequestService().getClientRequests(firebaseUser.uid),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as AppUser?;
        _requests = results[1] as List<CareRequest>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _errorMessage = 'حدث خطأ في تحميل البيانات';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?.name.trim().isNotEmpty == true ? _user!.name.trim() : 'العميل';
    final active = _requests.where((r) => r.status != 'completed' && r.status != 'cancelled').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _loadHome,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _Header(name: name, onLogout: _logout)),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _HeroCard(onPressed: () => context.push('/client/create-request')),
                            const SizedBox(height: 18),
                            _SectionTitle(title: 'طلبك الحالي', action: active.isNotEmpty ? 'عرض الطلبات' : null, onAction: () => context.go('/client/my-requests')),
                            const SizedBox(height: 10),
                            active.isEmpty ? _NoActiveRequest(onPressed: () => context.push('/client/create-request')) : _ActiveRequest(request: active.first, onTap: () => context.push('/client/request-details/${active.first.id}')),
                            const SizedBox(height: 22),
                            _SectionTitle(title: 'خدماتك'),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: _ServiceCard(icon: Icons.assignment_rounded, title: 'طلباتي', subtitle: '${_requests.length} طلب', onTap: () => context.go('/client/my-requests'))),
                              const SizedBox(width: 12),
                              Expanded(child: _ServiceCard(icon: Icons.calendar_month_rounded, title: 'حجوزاتي', subtitle: 'إدارة الحجوزات', onTap: () => context.go('/client/my-bookings'))),
                            ]),
                            const SizedBox(height: 12),
                            _HelpCard(),
                            if (_requests.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _SectionTitle(title: 'آخر نشاط', action: 'عرض الكل', onAction: () => context.go('/client/my-requests')),
                              const SizedBox(height: 10),
                              ..._requests.take(2).map((r) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _ActivityItem(request: r, onTap: () => context.push('/client/request-details/${r.id}')))),
                            ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        const Text('تعذر تحميل بيانات الصفحة الرئيسية'),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: _loadHome, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
      ]),
    ),
  );
}

class _Header extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;
  const _Header({required this.name, required this.onLogout});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 52, 20, 22),
    decoration: const BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    child: Row(children: [
      Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: Colors.white, size: 27)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('أهلاً بيك 👋', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 2),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
      ])),
      IconButton(onPressed: onLogout, tooltip: 'تسجيل الخروج', icon: const Icon(Icons.logout_rounded, color: Colors.white)),
    ]),
  );
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onPressed;
  const _HeroCard({required this.onPressed});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .18), blurRadius: 18, offset: const Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 27)),
        const Spacer(),
        const Icon(Icons.favorite_rounded, color: Colors.white70, size: 22),
      ]),
      const SizedBox(height: 18),
      const Text('محتاج رعاية منزلية؟', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      const Text('اطلب ممرض مناسب لاحتياجات الحالة، وحدد المواعيد والخدمة بسهولة.', style: TextStyle(color: Colors.white70, height: 1.45, fontSize: 14)),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إنشاء طلب رعاية', style: TextStyle(fontWeight: FontWeight.w800)),
        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
      )),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionTitle({required this.title, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
    if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
  ]);
}

class _NoActiveRequest extends StatelessWidget {
  final VoidCallback onPressed;
  const _NoActiveRequest({required this.onPressed});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.assignment_add, color: AppColors.primary)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('مفيش طلب نشط حالياً', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('ابدأ طلب جديد لو محتاج رعاية', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))])),
      IconButton(onPressed: onPressed, icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary)),
    ]),
  );
}

class _ActiveRequest extends StatelessWidget {
  final CareRequest request;
  final VoidCallback onTap;
  const _ActiveRequest({required this.request, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final status = _status(request.status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.medical_services_rounded, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.careType, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text('لـ ${request.patientName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))])),
            _StatusChip(text: status.$1, color: status.$2),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            _Info(icon: Icons.schedule_rounded, text: '${request.shiftHours} ساعة'),
            const SizedBox(width: 18),
            _Info(icon: Icons.calendar_today_rounded, text: '${request.daysCount} يوم'),
            const SizedBox(width: 18),
            Expanded(child: _Info(icon: Icons.location_on_outlined, text: request.governorate.isEmpty ? 'غير محدد' : request.governorate)),
          ]),
        ]),
      )),
    );
  }

  static (String, Color) _status(String value) {
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

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ServiceCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 45, height: 45, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: AppColors.primary)),
        const SizedBox(height: 13),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 4),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ]),
    )),
  );
}

class _HelpCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.support_agent_rounded, color: Colors.orange)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('محتاج مساعدة؟', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('نحن هنا لمساعدتك في أي خطوة', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))])),
      const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
    ]),
  );
}

class _ActivityItem extends StatelessWidget {
  final CareRequest request;
  final VoidCallback onTap;
  const _ActivityItem({required this.request, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        const Icon(Icons.history_rounded, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(request.careType, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(DateFormat('d/M/yyyy', 'ar').format(request.startDate), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ])),
        const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
      ]),
    )),
  );
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Info({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: AppColors.textSecondary), const SizedBox(width: 5), Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)))]);
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)));
}
