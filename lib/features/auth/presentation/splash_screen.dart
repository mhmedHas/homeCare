import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'جاري التحميل...';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _status = 'جاري تهيئة التطبيق...');

      final auth = AuthService();
      final user = auth.currentUser;

      if (user == null) {
        // No authenticated user: always start the authentication flow at Login.
        if (mounted) context.go('/login');
        return;
      }

      // Authenticated user: load the Firestore profile and continue to the
      // correct home screen based on the saved role.
      setState(() => _status = 'جاري تحميل بيانات الحساب...');
      final appUser = await UserService().getUser(user.uid);

      if (!mounted) return;

      if (appUser == null) {
        // Auth account exists, but the application profile is incomplete.
        context.go('/role');
        return;
      }

      if (appUser.role == 'client') {
        context.go('/client/home');
      } else if (appUser.role == 'nurse') {
        context.go('/nurse/home');
      } else {
        await auth.logout();
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'شفاء',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'خدمات الرعاية المنزلية',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                if (_hasError) ...[
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _errorMessage = '';
                      });
                      _initializeApp();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                ] else ...[
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _status,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
