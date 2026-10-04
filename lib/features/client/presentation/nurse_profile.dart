import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/nurse_profile_stats_service.dart';
import '../../../services/nurse_trust_score_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';

class NurseProfileScreen extends StatefulWidget {
  final String nurseId;
  final String requestId;

  const NurseProfileScreen({
    super.key,
    required this.nurseId,
    required this.requestId,
  });

  @override
  State<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  AppUser? _nurse;
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _verification = {};
  List<Map<String, dynamic>> _reviews = [];
  NurseProfileStats? _stats;
  NurseTrustScore? _trustScore;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    try {
      final db = FirebaseFirestore.instance;
      final results = await Future.wait([
        UserService().getUser(widget.nurseId),
        db.collection('nurseProfiles').doc(widget.nurseId).get(),
        db.collection('nurseDocuments').doc(widget.nurseId).get(),
        NurseProfileStatsService().getStats(widget.nurseId),
        NurseTrustScoreService().getScore(widget.nurseId),
        db.collection('reviews').where('nurseId', isEqualTo: widget.nurseId).limit(50).get(),
      ]);

      final nurse = results[0] as AppUser?;
      final profileDoc = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final verificationDoc = results[2] as DocumentSnapshot<Map<String, dynamic>>;
      final stats = results[3] as NurseProfileStats;
      final trustScore = results[4] as NurseTrustScore;
      final reviewSnap = results[5] as QuerySnapshot<Map<String, dynamic>>;

      if (nurse == null || nurse.role != 'nurse') {
        throw StateError('not_nurse');
      }

      final reviews = reviewSnap.docs
          .map((doc) => <String, dynamic>{...doc.data(), '_id': doc.id})
          .toList();
      reviews.sort((a, b) {
        final aDate = _timestamp(a['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = _timestamp(b['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      if (!mounted) return;
      setState(() {
        _nurse = nurse;
        _profile = profileDoc.data() ?? {};
        _verification = verificationDoc.data() ?? {};
        _stats = stats;
        _trustScore = trustScore;
        _reviews = reviews;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر تحميل ملف الممرض';
          _loading = false;
        });
      }
    }
  }

  DateTime? _timestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  List<String> _listField(String key, {String fallbackKey = ''}) {
    final primary = _profile[key];
    final value = primary is List ? primary : (fallbackKey.isNotEmpty ? _profile[fallbackKey] : null);
    if (value is! List) return [];
    return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toSet().toList();
  }

  bool get _verified =>
      _nurse?.isVerified == true ||
      _profile['isVerified'] == true ||
      _verification['verificationStatus']?.toString() == 'approved';

  String get _genderLabel {
    switch (_profile['gender']?.toString()) {
      case 'male':
        return 'ذكر';
      case 'female':
        return 'أنثى';
      default:
        return 'غير محدد';
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

  Widget _errorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, size: 56),
              const SizedBox(height: 12),
              Text(_error ?? 'الممرض غير موجود', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );

  Widget _buildProfile() {
    final services = _listField('skills', fallbackKey: 'services');
    final governorates = _listField('preferredGovernorates');
    final workAreas = _listField('workAreas');
    final experience = (_profile['experienceYears'] as num?)?.toInt() ?? 0;
    final specialization = _profile['specialization']?.toString().trim();
    final shiftPrice = (_profile['expectedPrice'] as num?)?.toDouble() ?? 0;
    final shiftHours = (_profile['shiftHours'] as num?)?.toInt() ?? 12;
    final average = (_profile['averageRating'] as num?)?.toDouble() ?? 0;
    final total = (_profile['totalReviews'] as num?)?.toInt() ?? 0;
    final distribution = Map<String, dynamic>.from(
      (_profile['ratingDistribution'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {},
    );
    final photo = (_profile['photoUrl']?.toString().trim().isNotEmpty == true)
        ? _profile['photoUrl'].toString().trim()
        : (_nurse!.photoUrl?.trim() ?? '');
    final stats = _stats ?? const NurseProfileStats(
          completedBookings: 0,
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _NurseProfileAvatar(url: photo, name: _nurse!.name),
                const SizedBox(height: 12),
                Text(
                  _nurse!.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (_verified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: AppColors.success, size: 18),
                        SizedBox(width: 6),
                        Text('موثق من شفاء', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statChip(Icons.medical_services_outlined, specialization?.isNotEmpty == true ? specialization! : 'تمريض'),
                    _statChip(Icons.workspace_premium_outlined, '$experience سنة خبرة'),
                    _statChip(_profile['gender'] == 'female' ? Icons.female : Icons.male, _genderLabel),
                    if (shiftPrice > 0)
                      _statChip(
                        Icons.payments_outlined,
                        shiftPrice.toStringAsFixed(0) + ' ج.م / ' + shiftHours.toString() + ' ساعة',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildRatingCard(average, total, distribution),
        const SizedBox(height: 12),
        _buildTrustScoreCard(),
        const SizedBox(height: 12),
        _buildPerformanceCard(stats),
        if (governorates.isNotEmpty || workAreas.isNotEmpty) ...[
          const SizedBox(height: 12),
          _section(
            'نطاق العمل',
            Icons.location_on_outlined,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (governorates.isNotEmpty) ...[
                  const Text('المحافظات', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: governorates.map((e) => Chip(label: Text(e))).toList()),
                ],
                if (workAreas.isNotEmpty) ...[
                  if (governorates.isNotEmpty) const SizedBox(height: 14),
                  const Text('المناطق', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: workAreas.map((e) => Chip(label: Text(e))).toList()),
                ],
              ],
            ),
          ),
        ],
        if (services.isNotEmpty) ...[
          const SizedBox(height: 12),
          _section(
            'المهارات والخدمات',
            Icons.volunteer_activism_outlined,
            Wrap(spacing: 8, runSpacing: 8, children: services.map((e) => Chip(label: Text(e))).toList()),
          ),
        ],
        const SizedBox(height: 12),
        _reviewsSection(),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: widget.requestId.isEmpty
                ? null
                : () => context.go('/client/request-offers/${widget.requestId}'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('العودة لعروض الطلب واختيار الممرض'),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard(
    double average,
    int total,
    Map<String, dynamic> distribution,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  average > 0 ? average.toStringAsFixed(1) : '—',
                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i + 1 <= average.round() ? Icons.star : Icons.star_border,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('$total تقييم', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var stars = 5; stars >= 1; stars--)
              _ratingRow(
                stars,
                (distribution['$stars'] as num?)?.toInt() ?? 0,
                total,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustScoreCard() {
    final trust = _trustScore;

    if (trust == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'درجة الثقة في شفاء',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: .10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    trust.scoreLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trust.score <= 0
                            ? 'لا توجد بيانات كافية حتى الآن'
                            : 'النتيجة مبنية على الأداء الفعلي للممرض',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'التقييم، الحجوزات المكتملة، وإلغاءات الممرض تدخل في حساب درجة الثقة.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _trustMetric(
                    'مكتملة',
                    trust.completedBookings.toString(),
                  ),
                ),
                Expanded(
                  child: _trustMetric(
                    'إلغاءات الممرض',
                    trust.cancelledBookings.toString(),
                  ),
                ),
                Expanded(
                  child: _trustMetric(
                    'التقييم',
                    trust.averageRating > 0
                        ? trust.averageRating.toStringAsFixed(1)
                        : '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'طريقة الحساب: التقييم 60% + الحجوزات المكتملة 25% + معدل عدم إلغاء الممرض 15%.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trustMetric(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(NurseProfileStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إحصائيات الممرض', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _metricCard(Icons.task_alt, 'حجوزات مكتملة', stats.completedBookings.toString()),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 3),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _ratingRow(int stars, int count, int total) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 18, child: Text('$stars', textAlign: TextAlign.center)),
          const Icon(Icons.star, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: fraction, minHeight: 7),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 28, child: Text('$count', textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _reviewsSection() {
    if (_reviews.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: const [
              Icon(Icons.rate_review_outlined, size: 40),
              SizedBox(height: 8),
              Text('لا توجد تقييمات بعد', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('ستظهر تقييمات العملاء هنا بعد انتهاء الحجوزات.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('آخر التقييمات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._reviews.take(5).map((review) {
              final stars = (review['rating'] as num?)?.toInt() ?? 0;
              final comment = review['comment']?.toString().trim() ?? '';
              final date = _timestamp(review['createdAt']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(i < stars ? Icons.star : Icons.star_border, size: 18, color: AppColors.primary)),
                        const Spacer(),
                        if (date != null) Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(comment),
                    ],
                    const Divider(height: 18),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(text),
          ],
        ),
      );

  Widget _section(String title, IconData icon, Widget content) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              content,
            ],
          ),
        ),
      );
}

class _NurseProfileAvatar extends StatelessWidget {
  final String url;
  final String name;

  const _NurseProfileAvatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final fallback = name.trim().isNotEmpty ? name.trim()[0] : '?';
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 52,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          fallback,
          style: const TextStyle(fontSize: 38, color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      );
    }
    return ClipOval(
      child: SizedBox(
        width: 104,
        height: 104,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primaryLight,
            alignment: Alignment.center,
            child: Text(fallback, style: const TextStyle(fontSize: 38, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}