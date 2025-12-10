class WorkspaceConfig {
  final String workspaceId;
  final String workspaceName;
  final String? apiKey;
  final String? modelName;
  final Map<String, dynamic> additionalSettings;
  final DateTime lastUpdated;

  const WorkspaceConfig({
    required this.workspaceId,
    required this.workspaceName,
    this.apiKey,
    this.modelName,
    this.additionalSettings = const {},
    required this.lastUpdated,
  });

  WorkspaceConfig copyWith({
    String? workspaceId,
    String? workspaceName,
    String? apiKey,
    String? modelName,
    Map<String, dynamic>? additionalSettings,
    DateTime? lastUpdated,
  }) {
    return WorkspaceConfig(
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceName: workspaceName ?? this.workspaceName,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      additionalSettings: additionalSettings ?? this.additionalSettings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'apiKey': apiKey,
      'modelName': modelName,
      'additionalSettings': additionalSettings,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory WorkspaceConfig.fromJson(Map<String, dynamic> json) {
    return WorkspaceConfig(
      workspaceId: json['workspaceId'] ?? '',
      workspaceName: json['workspaceName'] ?? '',
      apiKey: json['apiKey'],
      modelName: json['modelName'],
      additionalSettings: Map<String, dynamic>.from(
        json['additionalSettings'] ?? {},
      ),
      lastUpdated: DateTime.parse(
        json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Método para obter nome padrão baseado no ID
  static String getDefaultName(String workspaceId) {
    switch (workspaceId) {
      case '1':
        return 'Workspace Principal';
      case '2':
        return 'Workspace Secundário';
      case '3':
        return 'Workspace Auxiliar';
      default:
        return 'Workspace $workspaceId';
    }
  }

  // Método para obter cor baseada no ID
  static String getDefaultColor(String workspaceId) {
    switch (workspaceId) {
      case '1':
        return '#FF6B35';
      case '2':
        return '#2196F3';
      case '3':
        return '#4CAF50';
      default:
        return '#FF6B35';
    }
  }
}
