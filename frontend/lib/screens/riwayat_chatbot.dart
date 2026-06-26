// ignore_for_file: unnecessary_underscores, deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/chat_history_model.dart';
import '../providers/chat_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'chatbot_page.dart';
import 'home_page.dart';
import 'profil_page.dart';
import 'riwayat_daftarprofesional_page.dart';

class RiwayatChatPage extends ConsumerStatefulWidget {
  const RiwayatChatPage({super.key});

  @override
  ConsumerState<RiwayatChatPage> createState() => _RiwayatChatPageState();
}

class _RiwayatChatPageState extends ConsumerState<RiwayatChatPage> {
  String? selectedSessionId;
  final Set<String> _deletedIds = {};

  List<_SessionItem> _buildSessions(List<Map<String, dynamic>> dbData) {
    final localIds = <String>{};
    final items = <_SessionItem>[];

    for (final local in ChatHistoryStore.sessions) {
      localIds.add(local.id);
      items.add(_SessionItem(
        id: local.id,
        title: local.title,
        preview: local.messages.isEmpty
            ? 'Belum ada pesan'
            : local.messages.last.text,
        updatedAt: local.updatedAt,
      ));
    }

    for (final s in dbData) {
      final id = s['id'] as String;
      if (localIds.contains(id) || _deletedIds.contains(id)) continue;
      final tanggal =
          DateTime.tryParse(s['updated_at'] ?? s['tanggal'] ?? '') ??
              DateTime.now();
      final pesanCount = s['pesan_count'] as int? ?? 0;
      final summary = s['summary'] as String?;
      items.add(_SessionItem(
        id: id,
        title: summary ?? 'Chat ${_formatDateShort(tanggal)}',
        preview: pesanCount > 0 ? '$pesanCount pesan' : 'Belum ada pesan',
        updatedAt: tanggal,
      ));
    }

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  String _formatDateShort(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _openNewChat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatbotPage(),
      ),
    );
    ref.invalidate(chatSessionsProvider);
  }

  Future<void> _openChatSession(_SessionItem session) async {
    setState(() {
      selectedSessionId = session.id;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotPage(
          sessionId: session.id,
        ),
      ),
    );

    ref.invalidate(chatSessionsProvider);
  }

  void _deleteSession(_SessionItem session) {
    setState(() {
      ChatHistoryStore.deleteSession(session.id);
      _deletedIds.add(session.id);
      if (selectedSessionId == session.id) selectedSessionId = null;
    });
  }

  void _goToHome() {
    // Reset the stack to a fresh Home. popUntil(isFirst) is unreliable here:
    // after a fresh login the WelcomePage stays at the bottom of the stack,
    // so isFirst would pop back to Welcome instead of Home.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  void _goToProfessionalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RiwayatDaftarProfesionalPage(),
      ),
    );
  }

  void _goToProfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilPage(),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();

    final isToday = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    if (isToday) {
      return 'Hari ini, $hour:$minute';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final sessionsAsync = ref.watch(chatSessionsProvider);
    final sessions = _buildSessions(sessionsAsync.valueOrNull ?? []);
    final isLoading = sessionsAsync.isLoading && sessions.isEmpty;

    final profileAsync = ref.watch(profileProvider);
    final profileImagePath = profileAsync.valueOrNull?.localImagePath ?? '';
    final hasProfileImage =
        profileImagePath.isNotEmpty && File(profileImagePath).existsSync();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              right: width * 0.12,
              top: 230,
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  'assets/images/home_puyo_professional.png',
                  width: width * 0.50,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

            Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    width * 0.06,
                    18,
                    width * 0.06,
                    0,
                  ),
                  child: _Header(
                    hasProfileImage: hasProfileImage,
                    profileImagePath: profileImagePath,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentPurple,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            width * 0.06,
                            0,
                            width * 0.06,
                            104,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Riwayat Percakapan',
                                style: TextStyle(
                                  color: context.textHeadingColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

                              const SizedBox(height: 14),

                              if (sessions.isEmpty)
                                const _EmptyHistory()
                              else
                                ...sessions.map((session) {
                                  return _ChatHistoryTile(
                                    key: ValueKey(session.id),
                                    title: session.title,
                                    preview: session.preview,
                                    time: _formatTime(session.updatedAt),
                                    isSelected:
                                        selectedSessionId == session.id,
                                    onTap: () => _openChatSession(session),
                                    onDelete: () => _deleteSession(session),
                                  );
                                }),
                            ],
                          ),
                        ),
                ),
              ],
            ),

            Positioned(
              right: width * 0.07,
              bottom: 18,
              child: _AddChatButton(
                onTap: _openNewChat,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        activeIndex: 1,
        onHomeTap: _goToHome,
        onChatTap: () {},
        onAddTap: _goToProfessionalPage,
        onProfileTap: _goToProfil,
      ),
    );
  }
}

class _SessionItem {
  final String id;
  final String title;
  final String preview;
  final DateTime updatedAt;

  _SessionItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
  });
}

class _Header extends StatelessWidget {
  final bool hasProfileImage;
  final String profileImagePath;

  const _Header({
    required this.hasProfileImage,
    required this.profileImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.notifications_none_rounded,
          color: context.textPrimary,
          size: 26,
        ),
        Expanded(
          child: Center(
            child: Text(
              'PsyBot',
              style: TextStyle(
                color: context.textHeadingColor,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE7D8EC),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentPurple,
              width: 1.4,
            ),
          ),
          child: ClipOval(
            child: hasProfileImage
                ? Image.file(
                    File(profileImagePath),
                    fit: BoxFit.cover,
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: AppColors.accentPurple,
                    size: 23,
                  ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: context.cardBg.withOpacity(0.82),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.accentPurple,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada riwayat chat',
            style: TextStyle(
              color: context.textHeadingColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tekan tombol + untuk memulai percakapan baru.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.subtleTextColor,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHistoryTile extends StatelessWidget {
  final String title;
  final String preview;
  final String time;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChatHistoryTile({
    super.key,
    required this.title,
    required this.preview,
    required this.time,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key ?? UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 9),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.88),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 25,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Material(
          color: isSelected ? const Color(0xFFFFDDFB) : context.cardBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7D8EC),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      color: AppColors.accentPurple,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.textHeadingColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.88),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.8),
                      fontSize: 9.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddChatButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChatButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: AppColors.accentPurple,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 44,
        ),
      ),
    );
  }
}
