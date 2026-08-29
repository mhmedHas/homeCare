import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/client/presentation/client_shell.dart';
import '../../features/client/presentation/client_home.dart';
import '../../features/client/presentation/create_care_request.dart';
import '../../features/client/presentation/request_details.dart';
import '../../features/client/presentation/nurse_results_screen.dart';
import '../../features/client/presentation/nurse_profile.dart';
import '../../features/client/presentation/booking_confirmation.dart';
import '../../features/client/presentation/booking_details.dart';
import '../../features/client/presentation/my_bookings.dart';
import '../../features/client/presentation/my_requests.dart';
import '../../features/shared/presentation/chat_screen.dart';
import '../../features/client/presentation/messages.dart';
import '../../features/client/presentation/rating.dart';
import '../../features/client/presentation/client_profile.dart';
import '../../features/client/presentation/payment.dart';
import '../../features/client/presentation/care_offers.dart';
import '../../features/nurse/presentation/nurse_shell.dart';
import '../../features/nurse/presentation/nurse_home.dart';
import '../../features/nurse/presentation/nurse_professional_profile.dart';
import '../../features/nurse/presentation/nurse_documents.dart';
import '../../features/nurse/presentation/verification_status.dart';
import '../../features/nurse/presentation/available_requests.dart';
import '../../features/nurse/presentation/request_details_nurse.dart';
import '../../features/nurse/presentation/current_shift.dart';
import '../../features/nurse/presentation/previous_shifts.dart';
import '../../features/nurse/presentation/nurse_bookings.dart';
import '../../features/nurse/presentation/nurse_messages.dart';
import '../../features/nurse/presentation/earnings.dart';
import '../../features/nurse/presentation/nurse_reviews.dart';
import '../../features/nurse/presentation/nurse_pro.dart';
import '../../features/nurse/presentation/nurse_profile.dart' as nurse_profile;
import '../../features/nurse/presentation/nurse_settings.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/shared_preferences_service.dart';

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

final authNotifier = AuthStateNotifier();

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  refreshListenable: authNotifier,
  redirect: _redirectLogic,
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/role', builder: (_, __) => const RoleSelectionScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    ShellRoute(
      builder: (_, __, child) => ClientShell(child: child),
      routes: [
        GoRoute(path: '/client/home', builder: (_, __) => const ClientHomeScreen()),
        GoRoute(path: '/client/create-request', builder: (_, __) => const CreateCareRequestScreen()),
        GoRoute(path: '/client/my-requests', builder: (_, __) => const MyRequestsScreen()),
        GoRoute(path: '/client/request-details/:id', builder: (_, s) => RequestDetailsScreen(requestId: s.pathParameters['id']!)),
        GoRoute(path: '/client/request-offers/:id', builder: (_, s) => CareOffersScreen(requestId: s.pathParameters['id']!)),
        GoRoute(path: '/client/nurse-results/:id', builder: (_, s) => NurseResultsScreen(requestId: s.pathParameters['id']!)),
        GoRoute(path: '/client/nurse-profile/:id', builder: (_, s) => NurseProfileScreen(nurseId: s.pathParameters['id']!, requestId: s.uri.queryParameters['requestId'] ?? '')),
        GoRoute(path: '/client/booking-confirmation/:id', builder: (_, s) => BookingConfirmationScreen(bookingId: s.pathParameters['id']!)),
        GoRoute(path: '/client/booking-details/:id', builder: (_, s) => BookingDetailsScreen(bookingId: s.pathParameters['id']!)),
        GoRoute(path: '/client/my-bookings', builder: (_, __) => const MyBookingsScreen()),
        GoRoute(path: '/client/messages', builder: (_, __) => const ClientMessagesScreen()),
        GoRoute(path: '/client/chat/:id', builder: (_, s) => ChatScreen(bookingId: s.pathParameters['id']!)),
        GoRoute(path: '/client/rating/:id', builder: (_, s) => RatingScreen(bookingId: s.pathParameters['id']!)),
        GoRoute(path: '/client/payment/:id', builder: (_, s) => PaymentScreen(bookingId: s.pathParameters['id']!)),
        GoRoute(path: '/client/profile', builder: (_, __) => const ClientProfileScreen()),
      ],
    ),
    ShellRoute(
      builder: (_, __, child) => NurseShell(child: child),
      routes: [
        GoRoute(path: '/nurse/home', builder: (_, __) => const NurseHomeScreen()),
        GoRoute(path: '/nurse/professional-profile', builder: (_, __) => const NurseProfessionalProfileScreen()),
        GoRoute(path: '/nurse/documents', builder: (_, __) => const NurseDocumentsScreen()),
        GoRoute(path: '/nurse/verification-status', builder: (_, __) => const VerificationStatusScreen()),
        GoRoute(path: '/nurse/available-requests', builder: (_, __) => const AvailableRequestsScreen()),
        GoRoute(path: '/nurse/request-details/:id', builder: (_, s) => RequestDetailsNurseScreen(requestId: s.pathParameters['id']!)),
        GoRoute(path: '/nurse/current-shift', builder: (_, s) => CurrentShiftScreen(bookingId: s.uri.queryParameters['bookingId'])),
        GoRoute(path: '/nurse/bookings', builder: (_, __) => const NurseBookingsScreen()),
        GoRoute(path: '/nurse/previous-shifts', builder: (_, __) => const PreviousShiftsScreen()),
        GoRoute(path: '/nurse/messages', builder: (_, __) => const NurseMessagesScreen()),
        GoRoute(path: '/nurse/chat/:id', builder: (_, s) => ChatScreen(bookingId: s.pathParameters['id']!)),
        GoRoute(path: '/nurse/earnings', builder: (_, __) => const EarningsScreen()),
        GoRoute(path: '/nurse/reviews', builder: (_, __) => const NurseReviewsScreen()),
        GoRoute(path: '/nurse/nurse-pro', builder: (_, __) => const NurseProScreen()),
        GoRoute(path: '/nurse/profile', builder: (_, __) => const nurse_profile.NurseProfileScreen()),
        GoRoute(path: '/nurse/settings', builder: (_, __) => const NurseSettingsScreen()),
      ],
    ),
  ],
);

Future<String?> _redirectLogic(BuildContext context, GoRouterState state) async {
  final prefs = SharedPreferencesService();
  final auth = AuthService();
  final currentPath = state.uri.path;
  final user = auth.currentUser;

  if (user == null) {
    final onboardingCompleted = prefs.isOnboardingCompleted();
    if (!onboardingCompleted && currentPath != '/onboarding' && currentPath != '/splash') return '/onboarding';
    const publicPaths = {'/login', '/register', '/role', '/splash', '/onboarding'};
    return publicPaths.contains(currentPath) ? null : '/login';
  }

  final appUser = await UserService().getUser(user.uid);
  if (appUser == null) return (currentPath == '/role' || currentPath == '/register') ? null : '/role';

  final role = appUser.role;
  const authPaths = {'/login', '/register', '/role', '/splash', '/onboarding'};
  if (authPaths.contains(currentPath)) {
    if (role == 'client') return '/client/home';
    if (role == 'nurse') return '/nurse/home';
  }

  if (role == 'client') return currentPath.startsWith('/nurse') ? '/client/home' : null;
  if (role == 'nurse') return currentPath.startsWith('/client') ? '/nurse/home' : null;

  await auth.logout();
  return '/login';
}
