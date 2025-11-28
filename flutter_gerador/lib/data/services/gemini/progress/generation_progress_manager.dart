import 'package:flutter_gerador/data/models/debug_log.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';

/// 📊 Gerenciador de progresso de geração
/// Wrapper para o DebugLogManager existente com funcionalidades extras
class GenerationProgressManager {
  final DebugLogManager _debugLogger;
  final List<GenerationProgress> _progressHistory = [];

  GenerationProgressManager() : _debugLogger = DebugLogManager();

  /// Registra progresso de um bloco
  void recordProgress(GenerationProgress progress) {
    _progressHistory.add(progress);

    // Log no debug logger
    _debugLogger.block(
      progress.currentBlock,
      'Progresso: ${(progress.percentage * 100).toStringAsFixed(1)}%',
      metadata: {
        'fase': progress.currentPhase,
        'fasesTotal': progress.totalPhases,
        'palavras': progress.wordsGenerated,
      },
    );
  }

  /// Registra bloco concluído com sucesso
  void blockCompleted(int blockNumber, int wordsGenerated, int totalContext) {
    _debugLogger.success(
      "Bloco $blockNumber completado",
      details: "Tamanho: $wordsGenerated palavras",
      metadata: {
        'bloco': blockNumber,
        'palavrasNoBloco': wordsGenerated,
        'contextoTotal': totalContext,
      },
    );
  }

  /// Registra início de bloco
  void blockStarted(
    int blockNumber,
    String details, {
    Map<String, dynamic>? metadata,
  }) {
    _debugLogger.block(blockNumber, "Iniciando geração", metadata: metadata);
  }

  /// Registra aviso
  void warning(
    String message, {
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    _debugLogger.warning(message, details: details, metadata: metadata);
  }

  /// Registra erro
  void error(
    String message, {
    int? blockNumber,
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    _debugLogger.error(
      message,
      blockNumber: blockNumber,
      details: details,
      metadata: metadata,
    );
  }

  /// Registra validação
  void validation(
    String message, {
    int? blockNumber,
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    _debugLogger.validation(
      message,
      blockNumber: blockNumber,
      details: details,
      metadata: metadata,
    );
  }

  /// Registra personagem detectado
  void character(
    String name,
    String details, {
    int? blockNumber,
    Map<String, dynamic>? metadata,
  }) {
    _debugLogger.character(
      name,
      details,
      blockNumber: blockNumber,
      metadata: metadata,
    );
  }

  /// Registra sucesso final
  void success(
    String message, {
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    _debugLogger.success(message, details: details, metadata: metadata);
  }

  /// Obtém estatísticas dos logs
  Map<String, int> getStatistics() => _debugLogger.getStatistics();

  /// Obtém histórico de progresso
  List<GenerationProgress> get progressHistory =>
      List.unmodifiable(_progressHistory);

  /// Obtém último progresso registrado
  GenerationProgress? get lastProgress =>
      _progressHistory.isNotEmpty ? _progressHistory.last : null;

  /// Limpa histórico de progresso
  void clearHistory() {
    _progressHistory.clear();
  }

  /// Acesso direto ao debug logger (para compatibilidade)
  DebugLogManager get debugLogger => _debugLogger;
}
