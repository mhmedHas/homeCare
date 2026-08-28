import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/models/care_request.dart';

class CareOffersScreen extends StatefulWidget {
  final String requestId;
  const CareOffersScreen({super.key, required this.requestId});

  @override
  State<CareOffersScreen> createState() => _CareOffersScreenState();
}

class _CareOffersScreenState extends State<CareOffersScreen> {
  bool _loading = true;
  bool _accepting = false;
  CareRequest? _request;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _offers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('auth');
      final db = FirebaseFirestore.instance;
      final requestSnap = await db.collection('careRequests').doc(widget.requestId).get();
      if (!requestSnap.exists || requestSnap.data()?['clientId'] != uid) throw Exception('not allowed');

      final offersSnap = await db
          .collection('careOffers')
          .where('requestId', isEqualTo: widget.requestId)
          .limit(50)
          .get();

      final offers = offersSnap.docs.where((doc) {
        final status = doc.data()['status']?.toString() ?? '';
        return status == 'pending' || status == 'accepted';
      }).toList();
      offers.sort((a, b) {
        final aAccepted = a.data()['status'] == 'accepted';
        final bAccepted = b.data()['status'] == 'accepted';
        if (aAccepted != bAccepted) return aAccepted ? -1 : 1;
        final aPrice = (a.data()['proposedPrice'] as num?)?.toDouble() ?? double.infinity;
        final bPrice = (b.data()['proposedPrice'] as num?)?.toDouble() ?? double.infinity;
        return aPrice.compareTo(bPrice);
      });

