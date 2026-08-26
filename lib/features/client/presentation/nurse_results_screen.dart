import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/user_service.dart';
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
  String _sortBy = 'rating'; // rating, price, experience

  @override
  void initState() {
    super.initState();
    _loadNurses();
  }

  Future<void> _loadNurses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'nurse')
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .get();

      final nurses =
          snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
      setState(() {
        _nurses = nurses;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في تحميل الممرضين';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<AppUser> get _sortedNurses {
    final list = List<AppUser>.from(_nurses);
    // For MVP, just sort by name, later we add rating/price from sub-collections
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
              const PopupMenuItem(
                  value: 'experience', child: Text('الأكثر خبرة')),
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
                      Text(_errorMessage!,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadNurses,
                          child: const Text('إعادة المحاولة')),
                    ]))
              : _nurses.isEmpty
                  ? const Center(child: Text('لا يوجد ممرضين متاحين حالياً'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _sortedNurses.length,
                      itemBuilder: (context, index) {
                        final nurse = _sortedNurses[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                  nurse.name.isNotEmpty ? nurse.name[0] : '?'),
                            ),
                            title: Row(
                              children: [
                                Text(nurse.name),
                                const SizedBox(width: 8),
                                if (nurse.isVerified)
                                  const Icon(Icons.verified,
                                      color: AppColors.success, size: 16),
                              ],
                            ),
                            subtitle: Text('${nurse.phone} | ${nurse.role}'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              context.go(
                                  '/client/nurse-profile/${nurse.uid}?requestId=${widget.requestId}');
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
