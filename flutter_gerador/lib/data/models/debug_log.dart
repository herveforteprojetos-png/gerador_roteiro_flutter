import 'package:flutter/foundation.dart';

/// 🔍 Tipos de logs para debug visual
enum DebugLogType {
  info,      // Informações gerais
  success,   // Operação bem-sucedida
  warning,   // Alerta/atenção
  error,     // Erro crítico
  character, // Log relacionado a personagens
  block,     // Log de blocos de geração
  validation // Log de validações
}

/// 📝 Classe para representar um log de debug
class DebugLog {
  final DateTime timestamp;
  final DebugLogType type;
  final String message;
  final String? details;
  final int? blockNumber;
  final String? characterName;
  final Map<String, dynamic>? metadata;
  
  DebugLog({
    required this.type,
    required this.message,
    this.details,
    this.blockNumber,
    this.characterName,
    this.metadata,
  }) : timestamp = DateTime.now();
  
  /// Obtém o ícone correspondente ao tipo de log
  String get icon {
    switch (type) {
      case DebugLogType.info:
        return '🔵';
      case DebugLogType.success:
        return '✅';
      case DebugLogType.warning:
        return '⚠️';
      case DebugLogType.error:
        return '🚨';
      case DebugLogType.character:
        return '👤';
      case DebugLogType.block:
        return '📝';
      case DebugLogType.validation:
        return '🔍';
    }
  }
  
  /// Obtém a cor correspondente ao tipo de log (em string para facilitar)
  String get colorName {
    switch (type) {
      case DebugLogType.info:
        return 'blue';
      case DebugLogType.success:
        return 'green';
      case DebugLogType.warning:
        return 'orange';
      case DebugLogType.error:
        return 'red';
      case DebugLogType.character:
        return 'purple';
      case DebugLogType.block:
        return 'teal';
      case DebugLogType.validation:
        return 'cyan';
    }
  }
  
  /// Formata o log para exibição no console
  String toConsoleString() {
    final buffer = StringBuffer();
    buffer.write('$icon [${timestamp.toString().substring(11, 19)}]');
    
    if (blockNumber != null) {
      buffer.write(' [Bloco $blockNumber]');
    }
    
    if (characterName != null) {
      buffer.write(' [$characterName]');
    }
    
    buffer.write(' $message');
    
    if (details != null && details!.isNotEmpty) {
      buffer.write('\n   → $details');
    }
    
    if (metadata != null && metadata!.isNotEmpty) {
      buffer.write('\n   📊 ${metadata!.entries.map((e) => '${e.key}: ${e.value}').join(', ')}');
    }
    
    return buffer.toString();
  }
  
