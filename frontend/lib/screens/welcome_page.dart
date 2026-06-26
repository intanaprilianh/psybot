import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../routes/page_transition.dart';
import 'sign_up_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _goToSignUp(BuildContext context) {
    Navigator.push(
      context,
      PageTransition.fadeSlide(const SignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: AppColors.darkPurple,
      body: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: AppColors.darkPurple,
              ),
            ),

            // Background lingkaran ungu besar di atas
            Positioned(
              top: -height * 0.18,
              left: -width * 0.34,
              child: Container(
                width: width * 1.70,
                height: width * 1.70,
                decoration: const BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Badge atas
            Positioned(
              top: MediaQuery.paddingOf(context).top + 18,
              left: width * 0.20,
              right: width * 0.20,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.badgePurple,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Teman AI Personal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Puyo loncat - dibesarin lagi
            // ASSET WAJIB: assets/images/puyo_loncat.png
            Positioned(
              top: height * 0.12,
              left: width * 0.01,
              right: width * 0.01,
              child: Image.asset(
                'assets/images/puyo_loncat.png',
                height: height * 0.50,
                fit: BoxFit.contain,
              ),
            ),

            // Teks welcome
            Positioned(
              left: width * 0.10,
              right: width * 0.10,
              bottom: height * 0.18,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.078,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                  children: const [
                    TextSpan(text: 'Hai! Aku '),
                    TextSpan(
                      text: 'Puyo',
                      style: TextStyle(
                        color: AppColors.brightPurple,
                      ),
                    ),
                    TextSpan(text: '! Sini\ncerita sama aku!'),
                  ],
                ),
              ),
            ),

            // Tombol bawah
            Positioned(
              left: width * 0.08,
              right: width * 0.08,
              bottom: height * 0.07,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _goToSignUp(context),
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return const Color(0xFFEADDF3);
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.all(
                      const Color(0xFF161329),
                    ),
                    elevation: WidgetStateProperty.resolveWith<double>(
                      (states) {
                        if (states.contains(WidgetState.pressed)) {
                          return 1;
                        }
                        return 0;
                      },
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Ayo Mulai!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
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