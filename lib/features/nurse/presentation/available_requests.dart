import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/models/care_request.dart';

class AvailableRequestsScreen extends StatefulWidget {
  const AvailableRequestsScreen({super.key});

  @override
  State<AvailableRequestsScreen> createState() =>
      _AvailableRequestsScreenState();
}

class _AvailableRequestsScreenState extends State<AvailableRequestsScreen> {
  List<CareRequest> _requests = [];
  Map<String, int> _offerCounts = {};
  List<String> _areas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        throw Exception('auth');
      }

      final profile = await FirebaseFirestore.instance
          .collection('nurseProfiles')
          .doc(uid)
          .get();

      final values = profile.data()?['preferredGovernorates'];

      _areas = values is List ? values.map((e) => e.toString()).toList() : [];

      if (_areas.isEmpty) {
        setState(() {
          _requests = [];
          _loading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('careRequests')
          .where('status', isEqualTo: 'open')
          .where(
            'governorate',
            whereIn: _areas.take(30).toList(),
          )
          .limit(50)
          .get();

      final requests = snapshot.docs.map(CareRequest.fromFirestore).toList();

      // الأحدث إنشاءً يظهر أولاً.
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final offerCounts = await _loadOfferCounts(requests);

      if (mounted) {
        setState(() {
          _requests = requests;
          _offerCounts = offerCounts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر تحميل الطلبات المناسبة لمناطق عملك';
          _loading = false;
        });
      }
    }
  }

  Future<Map<String, int>> _loadOfferCounts(List<CareRequest> requests) async {
    final counts = <String, int>{for (final request in requests) request.id: 0};
    try {
      final db = FirebaseFirestore.instance;
      for (var i = 0; i < requests.length; i += 30) {
        final batch = requests.skip(i).take(30).map((request) => request.id).toList();
        if (batch.isEmpty) continue;
        final snapshot = await db
            .collection('careOffers')
            .where('requestId', whereIn: batch)
            .get();
        for (final offer in snapshot.docs) {
          final data = offer.data();
          final requestId = data['requestId']?.toString() ?? '';
          final status = data['status']?.toString() ?? 'pending';
          if (counts.containsKey(requestId) && status == 'pending') {
            counts[requestId] = (counts[requestId] ?? 0) + 1;
          }
        }
      }
    } catch (_) {
      return {};
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات مناسبة لي'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _state(
        Icons.error_outline,
        _error!,
        'إعادة المحاولة',
        _load,
      );
    }

    if (_areas.isEmpty) {
      return _state(
        Icons.location_city,
        'حدد محافظة واحدة على الأقل من إعدادات العمل أولاً',
        'إعدادات العمل',
        () => context.push('/nurse/settings'),
      );
    }

    if (_requests.isEmpty) {
      return _state(
        Icons.search_off,
        'لا توجد طلبات مفتوحة في المحافظات التي اخترتها حالياً',
        'تعديل المحافظات',
        () => context.push('/nurse/settings'),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: _requests.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.82)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('طلبات رعاية جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${_requests.length} طلب متاح في مناطق عملك', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return _requestCard(_requests[i - 1]);
        },
      ),
    );
  }

  Widget _requestCard(CareRequest request) {
    final shortId = request.id.length > 6 ? request.id.substring(0, 6) : request.id;
    final applicants = _offerCounts[request.id];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE6EAF1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/nurse/request-details/${request.id}'),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.medical_services_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.careType.isNotEmpty ? request.careType : 'طلب رعاية منزلية',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request.patientName.isNotEmpty ? request.patientName : 'صاحب الطلب'} • #$shortId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _info(Icons.location_on_outlined, '${request.governorate} - ${request.area}'),
                  _info(Icons.schedule_outlined, '${request.shiftHours} ساعة'),
                  _info(Icons.calendar_today_outlined, DateFormat('d/M/yyyy', 'ar').format(request.startDate)),
                ],
              ),
              if (request.services.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  request.services.take(3).join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 19, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        applicants == null ? 'عدد المتقدمين غير متاح' : '$applicants ممرض مقدم',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    Text(
                      'أُضيف ${DateFormat('d/M', 'ar').format(request.createdAt)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _state(
    IconData icon,
    String title,
    String button,
    VoidCallback action,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: action,
              icon: const Icon(Icons.arrow_back),
              label: Text(button),
            ),
          ],
        ),
      ),
    );
  }
}
