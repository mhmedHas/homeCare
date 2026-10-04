import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/care_request_service.dart';
import '../../../services/nurse_smart_matching_service.dart';
import '../../shared/models/care_request.dart';

class SmartMatchScreen extends StatefulWidget {
  final String requestId;

  const SmartMatchScreen({super.key, required this.requestId});

  @override
  State<SmartMatchScreen> createState() => _SmartMatchScreenState();
}

class _SmartMatchScreenState extends State<SmartMatchScreen> {
  final _specializationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _experienceController = TextEditingController();
  final _conditionController = TextEditingController();

  CareRequest? _request;
  List<SmartMatchCandidate> _matches = [];
  String _preferredGender = 'any';
  bool _loading = true;
  bool _matching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      final request = await CareRequestService().getRequest(widget.requestId);
      if (!mounted) return;
      if (request == null) {
        setState(() {
          _error = 'طلب الرعاية غير موجود';
          _loading = false;
        });
        return;
      }
      setState(() {
        _request = request;
        _loading = false;
      });
      await _findMatches();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل طلب الرعاية';
        _loading = false;
      });
    }
  }

  Future<void> _findMatches() async {
    if (_request == null || _matching) return;

    setState(() {
      _matching = true;
      _error = null;
    });

    try {
      final budget = double.tryParse(_budgetController.text.trim());
      final experience = int.tryParse(_experienceController.text.trim());

      final matches = await NurseSmartMatchingService().findBestMatches(
        requestId: widget.requestId,
        preferredGender: _preferredGender,
        specialization: _specializationController.text.trim(),
        maxBudget: budget,
        minExperienceYears: experience,
        specialCondition: _conditionController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _matches = matches;
        _matching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر العثور على الممرضين المناسبين';
        _matching = false;
      });
    }
  }

  @override
  void dispose() {
    _specializationController.dispose();
    _budgetController.dispose();
    _experienceController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

    return Scaffold(
      appBar: AppBar(title: const Text('اعثر لي على الممرض المناسب')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : request == null
              ? Center(child: Text(_error ?? 'طلب الرعاية غير موجود'))
              : RefreshIndicator(
                  onRefresh: _findMatches,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildIntro(),
                      const SizedBox(height: 12),
                      _buildRequestSummary(request),
                      const SizedBox(height: 12),
                      _buildPreferences(),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _matching ? null : _findMatches,
                          icon: _matching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _matching
                                ? 'جاري تحليل أفضل الممرضين...'
                                : 'اعثر لي على أفضل 3',
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
                      const SizedBox(height: 16),
                      _buildResults(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildIntro() => Card(
        color: AppColors.primaryLight,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 34),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مطابقة ذكية من شفاء',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'بنرشح لك أفضل 3 ممرضين من العروض الحالية حسب احتياجاتك وتقييماتهم وخبرتهم والسعر.',
                      style: TextStyle(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildRequestSummary(CareRequest request) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'بيانات طلبك',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _summaryRow(Icons.location_city, 'المحافظة', request.governorate),
              _summaryRow(Icons.place_outlined, 'المنطقة', request.area),
              _summaryRow(Icons.medical_services_outlined, 'نوع الرعاية', request.careType),
              _summaryRow(Icons.schedule, 'الشيفت', '${request.shiftHours} ساعة'),
              _summaryRow(Icons.calendar_today_outlined, 'التاريخ', DateFormat('d/M/yyyy', 'ar').format(request.startDate)),
            ],
          ),
        ),
      );

  Widget _buildPreferences() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تفضيلات الممرض',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _preferredGender,
                decoration: const InputDecoration(
                  labelText: 'النوع المفضل',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('لا يهم')),
                  DropdownMenuItem(value: 'male', child: Text('ذكر')),
                  DropdownMenuItem(value: 'female', child: Text('أنثى')),
                ],
                onChanged: _matching
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _preferredGender = value);
                        }
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _specializationController,
                enabled: !_matching,
                decoration: const InputDecoration(
                  labelText: 'التخصص المطلوب (اختياري)',
                  hintText: 'مثال: تمريض باطني، عناية مسنين',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _budgetController,
                enabled: !_matching,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'الميزانية القصوى للشيفت (اختياري)',
                  suffixText: 'ج.م',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _experienceController,
                enabled: !_matching,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الخبرة المطلوبة (سنوات - اختياري)',
                  prefixIcon: Icon(Icons.work_history_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _conditionController,
                enabled: !_matching,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'معدات لازمة / حالة خاصة (اختياري)',
                  hintText: 'مثال: تغيير جرح، قياس سكر، متابعة بعد عملية',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildResults() {
    if (_matching) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(
            child: Text('بنحلل العروض ونختار أفضل 3 ممرضين...'),
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.search_off_outlined, size: 52),
              const SizedBox(height: 10),
              const Text(
                'لسه مفيش 3 ممرضين مناسبين',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'انتظر وصول عروض جديدة أو جرّب تخفيف بعض التفضيلات.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
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
          'أفضل 3 ممرضين لك',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ..._matches.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _candidateCard(entry.key + 1, entry.value),
          ),
        ),
      ],
    );
  }

  Widget _candidateCard(int rank, SmartMatchCandidate candidate) {
    final photo = candidate.photoUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty
                      ? Text(
                          candidate.nurseName.isNotEmpty ? candidate.nurseName[0] : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              candidate.nurseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 17, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(candidate.rating > 0 ? candidate.rating.toStringAsFixed(1) : 'بدون تقييم'),
                          const SizedBox(width: 10),
                          Text('${candidate.experienceYears} سنوات خبرة'),
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
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      'نسبة المطابقة',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            if (candidate.specialization.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                candidate.specialization,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: candidate.matchedReasons
                  .map(
                    (reason) => Chip(
                      avatar: const Icon(Icons.check, size: 15),
                      label: Text(reason),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  candidate.offerPrice > 0
                      ? candidate.offerPrice.toStringAsFixed(0) + ' ج.م / الشيفت'
                      : 'السعر غير محدد',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => context.push(
                    '/client/nurse-profile/${candidate.nurseId}?requestId=${widget.requestId}',
                  ),
                  child: const Text('عرض الملف'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => context.push(
                    '/client/request-offers/${widget.requestId}?highlightOfferId=${candidate.offerId}',
                  ),
                  child: const Text('اختيار'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Flexible(
              child: Text(
                value.isEmpty ? 'غير محدد' : value,
                textAlign: TextAlign.end,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
}