import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles public profile photos (nurses and clients) only.
/// Private identity documents must continue to use the existing private storage flow.
class SupabaseStorageService {
  static const String bucket = 'nurse-profile-images';

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> uploadNurseProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    return _uploadProfilePhoto(folder: 'profile', uid: uid, bytes: bytes, contentType: contentType);
  }

  Future<void> deleteNurseProfilePhoto(String uid) async {
    await _client.storage.from(bucket).remove([
      'profile/$uid.jpg',
    ]);
  }

  /// Same storage flow as [uploadNurseProfilePhoto], for client profile photos.
  /// Uses a separate folder within the same public bucket so client and
  /// nurse photos never collide.
  Future<String> uploadClientProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    return _uploadProfilePhoto(folder: 'client-profile', uid: uid, bytes: bytes, contentType: contentType);
  }

  Future<String> _uploadProfilePhoto({
    required String folder,
    required String uid,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final path = '$folder/$uid.jpg';

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
}
