import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile_model.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'informed_consent.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  DateTime? selectedDate;
  String? selectedGender;
  XFile? profileImage;
  bool isLoading = false;

  bool get isFormValid {
    return nameController.text.trim().isNotEmpty &&
        selectedDate != null &&
        selectedGender != null &&
        emailController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _refreshForm() {
    setState(() {});
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      profileImage = image;
    });
  }

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5A1368),
              onPrimary: Colors.white,
              onSurface: Color(0xFF161329),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    setState(() {
      selectedDate = pickedDate;
    });
  }

  String get formattedDate {
    if (selectedDate == null) return 'Pilih tanggal lahir';

    final String day = selectedDate!.day.toString().padLeft(2, '0');
    final String month = selectedDate!.month.toString().padLeft(2, '0');
    final String year = selectedDate!.year.toString();

    return '$day/$month/$year';
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _continueToHome() async {
    if (!isFormValid || isLoading) return;

    setState(() => isLoading = true);

    try {
      final profileService = ref.read(profileServiceProvider);
      final userName = nameController.text.trim();
      final String? imagePath = profileImage?.path;
      final usia = _calculateAge(selectedDate!);

      await profileService.updateUserName(userName);
      await profileService.updateProfile(
        usia: usia,
        jenisKelamin: selectedGender,
        noTelp: phoneController.text.trim(),
      );

      // Simpan image path sesi ini dan update nama di provider
      UserProfileStore.profileImagePath = imagePath;
      ref.read(profileProvider.notifier).updateName(userName);
      if (imagePath != null) {
        ref.read(profileProvider.notifier).setLocalImagePath(imagePath);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InformedConsentPage(),
        ),
      );
    } catch (e) {
      debugPrint('Onboarding error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan profil. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double width = size.width;
    final double height = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF070013),
      resizeToAvoidBottomInset: false,
      body: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.25,
            colors: [
              Color(0xFF3F004F),
              Color(0xFF170022),
              Color(0xFF070013),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: height * 0.035,
                left: 0,
                right: 0,
                child: const Text(
                  'PsyBot',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Positioned(
                top: height * 0.105,
                left: width * 0.07,
                right: width * 0.07,
                bottom: height * 0.035,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          width * 0.055,
                          20,
                          width * 0.055,
                          90,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Lengkapi Profil Yuk!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF5B58D7),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: GestureDetector(
                                onTap: _pickProfileImage,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 82,
                                      height: 82,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF8A2398),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: profileImage == null
                                            ? Container(
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                  Icons.person_rounded,
                                                  size: 42,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            : Image.file(
                                                File(profileImage!.path),
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                    Container(
                                      width: 27,
                                      height: 27,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 15,
                                        color: Color(0xFF161329),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Detail Personal',
                              style: TextStyle(
                                color: Color(0xFF151226),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const _FieldLabel(label: 'Nama Panjang'),
                            _ProfileTextField(
                              controller: nameController,
                              hintText: 'Masukkan nama panjang',
                              onChanged: _refreshForm,
                            ),
                            const SizedBox(height: 10),
                            const _FieldLabel(label: 'Tanggal Lahir'),
                            GestureDetector(
                              onTap: _pickBirthDate,
                              child: Container(
                                height: 43,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: selectedDate == null
                                              ? Colors.grey.withValues(
                                                  alpha: 0.75,
                                                )
                                              : const Color(0xFF151226),
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const _FieldLabel(label: 'Jenis Kelamin'),
                            Row(
                              children: [
                                Expanded(
                                  child: _GenderButton(
                                    text: 'Laki-Laki',
                                    isSelected:
                                        selectedGender == 'Laki-Laki',
                                    onTap: () {
                                      setState(() {
                                        selectedGender = 'Laki-Laki';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _GenderButton(
                                    text: 'Perempuan',
                                    isSelected:
                                        selectedGender == 'Perempuan',
                                    onTap: () {
                                      setState(() {
                                        selectedGender = 'Perempuan';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            const Text(
                              'Detail Kontak',
                              style: TextStyle(
                                color: Color(0xFF151226),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const _FieldLabel(label: 'Email'),
                            _ProfileTextField(
                              controller: emailController,
                              hintText: 'Masukkan email',
                              keyboardType: TextInputType.emailAddress,
                              onChanged: _refreshForm,
                            ),
                            const SizedBox(height: 10),
                            const _FieldLabel(label: 'No. Telp'),
                            _ProfileTextField(
                              controller: phoneController,
                              hintText: 'Masukkan No. Telp...',
                              keyboardType: TextInputType.phone,
                              onChanged: _refreshForm,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: width * 0.055,
                        bottom: 18,
                        child: SizedBox(
                          width: 105,
                          height: 44,
                          child: ElevatedButton(
                            onPressed:
                                isFormValid && !isLoading ? _continueToHome : null,
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (states) {
                                  if (!isFormValid || isLoading) {
                                    return Colors.grey.shade400;
                                  }
                                  if (states.contains(WidgetState.pressed)) {
                                    return const Color(0xFF3F004E);
                                  }
                                  return const Color(0xFF4D0A5E);
                                },
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all(Colors.white),
                              elevation:
                                  WidgetStateProperty.resolveWith<double>(
                                (states) {
                                  if (!isFormValid || isLoading) return 0;
                                  if (states.contains(WidgetState.pressed)) {
                                    return 1;
                                  }
                                  return 3;
                                },
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                            child: Text(
                              isLoading ? 'Simpan...' : 'Lanjut',
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: height * 0.215,
                right: -width * 0.015,
                child: Image.asset(
                  'assets/images/intipBoarding.png',
                  width: width * 0.30,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final VoidCallback onChanged;

  const _ProfileTextField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => onChanged(),
        style: const TextStyle(
          color: Color(0xFF151226),
          fontSize: 13.5,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.65),
            fontSize: 13.5,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 0,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(
              color: Colors.grey.withValues(alpha: 0.35),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(
              color: Color(0xFF5B58D7),
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isSelected ? const Color(0xFF8A2398) : Colors.white,
          foregroundColor: isSelected ? Colors.white : const Color(0xFF151226),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF8A2398)
                : Colors.grey.withValues(alpha: 0.35),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
