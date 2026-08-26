import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/models/review.dart';

class NurseReviewsScreen extends StatefulWidget {
  const NurseReviewsScreen({super.key});

  @override
  State<NurseReviewsScreen> createState() => _NurseReviewsScreenState();
}

class _NurseReviewsScreenState extends State<NurseReviewsScreen> {
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _averageRating = 0;
  int _totalReviews = 0;
  Map<int, int> _ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
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

      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('nurseId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final reviews =
          snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();

      setState(() {
        _reviews = reviews;
        _totalReviews = reviews.length;
        if (_totalReviews > 0) {
          _averageRating =
              reviews.fold(0, (sum, r) => sum + r.rating) / _totalReviews;
        }

        // Distribution
        for (var r in reviews) {
          _ratingDistribution[r.rating] =
              (_ratingDistribution[r.rating] ?? 0) + 1;
        }
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقييماتي')),
      body: _isLoading
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
                          onPressed: _loadReviews,
                          child: const Text('إعادة المحاولة')),
                    ]))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Overall Rating
                      Row(
                        children: [
                          const Icon(Icons.star, size: 40, color: Colors.amber),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              Text('$_totalReviews تقييم',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Rating Distribution
                      ...List.generate(5, (index) {
                        final star = 5 - index;
                        final count = _ratingDistribution[star] ?? 0;
                        final percentage = _totalReviews > 0
                            ? (count / _totalReviews * 100)
                            : 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(width: 40, child: Text('$star ⭐')),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  color: Colors.amber,
                                  minHeight: 8,
                                ),
                              ),
                              SizedBox(width: 40, child: Text('$count')),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      const Divider(),
                      const Text('التقييمات',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _reviews.isEmpty
                            ? const Center(child: Text('لا توجد تقييمات بعد'))
                            : ListView.builder(
                                itemCount: _reviews.length,
                                itemBuilder: (context, index) {
                                  final review = _reviews[index];
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              ...List.generate(
                                                  5,
                                                  (i) => Icon(
                                                        i < review.rating
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        color: Colors.amber,
                                                        size: 16,
                                                      )),
                                              const Spacer(),
                                              Text(
                                                review.createdAt.year
                                                    .toString(),
                                                style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          if (review.comment != null) ...[
                                            const SizedBox(height: 4),
                                            Text(review.comment!),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
