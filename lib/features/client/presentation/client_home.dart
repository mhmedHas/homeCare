import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  AppUser? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final firebaseUser = AuthService().currentUser;
      if (firebaseUser == null) {
        if (mounted) {
          setState(() => _errorMessage = 'يرجى تسجيل الدخول');
        }
        return;
      }

      final appUser = await UserService().getUser(firebaseUser.uid);
      if (appUser == null) {
        if (mounted) {
          setState(() => _errorMessage = 'بيانات المستخدم غير مكتملة');
        }
        return;
      }

      if (mounted) {
        setState(() => _user = appUser);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'حدث خطأ في تحميل البيانات');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _buildBody(context, theme, colorScheme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadUser,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final name = _user?.name.trim().isNotEmpty == true
        ? _user!.name.trim()
        : 'العميل';

    return RefreshIndicator(
      onRefresh: _loadUser,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _WelcomeCard(name: name),
          const SizedBox(height: 16),
          _RequestCareCard(
            onPressed: () => context.push('/client/create-request'),
          ),
          const SizedBox(height: 24),
          Text(
            'الوصول السريع',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.calendar_month_outlined,
                  title: 'حجوزاتي',
                  onTap: () => context.go('/client/my-bookings'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.chat_bubble_outline,
                  title: 'الرسائل',
                  onTap: () => context.go('/client/messages'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'الحجوزات القادمة',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.go('/client/my-bookings'),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      child: Icon(Icons.event_available_outlined),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'لا توجد حجوزات حالية',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text('عند وجود حجز سيظهر هنا تلقائيًا.'),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_left),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'كيف نساعدك؟',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اطلب مقدم رعاية مناسب حسب احتياجات الحالة والوقت والمنطقة.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;

  const _WelcomeCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.person_outline, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أهلاً يا $name 👋',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text('إحنا هنا عشان نسهّل عليك رعاية الحالة في البيت.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCareCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _RequestCareCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.medical_services_outlined, size: 34),
            const SizedBox(height: 12),
            Text(
              'محتاج ممرض؟',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'أنشئ طلب رعاية وحدد احتياجات الحالة، وبعدها اختار مقدم الرعاية المناسب.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('اطلب رعاية'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
