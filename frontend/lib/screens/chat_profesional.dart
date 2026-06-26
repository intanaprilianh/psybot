import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import '../models/professional_model.dart';
import '../models/user_profile_model.dart';
import '../services/consultation_service.dart';
import 'emergency_call.dart';
import 'janji_temu_page.dart';

class ChatProfesionalPage extends StatefulWidget {
  final Professional? professional;
  final String? consultationId;

  const ChatProfesionalPage({
    super.key,
    this.professional,
    this.consultationId,
  });

  @override
  State<ChatProfesionalPage> createState() => _ChatProfesionalPageState();
}

class _ChatProfesionalPageState extends State<ChatProfesionalPage> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  ConsultationService? _service;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (widget.consultationId != null) {
      _service = ConsultationService(Supabase.instance.client);
      _subscribeToMessages();
    } else {
      _initDemoMessages();
    }
  }

  void _subscribeToMessages() {
    _subscription = _service!
        .messagesStream(widget.consultationId!)
        .listen((data) {
      if (!mounted) return;
      setState(() {
        _messages = data
            .map((m) => {
                  'text': m['isi_pesan'] as String,
                  'isMe': m['id_sender'] == _currentUserId,
                })
            .toList();
      });
      _scrollToBottom();
    });
  }

  void _initDemoMessages() {
    final String userName = UserProfileStore.firstName;
    final String greetingName = userName.trim().isEmpty ? 'kamu' : userName;

    _messages = [
      {
        'text':
            'Halo $greetingName, berdasarkan profil, saya lihat kamu sedang memiliki intensi yang tinggi untuk menyakiti diri sendiri ya? Apakah kamu berkenan saya bantu?',
        'isMe': false,
      },
      {
        'text':
            'iya dok, di kepalaku, aku ingin nyakitin diriku. aku ngga berguna di hidup ini. aku mau mati aja',
        'isMe': true,
      },
    ];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get doctorName {
    return widget.professional?.name ?? 'dr. Tirta M. Hudhi, Sp. KJ';
  }

  void _goToEmergencyCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyCallPage(),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final String text = messageController.text.trim();
    if (text.isEmpty) return;
    messageController.clear();

    if (widget.consultationId != null) {
      try {
        await _service!.sendMessage(
          consultationId: widget.consultationId!,
          message: text,
        );
        // Stream listener will update _messages automatically
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim pesan: $e')),
          );
        }
      }
    } else {
      setState(() {
        _messages.add({'text': text, 'isMe': true});
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              doctorName: doctorName,
              onEmergencyTap: _goToEmergencyCall,
              onDoctorNameTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JanjiTemuPage(),
                  ),
                );
              },
            ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  width * 0.06,
                  18,
                  width * 0.06,
                  22,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final Map<String, dynamic> message = _messages[index];

                  return _ChatBubble(
                    text: message['text'].toString(),
                    isMe: message['isMe'] == true,
                  );
                },
              ),
            ),

            _ChatInputBar(
              controller: messageController,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String doctorName;
  final VoidCallback? onEmergencyTap;
  final VoidCallback? onDoctorNameTap;

  const _ChatHeader({
    required this.doctorName,
    this.onEmergencyTap,
    this.onDoctorNameTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back_rounded,
              color: context.isDark ? AppColors.brightPurple : AppColors.purple,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: GestureDetector(
              onTap: onDoctorNameTap,
              child: Text(
                doctorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.textHeadingColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: onEmergencyTap,
            child: Container(
              width: 38,
              height: 38,
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
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const _ChatBubble({
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
        margin: const EdgeInsets.only(bottom: 15),
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
              color: Colors.black.withValues(alpha: 0.10),
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

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
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
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tulis ceritamu...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
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
    );
  }
}
