import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Simulated in-app emergency call screen (no real phone call is placed).
class EmergencyCallPage extends StatelessWidget {
  const EmergencyCallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.deepPurple,
      body: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            SizedBox(height: height * 0.08),

            const Text(
              'Layanan Darurat',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              '119',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),

            SizedBox(height: height * 0.06),

            Container(
              width: width * 0.36,
              height: width * 0.36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white24,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Image.asset(
                    'assets/images/kemenkes.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Kemenkes RI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Menghubungi...',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SideActionButton(
                  icon: Icons.volume_up_rounded,
                  onTap: () {},
                ),
                _EndCallButton(
                  onTap: () => Navigator.pop(context),
                ),
                _SideActionButton(
                  icon: Icons.videocam_rounded,
                  onTap: () {},
                ),
              ],
            ),

            SizedBox(height: height * 0.08),
          ],
        ),
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: AppColors.emergencyRed,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white10,
            width: 5,
          ),
        ),
        child: const Icon(
          Icons.call_end_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

class _SideActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SideActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
