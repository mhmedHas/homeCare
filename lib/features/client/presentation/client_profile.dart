import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/shared_preferences_service.dart';
import '../../shared/models/app_user.dart';

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
                                fontSize: 40, color: Colors.white)),
                      ),
                      const SizedBox(height: 8),
                      Text(_user!.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(_user!.phone,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      Text(_user!.email ?? '',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      const Divider(height: 32),
                      _buildMenuItem(Icons.edit, 'تعديل البيانات', () {}),
                      _buildMenuItem(Icons.history, 'حجوزاتي',
                          () => context.go('/client/my-bookings')),
                      _buildMenuItem(Icons.chat, 'الرسائل', () {}),
                      _buildMenuItem(Icons.help_outline, 'المساعدة', () {}),
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
