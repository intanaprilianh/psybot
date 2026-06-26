import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../core/supabase_provider.dart';
import '../services/self_help_service.dart';

class SelfHelpPage extends ConsumerStatefulWidget {
  const SelfHelpPage({super.key});

  @override
  ConsumerState<SelfHelpPage> createState() => _SelfHelpPageState();
}

class _SelfHelpPageState extends ConsumerState<SelfHelpPage> {
  List<Map<String, dynamic>> contents = [];
  bool isLoading = true;
  String? selectedKategori;
  int? expandedIndex;

  static const kategoriLabels = {
    'breathing_exercise': 'Latihan Napas',
    'mindfulness': 'Mindfulness',
    'relaksasi': 'Relaksasi',
    'journaling': 'Journaling',
    'olahraga_ringan': 'Olahraga Ringan',
    'edukasi_mental_health': 'Edukasi',
    'krisis': 'Krisis',
    'social_support': 'Dukungan Sosial',
  };

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final service = SelfHelpService(ref.read(supabaseProvider));
      final data = await service.getContent(kategori: selectedKategori);

      if (!mounted) return;
      setState(() {
        contents = data;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _onKategoriTap(String? kategori) {
    setState(() {
      selectedKategori = kategori;
      isLoading = true;
      expandedIndex = null;
    });
    _loadContent();
  }

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
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.purple,
            size: 28,
          ),
        ),
        title: Text(
          'Self-Help',
          style: TextStyle(
            color: context.textHeadingColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'Semua',
                  isSelected: selectedKategori == null,
                  onTap: () => _onKategoriTap(null),
                ),
                ...kategoriLabels.entries.map((e) {
                  return _FilterChip(
                    label: e.value,
                    isSelected: selectedKategori == e.key,
                    onTap: () => _onKategoriTap(e.key),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentPurple,
                    ),
                  )
                : contents.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada konten tersedia.',
                          style: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: contents.length,
                        itemBuilder: (context, index) {
                          final item = contents[index];
                          final isExpanded = expandedIndex == index;
                          final kategori = item['kategori'] as String? ?? '';
                          final label =
                              kategoriLabels[kategori] ?? kategori;
                          final durasi =
                              item['durasi_menit'] as int? ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    expandedIndex =
                                        isExpanded ? null : index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['judul'] as String? ??
                                                  '',
                                              style: TextStyle(
                                                color: context.textHeadingColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            isExpanded
                                                ? Icons
                                                    .keyboard_arrow_up_rounded
                                                : Icons
                                                    .keyboard_arrow_down_rounded,
                                            color: AppColors.accentPurple,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.chipBg,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                color:
                                                    AppColors.accentPurple,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (durasi > 0) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.timer_outlined,
                                              size: 13,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '$durasi menit',
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (isExpanded) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          item['konten'] as String? ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFF333333),
                                            fontSize: 13.5,
                                            height: 1.55,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentPurple : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentPurple
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