  /// Converte para JSON para armazenamento
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'message': message,
      'details': details,
      'blockNumber': blockNumber,
      'characterName': characterName,
      'metadata': metadata,
    };
  }
  
  /// Cria um log a partir de JSON
  factory DebugLog.fromJson(Map<String, dynamic> json) {
    return DebugLog(
      type: DebugLogType.values.firstWhere((e) => e.name == json['type']),
      message: json['message'],
      details: json['details'],
      blockNumber: json['blockNumber'],
      characterName: json['characterName'],
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

/// 🎯 Gerenciador central de logs de debug
class DebugLogManager {
  static final DebugLogManager _instance = DebugLogManager._internal();
  factory DebugLogManager() => _instance;
  DebugLogManager._internal();
  
  final List<DebugLog> _logs = [];
  final StreamController<DebugLog> _logController = StreamController<DebugLog>.broadcast();
  
  bool _isEnabled = kDebugMode; // Por padrão, ativo apenas em debug mode
  
  /// Stream de logs para interface em tempo real
  Stream<DebugLog> get logStream => _logController.stream;
  
  /// Lista completa de logs
  List<DebugLog> get logs => List.unmodifiable(_logs);
  
  /// Habilita/desabilita o sistema de logs
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  bool get isEnabled => _isEnabled;
  
  /// Adiciona um log
  void addLog(DebugLog log) {
    if (!_isEnabled) return;
    
    _logs.add(log);
    _logController.add(log);
    
    // Também imprime no console do Flutter
    if (kDebugMode) {
      debugPrint(log.toConsoleString());
    }
    
    // Limita o tamanho da lista para não consumir muita memória
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }
  }
  
  /// Limpa todos os logs
  void clear() {
    _logs.clear();
  }
  
  /// Obtém logs de um bloco específico
  List<DebugLog> getLogsForBlock(int blockNumber) {
    return _logs.where((log) => log.blockNumber == blockNumber).toList();
  }
  
  /// Obtém logs de um personagem específico
  List<DebugLog> getLogsForCharacter(String characterName) {
    return _logs.where((log) => log.characterName == characterName).toList();
  }
  
  /// Obtém logs por tipo
  List<DebugLog> getLogsByType(DebugLogType type) {
    return _logs.where((log) => log.type == type).toList();
  }
  
  /// Obtém estatísticas dos logs
  Map<String, int> getStats() {
    return {
      'total': _logs.length,
      'info': getLogsByType(DebugLogType.info).length,
      'success': getLogsByType(DebugLogType.success).length,
      'warning': getLogsByType(DebugLogType.warning).length,
      'error': getLogsByType(DebugLogType.error).length,
      'character': getLogsByType(DebugLogType.character).length,
      'block': getLogsByType(DebugLogType.block).length,
      'validation': getLogsByType(DebugLogType.validation).length,
    };
  }
  
  /// Exporta logs para texto
  String exportToText() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('    🔍 DEBUG LOG EXPORT');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('Data: ${DateTime.now()}');
    buffer.writeln('Total de logs: ${_logs.length}');
    buffer.writeln('═══════════════════════════════════════\n');
    
    for (final log in _logs) {
      buffer.writeln(log.toConsoleString());
      buffer.writeln('---');
    }
    
    buffer.writeln('\n═══════════════════════════════════════');
    buffer.writeln('    📊 ESTATÍSTICAS');
    buffer.writeln('═══════════════════════════════════════');
    
    final stats = getStats();
    stats.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    
    return buffer.toString();
  }
  
  /// Fecha o stream
  void dispose() {
    _logController.close();
  }
}

/// 🎨 Helper functions para criar logs facilmente
extension DebugLogHelper on DebugLogManager {
  void info(String message, {String? details, int? blockNumber, Map<String, dynamic>? metadata}) {
    addLog(DebugLog(
      type: DebugLogType.info,
      message: message,
      details: details,
      blockNumber: blockNumber,
      metadata: metadata,
    ));
  }
  
  void success(String message, {String? details, int? blockNumber, Map<String, dynamic>? metadata}) {
    addLog(DebugLog(
      type: DebugLogType.success,
      message: message,
      details: details,
      blockNumber: blockNumber,
      metadata: metadata,
    ));
  }
  
  void warning(String message, {String? details, int? blockNumber, Map<String, dynamic>? metadata}) {
    addLog(DebugLog(
      type: DebugLogType.warning,
      message: message,
      details: details,
      blockNumber: blockNumber,
      metadata: metadata,
    ));
  }
  
  void error(String message, {String? details, int? blockNumber, Map<String, dynamic>? metadata}) {
    addLog(DebugLog(
      type: DebugLogType.error,
      message: message,
      details: details,
      blockNumber: blockNumber,
      metadata: metadata,
    ));
  }
  
  void character(String characterName, String message, {String? details, int? blockNumber, Map<String, dynamic>? metadata}) {
    addLog(DebugLog(
      type: DebugLogType.character,
      message: message,
      details: details,
      blockNumber: blockNumber,
      characterName: characterName,
      metadata: metadata,
    ));
  }
  
  void block(int blockNumber, String message, {String? details, Map<String, dynamic>? metadata}) {
    addLog(DebugLog(
      type: DebugLogType.block,
      message: message,
      details: details,
      blockNumber: blockNumber,
      metadata: metadata,
    ));
  }
  
  void validation(String message, {String? details, int? blockNumber, Map<String, dynamic>? metadata}) {
    addLog(DebugLog(
      type: DebugLogType.validation,
      message: message,
      details: details,
      blockNumber: blockNumber,
      metadata: metadata,
    ));
  }
}
