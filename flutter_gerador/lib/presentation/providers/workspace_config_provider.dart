import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/workspace_config.dart';
import '../../data/services/workspace_config_service.dart';

class WorkspaceConfigNotifier extends StateNotifier<AsyncValue<WorkspaceConfig>> {
  final String workspaceId;
  
  WorkspaceConfigNotifier(this.workspaceId) : super(const AsyncValue.loading()) {
    loadConfig();
  }
  
  Future<void> loadConfig() async {
    try {
      state = const AsyncValue.loading();
      final config = await WorkspaceConfigService.loadConfig(workspaceId);
      state = AsyncValue.data(config);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<void> updateApiKey(String apiKey) async {
    try {
      await WorkspaceConfigService.updateApiKey(workspaceId, apiKey);
      await loadConfig(); // Recarrega para garantir consistência
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<void> updateWorkspaceName(String name) async {
    try {
      await WorkspaceConfigService.updateWorkspaceName(workspaceId, name);
      await loadConfig(); // Recarrega para garantir consistência
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<void> updateConfig(WorkspaceConfig config) async {
    try {
      await WorkspaceConfigService.saveConfig(config);
      await loadConfig(); // Recarrega para garantir consistência
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Provider family para diferentes workspaces
final workspaceConfigProvider = StateNotifierProvider.family<WorkspaceConfigNotifier, AsyncValue<WorkspaceConfig>, String>((ref, workspaceId) {
  return WorkspaceConfigNotifier(workspaceId);
});

// Provider para carregar todas as configurações (útil para o AuthWrapper)
final allWorkspaceConfigsProvider = FutureProvider<Map<String, WorkspaceConfig>>((ref) async {
  return await WorkspaceConfigService.loadAllConfigs();
});
