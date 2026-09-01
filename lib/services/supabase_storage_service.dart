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

      // Firebase Auth is the app authentication system. Supabase is used only
      // as public storage, so the upload must not depend on Supabase Auth.
      // upsert=true caused a 403 in this project because it can require an
      // UPDATE operation. Start with a plain INSERT instead.
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
              cacheControl: '3600',
            ),
          );
    } on StorageException catch (e, stackTrace) {
      // If this nurse already has a photo, INSERT correctly reports that the
      // object exists. In that case use an explicit UPDATE; this keeps the
      // request predictable and avoids upsert's combined INSERT/UPDATE path.
      final message = e.message.toLowerCase();
      final alreadyExists =
          message.contains('already exists') ||
          message.contains('duplicate') ||
          message.contains('exists');

      if (!alreadyExists) {
        debugPrint('[PROFILE PHOTO] STORAGE ERROR');
        debugPrint('[PROFILE PHOTO] statusCode=${e.statusCode}');
        debugPrint('[PROFILE PHOTO] message=${e.message}');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }

      debugPrint('[PROFILE PHOTO] existing file detected; updating $path');

      try {
        await _client.storage.from(bucket).updateBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                cacheControl: '3600',
              ),
            );
      } on StorageException catch (updateError, updateStack) {
        debugPrint('[PROFILE PHOTO] UPDATE STORAGE ERROR');
        debugPrint('[PROFILE PHOTO] statusCode=${updateError.statusCode}');
        debugPrint('[PROFILE PHOTO] message=${updateError.message}');
        debugPrintStack(stackTrace: updateStack);
        rethrow;
      }
    }

    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    final versionedUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('[PROFILE PHOTO] upload/update success: $publicUrl');
    return versionedUrl;
  }

  Future<void> deleteNurseProfilePhoto(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return;

    await _client.storage.from(bucket).remove([
      'profile/$cleanUid.jpg',
    ]);
  }
}
