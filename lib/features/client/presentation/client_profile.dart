import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
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
      var user = AuthService().currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => _errorMessage = 'يرجى تسجيل الدخول');
        }
        return;
      }

      // Refresh the Firebase user so a verified email change is reflected.
      try {
        await user.reload();
        user = AuthService().currentUser;
      } catch (_) {
        // Keep the signed-in session usable if refresh temporarily fails.
      }
      final appUser = await UserService().getUser(user!.uid);
      if (appUser != null &&
          (user.email ?? '').trim().isNotEmpty &&
          (user.email ?? '').trim().toLowerCase() !=
              (appUser.email ?? '').trim().toLowerCase()) {
        await UserService().updateUser(user.uid, {'email': user.email});
      }
      if (mounted) {
        setState(() => _user = appUser == null
            ? null
            : appUser.copyWith(email: user!.email ?? appUser.email));
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'حدث خطأ أثناء تحميل بياناتك');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final current = _user;
    final authUser = AuthService().currentUser;
    if (current == null || authUser == null) return;

    final nameController = TextEditingController(text: current.name);
    final phoneController = TextEditingController(text: current.phone);
    final emailController =
        TextEditingController(text: authUser.email ?? current.email ?? '');

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9E1E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'تعديل بياناتك',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'حدّث بيانات التواصل الخاصة بحسابك.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _editField(
                    controller: nameController,
                    label: 'الاسم بالكامل',
                    icon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 12),
                  _editField(
                    controller: phoneController,
                    label: 'رقم الهاتف',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _editField(
                    controller: emailController,
                    label: 'البريد الإلكتروني',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.mark_email_unread_outlined,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'تغيير البريد الإلكتروني يحتاج إلى تأكيد من رسالة تصلك على البريد الجديد.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext, false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(sheetContext, true),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('حفظ التعديلات'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final newName = nameController.text.trim();
    final newPhone = phoneController.text.trim();
    final newEmail = emailController.text.trim();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();

    if (shouldSave != true) return;
    if (newName.isEmpty || newPhone.isEmpty || newEmail.isEmpty) {
      _showMessage('من فضلك اكتب الاسم ورقم الهاتف والبريد الإلكتروني.');
      return;
    }
    if (!RegExp(r'^[^\\s@]+@[^\\s@]+\\.[^\\s@]+
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
                      const SizedBox(height: 16),
                      _buildProfileDetailsCard(_user!),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8EEF3)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_user_outlined,
                                color: AppColors.primary, size: 25),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'خصوصيتك وأمانك',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'نهتم بخصوصية بياناتك ونوفر لك تجربة استخدام بسيطة وآمنة.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const LegalLinksCard(),
                      const SizedBox(height: 20),
                      _buildLogoutButton(),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          'شفاء • رعاية أقرب واطمئنان أكبر',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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

  Widget _buildProfileDetailsCard(AppUser user) {
    final authEmail = AuthService().currentUser?.email;
    final email = (authEmail ?? user.email ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECF1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'بيانات الحساب',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('تعديل'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _profileDetail(
            icon: Icons.person_outline_rounded,
            label: 'الاسم',
            value: user.name.trim().isEmpty ? 'لم يتم إضافة الاسم' : user.name,
          ),
          const Divider(height: 22, color: Color(0xFFEAF0F4)),
          _profileDetail(
            icon: Icons.phone_outlined,
            label: 'رقم الهاتف',
            value: user.phone.trim().isEmpty ? 'لم يتم إضافة رقم الهاتف' : user.phone,
          ),
          const Divider(height: 22, color: Color(0xFFEAF0F4)),
          _profileDetail(
            icon: Icons.email_outlined,
            label: 'البريد الإلكتروني',
            value: email.isEmpty ? 'لم يتم إضافة البريد الإلكتروني' : email,
          ),
        ],
      ),
    );
  }

  Widget _profileDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
          const Row(
            children: [
              Icon(Icons.favorite_border_rounded, color: Colors.white70, size: 19),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'رعاية منزلية أقرب ليك وراحة بال لأسرتك',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
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
).hasMatch(newEmail)) {
      _showMessage('صيغة البريد الإلكتروني غير صحيحة.');
      return;
    }

    try {
      await UserService().updateUser(current.uid, {
        'name': newName,
        'phone': newPhone,
      });
      if (!mounted) return;
      setState(() {
        _user = current.copyWith(name: newName, phone: newPhone);
      });

      final currentEmail = (authUser.email ?? '').trim().toLowerCase();
      if (newEmail.toLowerCase() != currentEmail) {
        try {
          await authUser.verifyBeforeUpdateEmail(newEmail);
          _showMessage(
            'تم حفظ الاسم ورقم الهاتف. ابعتنا رسالة تأكيد للبريد الجديد؛ افتحها لإكمال تغيير الإيميل.',
          );
        } on FirebaseAuthException catch (e) {
          _showMessage(_emailErrorMessage(e.code));
        }
      } else {
        _showMessage('تم تحديث بياناتك بنجاح.');
      }
    } catch (_) {
      _showMessage('تعذر حفظ البيانات. تأكد من الاتصال بالإنترنت وحاول مرة أخرى.');
    }
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: TextDirection.ltr == Directionality.of(context)
          ? TextDirection.ltr
          : (keyboardType == TextInputType.emailAddress ||
                  keyboardType == TextInputType.phone
              ? TextDirection.ltr
              : TextDirection.rtl),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String _emailErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح.';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل في حساب آخر.';
      case 'requires-recent-login':
        return 'لأمان حسابك، سجّل الدخول مرة أخرى ثم حاول تغيير البريد.';
      case 'network-request-failed':
        return 'مشكلة في الاتصال بالإنترنت. حاول مرة أخرى.';
      default:
        return 'تعذر إرسال تأكيد البريد الإلكتروني. حاول مرة أخرى.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textDirection: TextDirection.rtl),
          behavior: SnackBarBehavior.floating,
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
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8EEF3)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_user_outlined,
                                color: AppColors.primary, size: 25),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'خصوصيتك وأمانك',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'نهتم بخصوصية بياناتك ونوفر لك تجربة استخدام بسيطة وآمنة.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const LegalLinksCard(),
                      const SizedBox(height: 20),
                      _buildLogoutButton(),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          'شفاء • رعاية أقرب واطمئنان أكبر',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
          const Row(
            children: [
              Icon(Icons.favorite_border_rounded, color: Colors.white70, size: 19),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'رعاية منزلية أقرب ليك وراحة بال لأسرتك',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
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
