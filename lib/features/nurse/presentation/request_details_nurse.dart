import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../shared/models/care_request.dart';

class RequestDetailsNurseScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailsNurseScreen({super.key, required this.requestId});
  @override
  State<RequestDetailsNurseScreen> createState() => _RequestDetailsNurseScreenState();
}

class _RequestDetailsNurseScreenState extends State<RequestDetailsNurseScreen> {
  CareRequest? _request;
  bool _loading = true;
  bool _sending = false;
  bool _alreadyApplied = false;
  final _price = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final snap = await FirebaseFirestore.instance.collection('careRequests').doc(widget.requestId).get();
      if (!snap.exists) throw Exception('missing');
      final request = CareRequest.fromFirestore(snap);
      if (uid != null) {
        final offer = await FirebaseFirestore.instance.collection('careOffers').where('requestId', isEqualTo: widget.requestId).where('nurseId', isEqualTo: uid).limit(1).get();
        _alreadyApplied = offer.docs.isNotEmpty;
      }
      if (mounted) setState(() { _request = request; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitOffer() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final request = _request;
    final price = double.tryParse(_price.text.trim());
    if (uid == null || request == null || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب سعر الشيفت بشكل صحيح')));
      return;
    }
    if (request.status != 'open') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الطلب لم يعد متاحاً للتقديم')));
      return;
    }
    setState(() => _sending = true);
    try {
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final profileSnap = await FirebaseFirestore.instance.collection('nurseProfiles').doc(uid).get();
      final userData = userSnap.data() ?? {};
      final profile = profileSnap.data() ?? {};
      final ref = FirebaseFirestore.instance.collection('careOffers').doc();
      await ref.set({
        'requestId': request.id,
        'clientId': request.clientId,
        'nurseId': uid,
        'nurseName': userData['name'] ?? 'ممرض',
        'nursePhotoUrl': userData['photoUrl'],
        'nurseRating': (profile['averageRating'] ?? 0).toDouble(),
        'nurseExperienceYears': profile['experienceYears'] ?? 0,
        'nurseVerified': userData['isVerified'] == true,
        'governorate': request.governorate,
        'proposedPrice': price,
        'note': _note.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() { _alreadyApplied = true; _sending = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال عرضك للعميل')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إرسال العرض، حاول مرة أخرى')));
      }
    }
  }

  @override
  void dispose() { _price.dispose(); _note.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final r = _request;
    if (r == null) return const Scaffold(body: Center(child: Text('الطلب غير موجود')));
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('طلب رعاية', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _row('نوع الرعاية', r.careType), _row('العمر', '${r.patientAge} سنة'),
          _row('الجنس', r.patientGender == 'male' ? 'ذكر' : 'أنثى'),
          _row('الشيفت', '${r.shiftHours} ساعة × ${r.daysCount} يوم'),
          _row('التاريخ', DateFormat('d/M/yyyy').format(r.startDate)),
          _row('المحافظة', r.governorate), _row('المنطقة', r.area),
          const SizedBox(height: 8), Text(r.services.join(' • '), style: const TextStyle(color: AppColors.textSecondary)),
          if (r.notes?.isNotEmpty == true) ...[const SizedBox(height: 10), Text(r.notes!)],
        ]))),
        const SizedBox(height: 16),
        if (_alreadyApplied)
          Card(color: AppColors.primaryLight, child: const Padding(padding: EdgeInsets.all(18), child: Row(children: [Icon(Icons.check_circle, color: AppColors.primary), SizedBox(width: 10), Expanded(child: Text('قدمت عرضك بالفعل. انتظر اختيار العميل.'))])))
        else if (r.status == 'open') ...[
          Text('قدم عرضك', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'سعر الشيفت المقترح', suffixText: 'ج.م', prefixIcon: Icon(Icons.payments_outlined))),
          const SizedBox(height: 12),
          TextField(controller: _note, maxLines: 3, decoration: const InputDecoration(labelText: 'رسالة للعميل (اختياري)', alignLabelWithHint: true, prefixIcon: Icon(Icons.message_outlined))),
          const SizedBox(height: 16),
          SizedBox(height: 52, child: FilledButton(onPressed: _sending ? null : _submitOffer, child: _sending ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('إرسال العرض'))),
        ] else
          const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('هذا الطلب لم يعد متاحاً للتقديم.'))),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 95, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))), Expanded(child: Text(value))]));
}
