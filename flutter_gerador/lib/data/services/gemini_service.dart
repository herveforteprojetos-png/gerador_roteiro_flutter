
import 'package:dio/dio.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/script_result.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';

class GeminiService {
  final Dio _dio = Dio();

  Future<ScriptResult> generateScript(ScriptConfig config, Function(GenerationProgress) onProgress) async {
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent',
        queryParameters: {'key': config.apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': '${config.title}\n${config.context}\nMedida: ${config.measureType}\nQtd: ${config.quantity}\nIdioma: ${config.language}\nPerspectiva: ${GeminiService.perspectiveLabel(config.perspective)}\nCTA: ${config.includeCallToAction}\n\nIMPORTANTE: Gere o texto como uma narrativa corrida, no formato de conto ou história, sem marcações de roteiro cinematográfico (não use FADE IN, INT/EXT, indicações de câmera ou montagem).'
                }
              ]
            }
          ]
        }
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

  static String perspectiveLabel(String value) {
    switch (value) {
      case 'terceira':
        return 'Terceira Pessoa';
      case 'primeira_homem_idoso':
        return 'Primeira pessoa Homem idoso';
      case 'primeira_homem_jovem':
        return 'Primeira pessoa Homem Jovem de 25 a 40';
      case 'primeira_mulher_idosa':
        return 'Primeira pessoa Mulher Idosa';
      case 'primeira_mulher_jovem':
        return 'Primeira pessoa Mulher jovem de 25 a 40';
      default:
        return 'Terceira Pessoa';
    }
  }
}
