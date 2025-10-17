import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workspace_config.dart';

class WorkspaceConfigService {
  static const String _keyPrefix = 'workspace_config_';
  static const String _allWorkspacesKey = 'all_workspace_ids';

  /// Carrega a configuração de um workspace específico
  static Future<WorkspaceConfig> loadConfig(String workspaceId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$workspaceId';
    final jsonString = prefs.getString(key);

    if (jsonString == null) {
      // Retorna configuração padrão se não existir
      return WorkspaceConfig(
        workspaceId: workspaceId,
        workspaceName: WorkspaceConfig.getDefaultName(workspaceId),
        lastUpdated: DateTime.now(),
      );
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return WorkspaceConfig.fromJson(json);
    } catch (e) {
      // Se houver erro ao decodificar, retorna configuração padrão
      return WorkspaceConfig(
        workspaceId: workspaceId,
        workspaceName: WorkspaceConfig.getDefaultName(workspaceId),
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Salva a configuração de um workspace
  static Future<void> saveConfig(WorkspaceConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${config.workspaceId}';
    final jsonString = jsonEncode(config.toJson());
    await prefs.setString(key, jsonString);

    // Adiciona o workspace ID à lista de todos os workspaces
    await _addWorkspaceId(config.workspaceId);
  }

  /// Atualiza apenas a API Key de um workspace
  static Future<void> updateApiKey(String workspaceId, String apiKey) async {
    final config = await loadConfig(workspaceId);
    final updatedConfig = config.copyWith(
      apiKey: apiKey,
      lastUpdated: DateTime.now(),
    );
    await saveConfig(updatedConfig);
  }

  /// Atualiza apenas o nome de um workspace
  static Future<void> updateWorkspaceName(String workspaceId, String name) async {
    final config = await loadConfig(workspaceId);
    final updatedConfig = config.copyWith(
      workspaceName: name,
      lastUpdated: DateTime.now(),
    );
    await saveConfig(updatedConfig);
  }

  /// Carrega todas as configurações de workspaces
  static Future<Map<String, WorkspaceConfig>> loadAllConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final workspaceIds = prefs.getStringList(_allWorkspacesKey) ?? [];
    
    final configs = <String, WorkspaceConfig>{};
    for (final id in workspaceIds) {
      configs[id] = await loadConfig(id);
    }

    return configs;
  }

  /// Adiciona um workspace ID à lista de todos os workspaces
  static Future<void> _addWorkspaceId(String workspaceId) async {
    final prefs = await SharedPreferences.getInstance();
    final workspaceIds = prefs.getStringList(_allWorkspacesKey) ?? [];
    
    if (!workspaceIds.contains(workspaceId)) {
      workspaceIds.add(workspaceId);
      await prefs.setStringList(_allWorkspacesKey, workspaceIds);
    }
  }

  /// Remove a configuração de um workspace
  static Future<void> deleteConfig(String workspaceId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$workspaceId';
    await prefs.remove(key);

    // Remove o workspace ID da lista
    final workspaceIds = prefs.getStringList(_allWorkspacesKey) ?? [];
    workspaceIds.remove(workspaceId);
    await prefs.setStringList(_allWorkspacesKey, workspaceIds);
  }

  /// Limpa todas as configurações de workspaces
  static Future<void> clearAllConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final workspaceIds = prefs.getStringList(_allWorkspacesKey) ?? [];
    
    for (final id in workspaceIds) {
      await prefs.remove('$_keyPrefix$id');
    }
    
    await prefs.remove(_allWorkspacesKey);
  }
}
