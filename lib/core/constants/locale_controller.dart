import 'package:flutter/material.dart';
import '../../services/shared_preferences_service.dart';

/// App-wide language switch (Arabic / English), persisted via
/// SharedPreferences and shared by both the client and the nurse sides —
/// changing it anywhere in the app changes it everywhere, since both
/// roles read from this same singleton/preference key.
///
/// Wire-up: MyApp (main.dart) listens to this with a ListenableBuilder and
/// passes [locale] to MaterialApp. Any screen can flip the language via
/// `LocaleController.instance.toggleLocale()` or `setLocale(...)`.
class LocaleController extends ChangeNotifier {
  LocaleController._internal();
  static final LocaleController instance = LocaleController._internal();

  static const String prefsKey = 'app_locale_code';

  Locale _locale = const Locale('ar', 'EG');
  Locale get locale => _locale;
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isArabic => !isEnglish;

  /// Call once during app startup, after SharedPreferencesService().init(),
  /// so the saved language is applied before the first frame.
  Future<void> loadSaved() async {
    final code = SharedPreferencesService().getLocaleCode();
    if (code == 'en') {
      _locale = const Locale('en', 'US');
    } else {
      _locale = const Locale('ar', 'EG');
    }
    // No notifyListeners() here on purpose: this runs before runApp(),
    // there are no listeners yet.
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale.languageCode == locale.languageCode) return;
    _locale = locale;
    await SharedPreferencesService().setLocaleCode(locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleLocale() =>
      setLocale(isEnglish ? const Locale('ar', 'EG') : const Locale('en', 'US'));
}
