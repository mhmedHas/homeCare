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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final requestSnap = await FirebaseFirestore.instance.collection('careRequests').doc(widget.requestId).get();
      if (!requestSnap.exists || requestSnap.data()?['clientId'] != uid) throw Exception('not allowed');
      final offers = await FirebaseFirestore.instance.collection('careOffers').where('requestId', isEqualTo: widget.requestId).where('status', isEqualTo: 'pending').limit(50).get();
      offers.docs.sort((a,b) => ((a.data()['proposedPrice'] ?? 0) as num).compareTo((b.data()['proposedPrice'] ?? 0) as num));
      if (mounted) setState(() { _request = CareRequest.fromFirestore(requestSnap); _offers = offers.docs; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _accept(QueryDocumentSnapshot<Map<String, dynamic>> offer) async {
    if (_accepting) return;
    final request = _request;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (request == null || uid == null) return;
    setState(() => _accepting = true);
    try {
      final db = FirebaseFirestore.instance;
      final bookingRef = db.collection('bookings').doc();
      final requestRef = db.collection('careRequests').doc(request.id);
      final offerRef = db.collection('careOffers').doc(offer.id);
      await db.runTransaction((tx) async {
        final reqSnap = await tx.get(requestRef);
        if (!reqSnap.exists || reqSnap.data()?['clientId'] != uid || reqSnap.data()?['status'] != 'open') throw Exception('closed');
        final data = reqSnap.data()!;
        final selectedPricePerShift = ((offer.data()['proposedPrice'] ?? 0) as num).toDouble();
        final hours = ((data['shiftHours'] ?? 0) as num).toInt();
        final days = ((data['daysCount'] ?? 1) as num).toInt();
        if (selectedPricePerShift <= 0 || hours <= 0) throw Exception('invalid price');
        final base = selectedPricePerShift * days;
        final fee = base * 0.10;
        final start = (data['startDate'] as Timestamp).toDate();
        final parts = (data['startTime'] as String? ?? '0:0').split(':');
        final shiftStart = DateTime(start.year, start.month, start.day, int.tryParse(parts[0]) ?? 0, int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
        tx.update(requestRef, {'status':'booked','selectedNurseId':offer.data()['nurseId'],'selectedOfferId':offer.id,'updatedAt':FieldValue.serverTimestamp()});
        tx.update(offerRef, {'status':'accepted','updatedAt':FieldValue.serverTimestamp()});
        tx.set(bookingRef, {
          'clientId': uid,
          'nurseId': offer.data()['nurseId'],
          'careRequestId': request.id,
          'offerId': offer.id,
          'shiftStart': Timestamp.fromDate(shiftStart),
          'shiftEnd': Timestamp.fromDate(shiftStart.add(Duration(hours: hours))),
          'shiftHours': hours,
          'pricePerHour': selectedPricePerShift / hours,
          'pricePerShift': selectedPricePerShift,
          'daysCount': days,
          'platformFee': fee,
          'totalAmount': base + fee,
          'status': 'pending_payment',
          'paymentStatus': 'unpaid',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      if (mounted) context.go('/client/payment/${bookingRef.id}');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('العرض لم يعد متاحاً، حدّث الصفحة وحاول مرة أخرى')));
    } finally { if (mounted) setState(() => _accepting = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_request == null) return const Scaffold(body: Center(child: Text('الطلب غير موجود')));
    return Scaffold(
      appBar: AppBar(title: const Text('عروض الممرضين')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _offers.isEmpty
            ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height:140), Icon(Icons.inbox_outlined, size:64), SizedBox(height:12), Center(child: Text('لسه مفيش عروض على طلبك', style: TextStyle(fontSize:18,fontWeight:FontWeight.bold))), SizedBox(height:8), Center(child: Text('هنعرض هنا الممرضين اللي قدموا على الطلب.'))])
            : ListView.separated(padding: const EdgeInsets.all(16), itemCount: _offers.length, separatorBuilder: (_,__) => const SizedBox(height:10), itemBuilder: (_,i) => _card(_offers[i])),
      ),
    );
  }

  Widget _card(QueryDocumentSnapshot<Map<String,dynamic>> offer) {
    final d = offer.data();
    final rating = ((d['nurseRating'] ?? 0) as num).toDouble();
    final price = ((d['proposedPrice'] ?? 0) as num).toDouble();
    final exp = d['nurseExperienceYears'] ?? 0;
    final photo = d['nursePhotoUrl'] as String?;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(backgroundImage: photo?.isNotEmpty == true ? NetworkImage(photo!) : null, child: photo?.isNotEmpty == true ? null : const Icon(Icons.person)), const SizedBox(width:12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['nurseName'] ?? 'ممرض', style: const TextStyle(fontWeight: FontWeight.bold,fontSize:17)), Row(children: [if (d['nurseVerified'] == true) const Icon(Icons.verified,size:16,color:AppColors.success), const SizedBox(width:4), Text(rating > 0 ? '${rating.toStringAsFixed(1)} ⭐' : 'بدون تقييم'), const SizedBox(width:10), Text('$exp سنوات خبرة')])])), Text('${price.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight:FontWeight.bold,fontSize:18,color:AppColors.primary))]),
      const SizedBox(height: 4),
      const Text('سعر الشيفت الواحد', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      if ((d['note'] ?? '').toString().trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top:12), child: Text(d['note'].toString())),
      const SizedBox(height:12),
      Row(children: [Expanded(child: OutlinedButton(onPressed: () => context.push('/client/nurse-profile/${d['nurseId']}?requestId=${widget.requestId}'), child: const Text('عرض الملف'))), const SizedBox(width:10), Expanded(child: FilledButton(onPressed: _accepting ? null : () => _accept(offer), child: const Text('اختيار الممرض')))]),
    ])));
  }
}
