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
  List<String> _selected = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final doc = await _firestore.collection('nurseProfiles').doc(uid).get();
      final data = doc.data();
      final values = data?['preferredGovernorates'];
      if (values is List) {
        _selected = values.map((e) => e.toString()).toList();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل المحافظات')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختار محافظة واحدة على الأقل')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _firestore.collection('nurseProfiles').doc(uid).set({
        'preferredGovernorates': _selected,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المحافظات بنجاح')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء الحفظ')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات العمل')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_city, color: AppColors.primary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'المحافظات اللي بتشتغل فيها',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'اختار المحافظات اللي تقدر تقدم فيها Home Care. هتظهر لك طلبات الرعاية في المحافظات دي فقط.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: governorates.map((g) {
                            final selected = _selected.contains(g);
                            return FilterChip(
                              label: Text(g),
                              selected: selected,
                              onSelected: (value) => setState(() {
                                if (value) {
                                  _selected.add(g);
                                } else {
                                  _selected.remove(g);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'جاري الحفظ...' : 'حفظ الإعدادات'),
                  ),
                ),
              ],
            ),
    );
  }
}
