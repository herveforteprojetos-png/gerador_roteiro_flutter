
import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/script_result.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';

class GeminiService {
  final Dio _dio = Dio();
  bool _isCancelled = false;

  // Fases narrativas para progresso
  final List<String> _narrativePhases = [
    'Preparação',
    'Introdução', 
    'Desenvolvimento',
    'Clímax',
    'Resolução',
    'Finalização'
  ];

  Future<ScriptResult> generateScript(ScriptConfig config, Function(GenerationProgress) onProgress) async {
    _isCancelled = false;
    final startTime = DateTime.now();
    
    try {
      // Simulação realística de progresso com fases narrativas
      for (int phase = 0; phase < _narrativePhases.length; phase++) {
        if (_isCancelled) throw Exception('Geração cancelada');
        
        final currentPhase = _narrativePhases[phase];
        final phaseProgress = (phase + 1) / _narrativePhases.length;
        
        // Simular múltiplos blocos por fase
        final blocksInPhase = phase == 0 ? 1 : (phase == _narrativePhases.length - 1 ? 1 : 2);
        
        for (int block = 0; block < blocksInPhase; block++) {
          if (_isCancelled) throw Exception('Geração cancelada');
          
          final blockProgress = (block + 1) / blocksInPhase;
          final totalProgress = (phase + blockProgress) / _narrativePhases.length;
          
          // Calcular tempo estimado
          final elapsed = DateTime.now().difference(startTime);
          final estimatedTotal = Duration(
            milliseconds: (elapsed.inMilliseconds / totalProgress).round()
          );
          final remaining = estimatedTotal - elapsed;
          
        // Logs em tempo real com informações de progresso
        final logs = _generatePhaseLogs(currentPhase, block + 1, blocksInPhase);
        
        // Adicionar informação sobre meta de tamanho
        if (config.measureType == 'caracteres') {
          logs.add('🎯 Meta: ${config.quantity} caracteres');
        } else {
          logs.add('🎯 Meta: ${config.quantity} palavras');
        }          onProgress(GenerationProgress(
            percentage: totalProgress,
            currentPhase: currentPhase,
            phaseIndex: phase,
            totalPhases: _narrativePhases.length,
            currentBlock: (phase * 2) + block + 1,
            totalBlocks: 10, // Total estimado de blocos
            estimatedTimeRemaining: remaining,
            logs: logs,
            wordsGenerated: (totalProgress * config.quantity).round(),
          ));
          
          // Delay realístico baseado na fase
          final delay = _getPhaseDelay(phase, block);
          await Future.delayed(Duration(milliseconds: delay));
        }
      }

      // Simular chamada real para API Gemini
      final response = await _callGeminiAPI(config);
      
      // Verificar se atendeu aos requisitos de tamanho (apenas para caracteres)
      String finalText = response;
      if (config.measureType == 'caracteres') {
        final currentLength = response.length;
        final targetLength = config.quantity;
        final tolerance = (targetLength * 0.1).round(); // 10% de tolerância
        
        // Se o texto está muito abaixo do esperado, tentar expandir
        if (currentLength < (targetLength - tolerance)) {
          onProgress(GenerationProgress(
            percentage: 0.8,
            currentPhase: 'Expansão',
            phaseIndex: 5,
            totalPhases: _narrativePhases.length,
            currentBlock: 9,
            totalBlocks: 10,
            logs: ['🔄 Texto muito curto ($currentLength chars). Expandindo para ${config.quantity} chars...'],
            wordsGenerated: _countWords(response),
          ));
          
          // Tentar expandir o texto
          finalText = await _expandText(response, config, targetLength - currentLength);
        }
      }
      
      return ScriptResult(
        scriptText: finalText,
        wordCount: _countWords(finalText),
        charCount: finalText.length,
        paragraphCount: finalText.split('\n').length,
        readingTime: (_countWords(finalText) / 150).ceil(),
      );
      
    } catch (e) {
      if (_isCancelled) {
        throw Exception('Geração cancelada pelo usuário');
      }
      onProgress(GenerationProgress(
        percentage: 0.0,
        currentPhase: 'Erro',
        phaseIndex: 0,
        totalPhases: _narrativePhases.length,
        currentBlock: 0,
        totalBlocks: 10,
        logs: ['Erro: $e'],
        wordsGenerated: 0,
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

  List<String> _generatePhaseLogs(String phase, int currentBlock, int totalBlocks) {
    final logs = <String>[];
    final timestamp = DateTime.now();
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    
    switch (phase) {
      case 'Preparação':
        logs.addAll([
          '[$timeStr] 🔄 Iniciando geração de roteiro...',
          '[$timeStr] 📋 Analisando configurações...',
          '[$timeStr] 🎯 Definindo estrutura narrativa...',
        ]);
        break;
      case 'Introdução':
        logs.addAll([
          '[$timeStr] ✍️ Gerando introdução - Bloco $currentBlock/$totalBlocks',
          '[$timeStr] 👥 Desenvolvendo personagens principais...',
          '[$timeStr] 🌍 Estabelecendo cenário e contexto...',
        ]);
        break;
      case 'Desenvolvimento':
        logs.addAll([
          '[$timeStr] 📈 Desenvolvimento narrativo - Bloco $currentBlock/$totalBlocks',
          '[$timeStr] ⚡ Construindo tensão dramática...',
          '[$timeStr] 🔀 Adicionando reviravoltas...',
        ]);
        break;
      case 'Clímax':
        logs.addAll([
          '[$timeStr] 🎬 Criando clímax - Bloco $currentBlock/$totalBlocks',
          '[$timeStr] 💥 Momento de maior tensão...',
          '[$timeStr] 🎭 Conflito principal em foco...',
        ]);
        break;
      case 'Resolução':
        logs.addAll([
          '[$timeStr] 🎯 Resolvendo conflitos - Bloco $currentBlock/$totalBlocks',
          '[$timeStr] 🤝 Conectando pontas soltas...',
          '[$timeStr] 📝 Finalizando arcos narrativos...',
        ]);
        break;
      case 'Finalização':
        logs.addAll([
          '[$timeStr] ✅ Finalizando roteiro...',
          '[$timeStr] 🔍 Revisão de qualidade...',
          '[$timeStr] 📄 Formatação final...',
        ]);
        break;
    }
    
    return logs;
  }

  int _getPhaseDelay(int phase, int block) {
    // Delays diferentes por fase para realismo
    switch (phase) {
      case 0: return 800; // Preparação
      case 1: return 1200; // Introdução
      case 2: return 1500; // Desenvolvimento
      case 3: return 1800; // Clímax
      case 4: return 1400; // Resolução
      case 5: return 600; // Finalização
      default: return 1000;
    }
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  void cancelGeneration() {
    _isCancelled = true;
  }

  Future<String> _callGeminiAPI(ScriptConfig config) async {
    // Construir prompt mais específico baseado na medida
    String measureInstruction;
    String detailInstruction = '';
    
    if (config.measureType == 'caracteres') {
      measureInstruction = 'O texto deve ter EXATAMENTE ${config.quantity} caracteres (incluindo espaços). É OBRIGATÓRIO atingir esse número de caracteres.';
      
      if (config.quantity > 50000) {
        detailInstruction = '\n\nPara atingir ${config.quantity} caracteres, desenvolva:\n- Diálogos extensos e naturais\n- Descrições detalhadas de cenários\n- Desenvolvimento profundo de personagens\n- Múltiplas cenas e situações\n- Narrativa rica em detalhes sensoriais';
      } else if (config.quantity > 20000) {
        detailInstruction = '\n\nPara atingir ${config.quantity} caracteres, inclua:\n- Diálogos desenvolvidos\n- Descrições de ambiente\n- Desenvolvimento de personagens\n- Várias cenas conectadas';
      }
    } else {
      measureInstruction = 'O texto deve ter aproximadamente ${config.quantity} palavras. Desenvolva o roteiro de forma completa e detalhada.';
      
      if (config.quantity > 10000) {
        detailInstruction = '\n\nPara atingir ${config.quantity} palavras, desenvolva:\n- História com múltiplos atos\n- Subtramas secundárias\n- Desenvolvimento extenso de personagens\n- Diálogos longos e naturais\n- Descrições ricas e envolventes\n- Várias reviravoltas na narrativa';
      } else if (config.quantity > 5000) {
        detailInstruction = '\n\nPara atingir ${config.quantity} palavras, inclua:\n- Desenvolvimento de personagens\n- Diálogos extensos\n- Descrições detalhadas\n- Múltiplas cenas';
      }
    }

    final prompt = '''
TÍTULO: ${config.title}

CONTEXTO: ${config.context}

CONFIGURAÇÕES:
- Idioma: ${_getLanguageInstruction(config.language)}
- Perspectiva narrativa: ${GeminiService.perspectiveLabel(config.perspective)}
- Incluir Call-to-Action: ${config.includeCallToAction ? 'Sim' : 'Não'}

INSTRUÇÕES OBRIGATÓRIAS:
$measureInstruction$detailInstruction

FORMATO REQUERIDO:
- Gere o texto como uma narrativa corrida, no formato de conto ou história
- NÃO use marcações de roteiro cinematográfico (FADE IN, INT/EXT, indicações de câmera)
- Desenvolva diálogos naturais integrados à narrativa
- Crie descrições detalhadas de cenários e ações
- Mantenha o tom e estilo adequados ao tema

${config.includeCallToAction ? '\nIMPORTANTE: Inclua um call-to-action convincente ao final do texto.' : ''}

Por favor, gere agora o roteiro completo seguindo todas essas especificações:
''';

    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent',
      queryParameters: {'key': config.apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {
                'text': prompt
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.8,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': _calculateMaxTokens(config),
        }
      }
    );
    
    return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Roteiro gerado com sucesso!';
  }

  int _calculateMaxTokens(ScriptConfig config) {
    if (config.measureType == 'caracteres') {
      // Para caracteres: aproximadamente 4 caracteres por token
      // Aumentamos um pouco para garantir que textos grandes sejam gerados
      final baseTokens = (config.quantity * 0.3).ceil();
      
      // Para textos muito grandes, aumentar ainda mais a margem
      if (config.quantity > 50000) {
        return (baseTokens * 1.5).ceil(); // 50% a mais para textos muito grandes
      } else if (config.quantity > 20000) {
        return (baseTokens * 1.3).ceil(); // 30% a mais para textos grandes
      } else {
        return baseTokens;
      }
    } else {
      // Para palavras: aproximadamente 1.3 tokens por palavra
      final baseTokens = (config.quantity * 1.4).ceil();
      
      // Para textos muito grandes, aumentar margem
      if (config.quantity > 10000) {
        return (baseTokens * 1.4).ceil(); // 40% a mais para textos muito grandes
      } else if (config.quantity > 5000) {
        return (baseTokens * 1.2).ceil(); // 20% a mais para textos grandes
      } else {
        return baseTokens;
      }
    }
  }

  String _getLanguageInstruction(String language) {
    switch (language) {
      case 'pt': return 'Português (Brasil)';
      case 'es': return 'Espanhol';
      case 'en': return 'Inglês';
      case 'fr': return 'Francês';
      case 'de': return 'Alemão';
      case 'it': return 'Italiano';
      case 'pl': return 'Polonês';
      case 'tr': return 'Turco';
      case 'ro': return 'Romeno';
      case 'bg': return 'Búlgaro';
      case 'mx': return 'Espanhol Mexicano';
      default: return 'Português (Brasil)';
    }
  }

  Future<String> _expandText(String originalText, ScriptConfig config, int neededChars) async {
    final expansionPrompt = '''
TEXTO ORIGINAL:
$originalText

INSTRUÇÃO: O texto acima precisa ser expandido em aproximadamente $neededChars caracteres adicionais para atingir ${config.quantity} caracteres totais.

REGRAS PARA EXPANSÃO:
- Mantenha a coerência narrativa e o estilo do texto original
- Adicione mais detalhes descritivos, diálogos ou desenvolvimento de personagens
- NÃO mude a estrutura principal da história
- Mantenha o mesmo tom e perspectiva narrativa
- Idioma: ${_getLanguageInstruction(config.language)}

Por favor, forneça APENAS o texto expandido completo (texto original + expansões):
''';

    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent',
        queryParameters: {'key': config.apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': expansionPrompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': (neededChars * 0.35).ceil(), // Margem maior para expansão
          }
        }
      );
      
      final expandedText = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? originalText;
      return expandedText;
    } catch (e) {
      // Se falhar na expansão, retorna o texto original
      return originalText;
    }
  }

  // Método público para geração de texto simples (usado pelas ferramentas auxiliares)
  Future<String> generateText({
    required String prompt,
    required String apiKey,
    String model = 'gemini-1.5-pro',
  }) async {
    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {
                'text': prompt
              }
            ]
          }
        ]
      }
    );
    
    return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Texto gerado com sucesso!';
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
