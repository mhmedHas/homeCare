import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/user_service.dart';

class NurseProfessionalProfileScreen extends StatefulWidget {
  const NurseProfessionalProfileScreen({super.key});

  @override
  State<NurseProfessionalProfileScreen> createState() =>
      _NurseProfessionalProfileScreenState();
}

class _NurseProfessionalProfileScreenState
    extends State<NurseProfessionalProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedSpecialization;
  List<String> _selectedServices = [];
  List<String> _selectedWorkAreas = [];

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول';
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('nurseProfiles')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _profileData = data;
          _experienceController.text =
              (data['experienceYears'] ?? 0).toString();
          _priceController.text = (data['expectedPrice'] ?? 0).toString();
          _selectedSpecialization = data['specialization'] ?? 'تمريض عام';
          _selectedServices = List<String>.from(data['services'] ?? []);
          _selectedWorkAreas = List<String>.from(data['workAreas'] ?? []);
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول';
        });
        return;
      }

      await FirebaseFirestore.instance
          .collection('nurseProfiles')
          .doc(user.uid)
          .update({
        'specialization': _selectedSpecialization,
        'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
        'services': _selectedServices,
        'workAreas': _selectedWorkAreas,
        'expectedPrice': double.tryParse(_priceController.text.trim()) ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ البيانات بنجاح')));
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في الحفظ';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف المهني')),
      body: _isLoading && _profileData == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
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

                          // Services
                          const Text('الخدمات',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Wrap(
                            spacing: 8,
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
                          const SizedBox(height: 12),

                          // Work Areas
                          const Text('مناطق العمل',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Wrap(
                            spacing: 8,
                            children: _areas.map((area) {
                              final isSelected =
                                  _selectedWorkAreas.contains(area);
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
                            onPressed: _isLoading ? null : _saveProfile,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('حفظ التغييرات'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
