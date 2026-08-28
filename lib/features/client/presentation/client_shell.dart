import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class ClientShell extends StatelessWidget {
  final Widget child;
  const ClientShell({super.key, required this.child});

  int _currentIndex(String path) {
    if (path.startsWith('/client/my-requests') ||
        path.startsWith('/client/request-details') ||
        path.startsWith('/client/request-offers') ||
        path.startsWith('/client/nurse-results') ||
        path.startsWith('/client/nurse-profile')) return 1;
    if (path.startsWith('/client/my-bookings') ||
        path.startsWith('/client/booking-details') ||
        path.startsWith('/client/payment') ||
        path.startsWith('/client/rating')) return 2;
    if (path.startsWith('/client/messages') || path.startsWith('/client/chat')) return 3;
    if (path.startsWith('/client/profile')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    const routes = [
      '/client/home',
      '/client/my-requests',
      '/client/my-bookings',
      '/client/messages',
      '/client/profile',
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
        onDestinationSelected: (index) => _onItemTapped(context, index),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'طلباتي'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'حجوزاتي'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'الرسائل'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}
