import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/nurse_profile_stats_service.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../services/supabase_storage_service.dart';
import '../../../services/user_service.dart';
import '../../../core/utils/support_contact.dart';
import '../../shared/models/app_user.dart';

class NurseProfileScreen extends StatefulWidget {
  const NurseProfileScreen({super.key});

  @override
  State<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  AppUser? _user;
  Map<String, dynamic>? _nurseProfile;

  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  String? _errorMessage;
  String? _photoUrl;
  NurseProfileStats? _stats;
  bool _isVerifiedByShifa = false;

  final ImagePicker _imagePicker = ImagePicker();
  final SupabaseStorageService _storage = SupabaseStorageService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final firebaseUser = AuthService().currentUser;

      if (firebaseUser == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول';
          _isLoading = false;
        });
        return;
      }

      // Load only the data needed to render the nurse's own profile.
      // nurseDocuments and booking-based stats are protected/private reads;
      // a permission error in either must not blank the whole profile.
      final results = await Future.wait([
        UserService().getUser(firebaseUser.uid),
        FirebaseFirestore.instance
            .collection('nurseProfiles')
            .doc(firebaseUser.uid)
            .get(),
      ]);

      final appUser = results[0] as AppUser?;
      final doc = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final profileData = doc.data();

      NurseProfileStats? stats;
      try {
        stats = await NurseProfileStatsService().getStats(firebaseUser.uid);
      } catch (e) {
        debugPrint('nurse_profile: failed to load private stats: $e');
      }

      String? photoUrl;
      final profilePhoto = profileData?['photoUrl'];
      final userPhoto = appUser?.photoUrl;

      if (profilePhoto != null && profilePhoto.toString().trim().isNotEmpty) {
        photoUrl = profilePhoto.toString();
      } else if (userPhoto != null && userPhoto.trim().isNotEmpty) {
        photoUrl = userPhoto;
      }

      if (!mounted) return;

      setState(() {
        _user = appUser;
        _nurseProfile = profileData;
        _photoUrl = photoUrl;
        _stats = stats;
        // users.isVerified is the single source of truth for verification.
        _isVerifiedByShifa = appUser?.isVerified == true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل الملف الشخصي';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeProfilePhoto() async {
    if (_isUploadingPhoto) return;

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        _showMessage('يرجى تسجيل الدخول أولًا');
        return;
      }

      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) {
          return SafeArea(
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
          );
        },
      );

      if (source == null) return;

      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        _showMessage('الصورة غير صالحة');
        return;
      }

      if (mounted) setState(() => _isUploadingPhoto = true);

      final uid = firebaseUser.uid;
      final photoUrl = await _storage.uploadNurseProfilePhoto(
        uid: uid,
        bytes: bytes,
        contentType: _contentType(image.name),
      );

      final db = FirebaseFirestore.instance;

      await db.collection('users').doc(uid).set(
        {
          'photoUrl': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await db.collection('nurseProfiles').doc(uid).set(
        {
          'photoUrl': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final verificationDoc =
          await db.collection('nurseDocuments').doc(uid).get();
      final verificationData = verificationDoc.data();
      final licenseUrl =
          verificationData?['professionalLicenseUrl']?.toString();

      if (licenseUrl != null && licenseUrl.isNotEmpty) {
        await db.collection('nurseDocuments').doc(uid).set(
          {
            'uid': uid,
            'profilePhotoUrl': photoUrl,
            'verificationStatus': 'pending',
            'submittedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'rejectionReason': FieldValue.delete(),
          },
          SetOptions(merge: true),
        );
      }

      if (!mounted) return;

      setState(() {
        _photoUrl = photoUrl;
        _isUploadingPhoto = false;
      });

      _showMessage(
        licenseUrl != null && licenseUrl.isNotEmpty
            ? 'تم رفع الصورة وإرسال المستندات للمراجعة'
            : 'تم تغيير صورة البروفايل بنجاح',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      _showMessage('حدث خطأ أثناء رفع الصورة، حاول مرة أخرى');
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
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _logout() async {
    await AuthService().logout();
    await SharedPreferencesService().clearTempPreferences();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'البيانات غير موجودة',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadProfile,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 12),
          _buildProfessionalSummary(),
          const SizedBox(height: 12),
          _buildMenuItem(
            Icons.location_city_outlined,
            'إعدادات العمل والمحافظات',
            () => context.push('/nurse/settings'),
          ),
          _buildMenuItem(
            Icons.verified_user_outlined,
            'التوثيق والتحقق',
            () => context.push('/nurse/documents'),
          ),
          _buildMenuItem(
            Icons.calendar_month_outlined,
            'الشيفتات',
            () => context.push('/nurse/previous-shifts'),
          ),
          _buildMenuItem(
            Icons.payments_outlined,
            'الأرباح',
            () => context.push('/nurse/earnings'),
          ),
          _buildMenuItem(
            Icons.star_outline,
            'تقييماتي',
            () => context.push('/nurse/reviews'),
          ),
          _buildMenuItem(
            Icons.support_agent,
            'الدعم الفني والشكاوى',
            () => openSupportWhatsApp(context),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            Icons.logout,
            'تسجيل الخروج',
            _logout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _user!.name.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _changeProfilePhoto,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                        ? NetworkImage(_photoUrl!)
                        : null,
                    child: _photoUrl == null || _photoUrl!.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0] : '?',
                            style: const TextStyle(
                              fontSize: 38,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: -2,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isUploadingPhoto ? null : _changeProfilePhoto,
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'اضغط على الصورة لتغييرها',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (_isVerifiedByShifa || _user!.isVerified)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified,
                      color: AppColors.success,
                      size: 18,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'حساب موثق',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
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

  Widget _buildProfessionalSummary() {
    final profile = _nurseProfile ?? {};
    final experience = (profile['experienceYears'] as num?)?.toInt() ?? 0;
    final specialization = profile['specialization']?.toString().trim();
    final shiftPrice = (profile['expectedPrice'] as num?)?.toDouble() ?? 0;
    final shiftHours = (profile['shiftHours'] as num?)?.toInt() ?? 12;
    final gender = profile['gender']?.toString();
    final governorates = profile['preferredGovernorates'] is List
        ? (profile['preferredGovernorates'] as List)
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList()
        : <String>[];
    final stats = _stats ?? const NurseProfileStats(
      completedBookings: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخصي المهني',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _profileInfoRow(
              Icons.medical_services_outlined,
              'التخصص',
              specialization?.isNotEmpty == true ? specialization! : 'غير محدد',
            ),
            _profileInfoRow(
              Icons.workspace_premium_outlined,
              'الخبرة',
              '$experience سنة',
            ),
            _profileInfoRow(
              gender == 'female' ? Icons.female : Icons.male,
              'الجنس',
              gender == 'female'
                  ? 'أنثى'
                  : gender == 'male'
                      ? 'ذكر'
                      : 'غير محدد',
            ),
            if (shiftPrice > 0)
              _profileInfoRow(
                Icons.payments_outlined,
                'سعر الشيفت',
                shiftPrice.toStringAsFixed(0) + ' ج.م / ' + shiftHours.toString() + ' ساعة',
              ),
            _profileInfoRow(
              Icons.location_on_outlined,
              'محافظات العمل',
              governorates.isEmpty
                  ? 'غير محددة'
                  : governorates.join('، '),
            ),
            const Divider(height: 22),
            _ownMetric('حجوزات مكتملة', stats.completedBookings.toString()),
          ],
        ),
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownMetric(String title, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppColors.error : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
