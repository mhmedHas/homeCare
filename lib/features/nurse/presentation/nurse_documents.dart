import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';

class NurseDocumentsScreen extends StatefulWidget {
  const NurseDocumentsScreen({super.key});

  @override
  State<NurseDocumentsScreen> createState() => _NurseDocumentsScreenState();
}

class _NurseDocumentsScreenState extends State<NurseDocumentsScreen> {
  static const _requiredDocuments = {'id_card', 'qualification'};

  final _picker = ImagePicker();
  final List<DocumentType> _documentTypes = const [
    DocumentType(id: 'id_card', label: 'بطاقة الهوية', required: true, icon: Icons.credit_card_outlined),
    DocumentType(id: 'qualification', label: 'المؤهل الدراسي', required: true, icon: Icons.school_outlined),
    DocumentType(id: 'license', label: 'ترخيص مزاولة المهنة', required: false, icon: Icons.verified_outlined),
  ];

  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  Map<String, String> _documents = {};
  String _verificationStatus = 'not_submitted';
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('unauthenticated');
      final doc = await FirebaseFirestore.instance.collection('nurseDocuments').doc(uid).get();
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data() ?? {};
        final rawDocuments = data['documents'];
        _documents = rawDocuments is Map
            ? rawDocuments.map((key, value) => MapEntry(key.toString(), value.toString()))
            : {};
        _verificationStatus = data['verificationStatus']?.toString() ?? 'not_submitted';
        _rejectionReason = data['rejectionReason']?.toString();
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'تعذر تحميل المستندات');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDocument(DocumentType type) async {
    if (_isUploading) return;
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1800);
      if (image == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('unauthenticated');

      setState(() { _isUploading = true; _errorMessage = null; });
      final ref = FirebaseStorage.instance.ref().child('nurse_documents').child(uid).child('${type.id}.jpg');
      await ref.putFile(File(image.path), SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      final updatedDocuments = Map<String, String>.from(_documents)..[type.id] = url;
      await FirebaseFirestore.instance.collection('nurseDocuments').doc(uid).set({
        'uid': uid,
        'documents': updatedDocuments,
        'verificationStatus': _verificationStatus == 'approved' ? 'approved' : 'not_submitted',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _documents = updatedDocuments;
        if (_verificationStatus != 'approved') _verificationStatus = 'not_submitted';
        _rejectionReason = null;
      });
      _showMessage('تم رفع ${type.label} بنجاح');
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'تعذر رفع المستند. تأكد من اختيار صورة واضحة وحاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submitForReview() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final missing = _requiredDocuments.where((id) => !_documents.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      _showMessage('ارفع البطاقة والمؤهل الدراسي أولاً');
      return;
    }

    setState(() => _isUploading = true);
    try {
      await FirebaseFirestore.instance.collection('nurseDocuments').doc(uid).set({
        'uid': uid,
        'documents': _documents,
        'verificationStatus': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _verificationStatus = 'pending';
        _rejectionReason = null;
      });
      _showMessage('تم إرسال المستندات للمراجعة');
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'تعذر إرسال المستندات للمراجعة');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'قيد المراجعة';
      case 'approved': return 'تم التحقق';
      case 'rejected': return 'مرفوض ويحتاج تعديل';
      default: return 'لم يتم الإرسال للمراجعة';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('توثيق الحساب')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _documents.isEmpty
              ? _errorState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _statusCard(),
                    const SizedBox(height: 16),
                    const Text('المستندات المطلوبة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('البطاقة والمؤهل الدراسي مطلوبان. ترخيص مزاولة المهنة اختياري إذا كان متاحًا.', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    ..._documentTypes.map(_documentCard),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isUploading || _verificationStatus == 'pending' || _verificationStatus == 'approved' ? null : _submitForReview,
                        icon: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_outlined),
                        label: Text(_verificationStatus == 'pending' ? 'قيد المراجعة' : _verificationStatus == 'approved' ? 'تم التحقق' : 'إرسال للمراجعة'),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _errorState() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, size: 56), const SizedBox(height: 12), Text(_errorMessage ?? 'حدث خطأ'), const SizedBox(height: 16), FilledButton.icon(onPressed: _loadDocuments, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'))])));

  Widget _statusCard() {
    final color = _statusColor(_verificationStatus);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(_verificationStatus == 'approved' ? Icons.check_circle : Icons.info_outline, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text('حالة التوثيق: ${_statusLabel(_verificationStatus)}', style: TextStyle(fontWeight: FontWeight.bold, color: color))),
          ],
        ),
      ),
    );
  }

  Widget _documentCard(DocumentType type) {
    final uploaded = _documents.containsKey(type.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(type.icon, color: uploaded ? AppColors.success : AppColors.primary),
        title: Text(type.label),
        subtitle: Text(type.required ? 'مطلوب' : 'اختياري'),
        trailing: uploaded
            ? IconButton(icon: const Icon(Icons.visibility_outlined), onPressed: () => _preview(_documents[type.id]!))
            : FilledButton.tonal(onPressed: _isUploading ? null : () => _uploadDocument(type), child: const Text('رفع')),
      ),
    );
  }

  void _preview(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(32), child: Text('تعذر عرض الصورة')))),
      ),
    );
  }
}

class DocumentType {
  final String id;
  final String label;
  final bool required;
  final IconData icon;

  const DocumentType({required this.id, required this.label, required this.required, required this.icon});
}
