import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/professional_model.dart';

class RiwayatTemuPage extends StatelessWidget {
  const RiwayatTemuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final List<AppointmentSession> appointments = ProfessionalStore.appointments;

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
                    'Riwayat Temu',
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
              child: appointments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            color: Colors.grey.shade300,
                            size: 64,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada riwayat temu',
                            style: TextStyle(
                              color: context.subtleTextColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                        children: appointments.map((appointment) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _RiwayatTemuCard(
                              appointment: appointment,
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

class _RiwayatTemuCard extends StatelessWidget {
  final AppointmentSession appointment;

  const _RiwayatTemuCard({
    required this.appointment,
  });

  String get _formattedDay {
    final parts = appointment.day.split('\n');
    if (parts.length < 2) return appointment.day;
    return '${parts[0]}, ${parts[1]} Mei 2026';
  }

  @override
  Widget build(BuildContext context) {
    final professional = appointment.professional;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: context.borderColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F0),
                  borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.starGold,
                          size: 15,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '4.9 (${professional.reviews} Ulasan)',
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
              Icon(
                professional.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: AppColors.favoriteRed,
                size: 23,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 13,
                ),
                const SizedBox(width: 6),
                Text(
                  _formattedDay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 18),
                const Icon(
                  Icons.access_time_filled_rounded,
                  color: Colors.white,
                  size: 13,
                ),
                const SizedBox(width: 6),
                Text(
                  appointment.time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
