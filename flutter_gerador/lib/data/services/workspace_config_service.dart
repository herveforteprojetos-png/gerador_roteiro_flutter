import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/workspace_config.dart';

class WorkspaceConfigService {
  static const String _configFileName = 'workspace_configs.json';
  
  // Cache em memória
  static Map<String, WorkspaceConfig> _configCache = {};
  
  /// Carrega todas as configurações de workspace
  static Future<Map<String, WorkspaceConfig>> loadAllConfigs() async {
    try {
      final file = await _getConfigFile();
      
      if (!await file.exists()) {
        return _createDefaultConfigs();
      }
      
      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final configs = <String, WorkspaceConfig>{};
      for (final entry in jsonData.entries) {
        configs[entry.key] = WorkspaceConfig.fromJson(entry.value);
      }
      
      _configCache = configs;
      return configs;
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao carregar configurações: $e');
      return _createDefaultConfigs();
    }
  }
  
  /// Salva todas as configurações
  static Future<void> saveAllConfigs(Map<String, WorkspaceConfig> configs) async {
    try {
      final file = await _getConfigFile();
      
      final jsonData = <String, dynamic>{};
      for (final entry in configs.entries) {
        jsonData[entry.key] = entry.value.toJson();
      }
      
      await file.writeAsString(json.encode(jsonData));
      _configCache = Map.from(configs);
      
      if (kDebugMode) debugPrint('Configurações salvas com sucesso');
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao salvar configurações: $e');
    }
  }
  
  /// Carrega configuração de um workspace específico
  static Future<WorkspaceConfig> loadConfig(String workspaceId) async {
    // Verifica cache primeiro
    if (_configCache.containsKey(workspaceId)) {
      return _configCache[workspaceId]!;
    }
    
    final allConfigs = await loadAllConfigs();
    return allConfigs[workspaceId] ?? _createDefaultConfig(workspaceId);
  }
  
  /// Salva configuração de um workspace específico
  static Future<void> saveConfig(WorkspaceConfig config) async {
    final allConfigs = await loadAllConfigs();
    allConfigs[config.workspaceId] = config;
    await saveAllConfigs(allConfigs);
  }
  
  /// Atualiza apenas a API key de um workspace
  static Future<void> updateApiKey(String workspaceId, String apiKey) async {
    final config = await loadConfig(workspaceId);
    final updatedConfig = config.copyWith(
      apiKey: apiKey,
      lastUpdated: DateTime.now(),
    );
    await saveConfig(updatedConfig);
  }
  
  /// Atualiza o nome de um workspace
  static Future<void> updateWorkspaceName(String workspaceId, String name) async {
    final config = await loadConfig(workspaceId);
    final updatedConfig = config.copyWith(
      workspaceName: name,
      lastUpdated: DateTime.now(),
    );
    await saveConfig(updatedConfig);
  }
  
  /// Obtém o arquivo de configuração
  static Future<File> _getConfigFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/FlutterGerador');
    
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    
    return File('${appDir.path}/$_configFileName');
  }
  
  /// Cria configurações padrão
  static Map<String, WorkspaceConfig> _createDefaultConfigs() {
    final now = DateTime.now();
    
    return {
      '1': WorkspaceConfig(
        workspaceId: '1',
        workspaceName: WorkspaceConfig.getDefaultName('1'),
        lastUpdated: now,
      ),
      '2': WorkspaceConfig(
        workspaceId: '2',
        workspaceName: WorkspaceConfig.getDefaultName('2'),
        lastUpdated: now,
      ),
      '3': WorkspaceConfig(
        workspaceId: '3',
        workspaceName: WorkspaceConfig.getDefaultName('3'),
        lastUpdated: now,
      ),
    };
  }
  
  /// Cria configuração padrão para um workspace
  static WorkspaceConfig _createDefaultConfig(String workspaceId) {
    return WorkspaceConfig(
      workspaceId: workspaceId,
      workspaceName: WorkspaceConfig.getDefaultName(workspaceId),
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Limpa o cache (útil para testes)
  static void clearCache() {
    _configCache.clear();
  }
}
