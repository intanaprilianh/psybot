import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_provider.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(supabaseProvider));
});

class ChatSessionsNotifier
    extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return ref.watch(chatServiceProvider).getSessions();
  }
}

final chatSessionsProvider =
    AsyncNotifierProvider<ChatSessionsNotifier, List<Map<String, dynamic>>>(
  ChatSessionsNotifier.new,
);
