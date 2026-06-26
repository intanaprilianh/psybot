import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_provider.dart';
import '../services/app_notification_service.dart';

final appNotificationServiceProvider = Provider<AppNotificationService>((ref) {
  return AppNotificationService(ref.watch(supabaseProvider));
});

class NotificationsNotifier
    extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return ref.watch(appNotificationServiceProvider).getNotifications();
  }

  Future<void> markAllRead() async {
    await ref.read(appNotificationServiceProvider).markAllAsRead();
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(appNotificationServiceProvider).delete(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<Map<String, dynamic>>>(
  NotificationsNotifier.new,
);
