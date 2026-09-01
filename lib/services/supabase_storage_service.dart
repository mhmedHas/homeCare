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
    if (uid.trim().isEmpty) {
      throw ArgumentError('uid cannot be empty');
    }
    if (bytes.isEmpty) {
      throw ArgumentError('image bytes cannot be empty');
    }

    final path = 'profile/${uid.trim()}.jpg';

    try {
      debugPrint('[PROFILE PHOTO] Upload started');
      debugPrint('[PROFILE PHOTO] bucket=$bucket');
      debugPrint('[PROFILE PHOTO] path=$path');
      debugPrint('[PROFILE PHOTO] bytes=${bytes.length}');
      debugPrint('[PROFILE PHOTO] contentType=$contentType');
      debugPrint('[PROFILE PHOTO] supabaseAuthUser=${_client.auth.currentUser?.id ?? 'none'}');

      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
              cacheControl: '3600',
            ),
          );

      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      final versionedUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('[PROFILE PHOTO] Upload successful');
      debugPrint('[PROFILE PHOTO] publicUrl=$publicUrl');

      return versionedUrl;
    } on StorageException catch (e, stackTrace) {
      debugPrint('[PROFILE PHOTO] STORAGE ERROR');
      debugPrint('[PROFILE PHOTO] statusCode=${e.statusCode}');
      debugPrint('[PROFILE PHOTO] message=${e.message}');
      debugPrint('[PROFILE PHOTO] error=$e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[PROFILE PHOTO] UNKNOWN ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteNurseProfilePhoto(String uid) async {
    final path = 'profile/${uid.trim()}.jpg';

    try {
      debugPrint('[PROFILE PHOTO] Delete started: $path');
      await _client.storage.from(bucket).remove([path]);
      debugPrint('[PROFILE PHOTO] Delete successful');
    } on StorageException catch (e, stackTrace) {
      debugPrint('[PROFILE PHOTO] DELETE STORAGE ERROR');
      debugPrint('[PROFILE PHOTO] statusCode=${e.statusCode}');
      debugPrint('[PROFILE PHOTO] message=${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
