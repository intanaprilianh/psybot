// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../core/supabase_provider.dart';
import '../models/professional_model.dart';
import '../services/professional_service.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'booking_profesional_page.dart';
import 'favorit_profesional_page.dart';
import 'home_page.dart';
import 'janji_temu_page.dart';
import 'profil_page.dart';
import 'riwayat_chatbot.dart' as chat_history;
import 'riwayat_temu_page.dart';

class RiwayatDaftarProfesionalPage extends ConsumerStatefulWidget {
  const RiwayatDaftarProfesionalPage({super.key});

  @override
  ConsumerState<RiwayatDaftarProfesionalPage> createState() =>
      _RiwayatDaftarProfesionalPageState();
}

class _RiwayatDaftarProfesionalPageState
    extends ConsumerState<RiwayatDaftarProfesionalPage> {
  final TextEditingController searchController = TextEditingController();

  String selectedFilter = 'Psikolog';
  List<Professional> professionals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    try {
      final service = ProfessionalService(ref.read(supabaseProvider));
      final data = await service.getVerifiedProfessionals();

      if (!mounted) return;
      setState(() {
        professionals = data.isEmpty ? ProfessionalStore.professionals : data;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        professionals = ProfessionalStore.professionals;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Professional> get filteredProfessionals {
    final String keyword = searchController.text.trim().toLowerCase();

    return professionals.where((professional) {
      final bool matchesKeyword =
          professional.name.toLowerCase().contains(keyword) ||
          professional.title.toLowerCase().contains(keyword) ||
          professional.profession.toLowerCase().contains(keyword) ||
          professional.category.toLowerCase().contains(keyword);

      bool matchesFilter = true;

      if (selectedFilter == 'Psikolog') {
        matchesFilter = professional.category == 'Psikolog';
      } else if (selectedFilter == 'Dokter') {
        matchesFilter = professional.category == 'Dokter';
      } else if (selectedFilter == 'Tersedia Hari Ini') {
        matchesFilter = professional.availableToday;
      }

      return matchesKeyword && matchesFilter;
    }).toList();
  }

  void _toggleFavorite(Professional professional) {
    setState(() {
      professional.isFavorite = !professional.isFavorite;
    });
  }

  Future<void> _openBooking(Professional professional) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingProfesionalPage(
          professional: professional,
        ),
      ),
    );

    setState(() {});
  }

  void _openJanjiTemu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JanjiTemuPage(),
      ),
    );
  }

  void _openRiwayatTemu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RiwayatTemuPage(),
      ),
    );
  }

  Future<void> _openFavorit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritProfesionalPage(),
      ),
    );

    setState(() {});
  }

  void _goToHome() {
    // Reset the stack to a fresh Home. popUntil(isFirst) is unreliable: after a
    // fresh login the WelcomePage stays at the bottom of the stack, so isFirst
    // would pop back to Welcome/login instead of Home.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  void _goToRiwayatChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const chat_history.RiwayatChatPage(),
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

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

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
              const _TopHeader(),

              const SizedBox(height: 18),

              Text(
                'Temui Profesional!',
                style: TextStyle(
                  color: context.textHeadingColor,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              _SearchField(
                controller: searchController,
                onChanged: () {
                  setState(() {});
                },
              ),

              const SizedBox(height: 14),

              Text(
                'Riwayat Kamu',
                style: TextStyle(
                  color: context.textHeadingColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _HistoryMenuCard(
                      imagePath: 'assets/images/puyo_janji.png',
                      text: 'Janji Temu',
                      onTap: _openJanjiTemu,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HistoryMenuCard(
                      imagePath: 'assets/images/puyo_riwayat.png',
                      text: 'Riwayat Temu',
                      onTap: _openRiwayatTemu,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HistoryMenuCard(
                      imagePath: 'assets/images/puyo_favorit.png',
                      text: 'Favorit',
                      onTap: _openFavorit,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                'Rekomendasi Untukmu',
                style: TextStyle(
                  color: context.textHeadingColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterButton(
                      text: 'Psikolog',
                      isSelected: selectedFilter == 'Psikolog',
                      onTap: () {
                        setState(() {
                          selectedFilter = 'Psikolog';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterButton(
                      text: 'Dokter',
                      isSelected: selectedFilter == 'Dokter',
                      onTap: () {
                        setState(() {
                          selectedFilter = 'Dokter';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterButton(
                      text: 'Tersedia Hari Ini',
                      isSelected: selectedFilter == 'Tersedia Hari Ini',
                      onTap: () {
                        setState(() {
                          selectedFilter = 'Tersedia Hari Ini';
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (filteredProfessionals.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'Profesional tidak ditemukan',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                ...filteredProfessionals.map((professional) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ProfessionalCard(
                      professional: professional,
                      onTap: () => _openBooking(professional),
                      onFavoriteTap: () {
                        _toggleFavorite(professional);
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),

      bottomNavigationBar: AppBottomNavBar(
        activeIndex: 2,
        onHomeTap: _goToHome,
        onChatTap: _goToRiwayatChat,
        onAddTap: () {},
        onProfileTap: _goToProfil,
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader();

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
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        // Balances the notification icon so the title stays centered.
        const SizedBox(width: 26),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        style: TextStyle(
          fontSize: 13,
          color: context.textHeadingColor,
        ),
        decoration: InputDecoration(
          hintText: 'Cari Dokter atau Psikolog...',
          hintStyle: TextStyle(
            color: Colors.grey.withOpacity(0.75),
            fontSize: 13,
          ),
          suffixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.grey,
          ),
          filled: true,
          fillColor: context.cardBg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _HistoryMenuCard extends StatelessWidget {
  final String imagePath;
  final String text;
  final VoidCallback onTap;

  const _HistoryMenuCard({
    required this.imagePath,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          height: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 12,
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

class _FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFE7D8EC) : context.cardBg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentPurple
                  : Colors.grey.withOpacity(0.25),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              // Selected chip has a light lavender background, so keep its text
              // dark in both themes; unselected follows the theme heading color.
              color: isSelected ? AppColors.purple : context.textHeadingColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final Professional professional;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _ProfessionalCard({
    required this.professional,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 92,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F0),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.accentPurple,
                  size: 38,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textHeadingColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      professional.title,
                      style: TextStyle(
                        color: context.textHeadingColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.starGold,
                          size: 15,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '4.9 (${professional.reviews} Ulasan)',
                            style: TextStyle(
                              color: context.textHeadingColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          professional.price,
                          style: TextStyle(
                            color: context.textHeadingColor
                                .withOpacity(0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onFavoriteTap,
                child: Icon(
                  professional.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: Colors.red,
                  size: 23,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}