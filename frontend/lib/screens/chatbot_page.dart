// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/call_center_model.dart';
import '../models/chat_history_model.dart';
import '../providers/chat_provider.dart';
import '../widgets/call_center_bottom_sheet.dart';
import 'emergency_call.dart';
import 'riwayat_daftarprofesional_page.dart';

class ChatbotPage extends ConsumerStatefulWidget {
  final String? sessionId;

  const ChatbotPage({
    super.key,
    this.sessionId,
  });

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  ChatSession? currentSession;
  bool isInitializing = true;

  bool isBotTyping = false;
  bool showMoodQuickReplies = true;

  List<ChatMessage> get messages {
    return currentSession?.messages ?? [];
  }

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    if (widget.sessionId != null) {
      final existing = ChatHistoryStore.getSessionById(widget.sessionId!);
      if (existing != null) {
        setState(() {
          currentSession = existing;
          isInitializing = false;
          showMoodQuickReplies = !messages.any((m) => m.isMe);
        });
        _scrollToBottom();
        return;
      }
      // DB-only session — resume without fetching messages (encrypted server-side)
      setState(() {
        currentSession = ChatHistoryStore.createSession(id: widget.sessionId);
        isInitializing = false;
        showMoodQuickReplies = false;
      });
      return;
    }

    try {
      final chatService = ref.read(chatServiceProvider);
      final sessionId = await chatService.createSession();

      if (!mounted) return;

      setState(() {
        currentSession = ChatHistoryStore.createSession(id: sessionId);
        isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        currentSession = ChatHistoryStore.createSession();
        isInitializing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal terhubung ke server. Mode offline.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? quickMessage}) async {
    final String text = quickMessage ?? messageController.text.trim();

    if (text.isEmpty || currentSession == null) return;

    setState(() {
      showMoodQuickReplies = false;
      isBotTyping = true;

      ChatHistoryStore.addMessage(
        sessionId: currentSession!.id,
        message: ChatMessage(
          text: text,
          isMe: true,
        ),
      );

      messageController.clear();
    });

    _scrollToBottom();

    try {
      final chatService = ref.read(chatServiceProvider);
      final apiResponse = await chatService.sendMessage(
        sessionId: currentSession!.id,
        message: text,
      );

      if (!mounted) return;

      setState(() {
        isBotTyping = false;

        ChatHistoryStore.addMessage(
          sessionId: currentSession!.id,
          message: ChatMessage(
            text: apiResponse.response,
            isMe: false,
          ),
        );
      });

      _scrollToBottom();

      // Critical risk: open the emergency call screen immediately. Lower
      // (high) risk still uses the opt-in call-center sheet.
      if (apiResponse.riskLevel == 'critical') {
        _goToEmergencyCall();
      } else if (apiResponse.showCallCenter &&
          apiResponse.callCenterServices != null) {
        _showCallCenterBottomSheet(
          alertId: apiResponse.alertId!,
          services: apiResponse.callCenterServices!,
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isBotTyping = false;

        ChatHistoryStore.addMessage(
          sessionId: currentSession!.id,
          message: ChatMessage(
            text:
                'Maaf, Puyo lagi kesulitan merespons. Coba kirim ulang ceritamu sebentar lagi ya.',
            isMe: false,
          ),
        );
      });

      _scrollToBottom();
    }
  }

  void _showCallCenterBottomSheet({
    required String alertId,
    required List<CallCenterService> services,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallCenterBottomSheet(
        services: services,
        alertId: alertId,
      ),
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

  void _goToEmergencyCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyCallPage(),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.accentPurple,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: ChatHeader(
        onEmergencyTap: _goToEmergencyCall,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
              itemCount: messages.length + (isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (isBotTyping && index == messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: TypingChatBubble(),
                  );
                }

                final ChatMessage message = messages[index];

                return MessageItem(
                  message: message,
                  time: _formatTime(message.createdAt),
                );
              },
            ),
          ),
          QuickReplySection(
            showMoodQuickReplies: showMoodQuickReplies,
            onMoodTap: (text) {
              _sendMessage(quickMessage: text);
            },
            onProfessionalTap: _goToProfessionalPage,
          ),
          const SizedBox(height: 8),
          ChatInputSection(
            controller: messageController,
            onSend: () {
              _sendMessage();
            },
          ),
        ],
      ),
    );
  }
}

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onEmergencyTap;

  const ChatHeader({
    super.key,
    this.onEmergencyTap,
  });

  @override
  Size get preferredSize {
    return const Size.fromHeight(66);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.cardBg,
      elevation: 0,
      surfaceTintColor: context.cardBg,
      centerTitle: true,
      leadingWidth: 52,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(
          Icons.arrow_back_rounded,
          color: context.isDark ? AppColors.darkTextPrimary : AppColors.purple,
          size: 30,
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PsyBot',
            style: TextStyle(
              color: context.textHeadingColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Hari Ini',
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (onEmergencyTap != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: onEmergencyTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.emergencyRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFEFEFEF),
        ),
      ),
    );
  }
}

