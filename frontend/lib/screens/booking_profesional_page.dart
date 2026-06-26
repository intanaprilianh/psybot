import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../models/professional_model.dart';
import '../services/consultation_service.dart';
import 'janji_temu_page.dart';

class BookingProfesionalPage extends StatefulWidget {
  final Professional professional;

  const BookingProfesionalPage({
    super.key,
    required this.professional,
  });

  @override
  State<BookingProfesionalPage> createState() =>
      _BookingProfesionalPageState();
}

class _BookingProfesionalPageState extends State<BookingProfesionalPage> {
  bool showReview = false;
  bool _isLoading = false;

  String selectedDay = 'Kamis\n14';
  String selectedTime = '10.00 WIB';

  final List<String> days = [
    'Senin\n11',
    'Selasa\n12',
    'Rabu\n13',
    'Kamis\n14',
    'Jumat\n15',
    'Senin\n18',
    'Selasa\n19',
  ];

  final List<String> times = [
    '09.00 WIB',
    '10.00 WIB',
    '13.00 WIB',
    '14.00 WIB',
    '15.00 WIB',
    '16.00 WIB',
    '17.00 WIB',
    '20.00 WIB',
    '21.00 WIB',
  ];

  void _toggleFavorite() {
    setState(() {
      widget.professional.isFavorite = !widget.professional.isFavorite;
    });
  }

  DateTime _parseJadwal() {
    final dayNumber = int.parse(selectedDay.split('\n')[1]);
    final timeParts = selectedTime.replaceAll(' WIB', '').split('.');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, dayNumber, hour, minute);
  }

  void _addToAppointments(String? consultationId) {
    ProfessionalStore.addAppointment(
      AppointmentSession(
        professional: widget.professional,
        day: selectedDay,
        time: selectedTime,
        consultationId: consultationId,
      ),
    );
  }

  Future<void> _scheduleSession() async {
    final professionalId = widget.professional.id;

    // Fallback untuk profesional hardcoded (tanpa DB id)
    if (professionalId == null) {
      _addToAppointments(null);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const JanjiTemuPage()),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ConsultationService(Supabase.instance.client);

      final consultationId = await service.createConsultation(
        professionalId: professionalId,
        jadwal: _parseJadwal(),
      );

      final payment = await service.createPayment(consultationId);

      _addToAppointments(consultationId);

      if (!mounted) return;

      if (payment['free'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const JanjiTemuPage()),
        );
      } else {
        final snapUrl = payment['snapUrl'] as String? ?? '';
        if (snapUrl.isNotEmpty) {
          final uri = Uri.parse(snapUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const JanjiTemuPage()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat janji: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final professional = widget.professional;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF5A1368),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _toggleFavorite,
                          child: Icon(
                            professional.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 82,
                          height: 92,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.accentPurple,
                            size: 48,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                professional.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.textHeadingColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                professional.title,
                                style: TextStyle(
                                  color: context.textHeadingColor,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                professional.price,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                color: context.cardBg,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      value: '${professional.experienceYears} tahun',
                      label: 'Pengalaman',
                    ),
                    const _DividerLine(),
                    _StatItem(
                      value: '${professional.patients}',
                      label: 'Pasien',
                    ),
                    const _DividerLine(),
                    _StatItem(
                      value: '${professional.reviews}',
                      label: 'Ulasan',
                      hasStar: true,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Text(
                  professional.description,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 12,
                    height: 1.65,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showReview = false;
                        });
                      },
                      child: _TabItem(
                        text: 'Jadwal',
                        isSelected: !showReview,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showReview = true;
                        });
                      },
                      child: _TabItem(
                        text: 'Ulasan',
                        isSelected: showReview,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              showReview
                  ? const _ReviewSection()
                  : _ScheduleSection(
                      days: days,
                      times: times,
                      selectedDay: selectedDay,
                      selectedTime: selectedTime,
                      isLoading: _isLoading,
                      onDaySelected: (value) {
                        setState(() {
                          selectedDay = value;
                        });
                      },
                      onTimeSelected: (value) {
                        setState(() {
                          selectedTime = value;
                        });
                      },
                      onSchedule: _scheduleSession,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool hasStar;

  const _StatItem({
    required this.value,
    required this.label,
    this.hasStar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasStar)
              const Icon(
                Icons.star_rounded,
                color: AppColors.starGold,
                size: 18,
              ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF5A1368),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: Colors.grey.withValues(alpha: 0.25),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String text;
  final bool isSelected;

  const _TabItem({
    required this.text,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF5A1368) : Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          color: isSelected ? AppColors.accentPurple : Colors.transparent,
        ),
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  final List<String> days;
  final List<String> times;
  final String selectedDay;
  final String selectedTime;
  final bool isLoading;
  final ValueChanged<String> onDaySelected;
  final ValueChanged<String> onTimeSelected;
  final VoidCallback onSchedule;

  const _ScheduleSection({
    required this.days,
    required this.times,
    required this.selectedDay,
    required this.selectedTime,
    required this.isLoading,
    required this.onDaySelected,
    required this.onTimeSelected,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hari',
            style: TextStyle(
              color: context.textHeadingColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: days.map((day) {
                final bool isSelected = selectedDay == day;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onDaySelected(day),
                    child: Container(
                      width: 48,
                      height: 58,
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentPurple
                              : Colors.grey.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.accentPurple
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Jam',
            style: TextStyle(
              color: context.textHeadingColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: times.map((time) {
              final bool isSelected = selectedTime == time;

              return GestureDetector(
                onTap: () => onTimeSelected(time),
                child: Container(
                  width: 96,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentPurple
                          : Colors.grey.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accentPurple
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 46),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.purple.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(34),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Jadwalkan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection();

  @override
  Widget build(BuildContext context) {
    final reviews = [
      {
        'name': 'Najma Khoirun Nisa',
        'review':
            'dokternya baik banget mau dengerin aku. trus apresiatif banget. thanks dok!',
      },
      {
        'name': 'Nasywa Alyaa',
        'review':
            'nyaman banget curhat sm dokter ini, berasa didengerin dan dikasih solusi juga',
      },
      {
        'name': 'Intan Aprilia',
        'review':
            'responsif dokternya, tapi agak susah dapetin jadwalnya. tapi overall oke.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Column(
        children: reviews.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EEF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFE7D8EC),
                  child: Text(
                    item['name']![0],
                    style: const TextStyle(
                      color: Color(0xFF5A1368),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['review']!,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
