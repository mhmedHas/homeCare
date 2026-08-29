import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Wraps Supabase Storage for uploading images (nurse verification
/// documents, nurse/client profile photos, etc).
///
/// SETUP REQUIRED before this works:
/// 1. Create a free project at https://supabase.com
/// 2. In Project Settings -> API, copy the "Project URL" and the
///    "anon public" key and paste them below instead of the placeholders.
/// 3. In Storage, create a *public* bucket named `app-uploads`
///    (Storage -> New bucket -> toggle "Public bucket" on).
///    You can use a different bucket name as long as you update
///    [SupabaseService.bucket] to match.
/// 4. Call `SupabaseService.init()` once, before `runApp()` (already wired
///    up in main.dart).
class SupabaseService {
  SupabaseService._();

  // TODO: replace with your own Supabase project credentials.
  static const String _supabaseUrl = 'https://YOUR-PROJECT.supabase.co';
  static const String _supabaseAnonKey = 'YOUR-ANON-PUBLIC-KEY';

  static const String bucket = 'app-uploads';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    if (_supabaseUrl.contains('YOUR-PROJECT') || _supabaseAnonKey.contains('YOUR-ANON')) {
      // Credentials were not filled in yet — skip silently instead of
      // crashing the whole app on startup. Upload calls will fail with a
      // clear error until real credentials are set above.
      debugPrint(
          'SupabaseService: skipped init — set your Supabase URL/anon key in supabase_service.dart');
      return;
    }
    await sb.Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
    _initialized = true;
  }

  static sb.SupabaseClient get _client => sb.Supabase.instance.client;

  /// Uploads [file] to `bucket/folder/fileName` and returns its public URL.
  /// Throws a [StateError] with a friendly message if Supabase was never
  /// configured/initialized.
  static Future<String> uploadImage({
    required File file,
    required String folder,
    required String fileName,
  }) async {
    if (!_initialized) {
      throw StateError(
          'رفع الصور غير مفعّل بعد: من فضلك أضف بيانات مشروع Supabase في lib/services/supabase_service.dart');
    }
    final path = '$folder/$fileName';
    await _client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: const sb.FileOptions(upsert: true),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
