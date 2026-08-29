import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';

class NurseProfessionalProfileScreen extends StatefulWidget {
  const NurseProfessionalProfileScreen({super.key});

  @override
  State<NurseProfessionalProfileScreen> createState() =>
      _NurseProfessionalProfileScreenState();
}

class _NurseProfessionalProfileScreenState
    extends State<NurseProfessionalProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  String? _photoUrl;

  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  final _priceController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedSpecialization;
  List<String> _selectedServices = [];

  final List<String> _specializations = [
    'تمريض عام',
    'تمريض طوارئ',
    'تمريض عناية مركزة',
    'تمريض أطفال',
    'تمريض كبار السن',
    'تمريض منازل',
    'تمريض عمليات',
  ];
  final List<String> _allServices = [
    'متابعة الحالة',
    'إعطاء الأدوية',
    'قياس الضغط',
    'قياس السكر',
    'تغيير الجروح',
    'مساعدة الحركة',
    'رعاية كبار السن',
    'رعاية ما بعد العمليات',
    'تمريض الأطفال',
    'العناية بالتنفس',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _experienceController.dispose();
    _priceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _errorMessage = 'يرجى تسجيل الدخول');
        return;
      }

      final results = await Future.wait([
        FirebaseFirestore.instance.collection('nurseProfiles').doc(user.uid).get(),
        UserService().getUser(user.uid),
      ]);
      final doc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final appUser = results[1] as AppUser?;

      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _experienceController.text = (data['experienceYears'] ?? 0).toString();
          _priceController.text = (data['expectedPrice'] ?? 0).toString();
          _bioController.text = (data['bio'] ?? '').toString();
          _selectedSpecialization = data['specialization'] ?? 'تمريض عام';
          _selectedServices = List<String>.from(data['services'] ?? []);
        });
      } else {
        setState(() => _selectedSpecialization = 'تمريض عام');
      }
      if (appUser?.photoUrl != null) {
        setState(() => _photoUrl = appUser!.photoUrl);
      }
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ في تحميل البيانات');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1000);
      if (image == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      setState(() => _isUploadingPhoto = true);
      final url = await SupabaseService.uploadImage(
        file: File(image.path),
        folder: 'profile_photos',
        fileName: '$uid.jpg',
      );
      await UserService().updateUser(uid, {'photoUrl': url});
      if (!mounted) return;
      setState(() => _photoUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الصورة الشخصية')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر رفع الصورة، تأكد من إعداد Supabase وحاول مرة أخرى')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _errorMessage = 'يرجى تسجيل الدخول');
        return;
      }

      // Using set(merge: true) instead of update() so this also works the
      // very first time a nurse opens this screen (before any nurseProfiles
      // document exists for them).
      await FirebaseFirestore.instance
          .collection('nurseProfiles')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'specialization': _selectedSpecialization,
        'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
        'services': _selectedServices,
        'expectedPrice': double.tryParse(_priceController.text.trim()) ?? 0,
        'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ البيانات بنجاح')));
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ في الحفظ');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الملف المهني')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _selectedSpecialization == null
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text(_errorMessage!,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadProfile,
                          child: const Text('إعادة المحاولة')),
                    ]))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: AppColors.primaryLight,
                                  backgroundImage: (_photoUrl?.isNotEmpty ?? false) ? NetworkImage(_photoUrl!) : null,
                                  child: (_photoUrl?.isNotEmpty ?? false)
                                      ? null
                                      : const Icon(Icons.person, size: 44, color: AppColors.primary),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _pickAndUploadPhoto,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
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
                          ),
                          const SizedBox(height: 20),

                          // Specialization
                          DropdownButtonFormField<String>(
                            value: _selectedSpecialization,
                            decoration: const InputDecoration(
                                labelText: 'التخصص',
                                prefixIcon: Icon(Icons.medical_information)),
                            items: _specializations
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedSpecialization = v),
                          ),
                          const SizedBox(height: 12),

                          // Experience
                          TextFormField(
                            controller: _experienceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'سنوات الخبرة',
                                prefixIcon: Icon(Icons.timeline)),
                            validator: (v) =>
                                v!.isEmpty ? 'الخبرة مطلوبة' : null,
                          ),
                          const SizedBox(height: 12),

                          // Price
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'السعر المتوقع (ج.م/ساعة)',
                                prefixIcon: Icon(Icons.money)),
                            validator: (v) => v!.isEmpty ? 'السعر مطلوب' : null,
                          ),
                          const SizedBox(height: 12),

                          // Bio
                          TextFormField(
                            controller: _bioController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'نبذة عني (تظهر للعميل)',
                              alignLabelWithHint: true,
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 48),
                                child: Icon(Icons.info_outline),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Services
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text('الخدمات',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allServices.map((service) {
                              final isSelected =
                                  _selectedServices.contains(service);
                              return FilterChip(
                                label: Text(service),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedServices.add(service);
                                    } else {
                                      _selectedServices.remove(service);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          if (_errorMessage != null)
                            Text(_errorMessage!,
                                style: const TextStyle(color: AppColors.error)),

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text('حفظ التغييرات'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
