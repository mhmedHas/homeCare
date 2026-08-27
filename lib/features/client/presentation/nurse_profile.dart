import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';

class NurseProfileScreen extends StatefulWidget {
  final String nurseId;
  final String requestId;

  const NurseProfileScreen({super.key, required this.nurseId, required this.requestId});

  @override
  State<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  AppUser? _nurse;
  Map<String, dynamic> _profile = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final nurse = await UserService().getUser(widget.nurseId);
      if (nurse == null || nurse.role != 'nurse') {
        throw StateError('not_nurse');
      }
      final profileDoc = await FirebaseFirestore.instance.collection('nurseProfiles').doc(widget.nurseId).get();
      if (!mounted) return;
      setState(() {
        _nurse = nurse;
        _profile = profileDoc.data() ?? {};
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _error = 'تعذر تحميل ملف الممرض'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملف الممرض')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _nurse == null
              ? _errorState()
              : _buildProfile(),
    );
  }

  Widget _errorState() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person_off_outlined, size: 56), const SizedBox(height: 12), Text(_error ?? 'الممرض غير موجود', textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'))])));

  Widget _buildProfile() {
    final services = _profile['services'] is List ? (_profile['services'] as List).map((e) => e.toString()).toList() : <String>[];
    final areas = _profile['preferredGovernorates'] is List ? (_profile['preferredGovernorates'] as List).map((e) => e.toString()).toList() : <String>[];
    final experience = _profile['experienceYears']?.toString() ?? 'غير محدد';
    final specialization = _profile['specialization']?.toString() ?? 'تمريض';
    final verified = _nurse!.isVerified;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(radius: 48, backgroundColor: AppColors.primary.withValues(alpha: 0.12), child: Text(_nurse!.name.isNotEmpty ? _nurse!.name.characters.first : '?', style: TextStyle(fontSize: 34, color: AppColors.primary, fontWeight: FontWeight.bold))),
                const SizedBox(height: 12),
                Text(_nurse!.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                if (verified) ...[
                  const SizedBox(height: 6),
                  const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified, color: AppColors.success, size: 19), SizedBox(width: 5), Text('ممرض موثق', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700))]),
                ],
                const SizedBox(height: 16),
                Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                  _stat(Icons.medical_services_outlined, specialization),
                  _stat(Icons.workspace_premium_outlined, '$experience سنوات خبرة'),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (areas.isNotEmpty) _section('محافظات العمل', Icons.location_on_outlined, Wrap(spacing: 8, runSpacing: 8, children: areas.map((area) => Chip(label: Text(area))).toList())),
        if (services.isNotEmpty) ...[
          const SizedBox(height: 12),
          _section('الخدمات المقدمة', Icons.volunteer_activism_outlined, Wrap(spacing: 8, runSpacing: 8, children: services.map((service) => Chip(label: Text(service))).toList())),
        ],
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Icon(Icons.info_outline, color: AppColors.primary), const SizedBox(width: 10), Expanded(child: Text('اختيار الممرض يتم من خلال عروض الطلب. راجع السعر والتقييم والملف قبل تأكيد الحجز.', style: TextStyle(color: AppColors.textSecondary)))]))),
        const SizedBox(height: 18),
        SizedBox(height: 52, child: FilledButton.icon(onPressed: widget.requestId.isEmpty ? null : () => context.go('/client/request-offers/${widget.requestId}'), icon: const Icon(Icons.check_circle_outline), label: const Text('العودة لعروض الطلب واختيار الممرض'))),
      ],
    );
  }

  Widget _stat(IconData icon, String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18, color: AppColors.primary), const SizedBox(width: 6), Text(text)]));

  Widget _section(String title, IconData icon, Widget content) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]), const SizedBox(height: 12), content])));
}
