import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadImage({
    required File file,
    required String folder,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${basename(file.path)}';

    final path = '$folder/$fileName';

    await _client.storage.from('lost-items').upload(
          path,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    return _client.storage.from('lost-items').getPublicUrl(path);
  }
}
