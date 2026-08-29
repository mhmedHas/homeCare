import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../services/supabase_storage_service.dart';
import '../../shared/models/app_user.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _picker = ImagePicker();
  final _storage = SupabaseStorageService();
  AppUser? _user;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
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

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto || _user == null) return;
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('التقاط صورة'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار من المعرض'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ]),
        ),
      );
      if (source == null) return;

      final image = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200, maxHeight: 1200);
      if (image == null) return;
      final Uint8List bytes = await image.readAsBytes();
      if (bytes.isEmpty) return;

      setState(() => _isUploadingPhoto = true);
      final url = await _storage.uploadClientProfilePhoto(uid: _user!.uid, bytes: bytes);
      await UserService().updateUser(_user!.uid, {'photoUrl': url});
      if (!mounted) return;
      setState(() => _user = _user!.copyWith(photoUrl: url));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الصورة الشخصية')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر رفع الصورة، حاول مرة أخرى')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _editInfo() async {
    if (_user == null) return;
    final nameController = TextEditingController(text: _user!.name);
    final phoneController = TextEditingController(text: _user!.phone);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل البيانات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );

    if (saved != true) return;
    final newName = nameController.text.trim();
    final newPhone = phoneController.text.trim();
    if (newName.isEmpty || newPhone.isEmpty) return;

    try {
      await UserService().updateUser(_user!.uid, {'name': newName, 'phone': newPhone});
      if (!mounted) return;
      setState(() => _user = _user!.copyWith(name: newName, phone: newPhone));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث البيانات')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ البيانات، حاول مرة أخرى')));
      }
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعدة'),
        content: const Text('لأي استفسار أو مشكلة في الحجز أو الدفع، تواصل معنا عبر البريد الإلكتروني للدعم الفني.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))],
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
      appBar: AppBar(title: const Text('حسابي')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null || _user == null
              ? Center(child: Text(_errorMessage ?? 'غير موجود'))
              : RefreshIndicator(
                  onRefresh: _loadUser,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 46,
                                    backgroundColor: AppColors.primary,
                                    backgroundImage: (_user!.photoUrl?.isNotEmpty ?? false)
                                        ? NetworkImage(_user!.photoUrl!)
                                        : null,
                                    child: (_user!.photoUrl?.isNotEmpty ?? false)
                                        ? null
                                        : Text(
                                            _user!.name.isNotEmpty ? _user!.name[0] : '?',
                                            style: const TextStyle(fontSize: 36, color: Colors.white),
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: InkWell(
                                      onTap: _pickAndUploadPhoto,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                                        child: _isUploadingPhoto
                                            ? const SizedBox(
                                                width: 16, height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(_user!.name, style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              Text(_user!.phone, style: const TextStyle(color: AppColors.textSecondary)),
                              if ((_user!.email ?? '').isNotEmpty)
                                Text(_user!.email!, style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuItem(Icons.edit_outlined, 'تعديل البيانات', _editInfo),
                      _buildMenuItem(Icons.history, 'حجوزاتي', () => context.push('/client/my-bookings')),
                      _buildMenuItem(Icons.list_alt_outlined, 'طلباتي', () => context.push('/client/my-requests')),
                      _buildMenuItem(Icons.chat_bubble_outline, 'الرسائل', () => context.push('/client/messages')),
                      _buildMenuItem(Icons.help_outline, 'المساعدة', _showHelp),
                      const SizedBox(height: 8),
                      _buildMenuItem(Icons.logout, 'تسجيل الخروج', _logout, isDestructive: true),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon,
            color: isDestructive ? AppColors.error : AppColors.primary),
        title: Text(title,
            style: TextStyle(color: isDestructive ? AppColors.error : null, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
