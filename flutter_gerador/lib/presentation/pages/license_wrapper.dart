import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/license_provider.dart';
import 'license_page.dart' as custom_license;
import 'auth_wrapper.dart';
import '../../data/models/license.dart';

class LicenseWrapper extends ConsumerWidget {
  const LicenseWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licenseState = ref.watch(licenseProvider);
    
    return licenseState.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF1a1a1a),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
              SizedBox(height: 16),
              Text(
                'Verificando licença...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro ao verificar licença',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(licenseProvider),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (license) {
        // Verifica se a licença permite uso
        if (license.type == LicenseType.lifetime) {
          // Licença vitalícia, pode usar
          return const AuthWrapper();
        } 
        
        if (license.type == LicenseType.demo && license.usageCount >= 10) {
          // Demo expirado, força ativação de licença
          return const _DemoExpiredScreen();
        }
        
        // Demo ainda válido ou licença ativa, pode usar
        return const AuthWrapper();
      },
    );
  }
}

class _DemoExpiredScreen extends StatelessWidget {
  const _DemoExpiredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                color: Color(0xFFFF6B35),
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Período de Demonstração Expirado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Você utilizou todas as 10 gerações do modo demonstração.\nPara continuar usando o Flutter Gerador, é necessário ativar uma licença vitalícia.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => const custom_license.LicensePage(canContinueWithDemo: false),
                      ),
                    );
                    
                    if (result == true) {
                      // Licença foi ativada, recarrega o provider
                      // O LicenseWrapper irá automaticamente reconstruir
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ativar Licença',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Entre em contato para adquirir uma licença',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
