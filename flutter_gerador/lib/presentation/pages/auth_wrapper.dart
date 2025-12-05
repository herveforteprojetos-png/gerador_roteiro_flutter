import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gerador/presentation/pages/login_page.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    // Limpa autenticação anterior para sempre mostrar tela de login
    await prefs.remove('is_authenticated');
    final isAuth = prefs.getBool('is_authenticated') ?? false;

    if (mounted) {
      setState(() {
        _isAuthenticated = isAuth;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1a1a1a),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
        ),
      );
    }

    if (_isAuthenticated) {
      // Placeholder - o código real do HomePage será carregado via navegação
      // Esta é uma solução temporária para evitar problemas de import circular
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const LoginPage();
  }
}
