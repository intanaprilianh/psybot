import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  Future<Map<String, dynamic>?> getProfile() async {
    final userId = _client.auth.currentUser!.id;
    final result = await _client
        .from('user_profile')
        .select()
        .eq('id_user', userId)
        .maybeSingle();
    return result;
  }

  Future<void> updateProfile({
    int? usia,
    String? status,
    String? institusi,
    String? avatarUrl,
    String? jenisKelamin,
    String? noTelp,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = <String, dynamic>{};
    if (usia != null) data['usia'] = usia;
    if (status != null) data['status'] = status;
    if (institusi != null) data['institusi'] = institusi;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (jenisKelamin != null) data['jenis_kelamin'] = jenisKelamin;
    if (noTelp != null) data['no_telp'] = noTelp;

    if (data.isEmpty) return;

    // The user_profile row is auto-created on signup (handle_new_user_profile
    // trigger), and RLS only allows UPDATE — not INSERT — so we must update,
    // never upsert. We .select() back the affected row: an empty result means
    // no row matched (missing row or RLS), which we surface as an error instead
    // of silently "succeeding" on a zero-row update.
    final updated = await _client
        .from('user_profile')
        .update(data)
        .eq('id_user', userId)
        .select('id');
    if (updated.isEmpty) {
      throw StateError(
        'Baris user_profile tidak ditemukan untuk user $userId. '
        'Jalankan backfill (migrasi 021).',
      );
    }
  }

  Future<void> updateUserName(String nama) async {
    final user = _client.auth.currentUser!;
    // The public.users row already exists (handle_new_user trigger); RLS allows
    // UPDATE but not INSERT, so update rather than upsert. .select() back the
    // row so a zero-row update (missing row / RLS) becomes a visible error
    // rather than a false success.
    final updated = await _client
        .from('users')
        .update({'nama': nama})
        .eq('id', user.id)
        .select('id');
    if (updated.isEmpty) {
      throw StateError(
        'Baris users tidak ditemukan untuk user ${user.id}. '
        'Jalankan backfill (migrasi 021).',
      );
    }
  }

  Future<void> completeOnboarding() async {
    final userId = _client.auth.currentUser!.id;
    // Row exists from signup trigger; RLS permits UPDATE only.
    await _client.from('user_profile').update(
      {
        'consent_diberikan': true,
        'consent_timestamp': DateTime.now().toUtc().toIso8601String(),
        'consent_version': '1.0',
        'onboarding_complete': true,
      },
    ).eq('id_user', userId);
  }
}
