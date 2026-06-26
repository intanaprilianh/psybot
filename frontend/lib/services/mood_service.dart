import 'package:supabase_flutter/supabase_flutter.dart';

class MoodService {
  final SupabaseClient _client;

  MoodService(this._client);

  Future<void> saveMood(String jenisMood) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('moods').insert({
      'id_user': userId,
      'jenis_mood': jenisMood.toLowerCase(),
    });
  }

  Future<List<Map<String, dynamic>>> getTodayMoods() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59)
        .toUtc()
        .toIso8601String();

    final data = await _client
        .from('moods')
        .select()
        .eq('id_user', userId)
        .gte('created_at', startOfDay)
        .lte('created_at', endOfDay)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data as List);
  }
}
