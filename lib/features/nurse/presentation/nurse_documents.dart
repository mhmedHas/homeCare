import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_storage_service.dart';

class NurseDocumentsScreen extends StatefulWidget {
  const NurseDocumentsScreen({super.key});

  @override
  State<NurseDocumentsScreen> createState() => _NurseDocumentsScreenState();
}

class _NurseDocumentsScreenState extends State<NurseDocumentsScreen> {
  final _picker = ImagePicker();
  final _storage = SupabaseStorageService();

  bool _isLoading = true;
  bool _isUploadingId = false;
  bool _isUploadingLicense = false;
  String? _errorMessage;
  String? _nationalIdUrl;
  String? _licenseUrl;
  String _verificationStatus = 'not_submitted';
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _loadVerification();
  }

  Future<void> _loadVerification() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('unauthenticated');

      final doc = await FirebaseFirestore.instance
          .collection('nurseDocuments')
          .doc(uid)
          .get();
      final data = doc.data();

      if (!mounted) return;
      setState(() {
        _nationalIdUrl = data?['nationalIdUrl']?.toString();
        _licenseUrl = data?['professionalLicenseUrl']?.toString();
        _verificationStatus =
            data?['verificationStatus']?.toString() ?? 'not_submitted';
        _rejectionReason = data?['rejectionReason']?.toString();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل بيانات التوثيق';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadDocument({required bool nationalId}) async {
    if (nationalId ? _isUploadingId : _isUploadingLicense) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('unauthenticated');

      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (image == null) return;

      if (mounted) {
        setState(() {
          if (nationalId) {
            _isUploadingId = true;
          } else {
            _isUploadingLicense = true;
          }
        });
      }

      final Uint8List bytes = await image.readAsBytes();
      final url = await _storage.uploadNurseVerificationDocument(
        uid: uid,
        documentType: nationalId ? 'national_id' : 'professional_license',
        bytes: bytes,
        contentType: _contentType(image.name),
      );

      final updates = <String, dynamic>{
        'uid': uid,
        nationalId ? 'nationalIdUrl' : 'professionalLicenseUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('nurseDocuments')
          .doc(uid)
          .set(updates, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          if (nationalId) {
            _nationalIdUrl = url;
            _isUploadingId = false;
          } else {
            _licenseUrl = url;
            _isUploadingLicense = false;
          }
        });
      }

      await _setPendingIfReady();
      _showMessage(
        nationalId
            ? 'تم رفع البطاقة الشخصية بنجاح'
            : 'تم رفع كارنيه مزاولة المهنة بنجاح',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (nationalId) {
          _isUploadingId = false;
        } else {
          _isUploadingLicense = false;
        }
      });
      _showMessage('تعذر رفع الصورة، حاول مرة أخرى');
    }
  }

  Future<void> _setPendingIfReady() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final idReady = _nationalIdUrl != null && _nationalIdUrl!.isNotEmpty;
    final licenseReady = _licenseUrl != null && _licenseUrl!.isNotEmpty;

    if (uid == null || !idReady || !licenseReady) return;

    await FirebaseFirestore.instance
        .collection('nurseDocuments')
        .doc(uid)
        .set(
      {
        'uid': uid,
        'nationalIdUrl': _nationalIdUrl,
        'professionalLicenseUrl': _licenseUrl,
        'verificationStatus': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );

    if (!mounted) return;
    setState(() {
      _verificationStatus = 'pending';
      _rejectionReason = null;
    });
  }

  String _contentType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _statusLabel() {
    switch (_verificationStatus) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'تم التوثيق';
      case 'rejected':
        return 'تم الرفض';
      default:
        return 'لم يتم استكمال التوثيق';
    }
  }

  Color _statusColor() {
    switch (_verificationStatus) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon() {
    switch (_verificationStatus) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'approved':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التوثيق والتحقق')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null &&
                  _nationalIdUrl == null &&
                  _licenseUrl == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadVerification,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadVerification,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _statusCard(),
                      const SizedBox(height: 18),
                      const Text(
                        'بيانات التحقق',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'ارفع البطاقة الشخصية وكارنيه مزاولة المهنة فقط. عند اكتمال الاثنين سيتم إرسال الطلب للمراجعة تلقائيًا.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      _documentCard(
                        title: 'البطاقة الشخصية',
                        subtitle: _nationalIdUrl != null && _nationalIdUrl!.isNotEmpty
                            ? 'تم رفع البطاقة'
                            : 'مطلوبة للتوثيق',
                        icon: Icons.credit_card_outlined,
                        url: _nationalIdUrl,
                        isUploading: _isUploadingId,
                        onUpload: () => _uploadDocument(nationalId: true),
                      ),
                      const SizedBox(height: 10),
                      _documentCard(
                        title: 'كارنيه مزاولة المهنة',
                        subtitle: _licenseUrl != null && _licenseUrl!.isNotEmpty
                            ? 'تم رفع الكارنيه'
                            : 'مطلوب للتوثيق',
                        icon: Icons.badge_outlined,
                        url: _licenseUrl,
                        isUploading: _isUploadingLicense,
                        onUpload: () => _uploadDocument(nationalId: false),
                      ),
                      if (_rejectionReason != null &&
                          _verificationStatus == 'rejected') ...[
                        const SizedBox(height: 14),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'سبب الرفض',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(_rejectionReason!),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _statusCard() {
    final color = _statusColor();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(_statusIcon(), color: color, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حالة التوثيق',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _statusLabel(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? url,
    required bool isUploading,
    required VoidCallback onUpload,
  }) {
    final uploaded = url != null && url.isNotEmpty;

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: uploaded ? AppColors.success : AppColors.primary,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (uploaded)
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined),
                      onPressed: () => _preview(url!),
                    ),
                  FilledButton.tonal(
                    onPressed: onUpload,
                    child: Text(uploaded ? 'تغيير' : 'رفع'),
                  ),
                ],
              ),
      ),
    );
  }

  void _preview(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(32),
              child: Text('تعذر عرض الصورة'),
            ),
          ),
        ),
      ),
    );
  }
}
