import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../core/supabase_provider.dart';
import '../models/call_center_model.dart';
import '../services/risk_service.dart';

class CallCenterBottomSheet extends ConsumerStatefulWidget {
  final List<CallCenterService> services;
  final String alertId;

  const CallCenterBottomSheet({
    super.key,
    required this.services,
    required this.alertId,
  });

  @override
  ConsumerState<CallCenterBottomSheet> createState() =>
      _CallCenterBottomSheetState();
}

class _CallCenterBottomSheetState
    extends ConsumerState<CallCenterBottomSheet> {
  bool isReporting = false;

  Future<void> _contactService(CallCenterService service) async {
    setState(() => isReporting = true);

    try {
      final riskService = RiskService(ref.read(supabaseProvider));
      await riskService.reportUserChoice(
        alertId: widget.alertId,
        userChoice: 'contacted',
        callCenterName: service.nama,
      );
    } catch (_) {}

    final uri = Uri.parse(service.nomor);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _decline() async {
    setState(() => isReporting = true);

    try {
      final riskService = RiskService(ref.read(supabaseProvider));
      await riskService.reportUserChoice(
        alertId: widget.alertId,
        userChoice: 'declined',
      );
    } catch (_) {}

    if (mounted) Navigator.pop(context);
  }

  IconData _iconForTipe(String tipe) {
    switch (tipe) {
      case 'whatsapp':
        return Icons.chat_rounded;
      case 'chat':
        return Icons.message_rounded;
      default:
        return Icons.call_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Icon(
              Icons.favorite_rounded,
              color: AppColors.accentPurple,
              size: 36,
            ),
            const SizedBox(height: 10),
            const Text(
              'Kamu Tidak Sendirian',
              style: TextStyle(
                color: AppColors.textHeading,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Berikut layanan bantuan yang bisa menemanimu. Sepenuhnya pilihanmu — tidak ada tekanan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ...widget.services.map((service) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: const Color(0xFFF8F2FA),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: isReporting ? null : () => _contactService(service),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accentPurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _iconForTipe(service.tipe),
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.nama,
                                  style: const TextStyle(
                                    color: AppColors.textHeading,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${service.jamOperasional} • ${service.gratis ? "Gratis" : "Berbayar"}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.accentPurple,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: isReporting ? null : _decline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Tidak sekarang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
