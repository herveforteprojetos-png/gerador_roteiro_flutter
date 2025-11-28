import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/license_model.dart';

class ProtectedLicenseService {
  static const String _licenseFileName = 'license_data.json';
  static const String _activationFileName = 'device_activation.json';

  // Função simples para obter diretório de documentos
  static Future<Directory> _getDocumentsDirectory() async {
    if (Platform.isWindows) {
      return Directory(
        '${Platform.environment['USERPROFILE']}\\Documents\\FlutterGerador',
      );
    }
    return Directory('./FlutterGerador');
  }

  static const String _secretKey = 'FLUTTER_GERADOR_SECRET_2024';

  // Gera ID único do dispositivo
  static String _generateDeviceId() {
    final platform = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;
    final hostname = Platform.localHostname;
    final processors = Platform.numberOfProcessors.toString();

    final deviceInfo = '$platform-$version-$hostname-$processors';
    final bytes = utf8.encode(deviceInfo);
    final digest = sha256.convert(bytes);

    return digest.toString().substring(0, 16).toUpperCase();
  }

  // Sistema de ativações globais (em produção seria um servidor)
  static final Map<String, Map<String, dynamic>> _globalActivations = {};

  // Lista de licenças válidas
  static final Map<String, LicenseModel> _validLicenses = {
    'DEMO-DEMO-DEMO-DEMO': LicenseModel(
      licenseKey: 'DEMO-DEMO-DEMO-DEMO',
      clientName: 'Usuário Demonstração',
      createdAt: DateTime.now(),
      maxGenerations: 10,
    ),
  };

  // Valida licença com proteção anti-pirataria
  static Future<LicenseModel?> validateLicense(String licenseKey) async {
    if (kDebugMode) debugPrint('🔍 Validando licença com proteção...');

    // 1. Verifica formato
    if (!isValidKeyFormat(licenseKey)) {
      if (kDebugMode) debugPrint('❌ Formato inválido');
      return null;
    }

    // 2. Verifica se licença existe
    final license = _validLicenses[licenseKey];
    if (license == null) {
      if (kDebugMode) debugPrint('❌ Licença não encontrada');
      return null;
    }

    // 3. Verifica proteção anti-pirataria
    final protectionResult = await _checkDeviceProtection(licenseKey);
    if (!protectionResult['success']) {
      if (kDebugMode) debugPrint('❌ ${protectionResult['error']}');
      throw Exception(protectionResult['error']);
    }

    // 4. Verifica se licença é válida
    if (!license.isValid) {
      if (kDebugMode) debugPrint('❌ Licença expirada ou sem gerações');
      return null;
    }

    if (kDebugMode) debugPrint('✅ Licença validada com sucesso');
    return license;
  }

  // Verifica proteção do dispositivo
  static Future<Map<String, dynamic>> _checkDeviceProtection(
    String licenseKey,
  ) async {
    final deviceId = _generateDeviceId();

    // Verifica se já está ativado neste dispositivo
    final savedActivation = await _loadActivation();
    if (savedActivation != null &&
        savedActivation['licenseKey'] == licenseKey &&
        savedActivation['deviceId'] == deviceId) {
      if (kDebugMode) debugPrint('✅ Dispositivo já ativado');
      return {'success': true, 'message': 'Dispositivo já ativado'};
    }

    // Verifica se já está ativado em outro dispositivo
    if (_globalActivations.containsKey(licenseKey)) {
      final existingDeviceId = _globalActivations[licenseKey]!['deviceId'];

      if (existingDeviceId != deviceId) {
        return {
          'success': false,
          'error':
              'Esta licença já está ativada em outro computador.\nCada licença pode ser usada em apenas 1 PC.\n\nSe você formatou ou trocou de computador, entre em contato conosco.',
        };
      }
    }

    // Ativa no dispositivo atual
    await _activateDevice(licenseKey, deviceId);

    return {'success': true, 'message': 'Dispositivo ativado com sucesso'};
  }

  // Ativa dispositivo
  static Future<void> _activateDevice(
    String licenseKey,
    String deviceId,
  ) async {
    // Salva ativação global
    _globalActivations[licenseKey] = {
      'deviceId': deviceId,
      'activatedAt': DateTime.now().toIso8601String(),
      'lastUsed': DateTime.now().toIso8601String(),
    };

    // Salva ativação local
    await _saveActivation(licenseKey: licenseKey, deviceId: deviceId);

    if (kDebugMode) debugPrint('🔐 Licença ativada neste dispositivo');
  }

