// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import '../models/user_profile_model.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../routes/page_transition.dart';
import '../services/notification_service.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'welcome_page.dart';

class ProfilPage extends ConsumerStatefulWidget {
  const ProfilPage({super.key});

  @override
  ConsumerState<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends ConsumerState<ProfilPage> {
  final _namaController = TextEditingController();
  final _noTelpController = TextEditingController();
  final _institusiController = TextEditingController();
  final _usiaController = TextEditingController();

  String? _selectedJenisKelamin;
  String? _selectedStatus;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _email;

  static const List<String> _statusOptions = [
    'Pelajar',
    'Mahasiswa',
    'Karyawan',
    'Lainnya',
  ];

  // The DB stores `status` in lowercase (enforced by a CHECK constraint), while
  // the dropdown shows capitalized labels. Map a stored value back to a valid
  // dropdown option, returning null for anything not in the list so the
  // DropdownButton never crashes on an unknown value.
  String? _displayStatusFromDb(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final normalized =
        raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    return _statusOptions.contains(normalized) ? normalized : null;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noTelpController.dispose();
    _institusiController.dispose();
    _usiaController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      _email = user?.email;

      // Read name from users table (source of truth), fall back to in-memory store
      final userData = await Supabase.instance.client
          .from('users')
          .select('nama')
          .eq('id', user!.id)
          .maybeSingle();
      _namaController.text = (userData?['nama'] as String?)?.isNotEmpty == true
          ? userData!['nama'] as String
          : UserProfileStore.name;

      final profileService = ref.read(profileServiceProvider);
      final profile = await profileService.getProfile();

      if (!mounted) return;
      if (profile != null) {
        setState(() {
          _noTelpController.text = profile['no_telp'] as String? ?? '';
          _institusiController.text = profile['institusi'] as String? ?? '';
          _selectedJenisKelamin = profile['jenis_kelamin'] as String?;
          _selectedStatus = _displayStatusFromDb(profile['status']);
          final usia = profile['usia'];
          _usiaController.text = usia != null ? usia.toString() : '';
        });
      }
    } catch (_) {
      // profile may not exist yet — that's fine
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final nama = _namaController.text.trim();
    if (nama.isEmpty) {
      _showSnack('Nama tidak boleh kosong');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final profileService = ref.read(profileServiceProvider);

      await profileService.updateUserName(nama);
      await profileService.updateProfile(
        noTelp: _noTelpController.text.trim().isEmpty
            ? null
            : _noTelpController.text.trim(),
        institusi: _institusiController.text.trim().isEmpty
            ? null
            : _institusiController.text.trim(),
        jenisKelamin: _selectedJenisKelamin,
        status: _selectedStatus?.toLowerCase(),
        usia: int.tryParse(_usiaController.text.trim()),
      );

      ref.read(profileProvider.notifier).updateName(nama);

      if (!mounted) return;
      _showSnack('Profil berhasil disimpan');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal menyimpan profil. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    setState(() {
      ref.read(profileProvider.notifier).setLocalImagePath(file.path);
    });
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.emergencyRed),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authService = ref.read(authServiceProvider);

    // Pembersihan token FCM tidak boleh menggagalkan proses logout. Jika gagal
    // (jaringan/Firebase), tetap lanjutkan sign out.
    try {
      await NotificationService.clearToken();
    } catch (_) {
      // Abaikan — sign out tetap dilakukan di bawah.
    }

    await authService.signOut();
    ref.read(profileProvider.notifier).clear();

    if (!mounted) return;
    Navigator.pushReplacement(context, PageTransition.fadeSlide(const WelcomePage()));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String? get _profileImagePath =>
      ref.read(profileProvider).valueOrNull?.localImagePath ??
      UserProfileStore.profileImagePath;

  bool get _hasProfileImage =>
      _profileImagePath != null &&
      _profileImagePath!.isNotEmpty &&
      File(_profileImagePath!).existsSync();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentPurple),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _ProfileHeader(
                          hasProfileImage: _hasProfileImage,
                          profileImagePath: _profileImagePath,
                          onPickImage: _pickImage,
                          name: _namaController.text,
                          email: _email,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionLabel('Informasi Pribadi'),
                              const SizedBox(height: 12),
                              _ProfileField(
                                label: 'Nama Lengkap',
                                controller: _namaController,
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 10),
                              _ProfileField(
                                label: 'Email',
                                initialValue: _email ?? '',
                                icon: Icons.email_outlined,
                                readOnly: true,
                              ),
                              const SizedBox(height: 10),
                              _ProfileField(
                                label: 'Nomor Telepon',
                                controller: _noTelpController,
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 10),
                              _ProfileField(
                                label: 'Usia',
                                controller: _usiaController,
                                icon: Icons.cake_outlined,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              const _SectionLabel('Lainnya'),
                              const SizedBox(height: 12),

                              // Jenis Kelamin toggle
                              _GenderToggle(
                                selected: _selectedJenisKelamin,
                                onChanged: (val) =>
                                    setState(() => _selectedJenisKelamin = val),
                              ),
                              const SizedBox(height: 10),

                              // Status dropdown
                              _DropdownField(
                                label: 'Status',
                                icon: Icons.work_outline_rounded,
                                value: _selectedStatus,
                                items: _statusOptions,
                                onChanged: (val) =>
                                    setState(() => _selectedStatus = val),
                              ),
                              const SizedBox(height: 10),
                              _ProfileField(
                                label: 'Institusi / Kampus',
                                controller: _institusiController,
                                icon: Icons.school_outlined,
                              ),
                              const SizedBox(height: 16),
                              const _SectionLabel('Tampilan'),
                              const SizedBox(height: 10),
                              _ThemeToggle(),
                              const SizedBox(height: 28),

                              // Save button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Simpan Perubahan',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Sign out
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: _signOut,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.emergencyRed,
                                    side: BorderSide(
                                      color: AppColors.emergencyRed
                                          .withOpacity(0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Keluar',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppBottomNavBar(
                  activeIndex: 3,
                  onHomeTap: () => Navigator.pop(context),
                  onChatTap: () => Navigator.pop(context),
                  onAddTap: () => Navigator.pop(context),
                  onProfileTap: () {},
                ),
              ],
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final bool hasProfileImage;
  final String? profileImagePath;
  final VoidCallback onPickImage;
  final String name;
  final String? email;

  const _ProfileHeader({
    required this.hasProfileImage,
    required this.profileImagePath,
    required this.onPickImage,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 16,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF420D4B), Color(0xFF7B337E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Back button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Profil Saya',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 26),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Avatar
          GestureDetector(
            onTap: onPickImage,
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7D8EC),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: hasProfileImage
                        ? Image.file(
                            File(profileImagePath!),
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: AppColors.accentPurple,
                            size: 52,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: AppColors.accentPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            name.isNotEmpty ? name : 'PsyBot User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (email != null) ...[
            const SizedBox(height: 3),
            Text(
              email!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.textHeadingColor,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final IconData icon;
  final bool readOnly;
  final TextInputType keyboardType;

  const _ProfileField({
    required this.label,
    required this.icon,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: context.subtleTextColor,
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: AppColors.accentPurple, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: readOnly,
          fillColor: readOnly ? context.inputFillAlt : null,
        ),
      ),
    );
  }
}

class _GenderToggle extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _GenderToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Jenis Kelamin'),
        const SizedBox(height: 6),
        Row(
          children: [
            _GenderOption(
              label: 'Laki-laki',
              icon: Icons.male_rounded,
              isSelected: selected == 'Laki-laki',
              onTap: () => onChanged(
                selected == 'Laki-laki' ? null : 'Laki-laki',
              ),
            ),
            const SizedBox(width: 10),
            _GenderOption(
              label: 'Perempuan',
              icon: Icons.female_rounded,
              isSelected: selected == 'Perempuan',
              onTap: () => onChanged(
                selected == 'Perempuan' ? null : 'Perempuan',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentPurple : context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentPurple
                  : context.borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : context.subtleTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            label,
            style: TextStyle(color: context.subtleTextColor, fontSize: 13),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.accentPurple),
          isExpanded: true,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.subtleTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          'Mode Gelap',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isDark ? 'Tampilan gelap aktif' : 'Tampilan terang aktif',
          style: TextStyle(
            color: context.subtleTextColor,
            fontSize: 12,
          ),
        ),
        secondary: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: AppColors.accentPurple,
        ),
        value: isDark,
        activeColor: AppColors.accentPurple,
        onChanged: (val) async {
          final mode = val ? ThemeMode.dark : ThemeMode.light;
          ref.read(themeModeProvider.notifier).state = mode;
          await saveThemePreference(mode);
        },
      ),
    );
  }
}
