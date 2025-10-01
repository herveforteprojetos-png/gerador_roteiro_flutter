import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/generation_config.dart';

class ScriptGenerationStateMulti {
  final Map<String, bool> isGeneratingBySession;
  final Map<String, GenerationResult?> resultsBySession;
  final Map<String, String?> errorsBySession;

  const ScriptGenerationStateMulti({
    this.isGeneratingBySession = const {},
    this.resultsBySession = const {},
    this.errorsBySession = const {},
  });

  bool isGenerating(String sessionId) => isGeneratingBySession[sessionId] ?? false;
  GenerationResult? getResult(String sessionId) => resultsBySession[sessionId];
  String? getError(String sessionId) => errorsBySession[sessionId];

  ScriptGenerationStateMulti copyWith({
    Map<String, bool>? isGeneratingBySession,
    Map<String, GenerationResult?>? resultsBySession,
    Map<String, String?>? errorsBySession,
  }) {
    return ScriptGenerationStateMulti(
      isGeneratingBySession: isGeneratingBySession ?? this.isGeneratingBySession,
      resultsBySession: resultsBySession ?? this.resultsBySession,
      errorsBySession: errorsBySession ?? this.errorsBySession,
    );
  }

  ScriptGenerationStateMulti setGenerating(String sessionId, bool generating) {
    final newGenerating = Map<String, bool>.from(isGeneratingBySession);
    newGenerating[sessionId] = generating;
    return copyWith(isGeneratingBySession: newGenerating);
  }

  ScriptGenerationStateMulti setResult(String sessionId, GenerationResult result) {
    final newResults = Map<String, GenerationResult?>.from(resultsBySession);
    final newErrors = Map<String, String?>.from(errorsBySession);
    
    newResults[sessionId] = result;
    newErrors.remove(sessionId); // Remove error if exists
    
    return copyWith(
      resultsBySession: newResults,
      errorsBySession: newErrors,
    );
  }

  ScriptGenerationStateMulti setError(String sessionId, String error) {
    final newErrors = Map<String, String?>.from(errorsBySession);
    final newResults = Map<String, GenerationResult?>.from(resultsBySession);
    
    newErrors[sessionId] = error;
    newResults.remove(sessionId); // Remove result if exists
    
    return copyWith(
      errorsBySession: newErrors,
      resultsBySession: newResults,
    );
  }

  ScriptGenerationStateMulti clearSession(String sessionId) {
    final newGenerating = Map<String, bool>.from(isGeneratingBySession);
    final newResults = Map<String, GenerationResult?>.from(resultsBySession);
    final newErrors = Map<String, String?>.from(errorsBySession);
    
    newGenerating.remove(sessionId);
    newResults.remove(sessionId);
    newErrors.remove(sessionId);
    
    return copyWith(
      isGeneratingBySession: newGenerating,
      resultsBySession: newResults,
      errorsBySession: newErrors,
    );
  }
}

class GenerationResult {
  final bool success;
  final String? scriptText;
  final String? errorMessage;
  final DateTime timestamp;

  const GenerationResult({
    required this.success,
    this.scriptText,
    this.errorMessage,
    required this.timestamp,
  });

  GenerationResult.success(String scriptText)
      : success = true,
        scriptText = scriptText,
        errorMessage = null,
        timestamp = DateTime.now();

  GenerationResult.error(String errorMessage)
      : success = false,
        scriptText = null,
        errorMessage = errorMessage,
        timestamp = DateTime.now();
}

final scriptGenerationMultiProvider = StateNotifierProvider<ScriptGenerationMultiNotifier, ScriptGenerationStateMulti>((ref) {
  return ScriptGenerationMultiNotifier();
});

class ScriptGenerationMultiNotifier extends StateNotifier<ScriptGenerationStateMulti> {
  ScriptGenerationMultiNotifier() : super(const ScriptGenerationStateMulti());

  Future<void> generateScript(String sessionId, GenerationConfig config) async {
    try {
      // Marcar como gerando
      state = state.setGenerating(sessionId, true);

      // Simular geração de script (implementar com service real)
      await Future.delayed(const Duration(seconds: 3));

      // Simular resultado (substituir por service real)
      final mockScript = '''
# ${config.title}

## Contexto
${config.context}

## Roteiro

FADE IN:

EXT. CENÁRIO INICIAL - DIA

(Descrição do cenário baseada no contexto fornecido)

Personagem principal aparece em cena...

[Diálogo baseado no contexto: ${config.context.split(' ').take(10).join(' ')}...]

FADE OUT.

FIM

---
Gerado com modelo: ${config.model}
Timestamp: ${DateTime.now().toIso8601String()}
      ''';

      final result = GenerationResult.success(mockScript);
      state = state.setGenerating(sessionId, false).setResult(sessionId, result);
      
    } catch (e) {
      state = state.setGenerating(sessionId, false).setError(sessionId, 'Erro na geração: $e');
    }
  }

  void clearResult(String sessionId) {
    state = state.clearSession(sessionId);
  }

  void stopGeneration(String sessionId) {
    state = state.setGenerating(sessionId, false);
  }
}
