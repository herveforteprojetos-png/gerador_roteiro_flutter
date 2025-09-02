
import 'package:dio/dio.dart';

class GeminiService {
  final Dio _dio = Dio();

  Future<ScriptResult> generateScript(ScriptConfig config, Function(GenerationProgress) onProgress) async {
    try {
      // Exemplo de chamada Gemini (ajuste endpoint/model conforme necessário)
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent',
        queryParameters: {'key': config.apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': '${config.title}\n${config.context}\nMedida: ${config.measureType}\nQtd: ${config.quantity}\nIdioma: ${config.language}\nCTA: ${config.includeCallToAction}'}
              ]
            }
          ]
        },
      );
      // Simula progresso
      for (int i = 0; i <= 100; i += 20) {
        await Future.delayed(const Duration(milliseconds: 200));
        onProgress(GenerationProgress(
          progress: i,
          generatedBlocks: i ~/ 20,
          wordCount: i * 10,
          currentPhase: 'Fase $i',
          logs: ['Progresso: $i%'],
        ));
      }
      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Roteiro gerado...';
      // Métricas simuladas
      return ScriptResult(
        scriptText: text,
        wordCount: text.split(' ').length,
        charCount: text.length,
        paragraphCount: text.split('\n').length,
        readingTime: (text.split(' ').length / 150).ceil(),
      );
    } catch (e) {
      onProgress(GenerationProgress(
        progress: 0,
        generatedBlocks: 0,
        wordCount: 0,
        currentPhase: 'Erro',
        logs: ['Erro: $e'],
      ));
      return ScriptResult(
        scriptText: 'Erro ao gerar roteiro: $e',
        wordCount: 0,
        charCount: 0,
        paragraphCount: 0,
        readingTime: 0,
      );
    }
  }
}
