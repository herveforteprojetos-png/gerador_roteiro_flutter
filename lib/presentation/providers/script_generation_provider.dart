import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/generation_progress.dart';
import '../../data/models/script_result.dart';
import '../../data/services/gemini_service.dart';

class ScriptGenerationState {
  final bool isGenerating;
  final GenerationProgress? progress;
  final ScriptResult? result;

  ScriptGenerationState({
    this.isGenerating = false,
    this.progress,
    this.result,
  });
}


class ScriptGenerationNotifier extends StateNotifier<ScriptGenerationState> {
  final GeminiService geminiService;
  bool _cancelRequested = false;

  ScriptGenerationNotifier(this.geminiService) : super(ScriptGenerationState());

  Future<void> generateScript(ScriptConfig config) async {
    state = ScriptGenerationState(isGenerating: true);
    _cancelRequested = false;
    final result = await geminiService.generateScript(config, (progress) {
      if (_cancelRequested) return;
      state = ScriptGenerationState(
        isGenerating: true,
        progress: progress,
      );
    });
    if (!_cancelRequested) {
      state = ScriptGenerationState(
        isGenerating: false,
        result: result,
      );
    }
  }

  void cancelGeneration() {
    _cancelRequested = true;
    state = ScriptGenerationState(isGenerating: false);
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final scriptGenerationProvider = StateNotifierProvider<ScriptGenerationNotifier, ScriptGenerationState>((ref) {
  return ScriptGenerationNotifier(ref.watch(geminiServiceProvider));
});
