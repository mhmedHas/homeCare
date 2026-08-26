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
import '../../features/client/presentation/client_home.dart';
import '../../features/client/presentation/create_care_request.dart';
import '../../features/client/presentation/request_details.dart';
import '../../features/client/presentation/nurse_results_screen.dart';
import '../../features/client/presentation/nurse_profile.dart';
import '../../features/client/presentation/booking_confirmation.dart';
import '../../features/client/presentation/booking_details.dart';
import '../../features/client/presentation/my_bookings.dart';
import '../../features/client/presentation/chat.dart';
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

// ============================================================
//  AuthStateNotifier – لإعلام GoRouter بتغير حالة المصادقة
// ============================================================
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      // عند تغير حالة تسجيل الدخول، يُعلم GoRouter لإعادة تقييم التوجيه
      notifyListeners();
    });
  }
}

final authNotifier = AuthStateNotifier();

// ============================================================
//  تكوين GoRouter
// ============================================================
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  refreshListenable: authNotifier, // 🔄 يستمع لتغيرات حالة المصادقة
  redirect: _redirectLogic,
  routes: [
    // === Auth Routes ===
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

    // === Client Routes ===
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
        return NurseProfileScreen(nurseId: nurseId, requestId: requestId);
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

    // === Nurse Routes ===
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

// ============================================================
//  منطق إعادة التوجيه – يحل مشكلة التوجيه اللانهائي
// ============================================================
Future<String?> _redirectLogic(
    BuildContext context, GoRouterState state) async {
  final prefs = SharedPreferencesService();
  final auth = AuthService();
  final currentPath = state.uri.path;

  // 1. المستخدم الحالي
  final user = auth.currentUser;

  // ──────────────────────────────────────────────────────────────
  //  الحالة 1: المستخدم غير مسجل الدخول
  // ──────────────────────────────────────────────────────────────
  if (user == null) {
    final isOnboarding = prefs.isOnboardingCompleted();

    // إذا لم يكمل Onboarding، أرسله إلى شاشة Onboarding (ما لم يكن موجوداً)
    if (!isOnboarding &&
        currentPath != '/onboarding' &&
        currentPath != '/splash') {
      return '/onboarding';
    }

    // بعد إكمال Onboarding، اسمح بالوصول إلى صفحات المصادقة فقط
    if (isOnboarding) {
      // الصفحات المسموح بها للمستخدم غير المسجل
      final allowedPublicPaths = [
        '/login',
        '/register',
        '/role',
        '/splash',
        '/onboarding',
      ];
      if (allowedPublicPaths.contains(currentPath)) {
        return null; // لا إعادة توجيه، ابق في الصفحة الحالية
      }
      // أي مسار آخر (مثلاً /client/home) -> أرسل إلى login
      return '/login';
    }

    // لا يزال في عملية Onboarding
    return null;
  }

  // ──────────────────────────────────────────────────────────────
  //  الحالة 2: المستخدم مسجل الدخول
  // ──────────────────────────────────────────────────────────────
  final uid = user.uid;
  final userService = UserService();
  final appUser = await userService.getUser(uid);

  // إذا لم يكن له سجل في Firestore -> أرسل إلى اختيار الدور (role)
  if (appUser == null) {
    if (currentPath == '/role' || currentPath == '/register') {
      return null;
    }
    return '/role';
  }

  final role = appUser.role;

  // ── منع الوصول إلى صفحات المصادقة للمستخدم المسجل ──
  final authPaths = ['/login', '/register', '/role', '/splash', '/onboarding'];
  if (authPaths.contains(currentPath)) {
    // أعد التوجيه إلى الصفحة الرئيسية حسب الدور
    if (role == 'client') return '/client/home';
    if (role == 'nurse') return '/nurse/home';
  }

  // ── توجيه حسب الدور ──
  if (role == 'client') {
    // إذا كان العميل يحاول الدخول إلى أي مسار يبدأ بـ /nurse -> أعده إلى /client/home
    if (currentPath.startsWith('/nurse')) {
      return '/client/home';
    }
    // البقاء في أي مسار آخر خاص بالعميل (مثل /client/...)
    return null;
  } else if (role == 'nurse') {
    // إذا كان الممرض يحاول الدخول إلى أي مسار يبدأ بـ /client -> أعده إلى /nurse/home
    if (currentPath.startsWith('/client')) {
      return '/nurse/home';
    }
    return null;
  }

  // دور غير معروف -> تسجيل خروج
  await auth.logout();
  return '/login';
}
