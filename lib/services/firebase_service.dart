import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable App Check (Debug/Release handling)
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider
          .debug, // For debug, change to playIntegrity for release
      appleProvider: AppleProvider.debug, // For debug
    );

    _initialized = true;
  }

  bool get isInitialized => _initialized;
}
