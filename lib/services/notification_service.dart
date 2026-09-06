import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/routing/app_router.dart';
import 'user_service.dart';

/// OneSignal integration for HomeCare.
///
/// Firebase UID is used as the OneSignal external_id so one user can receive
/// notifications on all of their registered devices.
class NotificationService {
  static const String oneSignalAppId = 'a0ad2ede-27ca-4058-9105-218162d2217f';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await OneSignal.initialize(oneSignalAppId);
    OneSignal.Notifications.addClickListener(_handleNotificationClick);
    await OneSignal.Notifications.requestPermission(false);

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        OneSignal.logout();
      } else {
        syncUser(user);
      }
    });
  }

  static Future<void> syncUser(User user) async {
    try {
      await OneSignal.login(user.uid);

      final appUser = await UserService().getUser(user.uid);
      if (appUser != null) {
        await OneSignal.User.addTags({'role': appUser.role});
      }
    } catch (_) {
      // Notification setup must never prevent the user from using the app.
    }
  }

  static Future<void> sendChatNotification({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != senderId) return;

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) return;

    await Supabase.instance.client.functions.invoke(
      'send-notification',
      headers: {'Authorization': 'Bearer $token'},
      body: {
        'type': 'message',
        'chatId': chatId,
        'receiverId': receiverId,
        'message': text,
      },
    );
  }

  static Future<void> sendCareRequestNotification({
    required String requestId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) return;

    await Supabase.instance.client.functions.invoke(
      'send-notification',
      headers: {'Authorization': 'Bearer $token'},
      body: {
        'type': 'care_request',
        'requestId': requestId,
      },
    );
  }

  static void _handleNotificationClick(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;
    if (data == null) return;

    final type = data['type']?.toString();
    final router = appRouter;

    if (type == 'message') {
      final bookingId = data['bookingId']?.toString();
      if (bookingId == null || bookingId.isEmpty) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      UserService().getUser(user.uid).then((appUser) {
        if (appUser?.role == 'nurse') {
          router.go('/nurse/chat/$bookingId');
        } else {
          router.go('/client/chat/$bookingId');
        }
      });
      return;
    }

    if (type == 'care_request') {
      final requestId = data['requestId']?.toString();
      if (requestId != null && requestId.isNotEmpty) {
        router.go('/nurse/request-details/$requestId');
      }
    }
  }
}
