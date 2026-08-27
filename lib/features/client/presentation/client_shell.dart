import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Persistent navigation container for the client area.
///
/// All client routes live inside this shell, so the bottom navigation remains
/// visible while moving between client screens instead of disappearing on
/// every navigation.
class ClientShell extends StatelessWidget {
  final Widget child;

  const ClientShell({super.key, required this.child});

  int _currentIndex(String path) {
    if (path.startsWith('/client/my-bookings') ||
        path.startsWith('/client/booking-details')) {
      return 1;
    }
    if (path.startsWith('/client/messages') ||
        path.startsWith('/client/chat')) {
      return 2;
    }
    if (path.startsWith('/client/profile')) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/client/home');
        break;
      case 1:
        context.go('/client/my-bookings');
        break;
      case 2:
        context.go('/client/messages');
        break;
      case 3:
        context.go('/client/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _currentIndex(path);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'حجوزاتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'الرسائل',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
