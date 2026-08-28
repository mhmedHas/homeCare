import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class NurseShell extends StatelessWidget {
  final Widget child;
  const NurseShell({super.key, required this.child});

  int _currentIndex(String path) {
    if (path.startsWith('/nurse/available-requests') || path.startsWith('/nurse/request-details')) return 1;
    if (path.startsWith('/nurse/bookings') || path.startsWith('/nurse/current-shift')) return 2;
    if (path.startsWith('/nurse/profile') ||
        path.startsWith('/nurse/settings') ||
        path.startsWith('/nurse/documents') ||
        path.startsWith('/nurse/verification-status') ||
        path.startsWith('/nurse/professional-profile') ||
        path.startsWith('/nurse/nurse-pro') ||
        path.startsWith('/nurse/reviews') ||
        path.startsWith('/nurse/earnings')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    const routes = [
      '/nurse/home',
      '/nurse/available-requests',
      '/nurse/bookings',
      '/nurse/profile',
    ];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(path),
        onDestinationSelected: (index) => _onTap(context, index),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'الطلبات'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'حجوزاتي'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}
