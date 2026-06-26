import 'package:supabase_flutter/supabase_flutter.dart';

class SelfHelpService {
  final SupabaseClient _client;

  SelfHelpService(this._client);

  Future<List<Map<String, dynamic>>> getContent({String? kategori}) async {
    var query = _client.from('self_help_content').select().eq('aktif', true);

    if (kategori != null) {
      query = query.eq('kategori', kategori);
    }

    return await query.order('urutan');
  }
}
