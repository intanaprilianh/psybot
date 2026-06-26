import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../routes/page_transition.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'sign_up_page.dart';
import 'onboarding_page.dart';
import 'home_page.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool agreePrivacy = true;
  bool isLoading = false;

  bool get isFormValid {
    return emailController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        agreePrivacy;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _refreshForm() {
    setState(() {});
  }

  void _goToSignUp() {
    Navigator.pushReplacement(
      context,
      PageTransition.fadeSlide(const SignUpPage()),
    );
  }

  Future<void> _signIn() async {
    if (!isFormValid || isLoading) return;

    setState(() => isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      final user = Supabase.instance.client.auth.currentUser!;
      final profile = await Supabase.instance.client
          .from('user_profile')
          .select('onboarding_complete')
          .eq('id_user', user.id)
          .maybeSingle();

      if (!mounted) return;

      final onboardingComplete = profile?['onboarding_complete'] == true;

      if (onboardingComplete) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageTransition.fadeSlide(const HomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageTransition.fadeSlide(const OnboardingPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;

      String message = 'Gagal masuk. Coba lagi.';
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('invalid login credentials') ||
          errorMsg.contains('invalid_credentials')) {
        message = 'Email atau kata sandi salah.';
      } else if (errorMsg.contains('email not confirmed')) {
        message = 'Email belum diverifikasi. Cek inbox kamu.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;

    final topHeight = height * 0.27;
    final panelTop = topHeight - 32;

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topHeight,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.darkPurple,
                      AppColors.purple,
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top + 34,
                    left: 26,
                  ),
                  child: const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'PsyBot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: panelTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    width * 0.075,
                    62,
                    width * 0.075,
                    22 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Ayo Masuk!',
                        style: TextStyle(
                          color: AppColors.softPurple,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 22),
                      CustomTextField(
                        controller: emailController,
                        labelText: 'Email',
                        hintText: 'Masukkan Email...',
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _refreshForm,
                      ),
                      const SizedBox(height: 11),
                      CustomTextField(
                        controller: passwordController,
                        labelText: 'Kata Sandi',
                        hintText: 'Masukkan Kata Sandi...',
                        obscureText: true,
                        onChanged: _refreshForm,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.82,
                            child: Checkbox(
                              value: agreePrivacy,
                              activeColor: AppColors.softPurple,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (value) {
                                setState(() {
                                  agreePrivacy = value ?? false;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Saya setuju dengan pemrosesan ',
                                  ),
                                  TextSpan(
                                    text: 'Data Pribadi',
                                    style: TextStyle(
                                      color: AppColors.linkPurple,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        text: isLoading ? 'Masuk...' : 'Masuk',
                        onPressed: isFormValid && !isLoading ? _signIn : null,
                      ),
                      const SizedBox(height: 17),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.withValues(alpha: 0.45),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Masuk Dengan',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Google Sign-In belum dikonfigurasi',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/images/google.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                          GestureDetector(
                            onTap: _goToSignUp,
                            child: const Text(
                              'Daftar Di Sini',
                              style: TextStyle(
                                color: AppColors.linkPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: panelTop - 109,
              right: width * 0.06,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                child: Image.asset(
                  'assets/images/puyo_intip.png',
                  width: width * 0.48,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
