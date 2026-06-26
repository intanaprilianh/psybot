import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultationService {
  final SupabaseClient _client;

  ConsultationService(this._client);

  Future<String> createConsultation({
    required String professionalId,
    required DateTime jadwal,
    String jenisKonsultasi = 'chat',
    int durasiMenit = 60,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final result = await _client
        .from('consultations')
        .insert({
          'id_user': userId,
          'id_professional': professionalId,
          'jadwal': jadwal.toUtc().toIso8601String(),
          'durasi_menit': durasiMenit,
          'jenis_konsultasi': jenisKonsultasi,
        })
        .select('id')
        .single();
    return result['id'] as String;
  }

  Future<Map<String, dynamic>> createPayment(String consultationId) async {
    final response = await _client.functions.invoke(
      'payment-create',
      body: {'consultationId': consultationId},
    );
    final data = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;
    if (data.containsKey('error')) throw Exception(data['error'] as String);
    return data;
  }

  Future<void> sendMessage({
    required String consultationId,
    required String message,
  }) async {
    await _client.from('consultation_messages').insert({
      'id_consultation': consultationId,
      'id_sender': _client.auth.currentUser!.id,
      'isi_pesan': message,
    });
  }

  Stream<List<Map<String, dynamic>>> messagesStream(String consultationId) {
    return _client
        .from('consultation_messages')
        .stream(primaryKey: ['id'])
        .eq('id_consultation', consultationId)
        .order('created_at');
  }
}
