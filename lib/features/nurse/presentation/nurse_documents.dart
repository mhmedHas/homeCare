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
  bool _isSubmitting = false;
  bool _isUploadingId = false;
  bool _isUploadingLicense = false;

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
    if (mounted) setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('unauthenticated');

      final doc = await FirebaseFirestore.instance
          .collection('nurseDocuments')
          .doc(uid)
          .get();
      final data = doc.data() ?? <String, dynamic>{};

      if (!mounted) return;
      setState(() {
        _nationalIdUrl = data['nationalIdUrl']?.toString();
        _licenseUrl = data['professionalLicenseUrl']?.toString();
        _verificationStatus =
            data['verificationStatus']?.toString() ?? 'not_submitted';
        _rejectionReason = data['rejectionReason']?.toString();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('تعذر تحميل بيانات التوثيق');
    }
  }

  bool get _hasId => _nationalIdUrl != null && _nationalIdUrl!.isNotEmpty;
  bool get _hasLicense => _licenseUrl != null && _licenseUrl!.isNotEmpty;
  bool get _canSubmit => _hasId && _hasLicense && !_isSubmitting;
  bool get _locked =>
      _verificationStatus == 'pending' || _verificationStatus == 'approved';

  Future<void> _pickAndUpload({required bool nationalId}) async {
    if (_locked || (nationalId ? _isUploadingId : _isUploadingLicense)) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('unauthenticated');

      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('التقاط صورة بالكاميرا'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('اختيار من المعرض'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      final image = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (image == null) return;

      setState(() {
        if (nationalId) {
          _isUploadingId = true;
        } else {
          _isUploadingLicense = true;
        }
      });

      final Uint8List bytes = await image.readAsBytes();
      final url = await _storage.uploadNurseVerificationDocument(
        uid: uid,
        documentType: nationalId ? 'national_id' : 'professional_license',
        bytes: bytes,
        contentType: _contentType(image.name),
      );

      await FirebaseFirestore.instance
          .collection('nurseDocuments')
          .doc(uid)
          .set(
        {
          'uid': uid,
          nationalId ? 'nationalIdUrl' : 'professionalLicenseUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() {
        if (nationalId) {
          _nationalIdUrl = url;
          _isUploadingId = false;
        } else {
          _licenseUrl = url;
          _isUploadingLicense = false;
        }
        if (_verificationStatus == 'rejected') {
          _verificationStatus = 'not_submitted';
          _rejectionReason = null;
        }
      });
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

  Future<void> _removeDocument({required bool nationalId}) async {
    if (_locked) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      setState(() {
        if (nationalId) {
          _nationalIdUrl = null;
        } else {
          _licenseUrl = null;
        }
      });

      await FirebaseFirestore.instance
          .collection('nurseDocuments')
          .doc(uid)
          .set(
        {
          nationalId ? 'nationalIdUrl' : 'professionalLicenseUrl':
              FieldValue.delete(),
          'verificationStatus': 'not_submitted',
          'rejectionReason': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      _showMessage('تعذر حذف الصورة');
      await _loadVerification();
    }
  }

  Future<void> _submitVerification() async {
    if (!_canSubmit) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSubmitting = true);
    try {
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
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage('تعذر إرسال طلب التوثيق');
    }
  }

  String _contentType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_verificationStatus == 'approved') {
      return _fullStatusScreen(
        icon: Icons.verified_rounded,
        title: 'حساب موثق',
        message: 'تم التحقق من بياناتك المهنية بنجاح.',
        color: AppColors.success,
      );
    }

    if (_verificationStatus == 'pending') {
      return _fullStatusScreen(
        icon: Icons.hourglass_top_rounded,
        title: 'قيد المراجعة',
        message: 'تم إرسال مستنداتك بنجاح، وسيتم مراجعتها من الإدارة.',
        color: Colors.orange,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('توثيق الحساب')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  const Text(
                    'توثيق الممرض',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ارفع صورتين واضحتين: البطاقة الشخصية وكارنيه مزاولة المهنة.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  _imageDocumentCard(
                    title: 'البطاقة الشخصية',
                    url: _nationalIdUrl,
                    uploading: _isUploadingId,
                    onAdd: () => _pickAndUpload(nationalId: true),
                    onRemove: () => _removeDocument(nationalId: true),
                  ),
                  const SizedBox(height: 16),
                  _imageDocumentCard(
                    title: 'كارنيه مزاولة المهنة',
                    url: _licenseUrl,
                    uploading: _isUploadingLicense,
                    onAdd: () => _pickAndUpload(nationalId: false),
                    onRemove: () => _removeDocument(nationalId: false),
                  ),
                  if (_verificationStatus == 'rejected') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تم رفض الطلب',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_rejectionReason != null &&
                              _rejectionReason!.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(_rejectionReason!),
                          ],
                          const SizedBox(height: 8),
                          const Text('يمكنك تعديل الصور وإرسال الطلب مرة أخرى.'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _canSubmit ? _submitVerification : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'تحقق',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageDocumentCard({
    required String title,
    required String? url,
    required bool uploading,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    final hasImage = url != null && url.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined, size: 42),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'حذف الصورة',
                            onPressed: onRemove,
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                : Material(
                    color: AppColors.surface,
                    child: InkWell(
                      onTap: onAdd,
                      child: Center(
                        child: uploading
                            ? const CircularProgressIndicator()
                            : const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 40),
                                  SizedBox(height: 8),
                                  Text('اضغط لإضافة الصورة'),
                                ],
                              ),
                      ),
                    ),
                  ),
          ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 7),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تغيير الصورة'),
          ),
        ],
      ],
    );
  }

  Widget _fullStatusScreen({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Scaffold(
      appBar: AppBar(title: const Text('توثيق الحساب')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 54, color: color),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
