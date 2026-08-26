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
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  Map<String, String> _documents = {};
  String _verificationStatus = 'not_submitted';
  String? _rejectionReason;

  final List<DocumentType> _documentTypes = [
    DocumentType(id: 'id_card', label: 'بطاقة الهوية', icon: Icons.credit_card),
    DocumentType(
        id: 'qualification', label: 'المؤهل الدراسي', icon: Icons.school),
    DocumentType(id: 'license', label: 'ترخيص المزاولة', icon: Icons.verified),
    DocumentType(
        id: 'additional',
        label: 'شهادات إضافية (اختياري)',
        icon: Icons.add_circle),
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
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

      final doc = await FirebaseFirestore.instance
          .collection('nurseDocuments')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _documents = Map<String, String>.from(data['documents'] ?? {});
          _verificationStatus = data['verificationStatus'] ?? 'not_submitted';
          _rejectionReason = data['rejectionReason'];
        });
      }
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

  Future<void> _uploadDocument(String docType, String label) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('غير مسجل دخول');

      final file = File(image.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('nurse_documents')
          .child(user.uid)
          .child('$docType.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      // Save to Firestore
      _documents[docType] = url;
      await FirebaseFirestore.instance
          .collection('nurseDocuments')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'documents': _documents,
        'verificationStatus': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _verificationStatus = 'pending';
        _rejectionReason = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تم رفع $label بنجاح')));
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في رفع الملف: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'not_submitted':
        return 'لم يتم التقديم';
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'تم التحقق ✅';
      case 'rejected':
        return 'مرفوض ❌';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'not_submitted':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستندات')),
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
                          onPressed: _loadDocuments,
                          child: const Text('إعادة المحاولة')),
                    ]))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_verificationStatus)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                                _verificationStatus == 'approved'
                                    ? Icons.check_circle
                                    : Icons.info_outline,
                                color: _getStatusColor(_verificationStatus)),
                            const SizedBox(width: 8),
                            Text(
                              'حالة المستندات: ${_getStatusLabel(_verificationStatus)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(_verificationStatus)),
                            ),
                          ],
                        ),
                      ),
                      if (_rejectionReason != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('سبب الرفض:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(_rejectionReason!),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      const Text('المستندات المطلوبة:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('يرجى رفع صورة واضحة لكل مستند',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),

                      Expanded(
                        child: ListView.builder(
                          itemCount: _documentTypes.length,
                          itemBuilder: (context, index) {
                            final doc = _documentTypes[index];
                            final isUploaded = _documents.containsKey(doc.id);
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: Icon(doc.icon,
                                    color: isUploaded
                                        ? AppColors.success
                                        : AppColors.primary),
                                title: Text(doc.label),
                                subtitle: isUploaded
                                    ? const Text('تم الرفع ✅',
                                        style:
                                            TextStyle(color: AppColors.success))
                                    : null,
                                trailing: isUploaded
                                    ? IconButton(
                                        icon: const Icon(Icons.visibility,
                                            color: AppColors.primary),
                                        onPressed: () {
                                          // Show image preview
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              child: Image.network(
                                                  _documents[doc.id]!),
                                            ),
                                          );
                                        },
                                      )
                                    : ElevatedButton(
                                        onPressed: _isUploading
                                            ? null
                                            : () => _uploadDocument(
                                                doc.id, doc.label),
                                        child: const Text('رفع'),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),

                      if (_verificationStatus == 'not_submitted' ||
                          _verificationStatus == 'rejected')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isUploading
                                ? null
                                : () async {
                                    // Submit for verification
                                    final user =
                                        FirebaseAuth.instance.currentUser;
                                    if (user != null) {
                                      await FirebaseFirestore.instance
                                          .collection('nurseDocuments')
                                          .doc(user.uid)
                                          .update({
                                        'verificationStatus': 'pending',
                                        'submittedAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                      setState(() {
                                        _verificationStatus = 'pending';
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'تم إرسال المستندات للمراجعة')));
                                    }
                                  },
                            child: const Text('إرسال للمراجعة'),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}

class DocumentType {
  final String id;
  final String label;
  final IconData icon;
  DocumentType({required this.id, required this.label, required this.icon});
}
