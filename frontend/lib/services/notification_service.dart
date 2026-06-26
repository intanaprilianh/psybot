import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import '../core/app_keys.dart';
import 'app_notification_service.dart';

// Handler pesan FCM saat app di background/terminated.
// Harus berupa top-level function (bukan method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages ditangani oleh sistem Android secara otomatis.
  // Tambahkan logika custom di sini jika diperlukan.
}

class NotificationService {
  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Daftarkan background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Minta izin notifikasi (Android 13+)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Daftarkan token saat pertama kali
    await _registerToken();

    // Perbarui token otomatis jika token FCM berubah
    messaging.onTokenRefresh.listen(_saveToken);

    // Tangani notifikasi saat app sedang terbuka (foreground)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  static Future<void> _registerToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _saveToken(token);
  }

  static Future<void> _saveToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client
        .from('users')
        .update({'fcm_token': token})
        .eq('id', user.id);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    final String judul =
        notif?.title ?? message.data['judul'] as String? ?? 'Notifikasi';
    final String deskripsi =
        notif?.body ?? message.data['deskripsi'] as String? ?? '';
    final String tipe = message.data['tipe'] as String? ?? 'sistem';

    // Simpan ke tabel notifications agar muncul di halaman Notifikasi.
    AppNotificationService.insert(
      judul: judul,
      deskripsi: deskripsi,
      tipe: tipe,
    ).ignore();

    // Android tidak menampilkan banner otomatis saat app terbuka — tampilkan
    // banner in-app sendiri.
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              if (deskripsi.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    deskripsi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.white),
                  ),
                ),
            ],
          ),
        ),
      );
  }

  // Hapus token FCM saat logout agar notifikasi tidak dikirim ke perangkat lama
  static Future<void> clearToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client
        .from('users')
        .update({'fcm_token': null})
        .eq('id', user.id);

    await FirebaseMessaging.instance.deleteToken();
  }
}
