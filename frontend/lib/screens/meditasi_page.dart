import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../routes/page_transition.dart';
import 'sesi_meditasi_page.dart';

const List<MeditasiSession> _sessions = [
  MeditasiSession(
    title: 'Relaksasi Napas',
    subtitle: 'Tenangkan pikiran dengan teknik pernapasan',
    kategori: 'Pernapasan',
    durasiMenit: 5,
    icon: Icons.air_rounded,
    color: Color(0xFF7B9EBE),
  ),
  MeditasiSession(
    title: 'Meditasi Pagi',
    subtitle: 'Mulai hari dengan kesadaran penuh',
    kategori: 'Mindfulness',
    durasiMenit: 10,
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFFE8A838),
  ),
  MeditasiSession(
    title: 'Tenangkan Pikiran',
    subtitle: 'Lepaskan kekhawatiran dan temukan ketenangan',
    kategori: 'Relaksasi',
    durasiMenit: 7,
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF7B337E),
  ),
  MeditasiSession(
    title: 'Tidur Lebih Nyenyak',
    subtitle: 'Persiapkan tubuh dan pikiran untuk tidur',
    kategori: 'Tidur',
    durasiMenit: 15,
    icon: Icons.nightlight_round,
    color: Color(0xFF5B5BD6),
  ),
];

class MeditasiPage extends StatelessWidget {
  const MeditasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: context.scaffoldBg,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: context.isDark ? AppColors.brightPurple : AppColors.purple,
            size: 28,
          ),
        ),
        title: Text(
          'Meditasi',
          style: TextStyle(
            color: context.textHeadingColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header illustration
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB172B4), Color(0xFF420D4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 20,
                    top: 0,
                    bottom: 0,
                    child: Image.asset(
                      'assets/images/home_puyo_meditation.png',
                      width: 110,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Positioned(
                    left: 22,
                    top: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yuk Meditasi!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Temukan ketenangan\ndalam dirimu',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Pilih Sesi',
              style: TextStyle(
                color: context.textHeadingColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: _sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _SessionCard(
                  session: _sessions[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition.fadeSlide(
                        SesiMeditasiPage(session: _sessions[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final MeditasiSession session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: session.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  session.icon,
                  color: session.color,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              // Title + subtitle + badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: TextStyle(
                        color: context.textHeadingColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      session.subtitle,
                      style: TextStyle(
                        color: context.subtleTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Badge(label: session.kategori),
                        const SizedBox(width: 6),
                        _Badge(
                          label: '${session.durasiMenit} menit',
                          icon: Icons.timer_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Start button
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Mulai',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _Badge({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.chipBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: AppColors.accentPurple),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accentPurple,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