      if (mounted) {
        setState(() {
          _request = CareRequest.fromFirestore(requestSnap);
          _offers = offers;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _request = null; _offers = []; _loading = false; });
    }
  }

  Future<void> _accept(QueryDocumentSnapshot<Map<String, dynamic>> offer) async {
    if (_accepting) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final request = _request;
    if (uid == null || request == null) return;

    setState(() => _accepting = true);
    try {
      final db = FirebaseFirestore.instance;
      final requestRef = db.collection('careRequests').doc(request.id);
      final offerRef = db.collection('careOffers').doc(offer.id);
      final bookingRef = db.collection('bookings').doc();

      await db.runTransaction((tx) async {
        final reqSnap = await tx.get(requestRef);
        final selectedOfferSnap = await tx.get(offerRef);
        final allOffersSnap = await tx.get(
          db.collection('careOffers')
              .where('requestId', isEqualTo: request.id)
              .where('status', isEqualTo: 'pending')
              .limit(50),
        );

        if (!reqSnap.exists || reqSnap.data()?['clientId'] != uid) throw Exception('not allowed');
        if (reqSnap.data()?['status'] != 'open') throw Exception('closed');
        if (!selectedOfferSnap.exists) throw Exception('offer missing');

        final offerData = selectedOfferSnap.data()!;
        if (offerData['requestId'] != request.id || offerData['status'] != 'pending') throw Exception('offer unavailable');

        final nurseId = offerData['nurseId']?.toString() ?? '';
        final selectedPrice = (offerData['proposedPrice'] as num?)?.toDouble() ?? 0;
        final hours = (reqSnap.data()?['shiftHours'] as num?)?.toInt() ?? 0;
        final days = (reqSnap.data()?['daysCount'] as num?)?.toInt() ?? 1;
        final rawStart = reqSnap.data()?['startDate'];
        final startDate = rawStart is Timestamp ? rawStart.toDate() : DateTime.now();
        final timeParts = (reqSnap.data()?['startTime']?.toString() ?? '08:00').split(':');
        final hour = int.tryParse(timeParts.first) ?? 8;
        final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

        if (nurseId.isEmpty || selectedPrice <= 0 || !CareRequest.allowedShiftHours.contains(hours)) throw Exception('invalid offer');

        final safeHour = hour.clamp(0, 23).toInt();
        final safeMinute = minute.clamp(0, 59).toInt();
        final shiftStart = DateTime(startDate.year, startDate.month, startDate.day, safeHour, safeMinute);
        final base = selectedPrice * days;
        final platformFee = base * 0.10;

        tx.update(requestRef, {
          'status': 'booked',
          'selectedNurseId': nurseId,
          'selectedOfferId': offer.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.update(offerRef, {'status': 'accepted', 'updatedAt': FieldValue.serverTimestamp()});

        for (final other in allOffersSnap.docs) {
          if (other.id == offer.id) continue;
          tx.update(other.reference, {'status': 'rejected', 'updatedAt': FieldValue.serverTimestamp()});
        }

        tx.set(bookingRef, {
          'clientId': uid,
          'nurseId': nurseId,
          'careRequestId': request.id,
          'offerId': offer.id,
          'shiftStart': Timestamp.fromDate(shiftStart),
          'shiftEnd': Timestamp.fromDate(shiftStart.add(Duration(hours: hours))),
          'shiftHours': hours,
          'pricePerHour': selectedPrice / hours,
          'pricePerShift': selectedPrice,
          'daysCount': days,
          'platformFee': platformFee,
          'totalAmount': base + platformFee,
          'status': 'pending_payment',
          'paymentStatus': 'unpaid',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) context.go('/client/payment/${bookingRef.id}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('العرض لم يعد متاحًا. حدّث الصفحة وحاول مرة أخرى.')));
        await _load();
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_request == null) return Scaffold(
      appBar: AppBar(title: const Text('عروض الممرضين')),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 56),
        const SizedBox(height: 12),
        const Text('تعذر تحميل الطلب. تأكد من اتصالك بالإنترنت.'),
        const SizedBox(height: 12),
        FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
      ])),
    );

    final closed = _request!.status != 'open';
    return Scaffold(
      appBar: AppBar(
        title: const Text('الممرضون والعروض'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              color: closed ? AppColors.primaryLight : null,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Icon(closed ? Icons.check_circle_outline : Icons.people_alt_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(closed ? 'تم اختيار الممرض لهذا الطلب.' : 'راجع العروض والتقييمات ثم اختر الممرض المناسب.')),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            if (_offers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 90),
                child: Column(children: [
                  Icon(Icons.inbox_outlined, size: 64),
                  SizedBox(height: 12),
                  Text('لسه مفيش عروض على طلبك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('عندما يقدم ممرض عرضًا سيظهر هنا.'),
                ]),
              )
            else ..._offers.map((offer) {
              final accepted = offer.data()['status'] == 'accepted';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _card(offer, disabled: closed, accepted: accepted),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _card(QueryDocumentSnapshot<Map<String, dynamic>> offer, {required bool disabled, required bool accepted}) {
    final d = offer.data();
    final rating = (d['nurseRating'] as num?)?.toDouble() ?? 0;
    final price = (d['proposedPrice'] as num?)?.toDouble() ?? 0;
    final exp = d['nurseExperienceYears'] ?? 0;
    final photo = d['nursePhotoUrl']?.toString();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (accepted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: .10), borderRadius: BorderRadius.circular(10)),
              child: const Text('✓ الممرض المختار', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
          ],
          Row(children: [
            CircleAvatar(
              backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo == null || photo.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['nurseName']?.toString() ?? 'ممرض', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 4),
              Row(children: [
                if (d['nurseVerified'] == true) const Icon(Icons.verified, size: 16, color: AppColors.success),
                if (d['nurseVerified'] == true) const SizedBox(width: 4),
                Text(rating > 0 ? '${rating.toStringAsFixed(1)} ⭐' : 'بدون تقييم'),
                const SizedBox(width: 10),
                Text('$exp سنوات خبرة'),
              ]),
            ])),
            Text('${price.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
          ]),
          const SizedBox(height: 4),
          const Text('سعر الشيفت الواحد', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          if ((d['note'] ?? '').toString().trim().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text(d['note'].toString())),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => context.push('/client/nurse-profile/${d['nurseId']}?requestId=${widget.requestId}'),
              child: const Text('عرض الملف والتقييمات'),
            )),
            if (!accepted) ...[
              const SizedBox(width: 10),
              Expanded(child: FilledButton(
                onPressed: disabled || _accepting ? null : () => _accept(offer),
                child: Text(_accepting ? 'جاري الاختيار...' : 'اختيار الممرض'),
              )),
            ],
          ]),
        ]),
      ),
    );
  }
}
