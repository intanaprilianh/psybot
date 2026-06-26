import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../providers/notification_provider.dart';

class NotifikasiPage extends ConsumerWidget {
  const NotifikasiPage({super.key});

  static IconData _iconForTipe(String tipe) {
    switch (tipe) {
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'konsultasi':
        return Icons.calendar_today_rounded;
      case 'meditasi':
        return Icons.self_improvement_rounded;
      case 'mood':
        return Icons.favorite_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final items = notificationsAsync.valueOrNull ?? [];
    final hasUnread = items.any((n) => n['dibaca'] != true);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: context.scaffoldBg,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: context.isDark ? AppColors.brightPurple : AppColors.purple,
            size: 28,
          ),
        ),
        title: Text(
          'Notifikasi',
          style: TextStyle(
            color: context.textHeadingColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: Text(
                'Tandai dibaca',
                style: TextStyle(
                  color: context.isDark
                      ? AppColors.brightPurple
                      : AppColors.accentPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentPurple),
        ),
        error: (_, _) => const _EmptyState(),
        data: (data) {
          if (data.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            color: AppColors.accentPurple,
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: data.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = data[index];
                final id = item['id'] as String;
                return Dismissible(
                  key: ValueKey(id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) =>
                      ref.read(notificationsProvider.notifier).remove(id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  child: _NotifCard(item: item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _NotifCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isRead = item['dibaca'] == true;
    final String judul = item['judul'] as String? ?? 'Notifikasi';
    final String deskripsi = item['deskripsi'] as String? ?? '';
    final String tipe = item['tipe'] as String? ?? 'sistem';
    final DateTime created =
        DateTime.tryParse(item['created_at'] as String? ?? '')?.toLocal() ??
            DateTime.now();

    // Unread notifications use the bold accent card; read ones are muted.
    final Color cardColor = isRead ? context.cardBg : AppColors.accentPurple;
    final Color titleColor = isRead ? context.textHeadingColor : Colors.white;
    final Color subColor =
        isRead ? context.subtleTextColor : Colors.white.withValues(alpha: 0.8);
    final Color iconBoxColor =
        isRead ? AppColors.accentPurple.withValues(alpha: 0.12) : Colors.white;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isRead ? Border.all(color: context.borderColor) : null,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBoxColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  NotifikasiPage._iconForTipe(tipe),
                  color: AppColors.accentPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            judul,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          NotifikasiPage._timeAgo(created),
                          style: TextStyle(
                            color: subColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (deskripsi.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        deskripsi,
                        style: TextStyle(
                          color: subColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: AppColors.accentPurple.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              color: context.subtleTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
