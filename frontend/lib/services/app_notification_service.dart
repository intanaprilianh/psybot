import 'package:supabase_flutter/supabase_flutter.dart';

/// In-app notifications backed by the `notifications` table.
class AppNotificationService {
  final SupabaseClient _client;

  AppNotificationService(this._client);

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('notifications')
        .select()
        .eq('id_user', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('notifications')
        .update({'dibaca': true})
        .eq('id_user', userId)
        .eq('dibaca', false);
  }

  Future<void> delete(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  /// Persist a notification for the current user. Used by the FCM foreground
  /// handler so incoming pushes also appear on the Notifikasi page.
  static Future<void> insert({
    required String judul,
    required String deskripsi,
    String tipe = 'sistem',
  }) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('notifications').insert({
      'id_user': userId,
      'judul': judul,
      'deskripsi': deskripsi,
      'tipe': tipe,
    });
  }
}
