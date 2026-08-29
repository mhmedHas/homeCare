import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static final SharedPreferencesService _instance =
      SharedPreferencesService._internal();
  factory SharedPreferencesService() => _instance;
  SharedPreferencesService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Onboarding
  bool isOnboardingCompleted() =>
      _prefs.getBool('onboarding_completed') ?? false;
  Future<void> setOnboardingCompleted(bool value) =>
      _prefs.setBool('onboarding_completed', value);

  // Selected Role (temporary during registration)
  String? getSelectedRole() => _prefs.getString('selected_role');
  Future<void> setSelectedRole(String role) =>
      _prefs.setString('selected_role', role);

  // Theme
  String? getThemeMode() => _prefs.getString('theme_mode');
  Future<void> setThemeMode(String mode) =>
      _prefs.setString('theme_mode', mode);

  // App language ('ar' or 'en') — shared by both client and nurse.
  String? getLocaleCode() => _prefs.getString('app_locale_code');
  Future<void> setLocaleCode(String code) =>
      _prefs.setString('app_locale_code', code);

  // Clear non-sensitive temp data
  Future<void> clearTempPreferences() async {
    await _prefs.remove('selected_role');
  }
}
