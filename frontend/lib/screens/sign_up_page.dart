import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../routes/page_transition.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'sign_in_page.dart';
import 'onboarding_page.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool agreePrivacy = true;
  bool isLoading = false;

  bool get isFormValid {
    return nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        agreePrivacy;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _refreshForm() {
    setState(() {});
  }

  void _goToSignIn() {
    Navigator.push(
      context,
      PageTransition.fadeSlide(const SignInPage()),
    );
  }

  Future<void> _signUp() async {
    if (!isFormValid || isLoading) return;

    setState(() => isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        nama: nameController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageTransition.fadeSlide(const OnboardingPage()),
      );
    } catch (e) {
      debugPrint('SignUp error: $e');
      if (!mounted) return;

      String message = 'Gagal mendaftar. Coba lagi.';
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already registered') ||
          errorMsg.contains('already been registered')) {
        message = 'Email sudah terdaftar. Silakan masuk.';
      } else if (errorMsg.contains('password')) {
        message = 'Kata sandi minimal 6 karakter.';
      } else if (errorMsg.contains('invalid') && errorMsg.contains('email')) {
        message = 'Format email tidak valid.';
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

    final topHeight = height * 0.255;
    final panelTop = topHeight - 32;

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: SizedBox(
        width: width,
        height: height,
        child: Stack(
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
                    right: 26,
                  ),
                  child: const Align(
                    alignment: Alignment.topRight,
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
                    58,
                    width * 0.075,
                    22 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Ayo Mulai!',
                        style: TextStyle(
                          color: AppColors.softPurple,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: nameController,
                        labelText: 'Nama Panjang',
                        hintText: 'Masukkan Nama Panjang...',
                        onChanged: _refreshForm,
                      ),
                      const SizedBox(height: 11),
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
                        text: isLoading ? 'Mendaftar...' : 'Daftar',
                        onPressed: isFormValid && !isLoading ? _signUp : null,
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
                              'Daftar Dengan',
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
                      Image.asset(
                        'assets/images/google.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah punya akun? ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                          GestureDetector(
                            onTap: _goToSignIn,
                            child: const Text(
                              'Masuk Di Sini',
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
              top: panelTop - 95,
              left: width * 0.07,
              child: Image.asset(
                'assets/images/puyo_intip.png',
                width: width * 0.43,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