class MessageItem extends StatelessWidget {
  final ChatMessage message;
  final String time;

  const MessageItem({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.isMe;

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ChatBubble(
          text: message.text,
          isMe: isMe,
        ),
        Padding(
          padding: EdgeInsets.only(
            left: isMe ? 0 : 4,
            right: isMe ? 4 : 0,
            bottom: 8,
          ),
          child: Text(
            time,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.75),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? (context.isDark ? AppColors.darkSurface2 : const Color(0xFFE6E6E6))
              : const Color(0xFFC1C2FF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(isMe ? 17 : 5),
            bottomRight: Radius.circular(isMe ? 5 : 17),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: (isMe && context.isDark)
                ? AppColors.darkTextPrimary
                : const Color(0xFF151226),
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class QuickReplySection extends StatelessWidget {
  final bool showMoodQuickReplies;
  final ValueChanged<String> onMoodTap;
  final VoidCallback onProfessionalTap;

  const QuickReplySection({
    super.key,
    required this.showMoodQuickReplies,
    required this.onMoodTap,
    required this.onProfessionalTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> moodReplies = [
      'Aku lagi senang',
      'Aku capek',
      'Aku sedih',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showMoodQuickReplies)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: moodReplies.map((text) {
                return MoodButton(
                  text: text,
                  onTap: () => onMoodTap(text),
                );
              }).toList(),
            ),
          if (showMoodQuickReplies) const SizedBox(height: 8),
          Center(
            child: MoodButton(
              text: 'Hubungi Profesional',
              isLarge: true,
              onTap: onProfessionalTap,
            ),
          ),
        ],
      ),
    );
  }
}

class MoodButton extends StatelessWidget {
  final String text;
  final bool isLarge;
  final VoidCallback onTap;

  const MoodButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isLarge || context.isDark
          ? const Color(0xFFACA1DA).withValues(alpha: 0.5)
          : context.cardBg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 22 : 15,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isLarge
                  ? AppColors.purple.withValues(alpha: 0.5)
                  : const Color(0xFFC3C3C3),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: context.isDark ? Colors.white : const Color(0xFF67207C),
              fontSize: isLarge ? 12 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class ChatInputSection extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputSection({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: context.inputFillAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      color: Colors.grey.shade400,
                      size: 25,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          onSend();
                        },
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tulis ceritamu...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.accentPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypingChatBubble extends StatelessWidget {
  const TypingChatBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFC1C2FF),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(17),
          topRight: Radius.circular(17),
          bottomRight: Radius.circular(17),
          bottomLeft: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const CuteTypingLoading(),
    );
  }
}

class CuteTypingLoading extends StatefulWidget {
  const CuteTypingLoading({super.key});

  @override
  State<CuteTypingLoading> createState() => _CuteTypingLoadingState();
}

class _CuteTypingLoadingState extends State<CuteTypingLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 26,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return CustomPaint(
            painter: CuteTypingPainter(controller.value),
          );
        },
      ),
    );
  }
}

class CuteTypingPainter extends CustomPainter {
  final double progress;

  CuteTypingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint orbitPaint = Paint()
      ..color = const Color(0xFF8B4BA3).withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final Paint dotPaint = Paint()..color = const Color(0xFF7B328E);
    final Paint smallDotPaint = Paint()..color = const Color(0xFFB678CB);

    canvas.drawCircle(center, 9, orbitPaint);

    for (int i = 0; i < 3; i++) {
      final double angle = progress * 2 * pi + (i * 2 * pi / 3);
      final double x = center.dx + cos(angle) * 9;
      final double y = center.dy + sin(angle) * 9;

      canvas.drawCircle(
        Offset(x, y),
        i == 0 ? 4 : 3,
        i == 0 ? dotPaint : smallDotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CuteTypingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
