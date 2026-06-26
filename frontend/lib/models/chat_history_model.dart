class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime createdAt;

  ChatMessage({
    required this.text,
    required this.isMe,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        messages = messages ?? [];
}

class ChatHistoryStore {
  static final List<ChatSession> _sessions = [];

  static List<ChatSession> get sessions {
    final List<ChatSession> sortedSessions = List.from(_sessions);

    sortedSessions.sort((a, b) {
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return sortedSessions;
  }

  static ChatSession? getSessionById(String id) {
    try {
      return _sessions.firstWhere((session) => session.id == id);
    } catch (_) {
      return null;
    }
  }

  static ChatSession createSession({String? id}) {
    final ChatSession session = ChatSession(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'Chat Baru',
    );

    _sessions.insert(0, session);

    return session;
  }

  static void addMessage({
    required String sessionId,
    required ChatMessage message,
  }) {
    final ChatSession? session = getSessionById(sessionId);

    if (session == null) return;

    session.messages.add(message);
    session.updatedAt = DateTime.now();

    if (message.isMe && session.title == 'Chat Baru') {
      session.title = _generateTitle(message.text);
    }
  }

  static void deleteSession(String id) {
    _sessions.removeWhere((session) => session.id == id);
  }

  static void clearAll() {
    _sessions.clear();
  }

  static String _generateTitle(String text) {
    final String trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      return 'Chat Baru';
    }

    if (trimmedText.length <= 28) {
      return trimmedText;
    }

    return '${trimmedText.substring(0, 28)}...';
  }
}