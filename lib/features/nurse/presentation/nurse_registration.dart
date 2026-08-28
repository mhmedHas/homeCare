import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../services/supabase_storage_service.dart';
import '../../../services/user_service.dart';

class NurseRegistrationScreen extends StatefulWidget {
  const NurseRegistrationScreen({super.key});

  @override
  State<NurseRegistrationScreen> createState() => _NurseRegistrationScreenState();
}

class _NurseRegistrationScreenState extends State<NurseRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _priceController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _storageService = SupabaseStorageService();

  String? _selectedGovernorate = 'القاهرة';
  String? _selectedArea = 'مدينة نصر';
  String? _selectedSpecialization = 'تمريض عام';
  final List<String> _selectedServices = [];
  final List<String> _selectedWorkAreas = [];
  XFile? _profileImage;
  bool _isLoading = false;
  bool _isPickingImage = false;
  String? _errorMessage;

  final List<String> _governorates = [
    'القاهرة', 'الإسكندرية', 'الجيزة', 'القليوبية',
    'الشرقية', 'الدقهلية', 'المنوفية', 'الغربية',
  ];

  final List<String> _areas = [
    'مدينة نصر', 'مصر الجديدة', 'الزمالك', 'الدقي',
    'المهندسين', 'مصر القديمة', 'المعادي', 'الهرم',
  ];

  final List<String> _specializations = [
    'تمريض عام', 'تمريض طوارئ', 'تمريض عناية مركزة', 'تمريض أطفال',
    'تمريض كبار السن', 'تمريض منازل', 'تمريض عمليات',
  ];

  final List<String> _allServices = [
    'متابعة الحالة', 'إعطاء الأدوية', 'قياس الضغط', 'قياس السكر',
    'تغيير الجروح', 'مساعدة الحركة', 'رعاية كبار السن',
    'رعاية ما بعد العمليات', 'تمريض الأطفال', 'العناية بالتنفس',
  ];

  Future<void> _pickProfileImage() async {
    if (_isPickingImage || _isLoading) return;
    setState(() => _isPickingImage = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image != null && mounted) {
        setState(() {
          _profileImage = image;
          _errorMessage = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'تعذر اختيار الصورة. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    final image = _profileImage;
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) throw Exception('empty_image');
    return _storageService.uploadNurseProfilePhoto(
      uid: uid,
      bytes: bytes,
      contentType: 'image/jpeg',
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null) {
      setState(() => _errorMessage = 'صورة البروفايل مطلوبة لعرض ملفك للعميل.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService().currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول أولاً';
          _isLoading = false;
        });
        return;
      }

      final photoUrl = await _uploadProfileImage(user.uid);
      if (photoUrl == null || photoUrl.isEmpty) throw Exception('photo_upload_failed');

      await UserService().updateUser(user.uid, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'photoUrl': photoUrl,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('nurseProfiles').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'photoUrl': photoUrl,
        'specialization': _selectedSpecialization,
        'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
        'services': List<String>.from(_selectedServices),
        'workAreas': List<String>.from(_selectedWorkAreas),
        'governorate': _selectedGovernorate,
        'area': _selectedArea,
        'expectedPrice': double.tryParse(_priceController.text.trim()) ?? 0,
        'isVerified': false,
        'verificationStatus': 'not_submitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await SharedPreferencesService().clearTempPreferences();
      if (mounted) context.go('/nurse/verification-status');
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage =
            'تعذر حفظ البيانات والصورة. تأكد من إعداد Storage ثم حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التسجيل كممرض')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.medical_services, size: 60, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text('أكمل بياناتك المهنية',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildProfilePhotoPicker(),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم كاملاً', prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v == null || v.trim().length < 2 ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) => v == null || v.trim().length < 10 ? 'رقم هاتف غير صحيح' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGovernorate,
                  decoration: const InputDecoration(
                    labelText: 'المحافظة', prefixIcon: Icon(Icons.location_city),
                  ),
                  items: _governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _selectedGovernorate = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedArea,
                  decoration: const InputDecoration(
                    labelText: 'المنطقة', prefixIcon: Icon(Icons.location_on),
                  ),
                  items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (v) => setState(() => _selectedArea = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSpecialization,
                  decoration: const InputDecoration(
                    labelText: 'التخصص', prefixIcon: Icon(Icons.medical_information),
                  ),
                  items: _specializations.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedSpecialization = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'سنوات الخبرة', prefixIcon: Icon(Icons.timeline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'الخبرة مطلوبة' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السعر المتوقع (ج.م/ساعة)', prefixIcon: Icon(Icons.money),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'السعر مطلوب' : null,
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('الخدمات التي تقدمها', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Wrap(
                  spacing: 8,
                  children: _allServices.map((service) {
                    final isSelected = _selectedServices.contains(service);
                    return FilterChip(
                      label: Text(service), selected: isSelected,
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedServices.add(service);
                        } else {
                          _selectedServices.remove(service);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('مناطق العمل', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Wrap(
                  spacing: 8,
                  children: _areas.map((area) {
                    final isSelected = _selectedWorkAreas.contains(area);
                    return FilterChip(
                      label: Text(area), selected: isSelected,
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedWorkAreas.add(area);
                        } else {
                          _selectedWorkAreas.remove(area);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Text(_errorMessage!, textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('إتمام التسجيل'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoPicker() {
    final image = _profileImage;
    return Column(
      children: [
        GestureDetector(
          onTap: _pickProfileImage,
          child: CircleAvatar(
            radius: 58,
            backgroundColor: AppColors.primary.withValues(alpha: 0.10),
            backgroundImage: image == null ? null : FileImage(File(image.path)),
            child: image == null
                ? const Icon(Icons.add_a_photo, size: 34, color: AppColors.primary)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _isPickingImage ? null : _pickProfileImage,
          icon: _isPickingImage
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.photo_library_outlined),
          label: Text(image == null ? 'إضافة صورة شخصية' : 'تغيير الصورة'),
        ),
        const Text(
          'الصورة ستظهر للعميل عند اختيارك كممرض',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
