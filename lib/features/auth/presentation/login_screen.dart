import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = AuthService();
      final cred = await auth.login(
          _emailController.text.trim(), _passwordController.text.trim());
      final user = cred.user;
      if (user != null) {
        final userService = UserService();
        final appUser = await userService.getUser(user.uid);
        if (appUser == null) {
          if (mounted) context.go('/role');
          return;
        }
        if (appUser.role == 'client') {
          if (mounted) context.go('/client/home');
        } else if (appUser.role == 'nurse') {
          if (mounted) context.go('/nurse/home');
        } else {
          setState(() {
            _errorMessage = 'نوع الحساب غير معروف';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ. حاول مرة أخرى.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password')
        msg = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      else if (e.code == 'invalid-email')
        msg = 'البريد الإلكتروني غير صالح.';
      else if (e.code == 'too-many-requests')
        msg = 'محاولات كثيرة. حاول لاحقاً.';
      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع.';
      });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('تسجيل الدخول'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.health_and_safety,
                  size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('مرحباً بعودتك',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('سجل الدخول للمتابعة',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email)),
                validator: (v) => v!.isEmpty ? 'البريد مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v!.length < 8
                    ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل'
                    : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    // Forgot password
                    if (_emailController.text.isNotEmpty) {
                      try {
                        await AuthService()
                            .resetPassword(_emailController.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'تم إرسال رابط إعادة تعيين كلمة المرور')));
                      } catch (e) {}
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('أدخل بريدك الإلكتروني أولاً')));
                    }
                  },
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!,
                    style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('تسجيل الدخول'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ليس لديك حساب؟'),
                  TextButton(
                    onPressed: () => context.go('/role'),
                    child: const Text('إنشاء حساب جديد',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
