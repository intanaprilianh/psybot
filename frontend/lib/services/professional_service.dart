import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/professional_model.dart';

class ProfessionalService {
  final SupabaseClient _client;

  ProfessionalService(this._client);

  Future<List<Professional>> getVerifiedProfessionals() async {
    final data = await _client
        .from('professionals')
        .select('*, users!inner(nama, email)')
        .eq('status_verified', true)
        .order('rating', ascending: false);

    return data.map((json) => Professional.fromJson(json)).toList();
  }
}
