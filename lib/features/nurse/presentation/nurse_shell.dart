import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class NurseShell extends StatelessWidget {
  final Widget child;
  const NurseShell({super.key, required this.child});

  int _currentIndex(String path) {
    if (path.startsWith('/nurse/available-requests') || path.startsWith('/nurse/request-details')) return 1;
    if (path.startsWith('/nurse/bookings') || path.startsWith('/nurse/current-shift')) return 2;
    if (path.startsWith('/nurse/messages') || path.startsWith('/nurse/chat')) return 3;
    if (path.startsWith('/nurse/profile') ||
        path.startsWith('/nurse/settings') ||
        path.startsWith('/nurse/documents') ||
        path.startsWith('/nurse/verification-status') ||
        path.startsWith('/nurse/professional-profile') ||
        path.startsWith('/nurse/nurse-pro') ||
        path.startsWith('/nurse/reviews') ||
        path.startsWith('/nurse/earnings')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    const routes = [
      '/nurse/home',
      '/nurse/available-requests',
      '/nurse/bookings',
      '/nurse/messages',
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
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: AppStrings.t('nav_home')),
          NavigationDestination(icon: const Icon(Icons.assignment_outlined), selectedIcon: const Icon(Icons.assignment), label: AppStrings.t('nav_requests')),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: AppStrings.t('nav_bookings')),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: AppStrings.t('nav_messages')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: AppStrings.t('nav_profile')),
        ],
      ),
    );
  }
}
