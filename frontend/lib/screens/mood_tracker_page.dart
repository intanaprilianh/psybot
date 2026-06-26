// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../providers/mood_provider.dart';

class MoodTrackerPage extends ConsumerStatefulWidget {
  const MoodTrackerPage({super.key});

  @override
  ConsumerState<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends ConsumerState<MoodTrackerPage> {
  final PageController moodController = PageController(
    viewportFraction: 0.58,
  );

  int selectedMoodIndex = 0;
  bool _isSaving = false;

  final List<MoodItem> moods = MoodItem.allMoods;

  MoodItem get selectedMood => moods[selectedMoodIndex];

  @override
  void dispose() {
    moodController.dispose();
    super.dispose();
  }

  Future<void> saveMood() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final mood = selectedMood;
    try {
      await ref.read(moodServiceProvider).saveMood(mood.title);
    } catch (_) {
      // Simpan ke DB gagal — tetap lanjut kembali ke home
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const MoodHeader(),

            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  width * 0.07,
                  22,
                  width * 0.07,
                  0,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Bagaimana suasana\nhatimu hari ini?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF84368B),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Scroll untuk memilih mood kamu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Expanded(
                      child: PageView.builder(
                        controller: moodController,
                        scrollDirection: Axis.vertical,
                        itemCount: moods.length,
                        onPageChanged: (index) {
                          setState(() {
                            selectedMoodIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final MoodItem mood = moods[index];
                          final bool isSelected = selectedMoodIndex == index;

                          return AnimatedScale(
                            duration: const Duration(milliseconds: 220),
                            scale: isSelected ? 1.0 : 0.84,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 220),
                              opacity: isSelected ? 1.0 : 0.25,
                              child: MoodScrollCard(
                                mood: mood,
                                isSelected: isSelected,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    MoodIndicator(
                      total: moods.length,
                      selectedIndex: selectedMoodIndex,
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : saveMood,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF84368B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoodHeader extends StatelessWidget {
  const MoodHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF280034),
            Color(0xFF3C064E),
            Color(0xFF4B075E),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: width * 0.10,
            bottom: -20,
            child: Image.asset(
              'assets/images/puyo_intip.png',
              width: width * 0.34,
              fit: BoxFit.contain,
            ),
          ),

          const Positioned(
            right: 28,
            top: 48,
            child: Text(
              'PsyBot',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodScrollCard extends StatelessWidget {
  final MoodItem mood;
  final bool isSelected;

  const MoodScrollCard({
    super.key,
    required this.mood,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight;

        double cardHeight = maxHeight - 16;
        if (cardHeight > 218) {
          cardHeight = 218;
        }
        if (cardHeight < 130) {
          cardHeight = 130;
        }

        final bool isSmall = cardHeight < 175;

        final double iconSize = isSmall ? 58 : 82;
        final double iconDataSize = isSmall ? 34 : 48;
        final double titleSize = isSmall ? 18 : 25;
        final double descSize = isSmall ? 10.5 : 13;

        return Center(
          child: Container(
            height: cardHeight,
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 14 : 18,
              vertical: isSmall ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isSelected ? mood.color : Colors.transparent,
                width: 2.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: mood.color.withOpacity(isSelected ? 0.24 : 0.06),
                  blurRadius: isSelected ? 18 : 8,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.76,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: mood.color.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(
                          isSmall ? 18 : 22,
                        ),
                      ),
                      child: Icon(
                        mood.icon,
                        size: iconDataSize,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: isSmall ? 8 : 12),

                    Text(
                      mood.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    SizedBox(height: isSmall ? 4 : 7),

                    Text(
                      mood.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(
                        color: context.subtleTextColor,
                        fontSize: descSize,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MoodIndicator extends StatelessWidget {
  final int total;
  final int selectedIndex;

  const MoodIndicator({
    super.key,
    required this.total,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      children: List.generate(total, (index) {
        final bool isSelected = index == selectedIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF84368B)
                : const Color(0xFFD6D6D6),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

class MoodItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const MoodItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<MoodItem> allMoods = [
    MoodItem(
      title: 'Senang',
      description: 'Kamu sedang merasa bahagia dan nyaman hari ini.',
      icon: Icons.sentiment_very_satisfied_rounded,
      color: Color(0xFFF9C74F),
    ),
    MoodItem(
      title: 'Sedih',
      description: 'Kamu sedang merasa murung atau ingin menyendiri.',
      icon: Icons.sentiment_dissatisfied_rounded,
      color: Color(0xFF577590),
    ),
    MoodItem(
      title: 'Marah',
      description: 'Kamu sedang merasa kesal, emosi, atau tidak nyaman.',
      icon: Icons.mood_bad_rounded,
      color: Color(0xFFF94144),
    ),
    MoodItem(
      title: 'Tenang',
      description: 'Kamu sedang merasa damai dan cukup stabil.',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF43AA8B),
    ),
    MoodItem(
      title: 'Cemas',
      description: 'Kamu sedang banyak pikiran atau merasa khawatir.',
      icon: Icons.psychology_alt_rounded,
      color: Color(0xFFF9844A),
    ),
    MoodItem(
      title: 'Lelah',
      description: 'Kamu sedang merasa capek secara fisik atau mental.',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF8E7DBE),
    ),
    MoodItem(
      title: 'Semangat',
      description: 'Kamu sedang punya energi dan motivasi yang baik.',
      icon: Icons.bolt_rounded,
      color: Color(0xFF90BE6D),
    ),
    MoodItem(
      title: 'Bingung',
      description: 'Kamu sedang merasa ragu atau belum tahu harus apa.',
      icon: Icons.help_outline_rounded,
      color: Color(0xFF4D96FF),
    ),
  ];

  static MoodItem? fromJenisMood(String jenisMood) {
    final lower = jenisMood.toLowerCase();
    for (final m in allMoods) {
      if (m.title.toLowerCase() == lower) return m;
    }
    return null;
  }
}