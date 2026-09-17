import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles nurse images stored in Supabase Storage.
class SupabaseStorageService {
  static const String bucket = 'nurse-profile-images';

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> uploadNurseProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    return _uploadImage(
      path: 'profile/${uid.trim()}.jpg',
      bytes: bytes,
      contentType: contentType,
      logPrefix: 'PROFILE PHOTO',
    );
  }

  Future<String> uploadNurseVerificationDocument({
    required String uid,
    required String documentType,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final cleanUid = uid.trim();
    final cleanType = documentType.trim();
    if (cleanUid.isEmpty) throw ArgumentError('uid cannot be empty');
    if (cleanType.isEmpty) throw ArgumentError('documentType cannot be empty');

    return _uploadImage(
      path: 'verification/$cleanUid/$cleanType.jpg',
      bytes: bytes,
      contentType: contentType,
      logPrefix: 'VERIFICATION DOCUMENT',
    );
  }

  Future<String> _uploadImage({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required String logPrefix,
  }) async {
    if (bytes.isEmpty) throw ArgumentError('image bytes cannot be empty');

    try {
      debugPrint('[$logPrefix] upload: $path (${bytes.length} bytes)');
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
      final message = e.message.toLowerCase();
      final alreadyExists =
          message.contains('already exists') ||
          message.contains('duplicate') ||
          message.contains('exists');

      if (!alreadyExists) {
        debugPrint('[$logPrefix] STORAGE ERROR');
        debugPrint('[$logPrefix] statusCode=${e.statusCode}');
        debugPrint('[$logPrefix] message=${e.message}');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }

      debugPrint('[$logPrefix] existing file detected; updating $path');
      await _client.storage.from(bucket).updateBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              cacheControl: '3600',
            ),
          );
    }

    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> deleteNurseProfilePhoto(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return;

    await _client.storage.from(bucket).remove([
      'profile/$cleanUid.jpg',
    ]);
  }
}
