import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/license.dart';

class LicenseService {
  static const String _licenseKey = 'app_license';
  static const String _usageCountKey = 'usage_count';
  
  // Singleton
  static final LicenseService _instance = LicenseService._internal();
  factory LicenseService() => _instance;
  LicenseService._internal();

  License? _currentLicense;

  /// Gera um ID único do dispositivo baseado em hardware
  String generateDeviceId() {
    try {
      // Combina informações do sistema para criar um hash único
      final platform = Platform.operatingSystem;
      final version = Platform.operatingSystemVersion;
      final hostname = Platform.localHostname;
      final environment = Platform.environment;
      
      // Pega informações específicas do Windows
      final computerName = environment['COMPUTERNAME'] ?? 'unknown';
      final userName = environment['USERNAME'] ?? 'unknown';
      final processor = environment['PROCESSOR_IDENTIFIER'] ?? 'unknown';
      
      final deviceInfo = '$platform-$version-$hostname-$computerName-$userName-$processor';
      final bytes = utf8.encode(deviceInfo);
      final digest = sha256.convert(bytes);
      
      return digest.toString().substring(0, 32).toUpperCase();
    } catch (e) {
      // Fallback para um ID baseado em timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fallback = 'FALLBACK-$timestamp';
      final bytes = utf8.encode(fallback);
      final digest = sha256.convert(bytes);
      return digest.toString().substring(0, 32).toUpperCase();
    }
  }

  /// Carrega a licença atual
  Future<License> loadLicense() async {
    if (_currentLicense != null) {
      return _currentLicense!;
    }

    final prefs = await SharedPreferences.getInstance();
    final licenseJson = prefs.getString(_licenseKey);
    
    if (licenseJson != null) {
      try {
        final licenseData = jsonDecode(licenseJson) as Map<String, dynamic>;
        _currentLicense = License.fromJson(licenseData);
        
        // Verifica se a licença é para este dispositivo
        final currentDeviceId = generateDeviceId();
        if (_currentLicense!.deviceId != currentDeviceId) {
          // Licença é de outro dispositivo, reset para demo
          _currentLicense = License.demo(currentDeviceId);
          await saveLicense(_currentLicense!);
        }
        
        return _currentLicense!;
      } catch (e) {
        // Erro ao carregar, volta para demo
        final deviceId = generateDeviceId();
        _currentLicense = License.demo(deviceId);
        await saveLicense(_currentLicense!);
        return _currentLicense!;
      }
    }
    
    // Primeira execução, cria licença demo
    final deviceId = generateDeviceId();
    _currentLicense = License.demo(deviceId);
    await saveLicense(_currentLicense!);
    return _currentLicense!;
    _currentLicense = License.demo(deviceId);
    await saveLicense(_currentLicense!);
  }

  /// Salva a licença
  Future<void> saveLicense(License license) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_licenseKey, jsonEncode(license.toJson()));
    _currentLicense = license;
  }

  /// Verifica se pode usar o app (não excedeu limite demo ou tem licença válida)
  Future<bool> canUseApp() async {
    final license = await loadLicense();
    
    if (license.type == LicenseType.lifetime) {
      return true;
    }
    
    // Para demo, verifica se não excedeu o limite
    return license.usageCount < 10;
  }

  /// Incrementa o contador de uso (apenas para demo)
  Future<void> incrementUsage() async {
    final license = await loadLicense();
    
    if (license.type == LicenseType.demo) {
      final updatedLicense = License(
        type: license.type,
        deviceId: license.deviceId,
        usageCount: license.usageCount + 1,
        createdAt: license.createdAt,
        licenseKey: license.licenseKey,
        isActive: license.isActive,
        expiryDate: license.expiryDate,
        usageLimit: license.usageLimit,
      );
      
      await saveLicense(updatedLicense);
    }
  }

  /// Ativa uma licença vitalícia usando uma chave
  Future<bool> activateLifetimeLicense(String key) async {
    if (!_isValidLicenseKey(key)) {
      return false;
    }
    
    final deviceId = generateDeviceId();
    final lifetimeLicense = License.lifetime(deviceId, key);
    
    await saveLicense(lifetimeLicense);
    return true;
  }

  /// Valida formato da chave de licença
  bool _isValidLicenseKey(String key) {
    // Formato: XXXX-XXXX-XXXX-XXXX
    final regex = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
    return regex.hasMatch(key.toUpperCase());
  }

  /// Gera uma chave de licença para um cliente
  String generateLicenseKey(String clientInfo) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$clientInfo-$timestamp-FLUTTER_GERADOR_2024';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    
    // Formatar como XXXX-XXXX-XXXX-XXXX
    final key = digest.toString().substring(0, 16).toUpperCase();
    return '${key.substring(0, 4)}-${key.substring(4, 8)}-${key.substring(8, 12)}-${key.substring(12, 16)}';
  }

  /// Obtém informações da licença atual
  Future<Map<String, dynamic>> getLicenseInfo() async {
    final license = await loadLicense();
    
    return {
      'type': license.type.name,
      'deviceId': license.deviceId,
      'usageCount': license.usageCount,
      'remainingUses': license.type == LicenseType.demo ? (10 - license.usageCount) : -1,
      'isActive': license.type == LicenseType.lifetime || license.usageCount < 10,
      'licenseKey': license.licenseKey,
      'createdAt': license.createdAt.toIso8601String(),
    };
  }

  /// Reset para modo demo (para desenvolvimento/testes)
  Future<void> resetToDemo() async {
    final deviceId = generateDeviceId();
    final demoLicense = License.demo(deviceId);
    await saveLicense(demoLicense);
  }
}
