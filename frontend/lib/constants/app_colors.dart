import 'package:flutter/material.dart';

class AppColors {
  // Light palette
  static const Color darkPurple = Color(0xFF020018);
  static const Color deepPurple = Color(0xFF210635);
  static const Color purple = Color(0xFF420D4B);
  static const Color accentPurple = Color(0xFF7B337E);
  static const Color brightPurple = Color(0xFFE84DFF);
  static const Color badgePurple = Color(0xFF9A4FA2);
  static const Color softPurple = Color(0xFF595BD5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color emergencyRed = Color(0xFFC44B4B);
  static const Color favoriteRed = Color(0xFFD90000);
  static const Color starGold = Color(0xFFFEBA09);

  static const Color lightBackground = Color(0xFFF8F2FA);
  static const Color surface = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF130B25);
  static const Color textHeading = Color(0xFF21062D);
  static const Color linkPurple = Color(0xFF2F235C);

  // Dark palette (from design SVGs)
  static const Color darkSurface = Color(0xFF1A182C);
  static const Color darkSurface2 = Color(0xFF2E2B4C);
  static const Color darkChipBg = Color(0xFF38163F);
  static const Color darkTextPrimary = Color(0xFFFBFAFF);
  static const Color darkTextSecondary = Color(0xFFC3C3C3);
  static const Color darkBorder = Color(0xFF2E2B4C);
  static const Color darkInputFill = Color(0xFF16163F);
}

extension AppTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg =>
      isDark ? AppColors.darkPurple : AppColors.lightBackground;

  Color get cardBg => isDark ? AppColors.darkSurface : Colors.white;

  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.textDark;

  Color get textHeadingColor =>
      isDark ? AppColors.darkTextPrimary : AppColors.textHeading;

  Color get subtleTextColor =>
      isDark ? AppColors.darkTextSecondary : const Color(0xFF888888);

  Color get borderColor =>
      isDark ? AppColors.darkBorder : const Color(0xFFE8E0ED);

  Color get chipBg =>
      isDark ? AppColors.darkChipBg : const Color(0xFFF0E3F3);

  Color get inputFillColor =>
      isDark ? AppColors.darkInputFill : Colors.white;

  Color get inputFillAlt =>
      isDark ? AppColors.darkSurface : const Color(0xFFFBFAFF);

  Color get dividerColor =>
      isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);

  Color get avatarBg =>
      isDark ? AppColors.darkSurface2 : const Color(0xFFE7D8EC);
}
