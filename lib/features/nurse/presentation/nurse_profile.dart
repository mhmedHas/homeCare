// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../../core/constants/app_colors.dart';
// import '../../../services/auth_service.dart';
// import '../../../services/user_service.dart';
// import '../../../services/shared_preferences_service.dart';
// import '../../shared/models/app_user.dart';

// class NurseProfileScreen extends StatefulWidget {
//   const NurseProfileScreen({super.key});
//   @override
//   State<NurseProfileScreen> createState() => _NurseProfileScreenState();
// }

// class _NurseProfileScreenState extends State<NurseProfileScreen> {
//   AppUser? _user;
//   Map<String, dynamic>? _nurseProfile;
//   bool _isLoading = true;
//   String? _errorMessage;

//   @override
//   void initState() { super.initState(); _loadProfile(); }

//   Future<void> _loadProfile() async {
//     setState(() { _isLoading = true; _errorMessage = null; });
//     try {
//       final user = AuthService().currentUser;
//       if (user == null) { if (mounted) setState(() => _errorMessage = 'يرجى تسجيل الدخول'); return; }
//       final results = await Future.wait([
//         UserService().getUser(user.uid),
//         FirebaseFirestore.instance.collection('nurseProfiles').doc(user.uid).get(),
//       ]);
//       final appUser = results[0] as AppUser?;
//       final doc = results[1] as DocumentSnapshot<Map<String, dynamic>>;
//       if (mounted) setState(() { _user = appUser; _nurseProfile = doc.data(); _isLoading = false; });
//     } catch (_) {
//       if (mounted) setState(() { _errorMessage = 'تعذر تحميل الملف الشخصي'; _isLoading = false; });
//     }
//   }

//   Future<void> _logout() async {
//     await AuthService().logout();
//     await SharedPreferencesService().clearTempPreferences();
//     if (mounted) context.go('/login');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('حسابي')),
//       body: _isLoading ? const Center(child: CircularProgressIndicator()) : _errorMessage != null || _user == null
//           ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_errorMessage ?? 'البيانات غير موجودة'), const SizedBox(height: 12), FilledButton(onPressed: _loadProfile, child: const Text('إعادة المحاولة'))])))
//           : RefreshIndicator(
//               onRefresh: _loadProfile,
//               child: ListView(padding: const EdgeInsets.all(16), children: [
//                 Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
//                   CircleAvatar(radius: 46, backgroundColor: AppColors.primaryLight, child: Text(_user!.name.isNotEmpty ? _user!.name[0] : '?', style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold))),
//                   const SizedBox(height: 12),
//                   Text(_user!.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
//                   if (_user!.isVerified) const Padding(padding: EdgeInsets.only(top: 6), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified, color: AppColors.success, size: 18), SizedBox(width: 5), Text('حساب موثق', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600))])),
//                   const SizedBox(height: 6),
//                   Text(_user!.phone, style: const TextStyle(color: AppColors.textSecondary)),
//                 ]))),
//                 const SizedBox(height: 12),
//                 _buildMenuItem(Icons.edit_outlined, 'الملف المهني', () => context.go('/nurse/professional-profile')),
//                 _buildMenuItem(Icons.location_city, 'إعدادات العمل والمحافظات', () => context.push('/nurse/settings')),
//                 _buildMenuItem(Icons.upload_file_outlined, 'المستندات', () => context.push('/nurse/documents')),
//                 _buildMenuItem(Icons.verified_outlined, 'حالة التحقق', () => context.push('/nurse/verification-status')),
//                 _buildMenuItem(Icons.calendar_month_outlined, 'الشيفتات', () => context.push('/nurse/previous-shifts')),
//                 _buildMenuItem(Icons.payments_outlined, 'الأرباح', () => context.push('/nurse/earnings')),
//                 _buildMenuItem(Icons.stars_outlined, 'Nurse Pro', () => context.push('/nurse/nurse-pro')),
//                 _buildMenuItem(Icons.star_outline, 'تقييماتي', () => context.push('/nurse/reviews')),
//                 const SizedBox(height: 8),
//                 _buildMenuItem(Icons.logout, 'تسجيل الخروج', _logout, isDestructive: true),
//               ]),
//             ),
//     );
//   }

//   Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary), title: Text(title, style: TextStyle(color: isDestructive ? AppColors.error : null, fontWeight: FontWeight.w500)), trailing: const Icon(Icons.chevron_left), onTap: onTap));
// }
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../services/supabase_storage_service.dart';
import '../../../services/user_service.dart';
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
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('اختيار من المعرض'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
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

      if (mounted) {
        setState(() {
          _isUploadingPhoto = true;
        });
      }

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

      if (!mounted) return;

      setState(() {
        _photoUrl = photoUrl;
        _isUploadingPhoto = false;
      });

      _showMessage('تم تغيير صورة البروفايل بنجاح');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      _showMessage('حدث خطأ أثناء رفع الصورة، حاول مرة أخرى');
    }
  }

  String _contentType(String fileName) {
    final name = fileName.toLowerCase();

    if (name.endsWith('.png')) {
      return 'image/png';
    }

    if (name.endsWith('.webp')) {
      return 'image/webp';
    }

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
      appBar: AppBar(
        title: const Text('حسابي'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null || _user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
              ),
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
          _buildMenuItem(
            Icons.edit_outlined,
            'الملف المهني',
            () => context.go('/nurse/professional-profile'),
          ),
          _buildMenuItem(
            Icons.location_city,
            'إعدادات العمل والمحافظات',
            () => context.push('/nurse/settings'),
          ),
          _buildMenuItem(
            Icons.upload_file_outlined,
            'المستندات',
            () => context.push('/nurse/documents'),
          ),
          _buildMenuItem(
            Icons.verified_outlined,
            'حالة التحقق',
            () => context.push('/nurse/verification-status'),
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
            Icons.stars_outlined,
            'Nurse Pro',
            () => context.push('/nurse/nurse-pro'),
          ),
          _buildMenuItem(
            Icons.star_outline,
            'تقييماتي',
            () => context.push('/nurse/reviews'),
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
            if (_user!.isVerified)
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
            const SizedBox(height: 6),
            Text(
              _user!.phone,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
