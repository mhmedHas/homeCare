import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/direct_nurse_matching_service.dart';

class DirectNurseMatchingScreen extends StatefulWidget {
  const DirectNurseMatchingScreen({super.key});

  @override
  State<DirectNurseMatchingScreen> createState() =>
      _DirectNurseMatchingScreenState();
}

class _DirectNurseMatchingScreenState
    extends State<DirectNurseMatchingScreen> {
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

  static const careTypes = <String, String>{
    'elderly': 'رعاية كبار السن',
    'post_surgery': 'رعاية ما بعد العمليات',
    'chronic_disease': 'رعاية الأمراض المزمنة',
    'disability': 'رعاية ذوي الاحتياجات الخاصة',
    'maternity': 'رعاية الأمومة',
    'general': 'رعاية عامة',
  };

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
    'تمريض الأمراض المزمنة',
    'تمريض العمليات والجراحة',
    'تمريض مرضى السكري',
    'تمريض أمراض الجهاز التنفسي',
  ];

  String _governorate = governorates.first;
  String _careType = careTypes.keys.first;
  String _gender = 'any';
  String? _specialization;
  final _areaController = TextEditingController();
  final _budgetController = TextEditingController();
  List<DirectNurseCandidate> _matches = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  @override
  void dispose() {
    _areaController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _findMatches() async {
    final area = _areaController.text.trim();
    final budget = double.tryParse(_budgetController.text.trim());

    if (area.isEmpty) {
      setState(() => _error = 'اكتب المنطقة أو المركز');
      return;
    }

    if (_budgetController.text.trim().isNotEmpty &&
        (budget == null || budget <= 0)) {
      setState(() => _error = 'اكتب ميزانية صحيحة');
      return;
    }

    setState(() {
      _loading = true;
      _searched = true;
      _error = null;
    });

    try {
      final matches = await DirectNurseMatchingService().findBestMatches(
        governorate: _governorate,
        area: area,
        careType: _careType,
        preferredGender: _gender,
        specialization: _specialization ?? '',
        maxBudget: budget,
      );

      if (!mounted) return;
      setState(() {
        _matches = matches;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر العثور على الممرضين المناسبين';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اعثر لي على الممرض المناسب'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildIntro(),
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _loading ? null : _findMatches,
              icon: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _loading ? 'جاري البحث...' : 'اعثر لي على الممرض المناسب',
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ],
          if (_searched) ...[
            const SizedBox(height: 20),
            _buildResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildIntro() => Card(
        color: AppColors.primaryLight,
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 34, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختارلي ممرض — بشكل ذكي',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'هندور بين الممرضين الموثقين ونرتب لك أفضل المطابقين حسب احتياجاتك وسعر الشيفت الموجود في بروفايل كل ممرض.',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFilters() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'احتياجاتك',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _governorate,
                decoration: const InputDecoration(
                  labelText: 'المحافظة',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: governorates
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value != null) setState(() => _governorate = value);
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _areaController,
                enabled: !_loading,
                decoration: const InputDecoration(
                  labelText: 'المنطقة / المركز',
                  hintText: 'مثال: شبين الكوم، مدينة نصر',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _careType,
                decoration: const InputDecoration(
                  labelText: 'نوع الرعاية',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                items: careTypes.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value != null) setState(() => _careType = value);
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'الجنس المفضل',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('لا يهم')),
                  DropdownMenuItem(value: 'male', child: Text('ذكر')),
                  DropdownMenuItem(value: 'female', child: Text('أنثى')),
                ],
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value != null) setState(() => _gender = value);
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _specialization,
                decoration: const InputDecoration(
                  labelText: 'التخصص',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('لا يهم'),
                  ),
                  ...specializations.map(
                    (value) => DropdownMenuItem<String?>(
                      value: value,
                      child: Text(value),
                    ),
                  ),
                ],
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _specialization = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _budgetController,
                enabled: !_loading,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'الميزانية القصوى للشيفت',
                  suffixText: 'ج.م',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildResults() {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(
            child: Text('بنرتب لك أفضل الممرضين...'),
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.search_off_outlined, size: 54),
              SizedBox(height: 10),
              Text(
                'مفيش ممرضين مطابقين بالشروط الحالية',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'جرّب توسّع المنطقة أو الميزانية أو تختار "لا يهم" في الجنس والتخصص.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أفضل المطابقين لطلبك',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ..._matches.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _candidateCard(entry.key + 1, entry.value),
          ),
        ),
      ],
    );
  }

  Widget _candidateCard(int rank, DirectNurseCandidate candidate) {
    final photo = candidate.photoUrl;
    final genderLabel = candidate.gender == 'female' ? 'أنثى' : 'ذكر';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage:
                      photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty
                      ? const Icon(Icons.person_outline, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '#$rank',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              candidate.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (candidate.verified)
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.success,
                            ),
                          const SizedBox(width: 4),
                          Text(genderLabel),
                          const SizedBox(width: 9),
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            candidate.averageRating > 0
                                ? candidate.averageRating.toStringAsFixed(1)
                                : 'جديد',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      candidate.matchScore.round().toString() + '%',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'مطابقة',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (candidate.specialization.isNotEmpty)
              Text(
                candidate.specialization,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  candidate.shiftPrice.toStringAsFixed(0) + ' ج.م',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '/ ${candidate.shiftHours} ساعة',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  '${candidate.totalReviews} تقييم',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            if (candidate.matchReasons.isNotEmpty) ...[
              const SizedBox(height: 9),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: candidate.matchReasons
                    .map(
                      (reason) => Chip(
                        avatar: const Icon(Icons.check, size: 15),
                        label: Text(reason),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/client/direct-chat/${candidate.nurseId}',
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('تواصل'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push(
                      '/client/direct-booking/${candidate.nurseId}',
                    ),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('احجز'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}