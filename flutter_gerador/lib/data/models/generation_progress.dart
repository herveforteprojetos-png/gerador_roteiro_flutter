// Modelo de progresso da geração avançado
class GenerationProgress {
  final double percentage; // 0.0 to 1.0
  final String currentPhase;
  final int phaseIndex;
  final int totalPhases;
  final int currentBlock;
  final int totalBlocks;
  final Duration? estimatedTimeRemaining;
  final List<String> logs;
  final int wordsGenerated;

  // Campos legados para compatibilidade
  final int progress;
  final int generatedBlocks;
  final int wordCount;

  GenerationProgress({
    required this.percentage,
    required this.currentPhase,
    required this.phaseIndex,
    required this.totalPhases,
    required this.currentBlock,
    required this.totalBlocks,
    this.estimatedTimeRemaining,
    required this.logs,
    required this.wordsGenerated,
    // Campos legados calculados automaticamente
    int? progress,
    int? generatedBlocks,
    int? wordCount,
  }) : progress = progress ?? (percentage * 100).round(),
       generatedBlocks = generatedBlocks ?? currentBlock,
       wordCount = wordCount ?? wordsGenerated;
}
