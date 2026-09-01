import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) throw ArgumentError('uid cannot be empty');
    if (bytes.isEmpty) throw ArgumentError('image bytes cannot be empty');

    final path = 'profile/$cleanUid.jpg';

    try {
      debugPrint('[PROFILE PHOTO] upload: $path (${bytes.length} bytes)');

      // Do not use upsert=true here. The Supabase project authenticates app
      // users with Firebase, not Supabase Auth, and upsert may require UPDATE
      // privileges. First upload is a pure INSERT.
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
              cacheControl: '3600',
            ),
          );

      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      final versionedUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('[PROFILE PHOTO] upload success: $publicUrl');
      return versionedUrl;
    } on StorageException catch (e, stackTrace) {
      debugPrint('[PROFILE PHOTO] STORAGE ERROR');
      debugPrint('[PROFILE PHOTO] statusCode=${e.statusCode}');
      debugPrint('[PROFILE PHOTO] message=${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteNurseProfilePhoto(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return;

    final path = 'profile/$cleanUid.jpg';
    await _client.storage.from(bucket).remove([path]);
  }
}
