// Modelo do resultado do roteiro
class ScriptResult {
  final String scriptText;
  final int wordCount;
  final int charCount;
  final int paragraphCount;
  final int readingTime;
  final bool success;
  final String? errorMessage;
  final String? generationTime;
  final String? model;
  final bool hasCtaIntegration;

  ScriptResult({
    required this.scriptText,
    required this.wordCount,
    required this.charCount,
    required this.paragraphCount,
    required this.readingTime,
    this.success = true,
    this.errorMessage,
    this.generationTime,
    this.model,
    this.hasCtaIntegration = false,
  });

  // Construtor para casos de erro
  ScriptResult.error({
    required String errorMessage,
  }) : scriptText = '',
        wordCount = 0,
        charCount = 0,
        paragraphCount = 0,
        readingTime = 0,
        success = false,
        errorMessage = errorMessage,
        generationTime = null,
        model = null,
        hasCtaIntegration = false;
}
