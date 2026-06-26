// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../providers/mood_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'chatbot_page.dart';
import 'mood_tracker_page.dart';
import 'riwayat_chatbot.dart' as chat_history;
import 'riwayat_daftarprofesional_page.dart';
import 'meditasi_page.dart';
import 'notifikasi_page.dart';
import 'profil_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedMoodIndex = 0;

  // Card "Ngobrol sama Puyo yuk!" tetap masuk ke ChatbotPage.
  void _goToChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatbotPage(),
      ),
    );
  }

  void _goToNotifikasi() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotifikasiPage()),
    );
  }

  Future<void> _goToProfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilPage()),
    );
    if (mounted) setState(() {});
  }

  // Icon chat di bottom navigation masuk ke RiwayatChatPage.
  void _goToRiwayatChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const chat_history.RiwayatChatPage(),
      ),
    );
  }

  // Tombol plus di bottom navigation masuk ke daftar profesional.
  void _goToProfessionalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RiwayatDaftarProfesionalPage(),
      ),
    );
  }

  Future<void> _goToMoodTracker() async {
    final moods = ref.read(todayMoodsProvider).valueOrNull ?? [];
    if (moods.length >= 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood maksimal 7'),
        ),
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => const MoodTrackerPage(),
      ),
    );

    if (mounted) ref.invalidate(todayMoodsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double width = size.width;
    final double height = size.height;

    final profileAsync = ref.watch(profileProvider);
    final firstName = profileAsync.valueOrNull?.firstName ?? 'User';
    final profileImagePath = profileAsync.valueOrNull?.localImagePath;

    final moodsAsync = ref.watch(todayMoodsProvider);
    final moods = (moodsAsync.valueOrNull ?? [])
        .map((r) => MoodItem.fromJenisMood(r['jenis_mood'] as String))
        .whereType<MoodItem>()
        .take(7)
        .toList();

    ref.listen(todayMoodsProvider, (_, next) {
      final updated = next.valueOrNull;
      if (updated != null && updated.isNotEmpty) {
        setState(() => _selectedMoodIndex = updated.length - 1);
      }
    });

    return Scaffold(
      backgroundColor: context.scaffoldBg,

      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            width * 0.06,
            16,
            width * 0.06,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(
                profileImagePath: profileImagePath,
                onBellTap: _goToNotifikasi,
                onProfileTap: _goToProfil,
              ),

              const SizedBox(height: 22),

              _GreetingText(firstName: firstName),

              const SizedBox(height: 10),

              Text(
                'Bagaimana suasana hatimu hari ini?',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              _MoodList(
                moods: moods,
                selectedMoodIndex:
                    moods.isEmpty ? 0 : _selectedMoodIndex.clamp(0, moods.length - 1),
                onMoodTap: (index) {
                  setState(() => _selectedMoodIndex = index);
                },
                onAddTap: _goToMoodTracker,
              ),

              const SizedBox(height: 24),

              Text(
                'Mau ngobrol sama siapa hari ini?',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              _ChatCard(
                height: height * 0.158,
                backgroundColor: const Color(0xFFD09ABB),
                imagePath: 'assets/images/home_puyo_chat.png',
                imageWidth: width * 0.56,
                imageBottomOffset: -25,
                imageLeftOffset: -10,
                title: 'Ngobrol\nsama\nPuyo yuk!',
                titleRight: true,
                onTap: _goToChatbot,
              ),

              const SizedBox(height: 14),

              _ChatCard(
                height: height * 0.158,
                backgroundColor: const Color(0xFFACA1DA),
                imagePath: 'assets/images/home_puyo_professional.png',
                imageWidth: width * 0.56,
                imageBottomOffset: -6,
                imageRightOffset: -8,
                title: 'Ngobrol sama\nProfesional\nyuk!',
                titleRight: false,
                onTap: _goToProfessionalPage,
              ),

              const SizedBox(height: 22),

              Text(
                'Mau beraktivitas apa hari ini?',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              _MeditationCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeditasiPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: AppBottomNavBar(
        activeIndex: 0,
        onHomeTap: () {},
        onChatTap: _goToRiwayatChat,
        onAddTap: _goToProfessionalPage,
        onProfileTap: _goToProfil,
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String? profileImagePath;
  final VoidCallback onBellTap;
  final VoidCallback onProfileTap;

  const _HomeHeader({
    required this.profileImagePath,
    required this.onBellTap,
    required this.onProfileTap,
  });

  bool get hasProfileImage {
    return profileImagePath != null &&
        profileImagePath!.isNotEmpty &&
        File(profileImagePath!).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBellTap,
          child: Icon(
            Icons.notifications_none_rounded,
            color: context.textPrimary,
            size: 26,
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'PsyBot',
              style: TextStyle(
                color: context.textHeadingColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE7D8EC),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentPurple,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: hasProfileImage
                  ? Image.file(
                      File(profileImagePath!),
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: AppColors.accentPurple,
                      size: 22,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GreetingText extends StatelessWidget {
  final String firstName;

  const _GreetingText({
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
        children: [
          const TextSpan(text: 'Selamat Siang, '),
          TextSpan(
            text: '$firstName!',
            style: const TextStyle(
              color: AppColors.accentPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodList extends StatelessWidget {
  final List<MoodItem> moods;
  final int selectedMoodIndex;
  final ValueChanged<int> onMoodTap;
  final VoidCallback onAddTap;

  const _MoodList({
    required this.moods,
    required this.selectedMoodIndex,
    required this.onMoodTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...List.generate(moods.length, (index) {
            final MoodItem mood = moods[index];
            final bool isSelected = selectedMoodIndex == index;

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _MoodPreviewCard(
                mood: mood,
                isSelected: isSelected,
                onTap: () => onMoodTap(index),
              ),
            );
          }),
          if (moods.length < 7)
            _AddMoodButton(
              onTap: onAddTap,
            ),
        ],
      ),
    );
  }
}

class _MoodPreviewCard extends StatelessWidget {
  final MoodItem mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodPreviewCard({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 82,
          height: 88,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isSelected ? mood.color : Colors.transparent,
              width: 1.7,
            ),
            boxShadow: [
              BoxShadow(
                color: mood.color.withOpacity(isSelected ? 0.24 : 0.08),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: mood.color.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  mood.icon,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                mood.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.textHeadingColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMoodButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMoodButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.chipBg,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 62,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.accentPurple.withOpacity(0.35),
              width: 1.4,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: AppColors.accentPurple,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final double height;
  final Color backgroundColor;
  final String imagePath;
  final double imageWidth;
  final double imageBottomOffset;
  final double imageLeftOffset;
  final double imageRightOffset;
  final String title;
  final bool titleRight;
  final VoidCallback onTap;

  const _ChatCard({
    required this.height,
    required this.backgroundColor,
    required this.imagePath,
    required this.imageWidth,
    required this.title,
    required this.titleRight,
    required this.onTap,
    this.imageBottomOffset = 0,
    this.imageLeftOffset = 0,
    this.imageRightOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool imageOnLeft = titleRight;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              children: [
                Positioned(
                  left: imageOnLeft ? imageLeftOffset : null,
                  right: imageOnLeft ? null : imageRightOffset,
                  bottom: imageBottomOffset,
                  child: Image.asset(
                    imagePath,
                    width: imageWidth,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: titleRight ? null : 24,
                  right: titleRight ? 24 : null,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      title,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeditationCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MeditationCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    return Material(
      color: const Color(0xFFF5D5D0),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          height: 130,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              children: [
                Positioned(
                  left: width * 0.07,
                  bottom: 0,
                  child: Image.asset(
                    'assets/images/home_puyo_meditation.png',
                    width: width * 0.32,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  right: 34,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      'Meditasi',
                      style: TextStyle(
                        color: context.textHeadingColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}