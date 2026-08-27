import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/shared_preferences_service.dart';
import '../../shared/models/app_user.dart';

class NurseProfileScreen extends StatefulWidget {
  const NurseProfileScreen({super.key});
  @override
  State<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  AppUser? _user;
  Map<String, dynamic>? _nurseProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final user = AuthService().currentUser;
      if (user == null) { if (mounted) setState(() => _errorMessage = 'يرجى تسجيل الدخول'); return; }
      final results = await Future.wait([
        UserService().getUser(user.uid),
        FirebaseFirestore.instance.collection('nurseProfiles').doc(user.uid).get(),
      ]);
      final appUser = results[0] as AppUser?;
      final doc = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      if (mounted) setState(() { _user = appUser; _nurseProfile = doc.data(); _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _errorMessage = 'تعذر تحميل الملف الشخصي'; _isLoading = false; });
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    await SharedPreferencesService().clearTempPreferences();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _errorMessage != null || _user == null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_errorMessage ?? 'البيانات غير موجودة'), const SizedBox(height: 12), FilledButton(onPressed: _loadProfile, child: const Text('إعادة المحاولة'))])))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                  CircleAvatar(radius: 46, backgroundColor: AppColors.primaryLight, child: Text(_user!.name.isNotEmpty ? _user!.name[0] : '?', style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 12),
                  Text(_user!.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                  if (_user!.isVerified) const Padding(padding: EdgeInsets.only(top: 6), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified, color: AppColors.success, size: 18), SizedBox(width: 5), Text('حساب موثق', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600))])),
                  const SizedBox(height: 6),
                  Text(_user!.phone, style: const TextStyle(color: AppColors.textSecondary)),
                ]))),
                const SizedBox(height: 12),
                _buildMenuItem(Icons.edit_outlined, 'الملف المهني', () => context.go('/nurse/professional-profile')),
                _buildMenuItem(Icons.location_city, 'إعدادات العمل والمحافظات', () => context.push('/nurse/settings')),
                _buildMenuItem(Icons.upload_file_outlined, 'المستندات', () => context.push('/nurse/documents')),
                _buildMenuItem(Icons.verified_outlined, 'حالة التحقق', () => context.push('/nurse/verification-status')),
                _buildMenuItem(Icons.calendar_month_outlined, 'الشيفتات', () => context.push('/nurse/previous-shifts')),
                _buildMenuItem(Icons.payments_outlined, 'الأرباح', () => context.push('/nurse/earnings')),
                _buildMenuItem(Icons.stars_outlined, 'Nurse Pro', () => context.push('/nurse/nurse-pro')),
                _buildMenuItem(Icons.star_outline, 'تقييماتي', () => context.push('/nurse/reviews')),
                const SizedBox(height: 8),
                _buildMenuItem(Icons.logout, 'تسجيل الخروج', _logout, isDestructive: true),
              ]),
            ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary), title: Text(title, style: TextStyle(color: isDestructive ? AppColors.error : null, fontWeight: FontWeight.w500)), trailing: const Icon(Icons.chevron_left), onTap: onTap));
}
