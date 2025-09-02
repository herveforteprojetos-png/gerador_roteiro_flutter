import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/script_result.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';
import 'package:flutter_gerador/data/services/gemini_service.dart';

class ScriptRepository {
  final GeminiService geminiService;

  ScriptRepository(this.geminiService);

  Future<ScriptResult> generateScript(ScriptConfig config, Function(GenerationProgress) onProgress) async {
    // Chama o serviço Gemini e retorna o resultado
    return await geminiService.generateScript(config, onProgress);
  }
}
