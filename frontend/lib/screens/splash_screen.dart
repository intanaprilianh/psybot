import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import '../routes/page_transition.dart';
import '../services/notification_service.dart';
import 'home_page.dart';
import 'onboarding_page.dart';
import 'welcome_page.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      _goTo(const WelcomePage());
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('user_profile')
          .select('onboarding_complete')
          .eq('id_user', session.user.id)
          .maybeSingle();

      if (!mounted) return;

      final onboardingComplete = profile?['onboarding_complete'] == true;

      // Daftarkan token FCM setelah user terautentikasi
      NotificationService.initialize().ignore();

      if (onboardingComplete) {
        if (!mounted) return;
        _goTo(const HomePage());
      } else {
        _goTo(const OnboardingPage());
      }
    } catch (_) {
      if (!mounted) return;
      _goTo(const WelcomePage());
    }
  }

  void _goTo(Widget page) {
    Navigator.pushReplacement(
      context,
      PageTransition.fadeUp(page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: AppColors.darkPurple,
      body: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.15,
            colors: [
              AppColors.purple,
              AppColors.deepPurple,
              AppColors.darkPurple,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: height * 0.075,
              left: width * 0.18,
              right: width * 0.18,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.badgePurple,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Teman AI Personal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.038,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              top: height * 0.34,
              left: 0,
              right: 0,
              child: Text(
                'PsyBot',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              left: -width * 0.12,
              bottom: -height * 0.03,
              child: Image.asset(
                'assets/images/puyo_splash.png',
                width: width * 0.95,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
