import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_gerador/core/theme/app_theme.dart';
import 'package:flutter_gerador/presentation/pages/auth_wrapper.dart';
import 'package:flutter_gerador/core/navigation/navigation_keys.dart';
import 'package:flutter_gerador/core/constants/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigationKeys.rootNavigatorKey,
      title: AppStrings.appTitle,
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}
