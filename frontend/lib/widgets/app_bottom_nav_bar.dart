import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onChatTap;
  final VoidCallback onAddTap;
  final VoidCallback onProfileTap;

  const AppBottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onHomeTap,
    required this.onChatTap,
    required this.onAddTap,
    required this.onProfileTap,
  });

  static const Color activeColor = AppColors.accentPurple;
  static const Color inactiveColor = Color(0xFFC3C3C3);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58 + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.home_rounded,
            color: activeIndex == 0 ? activeColor : inactiveColor,
            size: 30,
            onTap: onHomeTap,
          ),
          _BottomNavItem(
            icon: Icons.chat_bubble_rounded,
            color: activeIndex == 1 ? activeColor : inactiveColor,
            size: 26,
            onTap: onChatTap,
          ),
          _BottomNavItem(
            icon: Icons.add_circle_rounded,
            color: activeIndex == 2 ? activeColor : inactiveColor,
            size: 28,
            onTap: onAddTap,
          ),
          _BottomNavItem(
            icon: Icons.person_rounded,
            color: activeIndex == 3 ? activeColor : inactiveColor,
            size: 28,
            onTap: onProfileTap,
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          color: color,
          size: size,
        ),
      ),
    );
  }
}