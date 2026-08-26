import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/routing/app_router.dart';
import 'services/firebase_service.dart';
import 'services/shared_preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Firebase
  await FirebaseService().init();

  // Init SharedPreferences
  await SharedPreferencesService().init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'شفاء - Home Care',
      theme: AppTheme.lightTheme,
      locale: const Locale('ar', 'EG'),
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
