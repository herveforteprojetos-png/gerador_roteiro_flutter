
import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/script_result.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';

class GeminiService {
  final Dio _dio = Dio();
  bool _isCancelled = false;
  int _requestCount = 0;
  DateTime _lastRequestTime = DateTime.now();

  // Rate limiting - otimizado para Tier 1 com billing ativado
  static const int _maxRequestsPerMinute = 50; // Tier 1: TPM permite requests rápidos
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  
  // Configurar rate limit baseado no tier
  static int _currentRateLimit = 50; // Padrão otimizado para Tier 1 (billing ativado)
  
  static void setApiTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        _currentRateLimit = 5; // Free tier (sem billing)
        break;
      case 'tier1':
        _currentRateLimit = 200; // Tier 1: Ideal para produção
        break;
      case 'tier2':
        _currentRateLimit = 100; // Tier 2: RPM limitado mas estável
        break;
      case 'tier3':
        _currentRateLimit = 500; // Tier 3: Praticamente sem limite
        break;
      default:
        _currentRateLimit = 50; // Default para usuários com billing
    }
  }

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
      // Calcular número de blocos necessários baseado na meta
      var totalBlocks = _calculateTotalBlocks(config);
      String accumulatedText = '';
      int currentBlock = 0;
      int currentPhaseIndex = 0;
      
      // Sistema de geração contínua com chamadas reais incrementais
      while (currentBlock < totalBlocks && !_isCancelled) {
        currentBlock++;
        
        // Determinar fase atual baseada no progresso
        final phaseProgress = currentBlock / totalBlocks;
        currentPhaseIndex = _getPhaseIndexFromProgress(phaseProgress);
        final currentPhase = _narrativePhases[currentPhaseIndex];
        
        // Calcular progresso e tempo estimado
        final totalProgress = currentBlock / totalBlocks;
        final elapsed = DateTime.now().difference(startTime);
        final estimatedTotal = totalProgress > 0 ? Duration(
          milliseconds: (elapsed.inMilliseconds / totalProgress).round()
        ) : Duration.zero;
        final remaining = estimatedTotal - elapsed;
        
        // Gerar logs detalhados para o bloco atual
        final logs = _generateBlockLogs(currentPhase, currentBlock, totalBlocks, config);
        
        // Calcular palavras/caracteres gerados até agora
        int contentGenerated = 0;
        if (config.measureType == 'caracteres') {
          contentGenerated = accumulatedText.length;
        } else {
          contentGenerated = _countWords(accumulatedText);
        }
        
        // Atualizar progresso
        onProgress(GenerationProgress(
          percentage: totalProgress,
          currentPhase: currentPhase,
          phaseIndex: currentPhaseIndex,
          totalPhases: _narrativePhases.length,
          currentBlock: currentBlock,
          totalBlocks: totalBlocks,
          estimatedTimeRemaining: remaining,
          logs: logs,
          wordsGenerated: contentGenerated,
        ));
        
        // Fazer chamada real para API com mais frequência para garantir volume
        if (currentBlock == 1 || currentBlock % 3 == 0 || currentBlock == totalBlocks) {
          // Calcular quanto texto deve ser gerado neste bloco
          final targetForThisBlock = _calculateTargetForBlock(currentBlock, totalBlocks, config);
          final blockText = await _retryOnRateLimit(() => _generateBlockContent(accumulatedText, targetForThisBlock, currentPhase, config));
          accumulatedText += blockText;
        }
        
        // Delay realístico baseado no bloco
        final delay = _getBlockDelay(currentBlock, totalBlocks);
        await Future.delayed(Duration(milliseconds: delay));
      }
      
      // Verificar se atingiu a meta final e expandir se necessário
      if (!_isCancelled) {
        final targetMet = _checkTargetMet(accumulatedText, config);
        if (!targetMet) {
          // Sistema de expansão mais agressivo para ambos tipos de medida
          int expansionRound = 1;
          while (!_checkTargetMet(accumulatedText, config) && !_isCancelled && expansionRound <= 3) {
            String missingContent;
            if (config.measureType == 'caracteres') {
              final neededChars = config.quantity - accumulatedText.length;
              missingContent = '🎯 Faltam ${neededChars} caracteres para meta';
            } else {
              final currentWords = _countWords(accumulatedText);
              final neededWords = config.quantity - currentWords;
              missingContent = '🎯 Faltam ${neededWords} palavras para meta';
            }
            
            onProgress(GenerationProgress(
              percentage: 0.85 + (expansionRound * 0.05),
              currentPhase: 'Expansão Final',
              phaseIndex: _narrativePhases.length - 1,
              totalPhases: _narrativePhases.length,
              currentBlock: currentBlock + expansionRound,
              totalBlocks: totalBlocks + 3,
              estimatedTimeRemaining: Duration(milliseconds: 1000 * (4 - expansionRound)),
              logs: ['📈 Expandindo narrativa...', missingContent, '✍️ Adicionando conteúdo (Rodada $expansionRound/3)'],
              wordsGenerated: _countWords(accumulatedText),
            ));
            
            // Gerar conteúdo de expansão com target específico para cada tipo
            double targetForExpansion;
            if (config.measureType == 'caracteres') {
              final neededChars = config.quantity - accumulatedText.length;
              targetForExpansion = min(neededChars + 500, (neededChars * 1.2).toInt()).toDouble();
            } else {
              final currentWords = _countWords(accumulatedText);
              final neededWords = config.quantity - currentWords;
              targetForExpansion = min(neededWords + 100, (neededWords * 1.2).toInt()).toDouble();
            }
            
            final expansionContent = await _retryOnRateLimit(() => _generateExpansionContent(accumulatedText, targetForExpansion, config));
            
            if (expansionContent.isNotEmpty) {
              accumulatedText += expansionContent;
            }
            
            await Future.delayed(Duration(milliseconds: 400));
            expansionRound++;
          }
        }
      }
      
      if (_isCancelled) throw Exception('Geração cancelada');
      
      // Verificação final do CTA
      if (config.includeCallToAction) {
        final ctaText = _getCallToActionText(config.language);
        if (!accumulatedText.contains(ctaText)) {
          // Inserir CTA após o primeiro parágrafo
          final lines = accumulatedText.split('\n');
          int firstParagraphEnd = -1;
          
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].trim().isNotEmpty && lines[i].trim().endsWith('.')) {
              firstParagraphEnd = i;
              break;
            }
          }
          
          if (firstParagraphEnd >= 0) {
            lines.insert(firstParagraphEnd + 1, '');
            lines.insert(firstParagraphEnd + 2, ctaText);
            lines.insert(firstParagraphEnd + 3, '');
            accumulatedText = lines.join('\n');
          }
        }
      }
      
      // Resultado final
      return ScriptResult(
        scriptText: accumulatedText,
        wordCount: _countWords(accumulatedText),
        charCount: accumulatedText.length,
        paragraphCount: accumulatedText.split('\n').length,
        readingTime: (_countWords(accumulatedText) / 150).ceil(),
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
        totalBlocks: 1,
        logs: ['❌ Erro: $e'],
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

  // Métodos auxiliares para sistema de geração contínua
  
  int _calculateTotalBlocks(ScriptConfig config) {
    // Calcular blocos baseado na quantidade e tipo
    if (config.measureType == 'caracteres') {
      if (config.quantity <= 5000) return 8;
      if (config.quantity <= 15000) return 12;
      if (config.quantity <= 30000) return 18;
      if (config.quantity <= 50000) return 25;
      if (config.quantity <= 80000) return 35;
      return 45; // Para textos muito grandes (100k+)
    } else {
      // Para palavras
      if (config.quantity <= 1000) return 6;
      if (config.quantity <= 3000) return 10;
      if (config.quantity <= 8000) return 15;
      if (config.quantity <= 15000) return 22;
      if (config.quantity <= 25000) return 30;
      return 40; // Para textos muito grandes
    }
  }
  
  int _getPhaseIndexFromProgress(double progress) {
    // Mapear progresso para índices de fase
    if (progress <= 0.15) return 0; // Preparação
    if (progress <= 0.30) return 1; // Introdução
    if (progress <= 0.65) return 2; // Desenvolvimento
    if (progress <= 0.80) return 3; // Clímax
    if (progress <= 0.95) return 4; // Resolução
    return 5; // Finalização
  }
  
  List<String> _generateBlockLogs(String phase, int currentBlock, int totalBlocks, ScriptConfig config) {
    final logs = <String>[];
    final timestamp = DateTime.now();
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    
    // Log específico da fase
    String phaseAction = '';
    switch (phase) {
      case 'Preparação':
        phaseAction = currentBlock == 1 ? '🔄 Iniciando estrutura narrativa...' : '📋 Configurando parâmetros...';
        break;
      case 'Introdução':
        phaseAction = '✍️ Gerando introdução...';
        break;
      case 'Desenvolvimento':
        phaseAction = '📈 Desenvolvendo narrativa...';
        break;
      case 'Clímax':
        phaseAction = '🎬 Criando momento climático...';
        break;
      case 'Resolução':
        phaseAction = '🎯 Resolvendo conflitos...';
        break;
      case 'Finalização':
        phaseAction = currentBlock == totalBlocks ? '📄 Formatação final...' : '✅ Ajustes finais...';
        break;
    }
    
    logs.addAll([
      '[$timeStr] $phaseAction',
      '[$timeStr] 📊 Bloco $currentBlock/$totalBlocks - Fase: $phase',
      '[$timeStr] 🎯 Meta: ${config.quantity} ${config.measureType}',
    ]);
    
    // Adicionar informação sobre chamadas de API reais
    if (currentBlock == 1 || currentBlock % 5 == 0 || currentBlock == totalBlocks) {
      logs.add('[$timeStr] 🔗 Gerando conteúdo via API...');
    } else {
      logs.add('[$timeStr] ⚡ Processando estrutura...');
    }
    
    // Logs específicos do progresso
    final progressPercent = (currentBlock / totalBlocks * 100).toStringAsFixed(1);
    if (currentBlock <= 3) {
      logs.add('[$timeStr] 🚀 Iniciando ($progressPercent%)...');
    } else if (currentBlock >= totalBlocks - 2) {
      logs.add('[$timeStr] 🏁 Finalizando ($progressPercent%)...');
    } else {
      logs.add('[$timeStr] ⚡ Progresso: $progressPercent%');
    }
    
    return logs;
  }
  
  List<String> _generateExpansionLogs(int currentExpansion, int totalExpansions, int currentChars, int targetChars) {
    final logs = <String>[];
    final timestamp = DateTime.now();
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final needed = targetChars - currentChars;
    final percentage = (currentChars / targetChars * 100).toStringAsFixed(1);
    
    logs.addAll([
      '[$timeStr] 🔄 Expansão $currentExpansion/$totalExpansions',
      '[$timeStr] 📏 Atual: $currentChars chars ($percentage%) | Meta: $targetChars chars',
      '[$timeStr] ➕ Necessário: +$needed caracteres',
      '[$timeStr] 🔗 Expandindo via API Gemini...',
      if (currentExpansion == totalExpansions) '[$timeStr] 🎯 Ajuste final para meta exata...',
    ]);
    
    return logs;
  }
  
  int _getBlockDelay(int currentBlock, int totalBlocks) {
    // Delays otimizados para Gemini 2.5 Pro + Tier 1
    // Opção ULTRA-RÁPIDA (pode sacrificar qualidade)
    final progress = currentBlock / totalBlocks;
    
    if (progress <= 0.15) return 150; // Preparação - mais rápida
    if (progress <= 0.30) return 200; // Introdução - acelerada
    if (progress <= 0.65) return 250; // Desenvolvimento - rápido
    if (progress <= 0.80) return 400; // Clímax - mantém mínimo para qualidade
    if (progress <= 0.95) return 200; // Resolução - rápida
    return 100; // Finalização - ultra-rápida
  }
  
  bool _checkTargetMet(String text, ScriptConfig config) {
    if (config.measureType == 'caracteres') {
      // Reduzir tolerância para garantir que atinja o target exato
      final tolerance = (config.quantity * 0.02).round(); // Apenas 2% de tolerância
      return text.length >= (config.quantity - tolerance);
    } else {
      final wordCount = _countWords(text);
      final tolerance = (config.quantity * 0.05).round(); // 5% de tolerância para palavras
      return wordCount >= (config.quantity - tolerance);
    }
  }
  
  int _calculateExpansionBlocks(String text, ScriptConfig config) {
    if (config.measureType != 'caracteres') return 0;
    
    final currentLength = text.length;
    final needed = config.quantity - currentLength;
    final tolerance = (config.quantity * 0.02).round(); // Usar mesma tolerância de 2%
    
    if (needed <= tolerance) return 0; // Já está próximo o suficiente
    
    // Calcular blocos de expansão baseado no déficit - mais agressivo
    if (needed < 2000) return 2;
    if (needed < 5000) return 3;
    if (needed < 10000) return 4;
    if (needed < 20000) return 5;
    return 6; // Para grandes déficits
  }

  int _calculateTargetForBlock(int currentBlock, int totalBlocks, ScriptConfig config) {
    // Calcular quanto do total deve estar concluído neste bloco
    final progressRatio = currentBlock / totalBlocks;
    return (config.quantity * progressRatio).round();
  }

  Future<String> _generateBlockContent(String previousContent, int targetChars, String phase, ScriptConfig config) async {
    // Calcular quanto texto adicionar baseado no progresso
    final currentLength = previousContent.length;
    final neededForThisBlock = targetChars - currentLength;
    
    if (neededForThisBlock <= 0) return ''; // Já atingiu o necessário para este bloco
    
    String instruction = '';
    if (previousContent.isEmpty) {
      instruction = 'Comece uma nova história';
    } else {
      instruction = 'Continue a história a partir do ponto onde parou';
    }
    
    final blockPrompt = '''
${previousContent.isNotEmpty ? 'TEXTO ANTERIOR:\n$previousContent\n\n' : ''}
INSTRUÇÃO: $instruction sobre "${config.title}".

CONTEXTO: ${config.context}

FASE ATUAL: $phase - Desenvolva esta parte da narrativa.

REQUISITOS OBRIGATÓRIOS:
- GERE EXATAMENTE $neededForThisBlock caracteres ou mais
- Mantenha continuidade narrativa com o texto anterior
- Desenvolva a narrativa adequada à fase atual ($phase)
- Idioma: ${_getLanguageInstruction(config.language)}
- Perspectiva: ${GeminiService.perspectiveLabel(config.perspective)}
${previousContent.isNotEmpty ? '- NÃO repita conteúdo já escrito' : ''}
${previousContent.isEmpty ? '- Comece do início da história' : '- Continue naturalmente onde o texto anterior parou'}
- Se necessário, adicione diálogos, descrições detalhadas e desenvolvimento de personagens para atingir o volume

CONTROLES DE QUALIDADE PARA ESTE BLOCO:
• Mantenha TODOS os nomes de personagens consistentes com o texto anterior
• NÃO repita nenhuma cena ou evento já descrito
• Mantenha continuidade temporal e lógica
• Use exclusivamente português brasileiro
• Se esta é a fase final, finalize a história completamente
• Verifique se não está contradizendo informações anteriores

Gere APENAS o conteúdo adicional (sem repetir texto anterior):
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
                  'text': blockPrompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': (neededForThisBlock * 0.8).ceil(), // Aumentar tokens significativamente
          }
        }
      );
      
      final blockContent = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      return blockContent.isNotEmpty ? '\n$blockContent' : '';
    } catch (e) {
      return ''; // Se falhar, continua sem adicionar conteúdo
    }
  }

  Future<String> _generateExpansionContent(String originalText, double targetAdditionalAmount, ScriptConfig config) async {
    // Verificar se CTA já existe no texto
    final ctaText = _getCallToActionText(config.language);
    final ctaExists = originalText.contains(ctaText);
    
    String ctaInstruction = '';
    if (config.includeCallToAction && !ctaExists) {
      ctaInstruction = '''

🎯 ATENÇÃO - CALL-TO-ACTION OBRIGATÓRIO:
Você DEVE incluir este CTA após o primeiro parágrafo: "$ctaText"
''';
    }
    
    // Personalizar instruções baseado no tipo de medida
    String measureInstruction;
    String currentStats;
    if (config.measureType == 'caracteres') {
      measureInstruction = 'Adicione EXATAMENTE ${targetAdditionalAmount.round()} caracteres ou mais à narrativa acima.';
      currentStats = '${originalText.length} caracteres';
    } else {
      measureInstruction = 'Adicione EXATAMENTE ${targetAdditionalAmount.round()} palavras ou mais à narrativa acima.';
      final currentWords = _countWords(originalText);
      currentStats = '$currentWords palavras';
    }
    
    final expansionPrompt = '''
CONTINUAÇÃO DE NARRATIVA:

TEXTO EXISTENTE ($currentStats):
$originalText

🎯 OBJETIVO: $measureInstruction

📋 INSTRUÇÕES OBRIGATÓRIAS:
1. Continue a história de forma NATURAL e FLUIDA
2. Se o texto terminou no meio de uma cena, COMPLETE ela
3. Se terminou uma cena, INICIE a próxima
4. Adicione mais DIÁLOGOS, DESCRIÇÕES e DESENVOLVIMENTO
5. NÃO repita nenhum conteúdo já escrito
6. MANTENHA o mesmo tom e estilo
7. Se possível, RESOLVA a narrativa adequadamente$ctaInstruction

💡 DICAS PARA EXPANDIR:
- Desenvolva melhor os personagens
- Adicione detalhes de cenário
- Inclua diálogos internos
- Crie tensão adicional
- Desenvolva subtramas

Idioma: ${_getLanguageInstruction(config.language)}

IMPORTANTE: Forneça APENAS o conteúdo adicional que continua diretamente onde o texto parou. NÃO inclua títulos ou quebras artificiais.

CONTEÚDO ADICIONAL:
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
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': (targetAdditionalAmount * 1.0).ceil(), // Aumentar significativamente para expansão
          }
        }
      );
      
      final expansionContent = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      return expansionContent.isNotEmpty ? '\n$expansionContent' : '';
    } catch (e) {
      return '';
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

  int _getPhaseDelayOld(int phase, int block) {
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

  // Rate limiting inteligente
  Future<void> _ensureRateLimit() async {
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(_lastRequestTime);
    
    // Reset counter se passou mais de 1 minuto
    if (timeSinceLastRequest > _rateLimitWindow) {
      _requestCount = 0;
    }
    
    // Se atingiu o limite, aguardar
    if (_requestCount >= _currentRateLimit) {
      final waitTime = _rateLimitWindow - timeSinceLastRequest;
      if (waitTime > Duration.zero) {
        await Future.delayed(waitTime);
        _requestCount = 0;
      }
    }
    
    _requestCount++;
    _lastRequestTime = now;
  }

  // Retry automático para rate limits
  Future<T> _retryOnRateLimit<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await _ensureRateLimit();
        return await operation();
      } catch (e) {
        // Se é erro de rate limit (429) e não é a última tentativa
        if (e.toString().contains('429') && attempt < maxRetries - 1) {
          final backoffDelay = Duration(seconds: (attempt + 1) * 2); // Backoff exponencial
          await Future.delayed(backoffDelay);
          continue;
        }
        rethrow; // Re-lança se não é rate limit ou esgotou tentativas
      }
    }
    throw Exception('Máximo de tentativas excedido');
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

