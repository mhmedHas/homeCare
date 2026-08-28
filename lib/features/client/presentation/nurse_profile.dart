import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';

class NurseProfileScreen extends StatefulWidget {
  final String nurseId;
  final String requestId;

  const NurseProfileScreen(
      {super.key, required this.nurseId, required this.requestId});

  @override
  State<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  AppUser? _nurse;
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = FirebaseFirestore.instance;
      final nurse = await UserService().getUser(widget.nurseId);
      if (nurse == null || nurse.role != 'nurse') throw StateError('not_nurse');
      final profileDoc =
          await db.collection('nurseProfiles').doc(widget.nurseId).get();
      final reviewsSnap = await db
          .collection('reviews')
          .where('nurseId', isEqualTo: widget.nurseId)
          .limit(20)
          .get();
      final reviews = reviewsSnap.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{...data, '_id': doc.id};
      }).toList();
      reviews.sort((a, b) {
        final aDate = (a['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = (b['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      if (!mounted) return;
      setState(() {
        _nurse = nurse;
        _profile = profileDoc.data() ?? {};
        _reviews = reviews;
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'تعذر تحميل ملف الممرض';
          _loading = false;
        });
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_off_outlined, size: 56),
            const SizedBox(height: 12),
            Text(_error ?? 'الممرض غير موجود', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة')),
          ]),
        ),
      );

  Widget _buildProfile() {
    final services = _profile['services'] is List
        ? (_profile['services'] as List)
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList()
        : <String>[];
    final areas = _profile['preferredGovernorates'] is List
        ? (_profile['preferredGovernorates'] as List)
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList()
        : <String>[];
    final experience = _profile['experienceYears']?.toString() ?? 'غير محدد';
    final specialization = _profile['specialization']?.toString() ?? 'تمريض';
    final verified = _nurse!.isVerified;
    final average = (_profile['averageRating'] as num?)?.toDouble() ?? 0;
    final total = (_profile['totalReviews'] as num?)?.toInt() ?? 0;
    final distribution = Map<String, dynamic>.from(
        (_profile['ratingDistribution'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), v)) ??
            {});

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                          _nurse!.name.isNotEmpty
                              ? _nurse!.name.characters.first
                              : '?',
                          style: TextStyle(
                              fontSize: 34,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(height: 12),
                  Text(_nurse!.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center),
                  if (verified) ...[
                    const SizedBox(height: 6),
                    const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified,
                              color: AppColors.success, size: 19),
                          SizedBox(width: 5),
                          Text('ممرض موثق',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700))
                        ])
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _stat(Icons.medical_services_outlined, specialization),
                        _stat(Icons.workspace_premium_outlined,
                            '$experience سنوات خبرة')
                      ]),
                ]))),
        const SizedBox(height: 12),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(average > 0 ? average.toStringAsFixed(1) : '—',
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              children: List.generate(
                                  5,
                                  (i) => Icon(
                                      i < average.round()
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: AppColors.primary,
                                      size: 22))),
                          const SizedBox(height: 3),
                          Text('$total تقييم',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ]),
                  ]),
                  const SizedBox(height: 16),
                  for (var stars = 5; stars >= 1; stars--)
                    _ratingRow(stars,
                        (distribution['$stars'] as num?)?.toInt() ?? 0, total),
                ]))),
        const SizedBox(height: 12),
        if (areas.isNotEmpty)
          _section(
              'محافظات العمل',
              Icons.location_on_outlined,
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      areas.map((area) => Chip(label: Text(area))).toList())),
        if (services.isNotEmpty) ...[
          const SizedBox(height: 12),
          _section(
              'الخدمات المقدمة',
              Icons.volunteer_activism_outlined,
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: services
                      .map((service) => Chip(label: Text(service)))
                      .toList()))
        ],
        const SizedBox(height: 12),
        _reviewsSection(),
        const SizedBox(height: 18),
        SizedBox(
            height: 52,
            child: FilledButton.icon(
                onPressed: widget.requestId.isEmpty
                    ? null
                    : () => context
                        .go('/client/request-offers/${widget.requestId}'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('العودة لعروض الطلب واختيار الممرض'))),
      ],
    );
  }

  Widget _ratingRow(int stars, int count, int total) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
              width: 18, child: Text('$stars', textAlign: TextAlign.center)),
          const Icon(Icons.star, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      LinearProgressIndicator(value: fraction, minHeight: 7))),
          const SizedBox(width: 8),
          SizedBox(
              width: 28,
              child: Text('$count',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary))),
        ]));
  }

  Widget _reviewsSection() {
    if (_reviews.isEmpty) {
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                const Icon(Icons.rate_review_outlined, size: 40),
                const SizedBox(height: 8),
                const Text('لا توجد تقييمات بعد',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('ستظهر تقييمات العملاء هنا بعد انتهاء الحجوزات.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary))
              ])));
    }
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('آخر التقييمات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._reviews.take(5).map((review) {
                final stars = (review['rating'] as num?)?.toInt() ?? 0;
                final comment = review['comment']?.toString().trim() ?? '';
                final date = (review['createdAt'] as Timestamp?)?.toDate();
                return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            ...List.generate(
                                5,
                                (i) => Icon(
                                    i < stars ? Icons.star : Icons.star_border,
                                    size: 18,
                                    color: AppColors.primary)),
                            const Spacer(),
                            if (date != null)
                              Text('${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                          ]),
                          if (comment.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(comment)
                          ],
                          const Divider(height: 18),
                        ]));
              }),
            ])));
  }

  Widget _stat(IconData icon, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text)
      ]));

  Widget _section(String title, IconData icon, Widget content) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 12),
            content
          ])));
}
