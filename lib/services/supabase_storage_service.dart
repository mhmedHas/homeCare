import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles public nurse profile photos only.
/// Private identity documents must continue to use the existing private storage flow.
/// By product decision, no other image type (client photos, etc.) is
/// uploaded anywhere in the app — this service stays nurse-photo-only.
class SupabaseStorageService {
  static const String bucket = 'nurse-profile-images';

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> uploadNurseProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final path = 'profile/$uid.jpg';

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
            cacheControl: '3600',
          ),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> deleteNurseProfilePhoto(String uid) async {
    await _client.storage.from(bucket).remove([
      'profile/$uid.jpg',
    ]);
  }
}
