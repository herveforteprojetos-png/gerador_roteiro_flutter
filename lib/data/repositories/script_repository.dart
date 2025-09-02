import '../models/script_config.dart';
import '../models/script_result.dart';
import '../models/generation_progress.dart';
import '../services/gemini_service.dart';

class ScriptRepository {
  final GeminiService geminiService;

  ScriptRepository(this.geminiService);

  Future<ScriptResult> generateScript(ScriptConfig config, Function(GenerationProgress) onProgress) async {
    // Chama o serviço Gemini e retorna o resultado
    return await geminiService.generateScript(config, onProgress);
  }
}
