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
  void initState() { super.initState(); _loadHome(); }

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
      if (mounted) setState(() { _errorMessage = 'حدث خطأ في تحميل البيانات'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _user?.name.trim().isNotEmpty == true ? _user!.name.trim() : 'العميل';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج', icon: const Icon(Icons.logout_outlined),
            onPressed: () async { await AuthService().logout(); if (context.mounted) context.go('/login'); },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _errorView(theme)
              : RefreshIndicator(
                  onRefresh: _loadHome,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _WelcomeCard(name: name),
                      const SizedBox(height: 16),
                      _RequestCareCard(onPressed: () => context.push('/client/create-request')),
                      const SizedBox(height: 16),
                      _RequestsShortcut(
                        count: _requests.length,
                        onPressed: () => context.go('/client/my-requests'),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _QuickAction(icon: Icons.calendar_month_outlined, title: 'حجوزاتي', onTap: () => context.go('/client/my-bookings'))),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickAction(icon: Icons.chat_bubble_outline, title: 'الرسائل', onTap: () => context.go('/client/messages'))),
                      ]),
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(child: Text('آخر طلبات الرعاية', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
                        if (_requests.isNotEmpty) TextButton(onPressed: () => context.go('/client/my-requests'), child: const Text('عرض الكل')),
                      ]),
                      const SizedBox(height: 8),
                      if (_requests.isEmpty) _emptyRequests() else ..._requests.take(3).map(_requestCard),
                    ],
                  ),
                ),
    );
  }

  Widget _errorView(ThemeData theme) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.cloud_off_outlined, size: 48, color: theme.colorScheme.error),
      const SizedBox(height: 12), Text(_errorMessage!, textAlign: TextAlign.center), const SizedBox(height: 16),
      FilledButton.icon(onPressed: _loadHome, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
    ]),
  ));

  Widget _emptyRequests() => Card(margin: EdgeInsets.zero, child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(children: [
      const Icon(Icons.post_add_outlined, size: 42), const SizedBox(height: 8),
      const Text('لسه مفيش طلبات رعاية'), const SizedBox(height: 10),
      OutlinedButton(onPressed: () => context.push('/client/create-request'), child: const Text('إنشاء طلب')),
    ]),
  ));

  Widget _requestCard(CareRequest request) {
    final status = _status(request.status);
    return Card(margin: const EdgeInsets.only(bottom: 10), child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/client/request-details/${request.id}'),
      child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
        CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.medical_services_outlined, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(request.careType, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4),
          Text('${request.shiftHours} ساعة × ${request.daysCount} يوم • ${request.governorate}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 3), Text(DateFormat('d/M/yyyy', 'ar').format(request.startDate), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        _Badge(text: status.$1, color: status.$2),
      ])),
    ));
  }

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

class _WelcomeCard extends StatelessWidget {
  final String name;
  const _WelcomeCard({required this.name});
  @override
  Widget build(BuildContext context) => Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
    const CircleAvatar(radius: 28, child: Icon(Icons.person_outline, size: 30)), const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('أهلاً يا $name 👋', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4), const Text('إحنا هنا عشان نسهّل عليك رعاية الحالة في البيت.'),
    ])),
  ])));
}

class _RequestCareCard extends StatelessWidget {
  final VoidCallback onPressed;
  const _RequestCareCard({required this.onPressed});
  @override
  Widget build(BuildContext context) => Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.medical_services_outlined, size: 34), const SizedBox(height: 12),
    Text('محتاج ممرض؟', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 6), const Text('أنشئ طلب رعاية وحدد احتياجات الحالة، وبعدها اختار مقدم الرعاية المناسب.'), const SizedBox(height: 16),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onPressed, icon: const Icon(Icons.add_circle_outline), label: const Text('اطلب رعاية'))),
  ])));
}

class _RequestsShortcut extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;
  const _RequestsShortcut({required this.count, required this.onPressed});
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(16), onTap: onPressed,
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.assignment_outlined)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('طلبات الرعاية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('تابع طلباتك وشوف عروض الممرضين واختار المناسب', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)), child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800))),
        const SizedBox(width: 4), const Icon(Icons.chevron_left),
      ]),),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(margin: EdgeInsets.zero, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 25), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w700))]))));
}

class _Badge extends StatelessWidget {
  final String text; final Color color;
  const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
}
