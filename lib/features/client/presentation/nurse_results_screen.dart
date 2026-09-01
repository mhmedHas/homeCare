import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/models/app_user.dart';

class NurseResultsScreen extends StatefulWidget {
  final String requestId;
  const NurseResultsScreen({super.key, required this.requestId});

  @override
  State<NurseResultsScreen> createState() => _NurseResultsScreenState();
}

class _NurseResultsScreenState extends State<NurseResultsScreen> {
  List<AppUser> _nurses = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _sortBy = 'rating';

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

      if (!mounted) return;
      setState(() => _nurses = nurses);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'حدث خطأ في تحميل الممرضين');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AppUser> get _sortedNurses {
    final list = List<AppUser>.from(_nurses);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الممرضين المتاحين'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'rating', child: Text('أعلى تقييم')),
              const PopupMenuItem(value: 'price', child: Text('أقل سعر')),
              const PopupMenuItem(value: 'experience', child: Text('الأكثر خبرة')),
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
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadNurses, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : _nurses.isEmpty
                  ? const Center(child: Text('لا يوجد ممرضين متاحين حالياً'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _sortedNurses.length,
                      itemBuilder: (context, index) {
                        final nurse = _sortedNurses[index];
                        final photoUrl = nurse.photoUrl?.trim() ?? '';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
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
                                  const Icon(Icons.verified, color: AppColors.success, size: 16),
                              ],
                            ),
                            subtitle: Text('${nurse.phone} | ${nurse.role}'),
                            trailing: const Icon(Icons.arrow_forward_ios),
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
