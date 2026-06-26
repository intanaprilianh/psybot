import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants/app_colors.dart';
import 'core/app_keys.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'screens/janji_temu_page.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // Firebase belum dikonfigurasi — jalankan `flutterfire configure`
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkPurple,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final initialTheme = await loadThemePreference();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((ref) => initialTheme),
      ],
      child: const PsyBotApp(),
    ),
  );
}

class PsyBotApp extends ConsumerStatefulWidget {
  const PsyBotApp({super.key});

  @override
  ConsumerState<PsyBotApp> createState() => _PsyBotAppState();
}

class _PsyBotAppState extends ConsumerState<PsyBotApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handlePaymentLink(initial);
    } catch (_) {
      // No initial link — fine.
    }
    _linkSub = _appLinks.uriLinkStream.listen(_handlePaymentLink);
  }

  // Handles the Midtrans callbacks: psybot://payment/finish | /error.
  void _handlePaymentLink(Uri uri) {
    if (uri.scheme != 'psybot' || uri.host != 'payment') return;
    final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = scaffoldMessengerKey.currentState;
      if (segment == 'finish') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const JanjiTemuPage()),
        );
        messenger?.showSnackBar(
          const SnackBar(
            content: Text(
              'Pembayaran selesai. Janji temu kamu sudah dikonfirmasi.',
            ),
          ),
        );
      } else if (segment == 'error') {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Pembayaran dibatalkan atau gagal. Coba lagi ya.'),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'PsyBot',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      scrollBehavior: const _AppScrollBehavior(),
      themeMode: themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const SplashScreen(),
    );
  }
}

// Perilaku scroll global: pakai efek "bounce" ala iOS di semua platform agar
// terasa halus/profesional, dan hilangkan efek stretch/glow bawaan Android.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  // Bounce sudah menggantikan indikator overscroll — jangan gambar stretch/glow.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

ThemeData _buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Arial',
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.purple,
      onPrimary: AppColors.white,
      secondary: AppColors.softPurple,
      onSecondary: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textDark,
      error: AppColors.emergencyRed,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textDark),
      titleTextStyle: TextStyle(
        color: AppColors.textHeading,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        fontFamily: 'Arial',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.purple,
        foregroundColor: AppColors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          fontFamily: 'Arial',
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.softPurple;
        }
        return null;
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.45),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: AppColors.softPurple,
          width: 1.3,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.deepPurple,
      contentTextStyle: const TextStyle(
        color: AppColors.white,
        fontSize: 14,
        fontFamily: 'Arial',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Arial',
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentPurple,
      onPrimary: AppColors.white,
      secondary: AppColors.softPurple,
      onSecondary: AppColors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      error: AppColors.emergencyRed,
    ),
    scaffoldBackgroundColor: AppColors.darkPurple,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        fontFamily: 'Arial',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPurple,
        foregroundColor: AppColors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          fontFamily: 'Arial',
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.softPurple;
        }
        return null;
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkInputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: AppColors.darkBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: AppColors.softPurple,
          width: 1.3,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface2,
      contentTextStyle: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 14,
        fontFamily: 'Arial',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
