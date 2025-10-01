import 'package:flutter/material.dart';

/// Central place for global navigation keys.
/// Use only when you can't access BuildContext directly.
class AppNavigationKeys {
  AppNavigationKeys._();

  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
}
