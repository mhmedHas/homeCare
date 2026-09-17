import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NurseSettingsScreen extends StatefulWidget {
  const NurseSettingsScreen({super.key});

  @override
  State<NurseSettingsScreen> createState() => _NurseSettingsScreenState();
}

class _NurseSettingsScreenState extends State<NurseSettingsScreen> {
  static const governorates = <String>[
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'القليوبية',
    'الدقهلية',
    'الشرقية',
    'الغربية',
    'المنوفية',
    'البحيرة',
    'كفر الشيخ',
    'دمياط',
    'بورسعيد',
    'الإسماعيلية',
    'السويس',
    'الفيوم',
    'بني سويف',
    'المنيا',
    'أسيوط',
    'سوهاج',
    'قنا',
    'الأقصر',
    'أسوان',
    'مطروح',
    'الوادي الجديد',
    'شمال سيناء',
    'جنوب سيناء',
    'البحر الأحمر',
  ];

  // تخصصات التمريض المتاحة للاختيار من القائمة.
  static const specializations = <String>[
    'تمريض عام',
    'تمريض باطني وجراحي',
    'تمريض الأطفال',
    'تمريض النساء والتوليد',
    'تمريض حديثي الولادة',
    'العناية المركزة',
    'الطوارئ والحوادث',
    'رعاية كبار السن',
    'الرعاية المنزلية',
    'تمريض الحالات الحرجة',
    'تمريض القلب والأوعية الدموية',
    'تمريض أمراض الكلى والغسيل الكلوي',
    'تمريض الأورام',
    'تمريض الأمراض المزمنة',
    'تمريض الصحة النفسية',
    'تمريض صحة المجتمع',
    'تمريض العمليات والجراحة',
    'تمريض التخدير',
    'تمريض مكافحة العدوى',
    'تمريض التأهيل والعلاج الطبيعي',
    'تمريض الحروق',
    'تمريض العناية التلطيفية',
    'تمريض مرضى السكري',
    'تمريض أمراض الجهاز التنفسي',
    'تمريض الأمراض العصبية',
    'تمريض العناية بالقلب',
    'تمريض الرعاية طويلة الأمد',
    'أخرى',
  ];

  final _firestore = FirebaseFirestore.instance;
  final _experienceController = TextEditingController();
  final _servicesController = TextEditingController();

  List<String> _selectedGovernorates = [];
  String? _selectedSpecialization;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _experienceController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('nurseProfiles').doc(uid).get();
      final data = doc.data() ?? {};
      final governoratesValue = data['preferredGovernorates'];
      final servicesValue = data['services'];
      final savedSpecialization = data['specialization']?.toString().trim();

      _selectedGovernorates = governoratesValue is List
          ? governoratesValue
              .map((e) => e.toString())
              .where(governorates.contains)
              .toSet()
              .toList()
          : [];

      _selectedSpecialization = specializations.contains(savedSpecialization)
          ? savedSpecialization
          : null;

      _experienceController.text =
          data['experienceYears']?.toString() ?? '';
      _servicesController.text = servicesValue is List
          ? servicesValue.map((e) => e.toString()).join('\n')
          : (data['servicesText']?.toString() ?? '');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل إعدادات العمل')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectGovernorates() async {
    final tempSelected = {..._selectedGovernorates};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.82,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'اختيار محافظات العمل',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(tempSelected.clear);
                            },
                            child: const Text('مسح الكل'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '${tempSelected.length} محافظة محددة',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: governorates.length,
                        itemBuilder: (_, index) {
                          final governorate = governorates[index];
                          final selected = tempSelected.contains(governorate);

                          return CheckboxListTile(
                            value: selected,
                            title: Text(governorate),
                            secondary: Icon(
                              Icons.location_on_outlined,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  tempSelected.add(governorate);
                                } else {
                                  tempSelected.remove(governorate);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedGovernorates = tempSelected.toList();
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('تأكيد المحافظات'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final experience = int.tryParse(_experienceController.text.trim());

    if (_selectedGovernorates.isEmpty) {
      _showMessage('اختار محافظة واحدة على الأقل');
      return;
    }
    if (_selectedSpecialization == null) {
      _showMessage('اختار التخصص');
      return;
    }
    if (experience == null || experience < 0 || experience > 60) {
      _showMessage('اكتب عدد سنوات خبرة صحيح');
      return;
    }
    if (_servicesController.text.trim().isEmpty) {
      _showMessage('اكتب الخدمات التي تقدمها');
      return;
    }

    setState(() => _saving = true);

    try {
      final services = _servicesController.text
          .split(RegExp(r'[\n,،]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      await _firestore.collection('nurseProfiles').doc(uid).set(
        {
          'preferredGovernorates': _selectedGovernorates,
          'specialization': _selectedSpecialization,
          'experienceYears': experience,
          'services': services,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ إعدادات العمل بنجاح')),
        );
      }
    } catch (_) {
      if (mounted) _showMessage('حدث خطأ أثناء الحفظ، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String get _governoratesSummary {
    if (_selectedGovernorates.isEmpty) return 'لم يتم اختيار محافظة';
    if (_selectedGovernorates.length == 1) return _selectedGovernorates.first;
    if (_selectedGovernorates.length == 2) {
      return _selectedGovernorates.join('، ');
    }
    return '${_selectedGovernorates.length} محافظات مختارة';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات العمل')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _section(
                  icon: Icons.location_on_outlined,
                  title: 'محافظات العمل',
                  subtitle:
                      'حدد المحافظات التي ترغب في استقبال طلبات الرعاية المنزلية فيها.',
                  child: InkWell(
                    onTap: _saving ? null : _selectGovernorates,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'المحافظات',
                        prefixIcon: Icon(Icons.map_outlined),
                        suffixIcon: Icon(Icons.keyboard_arrow_down),
                      ),
                      child: Text(
                        _governoratesSummary,
                        style: TextStyle(
                          color: _selectedGovernorates.isEmpty
                              ? AppColors.textSecondary
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  icon: Icons.badge_outlined,
                  title: 'البيانات المهنية',
                  subtitle:
                      'اختار تخصصك من القائمة وحدد خبرتك والخدمات التي تقدمها. هذه البيانات ستظهر للعميل.',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedSpecialization,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'التخصص',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                        items: specializations
                            .map(
                              (specialization) => DropdownMenuItem<String>(
                                value: specialization,
                                child: Text(specialization),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedSpecialization = value;
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'سنوات الخبرة',
                          hintText: 'مثال: 5',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _servicesController,
                        minLines: 4,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'الخدمات التي تقدمها',
                          hintText:
                              'اكتب كل خدمة في سطر أو افصل بينها بفاصلة\nمثال:\nرعاية كبار السن\nإعطاء الأدوية\nقياس الضغط والسكر',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 70),
                            child: Icon(Icons.volunteer_activism_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'الأوراق المطلوبة لإتمام التحقق موجودة في صفحة المستندات: البطاقة، المؤهل الدراسي، وترخيص مزاولة المهنة إن وجد.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'جاري الحفظ...' : 'حفظ الإعدادات'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
