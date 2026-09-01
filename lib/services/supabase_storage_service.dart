import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles the only public profile image in the app: the nurse profile photo.
/// Client profile photos are intentionally not supported.
class SupabaseStorageService {
  static const String bucket = 'nurse-profile-images';

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> uploadNurseProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError('uid cannot be empty');
    }
    if (bytes.isEmpty) {
      throw ArgumentError('image bytes cannot be empty');
    }

    final path = 'profile/${uid.trim()}.jpg';

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
            cacheControl: '3600',
          ),
        );

    // The file path is stable, so append a version to prevent an old
    // browser/device cache from showing the previous profile photo.
    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> deleteNurseProfilePhoto(String uid) async {
    await _client.storage.from(bucket).remove([
      'profile/${uid.trim()}.jpg',
    ]);
  }
}
