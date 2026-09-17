import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  bool _isUploadingPhoto = false;
  bool _isUploadingLicense = false;
  String? _errorMessage;
  String? _photoUrl;
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

      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
        FirebaseFirestore.instance.collection('nurseProfiles').doc(uid).get(),
        FirebaseFirestore.instance.collection('nurseDocuments').doc(uid).get(),
      ]);

      final userData = results[0].data() as Map<String, dynamic>?;
      final profileData = results[1].data() as Map<String, dynamic>?;
      final verificationData = results[2].data() as Map<String, dynamic>?;

      final photo = profileData?['photoUrl'] ?? userData?['photoUrl'];
      final license = verificationData?['professionalLicenseUrl'];

      if (!mounted) return;
      setState(() {
        _photoUrl = photo?.toString();
        _licenseUrl = license?.toString();
        _verificationStatus = verificationData?['verificationStatus']?.toString() ?? 'not_submitted';
        _rejectionReason = verificationData?['rejectionReason']?.toString();
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

  Future<void> _uploadProfilePhoto() async {
    if (_isUploadingPhoto || _verificationStatus == 'pending') return;

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
                title: const Text('التقاط صورة'),
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
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image == null) return;

      if (mounted) setState(() => _isUploadingPhoto = true);
      final bytes = await image.readAsBytes();
      final url = await _storage.uploadNurseProfilePhoto(
        uid: uid,
        bytes: bytes,
        contentType: _contentType(image.name),
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'photoUrl': url, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      await FirebaseFirestore.instance.collection('nurseProfiles').doc(uid).set(
        {'photoUrl': url, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _isUploadingPhoto = false;
      });
      await _setPendingIfReady();
      _showMessage('تم رفع الصورة الشخصية بنجاح');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      _showMessage('تعذر رفع الصورة الشخصية، حاول مرة أخرى');
    }
  }

  Future<void> _uploadLicense() async {
    if (_isUploadingLicense || _verificationStatus == 'pending') return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('unauthenticated');

      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (image == null) return;

      if (mounted) setState(() => _isUploadingLicense = true);
      final ref = FirebaseStorage.instance
          .ref()
          .child('nurse_documents')
          .child(uid)
          .child('professional_license.jpg');

      await ref.putData(
        await image.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('nurseDocuments').doc(uid).set(
        {
          'uid': uid,
          'professionalLicenseUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() {
        _licenseUrl = url;
        _isUploadingLicense = false;
      });
      await _setPendingIfReady();
      _showMessage('تم رفع كارنيه مزاولة المهنة بنجاح');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploadingLicense = false);
      _showMessage('تعذر رفع كارنيه مزاولة المهنة، حاول مرة أخرى');
    }
  }

  Future<void> _setPendingIfReady() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _photoUrl == null || _photoUrl!.isEmpty || _licenseUrl == null || _licenseUrl!.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection('nurseDocuments').doc(uid).set(
      {
        'uid': uid,
        'professionalLicenseUrl': _licenseUrl,
        'profilePhotoUrl': _photoUrl,
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
          : _errorMessage != null && _photoUrl == null && _licenseUrl == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _loadVerification, child: const Text('إعادة المحاولة')),
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
                        'المطلوب للتوثيق',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'ارفع الصورة الشخصية وكارنيه مزاولة المهنة. بمجرد اكتمالهما سيتم إرسال الحساب تلقائيًا للمراجعة.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      _photoCard(),
                      const SizedBox(height: 10),
                      _licenseCard(),
                      if (_rejectionReason != null && _verificationStatus == 'rejected') ...[
                        const SizedBox(height: 14),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('سبب الرفض', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('حالة التوثيق', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 3),
                  Text(_statusLabel(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoCard() {
    final uploaded = _photoUrl != null && _photoUrl!.isNotEmpty;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: uploaded ? NetworkImage(_photoUrl!) : null,
          child: uploaded ? null : const Icon(Icons.person_outline),
        ),
        title: const Text('الصورة الشخصية'),
        subtitle: Text(uploaded ? 'تم رفع الصورة' : 'مطلوبة للتوثيق'),
        trailing: _isUploadingPhoto
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : FilledButton.tonal(
                onPressed: _verificationStatus == 'pending' ? null : _uploadProfilePhoto,
                child: Text(uploaded ? 'تغيير' : 'رفع'),
              ),
      ),
    );
  }

  Widget _licenseCard() {
    final uploaded = _licenseUrl != null && _licenseUrl!.isNotEmpty;
    return Card(
      child: ListTile(
        leading: Icon(Icons.badge_outlined, color: uploaded ? AppColors.success : AppColors.primary),
        title: const Text('كارنيه مزاولة المهنة'),
        subtitle: Text(uploaded ? 'تم رفع الكارنيه' : 'مطلوب للتوثيق'),
        trailing: _isUploadingLicense
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : uploaded
                ? IconButton(icon: const Icon(Icons.visibility_outlined), onPressed: () => _preview(_licenseUrl!))
                : FilledButton.tonal(
                    onPressed: _verificationStatus == 'pending' ? null : _uploadLicense,
                    child: const Text('رفع'),
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
