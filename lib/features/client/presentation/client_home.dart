// import 'package:flutter/material.dart';
// import '../../../core/constants/app_colors.dart';
// import '../../../services/auth_service.dart';
// import '../../../services/user_service.dart';
// import 'package:go_router/go_router.dart';

// class ClientHomeScreen extends StatefulWidget {
//   const ClientHomeScreen({super.key});

//   @override
//   State<ClientHomeScreen> createState() => _ClientHomeScreenState();
// }

// class _ClientHomeScreenState extends State<ClientHomeScreen> {
//   String _userName = 'العميل';
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadUser();
//   }

//   Future<void> _loadUser() async {
//     final user = AuthService().currentUser;
//     if (user != null) {
//       final appUser = await UserService().getUser(user.uid);
//       if (appUser != null && mounted) {
//         setState(() {
//           _userName = appUser.name;
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     } else {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text('الرئيسية'),
//         actions: [
//           IconButton(
//               onPressed: () => context.go('/login'),
//               icon: const Icon(Icons.logout)),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('أهلاً، $_userName 👋',
//                       style: Theme.of(context).textTheme.headlineMedium),
//                   const SizedBox(height: 8),
//                   const Text(
//                       'محتاج ممرض؟ أنشئ طلب رعاية واحنا نساعدك تلاقي الشخص المناسب.',
//                       style: TextStyle(color: AppColors.textSecondary)),
//                   const SizedBox(height: 24),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                                 content: Text(
//                                     'سيتم إضافة شاشة إنشاء الطلب قريباً')));
//                       },
//                       icon: const Icon(Icons.medical_services),
//                       label: const Text('اطلب رعاية'),
//                       style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 18)),
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   const Text('الحجوزات القادمة',
//                       style:
//                           TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 16),
//                   Card(
//                     child: ListTile(
//                       title: const Text('لا توجد حجوزات حالية'),
//                       subtitle: const Text('قم بإنشاء طلب جديد للبدء'),
//                       leading: const Icon(Icons.info_outline),
//                     ),
//                   ),
//                   const Spacer(),
//                   const Center(
//                       child: Text('تم بنجاح 🎉',
//                           style: TextStyle(color: AppColors.success))),
//                 ],
//               ),
//             ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
//           BottomNavigationBarItem(icon: Icon(Icons.history), label: 'حجوزاتي'),
//           BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'الرسائل'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
//         ],
//         currentIndex: 0,
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  AppUser? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول';
        });
        return;
      }
      final appUser = await UserService().getUser(user.uid);
      if (appUser == null) {
        setState(() {
          _errorMessage = 'بيانات المستخدم غير مكتملة';
        });
        return;
      }
      setState(() {
        _user = appUser;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في تحميل البيانات';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUser,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الترحيب
                      Text(
                        'أهلاً، ${_user?.name ?? 'العميل'} 👋',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'محتاج ممرض؟ أنشئ طلب رعاية واحنا نساعدك تلاقي الشخص المناسب.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      // زر طلب رعاية (تم التعديل للانتقال إلى الشاشة الفعلية)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // ✅ الانتقال إلى شاشة إنشاء الطلب
                            context.go('/client/create-request');
                          },
                          icon: const Icon(Icons.medical_services),
                          label: const Text('اطلب رعاية'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // قسم الحجوزات القادمة
                      const Text(
                        'الحجوزات القادمة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // بطاقة الحجوزات (فارغة حالياً)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('لا توجد حجوزات حالية'),
                          subtitle: const Text('قم بإنشاء طلب جديد للبدء'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // يمكن الانتقال إلى قائمة الحجوزات
                            context.go('/client/my-bookings');
                          },
                        ),
                      ),
                      const Spacer(),

                      // نص تجريبي للإشارة إلى أن التطبيق يعمل
                      const Center(
                        child: Text(
                          'Foundation جاهز 🚀',
                          style: TextStyle(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'حجوزاتي'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'الرسائل'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              // بالفعل في الرئيسية
              break;
            case 1:
              context.go('/client/my-bookings');
              break;
            case 2:
              // سيتم تفعيله لاحقاً
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الرسائل قيد التطوير')),
              );
              break;
            case 3:
              context.go('/client/profile');
              break;
          }
        },
      ),
    );
  }
}
