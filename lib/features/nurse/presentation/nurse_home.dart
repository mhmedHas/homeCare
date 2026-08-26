// import 'package:flutter/material.dart';
// import '../../../core/constants/app_colors.dart';
// import '../../../services/auth_service.dart';
// import '../../../services/user_service.dart';
// import 'package:go_router/go_router.dart';

// class NurseHomeScreen extends StatefulWidget {
//   const NurseHomeScreen({super.key});

//   @override
//   State<NurseHomeScreen> createState() => _NurseHomeScreenState();
// }

// class _NurseHomeScreenState extends State<NurseHomeScreen> {
//   String _userName = 'الممرض';
//   bool _isLoading = true;
//   bool _isVerified = false;

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
//           _isVerified = appUser.isVerified;
//           _isLoading = false;
//         });
//       } else {
//         setState(() { _isLoading = false; });
//       }
//     } else {
//       setState(() { _isLoading = false; });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text('لوحة الممرض'),
//         actions: [
//           IconButton(onPressed: () => context.go('/login'), icon: const Icon(Icons.logout)),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('أهلاً، $_userName 🩺', style: Theme.of(context).textTheme.headlineMedium),
//                   const SizedBox(height: 8),
//                   if (!_isVerified)
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
//                       child: const Row(
//                         children: [
//                           Icon(Icons.warning_amber, color: Colors.amber),
//                           SizedBox(width: 8),
//                           Expanded(child: Text('أكمل توثيق حسابك لاستقبال الطلبات', style: TextStyle(color: AppColors.textPrimary))),
//                         ],
//                       ),
//                     ),
//                   const SizedBox(height: 24),
//                   Row(
//                     children: [
//                       Expanded(child: _buildStatCard('طلبات جديدة', '0', Icons.request_page)),
//                       const SizedBox(width: 12),
//                       Expanded(child: _buildStatCard('شيفت اليوم', '0', Icons.today)),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(child: _buildStatCard('الأرباح', '0 ج.م', Icons.money)),
//                       const SizedBox(width: 12),
//                       Expanded(child: _buildStatCard('التقييم', '4.5 ⭐', Icons.star)),
//                     ],
//                   ),
//                   const SizedBox(height: 32),
//                   const Text('الطلبات المتاحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 16),
//                   Card(
//                     child: ListTile(
//                       title: const Text('لا توجد طلبات حالياً'),
//                       subtitle: const Text('سيتم إظهار الطلبات المناسبة هنا'),
//                       leading: const Icon(Icons.search_off),
//                     ),
//                   ),
//                   const Spacer(),
//                   const Center(child: Text('Foundation جاهز 🚀', style: TextStyle(color: AppColors.success))),
//                 ],
//               ),
//             ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
//           BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'الطلبات'),
//           BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'الشيفتات'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
//         ],
//         currentIndex: 0,
//       ),
//     );
//   }

//   Widget _buildStatCard(String label, String value, IconData icon) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//         child: Column(
//           children: [
//             Icon(icon, color: AppColors.primary),
//             const SizedBox(height: 4),
//             Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/care_request.dart';
import '../../shared/models/booking.dart';

class NurseHomeScreen extends StatefulWidget {
  const NurseHomeScreen({super.key});

  @override
  State<NurseHomeScreen> createState() => _NurseHomeScreenState();
}

class _NurseHomeScreenState extends State<NurseHomeScreen> {
  String _userName = 'الممرض';
  bool _isLoading = true;
  bool _isVerified = false;

  // ✅ بيانات حقيقية من Firestore
  int _pendingRequestsCount = 0;
  int _todayShiftsCount = 0;
  double _totalEarnings = 0;
  double _averageRating = 0;
  List<CareRequest> _availableRequests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 1. تحميل بيانات المستخدم
      final appUser = await UserService().getUser(user.uid);
      if (appUser != null && mounted) {
        setState(() {
          _userName = appUser.name;
          _isVerified = appUser.isVerified;
        });
      }

      // 2. تحميل الطلبات المفتوحة (التي يمكن للممرض التقديم عليها)
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('careRequests')
          .where('status', isEqualTo: 'open')
          .get();

      final requests = requestsSnapshot.docs
          .map((doc) => CareRequest.fromFirestore(doc))
          .toList();

      setState(() {
        _availableRequests = requests;
        _pendingRequestsCount = requests.length;
      });

      // 3. تحميل شيفتات اليوم
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 0, 0);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59);

      final shiftsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nurseId', isEqualTo: user.uid)
          .where('status', whereIn: ['confirmed', 'in_progress'])
          .where('shiftStart', isGreaterThanOrEqualTo: todayStart)
          .where('shiftStart', isLessThanOrEqualTo: todayEnd)
          .get();

      setState(() {
        _todayShiftsCount = shiftsSnapshot.docs.length;
      });

      // 4. تحميل الأرباح (شيفتات مكتملة)
      final completedSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nurseId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      final completedShifts = completedSnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      setState(() {
        _totalEarnings =
            completedShifts.fold(0, (sum, b) => sum + b.totalAmount);
      });

      // 5. تحميل التقييمات
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('nurseId', isEqualTo: user.uid)
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        final sum = reviewsSnapshot.docs.fold<double>(
          0.0,
          (s, doc) => s + ((doc.data()['rating'] ?? 0) as num).toDouble(),
        );
        setState(() {
          _averageRating = sum / reviewsSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة الممرض'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الترحيب
                    Text(
                      'أهلاً، $_userName 🩺',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),

                    // تحذير إذا لم يتم التوثيق
                    if (!_isVerified)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.amber),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'أكمل توثيق حسابك لاستقبال الطلبات',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // بطاقات الإحصائيات
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'طلبات جديدة',
                            '$_pendingRequestsCount',
                            Icons.request_page,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'شيفت اليوم',
                            '$_todayShiftsCount',
                            Icons.today,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'الأرباح',
                            '${_totalEarnings.toStringAsFixed(0)} ج.م',
                            Icons.money,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'التقييم',
                            _averageRating > 0
                                ? '${_averageRating.toStringAsFixed(1)} ⭐'
                                : 'لا يوجد',
                            Icons.star,
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // الطلبات المتاحة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الطلبات المتاحة',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go('/nurse/available-requests'),
                          child: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ✅ قائمة الطلبات الحقيقية من Firestore
                    Expanded(
                      child: _availableRequests.isEmpty
                          ? Card(
                              child: const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'لا توجد طلبات حالياً',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'سيتم إظهار الطلبات المناسبة هنا',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _availableRequests.length > 3
                                  ? 3
                                  : _availableRequests.length,
                              itemBuilder: (context, index) {
                                final request = _availableRequests[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary,
                                      child: Text(
                                        request.patientName.isNotEmpty
                                            ? request.patientName[0]
                                            : '?',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    title: Text(request.patientName),
                                    subtitle: Text(
                                      '${request.careType} • ${request.shiftHours} ساعة • ${request.governorate}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16),
                                    onTap: () {
                                      context.go(
                                          '/nurse/request-details/${request.id}');
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'الطلبات'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'الشيفتات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              // الرئيسية
              break;
            case 1:
              context.go('/nurse/available-requests');
              break;
            case 2:
              context.go('/nurse/previous-shifts');
              break;
            case 3:
              context.go('/nurse/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
