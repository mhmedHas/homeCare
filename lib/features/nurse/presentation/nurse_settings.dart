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
    'القاهرة', 'الجيزة', 'الإسكندرية', 'القليوبية', 'الدقهلية', 'الشرقية',
    'الغربية', 'المنوفية', 'البحيرة', 'كفر الشيخ', 'دمياط', 'بورسعيد',
    'الإسماعيلية', 'السويس', 'الفيوم', 'بني سويف', 'المنيا', 'أسيوط',
    'سوهاج', 'قنا', 'الأقصر', 'أسوان', 'مطروح', 'الوادي الجديد',
    'شمال سيناء', 'جنوب سيناء', 'البحر الأحمر',
  ];

  final _firestore = FirebaseFirestore.instance;
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _servicesController = TextEditingController();

  List<String> _selectedGovernorates = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _specializationController.dispose();
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

      _selectedGovernorates = governoratesValue is List
          ? governoratesValue.map((e) => e.toString()).toSet().toList()
          : [];
      _specializationController.text = data['specialization']?.toString() ?? '';
      _experienceController.text = data['experienceYears']?.toString() ?? '';
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

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final experience = int.tryParse(_experienceController.text.trim());
    if (_selectedGovernorates.isEmpty) {
      _showMessage('اختار محافظة واحدة على الأقل');
      return;
    }
    if (_specializationController.text.trim().isEmpty) {
      _showMessage('اكتب التخصص');
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

      await _firestore.collection('nurseProfiles').doc(uid).set({
        'preferredGovernorates': _selectedGovernorates,
        'specialization': _specializationController.text.trim(),
        'experienceYears': experience,
        'services': services,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                  icon: Icons.location_city_outlined,
                  title: 'محافظات العمل',
                  subtitle:
                      'اختار المحافظات التي ترغب في استقبال طلبات Home Care فيها. سيتم فلترة الطلبات بناءً عليها فقط.',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: governorates.map((governorate) {
                      final selected = _selectedGovernorates.contains(governorate);
                      return FilterChip(
                        label: Text(governorate),
                        selected: selected,
                        onSelected: _saving
                            ? null
                            : (value) {
                                setState(() {
                                  if (value) {
                                    _selectedGovernorates.add(governorate);
                                  } else {
                                    _selectedGovernorates.remove(governorate);
                                  }
                                });
                              },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  icon: Icons.badge_outlined,
                  title: 'البيانات المهنية',
                  subtitle: 'هذه البيانات ستظهر للعميل عند مراجعة ملفك.',
                  child: Column(
                    children: [
                      TextField(
                        controller: _specializationController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'التخصص',
                          hintText: 'مثال: تمريض عام، رعاية كبار السن',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
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
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
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
