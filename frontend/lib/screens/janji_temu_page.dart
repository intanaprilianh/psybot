import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/professional_model.dart';
import 'chat_profesional.dart';

class JanjiTemuPage extends StatefulWidget {
  const JanjiTemuPage({super.key});

  @override
  State<JanjiTemuPage> createState() => _JanjiTemuPageState();
}

class _JanjiTemuPageState extends State<JanjiTemuPage> {
  List<AppointmentSession> get appointments {
    return ProfessionalStore.appointments;
  }

  String _formatDay(String day) {
    final parts = day.split('\n');

    if (parts.length < 2) return day;

    return '${parts[0]}, ${parts[1]} Mei 2026';
  }

  void _openChat(AppointmentSession appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatProfesionalPage(
          professional: appointment.professional,
          consultationId: appointment.consultationId,
        ),
      ),
    );
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
                    'Janji Temu',
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
                      child: Text(
                        'Belum ada janji temu',
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
                        children: appointments.map((appointment) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _AppointmentCard(
                              appointment: appointment,
                              formattedDay: _formatDay(appointment.day),
                              onChatTap: () => _openChat(appointment),
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

class _AppointmentCard extends StatelessWidget {
  final AppointmentSession appointment;
  final String formattedDay;
  final VoidCallback onChatTap;

  const _AppointmentCard({
    required this.appointment,
    required this.formattedDay,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final professional = appointment.professional;

    return Container(
      height: 126,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Expanded(
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

                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      professional.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: Colors.red,
                      size: 23,
                    ),
                    GestureDetector(
                      onTap: onChatTap,
                      child: Container(
                        width: 70,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8CCFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Center(
                          child: Text(
                            'Chat',
                            style: TextStyle(
                              color: AppColors.purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

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
                  formattedDay,
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