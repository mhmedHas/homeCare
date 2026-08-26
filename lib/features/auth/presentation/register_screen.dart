import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/shared_preferences_service.dart';
import '../../shared/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = SharedPreferencesService();
    final role = prefs.getSelectedRole();

    if (role == null || (role != 'client' && role != 'nurse')) {
      setState(() {
        _errorMessage = 'يرجى اختيار نوع الحساب أولاً.';
        _isLoading = false;
      });
      return;
    }

    try {
      final auth = AuthService();
      final cred = await auth.register(
          _emailController.text.trim(), _passwordController.text.trim());
      final user = cred.user!;

      // Create AppUser
      final appUser = AppUser(
        uid: user.uid,
        role: role,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await UserService().createUser(appUser);

      // Clear temp role
      await prefs.clearTempPreferences();

      if (role == 'client') {
        if (mounted) context.go('/client/home');
      } else {
        if (mounted) context.go('/nurse/home');
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ. حاول مرة أخرى.';
      if (e.code == 'email-already-in-use')
        msg = 'البريد الإلكتروني مستخدم بالفعل.';
      else if (e.code == 'weak-password')
        msg = 'كلمة المرور ضعيفة جداً.';
      else if (e.code == 'invalid-email') msg = 'البريد الإلكتروني غير صالح.';
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
          title: const Text('إنشاء حساب'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add,
                    size: 60, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text('حساب جديد',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('املأ البيانات لإنشاء حسابك',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'الاسم كاملاً',
                      prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.length < 2 ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
                  validator: (v) => v!.length < 10 ? 'رقم هاتف غير صحيح' : null,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: Icon(Icons.check)),
                  validator: (v) => v != _passwordController.text
                      ? 'كلمة المرور غير متطابقة'
                      : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('إنشاء الحساب'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لديك حساب بالفعل؟'),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('تسجيل الدخول',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
