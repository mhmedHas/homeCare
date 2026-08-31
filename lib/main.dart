import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/locale_controller.dart';
import 'core/routing/app_router.dart';
import 'services/firebase_service.dart';
import 'services/shared_preferences_service.dart';

const String supabaseUrl = 'https://ccaoalnicofolubsyovw.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_QWSPbkX-6xEM-7bsGxYX4Q_0Z_4aOdH';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ar');
  await initializeDateFormatting('ar_EG');
  await initializeDateFormatting('en');

  await FirebaseService().init();
  await SharedPreferencesService().init();
  await LocaleController.instance.loadSaved();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final locale = LocaleController.instance.locale;
        return MaterialApp.router(
          title: AppStrings.t('app_name'),
          theme: AppTheme.lightTheme,
          locale: locale,
          supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
        );
      },
    );
  }
}