CONTROLES DE QUALIDADE OBRIGATÓRIOS:

1. PREVENÇÃO DE DUPLICAÇÃO
• NUNCA repita trechos, cenas, parágrafos ou sequências narrativas
• Antes de finalizar, revise o texto completo para garantir que cada evento ocorre apenas UMA vez
• Se detectar repetição durante a geração, pare e reescreva
• Mantenha um "registro mental" dos eventos já narrados para evitar loops

2. CONSISTÊNCIA DE NOMES E PERSONAGENS
• Estabeleça os nomes completos dos personagens no início
• Mantenha uma lista mental: [Nome - Relação - Idade - Características]
• NUNCA troque ou altere nomes durante a narrativa
• NUNCA misture idiomas (mantenha TUDO em português brasileiro)
• Verifique cada menção de nome antes de escrevê-la

3. ESTRUTURA NARRATIVA
• Início → Desenvolvimento → Clímax → Resolução → Conclusão
• Cada seção deve fluir naturalmente para a próxima
• Finalize a história de forma completa e satisfatória
• NÃO corte o texto abruptamente

4. VERIFICAÇÃO FINAL (OBRIGATÓRIA)
Antes de entregar o texto, execute mentalmente esta checklist:
✓ Todos os nomes de personagens estão consistentes?
✓ O texto está 100% em português brasileiro?
✓ Existe alguma cena ou parágrafo repetido?
✓ A história tem um final apropriado e completo?
✓ A continuidade temporal está correta?
✓ As idades e relações dos personagens se mantêm?

