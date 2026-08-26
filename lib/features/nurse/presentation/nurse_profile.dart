import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول';
        });
        return;
      }

      final appUser = await UserService().getUser(user.uid);
      setState(() {
        _user = appUser;
      });

      final doc = await FirebaseFirestore.instance
          .collection('nurseProfiles')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _nurseProfile = doc.data();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null || _user == null
              ? Center(child: Text(_errorMessage ?? 'غير موجود'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _user!.name.isNotEmpty ? _user!.name[0] : '?',
                          style: const TextStyle(
                              fontSize: 40, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_user!.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      if (_user!.isVerified)
                        const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified,
                                  color: AppColors.success, size: 16),
                              SizedBox(width: 4),
                              Text('موثق',
                                  style: TextStyle(color: AppColors.success)),
                            ]),
                      const SizedBox(height: 4),
                      Text(_user!.phone,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      Text(_user!.email ?? '',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      const Divider(height: 32),
                      _buildMenuItem(Icons.edit, 'تعديل الملف',
                          () => context.go('/nurse/professional-profile')),
                      _buildMenuItem(Icons.upload_file, 'المستندات',
                          () => context.go('/nurse/documents')),
                      _buildMenuItem(Icons.verified, 'حالة التحقق',
                          () => context.go('/nurse/verification-status')),
                      _buildMenuItem(Icons.calendar_month, 'الشيفتات',
                          () => context.go('/nurse/previous-shifts')),
                      _buildMenuItem(Icons.money, 'الأرباح',
                          () => context.go('/nurse/earnings')),
                      _buildMenuItem(Icons.stars, 'Nurse Pro',
                          () => context.go('/nurse/nurse-pro')),
                      _buildMenuItem(Icons.star, 'تقييماتي',
                          () => context.go('/nurse/reviews')),
                      const Spacer(),
                      _buildMenuItem(Icons.logout, 'تسجيل الخروج', _logout,
                          isDestructive: true),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon,
          color: isDestructive ? AppColors.error : AppColors.primary),
      title: Text(title,
          style: TextStyle(color: isDestructive ? AppColors.error : null)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
