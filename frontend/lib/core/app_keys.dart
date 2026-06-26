import 'package:flutter/material.dart';

/// Global keys so non-widget code (FCM handlers, deep-link listeners) can drive
/// navigation and show SnackBars without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
