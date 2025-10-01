import '../../data/models/generation_config.dart';

class WorkspaceSession {
  final String id;
  final String name;
  final GenerationConfig config;
  final DateTime createdAt;
  final DateTime lastUsed;

  WorkspaceSession({
    required this.id,
    required this.name,
    required this.config,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    lastUsed = lastUsed ?? DateTime.now();

  WorkspaceSession copyWith({
    String? id,
    String? name,
    GenerationConfig? config,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return WorkspaceSession(
      id: id ?? this.id,
      name: name ?? this.name,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'config': config.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory WorkspaceSession.fromJson(Map<String, dynamic> json) {
    return WorkspaceSession(
      id: json['id'],
      name: json['name'],
      config: GenerationConfig.fromJson(json['config']),
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: DateTime.parse(json['lastUsed']),
    );
  }

  // Status indicators
  bool get hasApiKey => config.apiKey.isNotEmpty;
  bool get hasTitle => config.title.isNotEmpty;
  bool get hasContext => config.context.isNotEmpty;
  bool get isConfigured => hasApiKey && hasTitle && hasContext;
  
  String get statusIcon {
    if (isConfigured) return '✅';
    if (hasApiKey) return '🔑';
    return '⚠️';
  }
  
  String get statusText {
    if (isConfigured) return 'Configurado';
    if (hasApiKey) return 'Chave API definida';
    return 'Não configurado';
  }
}
