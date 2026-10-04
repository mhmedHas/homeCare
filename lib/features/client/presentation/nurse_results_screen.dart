import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/nurse_trust_score_service.dart';
import '../../shared/models/app_user.dart';

class NurseResultsScreen extends StatefulWidget {
  final String requestId;

  const NurseResultsScreen({super.key, required this.requestId});

  @override
  State<NurseResultsScreen> createState() => _NurseResultsScreenState();
}

class _NurseResultsScreenState extends State<NurseResultsScreen> {
  List<AppUser> _nurses = [];
  Map<String, NurseTrustScore> _trustScores = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _sortBy = 'trust';

  @override
  void initState() {
    super.initState();
    _loadNurses();
  }

  Future<void> _loadNurses() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'nurse')
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .get();

      final nurses = snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();

      final trustScores = await NurseTrustScoreService().getScores(
        nurses.map((nurse) => nurse.uid).toList(),
      );

      if (!mounted) return;
      setState(() {
        _nurses = nurses;
        _trustScores = trustScores;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'حدث خطأ في تحميل الممرضين');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AppUser> get _sortedNurses {
    final list = List<AppUser>.from(_nurses);
    list.sort((a, b) {
      final aScore = _trustScores[a.uid];
      final bScore = _trustScores[b.uid];

      int result;
      switch (_sortBy) {
        case 'rating':
          result = (bScore?.averageRating ?? 0)
              .compareTo(aScore?.averageRating ?? 0);
          break;
        case 'price':
          final aPrice = aScore?.expectedPrice ?? 0;
          final bPrice = bScore?.expectedPrice ?? 0;
          result = aPrice.compareTo(bPrice);
          break;
        case 'experience':
          result = (bScore?.experienceYears ?? 0)
              .compareTo(aScore?.experienceYears ?? 0);
          break;
        default:
          result = (bScore?.score ?? 0).compareTo(aScore?.score ?? 0);
      }

      return result != 0 ? result : a.name.compareTo(b.name);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الممرضين المتاحين'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'trust',
                child: Text('الأكثر موثوقية'),
              ),
              PopupMenuItem(
                value: 'rating',
                child: Text('أعلى تقييم'),
              ),
              PopupMenuItem(
                value: 'price',
                child: Text('أقل سعر'),
              ),
              PopupMenuItem(
                value: 'experience',
                child: Text('الأكثر خبرة'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNurses,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _nurses.isEmpty
                  ? const Center(
                      child: Text('لا يوجد ممرضين متاحين حالياً'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _sortedNurses.length,
                      itemBuilder: (context, index) {
                        final nurse = _sortedNurses[index];
                        final trust = _trustScores[nurse.uid];
                        final photoUrl = nurse.photoUrl?.trim() ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            leading: _NurseAvatar(
                              photoUrl: photoUrl,
                              name: nurse.name,
                              radius: 28,
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    nurse.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (nurse.isVerified)
                                  const Icon(
                                    Icons.verified,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (trust != null)
                                    _InfoChip(
                                      icon: Icons.shield_outlined,
                                      label: 'موثوقية شفاء ${trust.scoreLabel}',
                                    ),
                                  if (trust != null && trust.averageRating > 0)
                                    _InfoChip(
                                      icon: Icons.star,
                                      label: trust.averageRating.toStringAsFixed(1),
                                    ),
                                  if (trust != null)
                                    _InfoChip(
                                      icon: Icons.task_alt,
                                      label: '${trust.completedBookings} مكتمل',
                                    ),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () => context.go(
                              '/client/nurse-profile/${nurse.uid}?requestId=${widget.requestId}',
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _NurseAvatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final double radius;

  const _NurseAvatar({
    required this.photoUrl,
    required this.name,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
      onBackgroundImageError: hasPhoto ? (_, __) {} : null,
      child: hasPhoto
          ? null
          : Text(
              name.trim().isNotEmpty ? name.trim()[0] : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: radius * .65,
              ),
            ),
    );
  }
}