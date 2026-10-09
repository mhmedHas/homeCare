import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/support_contact.dart';
import '../../../services/auth_service.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';
import '../../shared/presentation/legal_links.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
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
      final user = AuthService().currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => _errorMessage = 'يرجى تسجيل الدخول');
        }
        return;
      }

      final appUser = await UserService().getUser(user.uid);
      if (mounted) setState(() => _user = appUser);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'حدث خطأ أثناء تحميل بياناتك');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editInfo() async {
    final currentUser = _user;
    if (currentUser == null) return;

    final nameController = TextEditingController(text: currentUser.name);
    final phoneController = TextEditingController(text: currentUser.phone);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('تعديل البيانات الشخصية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('الاسم بالكامل', Icons.person_outline),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('رقم الهاتف', Icons.phone_outlined),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );

    final newName = nameController.text.trim();
    final newPhone = phoneController.text.trim();
    nameController.dispose();
    phoneController.dispose();

    if (saved != true || newName.isEmpty || newPhone.isEmpty) return;

    try {
      await UserService().updateUser(currentUser.uid, {
        'name': newName,
        'phone': newPhone,
      });

      if (!mounted) return;
      setState(() {
        _user = currentUser.copyWith(name: newName, phone: newPhone);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث بياناتك بنجاح')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ البيانات، حاول مرة أخرى')),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('المساعدة'),
          content: const Text(
            'لأي استفسار أو مشكلة في الحجز أو الدفع، تواصل معنا عبر الدعم الفني.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('تمام'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService().logout();
    await SharedPreferencesService().clearTempPreferences();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حسابي', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null || _user == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadUser,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      _buildWelcomeCard(_user!),
                      const SizedBox(height: 24),
                      _buildSectionTitle('حسابك'),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        Icons.person_outline_rounded,
                        'البيانات الشخصية',
                        'الاسم ورقم الهاتف',
                        _editInfo,
                      ),
                      _buildMenuItem(
                        Icons.calendar_month_outlined,
                        'حجوزاتي',
                        'تابع مواعيد الرعاية والحجوزات',
                        () => context.push('/client/my-bookings'),
                      ),
                      _buildMenuItem(
                        Icons.assignment_outlined,
                        'طلباتي',
                        'راجع طلبات الرعاية التي أنشأتها',
                        () => context.push('/client/my-requests'),
                      ),
                      _buildMenuItem(
                        Icons.chat_bubble_outline_rounded,
                        'الرسائل',
                        'تواصل مع مقدم الرعاية',
                        () => context.push('/client/messages'),
                      ),
                      const SizedBox(height: 22),
                      _buildSectionTitle('المساعدة والدعم'),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        Icons.help_outline_rounded,
                        'المساعدة',
                        'إجابات عن الحجز والدفع',
                        _showHelp,
                      ),
                      _buildMenuItem(
                        Icons.support_agent_rounded,
                        'الدعم الفني والشكاوى',
                        'تواصل معنا إذا احتجت إلى مساعدة',
                        () => openSupportWhatsApp(context),
                      ),
                      const SizedBox(height: 8),
                      const LegalLinksCard(),
                      const SizedBox(height: 18),
                      _buildLogoutButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'تعذر تحميل بيانات الحساب',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
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

  Widget _buildWelcomeCard(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF155E75)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أهلاً بيك 👋',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      user.name.trim().isEmpty ? 'حساب العميل' : user.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: Colors.white70, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  user.phone.trim().isEmpty ? 'أضف رقم هاتفك' : user.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: _editInfo,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تعديل'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE8EEF3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppColors.primary, size: 23),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
        trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _logout,
      icon: const Icon(Icons.logout_rounded),
      label: const Text('تسجيل الخروج'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
