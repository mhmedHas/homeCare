import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Auth Screens
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

// Client Screens
import '../../features/client/presentation/client_shell.dart';
import '../../features/client/presentation/client_home.dart';
import '../../features/client/presentation/create_care_request.dart';
import '../../features/client/presentation/request_details.dart';
import '../../features/client/presentation/nurse_results_screen.dart';
import '../../features/client/presentation/nurse_profile.dart';
import '../../features/client/presentation/booking_confirmation.dart';
import '../../features/client/presentation/booking_details.dart';
import '../../features/client/presentation/my_bookings.dart';
import '../../features/client/presentation/chat.dart';
import '../../features/client/presentation/messages.dart';
import '../../features/client/presentation/rating.dart';
import '../../features/client/presentation/client_profile.dart';
import '../../features/client/presentation/payment.dart';

// Nurse Screens
import '../../features/nurse/presentation/nurse_home.dart';
import '../../features/nurse/presentation/nurse_registration.dart';
import '../../features/nurse/presentation/nurse_professional_profile.dart';
import '../../features/nurse/presentation/nurse_documents.dart';
import '../../features/nurse/presentation/verification_status.dart';
import '../../features/nurse/presentation/available_requests.dart';
import '../../features/nurse/presentation/request_details_nurse.dart';
import '../../features/nurse/presentation/current_shift.dart';
import '../../features/nurse/presentation/previous_shifts.dart';
import '../../features/nurse/presentation/earnings.dart';
import '../../features/nurse/presentation/nurse_reviews.dart';
import '../../features/nurse/presentation/nurse_pro.dart';
import '../../features/nurse/presentation/nurse_profile.dart'
    hide NurseProfileScreen;

// Services
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/shared_preferences_service.dart';

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }
}

final authNotifier = AuthStateNotifier();

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  refreshListenable: authNotifier,
  redirect: _redirectLogic,
  routes: [
    // ==================== AUTH ====================
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/role',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // ==================== CLIENT ====================
    // The shell wraps every client route, so the bottom navigation remains
    // visible while navigating inside the client experience.
    ShellRoute(
      builder: (context, state, child) => ClientShell(child: child),
      routes: [
        GoRoute(
          path: '/client/home',
          builder: (context, state) => const ClientHomeScreen(),
        ),
        GoRoute(
          path: '/client/create-request',
          builder: (context, state) => const CreateCareRequestScreen(),
        ),
        GoRoute(
          path: '/client/request-details/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return RequestDetailsScreen(requestId: id);
          },
        ),
        GoRoute(
          path: '/client/nurse-results/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return NurseResultsScreen(requestId: id);
          },
        ),
        GoRoute(
          path: '/client/nurse-profile/:id',
          builder: (context, state) {
            final nurseId = state.pathParameters['id']!;
            final requestId = state.uri.queryParameters['requestId'] ?? '';
            return NurseProfileScreen(
              nurseId: nurseId,
              requestId: requestId,
            );
          },
        ),
        GoRoute(
          path: '/client/booking-confirmation/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return BookingConfirmationScreen(bookingId: id);
          },
        ),
        GoRoute(
          path: '/client/booking-details/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return BookingDetailsScreen(bookingId: id);
          },
        ),
        GoRoute(
          path: '/client/my-bookings',
          builder: (context, state) => const MyBookingsScreen(),
        ),
        GoRoute(
          path: '/client/messages',
          builder: (context, state) => const ClientMessagesScreen(),
        ),
        GoRoute(
          path: '/client/chat/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ChatScreen(bookingId: id);
          },
        ),
        GoRoute(
          path: '/client/rating/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return RatingScreen(bookingId: id);
          },
        ),
        GoRoute(
          path: '/client/payment/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return PaymentScreen(bookingId: id);
          },
        ),
        GoRoute(
          path: '/client/profile',
          builder: (context, state) => const ClientProfileScreen(),
        ),
      ],
    ),

    // ==================== NURSE ====================
    GoRoute(
      path: '/nurse/home',
      builder: (context, state) => const NurseHomeScreen(),
    ),
    GoRoute(
      path: '/nurse/registration',
      builder: (context, state) => const NurseRegistrationScreen(),
    ),
    GoRoute(
      path: '/nurse/professional-profile',
      builder: (context, state) => const NurseProfessionalProfileScreen(),
    ),
    GoRoute(
      path: '/nurse/documents',
      builder: (context, state) => const NurseDocumentsScreen(),
    ),
    GoRoute(
      path: '/nurse/verification-status',
      builder: (context, state) => const VerificationStatusScreen(),
    ),
    GoRoute(
      path: '/nurse/available-requests',
      builder: (context, state) => const AvailableRequestsScreen(),
    ),
    GoRoute(
      path: '/nurse/request-details/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RequestDetailsNurseScreen(requestId: id);
      },
    ),
    GoRoute(
      path: '/nurse/current-shift',
      builder: (context, state) => const CurrentShiftScreen(),
    ),
    GoRoute(
      path: '/nurse/previous-shifts',
      builder: (context, state) => const PreviousShiftsScreen(),
    ),
    GoRoute(
      path: '/nurse/earnings',
      builder: (context, state) => const EarningsScreen(),
    ),
    GoRoute(
      path: '/nurse/reviews',
      builder: (context, state) => const NurseReviewsScreen(),
    ),
    GoRoute(
      path: '/nurse/nurse-pro',
      builder: (context, state) => const NurseProScreen(),
    ),
    GoRoute(
      path: '/nurse/profile',
      builder: (context, state) =>
          const NurseProfileScreen(nurseId: '', requestId: ''),
    ),
  ],
);

Future<String?> _redirectLogic(
  BuildContext context,
  GoRouterState state,
) async {
  final prefs = SharedPreferencesService();
  final auth = AuthService();
  final currentPath = state.uri.path;
  final user = auth.currentUser;

  if (user == null) {
    final onboardingCompleted = prefs.isOnboardingCompleted();

    if (!onboardingCompleted &&
        currentPath != '/onboarding' &&
        currentPath != '/splash') {
      return '/onboarding';
    }

    if (onboardingCompleted) {
      const allowedPublicPaths = {
        '/login',
        '/register',
        '/role',
        '/splash',
        '/onboarding',
      };

      if (allowedPublicPaths.contains(currentPath)) {
        return null;
      }
      return '/login';
    }

    return null;
  }

  final uid = user.uid;
  final userService = UserService();
  final appUser = await userService.getUser(uid);

  if (appUser == null) {
    if (currentPath == '/role' || currentPath == '/register') {
      return null;
    }
    return '/role';
  }

  final role = appUser.role;
  const authPaths = {
    '/login',
    '/register',
    '/role',
    '/splash',
    '/onboarding',
  };

  if (authPaths.contains(currentPath)) {
    if (role == 'client') return '/client/home';
    if (role == 'nurse') return '/nurse/home';
  }

  if (role == 'client') {
    if (currentPath.startsWith('/nurse')) {
      return '/client/home';
    }
    return null;
  }

  if (role == 'nurse') {
    if (currentPath.startsWith('/client')) {
      return '/nurse/home';
    }
    return null;
  }

  await auth.logout();
  return '/login';
}
