import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/license_model.dart';
import '../../data/services/protected_license_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState.unauthenticated()) {
    _checkSavedLicense();
  }

  Future<void> _checkSavedLicense() async {
    state = const AuthState.loading();
    
    try {
      final savedLicense = await ProtectedLicenseService.loadSavedLicenseData();
      if (savedLicense != null && savedLicense.isValid) {
        state = AuthState.authenticated(savedLicense);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error('Erro ao carregar licença: $e');
    }
  }

  Future<void> login(String licenseKey) async {
    state = const AuthState.loading();
    
    try {
      final cleanKey = licenseKey.trim().toUpperCase();
      if (kDebugMode) debugPrint('Debug - Tentando validar chave: $cleanKey');
      
      final license = await ProtectedLicenseService.validateLicense(cleanKey);
      
      if (license != null) {
        if (kDebugMode) debugPrint('Debug - Licença válida encontrada: ${license.clientName}');
        await ProtectedLicenseService.saveLicenseData(license);
        state = AuthState.authenticated(license);
      } else {
        if (kDebugMode) debugPrint('Debug - Licença não encontrada ou inválida para: $cleanKey');
        state = const AuthState.error('Chave de licença inválida ou expirada');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Debug - Erro na validação: $e');
      state = AuthState.error('$e');
    }
  }

  Future<void> logout() async {
    try {
      await ProtectedLicenseService.clearLicenseData();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error('Erro ao fazer logout: $e');
    }
  }

  Future<void> incrementUsage() async {
    final currentState = state;
    if (currentState is AuthenticatedState) {
      try {
        final updatedLicense = await ProtectedLicenseService.incrementUsage(currentState.license.licenseKey);
        if (updatedLicense != null) {
          state = AuthState.authenticated(updatedLicense);
        }
      } catch (e) {
        debugPrint('Erro ao incrementar uso: $e');
      }
    }
  }

  void clearError() {
    if (state is ErrorState) {
      state = const AuthState.unauthenticated();
    }
  }

  // Simulate login for workspace mode
  void simulateLogin() {
    final workspaceLicense = LicenseModel(
      licenseKey: 'WORKSPACE-DEMO',
      clientName: 'Workspace Demonstração',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(days: 365)),
      isActive: true,
      maxGenerations: 999999,
      usedGenerations: 0,
    );
    state = AuthState.authenticated(workspaceLicense);
  }
}

// Estados de autenticação
sealed class AuthState {
  const AuthState();

  const factory AuthState.loading() = LoadingState;
  const factory AuthState.unauthenticated() = UnauthenticatedState;
  const factory AuthState.authenticated(LicenseModel license) = AuthenticatedState;
  const factory AuthState.error(String message) = ErrorState;
  
  bool get isAuthenticated => this is AuthenticatedState;
  LicenseModel? get license => this is AuthenticatedState ? (this as AuthenticatedState).license : null;
}

class LoadingState extends AuthState {
  const LoadingState();
}

class UnauthenticatedState extends AuthState {
  const UnauthenticatedState();
}

class AuthenticatedState extends AuthState {
  @override
  final LicenseModel license;
  
  const AuthenticatedState(this.license);
}

class ErrorState extends AuthState {
  final String message;
  
  const ErrorState(this.message);
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
