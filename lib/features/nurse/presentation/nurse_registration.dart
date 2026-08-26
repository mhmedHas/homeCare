import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/shared_preferences_service.dart';
import '../../shared/models/app_user.dart';

class NurseRegistrationScreen extends StatefulWidget {
  const NurseRegistrationScreen({super.key});

  @override
  State<NurseRegistrationScreen> createState() =>
      _NurseRegistrationScreenState();
}

class _NurseRegistrationScreenState extends State<NurseRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedGovernorate = 'القاهرة';
  String? _selectedArea = 'مدينة نصر';
  String? _selectedSpecialization = 'تمريض عام';
  List<String> _selectedServices = [];
  List<String> _selectedWorkAreas = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _governorates = [
    'القاهرة',
    'الإسكندرية',
    'الجيزة',
    'القليوبية',
    'الشرقية',
    'الدقهلية',
    'المنوفية',
    'الغربية'
  ];
  final List<String> _areas = [
    'مدينة نصر',
    'مصر الجديدة',
    'الزمالك',
    'الدقي',
    'المهندسين',
    'مصر القديمة',
    'المعادي',
    'الهرم'
  ];
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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

      // Update user profile
      await UserService().updateUser(user.uid, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create nurse profile
      await FirebaseFirestore.instance
          .collection('nurseProfiles')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'specialization': _selectedSpecialization,
        'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
        'services': _selectedServices,
        'workAreas': _selectedWorkAreas,
        'governorate': _selectedGovernorate,
        'area': _selectedArea,
        'expectedPrice': double.tryParse(_priceController.text.trim()) ?? 0,
        'isVerified': false,
        'verificationStatus': 'not_submitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear temp role
      await SharedPreferencesService().clearTempPreferences();

      if (mounted) {
        context.go('/nurse/verification-status');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: $e';
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
      appBar: AppBar(title: const Text('التسجيل كمرض')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.medical_services,
                    size: 60, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text('أكمل بياناتك المهنية',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'الاسم كاملاً',
                      prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.length < 2 ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
                  validator: (v) => v!.length < 10 ? 'رقم هاتف غير صحيح' : null,
                ),
                const SizedBox(height: 12),

                // Governorate
                DropdownButtonFormField<String>(
                  value: _selectedGovernorate,
                  decoration: const InputDecoration(
                      labelText: 'المحافظة',
                      prefixIcon: Icon(Icons.location_city)),
                  items: _governorates
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGovernorate = v),
                ),
                const SizedBox(height: 12),

                // Area
                DropdownButtonFormField<String>(
                  value: _selectedArea,
                  decoration: const InputDecoration(
                      labelText: 'المنطقة',
                      prefixIcon: Icon(Icons.location_on)),
                  items: _areas
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedArea = v),
                ),
                const SizedBox(height: 12),

                // Specialization
                DropdownButtonFormField<String>(
                  value: _selectedSpecialization,
                  decoration: const InputDecoration(
                      labelText: 'التخصص',
                      prefixIcon: Icon(Icons.medical_information)),
                  items: _specializations
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSpecialization = v),
                ),
                const SizedBox(height: 12),

                // Experience
                TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'سنوات الخبرة',
                      prefixIcon: Icon(Icons.timeline)),
                  validator: (v) => v!.isEmpty ? 'الخبرة مطلوبة' : null,
                ),
                const SizedBox(height: 12),

                // Expected Price
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'السعر المتوقع (ج.م/ساعة)',
                      prefixIcon: Icon(Icons.money)),
                  validator: (v) => v!.isEmpty ? 'السعر مطلوب' : null,
                ),
                const SizedBox(height: 12),

                // Services (Multi-select chips)
                const Text('الخدمات التي تقدمها',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _allServices.map((service) {
                    final isSelected = _selectedServices.contains(service);
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
                const SizedBox(height: 12),

                // Work Areas (Multi-select chips)
                const Text('مناطق العمل',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _areas.map((area) {
                    final isSelected = _selectedWorkAreas.contains(area);
                    return FilterChip(
                      label: Text(area),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedWorkAreas.add(area);
                          } else {
                            _selectedWorkAreas.remove(area);
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
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('إتمام التسجيل'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
