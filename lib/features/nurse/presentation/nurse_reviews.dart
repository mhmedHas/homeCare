import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/review_service.dart';
import '../../shared/models/review.dart';

class NurseReviewsScreen extends StatefulWidget {
  const NurseReviewsScreen({super.key});

  @override
  State<NurseReviewsScreen> createState() => _NurseReviewsScreenState();
}

class _NurseReviewsScreenState extends State<NurseReviewsScreen> {
  final _service = ReviewService();
  List<Review> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('auth');
      final reviews = await _service.getNurseReviews(user.uid, limit: 100);
      if (!mounted) return;
      setState(() => _reviews = reviews);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحميل التقييمات. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _average {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold<int>(0, (sum, r) => sum + r.rating) / _reviews.length;
  }

  Map<int, int> get _distribution {
    final result = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in _reviews) {
      if (result.containsKey(review.rating)) result[review.rating] = result[review.rating]! + 1;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(appBar: AppBar(title: const Text('تقييماتي')), body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, style: const TextStyle(color: AppColors.error)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: _loadReviews, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
      ])));
    }

    final distribution = _distribution;
    return Scaffold(
      appBar: AppBar(title: const Text('تقييماتي'), automaticallyImplyLeading: false, actions: [IconButton(onPressed: _loadReviews, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
              const Icon(Icons.star, size: 44, color: Colors.amber),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_average.toStringAsFixed(1), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                Text('${_reviews.length} تقييم', style: const TextStyle(color: AppColors.textSecondary)),
              ]),
            ]))),
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: List.generate(5, (index) {
              final star = 5 - index;
              final count = distribution[star] ?? 0;
              final value = _reviews.isEmpty ? 0.0 : count / _reviews.length;
              return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                SizedBox(width: 42, child: Text('$star ⭐')),
                Expanded(child: LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: Colors.grey.shade200, color: Colors.amber)),
                SizedBox(width: 35, child: Text('$count', textAlign: TextAlign.end)),
              ]));
            }))),),
            const SizedBox(height: 18),
            const Text('آراء العملاء', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_reviews.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: Text('لسه مفيش تقييمات')))
            else
              ..._reviews.map((review) => Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  ...List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 18)),
                  const Spacer(),
                  Text('${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
                if (review.comment?.trim().isNotEmpty == true) ...[const SizedBox(height: 8), Text(review.comment!)],
              ])))),
          ],
        ),
      ),
    );
  }
}
