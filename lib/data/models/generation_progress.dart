class GenerationProgress {
  final int progress;
  final int generatedBlocks;
  final int wordCount;
  final String currentPhase;
  final List<String> logs;

  GenerationProgress({
    required this.progress,
    required this.generatedBlocks,
    required this.wordCount,
    required this.currentPhase,
    required this.logs,
  });
}
