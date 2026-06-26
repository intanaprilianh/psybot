import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_response_model.dart';

class ChatService {
  final SupabaseClient _client;

  ChatService(this._client);

  Future<String> createSession() async {
    final userId = _client.auth.currentUser!.id;
    final result = await _client
        .from('chat_sessions')
        .insert({'id_user': userId})
        .select('id')
        .single();
    return result['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final userId = _client.auth.currentUser!.id;
    return await _client
        .from('chat_sessions')
        .select(
            'id, tanggal, status_risiko, status_sesi, summary, pesan_count, created_at, updated_at')
        .eq('id_user', userId)
        .order('updated_at', ascending: false);
  }

  Future<ChatApiResponse> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    final response = await _client.functions.invoke(
      'ai-chat',
      body: {
        'sessionId': sessionId,
        'message': message,
      },
    );

    final data = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    if (data.containsKey('error')) {
      throw Exception(data['error'] as String);
    }

    return ChatApiResponse.fromJson(data);
  }
}