5. COMPRIMENTO E COMPLETUDE
• Gere a história COMPLETA em uma única resposta
• Se o limite de tokens for atingido, finalize a cena atual com uma conclusão satisfatória
• NUNCA termine no meio de uma palavra ou frase
• Se precisar comprimir, remova detalhes secundários, não o final

6. COMANDO DE VALIDAÇÃO
Após gerar cada seção importante (aproximadamente a cada 500 palavras):
• Pause mentalmente
• Releia o que foi escrito
• Confirme que não está repetindo eventos anteriores
• Continue apenas se tudo estiver correto

INSTRUÇÃO FINAL CRÍTICA:
Se em qualquer momento detectar que está prestes a repetir conteúdo, PARE imediatamente e prossiga para a próxima parte da narrativa ou finalize a história se já estiver completa.

${config.includeCallToAction ? _getCallToActionInstruction(config.language) : ''}

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

CONTROLES DE QUALIDADE PARA EXPANSÃO:
• MANTENHA todos os nomes de personagens EXATAMENTE iguais ao texto original
• NÃO repita nenhuma cena ou evento já descrito
• NÃO contradiga informações já estabelecidas
• Expanda com coerência temporal e narrativa
• Se estiver no final, conclua a história adequadamente
• Use exclusivamente português brasileiro

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
    String model = 'gemini-2.5-pro',
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

  static String _getCallToActionInstruction(String language) {
    final ctaText = _getCallToActionText(language);
    return '''

🎯 INSTRUÇÃO OBRIGATÓRIA - CALL-TO-ACTION:
APÓS o primeiro parágrafo completo da narrativa, você DEVE inserir EXATAMENTE este texto:

"$ctaText"

ESTRUTURA OBRIGATÓRIA:
1. Escreva o primeiro parágrafo da história
2. Termine o parágrafo com ponto final
3. Pule uma linha
4. Insira EXATAMENTE o CTA acima (sem aspas)
5. Adicione ponto final após o CTA
6. Pule uma linha
7. Continue com o segundo parágrafo da narrativa

EXEMPLO DE FORMATAÇÃO:
[Primeiro parágrafo da história.]

$ctaText

[Segundo parágrafo da história...]

Esta inserção é OBRIGATÓRIA e deve ser feita EXATAMENTE como especificado.
''';
  }

  static String _getCallToActionText(String language) {
    switch (language.toLowerCase()) {
      case 'english':
      case 'inglês':
        return 'Before we continue, don\'t forget to like this audio and subscribe to the channel by clicking the icon that appears in the bottom right corner of your screen! And tell me in the comments: where are you listening to us from and what are you doing while you listen? I love knowing who I\'m sharing this moment with. Now, let\'s continue with the narrative.';
      
      case 'spanish':
      case 'espanhol':
      case 'espanhol(mexicano)':
      case 'mexicano':
        return 'Antes de continuar, no olvides darle me gusta a este audio y suscribirte al canal haciendo clic en el ícono que aparece en la esquina inferior derecha de tu pantalla! Y cuéntame en los comentarios: ¿desde dónde nos estás escuchando y qué estás haciendo mientras nos escuchas? Me encanta saber con quién estoy compartiendo este momento. Ahora, continuemos con la narrativa.';
      
      case 'french':
      case 'francês':
        return 'Avant de continuer, n\'oubliez pas d\'aimer cet audio et de vous abonner à la chaîne en cliquant sur l\'icône qui apparaît dans le coin inférieur droit de votre écran ! Et dites-moi dans les commentaires : d\'où nous écoutez-vous et que faites-vous en nous écoutant ? J\'adore savoir avec qui je partage ce moment. Maintenant, continuons avec le récit.';
      
      case 'german':
      case 'alemão':
        return 'Bevor wir fortfahren, vergessen Sie nicht, diesem Audio zu liken und den Kanal zu abonnieren, indem Sie auf das Symbol klicken, das in der unteren rechten Ecke Ihres Bildschirms erscheint! Und erzählen Sie mir in den Kommentaren: Von wo hören Sie uns zu und was machen Sie, während Sie zuhören? Ich liebe es zu wissen, mit wem ich diesen Moment teile. Jetzt fahren wir mit der Erzählung fort.';
      
      case 'italian':
      case 'italiano':
        return 'Prima di continuare, non dimenticare di mettere mi piace a questo audio e iscriverti al canale cliccando sull\'icona che appare nell\'angolo in basso a destra del tuo schermo! E dimmi nei commenti: da dove ci stai ascoltando e cosa stai facendo mentre ci ascolti? Adoro sapere con chi sto condividendo questo momento. Ora, continuiamo con la narrativa.';
      
      case 'bulgarian':
      case 'búlgaro':
        return 'Преди да продължим, не забравяйте да харесате това аудио и да се абонирате за канала, като кликнете върху иконата, която се появява в долния десен ъгъл на екрана ви! И ми кажете в коментарите: откъде ни слушате и какво правите, докато ни слушате? Обичам да знам с кого споделям този момент. Сега да продължим с разказа.';
      
      case 'polish':
      case 'polonês':
        return 'Zanim przejdziemy dalej, nie zapomnijcie polubić tego audio i zasubskrybować kanał, klikając ikonę, która pojawi się w prawym dolnym rogu waszego ekranu! I powiedzcie mi w komentarzach: skąd nas słuchacie i co robicie podczas słuchania? Uwielbiam wiedzieć, z kim dzielę ten moment. Teraz przejdźmy do narracji.';
      
      case 'turkish':
      case 'turco':
        return 'Devam etmeden önce, bu sesli içeriği beğenmeyi ve ekranınızın sağ alt köşesinde görünen simgeye tıklayarak kanala abone olmayı unutmayın! Ve yorumlarda bana söyleyin: bizi nereden dinliyorsunuz ve dinlerken ne yapıyorsunuz? Bu anı kiminle paylaştığımı bilmeyi seviyorum. Şimdi anlatıma devam edelim.';
      
      case 'romanian':
      case 'romeno':
        return 'Înainte de a continua, nu uitați să dați like la acest audio și să vă abonați la canal făcând clic pe pictograma care apare în colțul din dreapta jos al ecranului! Și spuneți-mi în comentarii: de unde ne ascultați și ce faceți în timp ce ne ascultați? Îmi place să știu cu cine împart acest moment. Acum, să continuăm cu povestirea.';
      
      case 'croatian':
      case 'croata':
        return 'Prije nego što nastavimo, ne zaboravite lajkati ovaj audio i pretplatiti se na kanal klikom na ikonu koja se pojavljuje u donjem desnom kutu vašeg ekrana! I recite mi u komentarima: odakle nas slušate i što radite dok nas slušate? Volim znati s kim dijelim ovaj trenutak. Sada, nastavimo s pripovjedanjem.';
      
      case 'portuguese':
      case 'português':
      default:
        return 'Antes de continuar, não se esqueça de curtir este áudio e se inscrever no canal clicando no ícone que aparece no canto inferior direito da sua tela! E me conta nos comentários: de onde você está nos ouvindo e o que está fazendo enquanto nos escuta? Eu adoro saber com quem estou compartilhando este momento. Agora, vamos com a narrativa.';
    }
  }
}
