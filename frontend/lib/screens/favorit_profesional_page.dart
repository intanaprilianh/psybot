import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/professional_model.dart';

class FavoritProfesionalPage extends StatefulWidget {
  const FavoritProfesionalPage({super.key});

  @override
  State<FavoritProfesionalPage> createState() =>
      _FavoritProfesionalPageState();
}

class _FavoritProfesionalPageState extends State<FavoritProfesionalPage> {
  List<Professional> get favorites {
    return ProfessionalStore.favorites;
  }

  void _toggleFavorite(Professional professional) {
    setState(() {
      professional.isFavorite = !professional.isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                width * 0.07,
                18,
                width * 0.07,
                10,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: context.isDark
                          ? AppColors.brightPurple
                          : AppColors.purple,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Favorit',
                    style: TextStyle(
                      color: context.textHeadingColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: favorites.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada profesional favorit',
                        style: TextStyle(
                          color: context.subtleTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        width * 0.07,
                        0,
                        width * 0.07,
                        28,
                      ),
                      child: Column(
                        children: favorites.map((professional) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _FavoriteProfessionalCard(
                              professional: professional,
                              onFavoriteTap: () {
                                _toggleFavorite(professional);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteProfessionalCard extends StatelessWidget {
  final Professional professional;
  final VoidCallback onFavoriteTap;

  const _FavoriteProfessionalCard({
    required this.professional,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(11),
      ),
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
                        color: context.textHeadingColor,
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
    );
  }
}