  // Salva ativação local
  static Future<void> _saveActivation({
    required String licenseKey,
    required String deviceId,
  }) async {
    try {
      final directory = await _getDocumentsDirectory();
      final file = File('${directory.path}/$_activationFileName');

      final activationData = {
        'licenseKey': licenseKey,
        'deviceId': deviceId,
        'activatedAt': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(json.encode(activationData));
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao salvar ativação: $e');
    }
  }

  // Carrega ativação local
  static Future<Map<String, dynamic>?> _loadActivation() async {
    try {
      final directory = await _getDocumentsDirectory();
      final file = File('${directory.path}/$_activationFileName');

      if (!await file.exists()) return null;

      final data = await file.readAsString();
      return json.decode(data);
    } catch (e) {
      return null;
    }
  }

  // Métodos originais mantidos
  static String generateLicenseKey(String clientName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$clientName-$timestamp-$_secretKey';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);

    final key = digest.toString().substring(0, 16).toUpperCase();
    return '${key.substring(0, 4)}-${key.substring(4, 8)}-${key.substring(8, 12)}-${key.substring(12, 16)}';
  }

  static bool isValidKeyFormat(String key) {
    final regex = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
    return regex.hasMatch(key);
  }

  static Future<void> saveLicenseData(LicenseModel license) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_licenseFileName');

      final jsonData = json.encode(license.toJson());
      await file.writeAsString(jsonData);
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao salvar dados de licença: $e');
    }
  }

  static Future<LicenseModel?> loadSavedLicenseData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_licenseFileName');

      if (!await file.exists()) return null;

      final jsonData = await file.readAsString();
      final data = json.decode(jsonData);

      return LicenseModel.fromJson(data);
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao carregar dados de licença: $e');
      return null;
    }
  }

  static Future<void> clearLicenseData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      // Remove dados da licença
      final licenseFile = File('${directory.path}/$_licenseFileName');
      if (await licenseFile.exists()) {
        await licenseFile.delete();
      }

      // Remove ativação do dispositivo
      final activationFile = File('${directory.path}/$_activationFileName');
      if (await activationFile.exists()) {
        await activationFile.delete();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao limpar dados: $e');
    }
  }

  static Future<LicenseModel?> incrementUsage(String licenseKey) async {
    final license = _validLicenses[licenseKey];
    if (license == null) return null;

    final updatedLicense = license.copyWith(
      usedGenerations: license.usedGenerations + 1,
    );

    _validLicenses[licenseKey] = updatedLicense;
    await saveLicenseData(updatedLicense);

    // Atualiza último uso
    if (_globalActivations.containsKey(licenseKey)) {
      _globalActivations[licenseKey]!['lastUsed'] = DateTime.now()
          .toIso8601String();
    }

    return updatedLicense;
  }

  static void addLicense(LicenseModel license) {
    _validLicenses[license.licenseKey] = license;
  }

  static LicenseModel createLicense({
    required String clientName,
    DateTime? expiresAt,
    int maxGenerations = -1,
  }) {
    final licenseKey = generateLicenseKey(clientName);
    final license = LicenseModel(
      licenseKey: licenseKey,
      clientName: clientName,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      maxGenerations: maxGenerations,
    );

    addLicense(license);
    return license;
  }

  // Reset para testes
  static Future<void> resetDeviceActivation() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_activationFileName');

      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) debugPrint('✅ Ativação do dispositivo removida');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erro ao remover ativação: $e');
    }
  }

  // Status das ativações (admin)
  static void printActivationStatus() {
    print('\n${'=' * 60}');
    print('STATUS DAS ATIVAÇÕES - CONTROLE ANTI-PIRATARIA');
    print('=' * 60);

    if (_globalActivations.isEmpty) {
      print('Nenhuma licença ativada ainda.');
      return;
    }

    for (final entry in _globalActivations.entries) {
      final licenseKey = entry.key;
      final data = entry.value;

      print('\n📄 Licença: $licenseKey');
      print('   🖥️  Dispositivo: ${data['deviceId']}');
      print('   📅 Ativada: ${data['activatedAt']}');
      print('   ⏰ Último uso: ${data['lastUsed']}');
    }

    print('\n${'=' * 60}');
  }
}
