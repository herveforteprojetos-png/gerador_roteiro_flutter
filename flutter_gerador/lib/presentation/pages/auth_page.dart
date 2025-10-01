import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return switch (authState) {
      LoadingState() => const Scaffold(
          backgroundColor: Color(0xFF1a1a1a),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF6B35),
            ),
          ),
        ),
      UnauthenticatedState() => const LoginPage(),
      ErrorState() => const LoginPage(),
      _ => const LoginPage(),
    };
  }
}
