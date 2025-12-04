import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/script_result.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';
import 'package:flutter_gerador/data/models/localization_level.dart';
import 'package:flutter_gerador/data/models/debug_log.dart';
import 'gemini/gemini_modules.dart'; // 🆕 v7.6.35: Inclui PostGenerationFixer via barrel

// 🚀 NOVOS MÓDULOS DE PROMPTS (Refatoração v2.0)
import 'package:flutter_gerador/data/services/prompts/main_prompt_template.dart';

// 🏗️ v7.6.64: MÓDULOS REFATORADOS (Arquitetura SOLID)
import 'package:flutter_gerador/data/services/scripting/scripting_modules.dart';

/// 📝 Helper padronizado para logs (mantém emojis em debug, limpa em produção)
void _log(String message, {String level = 'info'}) {
  if (kDebugMode) {
    // Debug: mantém emojis e formatação original
    debugPrint(message);
  } else if (level == 'error' || level == 'critical') {
    // Produção: apenas erros críticos, sem emojis
    final cleaned = message
        .replaceAll(RegExp(r'[🚨🔥✅❌⚠️💡📊🎯📝🔗📚]'), '')
        .trim();
    debugPrint('[${level.toUpperCase()}] $cleaned');
  }
  // Produção: info/warning não logam (evita spam)
}

/// 🚀 FUNÇÃO TOP-LEVEL para filtrar parágrafos duplicados em Isolate
String _filterDuplicateParagraphsStatic(Map<String, dynamic> params) {
  final String existing = params['existing'] as String;
  final String addition = params['addition'] as String;

  if (addition.trim().isEmpty) return '';

  // Comparar apenas últimos ~5000 caracteres
  final recentText = existing.length > 5000
      ? existing.substring(existing.length - 5000)
      : existing;

  final existingSet = recentText
      .split(RegExp(r'\n{2,}'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toSet();

  final seen = <String>{};
  final buffer = <String>[];

  for (final rawParagraph in addition.split(RegExp(r'\n{2,}'))) {
    final paragraph = rawParagraph.trim();
    if (paragraph.isEmpty) continue;
    if (existingSet.contains(paragraph)) continue;
    if (!seen.add(paragraph)) continue;
    buffer.add(paragraph);
  }

  return buffer.join('\n\n');
}

/// 🚀 FUNÇÃO TOP-LEVEL para execução em Isolate separado
/// Evita travar UI thread durante verificação de repetição
Map<String, dynamic> _isTooSimilarInIsolate(Map<String, dynamic> params) {
  final String newBlock = params['newBlock'] as String;
  final String previousContent = params['previousContent'] as String;
  final double threshold = params['threshold'] as double;

  if (previousContent.isEmpty) {
    return {'isSimilar': false, 'reason': 'No previous content'};
  }

  // 🔥 PRIORIDADE 1: Verificar duplicação literal de blocos grandes
  final hasLiteral = _hasLiteralDuplicationStatic(newBlock, previousContent);
  if (hasLiteral) {
    return {'isSimilar': true, 'reason': 'Literal duplication detected'};
  }

  // 🚀 OTIMIZAÇÃO: Limitar contexto anterior para comparação
  final limitedPrevious = previousContent.length > 12000
      ? previousContent.substring(previousContent.length - 12000)
      : previousContent;

  // Dividir conteúdo anterior em parágrafos
  final paragraphs = limitedPrevious
      .split('\n\n')
      .where((p) => p.trim().isNotEmpty)
      .toList();

  // 🚀 OTIMIZAÇÃO CRÍTICA: Limitar a 10 últimos parágrafos
  final recentParagraphs = paragraphs.length > 10
      ? paragraphs.sublist(paragraphs.length - 10)
      : paragraphs;

  // Dividir novo bloco em parágrafos
  final newParagraphs = newBlock
      .split('\n\n')
      .where((p) => p.trim().isNotEmpty)
      .toList();

  // 🎯 AJUSTE FINO: Verificar cada parágrafo novo contra os RECENTES
  int highSimilarityCount = 0;

  for (final newPara in newParagraphs) {
    // 🔥 AJUSTE: Detectar parágrafos de 50+ palavras (era 100)
    final wordCount = newPara.trim().split(RegExp(r'\s+')).length;
    if (wordCount < 50) continue; // Ignorar parágrafos muito curtos

    if (highSimilarityCount >= 2) break;

    for (final oldPara in recentParagraphs) {
      final oldWordCount = oldPara.trim().split(RegExp(r'\s+')).length;
      if (oldWordCount < 50) continue; // Ignorar parágrafos muito curtos

      final similarity = _calculateSimilarityStatic(newPara, oldPara);

      // 🔥 AJUSTE: Threshold reduzido de 85% para 80%
      if (similarity >= threshold) {
        highSimilarityCount++;

        if (highSimilarityCount >= 2) {
          return {
            'isSimilar': true,
            'reason':
                '$highSimilarityCount paragraphs with ${(similarity * 100).toStringAsFixed(1)}% similarity',
          };
        }
        break;
      }
    }
  }

  return {'isSimilar': false, 'reason': 'Content is unique'};
}

/// Versão estática de _hasLiteralDuplication para usar em Isolate
/// 🔥 FORTALECIDO: Detecta duplicações literais com mais agressividade
bool _hasLiteralDuplicationStatic(String newBlock, String previousContent) {
  if (previousContent.length < 500) {
    return false; // 🔥 REDUZIDO: Era 1000, agora 500
  }

  // 🆕 NOVO: Verificar parágrafos completos duplicados (para transições de seção)
  final newParagraphs = newBlock
      .split('\n\n')
      .where(
        (p) =>
            p.trim().isNotEmpty && p.trim().split(RegExp(r'\s+')).length > 30,
      )
      .map((p) => p.trim().toLowerCase())
      .toList();

  final prevParagraphs = previousContent
      .split('\n\n')
      .where(
        (p) =>
            p.trim().isNotEmpty && p.trim().split(RegExp(r'\s+')).length > 30,
      )
      .map((p) => p.trim().toLowerCase())
      .toList();

  // 🔥 CRÍTICO: Detectar parágrafos idênticos (problema do Quitéria)
  for (final newPara in newParagraphs) {
    for (final prevPara in prevParagraphs) {
      // Similaridade exata ou muito próxima (95%+)
      if (newPara == prevPara) {
        return true; // Parágrafo duplicado exato
      }

      // 🆕 Verificar similaridade estrutural (mesmas primeiras 50 palavras)
      final newWords = newPara.split(RegExp(r'\s+'));
      final prevWords = prevPara.split(RegExp(r'\s+'));

      if (newWords.length > 50 && prevWords.length > 50) {
        final newStart = newWords.take(50).join(' ');
        final prevStart = prevWords.take(50).join(' ');

        if (newStart == prevStart) {
          return true; // Início idêntico em parágrafo longo
        }
      }
    }
  }

  // 🔥 Verificação de sequências de palavras (original)
  final newWords = newBlock.split(RegExp(r'\s+'));
  if (newWords.length < 150) return false; // 🔥 REDUZIDO: Era 200, agora 150

  final prevWords = previousContent.split(RegExp(r'\s+'));
  if (prevWords.length < 150) return false; // 🔥 REDUZIDO: Era 200, agora 150

  // 🔥 OTIMIZADO: Verificar sequências menores (150 palavras em vez de 200)
  for (int i = 0; i <= newWords.length - 150; i++) {
    final newSequence = newWords.sublist(i, i + 150).join(' ').toLowerCase();

    for (int j = 0; j <= prevWords.length - 150; j++) {
      final prevSequence = prevWords
          .sublist(j, j + 150)
          .join(' ')
          .toLowerCase();

      if (newSequence == prevSequence) {
        return true;
      }
    }
  }

  return false;
}

/// Versão estática de _calculateSimilarity para usar em Isolate
double _calculateSimilarityStatic(String text1, String text2) {
  if (text1.isEmpty || text2.isEmpty) return 0.0;

  final normalized1 = text1.toLowerCase().trim().replaceAll(
    RegExp(r'\s+'),
    ' ',
  );
  final normalized2 = text2.toLowerCase().trim().replaceAll(
    RegExp(r'\s+'),
    ' ',
  );

  if (normalized1 == normalized2) return 1.0;

  const nGramSize = 8;
  final words1 = normalized1.split(' ');
  final words2 = normalized2.split(' ');

  if (words1.length < nGramSize || words2.length < nGramSize) {
    final commonWords = words1.toSet().intersection(words2.toSet()).length;
    return commonWords / max(words1.length, words2.length);
  }

  final ngrams1 = <String>{};
  for (int i = 0; i <= words1.length - nGramSize; i++) {
    ngrams1.add(words1.sublist(i, i + nGramSize).join(' '));
  }

  final ngrams2 = <String>{};
  for (int i = 0; i <= words2.length - nGramSize; i++) {
    ngrams2.add(words2.sublist(i, i + nGramSize).join(' '));
  }

  final intersection = ngrams1.intersection(ngrams2).length;
  final union = ngrams1.union(ngrams2).length;

  return union > 0 ? intersection / union : 0.0;
}

/// Implementação consolidada limpa do GeminiService
class GeminiService {
  final Dio _dio;
  final String _instanceId;
  bool _isCancelled = false;

  // 🏗️ v7.6.64: MÓDULOS REFATORADOS (Arquitetura SOLID)
  late final LlmClient _llmClient;
  late final WorldStateManager _worldStateManager;
  late final ScriptValidator _scriptValidator;

  // 🚀 v7.6.20: Adaptive Delay Manager (economia de 40-50% do tempo)
  DateTime? _lastSuccessfulCall;
  int _consecutive503Errors = 0;
  int _consecutiveSuccesses = 0;

  // Debug Logger
  final _debugLogger = DebugLogManager();

  // 🆕 SISTEMA DE RASTREAMENTO DE NOMES - v4 (SOLUÇÃO TÉCNICA)
  // Armazena todos os nomes usados na história atual para prevenir duplicações
  final Set<String> _namesUsedInCurrentStory = {};

  // Circuit breaker
  bool _isCircuitOpen = false;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  static const int _maxFailures = 5; // Aumentado de 3 para 5
  static const Duration _circuitResetTime = Duration(
    seconds: 30,
  ); // Reduzido de 2 min para 30s

  // ===== RATE LIMITING GLOBAL OTIMIZADO PARA GEMINI BILLING =====
  // OTIMIZADO: Configuração mais agressiva baseada nos limites reais do Gemini
  static int _globalRequestCount = 0;
  static DateTime _globalLastRequestTime = DateTime.now();
  static const Duration _rateLimitWindow = Duration(
    seconds: 60,
  ); // AUMENTADO: Era 10s, agora 60s
  static const int _maxRequestsPerWindow =
      50; // AUMENTADO: Era 8, agora 50 (mais prÃ³ximo dos limites reais)
  static bool _rateLimitBusy = false;

  // Watchdog
  Timer? _watchdogTimer;
  bool _isOperationRunning = false;
  static const Duration _maxOperationTime = Duration(
    minutes: 60,
  ); // AUMENTADO: 60 min para roteiros longos (13k+ palavras = 35+ blocos)

  // 🎯 v7.6.51: HELPER PARA MODELO ÚNICO - Arquitetura Pipeline Modelo Único
  // O modelo selecionado pelo usuário deve ser usado em TODAS as etapas
  // para garantir consistência de estilo e respeitar a configuração do cliente
  static String _getSelectedModel(String qualityMode) {
    return qualityMode == 'flash'
        ? 'gemini-2.5-flash' // STABLE - Rápido e eficiente
        : qualityMode == 'ultra'
        ? 'gemini-3-pro-preview' // PREVIEW - Modelo mais avançado (Jan 2025)
        : 'gemini-2.5-pro'; // STABLE - Máxima qualidade (default)
  }

  GeminiService({String? instanceId})
    : _instanceId = instanceId ?? _genId(),
      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(
            seconds: 45,
          ), // AUMENTADO: Era 30s, agora 45s
          receiveTimeout: const Duration(
            minutes: 5,
          ), // AUMENTADO: Era 3min, agora 5min (para contextos grandes)
          sendTimeout: const Duration(
            seconds: 45,
          ), // AUMENTADO: Era 30s, agora 45s
        ),
      ) {
    // 🏗️ v7.6.64: Inicializar módulos refatorados
    _llmClient = LlmClient(instanceId: _instanceId);
    _worldStateManager = WorldStateManager(llmClient: _llmClient);
    _scriptValidator = ScriptValidator(llmClient: _llmClient);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (kDebugMode) debugPrint('[$_instanceId] -> ${o.method} ${o.path}');
          h.next(o);
        },
        onResponse: (r, h) {
          if (kDebugMode) debugPrint('[$_instanceId] <- ${r.statusCode}');
          _resetCircuit();
          h.next(r);
        },
        onError: (e, h) {
          if (kDebugMode) debugPrint('[$_instanceId] ERROR: ${e.message}');
          _registerFailure();
          h.next(e);
        },
      ),
    );
  }

  // ===================== API PÃšBLICA =====================
  Future<ScriptResult> generateScript(
    ScriptConfig config,
    void Function(GenerationProgress) onProgress,
  ) async {
    // 🤖 v7.6.19: RESPEITAR SELEÇÃO DO USUÁRIO - Não usar fallback automático
    // Se selecionou Gemini → usar APENAS Gemini
    // Se selecionou OpenAI → usar APENAS OpenAI (implementar no futuro)
    // _useOpenAIFallback = false; // ❌ REMOVIDO - OpenAI descontinuado

    if (kDebugMode) {
      debugPrint(
        '[$_instanceId] 🎯 Provider selecionado: ${config.selectedProvider}',
      );
      debugPrint(
        '[$_instanceId] 🚫 Fallback automático: DESABILITADO (usar apenas API selecionada)',
      );
    }

    // 🔥 CORREÇÃO CRÍTICA: Resetar variáveis globais ANTES de verificar rate limit
    // Isso garante que cada nova geração comece do zero
    _resetGlobalRateLimit();

    // 🆕 v4: Resetar rastreador de nomes para nova história
    _resetNameTracker();

    // 🆕 v7.6.37: Resetar personagens introduzidos para detecção de duplicatas
    PostGenerationFixer.resetIntroducedCharacters();

    if (!_canMakeRequest()) {
      return ScriptResult.error(
        errorMessage:
            'ServiÃ§o temporariamente indisponÃ­vel. Tente mais tarde.',
      );
    }

    // CORREÃ‡ÃƒO: Reset completo do estado para nova geraÃ§Ã£o
    resetState();

    // Tracker global alimentado com os nomes definidos pelo usuÃ¡rio/contexto
    final persistentTracker = _CharacterTracker();
    _bootstrapCharacterTracker(persistentTracker, config);

    // 🏗️ v7.6.64: WORLD STATE - Agora usa WorldState do módulo (SOLID)
    // Rastreia personagens, inventário, fatos e resumo da história
    // Usa o MESMO modelo selecionado pelo usuário (Pipeline Modelo Único)
    final worldState = WorldState();

    // 🏗️ v7.6.64: Reset e inicialização do WorldStateManager (SOLID)
    _worldStateManager.reset();
    _worldStateManager.initializeProtagonist(config.protagonistName);

    // Inicializar protagonista no World State usando classe do módulo
    if (config.protagonistName.trim().isNotEmpty) {
      worldState.upsertCharacter(
        'protagonista',
        WorldCharacter(
          nome: config.protagonistName.trim(),
          papel: 'protagonista/narradora',
          status: 'vivo',
        ),
      );
    }

    // 🆕 v7.6.53: CAMADA 1 - Gerar Sinopse Comprimida UMA VEZ no início
    // Usa o MESMO modelo selecionado pelo usuário (Pipeline Modelo Único)
    // 🏗️ v7.6.64: Migrado para usar WorldStateManager (SOLID)
    try {
      worldState.sinopseComprimida = await _worldStateManager.generateCompressedSynopsis(
        tema: config.tema,
        title: config.title,
        protagonistName: config.protagonistName,
        language: config.language,
        apiKey: config.apiKey,
        qualityMode: config.qualityMode,
      );
      if (kDebugMode) {
        debugPrint(
          '🔵 Camada 1 (Sinopse) gerada: ${worldState.sinopseComprimida.length} chars',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Erro ao gerar sinopse (não-crítico): $e');
      }
      // Fallback: usar tema truncado
      final fallbackSynopsis = config.tema.length > 500
          ? '${config.tema.substring(0, 500)}...'
          : config.tema;
      worldState.sinopseComprimida = fallbackSynopsis;
      // 🏗️ v7.6.64: Sincronizar fallback para WorldStateManager
      _worldStateManager.setSynopsis(fallbackSynopsis);
    }

    _startWatchdog();
    final start = DateTime.now();
    try {
      final totalBlocks = _calculateTotalBlocks(config);
      var acc = '';

      for (var block = 1; block <= totalBlocks && !_isCancelled; block++) {
        // 🎯 YIELD CRÍTICO: Liberar UI thread completamente antes de cada bloco
        // Aumentado de 5ms → 100ms para garantir animações suaves
        await Future.delayed(const Duration(milliseconds: 100));

        // 🐛 DEBUG: Log início de bloco
        _debugLogger.block(
          block,
          "Iniciando geração",
          metadata: {
            'totalBlocos': totalBlocks,
            'contextoAtual': acc.length,
            'palavrasGeradas': _countWords(acc),
          },
        );

        final phaseIdx = _getPhaseIndexFromProgress(block / totalBlocks);
        final phase = _phases[phaseIdx];
        final progress = block / totalBlocks;
        final elapsed = DateTime.now().difference(start);
        final estTotal = progress > 0
            ? Duration(
                milliseconds: (elapsed.inMilliseconds / progress).round(),
              )
            : Duration.zero;
        final remaining = estTotal - elapsed;
        final logs = _generateBlockLogs(phase, block, totalBlocks, config);

        // 🚀 OTIMIZAÇÃO CRÍTICA: Reduzir frequência de onProgress após 50%
        // Isso evita sobrecarga da UI quando contexto fica grande
        final shouldUpdateProgress = progress <= 0.5 || block % 2 == 0;

        if (shouldUpdateProgress) {
          onProgress(
            GenerationProgress(
              percentage: progress,
              currentPhase: phase,
              phaseIndex: phaseIdx,
              totalPhases: _phases.length,
              currentBlock: block,
              totalBlocks: totalBlocks,
              estimatedTimeRemaining: remaining,
              logs: logs,
              wordsGenerated: _countWords(acc),
            ),
          );

          // 🎯 YIELD OTIMIZADO: 50ms para UI respirar sem bloquear geração
          await Future.delayed(Duration(milliseconds: 50));
        }

        // 🔥 DELAY INTELIGENTE ENTRE BLOCOS: Sistema Adaptativo v7.6.20
        // Aprende com o comportamento da API e ajusta delays automaticamente
        if (block > 1) {
          final adaptiveDelay = _getAdaptiveDelay(blockNumber: block);

          if (kDebugMode) {
            debugPrint(
              '⏱️ Delay adaptativo de ${adaptiveDelay.inSeconds}s antes do bloco $block',
            );
            if (_consecutiveSuccesses >= 3) {
              debugPrint('   ✅ API rápida detectada - usando delay mínimo');
            } else if (_consecutive503Errors > 0) {
              debugPrint('   ⚠️ API lenta detectada - usando delay maior');
            }
          }
          await Future.delayed(adaptiveDelay);
        }

        final targetForBlock = _calculateTargetForBlock(
          block,
          totalBlocks,
          config,
        );
        var added = await _retryOnRateLimit(
          () => _generateBlockContent(
            acc,
            targetForBlock,
            phase,
            config,
            persistentTracker,
            block,
            totalBlocks,
            worldState: worldState, // 🆕 v7.6.52: World State
          ),
        );

        // 🆕 v7.6.35: CORREÇÃO PÓS-GERAÇÃO - Corrigir nomes trocados automaticamente
        // Executa ANTES de qualquer validação para garantir consistência
        if (added.trim().isNotEmpty && block > 1) {
          // 🔍 DEBUG v7.6.36: Verificar mapa antes de chamar fixer
          if (kDebugMode) {
            final roleMap = persistentTracker.roleToNameMap;
            debugPrint('🔧 [Bloco $block] Chamando PostGenerationFixer');
            debugPrint(
              '   roleToNameMap: ${roleMap.isEmpty ? "VAZIO!" : roleMap.toString()}',
            );
          }
          added = PostGenerationFixer.fixSwappedNames(
            added,
            persistentTracker.roleToNameMap,
            block,
          );
        }

        // 🎯 YIELD PÓS-API: Mínimo delay para UI
        await Future.delayed(const Duration(milliseconds: 10));

        // 🔥 RETRY PARA BLOCOS VAZIOS: Se bloco retornou vazio, tentar novamente até 6 vezes
        if (added.trim().isEmpty && acc.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              '⚠️ BLOCO $block VAZIO! Iniciando tentativas de retry...',
            );
          }

          for (int retry = 1; retry <= 6; retry++) {
            if (kDebugMode) {
              debugPrint('🔄 Retry $retry/6 para bloco $block...');
            }

            // 🚀 v7.6.47: DELAY PROGRESSIVO INTELIGENTE
            // Primeiros 3 retries: rápido (5s, 10s, 15s)
            // Últimos 3 retries: moderado (20s, 30s, 40s) para dar tempo ao servidor
            final retryDelay = retry <= 3 ? 5 * retry : 15 + (retry - 3) * 10;
            if (kDebugMode) {
              debugPrint(
                '⏱️ Aguardando ${retryDelay}s antes do retry (${retry <= 3 ? "rápido" : "moderado"})...',
              );
            }
            await Future.delayed(Duration(seconds: retryDelay));

            // 🔥 AUMENTADO: Contexto de 3000 para 8000 chars para manter nomes em memória
            final contextForRetry = retry > 1 && acc.length > 8000
                ? acc.substring(acc.length - 8000)
                : acc;

            added = await _retryOnRateLimit(
              () => _generateBlockContent(
                contextForRetry,
                targetForBlock,
                phase,
                config,
                persistentTracker,
                block,
                totalBlocks,
                worldState: worldState, // 🆕 v7.6.52
              ),
            );

            if (added.trim().isNotEmpty) {
              if (kDebugMode) {
                debugPrint('✅ Retry $retry bem-sucedido! Bloco $block gerado.');
              }
              break;
            }
          }

          // 🔥 CORREÇÃO CRÍTICA: Se após 6 tentativas ainda estiver vazio, ABORTAR geração
          if (added.trim().isEmpty) {
            _log(
              '❌ ERRO CRÍTICO: Bloco $block permaneceu vazio após 6 retries!',
              level: 'critical',
            );
            _log(
              '🔴 ABORTANDO GERAÇÃO: Servidor Gemini pode estar sobrecarregado.',
              level: 'critical',
            );
            _log(
              '💡 SOLUÇÃO: Aguarde 10-15 minutos e tente novamente, ou use OpenAI GPT-4o.',
              level: 'critical',
            );

            // 🔥 RETORNAR ERRO em vez de continuar
            return ScriptResult.error(
              errorMessage:
                  '🔴 ERRO: Bloco $block falhou após 6 tentativas (total ~2min de espera).\n\n'
                  'O servidor Gemini está temporariamente sobrecarregado.\n'
                  'Aguarde 10-15 minutos e tente novamente, ou:\n'
                  '• Troque para OpenAI GPT-4o nas configurações\n'
                  '• Tente em horário de menor tráfego\n\n'
                  'Progresso salvo: ${_countWords(acc)} palavras (bloco $block de $totalBlocks).',
            );
          }
        }

        // 🎯 YIELD: Liberar UI thread antes de validação pesada
        await Future.delayed(const Duration(milliseconds: 10));

        // � VALIDAÇÃO ANTI-REPETIÇÃO EM ISOLATE: Verificar sem travar UI
        if (added.trim().isNotEmpty && acc.length > 500) {
          // Executar em isolate separado para não bloquear UI thread
          final result = await compute(_isTooSimilarInIsolate, {
            'newBlock': added,
            'previousContent': acc,
            'threshold':
                0.80, // 🔥 AJUSTADO: Era 0.85, agora 0.80 para maior sensibilidade
          });

          final isSimilar = result['isSimilar'] as bool;

          if (isSimilar) {
            // 🐛 DEBUG: Log repetição detectada
            _debugLogger.warning(
              "Repetição detectada no bloco $block",
              details: result['reason'] as String,
              metadata: {
                'bloco': block,
                'tamanho': _countWords(added),
                'threshold': 0.80,
              },
            );

            if (kDebugMode) {
              debugPrint(
                '❌ BLOCO $block REJEITADO: Muito similar ao conteúdo anterior!',
              );
              debugPrint(
                '   📊 Tamanho do bloco: ${_countWords(added)} palavras',
              );
              debugPrint('   🔍 Motivo: ${result['reason']}');
              debugPrint(
                '   🔄 Regenerando com aviso explícito contra repetição...',
              );
            }

            // 🔥 TENTATIVA 1: Regenerar com prompt específico contra repetição
            final regenerated = await _retryOnRateLimit(
              () => _generateBlockContent(
                acc,
                targetForBlock,
                phase,
                config,
                persistentTracker,
                block,
                totalBlocks,
                avoidRepetition: true, // Flag especial
                worldState: worldState, // 🆕 v7.6.52
              ),
            );

            // Verificar novamente com threshold ainda mais alto (90%)
            final retryResult = await compute(_isTooSimilarInIsolate, {
              'newBlock': regenerated,
              'previousContent': acc,
              'threshold': 0.85, // 🔥 AJUSTADO: Era 0.90, agora 0.85
            });

            final stillSimilar = retryResult['isSimilar'] as bool;

            if (stillSimilar) {
              if (kDebugMode) {
                debugPrint(
                  '⚠️ TENTATIVA 1 FALHOU: Ainda há similaridade alta!',
                );
                debugPrint(
                  '   🔄 TENTATIVA 2: Regenerando novamente com contexto reduzido...',
                );
              }

              // 🔥 AUMENTADO: Contexto de 3000 para 8000 chars para manter nomes em memória
              final contextoPrevioReduzido = acc.length > 8000
                  ? acc.substring(acc.length - 8000)
                  : acc;

              final regenerated2 = await _retryOnRateLimit(
                () => _generateBlockContent(
                  contextoPrevioReduzido,
                  targetForBlock,
                  phase,
                  config,
                  persistentTracker,
                  block,
                  totalBlocks,
                  avoidRepetition: true,
                  worldState: worldState, // 🆕 v7.6.52
                ),
              );

              final stillSimilar2 = _isTooSimilar(
                regenerated2,
                acc,
                threshold: 0.90,
              );

              if (stillSimilar2) {
                if (kDebugMode) {
                  debugPrint('⚠️ TENTATIVA 2 FALHOU: Similaridade persiste!');
                  debugPrint(
                    '   ⚠️ DECISÃO: Usando versão menos similar (tentativa 1)',
                  );
                }
                acc +=
                    regenerated; // Usar primeira tentativa (menos similar que original)
              } else {
                if (kDebugMode) {
                  debugPrint('✅ TENTATIVA 2 BEM-SUCEDIDA: Bloco único gerado!');
                }
                acc += regenerated2;
              }
            } else {
              if (kDebugMode) {
                debugPrint('✅ REGENERAÇÃO BEM-SUCEDIDA: Bloco agora é único!');
              }
              acc += regenerated;
            }
          } else {
            // ✅ Bloco passou na validação anti-repetição
            acc += added; // Usar versão original
          }
        } else {
          // ✅ Primeiro bloco ou contexto pequeno - adicionar direto
          acc += added;
        }

        if (added.trim().isNotEmpty) {
          // 🚨 VALIDAÇÃO CRÍTICA 1: Detectar e registrar protagonista no Bloco 1
          if (block == 1) {
            _detectAndRegisterProtagonist(added, config, persistentTracker);
          }

          // 🚨 VALIDAÇÃO CRÍTICA 2: Verificar se protagonista mudou de nome
          final protagonistChanged = _detectProtagonistNameChange(
            added,
            config,
            persistentTracker,
            block,
          );

          // 🚨 VALIDAÇÃO CRÍTICA 3: Verificar se algum nome foi reutilizado
          _validateNameReuse(added, persistentTracker, block);

          // 🔥 VALIDAÇÃO CRÍTICA 4: REJEITAR BLOCO se protagonista mudou ou personagens trocaram de nome
          final characterNameChanges = _detectCharacterNameChanges(
            added,
            persistentTracker,
            block,
          );
          if (protagonistChanged || characterNameChanges.isNotEmpty) {
            if (kDebugMode) {
              debugPrint(
                '🚨🚨🚨 BLOCO $block REJEITADO - MUDANÇA DE NOME DETECTADA! 🚨🚨🚨',
              );
              if (protagonistChanged) {
                final detected = persistentTracker.getProtagonistName();
                debugPrint(
                  '   ❌ PROTAGONISTA: "$detected" mudou para outro nome!',
                );
              }
              for (final change in characterNameChanges) {
                final role = change['role'] ?? 'personagem';
                final oldName = change['oldName'] ?? '';
                final newName = change['newName'] ?? '';
                debugPrint('   ❌ $role: "$oldName" → "$newName"');
              }
              debugPrint('   🔄 Regenerando bloco (tentativa 1/3)...');
            }

            // 🆕 v7.6.17: LIMITE DE REGENERAÇÕES para evitar loop infinito
            const maxRegenerations = 3;
            String? regenerated;

            for (
              int regenAttempt = 1;
              regenAttempt <= maxRegenerations;
              regenAttempt++
            ) {
              if (kDebugMode && regenAttempt > 1) {
                debugPrint(
                  '   🔄 Tentativa $regenAttempt/$maxRegenerations...',
                );
              }

              regenerated = await _generateBlockContent(
                acc,
                targetForBlock,
                phase,
                config,
                persistentTracker,
                block,
                totalBlocks,
                avoidRepetition: true,
                worldState: worldState, // 🆕 v7.6.52
              );

              if (regenerated.trim().isEmpty) {
                if (kDebugMode) {
                  debugPrint('   ❌ Regeneração $regenAttempt retornou vazia!');
                }
                continue; // Tentar novamente
              }

              // Validar se regeneração corrigiu o problema
              final stillChanged = _detectProtagonistNameChange(
                regenerated,
                config,
                persistentTracker,
                block,
              );

              if (!stillChanged) {
                if (kDebugMode) {
                  debugPrint('   ✅ Regeneração $regenAttempt bem-sucedida!');
                }
                break; // Sucesso! Sair do loop
              } else {
                if (kDebugMode) {
                  debugPrint(
                    '   ⚠️ Regeneração $regenAttempt ainda tem erro de nome!',
                  );
                }
                if (regenAttempt == maxRegenerations) {
                  if (kDebugMode) {
                    debugPrint(
                      '   ❌ Limite de regenerações atingido! Aceitando bloco...',
                    );
                  }
                }
              }
            }

            // Substituir bloco rejeitado pelo regenerado (ou null se todas falharam)
            if (regenerated != null && regenerated.trim().isNotEmpty) {
              added = regenerated;
              if (kDebugMode) {
                debugPrint('✅ Bloco $block regenerado com nomes corretos!');
              }
            } else {
              if (kDebugMode) {
                debugPrint(
                  '❌ ERRO: Todas as $maxRegenerations tentativas falharam! Usando bloco original...',
                );
              }
              // Manter bloco original se todas regenerações falharam
            }
          }

          // 🆕 v7.6.17: VALIDAÇÃO UNIVERSAL DE TODOS OS NOMES (primários + secundários)
          final allNamesInBlock = _extractNamesFromText(
            added,
          ).where((n) => _looksLikePersonName(n)).toList();

          // Detectar nomes novos não registrados no tracker
          final unregisteredNames = allNamesInBlock
              .where((name) => !persistentTracker.hasName(name))
              .toList();

          if (unregisteredNames.isNotEmpty && block > 1) {
            if (kDebugMode) {
              debugPrint(
                '🆕 Bloco $block: Nomes novos detectados: ${unregisteredNames.join(", ")}',
              );
            }
            // Registrar novos nomes no tracker
            for (final name in unregisteredNames) {
              persistentTracker.addName(name, blockNumber: block);
            }
          }

          // 🆕 v4: EXTRAÇÃO E RASTREAMENTO DE NOMES
          final duplicatedNames = _validateNamesInText(
            added,
            _namesUsedInCurrentStory,
          );
          if (duplicatedNames.isNotEmpty) {
            if (kDebugMode) {
              debugPrint(
                '🚨 ALERTA: Nomes duplicados detectados no Bloco $block!',
              );
              debugPrint('   Nomes: ${duplicatedNames.join(", ")}');
              debugPrint(
                '   ⚠️ Isso pode indicar personagens com mesmo nome em papéis diferentes!',
              );
            }
            _debugLogger.warning(
              "Possível duplicação de nomes no bloco $block",
              details: "Nomes: ${duplicatedNames.join(", ")}",
              metadata: {'bloco': block, 'nomes': duplicatedNames},
            );
          }
          _addNamesToTracker(added);

          // 🆕 VALIDAÇÃO CRÍTICA 4: Verificar inconsistências em relações familiares
          _validateFamilyRelations(added, block);

          // 🔄 v7.6.41: Resetar watchdog a cada bloco bem-sucedido
          // Evita timeout em roteiros longos (35+ blocos)
          _resetWatchdog();

          // 🐛 DEBUG: Log bloco completado com sucesso
          _debugLogger.success(
            "Bloco $block completado",
            details: "Tamanho: ${_countWords(added)} palavras",
            metadata: {
              'bloco': block,
              'palavrasNoBloco': _countWords(added),
              'contextoTotal': acc.length + added.length,
            },
          );

          // 🚨 v7.6.28: VALIDAÇÃO DE NOMES DUPLICADOS (antes da v7.6.25)
          // OBJETIVO: Detectar quando MESMO NOME aparece em PAPÉIS DIFERENTES
          // EXEMPLO: "Mark" como boyfriend + "Mark" como attorney
          final duplicateNameConflict = _validateUniqueNames(
            added,
            persistentTracker,
            block,
          );

          if (duplicateNameConflict) {
            // ❌ BLOCO REJEITADO: Nome duplicado em papéis diferentes
            if (kDebugMode) {
              debugPrint(
                '❌ v7.6.28: BLOCO $block REJEITADO por NOME DUPLICADO!',
              );
              debugPrint(
                '   💡 EXEMPLO: "Mark" aparece como boyfriend E attorney (nomes devem ser únicos)',
              );
              debugPrint('   🔄 Forçando regeneração do bloco...');
            }

            _debugLogger.warning(
              "Bloco $block rejeitado por nome duplicado",
              details: "Mesmo nome usado para personagens diferentes",
              metadata: {'bloco': block},
            );

            // 🔄 Forçar regeneração: bloco vazio = retry automático
            added = '';
          } else {
            // ✅ v7.6.28: Nomes únicos, prosseguir para validação de papéis

            // 🚨 v7.6.25: VALIDAÇÃO DE CONFLITOS DE PAPEL
            final trackerValid = _updateTrackerFromContextSnippet(
              persistentTracker,
              config,
              added,
            );

            if (!trackerValid) {
              // ❌ BLOCO REJEITADO: Conflito de papel detectado (ex: advogado Martin → Richard)
              if (kDebugMode) {
                debugPrint(
                  '❌ v7.6.25: BLOCO $block REJEITADO por CONFLITO DE PAPEL!',
                );
                debugPrint(
                  '   💡 EXEMPLO: Mesmo papel (advogado) com nomes diferentes (Martin vs Richard)',
                );
                debugPrint('   🔄 Forçando regeneração do bloco...');
              }

              _debugLogger.warning(
                "Bloco $block rejeitado por conflito de papel",
                details: "Um personagem mudou de nome no mesmo papel",
                metadata: {'bloco': block},
              );

              // 🔄 Forçar regeneração: bloco vazio = retry automático
              added = '';
            } else {
              // ✅ v7.6.25: Tracker válido, atualizar mapeamento já foi feito
              if (kDebugMode) {
                debugPrint(
                  '✅ v7.6.28 + v7.6.25: Bloco $block ACEITO (nomes únicos + sem conflitos de papel)',
                );
              }

              // 🆕 v7.6.52: ATUALIZAR WORLD STATE - Pipeline Modelo Único
              // O MESMO modelo selecionado pelo usuário atualiza o JSON de estado
              // Isso garante consistência e respeita a config do cliente
              // 🏗️ v7.6.64: Migrado para usar WorldStateManager (SOLID)
              if (added.trim().isNotEmpty) {
                await _worldStateManager.updateFromGeneratedBlock(
                  generatedBlock: added,
                  blockNumber: block,
                  apiKey: config.apiKey,
                  qualityMode: config.qualityMode,
                  language: config.language,
                );
                // Sincronizar resumo de volta para o worldState local (compatibilidade)
                worldState.resumoAcumulado = _worldStateManager.state.resumoAcumulado;
              }
            }
          }
        }

        // OTIMIZADO: Checkpoint de estabilidade ultra-rápido
        await Future.delayed(
          const Duration(milliseconds: 50),
        ); // ULTRA-OTIMIZADO: Era 150ms, agora 50ms

        // Verificacao de sanidade do resultado
        if (added.trim().isEmpty) {
          if (kDebugMode) {
            debugPrint(
              '[$_instanceId] AVISO: Bloco $block retornou vazio - tentando RETRY',
            );
          }

          // 🔥 RETRY AUTOMÁTICO: Tentar novamente até 3x quando bloco vazio
          // AUMENTADO: Era 2, agora 3 retries para dar mais chance de sucesso
          int retryCount = 0;
          const maxRetries = 3;

          while (retryCount < maxRetries && added.trim().isEmpty) {
            retryCount++;
            if (kDebugMode) {
              debugPrint(
                '[$_instanceId] 🔄 Retry automático $retryCount/$maxRetries para bloco $block',
              );
            }

            // Aguardar antes de retry (exponential backoff otimizado: 2s, 4s, 6s)
            await Future.delayed(
              Duration(seconds: 2 * retryCount),
            ); // OTIMIZADO: era 4s

            // Tentar gerar novamente
            try {
              added = await _retryOnRateLimit(
                () => _generateBlockContent(
                  acc,
                  targetForBlock,
                  phase,
                  config,
                  persistentTracker,
                  block,
                  totalBlocks,
                  worldState: worldState, // 🆕 v7.6.52
                ),
              );

              if (added.trim().isNotEmpty) {
                // 🚨 v7.6.28: VALIDAR nomes duplicados PRIMEIRO
                final retryHasDuplicateNames = _validateUniqueNames(
                  added,
                  persistentTracker,
                  block,
                );

                if (retryHasDuplicateNames) {
                  // ❌ Bloco regenerado tem nomes duplicados
                  if (kDebugMode) {
                    debugPrint(
                      '[$_instanceId] ❌ v7.6.28: Retry $retryCount REJEITADO (nomes duplicados)',
                    );
                  }
                  added = ''; // Forçar nova tentativa
                  continue; // Tentar próximo retry
                }

                // 🚨 v7.6.25: VALIDAR conflitos de papel DEPOIS
                final retryTrackerValid = _updateTrackerFromContextSnippet(
                  persistentTracker,
                  config,
                  added,
                );

                if (!retryTrackerValid) {
                  // ❌ Bloco regenerado também tem conflito de papel
                  if (kDebugMode) {
                    debugPrint(
                      '[$_instanceId] ❌ v7.6.25: Retry $retryCount REJEITADO (conflito de papel)',
                    );
                  }
                  added = ''; // Forçar nova tentativa
                  continue; // Tentar próximo retry
                }

                if (kDebugMode) {
                  debugPrint(
                    '[$_instanceId] ✅ v7.6.28 + v7.6.25: Retry válido! Bloco $block aceito.',
                  );
                }
                break; // Sucesso, sair do loop de retry
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                  '[$_instanceId] ❌ Retry automático $retryCount falhou: $e',
                );
              }
            }
          }

          // 🔥 CORREÇÃO CRÍTICA: Se ainda vazio após retries, ABORTAR em vez de continuar
          if (added.trim().isEmpty) {
            if (kDebugMode) {
              debugPrint(
                '[$_instanceId] ❌ ERRO CRÍTICO: Bloco $block falhou após $maxRetries retries - ABORTANDO',
              );
            }

            return ScriptResult.error(
              errorMessage:
                  '🔴 ERRO CRÍTICO: Bloco $block permaneceu vazio após 6 tentativas.\n\n'
                  'O servidor Gemini está temporariamente sobrecarregado.\n'
                  'Aguarde 10-15 minutos e tente novamente, ou troque para OpenAI.\n\n'
                  'Progresso salvo: ${_countWords(acc)} palavras de ${config.quantity} (bloco $block de $totalBlocks).',
            );
          }
        }

        // Limpeza de memÃ³ria otimizada
        if (kDebugMode) {
          debugPrint(
            '[$_instanceId] Checkpoint bloco $block - Limpeza memÃ³ria',
          );
        }
        await Future.delayed(
          const Duration(milliseconds: 10),
        ); // ULTRA-OTIMIZADO: Era 50ms, agora 10ms

        // Delay adicional entre blocos para evitar sobrecarga
        await Future.delayed(
          Duration(milliseconds: _getBlockDelay(block, totalBlocks)),
        );
      }

      // ðŸš« EXPANSÃƒO FORÃ‡ADA DESATIVADA
      // Sistema de expansÃ£o removido para evitar mÃºltiplos finais empilhados.
      // A meta de caracteres deve ser atingida atravÃ©s do ajuste dos blocos iniciais,
      // nÃ£o forÃ§ando continuaÃ§Ãµes apÃ³s a histÃ³ria jÃ¡ ter concluÃ­do naturalmente.
      // Isso preserva a qualidade narrativa e evita finais duplicados.

      if (!_isCancelled && !_checkTargetMet(acc, config)) {
        final needed = config.measureType == 'caracteres'
            ? (config.quantity - acc.length)
            : (config.quantity - _countWords(acc));

        if (kDebugMode) {
          debugPrint(
            '[$_instanceId] âš ï¸ Meta nÃ£o atingida - Faltam $needed ${config.measureType}',
          );
          debugPrint(
            '[$_instanceId] ï¿½ DICA: Aumente o tamanho dos blocos iniciais para atingir a meta',
          );
        }
      }

      if (_isCancelled) {
        return ScriptResult.error(errorMessage: 'Geração cancelada');
      }

      _stopWatchdog();

      // 📊 LOG FINAL: Resumo de personagens rastreados
      if (kDebugMode && persistentTracker.confirmedNames.isNotEmpty) {
        debugPrint('📊 RESUMO FINAL DE PERSONAGENS:');
        debugPrint(
          '   Total rastreado: ${persistentTracker.confirmedNames.length} personagem(ns)',
        );
        debugPrint('   Nomes: ${persistentTracker.confirmedNames.join(", ")}');
      }

      // 🧹 LIMPAR MARCADORES DE DEBUG DO TEXTO FINAL
      final cleanedAcc = acc.replaceAll(
        RegExp(r'PERSONAGEM MENCIONADO:\s*'),
        '',
      );

      // 🆕 v7.6.43: REMOVER PARÁGRAFOS DUPLICADOS DO ROTEIRO FINAL
      var deduplicatedScript = _removeAllDuplicateParagraphs(cleanedAcc);

      // 🔍 DETECÇÃO FINAL: Verificar se há parágrafos duplicados restantes (apenas LOG)
      if (kDebugMode) {
        _detectDuplicateParagraphsInFinalScript(deduplicatedScript);
      }

      // 🎯 v7.6.45: VALIDAÇÃO RIGOROSA DE COERÊNCIA COM TÍTULO
      // 🏗️ v7.6.64: Migrado para usar ScriptValidator (SOLID)
      if (config.title.trim().isNotEmpty) {
        final validationResult = await _scriptValidator.validateTitleCoherenceRigorous(
          title: config.title,
          story: deduplicatedScript,
          language: config.language,
          apiKey: config.apiKey,
        );

        final isCoherent = validationResult['isValid'] as bool? ?? true;
        final confidence = validationResult['confidence'] as int? ?? 0;
        final missingElements =
            (validationResult['missingElements'] as List?)?.cast<String>() ??
            [];
        final foundElements =
            (validationResult['foundElements'] as List?)?.cast<String>() ?? [];

        _debugLogger.info(
          '🎯 Validação de coerência título-história',
          details:
              '''
Título: "${config.title}"
Resultado: ${isCoherent ? '✅ COERENTE' : '❌ INCOERENTE'}
Confiança: $confidence%

📋 Elementos encontrados:
${foundElements.isEmpty ? '  (nenhum)' : foundElements.map((e) => '  ✓ $e').join('\n')}

${missingElements.isEmpty ? '' : '⚠️ Elementos ausentes:\n${missingElements.map((e) => '  ✗ $e').join('\n')}'}
''',
          metadata: {
            'isCoherent': isCoherent,
            'confidence': confidence,
            'missingCount': missingElements.length,
            'foundCount': foundElements.length,
          },
        );

        // 🔄 FALLBACK: Se incoerente E confiança baixa, tentar regenerar ÚLTIMO bloco
        if (!isCoherent && confidence < 50 && missingElements.isNotEmpty) {
          _debugLogger.warning(
            '🔄 Tentando regeneração com ênfase nos elementos faltantes',
            details:
                'Elementos críticos ausentes: ${missingElements.take(3).join(", ")}',
          );

          try {
            // Extrair últimos 2 blocos para contexto
            final blocks = deduplicatedScript.split('\n\n');
            final contextBlocks = blocks.length > 2
                ? blocks.sublist(blocks.length - 2)
                : blocks;
            final context = contextBlocks.join('\n\n');

            // Criar prompt de recuperação com elementos faltantes
            final recoveryPrompt = _buildRecoveryPrompt(
              config.title,
              missingElements,
              context,
              config.language,
            );

            // Gerar bloco de recuperação com o MESMO modelo selecionado pelo usuário
            // 🎯 v7.6.51: Arquitetura Modelo Único - usar config.qualityMode
            final recoveryResponse = await _makeApiRequest(
              apiKey: config.apiKey,
              model: _getSelectedModel(config.qualityMode),
              prompt: recoveryPrompt,
              maxTokens: 500, // Bloco pequeno de recuperação
            );

            if (recoveryResponse != null &&
                recoveryResponse.trim().isNotEmpty) {
              // Adicionar bloco de recuperação ao final
              deduplicatedScript = '$deduplicatedScript\n\n$recoveryResponse';
              _debugLogger.success(
                '✅ Bloco de recuperação adicionado',
                details: 'Novos elementos incorporados à história',
              );
            }
          } catch (e) {
            _debugLogger.warning(
              '⚠️ Falha na regeneração',
              details: 'Mantendo história original: $e',
            );
          }
        }
      }

      // 🐛 DEBUG: Log estatísticas finais
      final stats = _debugLogger.getStatistics();
      _debugLogger.success(
        "Geração completa!",
        details:
            "Roteiro finalizado com sucesso\n"
            "- Palavras: ${_countWords(deduplicatedScript)}\n"
            "- Caracteres: ${deduplicatedScript.length}\n"
            "- Personagens: ${persistentTracker.confirmedNames.length}\n"
            "- Logs gerados: ${stats['total']}",
        metadata: {
          'palavras': _countWords(deduplicatedScript),
          'caracteres': deduplicatedScript.length,
          'personagens': persistentTracker.confirmedNames.length,
          'logsTotal': stats['total'],
          'erros': stats['error'],
          'avisos': stats['warning'],
        },
      );

      return ScriptResult(
        scriptText: deduplicatedScript,
        wordCount: _countWords(deduplicatedScript),
        charCount: deduplicatedScript.length,
        paragraphCount: deduplicatedScript.split('\n').length,
        readingTime: (_countWords(deduplicatedScript) / 150).ceil(),
      );
    } catch (e) {
      _stopWatchdog();
      if (_isCancelled) {
        return ScriptResult.error(errorMessage: 'Geração cancelada');
      }
      return ScriptResult.error(errorMessage: 'Erro: $e');
    }
  }

  void cancelGeneration() {
    if (kDebugMode) debugPrint('[$_instanceId] Cancelando geraÃ§Ã£o...');
    _isCancelled = true;
    _stopWatchdog();

    // CORREÇÃO: Não fechar o Dio aqui, pois pode ser reutilizado
    // Apenas marcar como cancelado e limpar estado se necessário
    if (kDebugMode) {
      debugPrint('[$_instanceId] Geração cancelada pelo usuário');
    }
  }

  /// 🤖 Configura OpenAI como fallback para erro 503 (DESCONTINUADO)
  void setOpenAIKey(String? apiKey) {
    // REMOVIDO - OpenAI não é mais usado
    if (kDebugMode) {
      debugPrint('[$_instanceId] OpenAI fallback descontinuado');
    }
  }

  // Método para limpar recursos quando o service não for mais usado
  void dispose() {
    if (kDebugMode) debugPrint('[$_instanceId] Fazendo dispose do service...');
    _isCancelled = true;
    _stopWatchdog();
    try {
      _dio.close(force: true);
    } catch (e) {
      if (kDebugMode) debugPrint('[$_instanceId] Erro ao fechar Dio: $e');
    }
  }

  // CORREÃ‡ÃƒO: MÃ©todo para resetar completamente o estado interno
  void resetState() {
    if (kDebugMode) debugPrint('[$_instanceId] Resetando estado interno...');
    _isCancelled = false;
    _isOperationRunning = false;
    _failureCount = 0;
    _isCircuitOpen = false;
    _lastFailureTime = null;
    _stopWatchdog();

    // 🔧 NOVO: Resetar variáveis static também (rate limiting global)
    _resetGlobalRateLimit();

    if (kDebugMode) {
      debugPrint(
        '[$_instanceId] ✅ Estado completamente resetado (incluindo rate limit global)',
      );
    }
  }

  // 🔧 NOVO: Método para resetar rate limiting global entre gerações
  static void _resetGlobalRateLimit() {
    _globalRequestCount = 0;
    _globalLastRequestTime = DateTime.now();
    _rateLimitBusy = false;
  }

  Future<String> generateText(String prompt) async {
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
        queryParameters: {'key': 'demo_key'},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1000,
          },
        },
      );

      return response
              .data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          '';
    } catch (e) {
      if (kDebugMode) debugPrint('Erro na geraÃ§Ã£o de texto: $e');
      return '';
    }
  }

  void cancel() {
    cancelGeneration();
  }

  // ===================== Infra =====================
  static String _genId() =>
      'gemini_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
  void _resetCircuit() {
    _isCircuitOpen = false;
    _failureCount = 0;
    _lastFailureTime = null;
  }

  void _registerFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    if (_failureCount >= _maxFailures) {
      _isCircuitOpen = true;
      if (kDebugMode) debugPrint('[$_instanceId] Circuit aberto');
    }
  }

  bool _canMakeRequest() {
    if (!_isCircuitOpen) return true;
    if (_lastFailureTime != null &&
        DateTime.now().difference(_lastFailureTime!) > _circuitResetTime) {
      _resetCircuit();
      return true;
    }
    return false;
  }

  void _startWatchdog() {
    _stopWatchdog();
    _isOperationRunning = true;
    if (kDebugMode) {
      debugPrint(
        '[$_instanceId] Iniciando watchdog (${_maxOperationTime.inMinutes} min)',
      );
    }

    _watchdogTimer = Timer(_maxOperationTime, () {
      if (_isOperationRunning && !_isCancelled) {
        if (kDebugMode) {
          debugPrint(
            '[$_instanceId] Watchdog timeout - cancelando operaÃ§Ã£o apÃ³s ${_maxOperationTime.inMinutes} min',
          );
        }
        _isCancelled = true;
      }
    });
  }

  /// 🔄 v7.6.41: Resetar watchdog a cada bloco bem-sucedido
  /// Evita timeout em roteiros longos quando a geração está funcionando
  void _resetWatchdog() {
    if (_isOperationRunning && !_isCancelled) {
      _startWatchdog(); // Reinicia o timer
      if (kDebugMode) {
        debugPrint('[$_instanceId] Watchdog resetado - operação ativa');
      }
    }
  }

  void _stopWatchdog() {
    if (_watchdogTimer != null) {
      _watchdogTimer!.cancel();
      if (kDebugMode && _isOperationRunning) {
        debugPrint('[$_instanceId] Parando watchdog');
      }
    }
    _isOperationRunning = false;
  }

  Future<void> _ensureRateLimit() async {
    // CRÃTICO: Rate limiting global para mÃºltiplas instÃ¢ncias/workspaces
    // Tentativa com timeout para evitar deadlocks
    int attempts = 0;
    const maxAttempts = 100; // 5 segundos mÃ¡ximo de espera

    while (_rateLimitBusy && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    if (attempts >= maxAttempts) {
      if (kDebugMode) {
        debugPrint('[$_instanceId] Rate limit timeout, proceeding anyway');
      }
      return; // Evita deadlock total
    }

    _rateLimitBusy = true;

    try {
      final now = DateTime.now();
      final diff = now.difference(_globalLastRequestTime);

      if (kDebugMode) {
        debugPrint(
          '[$_instanceId] Rate limit check: $_globalRequestCount/$_maxRequestsPerWindow requests in window',
        );
      }

      // Reset contador se passou da janela de rate limit
      if (diff > _rateLimitWindow) {
        _globalRequestCount = 0;
        if (kDebugMode) debugPrint('[$_instanceId] Rate limit window reset');
      }

      // Se atingiu limite, aguarda atÃ© o fim da janela
      if (_globalRequestCount >= _maxRequestsPerWindow) {
        final wait = _rateLimitWindow - diff;
        if (wait > Duration.zero && wait < Duration(seconds: 30)) {
          // MÃ¡ximo 30s de espera
          if (kDebugMode) {
            debugPrint(
              '[$_instanceId] Rate limit hit, waiting ${wait.inSeconds}s',
            );
          }
          _rateLimitBusy = false; // Libera antes de aguardar
          await Future.delayed(wait);

          // Tenta reaquirir lock com timeout
          attempts = 0;
          while (_rateLimitBusy && attempts < 20) {
            await Future.delayed(const Duration(milliseconds: 50));
            attempts++;
          }

          if (attempts < 20) {
            _rateLimitBusy = true; // Reaquire lock apenas se conseguiu
            _globalRequestCount = 0;
          } else {
            if (kDebugMode) {
              debugPrint(
                '[$_instanceId] Could not reacquire rate limit lock, proceeding',
              );
            }
            return;
          }
        }
      }

      _globalRequestCount++;
      _globalLastRequestTime = now;

      if (kDebugMode) {
        debugPrint(
          '[$_instanceId] Request $_globalRequestCount/$_maxRequestsPerWindow approved for instance',
        );
      }
    } finally {
      _rateLimitBusy = false;
    }
  }

  /// 🚀 v7.6.20: Sistema de Delay Adaptativo
  /// Aprende com comportamento da API e ajusta delays automaticamente
  /// Reduz tempo de geração em 40-50% quando API está rápida
  Duration _getAdaptiveDelay({required int blockNumber}) {
    // 🚀 v7.6.46: DELAYS ULTRA-OTIMIZADOS para velocidade máxima
    // Se última chamada foi sucesso RÁPIDO (< 3s atrás), delay mínimo
    if (_lastSuccessfulCall != null &&
        DateTime.now().difference(_lastSuccessfulCall!) <
            Duration(seconds: 3)) {
      _consecutiveSuccesses++;

      // Após 2 sucessos rápidos consecutivos, usar delays mínimos
      if (_consecutiveSuccesses >= 2) {
        // API está rápida - usar delays mínimos (0.3-0.8s)
        if (blockNumber <= 10) return Duration(milliseconds: 300);
        return Duration(
          milliseconds: 800,
        ); // Blocos finais precisam um pouco mais
      }
    }

    // Se teve erro 503 recente, aumentar delay progressivamente
    if (_consecutive503Errors > 0) {
      _consecutiveSuccesses = 0; // Reset sucessos
      final delaySeconds = min(
        5 * _consecutive503Errors,
        15,
      ); // Reduzido de 10s/30s para 5s/15s
      return Duration(seconds: delaySeconds);
    }

    // Padrão: delays MÍNIMOS (0.5s-2s em vez de 3s-6s)
    _consecutiveSuccesses = 0;
    _consecutive503Errors = max(0, _consecutive503Errors - 1); // Decay gradual

    if (blockNumber <= 5) return Duration(milliseconds: 500); // 0.5s
    if (blockNumber <= 15) return Duration(milliseconds: 1000); // 1s
    if (blockNumber <= 25) return Duration(milliseconds: 1500); // 1.5s
    return Duration(seconds: 2); // 2s máximo
  }

  /// Registra sucesso de chamada da API
  void _recordApiSuccess() {
    _lastSuccessfulCall = DateTime.now();
    _consecutive503Errors = max(0, _consecutive503Errors - 1); // Decay
  }

  /// Registra erro 503 da API
  void _recordApi503Error() {
    _consecutive503Errors++;
    _consecutiveSuccesses = 0;
  }

  Future<T> _retryOnRateLimit<T>(
    Future<T> Function() op, {
    int maxRetries = 6,
  }) async {
    // 🔥 AUMENTADO: Era 4, agora 6 para erro 503 (servidor indisponível)
    // RATIONALE: Erro 503 é transitório, servidor pode voltar em 30-60s
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (_isCancelled) {
          throw Exception('OperaÃ§Ã£o cancelada');
        }

        await _ensureRateLimit();

        if (_isCancelled) {
          throw Exception('OperaÃ§Ã£o cancelada');
        }

        return await op();
      } catch (e) {
        if (_isCancelled) {
          throw Exception('OperaÃ§Ã£o cancelada');
        }

        final errorStr = e.toString().toLowerCase();

        // 🔥 CORREÇÃO CRÍTICA: Tratar erro 503 (servidor indisponível) especificamente
        // Erro 503 = "Service Unavailable" (transitório, não é rate limit)
        if (errorStr.contains('503') ||
            errorStr.contains('server error') ||
            errorStr.contains('service unavailable')) {
          // 🚀 v7.6.20: Registrar erro 503 para Adaptive Delay Manager
          _recordApi503Error();

          // 🚫 v7.6.19: Fallback OpenAI REMOVIDO - respeitar seleção do usuário
          // Se usuário escolheu Gemini, usar APENAS Gemini (mesmo com erros 503)
          // Se usuário escolheu OpenAI, implementar chamada direta do OpenAI (futuro)

          if (attempt < maxRetries - 1) {
            // 🚀 v7.6.46: BACKOFF OTIMIZADO para 503:
            // Tentativa 1: 10s
            // Tentativa 2: 20s
            // Tentativa 3: 40s
            // Tentativa 4: 60s
            // Tentativa 5: 90s (cap)
            final baseDelay = 10; // OTIMIZADO: era 30s
            final exponentialDelay = baseDelay * (1 << attempt); // 2^attempt
            final delay = Duration(
              seconds: min(exponentialDelay, 90),
            ); // Cap em 90s (era 300s)

            if (kDebugMode) {
              debugPrint(
                '[$_instanceId] 🔴 ERRO 503 (Servidor Indisponível) - Aguardando ${delay.inSeconds}s antes de retry ${attempt + 2}/$maxRetries',
              );
              debugPrint(
                '[$_instanceId] 📊 Backoff otimizado: 10s → 20s → 40s → 60s → 90s',
              );
            }
            await Future.delayed(delay);
            continue;
          } else {
            // 🔥 APÓS 6 TENTATIVAS, desistir com mensagem clara
            final totalWaitTime = (10 + 20 + 40 + 60 + 90); // Total: ~3.7 min
            throw Exception(
              '🔴 ERRO CRÍTICO: Servidor do Gemini permanece indisponível após $maxRetries tentativas (~${(totalWaitTime / 60).toStringAsFixed(1)} min de espera total).\n'
              '\n'
              '💡 SOLUÇÕES POSSÍVEIS:\n'
              '  1️⃣ Aguarde 5-10 minutos e tente novamente\n'
              '  2️⃣ Troque para OpenAI GPT-4o nas configurações\n'
              '  3️⃣ Tente novamente em horário de menor tráfego\n'
              '\n'
              '📊 Seu progresso foi salvo e pode ser continuado.',
            );
          }
        }

        // 🔥 CORREÇÃO: Diferentes delays para diferentes tipos de erro
        if (errorStr.contains('429') && attempt < maxRetries - 1) {
          // 🔴 ERRO 429 (Rate Limit) = Delay otimizado progressivo
          // Tentativas: 5s, 10s, 15s, 20s, 25s, 30s
          final delay = Duration(
            seconds: (attempt + 1) * 5,
          ); // OTIMIZADO: era * 15
          if (kDebugMode) {
            debugPrint(
              '[$_instanceId] 🔴 ERRO 429 (Rate Limit) - Aguardando ${delay.inSeconds}s (tentativa ${attempt + 1}/$maxRetries)',
            );
          }
          await Future.delayed(delay);
          continue;
        }

        // ⚡ Timeout/Connection = Retry muito rápido (1s por tentativa)
        if ((errorStr.contains('timeout') || errorStr.contains('connection')) &&
            attempt < maxRetries - 1) {
          final delay = Duration(seconds: attempt + 1); // OTIMIZADO: era * 2
          if (kDebugMode) {
            debugPrint(
              '[$_instanceId] ⚡ Retry rápido (timeout/connection) - ${delay.inSeconds}s (tentativa ${attempt + 1}/$maxRetries)',
            );
          }
          await Future.delayed(delay);
          continue;
        }

        if (kDebugMode) {
          debugPrint(
            '[$_instanceId] Erro final apÃ³s $maxRetries tentativas: $e',
          );
        }
        rethrow;
      }
    }
    throw Exception(
      'Limite de tentativas excedido apÃ³s $maxRetries tentativas',
    );
  }

  // ===================== Narrativa =====================
  final List<String> _phases = const [
    'Preparação',
    'Introdução',
    'Desenvolvimento',
    'Clímax',
    'Resolução',
    'Finalização',
  ];

  int _getPhaseIndexFromProgress(double p) {
    if (p <= 0.15) return 0;
    if (p <= 0.30) return 1;
    if (p <= 0.65) return 2;
    if (p <= 0.80) return 3;
    if (p <= 0.95) return 4;
    return 5;
  }

  List<String> _generateBlockLogs(
    String phase,
    int block,
    int total,
    ScriptConfig c,
  ) {
    return [
      'Fase: $phase',
      'Bloco $block/$total',
      'Meta: ${c.quantity} ${c.measureType}',
    ];
  }

  int _getBlockDelay(int block, int total) {
    final p = block / total;
    // OTIMIZADO: Delays mínimos para maximizar velocidade (sem afetar qualidade)
    if (p <= 0.15) return 50; // Reduzido de 100ms para 50ms
    if (p <= 0.30) return 75; // Reduzido de 150ms para 75ms
    if (p <= 0.65) return 100; // Reduzido de 200ms para 100ms
    if (p <= 0.80) return 125; // Reduzido de 250ms para 125ms
    if (p <= 0.95) return 75; // Reduzido de 150ms para 75ms
    return 50; // Reduzido de 100ms para 50ms
  }

  bool _checkTargetMet(String text, ScriptConfig c) {
    if (c.measureType == 'caracteres') {
      // TOLERÃ‚NCIA ZERO: SÃ³ aceita se atingir pelo menos 99.5% da meta
      final tol = max(
        50,
        (c.quantity * 0.005).round(),
      ); // MÃ¡ximo 0.5% ou 50 chars, o que for maior
      return text.length >= (c.quantity - tol);
    }
    final wc = _countWords(text);
    // TOLERÃ‚NCIA ZERO: SÃ³ aceita se atingir pelo menos 99% da meta
    final tol = max(
      10,
      (c.quantity * 0.01).round(),
    ); // MÃ¡ximo 1% ou 10 palavras, o que for maior
    return wc >= (c.quantity - tol);
  }

  int _calculateTotalBlocks(ScriptConfig c) {
    // 🎯 NORMALIZAÇÃO: Converter tudo para palavras equivalentes
    // Isso garante que quantidades equivalentes de conteúdo recebam blocos similares
    // ⚠️ IMPORTANTE: NÃO aplicar multiplicador de idioma aqui!
    //    O multiplicador é aplicado por bloco, não no total de blocos.
    //    Caso contrário, inglês (1.05x) geraria blocos extras desnecessários.

    // 🇰🇷 AJUSTE ESPECIAL PARA COREANO: Densidade de caracteres menor
    // Hangul: 1 caractere = 1 sílaba completa → menos chars por palavra
    // Fórmula coreano: 4.2 chars/palavra (vs inglês/PT: 5.5)
    final isKoreanMeasure =
        c.language.contains('한국어') ||
        c.language.toLowerCase().contains('coreano') ||
        c.language.toLowerCase().contains('korean');

    final charToWordRatio = (c.measureType == 'caracteres' && isKoreanMeasure)
        ? 4.2 // Coreano: alta densidade silábica
        : 5.5; // Outros idiomas: padrão

    int wordsEquivalent = c.measureType == 'caracteres'
        ? (c.quantity / charToWordRatio)
              .round() // Conversão: chars → palavras
        : c.quantity;

    if (kDebugMode) {
      debugPrint('🧮 CÁLCULO DE BLOCOS (DEBUG):');
      debugPrint('   Idioma: "${c.language}"');
      debugPrint('   IsKoreanMeasure? $isKoreanMeasure');
      debugPrint('   Ratio: $charToWordRatio');
      debugPrint('   WordsEquivalent: $wordsEquivalent');
    }

    // 🌍 AJUSTE AUTOMÁTICO PARA IDIOMAS COM ALFABETOS PESADOS
    // IMPORTANTE: Este ajuste só deve ser aplicado para medida em CARACTERES!
    // Para medida em PALAVRAS, não aplicar redução (o multiplicador 1.20 já compensa)
    // Diferentes alfabetos ocupam diferentes quantidades de bytes em UTF-8
    // Ajustamos palavras equivalentes para evitar timeout de contexto em roteiros longos

    // 🔴 NÍVEL 2: Cirílico e Alfabetos Pesados - 2-3 bytes/char → Redução de 12%
    final cyrillicLanguages = [
      'Russo', 'Búlgaro', 'Sérvio', // Cirílico
    ];

    // 🔴 NÍVEL 2B: Outros Não-Latinos - 2-3 bytes/char → Redução de 15%
    // ATENÇÃO: Coreano FOI REMOVIDO desta lista (usa estratégia de blocos múltiplos)
    final otherNonLatinLanguages = [
      'Hebraico', 'Grego', 'Tailandês', // Semíticos e outros
    ];

    // 🟡 NÍVEL 1: Latinos com Diacríticos Pesados - 1.2-1.5 bytes/char → Redução de 8%
    final heavyDiacriticLanguages = [
      'Turco',
      'Polonês',
      'Tcheco',
      'Vietnamita',
      'Húngaro',
    ];

    // 🔧 CORREÇÃO: Aplicar ajuste SOMENTE para 'caracteres', nunca para 'palavras'
    // Motivo: O problema de timeout só ocorre com caracteres (tokens UTF-8)
    // Para palavras, o multiplicador 1.20 já é suficiente para compensar variação
    if (c.measureType == 'caracteres' && wordsEquivalent > 6000) {
      double adjustmentFactor = 1.0;
      String adjustmentLevel = '';

      if (cyrillicLanguages.contains(c.language)) {
        adjustmentFactor = 0.88; // -12% (AJUSTADO: era -20%)
        adjustmentLevel = 'CIRÍLICO';
      } else if (otherNonLatinLanguages.contains(c.language)) {
        adjustmentFactor = 0.85; // -15%
        adjustmentLevel = 'NÃO-LATINO';
      } else if (heavyDiacriticLanguages.contains(c.language)) {
        adjustmentFactor = 0.92; // -8% (AJUSTADO: era -10%)
        adjustmentLevel = 'DIACRÍTICOS';
      }

      if (adjustmentFactor < 1.0) {
        final originalWords = wordsEquivalent;
        wordsEquivalent = (wordsEquivalent * adjustmentFactor).round();
        if (kDebugMode) {
          debugPrint('🌍 AJUSTE $adjustmentLevel (CARACTERES): ${c.language}');
          debugPrint(
            '   $originalWords → $wordsEquivalent palavras equiv. (${(adjustmentFactor * 100).toInt()}%)',
          );
        }
      }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 🎯 v7.6.53: CHUNKING OTIMIZADO POR IDIOMA - Pipeline de Modelo Único
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //
    // ESPECIFICAÇÃO DE PALAVRAS POR BLOCO (pal/bloco):
    //   🇧🇷 PORTUGUÊS:     1.200 - 1.500 pal/bloco (verboso, latino)
    //   🇰🇷 COREANO:       600 - 800 pal/bloco (Hangul, alta densidade)
    //   🇷🇺🇧🇬 CIRÍLICOS:  900 - 1.100 pal/bloco (tokens pesados)
    //   🇹🇷 TURCO:         1.000 - 1.200 pal/bloco (aglutinante)
    //   🇵🇱 POLONÊS:       1.000 - 1.200 pal/bloco (diacríticos)
    //   🇩🇪 ALEMÃO:        1.000 - 1.200 pal/bloco (palavras compostas)
    //   🌍 LATINOS:        1.200 - 1.500 pal/bloco (EN, ES, FR, IT, RO)
    //
    // FÓRMULA: blocos = wordsEquivalent / target_pal_bloco
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    final langLower = c.language.toLowerCase();

    // 🔍 DETECÇÃO DE IDIOMA
    final isPortuguese = langLower.contains('portugu') || langLower == 'pt';
    final isKorean =
        c.language.contains('한국어') ||
        langLower.contains('coreano') ||
        langLower.contains('korean') ||
        langLower == 'ko';
    final isRussian = langLower.contains('russo') || langLower == 'ru';
    final isBulgarian =
        langLower.contains('búlgar') ||
        langLower.contains('bulgar') ||
        langLower == 'bg';
    final isCyrillic = isRussian || isBulgarian;
    final isTurkish = langLower.contains('turco') || langLower == 'tr';
    final isPolish = langLower.contains('polon') || langLower == 'pl';
    final isGerman = langLower.contains('alem') || langLower == 'de';
    // Latinos: en, es-mx, fr, it, ro (usam valores similares ao português)
    final isLatin =
        langLower.contains('inglês') ||
        langLower.contains('english') ||
        langLower == 'en' ||
        langLower.contains('espanhol') ||
        langLower.contains('español') ||
        langLower.contains('es') ||
        langLower.contains('francês') ||
        langLower.contains('français') ||
        langLower == 'fr' ||
        langLower.contains('italiano') ||
        langLower == 'it' ||
        langLower.contains('romeno') ||
        langLower.contains('român') ||
        langLower == 'ro';

    // 🎯 TARGET DE PALAVRAS POR BLOCO (centro do range)
    int targetPalBloco;
    String langCategory;

    if (isKorean) {
      targetPalBloco = 700; // 600-800 pal/bloco
      langCategory = '🇰🇷 COREANO';
    } else if (isCyrillic) {
      targetPalBloco = 1000; // 900-1100 pal/bloco
      langCategory = '🔤 CIRÍLICO';
    } else if (isTurkish) {
      targetPalBloco = 1100; // 1000-1200 pal/bloco
      langCategory = '🇹🇷 TURCO';
    } else if (isPolish) {
      targetPalBloco = 1100; // 1000-1200 pal/bloco
      langCategory = '🇵🇱 POLONÊS';
    } else if (isGerman) {
      targetPalBloco = 1100; // 1000-1200 pal/bloco
      langCategory = '🇩🇪 ALEMÃO';
    } else if (isPortuguese) {
      targetPalBloco = 1350; // 1200-1500 pal/bloco
      langCategory = '🇧🇷 PORTUGUÊS';
    } else if (isLatin) {
      targetPalBloco = 1350; // 1200-1500 pal/bloco
      langCategory = '🌍 LATINO';
    } else {
      // Fallback para idiomas não especificados
      targetPalBloco = 1200;
      langCategory = '🌐 OUTROS';
    }

    // 📊 CÁLCULO DE BLOCOS: words / target
    int calculatedBlocks = (wordsEquivalent / targetPalBloco).ceil();

    // 🔒 LIMITES DE SEGURANÇA
    // Mínimo: 2 blocos (intro + conclusão)
    // Máximo: varia por idioma para evitar erro 503
    int minBlocks = 2;
    int maxBlocks;

    if (isKorean) {
      maxBlocks = 50; // Coreano precisa de mais blocos menores
    } else if (isCyrillic) {
      maxBlocks = 30; // Cirílicos são mais pesados
    } else {
      maxBlocks = 25; // Latinos e outros são eficientes
    }

    // Aplicar limites
    int finalBlocks = calculatedBlocks.clamp(minBlocks, maxBlocks);

    // 🇰🇷 COMPENSAÇÃO COREANO: +18% blocos para compensar sub-geração natural
    if (isKorean) {
      finalBlocks = (finalBlocks * 1.18).ceil().clamp(minBlocks, maxBlocks);
    }

    if (kDebugMode) {
      final actualPalBloco = (wordsEquivalent / finalBlocks).round();
      debugPrint(
        '   $langCategory: $wordsEquivalent palavras ÷ $targetPalBloco target = $calculatedBlocks → $finalBlocks blocos (~$actualPalBloco pal/bloco)',
      );
    }

    return finalBlocks;
  }

  int _calculateTargetForBlock(int current, int total, ScriptConfig c) {
    // 🔧 CALIBRAÇÃO AJUSTADA: Multiplicador reduzido de 1.20 para 0.95 (95%)
    // PROBLEMA DETECTADO: Roteiros saindo 30% maiores (Wanessa +28%, Quitéria +30%)
    // ANÁLISE: Gemini está gerando MAIS do que o pedido, não menos
    // SOLUÇÃO: Reduzir multiplicador para evitar sobre-geração
    // Target: Ficar entre -5% e +10% do alvo (±10% aceitável)

    // 🔧 CORREÇÃO: Usar a mesma lógica de normalização que _calculateTotalBlocks
    // 🇰🇷 AJUSTE ESPECIAL PARA COREANO: Densidade de caracteres menor
    final isKoreanTarget =
        c.language.contains('한국어') ||
        c.language.toLowerCase().contains('coreano') ||
        c.language.toLowerCase().contains('korean');

    final charToWordRatio = (c.measureType == 'caracteres' && isKoreanTarget)
        ? 4.2 // Coreano: alta densidade silábica
        : 5.5; // Outros idiomas: padrão

    int targetQuantity = c.measureType == 'caracteres'
        ? (c.quantity / charToWordRatio)
              .round() // Conversão: chars → palavras
        : c.quantity;

    // 🚫 v10: REMOVIDO boost artificial
    // Lição: Gemini ignora multiplicadores - gera naturalmente
    // Solução: Usar mesma tabela de blocos do português (comprovada)

    // 🌍 Aplicar os mesmos ajustes de idioma que em _calculateTotalBlocks
    // IMPORTANTE: Só aplicar para 'caracteres', nunca para 'palavras'
    // ATENÇÃO: Coreano usa estratégia de blocos múltiplos, não redução percentual
    if (c.measureType == 'caracteres' && targetQuantity > 6000) {
      final cyrillicLanguages = ['Russo', 'Búlgaro', 'Sérvio'];
      final otherNonLatinLanguages = ['Hebraico', 'Grego', 'Tailandês'];
      final heavyDiacriticLanguages = [
        'Turco',
        'Polonês',
        'Tcheco',
        'Vietnamita',
        'Húngaro',
      ];

      if (cyrillicLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.88).round();
      } else if (otherNonLatinLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.85).round();
      } else if (heavyDiacriticLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.92).round();
      }
    }

    // 🔥 AJUSTE CRÍTICO: Multiplicador calibrado por idioma
    // HISTÓRICO:
    //   v1: 1.05 → Gerou 86.7% (déficit de -13.3%) ❌
    //   v2: 1.15 → Gerou 116% (excesso de +16%) ❌
    //   v3: 1.08 → Gerou 112% (excesso de +12%) ⚠️
    //   v4.1: 0.98 → Esperado: 98-105% (ideal) ✅
    //   v5.0: 1.08 → Gerava bem (100%+) MAS erro 503 (10 blocos grandes) ❌
    //   v6.0: 0.85 → Não dá 503 MAS gera só 82% (8700/10600) ❌
    //   v6.1: 0.95 → Ainda baixo, gera só 87% (9200/10600) ❌
    //   v6.2: 1.00 → Melhorou mas ainda 91% (9600/10600) ❌
    //   v6.3: 1.05 → Melhor, mas ainda 100% (10600) ou 77% (8500) variável ⚠️
    //   v6.4: 1.08 → Volta ao valor do v5.0 MAS ainda dá 503 com 12 blocos ❌
    //   v6.5: 1.05 → Reduz para 1.05 + AUMENTA blocos (12→14) = blocos 25% menores 🎯
    //   v7.6.42: 1.18 → Coreano específico para compensar sub-geração de ~15%
    //
    // 🇰🇷 COREANO v12: Multiplicador 1.18 para compensar sub-geração natural
    // ANÁLISE: Coreano gera apenas ~84.6% do pedido (11k de 13k)
    // SOLUÇÃO: Pedir 18% a mais para compensar
    double multiplier;
    if (isKoreanTarget) {
      multiplier = 1.18; // 🇰🇷 v12: Compensar sub-geração de ~15%
    } else if (c.language.toLowerCase().contains('portugu')) {
      multiplier = 1.05; // v6.5: Português
    } else {
      multiplier = 1.05; // Outros idiomas
    }

    // Calcular target acumulado até este bloco (com margem ajustada)
    final cumulativeTarget = (targetQuantity * (current / total) * multiplier)
        .round();

    // Calcular target acumulado do bloco anterior
    final previousCumulativeTarget = current > 1
        ? (targetQuantity * ((current - 1) / total) * multiplier).round()
        : 0;

    // DELTA = palavras necessárias NESTE bloco específico
    final baseTarget = cumulativeTarget - previousCumulativeTarget;

    // LIMITES por bloco individual (aumentado para evitar cortes)
    final maxBlockSize = c.measureType == 'caracteres' ? 15000 : 5000;

    // Para o último bloco, usar o multiplicador ajustado por idioma
    // Português: 1.05 para compensar leve sub-geração (~105% do target)
    // Outros: 0.95 para evitar sobre-geração
    if (current == total) {
      final wordsPerBlock = (targetQuantity / total).ceil();
      return min((wordsPerBlock * multiplier).round(), maxBlockSize);
    }

    return baseTarget > maxBlockSize ? maxBlockSize : baseTarget;
  }

  // ===================== Geração de Blocos =====================

  /// 🔄 WRAPPER: Chama o novo módulo BaseRules
  String _getLanguageInstruction(String l) {
    return BaseRules.getLanguageInstruction(l);
  }

  /// 🔄 WRAPPER: Chama o novo módulo BaseRules
  String _getStartInstruction(
    String language, {
    required bool withTitle,
    String? title,
  }) {
    return BaseRules.getStartInstruction(
      language,
      withTitle: withTitle,
      title: title,
    );
  }

  /// 🔄 WRAPPER: Chama o novo módulo BaseRules
  String _getContinueInstruction(String language) {
    return BaseRules.getContinueInstruction(language);
  }

  /// 🌍 Traduz labels de metadados (TEMA, SUBTEMA, etc) para o idioma selecionado
  /// 🔄 WRAPPER: Chama o novo módulo BaseRules
  Map<String, String> _getMetadataLabels(String language) {
    return BaseRules.getMetadataLabels(language);
  }

  /// 🔄 WRAPPER: Chama o novo módulo BaseRules
  String _buildLocalizationGuidance(ScriptConfig config) {
    return BaseRules.buildLocalizationGuidance(config);
  }

  void _bootstrapCharacterTracker(
    _CharacterTracker tracker,
    ScriptConfig config,
  ) {
    final names = <String>{};
    final fromProtagonist = <String>{};
    final fromSecondary = <String>{};
    final fromContext = <String>{};
    final fromTitle = <String>{};

    if (config.protagonistName.trim().isNotEmpty) {
      final name = config.protagonistName.trim();
      names.add(name);
      fromProtagonist.add(name);
    }
    if (config.secondaryCharacterName.trim().isNotEmpty) {
      final name = config.secondaryCharacterName.trim();
      names.add(name);
      fromSecondary.add(name);
    }

    // Context removido - não há mais nomes para extrair do contexto manual

    // 🎯 NOVO: Extrair gênero e relações de personagens do título
    final titleNames = _extractCharacterHintsFromTitle(config.title, '');
    names.addAll(titleNames);
    fromTitle.addAll(titleNames);

    // 🆕 CORREÇÃO BUG ALBERTO: Adicionar nomes COM papéis ao tracker
    for (final name in names) {
      // Context removido - papel não pode mais ser extraído do contexto manual

      // Para protagonista e secundário, usar papéis explícitos
      if (fromProtagonist.contains(name)) {
        tracker.addName(name, role: 'protagonista');
      } else if (fromSecondary.contains(name)) {
        tracker.addName(name, role: 'secundário');
      } else {
        tracker.addName(name, role: 'indefinido');
      }
    }

    // 📊 LOG DETALHADO: Mostrar origem de cada nome carregado
    if (kDebugMode && tracker.confirmedNames.isNotEmpty) {
      debugPrint(
        '🔐 TRACKER BOOTSTRAP - ${tracker.confirmedNames.length} nome(s) carregado(s):',
      );
      if (fromProtagonist.isNotEmpty) {
        debugPrint('   📌 Protagonista: ${fromProtagonist.join(", ")}');
      }
      if (fromSecondary.isNotEmpty) {
        debugPrint('   📌 Secundário: ${fromSecondary.join(", ")}');
      }
      if (fromContext.isNotEmpty) {
        debugPrint('   📌 Do contexto: ${fromContext.join(", ")}');
      }
      if (fromTitle.isNotEmpty) {
        debugPrint('   📌 Do título: ${fromTitle.join(", ")}');
      }
      debugPrint('   ✅ Total: ${tracker.confirmedNames.join(", ")}');
    } else if (kDebugMode) {
      debugPrint(
        '⚠️ TRACKER BOOTSTRAP: Nenhum nome inicial fornecido (será detectado no bloco 1)',
      );
    }
  }

  /// 🔄 v7.6.25: Atualiza tracker, RETORNA FALSE se houve conflito de papel
  bool _updateTrackerFromContextSnippet(
    _CharacterTracker tracker,
    ScriptConfig config,
    String snippet,
  ) {
    if (snippet.trim().isEmpty) return true; // Snippet vazio = sem erro

    bool hasRoleConflict = false; // 🚨 v7.6.25: Flag de erro

    final existingLower = tracker.confirmedNames
        .map((n) => n.toLowerCase())
        .toSet();
    final locationLower = config.localizacao.trim().toLowerCase();
    final candidateCounts = _extractNamesFromSnippet(snippet);

    candidateCounts.forEach((name, count) {
      final normalized = name.toLowerCase();
      if (existingLower.contains(normalized)) return;

      // 🔥 v7.6.31: REMOVER filtro "count < 2" - BUG CRÍTICO!
      // PROBLEMA: "Janice" com 1 menção no Bloco 2 não entrava no tracker
      // RESULTADO: "Janice" no Bloco 9 passava na validação (tracker vazio)
      // SOLUÇÃO: Adicionar TODOS os nomes válidos, independente de contagem
      // A validação isValidName() já garante que são nomes reais
      // if (count < 2) return; // ❌ REMOVIDO - causava duplicações

      if (locationLower.isNotEmpty && normalized == locationLower) return;
      if (_nameStopwords.contains(normalized)) return;

      // v7.6.63: Validação estrutural (aceita nomes do LLM)
      if (!_isLikelyName(name)) {
        if (kDebugMode) {
          debugPrint('Tracker ignorou texto invalido: "$name"');
        }
        return;
      }

      // 🆕 CORREÇÃO BUG ALBERTO: Extrair papel antes de adicionar
      final role = _extractRoleForName(name, snippet);

      if (role != null) {
        final success = tracker.addName(name, role: role); // 🚨 v7.6.25
        if (kDebugMode) {
          if (success) {
            debugPrint(
              '🔍 v7.6.31: Tracker adicionou personagem COM PAPEL: "$name" = "$role" (ocorrências: $count)',
            );
          } else {
            debugPrint('❌ v7.6.25: CONFLITO DE PAPEL detectado!');
            debugPrint('   Nome: "$name"');
            debugPrint('   Papel tentado: "$role"');
            hasRoleConflict = true; // 🚨 Marca erro
          }
        }
      } else {
        tracker.addName(name, role: 'indefinido');
        if (kDebugMode) {
          debugPrint(
            '🔍 v7.6.31: Tracker adicionou personagem SEM PAPEL: "$name" (indefinido - ocorrências: $count)',
          );
        }
      }
      if (kDebugMode) {
        debugPrint(
          '🔍 v7.6.31: Tracker adicionou personagem detectado: $name (ocorrências: $count)',
        );
      }
    });

    return !hasRoleConflict; // ✅ true = OK, ❌ false = ERRO
  }

  /// 🌍 Traduz termos de parentesco do português para o idioma do roteiro
  /// 🔄 WRAPPER: Chama o novo módulo BaseRules
  String _translateFamilyTerms(String text, String language) {
    return BaseRules.translateFamilyTerms(language, text);
  }

  String _buildCharacterGuidance(
    ScriptConfig config,
    _CharacterTracker tracker,
  ) {
    final lines = <String>[];
    final baseNames = <String>{};

    final protagonist = config.protagonistName.trim();
    if (protagonist.isNotEmpty) {
      final translatedProtagonist = _translateFamilyTerms(
        protagonist,
        config.language,
      );
      lines.add(
        '- Protagonista: "$translatedProtagonist" — mantenha exatamente este nome e sua função.',
      );
      baseNames.add(protagonist.toLowerCase());
    }

    final secondary = config.secondaryCharacterName.trim();
    if (secondary.isNotEmpty) {
      final translatedSecondary = _translateFamilyTerms(
        secondary,
        config.language,
      );
      lines.add(
        '- Personagem secundário: "$translatedSecondary" — preserve o mesmo nome em todos os blocos.',
      );
      baseNames.add(secondary.toLowerCase());
    }

    final additional =
        tracker.confirmedNames
            .where((n) => !baseNames.contains(n.toLowerCase()))
            .toList()
          ..sort((a, b) => a.compareTo(b));

    for (final name in additional) {
      // 🎯 CORRIGIDO: Adicionar personagens mencionados (não são hints de narrador)
      if (name.startsWith('PERSONAGEM MENCIONADO')) {
        // Remover marcador e traduzir termo familiar antes de adicionar ao prompt
        final cleanName = name.replaceFirst('PERSONAGEM MENCIONADO: ', '');
        final translatedName = _translateFamilyTerms(
          cleanName,
          config.language,
        );
        lines.add(
          '- Personagem mencionado: $translatedName (manter como referência familiar)',
        );
      } else {
        final translatedName = _translateFamilyTerms(name, config.language);
        lines.add(
          '- Personagem estabelecido: "$translatedName" — não altere este nome nem invente apelidos.',
        );
      }
    }

    if (lines.isEmpty) return '';

    return 'PERSONAGENS ESTABELECIDOS:\n${lines.join('\n')}\nNunca substitua esses nomes por variações ou apelidos.\n';
  }

  // 🎯 CORRIGIDO: Extrair hints de gênero/relações APENAS como contexto, NÃO como narrador
  // O título é apenas o GANCHO da história, não define quem narra!
  // Quem narra é definido por: Perspectiva + Campo Protagonista + Contexto do usuário
  Set<String> _extractCharacterHintsFromTitle(String title, String context) {
    final hints = <String>{};
    if (title.trim().isEmpty) return hints;

    final titleLower = title.toLowerCase();
    final contextLower = context.toLowerCase();

    // 🎯 DETECTAR: 1) Relações familiares e 2) Nomes próprios mencionados no título

    // 1️⃣ RELAÇÕES FAMILIARES
    final charactersInTitle = {
      'mãe': 'PERSONAGEM MENCIONADO: Mãe',
      'pai': 'PERSONAGEM MENCIONADO: Pai',
      'filho': 'PERSONAGEM MENCIONADO: Filho',
      'filha': 'PERSONAGEM MENCIONADO: Filha',
      'esposa': 'PERSONAGEM MENCIONADO: Esposa',
      'marido': 'PERSONAGEM MENCIONADO: Marido',
      'irmã': 'PERSONAGEM MENCIONADO: Irmã',
      'irmão': 'PERSONAGEM MENCIONADO: Irmão',
      'avó': 'PERSONAGEM MENCIONADO: Avó',
      'avô': 'PERSONAGEM MENCIONADO: Avô',
      'tia': 'PERSONAGEM MENCIONADO: Tia',
      'tio': 'PERSONAGEM MENCIONADO: Tio',
    };

    for (final entry in charactersInTitle.entries) {
      if (titleLower.contains(entry.key) || contextLower.contains(entry.key)) {
        hints.add(entry.value);
        if (kDebugMode) {
          debugPrint(
            '🎯 Personagem detectado no título: ${entry.key} → ${entry.value}',
          );
        }
      }
    }

    // 2️⃣ NOMES PRÓPRIOS MENCIONADOS NO TÍTULO
    // Detectar padrões como: "Você é Michael?" ou "chamado João" ou "nome: Maria"
    final namePatterns = [
      RegExp(
        r'(?:é|chamad[oa]|nome:|sou)\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+(?:\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)?)',
        caseSensitive: false,
      ),
      RegExp(r'"([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)"'), // Nomes entre aspas
      RegExp(
        r'protagonista\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in namePatterns) {
      for (final match in pattern.allMatches(title)) {
        final name = match.group(1)?.trim() ?? '';
        if (_looksLikePersonName(name) && name.length >= 3) {
          hints.add('NOME MENCIONADO NO TÍTULO: $name');
          if (kDebugMode) {
            debugPrint('🎯 Nome próprio detectado no título: $name');
          }
        }
      }
    }

    return hints;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎭 SISTEMA DE ESTILOS NARRATIVOS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Extrai ano de strings como "Ano 1890, Velho Oeste" ou "1920, Nova York"
  String _extractYear(String localizacao) {
    if (localizacao.trim().isEmpty) return '';

    // Padrões: "Ano 1890", "ano 1920", "Year 1850", "1776"
    final yearRegex = RegExp(r'(?:Ano|ano|Year|year)?\s*(\d{4})');
    final match = yearRegex.firstMatch(localizacao);

    if (match != null) {
      final year = match.group(1)!;
      final yearInt = int.tryParse(year);

      // Validar se é um ano razoável (1000-2100)
      if (yearInt != null && yearInt >= 1000 && yearInt <= 2100) {
        return year;
      }
    }

    return '';
  }

  /// Retorna lista de anacronismos a evitar baseado no ano
  List<String> _getAnachronismList(String year) {
    if (year.isEmpty) return [];

    final yearInt = int.tryParse(year);
    if (yearInt == null) return [];

    final anachronisms = <String>[];

    // Tecnologias por período (data da invenção/popularização)
    if (yearInt < 1876) anachronisms.add('Telefone (inventado em 1876)');
    if (yearInt < 1879) {
      anachronisms.add('Lâmpada elétrica (inventada em 1879)');
    }
    if (yearInt < 1886) {
      anachronisms.add('Automóvel a gasolina (inventado em 1886)');
    }
    if (yearInt < 1895) anachronisms.add('Cinema (inventado em 1895)');
    if (yearInt < 1903) anachronisms.add('Avião (inventado em 1903)');
    if (yearInt < 1920) {
      anachronisms.add('Rádio comercial (popularizado em 1920)');
    }
    if (yearInt < 1927) anachronisms.add('Cinema sonoro (1927)');
    if (yearInt < 1936) anachronisms.add('Televisão comercial (1936)');
    if (yearInt < 1946) anachronisms.add('Computador eletrônico (ENIAC 1946)');
    if (yearInt < 1950) anachronisms.add('Cartão de crédito (1950)');
    if (yearInt < 1969) anachronisms.add('Internet/ARPANET (1969)');
    if (yearInt < 1973) anachronisms.add('Telefone celular (1973)');
    if (yearInt < 1981) anachronisms.add('Computador pessoal (IBM PC 1981)');
    if (yearInt < 1983) anachronisms.add('Internet comercial (1983)');
    if (yearInt < 1991) anachronisms.add('World Wide Web (1991)');
    if (yearInt < 2001) anachronisms.add('Wikipedia (2001)');
    if (yearInt < 2004) anachronisms.add('Facebook (2004)');
    if (yearInt < 2006) anachronisms.add('Twitter (2006)');
    if (yearInt < 2007) anachronisms.add('iPhone/Smartphone moderno (2007)');

    return anachronisms;
  }

  /// Retorna elementos de época que DEVEM ser incluídos
  List<String> _getPeriodElements(String year, String? genre) {
    if (year.isEmpty) return [];

    final yearInt = int.tryParse(year);
    if (yearInt == null) return [];

    final elements = <String>[];

    // ⚔️ WESTERN (1850-1900)
    if (genre == 'western' && yearInt >= 1850 && yearInt <= 1900) {
      elements.addAll([
        'Revólver (Colt Peacemaker comum após 1873)',
        'Saloon com portas batentes',
        'Cavalo como transporte principal',
        'Diligência (stagecoach)',
        'Xerife e delegados',
        'Lei do mais rápido',
      ]);

      if (yearInt >= 1869) {
        elements.add('Ferrovia transcontinental (completada em 1869)');
      }
      if (yearInt >= 1844) {
        elements.add('Telégrafo para comunicação à distância');
      }
    }

    // 📜 ELEMENTOS GERAIS POR PERÍODO
    if (yearInt < 1850) {
      // Era pré-industrial
      elements.addAll([
        'Iluminação a vela ou lampião a óleo',
        'Transporte por carroça ou cavalo',
        'Cartas entregues por mensageiro',
        'Vestimentas formais e conservadoras',
        'Sociedade rigidamente hierárquica',
      ]);
    } else if (yearInt >= 1850 && yearInt < 1900) {
      // Era vitoriana/industrial
      elements.addAll([
        'Iluminação a gás nas cidades',
        'Trem a vapor (ferrovias em expansão)',
        'Telégrafo para comunicação',
        'Fotografia (daguerreótipo)',
        'Jornais impressos',
      ]);
    } else if (yearInt >= 1900 && yearInt < 1920) {
      // Belle Époque / Era Eduardiana
      elements.addAll([
        'Primeiros automóveis (ainda raros)',
        'Telefone fixo (casas ricas)',
        'Cinema mudo',
        'Iluminação elétrica nas cidades',
        'Fonógrafo (música gravada)',
      ]);
    } else if (yearInt >= 1920 && yearInt < 1945) {
      // Entre-guerras
      elements.addAll([
        'Rádio como principal entretenimento',
        'Cinema sonoro (após 1927)',
        'Automóveis mais comuns',
        'Telefone residencial',
        'Aviões comerciais (raros)',
      ]);
    } else if (yearInt >= 1945 && yearInt < 1970) {
      // Pós-guerra / Era de ouro
      elements.addAll([
        'Televisão em preto e branco',
        'Automóvel como padrão',
        'Eletrodomésticos modernos',
        'Cinema em cores',
        'Discos de vinil',
      ]);
    } else if (yearInt >= 1970 && yearInt < 1990) {
      // Era moderna
      elements.addAll([
        'Televisão em cores',
        'Telefone residencial fixo',
        'Fitas cassete e VHS',
        'Primeiros computadores pessoais (após 1981)',
        'Walkman (música portátil)',
      ]);
    } else if (yearInt >= 1990 && yearInt < 2007) {
      // Era digital inicial
      elements.addAll([
        'Internet discada/banda larga',
        'Celular básico (sem smartphone)',
        'E-mail',
        'CDs e DVDs',
        'Computadores pessoais comuns',
      ]);
    } else if (yearInt >= 2007 && yearInt <= 2025) {
      // Era dos smartphones
      elements.addAll([
        'Smartphone touchscreen',
        'Redes sociais (Facebook, Twitter, Instagram)',
        'Wi-Fi ubíquo',
        'Streaming de vídeo/música',
        'Apps para tudo',
      ]);
    }

    return elements;
  }

  /// Gera orientação de estilo narrativo baseado na configuração
  String _getNarrativeStyleGuidance(ScriptConfig config) {
    final style = config.narrativeStyle;

    switch (style) {
      case 'reflexivo_memorias':
        return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎭 ESTILO NARRATIVO: REFLEXIVO (MEMÓRIAS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Tom:** Nostálgico, pausado, introspectivo, suave
**Ritmo:** Lento e contemplativo, com pausas naturais
**Perspectiva emocional:** Olhar do presente para o passado com sabedoria

**ESTRUTURA NARRATIVA:**
1. Começar com gatilhos de memória: "Eu me lembro...", "Naquele tempo...", "Era uma época em que..."
2. Intercalar presente e passado sutilmente
3. Usar pausas reflexivas (reticências, silêncios)
4. Incluir detalhes sensoriais: cheiro, textura, luz, sons
5. Mencionar pequenas coisas que marcam época (objetos, costumes)

**VOCABULÁRIO:**
- Palavras suaves: "gentil", "singelo", "sutil", "delicado"
- Expressões temporais: "naqueles dias", "antigamente", "costumava"
- Verbos no imperfeito: "era", "tinha", "fazia", "lembrava"

**TÉCNICAS:**
- Digressões naturais (como alguém contando história oral)
- Comparações passado × presente
- Admitir falhas de memória: "Se não me engano...", "Creio que..."
- Tom de sabedoria adquirida com o tempo

**EXEMPLO DE NARRAÇÃO:**
"Eu me lembro... O cheiro do café coado na manhã, ainda quente na caneca de porcelana.
As mãos da minha avó, calejadas mas gentis, preparando o pão caseiro.
Naquela época, as coisas eram mais simples. Não tínhamos pressa.
O tempo... ah, o tempo parecia se mover de outra forma.
Hoje, quando sinto o aroma de café, sou transportada de volta àqueles dias..."

**EVITE:**
❌ Ação frenética ou tensão extrema
❌ Vocabulário técnico ou moderno demais
❌ Narrativa onisciente (manter ponto de vista pessoal)
❌ Tom jovial ou energia excessiva
❌ Certezas absolutas (memórias são fluidas)
''';

      case 'epico_periodo':
        final year = _extractYear(config.localizacao);
        final anachronisms = _getAnachronismList(year);
        final periodElements = _getPeriodElements(year, config.genre);

        String anachronismSection = '';
        if (anachronisms.isNotEmpty) {
          anachronismSection =
              '''

**🚨 ANACRONISMOS A EVITAR (Não existiam em $year):**
${anachronisms.map((a) => '  ❌ $a').join('\n')}
''';
        }

        String periodSection = '';
        if (periodElements.isNotEmpty) {
          periodSection =
              '''

**✅ ELEMENTOS DO PERÍODO A INCLUIR (Existiam em $year):**
${periodElements.map((e) => '  ✓ $e').join('\n')}
''';
        }

        return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚔️ ESTILO NARRATIVO: ÉPICO DE PERÍODO${year.isNotEmpty ? ' (Ano: $year)' : ''}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Tom:** Grandioso, formal, heroico, majestoso
**Ritmo:** Cadenciado e majestoso, com construção dramática
**Perspectiva:** Narrador que conhece a importância histórica dos eventos

**ESTRUTURA NARRATIVA:**
1. Descrições detalhadas e vívidas do período histórico
2. Diálogos formais e apropriados à época (sem gírias modernas)
3. Enfatizar valores, honra e códigos morais da época
4. Usar linguagem elevada mas compreensível
5. Construir tensão com descrições atmosféricas

**VOCABULÁRIO:**
- Palavras de peso: "honra", "destino", "coragem", "sacrifício"
- Descrições grandiosas: "sob o sol escaldante", "nas sombras da história"
- Evitar contrações: "não havia" em vez de "não tinha"

**TÉCNICAS:**
- Começar com estabelecimento de época e lugar
- Usar marcos históricos reais quando possível
- Descrever vestimentas, armas, tecnologia da época
- Criar senso de inevitabilidade histórica
- Pausas dramáticas antes de momentos cruciais$anachronismSection$periodSection

**EXEMPLO DE NARRAÇÃO:**
"${year.isNotEmpty ? 'No ano de $year' : 'Naquele tempo'}, sob o sol escaldante do Velho Oeste,
Jake ajustou o revólver no coldre de couro gasto. O duelo seria ao meio-dia.
A cidade inteira observava em silêncio das janelas empoeiradas,
sabendo que a justiça seria feita pela lei do mais rápido.
O vento quente soprava pela rua deserta, levantando nuvens de poeira vermelha.
Dois homens. Um código. Um destino."

**EVITE:**
❌ Anacronismos (tecnologias que não existiam na época)
❌ Gírias modernas ou linguagem informal
❌ Referências contemporâneas
❌ Tom humorístico ou irreverente
❌ Ritmo apressado (épico requer peso)
''';

      case 'educativo_curioso':
        return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 ESTILO NARRATIVO: EDUCATIVO (CURIOSIDADES)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Tom:** Entusiasta, acessível, didático, fascinante
**Ritmo:** Moderado, com pausas para absorção de conceitos
**Perspectiva:** Guia amigável que revela conhecimento surpreendente

**ESTRUTURA NARRATIVA (Framework de 4 Passos):**
1. **PERGUNTA INTRIGANTE:** Despertar curiosidade
2. **FATO SURPREENDENTE:** Resposta que causa "Uau!"
3. **EXPLICAÇÃO COM CONTEXTO:** Como/Por que funciona
4. **IMPACTO/APLICAÇÃO:** Por que isso importa

**FRASES-GATILHO (Use frequentemente):**
- "Você sabia que...?"
- "Mas aqui está o fascinante..."
- "E é por isso que..."
- "Isso explica por que..."
- "Surpreendentemente..."
- "O interessante é que..."
- "Aqui está a parte incrível..."

**TÉCNICAS DE ENGAJAMENTO:**
- Fazer perguntas retóricas para o espectador
- Usar analogias com coisas do cotidiano
- Comparações de escala (tamanho, tempo, distância)
- Fatos numéricos impressionantes
- Conexões inesperadas entre conceitos

**VOCABULÁRIO:**
- Palavras de descoberta: "revelador", "surpreendente", "fascinante"
- Verbos ativos: "descobrir", "revelar", "transformar", "conectar"
- Evitar jargão técnico SEM explicação simples

**EXEMPLO DE NARRAÇÃO:**
"Você sabia que o céu é azul por causa de um fenômeno chamado espalhamento de Rayleigh?

Mas aqui está o fascinante: quando a luz solar entra na atmosfera,
ela colide com moléculas minúsculas de ar. A luz é composta de diferentes cores,
cada uma com seu próprio comprimento de onda.

A luz azul tem ondas menores e mais curtas, então ela se espalha mais facilmente
ao colidir com as moléculas. É como jogar bolinhas de diferentes tamanhos
através de uma peneira - as menores ricocheteiam mais!

E é por isso que vemos azul durante o dia, mas laranja e vermelho no pôr do sol.
No final do dia, a luz precisa atravessar MUITO mais atmosfera,
então até as ondas maiores (vermelhas e laranjas) começam a se espalhar."

**EVITE:**
❌ Jargão técnico sem explicação
❌ Tom professoral ou autoritário ("vocês DEVEM saber...")
❌ Exemplos muito abstratos ou acadêmicos
❌ Informação sem contexto prático
❌ Monotonia (variar ritmo e entusiasmo)
''';

      case 'acao_rapida':
        return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ ESTILO NARRATIVO: AÇÃO RÁPIDA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Tom:** Urgente, intenso, visceral, adrenalina pura
**Ritmo:** FRENÉTICO - frases curtas e impactantes
**Perspectiva:** Imersão total no momento presente

**ESTRUTURA NARRATIVA:**
1. Frases CURTAS (5-10 palavras máximo)
2. Verbos de ação fortes e diretos
3. Tempo presente para imediatismo
4. Eliminação de adjetivos desnecessários
5. Foco em MOVIMENTO e IMPACTO

**TÉCNICA DE ESCRITA:**
- Cortar conjunções: "Jake corre. Pula. Rola." (não "Jake corre, pula e rola")
- Um verbo forte por frase
- Frases fragmentadas para urgência
- Pontuação agressiva: ponto final, não vírgula
- Onomatopeias quando apropriado: BAM! CRASH! BANG!

**VERBOS PREFERIDOS:**
- Movimento: corre, salta, mergulha, voa, derrapa
- Impacto: explode, estilhaça, rompe, perfura, esmaga
- Combate: ataca, esquiva, bloqueia, contra-ataca, elimina

**EXEMPLO DE NARRAÇÃO:**
"O tiro ecoa. Jake rola. Esquiva.
Vidro explode atrás dele. CRASH!
Levanta. Corre. Três passos.
Mira. Dispara. BAM!
O oponente cambaleia. Cai.
Silêncio.
Vitória."

**TÉCNICAS AVANÇADAS:**
- Frases de uma palavra para picos: "Agora." "Fogo!" "Corre!"
- Eliminar artigos: "Bala rasga ar" (não "A bala rasga o ar")
- Usar presente simples: "Ele ataca" (não "Ele está atacando")
- Staccato verbal: ritmo de metralhadora

**ESTRUTURA DE CENA DE AÇÃO:**
1. Estabelecer perigo (2 frases)
2. Reação instintiva (3-4 frases ultra-curtas)
3. Escalada (mais movimento, mais perigo)
4. Clímax (1-2 frases de impacto)
5. Resolução (1 frase de alívio)

**EVITE:**
❌ Descrições longas de cenário
❌ Reflexões filosóficas ou emocionais
❌ Diálogos extensos (máximo 3-4 palavras)
❌ Adjetivos múltiplos ("a bela e majestosa espada" → "a espada")
❌ Subordinadas complexas
❌ Explicações de motivação (ação pura)
''';

      case 'lirico_poetico':
        return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌸 ESTILO NARRATIVO: LÍRICO POÉTICO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Tom:** Melancólico, suave, contemplativo, etéreo
**Ritmo:** Cadenciado e musical, quase como versos livres
**Perspectiva:** Olhar artístico que transforma realidade em poesia

**ESTRUTURA NARRATIVA:**
1. Imagens sensoriais ricas e sinestésicas
2. Metáforas da natureza e elementos
3. Ritmo quase musical (atenção à sonoridade)
4. Simbolismo em vez de descrição direta
5. Repetições para ênfase emocional

**RECURSOS POÉTICOS:**

**Metáforas:**
- Comparar emoções com natureza: "dor como tempestade", "alegria como aurora"
- Personificar elementos: "o vento sussurra", "a noite abraça"
- Transformar concreto em abstrato: "olhos eram janelas de alma"

**Sinestesia (Misturar Sentidos):**
- "Som aveludado da voz"
- "Silêncio pesado"
- "Luz quente das palavras"
- "Sabor amargo da saudade"

**Aliteração e Assonância:**
- "Suave som do silêncio sussurra"
- "Lua lânguida lamenta"
- Atenção ao ritmo das palavras

**VOCABULÁRIO:**
- Palavras suaves: "etéreo", "efêmero", "sublime", "tênue"
- Natureza: "aurora", "crepúsculo", "orvalho", "brisa"
- Emoção profunda: "melancolia", "nostalgia", "anseio", "enlevo"

**EXEMPLO DE NARRAÇÃO:**
"A lua, pálida testemunha da noite eterna,
derramava sua luz prateada sobre os campos adormecidos.
O vento, esse mensageiro de segredos antigos,
sussurrava entre as folhas trementes das árvores.

E o tempo, esse eterno viajante sem repouso,
seguia seu curso inexorável,
levando consigo os momentos como pétalas ao vento,
enquanto as estrelas bordavam seus poemas silenciosos
no vasto manto azul do infinito."

**TÉCNICAS AVANÇADAS:**
- Repetição para ênfase: "Esperava. Sempre esperava. Como se esperar fosse seu destino."
- Frases longas e fluidas (contrário da ação rápida)
- Usar vírgulas para criar ritmo de respiração
- Imagens visuais como pinturas
- Deixar espaço para interpretação (não explicar tudo)

**ESTRUTURA EMOCIONAL:**
- Começar com imagem sensorial
- Construir camadas de significado
- Clímax emocional (não de ação)
- Resolução contemplativa ou em aberto

**EVITE:**
❌ Linguagem técnica ou prosaica
❌ Ação frenética ou violência explícita
❌ Diálogos diretos e funcionais
❌ Explicações literais
❌ Ritmo apressado ou urgente
❌ Jargão ou coloquialismo
''';

      default: // ficcional_livre
        return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📖 ESTILO NARRATIVO: FICÇÃO LIVRE (SEM RESTRIÇÕES)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Tom:** Flexível - adapta-se ao tema e gênero
**Ritmo:** Balanceado - varia conforme necessidade
**Perspectiva:** Liberdade criativa total

**ORIENTAÇÕES GERAIS:**
✓ Misturar estilos conforme necessário (ação + reflexão + descrição)
✓ Adaptar tom ao tema escolhido (drama, comédia, suspense, etc.)
✓ Usar técnicas narrativas variadas
✓ Focar em contar uma boa história sem restrições formais
✓ Priorizar engajamento e fluidez

**ESTRUTURA SUGERIDA:**
1. Estabelecimento (contexto e personagens)
2. Desenvolvimento (conflito e progressão)
3. Clímax (momento de maior tensão)
4. Resolução (desfecho satisfatório)

**FLEXIBILIDADE:**
- Pode usar diálogos extensos ou ausentes
- Pode alternar entre ação e contemplação
- Pode misturar tempos verbais se necessário
- Pode variar entre formal e coloquial

**DICA:** Use os elementos dos outros estilos conforme a cena:
- Momentos intensos? Técnicas de "Ação Rápida"
- Momentos emotivos? Toques de "Lírico Poético"
- Flashbacks? Elementos de "Reflexivo Memórias"
- Período histórico? Cuidado com anacronismos do "Épico"
- Explicar algo? Clareza do "Educativo"
''';
    }
  }

  Map<String, int> _extractNamesFromSnippet(String snippet) {
    final counts = <String, int>{};
    final regex = RegExp(
      r'\b([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+(?:\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)*)\b',
    );

    for (final match in regex.allMatches(snippet)) {
      final candidate = match.group(1)?.trim() ?? '';
      if (!_looksLikePersonName(candidate)) continue;
      final normalized = candidate.replaceAll(RegExp(r'\s+'), ' ');
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }

    return counts;
  }

  // 🔥 EXECUTAR EM ISOLATE para não travar UI
  Future<String> _filterDuplicateParagraphs(
    String existing,
    String addition,
  ) async {
    if (addition.trim().isEmpty) return '';

    // Para textos pequenos, executar direto (mais rápido que spawn isolate)
    if (existing.length < 3000 && addition.length < 1000) {
      return _filterDuplicateParagraphsSync(existing, addition);
    }

    // Textos grandes: processar em isolate separado
    return await compute(_filterDuplicateParagraphsStatic, {
      'existing': existing,
      'addition': addition,
    });
  }

  // Versão síncrona para casos rápidos
  String _filterDuplicateParagraphsSync(String existing, String addition) {
    if (addition.trim().isEmpty) return '';

    // 🚀 OTIMIZAÇÃO CRÍTICA: Comparar apenas últimos ~5000 caracteres
    final recentText = existing.length > 5000
        ? existing.substring(existing.length - 5000)
        : existing;

    final existingSet = recentText
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet();

    final seen = <String>{};
    final buffer = <String>[];

    for (final rawParagraph in addition.split(RegExp(r'\n{2,}'))) {
      final paragraph = rawParagraph.trim();
      if (paragraph.isEmpty) {
        continue;
      }

      if (existingSet.contains(paragraph)) {
        continue;
      }

      if (!seen.add(paragraph)) {
        continue;
      }

      buffer.add(paragraph);
    }

    return buffer.join('\n\n');
  }

  /// 🔍 Detecta parágrafos duplicados no roteiro final (apenas para LOG)
  /// NÃO remove nada, apenas alerta no console para debugging
  void _detectDuplicateParagraphsInFinalScript(String fullScript) {
    final paragraphs = fullScript
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final seen = <String, int>{};
    var duplicateCount = 0;

    for (var i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];

      if (seen.containsKey(paragraph)) {
        duplicateCount++;
        final firstIndex = seen[paragraph]!;
        final preview = paragraph.length > 80
            ? '${paragraph.substring(0, 80)}...'
            : paragraph;

        debugPrint('⚠️ DUPLICAÇÃO DETECTADA:');
        debugPrint(
          '   📍 Parágrafo #${firstIndex + 1} repetido no parágrafo #${i + 1}',
        );
        debugPrint('   📝 Prévia: "$preview"');
      } else {
        seen[paragraph] = i;
      }
    }

    if (duplicateCount > 0) {
      debugPrint(
        '🚨 TOTAL: $duplicateCount parágrafo(s) duplicado(s) encontrado(s) no roteiro final!',
      );
      debugPrint(
        '   💡 DICA: Fortaleça as instruções anti-repetição no prompt',
      );
    } else {
      debugPrint(
        '✅ VERIFICAÇÃO: Nenhuma duplicação de parágrafo detectada no roteiro final',
      );
    }
  }

  // 🏗️ v7.6.64: _removeDuplicateConsecutiveParagraphs removido (não era usado)

  /// 🆕 v7.6.43: Remove TODAS as duplicatas de parágrafos (não apenas consecutivas)
  /// Mantém a primeira ocorrência e remove todas as repetições posteriores
  String _removeAllDuplicateParagraphs(String fullScript) {
    final paragraphs = fullScript.split(RegExp(r'\n{2,}'));

    if (paragraphs.length < 2) return fullScript;

    final seen = <String>{};
    final seenNormalized = <String>{};
    final result = <String>[];
    var removedCount = 0;

    for (final rawParagraph in paragraphs) {
      final paragraph = rawParagraph.trim();

      if (paragraph.isEmpty) continue;

      // Normalizar para comparação (ignorar espaços extras)
      final normalized = paragraph
          .replaceAll(RegExp(r'\s+'), ' ')
          .toLowerCase();

      // Verificar duplicata exata
      if (seen.contains(paragraph)) {
        removedCount++;
        if (kDebugMode) {
          final preview = paragraph.length > 50
              ? '${paragraph.substring(0, 50)}...'
              : paragraph;
          debugPrint('🧹 REMOVIDO duplicata exata: "$preview"');
        }
        continue;
      }

      // Verificar duplicata normalizada (ignora case e espaços)
      if (seenNormalized.contains(normalized)) {
        removedCount++;
        if (kDebugMode) {
          debugPrint('🧹 REMOVIDO duplicata similar (case/espaços diferentes)');
        }
        continue;
      }

      seen.add(paragraph);
      seenNormalized.add(normalized);
      result.add(paragraph);
    }

    if (removedCount > 0) {
      debugPrint(
        '✅ v7.6.43: Total de $removedCount parágrafo(s) duplicado(s) removido(s) do roteiro final',
      );
    }

    return result.join('\n\n');
  }

  /// 🆕 v7.6.45: Cria prompt de recuperação para incorporar elementos faltantes
  /// Gera um parágrafo final que adiciona os elementos ausentes à história
  String _buildRecoveryPrompt(
    String title,
    List<String> missingElements,
    String context,
    String language,
  ) {
    // Mapear idioma para instruções
    final languageInstructions = {
      'pt': 'em português brasileiro',
      'en': 'in English',
      'es': 'en español',
      'ko': '한국어로',
    };

    final langCode = language.toLowerCase().substring(0, 2);
    final langInstruction =
        languageInstructions[langCode] ?? 'in the same language as the title';

    return '''
🎯 MISSÃO DE RECUPERAÇÃO: Adicionar elementos faltantes à história

TÍTULO ORIGINAL: "$title"

ELEMENTOS QUE AINDA NÃO APARECERAM:
${missingElements.map((e) => '❌ $e').join('\n')}

CONTEXTO FINAL DA HISTÓRIA ATÉ AGORA:
---
${context.length > 800 ? context.substring(context.length - 800) : context}
---

TAREFA:
Escreva UM PARÁGRAFO FINAL (100-150 palavras) $langInstruction que:
✅ Incorpore TODOS os elementos faltantes de forma NATURAL
✅ Seja uma continuação FLUIDA do contexto acima
✅ Mantenha coerência com a história existente
✅ NÃO repita eventos já narrados

❌ PROIBIDO:
- Começar nova história do zero
- Ignorar o contexto fornecido
- Usar "CONTINUAÇÃO:", "CONTEXTO:", etc.
- Adicionar mais de 200 palavras

APENAS o parágrafo final. Comece direto:
''';
  }

  /// 🆕 v7.6.17: Detecta e registra o nome da protagonista no Bloco 1
  /// Extrai o primeiro nome próprio encontrado e registra no tracker
  void _detectAndRegisterProtagonist(
    String generatedText,
    ScriptConfig config,
    _CharacterTracker tracker,
  ) {
    final configName = config.protagonistName.trim();
    if (configName.isEmpty) return;

    // Extrair todos os nomes do texto
    final names = _extractNamesFromText(generatedText);

    // Procurar o nome configurado
    if (names.contains(configName)) {
      tracker.setProtagonistName(configName);
      if (kDebugMode) {
        debugPrint('✅ Bloco 1: Protagonista "$configName" confirmada');
      }
    } else {
      // Se nome configurado não apareceu, pegar primeiro nome válido
      final validNames = names.where((n) => _looksLikePersonName(n)).toList();
      if (validNames.isNotEmpty) {
        final detectedName = validNames.first;
        tracker.setProtagonistName(detectedName);
        if (kDebugMode) {
          debugPrint(
            '⚠️ Bloco 1: Nome configurado "$configName" não usado, '
            'detectado "$detectedName" como protagonista',
          );
        }
      }
    }
  }

  /// 🆕 v7.6.17: Valida se protagonista manteve o mesmo nome
  /// Retorna true se mudança detectada (bloco deve ser rejeitado)
  bool _detectProtagonistNameChange(
    String generatedText,
    ScriptConfig config,
    _CharacterTracker tracker,
    int blockNumber,
  ) {
    if (blockNumber == 1) return false; // Bloco 1 sempre válido

    final registeredName = tracker.getProtagonistName();
    if (registeredName == null) return false; // Sem protagonista registrada

    // Extrair todos os nomes do bloco atual
    final currentNames = _extractNamesFromText(generatedText);

    // Verificar se protagonista registrada aparece
    final protagonistPresent = currentNames.contains(registeredName);

    // Verificar se há outros nomes válidos (possível troca)
    final otherValidNames = currentNames
        .where((n) => n != registeredName && _looksLikePersonName(n))
        .toList();

    // 🚨 DETECÇÃO: Se protagonista não apareceu MAS há outros nomes válidos
    if (!protagonistPresent && otherValidNames.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '🚨 Bloco $blockNumber: Protagonista "$registeredName" ausente!',
        );
        debugPrint('   Nomes encontrados: ${otherValidNames.join(", ")}');
        debugPrint('   ⚠️ Possível mudança de nome!');
      }

      _debugLogger.error(
        'Mudança de protagonista detectada',
        blockNumber: blockNumber,
        details:
            'Esperado "$registeredName", encontrado ${otherValidNames.join(", ")}',
        metadata: {
          'protagonistaEsperada': registeredName,
          'nomesEncontrados': otherValidNames,
        },
      );

      return true; // Bloco deve ser rejeitado
    }

    return false; // Nome consistente
  }

  /// 🚨 VALIDAÇÃO CRÍTICA: Detecta reutilização de nomes de personagens
  /// Cada personagem deve ter apenas 1 nome único
  /// Retorna true se validação passou, false se detectou erro crítico
  bool _validateProtagonistName(
    String generatedText,
    ScriptConfig config,
    int blockNumber,
  ) {
    final protagonistName = config.protagonistName.trim();
    if (protagonistName.isEmpty)
      return true; // Sem protagonista configurada = ok

    // 🚨 NOVA VALIDAÇÃO: Detectar auto-apresentações com nomes errados
    // Padrões: "my name is X", "i'm X", "call me X"
    final nameIntroPatterns = [
      RegExp(r'my name is ([A-Z][a-z]+)', caseSensitive: false),
      RegExp(r"i'm ([A-Z][a-z]+)", caseSensitive: false),
      RegExp(r'call me ([A-Z][a-z]+)', caseSensitive: false),
      RegExp(r"i am ([A-Z][a-z]+)", caseSensitive: false),
    ];

    for (final pattern in nameIntroPatterns) {
      final match = pattern.firstMatch(generatedText);
      if (match != null) {
        final introducedName = match.group(1);
        if (introducedName != null &&
            introducedName.toLowerCase() != protagonistName.toLowerCase()) {
          _log(
            '🚨 ERRO CRÍTICO: AUTO-APRESENTAÇÃO COM NOME ERRADO!',
            level: 'critical',
          );
          _log(
            '   ❌ Protagonista configurada: "$protagonistName"',
            level: 'critical',
          );
          _log(
            '   ❌ Nome na auto-apresentação: "$introducedName"',
            level: 'critical',
          );
          _log('   📝 Trecho: "${match.group(0)}"', level: 'critical');
          _log('   🔄 BLOCO SERÁ REJEITADO E REGENERADO', level: 'critical');

          return false; // 🚨 REJEITAR BLOCO
        }
      }
    }

    // 🔥 PARTE 1: Validar protagonista específica
    final suspiciousNames = [
      'Wanessa',
      'Carla',
      'Beatriz',
      'Fernanda',
      'Juliana',
      'Mariana',
      'Patrícia',
      'Roberta',
      'Silvia',
      'Tatiana',
      'Carlos',
      'Eduardo',
      'Fernando',
      'Gustavo',
      'Henrique',
      'Leonardo',
      'Marcelo',
      'Rafael',
      'Rodrigo',
      'Thiago',
      // Nomes comuns em inglês (caso do roteiro gerado)
      'Hannah',
      'Laura',
      'Jessica',
      'Sarah',
      'Emily',
      'Emma',
      'Olivia',
      'Sophia',
      'Michael',
      'David',
      'James',
      'John',
      'Robert',
    ];

    final hasProtagonist = generatedText.contains(protagonistName);

    for (final suspiciousName in suspiciousNames) {
      if (suspiciousName.toLowerCase() == protagonistName.toLowerCase()) {
        continue; // Nome suspeito é o próprio protagonista configurado
      }

      if (generatedText.contains(suspiciousName)) {
        // 🐛 DEBUG: Log erro crítico de nome
        _debugLogger.error(
          "Troca de nome detectada: '$suspiciousName'",
          blockNumber: blockNumber,
          details:
              "Protagonista deveria ser '$protagonistName' mas encontrei '$suspiciousName'",
          metadata: {
            'protagonista': protagonistName,
            'nomeEncontrado': suspiciousName,
          },
        );

        _log(
          '🚨 ERRO CRÍTICO DETECTADO NO BLOCO $blockNumber:',
          level: 'critical',
        );
        _log(
          '   ❌ Protagonista deveria ser: "$protagonistName"',
          level: 'critical',
        );
        _log(
          '   ❌ Mas encontrei nome suspeito: "$suspiciousName"',
          level: 'critical',
        );
        _log(
          '   ⚠️ POSSÍVEL TROCA DE NOME DA PROTAGONISTA!',
          level: 'critical',
        );
        _log('   🔄 BLOCO SERÁ REJEITADO E REGENERADO', level: 'critical');

        return false; // 🚨 REJEITAR BLOCO
      }
    }

    if (!hasProtagonist && blockNumber <= 2) {
      // 🐛 DEBUG: Log aviso de protagonista ausente
      _debugLogger.warning(
        "Protagonista ausente",
        details: "'$protagonistName' não apareceu no bloco $blockNumber",
        metadata: {'bloco': blockNumber, 'protagonista': protagonistName},
      );

      debugPrint(
        '⚠️ AVISO: Protagonista "$protagonistName" não apareceu no bloco $blockNumber',
      );
    } else if (hasProtagonist) {
      // 🐛 DEBUG: Log validação bem-sucedida
      _debugLogger.validation(
        "Protagonista validada",
        blockNumber: blockNumber,
        details: "'$protagonistName' presente no bloco",
        metadata: {'protagonista': protagonistName},
      );
    }

    return true; // Validação passou
  }

  /// 🆕 v7.6.22: VALIDAÇÃO DE RELACIONAMENTOS FAMILIARES
  /// Detecta contradições lógicas em árvores genealógicas
  /// Retorna true se relacionamentos são consistentes, false se há erros
  bool _validateFamilyRelationships(String text, int blockNumber) {
    if (text.isEmpty) return true;

    // Mapa de relacionamentos encontrados: pessoa → relação → pessoa relacionada
    final Map<String, Map<String, Set<String>>> relationships = {};

    // Padrões de relacionamentos em múltiplos idiomas
    final patterns = {
      // Português
      'marido': RegExp(
        r'meu marido(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'esposa': RegExp(
        r'minha esposa(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'pai': RegExp(r'meu pai(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
      'mãe': RegExp(r'minha mãe(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
      'irmão': RegExp(r'meu irmão(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
      'irmã': RegExp(r'minha irmã(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
      'sogro': RegExp(r'meu sogro(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
      'sogra': RegExp(
        r'minha sogra(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'cunhado': RegExp(
        r'meu cunhado(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'cunhada': RegExp(
        r'minha cunhada(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'genro': RegExp(r'meu genro(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
      'nora': RegExp(r'minha nora(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
      'neto': RegExp(r'meu neto(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
      'neta': RegExp(r'minha neta(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
      'avô': RegExp(r'meu avô(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
      'avó': RegExp(r'minha avó(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),

      // Inglês
      'husband_en': RegExp(
        r'my husband(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'wife_en': RegExp(r'my wife(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
      'father_en': RegExp(
        r'my father(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'mother_en': RegExp(
        r'my mother(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'brother_en': RegExp(
        r'my brother(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'sister_en': RegExp(
        r'my sister(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'father_in_law_en': RegExp(
        r'my father-in-law(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'mother_in_law_en': RegExp(
        r'my mother-in-law(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'brother_in_law_en': RegExp(
        r'my brother-in-law(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'sister_in_law_en': RegExp(
        r'my sister-in-law(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'son_in_law_en': RegExp(
        r'my son-in-law(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'daughter_in_law_en': RegExp(
        r'my daughter-in-law(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'grandson_en': RegExp(
        r'my grandson(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'granddaughter_en': RegExp(
        r'my granddaughter(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'grandfather_en': RegExp(
        r'my grandfather(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
      'grandmother_en': RegExp(
        r'my grandmother(?:,)?\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),

      // Padrões de casamento (detectar quem casa com quem)
      'married_to': RegExp(
        r'([A-Z][a-z]+)\s+(?:casou com|married|se casou com)\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
    };

    // Extrair relacionamentos do texto
    for (final entry in patterns.entries) {
      final relationType = entry.key;
      final pattern = entry.value;

      for (final match in pattern.allMatches(text)) {
        final name = match.group(1);
        if (name != null) {
          relationships.putIfAbsent('protagonist', () => {});
          relationships['protagonist']!.putIfAbsent(relationType, () => {});
          relationships['protagonist']![relationType]!.add(name);
        }
      }
    }

    // Validar relacionamentos lógicos
    bool hasError = false;

    // REGRA 1: Se X é meu cunhado/cunhada, então:
    //   - X deve ser irmão/irmã do meu cônjuge OU
    //   - X deve ser cônjuge do meu irmão/irmã
    final brotherInLaw = relationships['protagonist']?['cunhado'] ?? {};
    final sisterInLaw = relationships['protagonist']?['cunhada'] ?? {};
    final husband = relationships['protagonist']?['marido'] ?? {};
    final wife = relationships['protagonist']?['esposa'] ?? {};
    final brother = relationships['protagonist']?['irmão'] ?? {};
    final sister = relationships['protagonist']?['irmã'] ?? {};

    for (final inLaw in [...brotherInLaw, ...sisterInLaw]) {
      // Se X é cunhado mas nunca mencionamos cônjuge nem irmãos = ERRO
      if (husband.isEmpty &&
          wife.isEmpty &&
          brother.isEmpty &&
          sister.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '🚨 ERRO: $inLaw é cunhado/cunhada mas não há cônjuge nem irmãos mencionados!',
          );
        }
        hasError = true;
      }
    }

    // REGRA 2: Se X é meu sogro/sogra, então:
    //   - Eu DEVO ter cônjuge (marido/esposa)
    //   - X deve ser pai/mãe do meu cônjuge
    final fatherInLaw = relationships['protagonist']?['sogro'] ?? {};
    final motherInLaw = relationships['protagonist']?['sogra'] ?? {};

    if (fatherInLaw.isNotEmpty || motherInLaw.isNotEmpty) {
      if (husband.isEmpty && wife.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '🚨 ERRO: Tem sogro/sogra mas protagonista não tem cônjuge!',
          );
          debugPrint('   ❌ Se X é sogro, protagonista DEVE ter esposa/marido');
        }
        hasError = true;
      }
    }

    // REGRA 3: Se X é meu genro/nora, então:
    //   - Eu DEVO ter filho/filha
    //   - X deve ser cônjuge do meu filho/filha
    final sonInLaw = relationships['protagonist']?['genro'] ?? {};
    final daughterInLaw = relationships['protagonist']?['nora'] ?? {};

    if (sonInLaw.isNotEmpty || daughterInLaw.isNotEmpty) {
      // Verificar se menciona filhos (procurar padrão mais amplo)
      final hasChildren = text.contains(
        RegExp(
          r'meu filho|minha filha|my son|my daughter',
          caseSensitive: false,
        ),
      );

      if (!hasChildren) {
        if (kDebugMode) {
          debugPrint('🚨 ERRO: Tem genro/nora mas não menciona filhos!');
          debugPrint(
            '   ❌ Se X é genro/nora, protagonista DEVE ter filho/filha',
          );
        }
        hasError = true;
      }
    }

    // REGRA 4: Se X é meu neto/neta, então:
    //   - Eu DEVO ter filhos
    //   - X deve ser filho/filha dos meus filhos
    final grandson = relationships['protagonist']?['neto'] ?? {};
    final granddaughter = relationships['protagonist']?['neta'] ?? {};

    if (grandson.isNotEmpty || granddaughter.isNotEmpty) {
      final hasChildren = text.contains(
        RegExp(
          r'meu filho|minha filha|my son|my daughter',
          caseSensitive: false,
        ),
      );

      if (!hasChildren) {
        if (kDebugMode) {
          debugPrint('🚨 ERRO: Tem neto/neta mas não menciona filhos!');
          debugPrint(
            '   ❌ Se X é neto/neta, protagonista DEVE ter filho/filha',
          );
        }
        hasError = true;
      }
    }

    // REGRA 5: Detectar contradições com sufixos -in-law
    // Exemplo: "my brother Paul married Megan" + "my father-in-law Alan"
    // Se Megan é filha de Alan, então Alan é sogro de Paul (não do protagonista)
    final marriedPattern = RegExp(
      r'my (brother|sister)(?:,)?\s+([A-Z][a-z]+)\s+(?:married|casou com)\s+([A-Z][a-z]+)',
      caseSensitive: false,
    );

    for (final match in marriedPattern.allMatches(text)) {
      final sibling = match.group(2); // Nome do irmão/irmã
      final spouse = match.group(3); // Nome do cônjuge do irmão/irmã

      if (sibling != null && spouse != null) {
        // Se texto diz "X's father Alan" ou "father of X"
        final parentPattern = RegExp(
          r'(?:' +
              spouse +
              r"'s father|father of " +
              spouse +
              r'|pai de ' +
              spouse +
              r')(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        );

        for (final parentMatch in parentPattern.allMatches(text)) {
          final parentName = parentMatch.group(1);

          // Se esse pai foi chamado de "my father-in-law" = ERRO
          if (parentName != null && fatherInLaw.contains(parentName)) {
            if (kDebugMode) {
              debugPrint('🚨 ERRO DE RELACIONAMENTO GENEALÓGICO!');
              debugPrint(
                '   ❌ $parentName é pai de $spouse (cônjuge de $sibling)',
              );
              debugPrint(
                '   ❌ Mas texto chama $parentName de "my father-in-law"',
              );
              debugPrint(
                '   ✅ CORRETO seria: "$parentName é sogro do meu irmão $sibling"',
              );
            }
            hasError = true;
          }
        }
      }
    }

    if (hasError) {
      if (kDebugMode) {
        debugPrint(
          '❌ BLOCO $blockNumber REJEITADO: Relacionamentos familiares inconsistentes!',
        );
        debugPrint(
          '   🔄 Forçando regeneração com lógica genealógica correta...',
        );
      }
    }

    return !hasError; // Retorna true se não há erros
  }

  /// 🆕 EXTRAÇÃO DE PAPEL: Identifica o papel/relação de um nome em um texto
  /// Retorna o primeiro papel encontrado ou null se não detectar nenhum
  /// 🆕 v7.6.28: Valida se há nomes duplicados em papéis diferentes
  /// 🔥 v7.6.32: NOVA VALIDAÇÃO - Detecta quando MESMO PAPEL tem NOMES DIFERENTES
  /// 🆕 v7.6.33: PAPÉIS POSSESSIVOS SINGULARES - Detecta "my lawyer" como papel único
  /// 🔥 v7.6.34: FIX MULTI-WORD ROLES - Corrige detecção de "executive assistant", "financial advisor"
  ///
  /// OBJETIVO 1 (v7.6.28): Detectar quando MESMO NOME aparece para PERSONAGENS DIFERENTES
  /// EXEMPLO RUIM: "Mark" como boyfriend + "Mark" como attorney
  ///
  /// OBJETIVO 2 (v7.6.32): Detectar quando MESMO PAPEL é atribuído a NOMES DIFERENTES
  /// EXEMPLO RUIM: "Ashley" como protagonista + "Emily" como protagonista
  ///
  /// OBJETIVO 3 (v7.6.33/34): Detectar quando PAPEL POSSESSIVO tem NOMES DIFERENTES
  /// EXEMPLOS RUINS:
  ///   - "my lawyer, Richard" (Bloco 5) → "my lawyer, Mark" (Bloco 10)
  ///   - "my executive assistant, Lauren" (Bloco 7) → "my executive assistant, Danielle" (Bloco 12)
  /// LÓGICA: "my X" = possessivo singular = papel único (não pode ter múltiplos)
  /// 🔥 v7.6.34: Agora captura corretamente multi-word roles (executive assistant, financial advisor, etc.)
  ///
  /// Retorna TRUE se houver conflito (bloco deve ser rejeitado)
  /// Retorna FALSE se nomes são únicos (bloco pode ser aceito)
  bool _validateUniqueNames(
    String blockText,
    _CharacterTracker tracker,
    int blockNumber,
  ) {
    if (blockText.trim().isEmpty) return false; // Texto vazio = sem erro

    // Extrair nomes do bloco atual
    final namesInBlock = _extractNamesFromText(blockText);

    // Verificar cada nome extraído
    for (final name in namesInBlock) {
      // ═══════════════════════════════════════════════════════════════
      // VALIDAÇÃO 1 (v7.6.28): MESMO NOME em PAPÉIS DIFERENTES
      // ═══════════════════════════════════════════════════════════════
      if (tracker.hasName(name)) {
        // Nome já existe - verificar se é o MESMO personagem ou REUSO indevido

        // Extrair papel atual deste nome no bloco
        final currentRole = _extractRoleForName(name, blockText);

        // Extrair papel registrado anteriormente
        final previousRole = tracker.getRole(name);

        if (currentRole != null && previousRole != null) {
          // Normalizar papéis para comparação
          final normalizedCurrent = _normalizeRole(currentRole);
          final normalizedPrevious = _normalizeRole(previousRole);

          // Se papéis são DIFERENTES = NOME DUPLICADO (ERRO!)
          if (normalizedCurrent != normalizedPrevious &&
              normalizedCurrent != 'indefinido' &&
              normalizedPrevious != 'indefinido') {
            if (kDebugMode) {
              debugPrint('🚨🚨🚨 v7.6.28: NOME DUPLICADO DETECTADO! 🚨🚨🚨');
              debugPrint('   ❌ Nome: "$name"');
              debugPrint(
                '   ❌ Papel anterior: "$previousRole" → "$normalizedPrevious"',
              );
              debugPrint(
                '   ❌ Papel atual: "$currentRole" → "$normalizedCurrent"',
              );
              debugPrint(
                '   💡 EXEMPLO DO BUG: "Mark" sendo boyfriend E attorney!',
              );
              debugPrint(
                '   🔄 Bloco $blockNumber será REJEITADO e REGENERADO',
              );
              debugPrint('🚨🚨🚨 FIM DO ALERTA 🚨🚨🚨');
            }

            _debugLogger.error(
              "Nome duplicado em papéis diferentes - Bloco $blockNumber",
              blockNumber: blockNumber,
              details:
                  "Nome '$name': papel anterior '$previousRole', papel atual '$currentRole'",
              metadata: {
                'nome': name,
                'papelAnterior': previousRole,
                'papelAtual': currentRole,
              },
            );

            return true; // ❌ CONFLITO DETECTADO
          }
        }
      }

      // ═══════════════════════════════════════════════════════════════
      // 🔥 VALIDAÇÃO 2 (v7.6.32): MESMO PAPEL em NOMES DIFERENTES
      // ═══════════════════════════════════════════════════════════════
      final currentRole = _extractRoleForName(name, blockText);

      if (currentRole != null && currentRole != 'indefinido') {
        final normalizedCurrent = _normalizeRole(currentRole);

        // Verificar se este PAPEL já existe com um NOME DIFERENTE
        for (final existingName in tracker.confirmedNames) {
          if (existingName.toLowerCase() == name.toLowerCase()) {
            continue; // Mesmo nome = OK (já validado acima)
          }

          final existingRole = tracker.getRole(existingName);
          if (existingRole == null) continue;

          final normalizedExisting = _normalizeRole(existingRole);

          // 🎯 PAPÉIS CRÍTICOS que DEVEM ser únicos (1 nome por papel)
          final uniqueRoles = {
            'protagonista',
            'protagonist',
            'main character',
            'narradora',
            'narrador',
            'narrator',
            'hero',
            'heroine',
            'herói',
            'heroína',
          };

          // Se MESMO PAPEL com NOMES DIFERENTES = ERRO CRÍTICO!
          if (normalizedCurrent == normalizedExisting) {
            // Verificar se é papel crítico que deve ser único
            bool isCriticalRole = false;
            for (final uniqueRole in uniqueRoles) {
              if (normalizedCurrent.contains(uniqueRole) ||
                  normalizedExisting.contains(uniqueRole)) {
                isCriticalRole = true;
                break;
              }
            }

            if (isCriticalRole) {
              if (kDebugMode) {
                debugPrint('🚨🚨🚨 v7.6.32: PAPEL DUPLICADO DETECTADO! 🚨🚨🚨');
                debugPrint('   ❌ Papel: "$currentRole" → "$normalizedCurrent"');
                debugPrint('   ❌ Nome anterior: "$existingName"');
                debugPrint('   ❌ Nome atual: "$name"');
                debugPrint(
                  '   💡 EXEMPLO DO BUG: "Ashley" sendo protagonista E "Emily" sendo protagonista!',
                );
                debugPrint(
                  '   🔄 Bloco $blockNumber será REJEITADO e REGENERADO',
                );
                debugPrint('🚨🚨🚨 FIM DO ALERTA 🚨🚨🚨');
              }

              _debugLogger.error(
                "Papel duplicado com nomes diferentes - Bloco $blockNumber",
                blockNumber: blockNumber,
                details:
                    "Papel '$currentRole': nome anterior '$existingName', nome atual '$name'",
                metadata: {
                  'papel': currentRole,
                  'nomeAnterior': existingName,
                  'nomeAtual': name,
                },
              );

              return true; // ❌ CONFLITO CRÍTICO DETECTADO
            }
          }
        }
      }

      // ═══════════════════════════════════════════════════════════════
      // 🆕 VALIDAÇÃO 3 (v7.6.33): PAPÉIS POSSESSIVOS SINGULARES
      // ═══════════════════════════════════════════════════════════════
      // OBJETIVO: Detectar papéis únicos indicados por possessivos singulares
      // EXEMPLO RUIM: "my lawyer, Richard" (Bloco 5) → "my lawyer, Mark" (Bloco 10)
      //
      // Quando texto usa "my X" (possessive singular), indica papel único
      // Não pode haver múltiplas instâncias: "my lawyer" = apenas 1 advogado
      //
      // 🔍 Detecta padrões:
      // - "my lawyer", "my attorney", "my doctor"
      // - "my therapist", "my accountant", "my agent"
      // - "my boss", "my mentor", "my partner"
      //
      // ⚠️ IMPORTANTE: "my lawyers" (plural) NÃO é considerado único
      // ═══════════════════════════════════════════════════════════════

      // Padrão para detectar possessivos singulares
      // Captura: "my [role]" mas NÃO "my [role]s" (plural)
      // 🔥 v7.6.34: EXPANDIDO para capturar multi-word roles (executive assistant, financial advisor, etc.)
      final possessiveSingularPattern = RegExp(
        r'\b(?:my|nossa)\s+(?:executive\s+assistant|personal\s+assistant|financial\s+advisor|real\s+estate\s+agent|estate\s+planner|tax\s+advisor|makeup\s+artist|physical\s+therapist|occupational\s+therapist|speech\s+therapist|au\s+pair|dalai\s+lama|vice[-\s]president|lawyer|attorney|doctor|therapist|accountant|agent|boss|mentor|partner|adviser|advisor|consultant|coach|teacher|tutor|counselor|psychologist|psychiatrist|dentist|surgeon|specialist|physician|nurse|caregiver|assistant|secretary|manager|supervisor|director|ceo|cfo|cto|president|chairman|investor|banker|auditor|notary|mediator|arbitrator|investigator|detective|officer|sergeant|captain|lieutenant|judge|magistrate|prosecutor|defender|guardian|curator|executor|trustee|beneficiary|architect|engineer|contractor|builder|designer|decorator|landscaper|gardener|housekeeper|maid|butler|chef|cook|driver|chauffeur|pilot|navigator|guide|translator|interpreter|editor|publisher|producer|publicist|stylist|hairdresser|barber|beautician|esthetician|masseuse|trainer|nutritionist|dietitian|pharmacist|optometrist|veterinarian|groomer|walker|sitter|nanny|governess|babysitter|midwife|doula|chiropractor|acupuncturist|hypnotist|healer|shaman|priest|pastor|minister|rabbi|imam|monk|nun|chaplain|deacon|elder|bishop|archbishop|cardinal|pope|guru|sensei|sifu|master|grandmaster)(?![a-z])',
        caseSensitive: false,
      );

      final possessiveMatches = possessiveSingularPattern.allMatches(blockText);

      for (final match in possessiveMatches) {
        // 🔥 v7.6.34: Captura o grupo completo (incluindo multi-word roles)
        final possessiveRole = match
            .group(0)
            ?.replaceFirst(
              RegExp(r'\b(?:my|nossa)\s+', caseSensitive: false),
              '',
            )
            .toLowerCase()
            .trim();

        if (possessiveRole == null || possessiveRole.isEmpty) continue;

        // Verificar se JÁ existe este papel possessivo com NOME DIFERENTE
        for (final existingName in tracker.confirmedNames) {
          if (existingName.toLowerCase() == name.toLowerCase()) {
            continue; // Mesmo nome = OK
          }

          final existingRole = tracker.getRole(existingName);
          if (existingRole == null) continue;

          final normalizedExisting = _normalizeRole(existingRole).toLowerCase();

          // 🔥 v7.6.34: Match exato ou contém o papel completo (executive assistant, etc.)
          final possessiveRoleNormalized = possessiveRole.replaceAll(
            RegExp(r'\s+'),
            ' ',
          );

          // Verificar se papel possessivo já existe
          if (normalizedExisting.contains(possessiveRoleNormalized) ||
              possessiveRoleNormalized.contains(
                normalizedExisting.split(' ').last,
              )) {
            if (kDebugMode) {
              debugPrint(
                '🚨🚨🚨 v7.6.34: PAPEL POSSESSIVO SINGULAR DUPLICADO! 🚨🚨🚨',
              );
              debugPrint('   ❌ Papel possessivo: "my $possessiveRole"');
              debugPrint(
                '   ❌ Nome anterior: "$existingName" (papel: "$existingRole")',
              );
              debugPrint('   ❌ Nome atual: "$name"');
              debugPrint('   💡 EXEMPLOS DO BUG:');
              debugPrint('      - "my lawyer, Richard" → "my lawyer, Mark"');
              debugPrint(
                '      - "my executive assistant, Lauren" → "my executive assistant, Danielle"',
              );
              debugPrint(
                '   💡 "my X" indica papel ÚNICO - não pode haver múltiplos!',
              );
              debugPrint(
                '   🔄 Bloco $blockNumber será REJEITADO e REGENERADO',
              );
              debugPrint('🚨🚨🚨 FIM DO ALERTA 🚨🚨🚨');
            }

            _debugLogger.error(
              "Papel possessivo singular duplicado - Bloco $blockNumber",
              blockNumber: blockNumber,
              details:
                  "'my $possessiveRole': nome anterior '$existingName', nome atual '$name'",
              metadata: {
                'papelPossessivo': possessiveRole,
                'nomeAnterior': existingName,
                'nomeAtual': name,
              },
            );

            return true; // ❌ CONFLITO POSSESSIVO DETECTADO
          }
        }
      }
    }

    return false; // ✅ Nenhum conflito de nomes ou papéis
  }

  /// 🔧 v7.6.26: Normaliza papel SELETIVAMENTE (evita falsos positivos)
  ///
  /// PAPÉIS FAMILIARES: Mantém completo "mãe de Emily" ≠ "mãe de Michael"
  /// PAPÉIS GENÉRICOS: Normaliza "advogado de Sarah" → "advogado"
  ///
  /// Exemplo:
  /// - "mãe de Emily" → "mãe de emily" (mantém relação)
  /// - "irmão de João" → "irmão de joão" (mantém relação)
  /// - "advogado de Sarah" → "advogado" (remove relação)
  /// - "médico de Michael" → "médico" (remove relação)
  String _normalizeRole(String role) {
    final roleLower = role.toLowerCase().trim();

    // 🔥 v7.6.26: PAPÉIS FAMILIARES - NÃO normalizar (manter contexto familiar)
    // Permite múltiplas famílias na mesma história sem falsos positivos
    final familyRoles = [
      'mãe',
      'pai',
      'filho',
      'filha',
      'irmão',
      'irmã',
      'avô',
      'avó',
      'tio',
      'tia',
      'primo',
      'prima',
      'sogro',
      'sogra',
      'cunhado',
      'cunhada',
      'mother',
      'father',
      'son',
      'daughter',
      'brother',
      'sister',
      'grandfather',
      'grandmother',
      'uncle',
      'aunt',
      'cousin',
      'father-in-law',
      'mother-in-law',
      'brother-in-law',
      'sister-in-law',
      'mère',
      'père',
      'fils',
      'fille',
      'frère',
      'sœur',
      'grand-père',
      'grand-mère',
      'oncle',
      'tante',
      'cousin',
      'cousine',
    ];

    // Verificar se é papel familiar
    for (final familyRole in familyRoles) {
      if (roleLower.contains(familyRole)) {
        // ✅ MANTER COMPLETO: "mãe de Emily" permanece "mãe de emily"
        // Isso permite Sarah ser "mãe de Emily" e Jennifer ser "mãe de Michael"
        if (kDebugMode) {
          debugPrint(
            '👨‍👩‍👧‍👦 v7.6.26: Papel familiar detectado, mantendo completo: "$roleLower"',
          );
        }
        return roleLower;
      }
    }

    // 🔧 PAPÉIS GENÉRICOS: Normalizar (remover sufixo "de [Nome]")
    // "advogado de Sarah" → "advogado"
    // "médico de João" → "médico"
    final normalized = roleLower
        .replaceAll(RegExp(r'\s+de\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇa-záàâãéêíóôõúç]+.*$'), '')
        .trim();

    if (kDebugMode && normalized != roleLower) {
      debugPrint(
        '🔧 v7.6.26: Papel genérico normalizado: "$roleLower" → "$normalized"',
      );
    }

    return normalized;
  }

  String? _extractRoleForName(String name, String text) {
    // Padrões para detectar relações familiares e sociais
    final rolePatterns = {
      'marido': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:marido|esposo)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'esposa': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:esposa|mulher)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'pai': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Pp]ai(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'mãe': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Mm]ãe(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'filho': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Ff]ilho(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'filha': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Ff]ilha(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'irmão': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:irmão|irmao)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'irmã': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:irmã|irma)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'sogro': RegExp(
        r'(?:meu|seu|nosso|o)\s+sogro(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'sogra': RegExp(
        r'(?:minha|sua|nossa|a)\s+sogra(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'cunhado': RegExp(
        r'(?:meu|seu|nosso|o)\s+cunhado(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'cunhada': RegExp(
        r'(?:minha|sua|nossa|a)\s+cunhada(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'nora': RegExp(
        r'(?:minha|sua|nossa|a)\s+nora(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'genro': RegExp(
        r'(?:meu|seu|nosso|o)\s+genro(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'amigo': RegExp(
        r'(?:meu|seu|nosso|o)\s+amigo(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'amiga': RegExp(
        r'(?:minha|sua|nossa|a)\s+amiga(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'vizinho': RegExp(
        r'(?:o|um)\s+vizinho(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'vizinha': RegExp(
        r'(?:a|uma)\s+vizinha(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'tio': RegExp(
        r'(?:meu|seu|o)\s+[Tt]io(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'tia': RegExp(
        r'(?:minha|sua|a)\s+[Tt]ia(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'avô': RegExp(
        r'(?:meu|seu|o)\s+avô(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'avó': RegExp(
        r'(?:minha|sua|a)\s+avó(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'neto': RegExp(
        r'(?:meu|seu|o)\s+neto(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'neta': RegExp(
        r'(?:minha|sua|a)\s+neta(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'primo': RegExp(
        r'(?:meu|seu|o)\s+primo(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'prima': RegExp(
        r'(?:minha|sua|a)\s+prima(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
    };

    // Retornar primeiro papel encontrado (português)
    for (final entry in rolePatterns.entries) {
      if (entry.value.hasMatch(text)) {
        return entry.key;
      }
    }

    // 🆕 v7.6.36: Padrões em INGLÊS para detectar papéis
    final englishPatterns = {
      'father': RegExp(
        r'(?:my|his|her|our|the)\s+(?:father|dad)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'mother': RegExp(
        r'(?:my|his|her|our|the)\s+(?:mother|mom|mum)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'sister': RegExp(
        r'(?:my|his|her|our|the)\s+sister(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'brother': RegExp(
        r'(?:my|his|her|our|the)\s+brother(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'husband': RegExp(
        r'(?:my|her|our|the)\s+husband(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'wife': RegExp(
        r'(?:my|his|our|the)\s+wife(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'boyfriend': RegExp(
        r'(?:my|her|the)\s+(?:boyfriend|fianc[eé])(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'girlfriend': RegExp(
        r'(?:my|his|the)\s+(?:girlfriend|fianc[eé]e)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'uncle': RegExp(
        r'(?:my|his|her|our|the)\s+uncle(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'aunt': RegExp(
        r'(?:my|his|her|our|the)\s+aunt(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'grandfather': RegExp(
        r'(?:my|his|her|our|the)\s+(?:grandfather|grandpa)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'grandmother': RegExp(
        r'(?:my|his|her|our|the)\s+(?:grandmother|grandma)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'lawyer': RegExp(
        r'(?:my|his|her|our|the|a)\s+(?:lawyer|attorney)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'father-in-law': RegExp(
        r'(?:my|his|her|our|the)\s+father-in-law(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'mother-in-law': RegExp(
        r'(?:my|his|her|our|the)\s+mother-in-law(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'son': RegExp(
        r'(?:my|his|her|our|the)\s+son(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'daughter': RegExp(
        r'(?:my|his|her|our|the)\s+daughter(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'friend': RegExp(
        r'(?:my|his|her|our|a)\s+(?:friend|best friend)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
    };

    // Retornar primeiro papel encontrado (inglês)
    for (final entry in englishPatterns.entries) {
      if (entry.value.hasMatch(text)) {
        return entry.key;
      }
    }

    return null; // Nenhum papel detectado
  }

  /// 🆕 VALIDAÇÃO FORTALECIDA: Detecta quando um nome é reutilizado para outro personagem
  /// Exemplo: "Regina" sendo usada para sogra E amiga, "Marta" para irmã de A e irmã de B
  void _validateNameReuse(
    String generatedText,
    _CharacterTracker tracker,
    int blockNumber,
  ) {
    // Extrair todos os nomes do texto gerado
    final namePattern = RegExp(r'\b([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]{2,})\b');
    final foundNames = <String>{};

    for (final match in namePattern.allMatches(generatedText)) {
      final name = match.group(1)?.trim();
      if (name != null && _looksLikePersonName(name)) {
        foundNames.add(name);
      }
    }

    // Verificar se algum nome encontrado JÁ existe no tracker com papel diferente
    for (final name in foundNames) {
      if (tracker.hasName(name)) {
        final existingRole = tracker.getRole(name);

        // 🔥 NOVO: Detectar papéis/relações no texto atual (padrões expandidos)
        final currentRoles = <String>[];

        // PADRÃO 1: "meu/minha [relação] Nome" ou "Nome, [relação]" ou "a/o [relação], Nome"
        final relationPatterns = {
          'pai': RegExp(
            r'(?:meu|seu|nosso|o)\s+[Pp]ai(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:o\s+)?pai|(?:o|um)\s+pai(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'mãe': RegExp(
            r'(?:minha|sua|nossa|a)\s+[Mm]ãe(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:a\s+)?m[ãa]e|(?:a|uma)\s+m[ãa]e(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'marido': RegExp(
            r'(?:meu|seu|nosso|o)\s+(?:marido|esposo)(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:o\s+)?(?:marido|esposo)|(?:o|um)\s+(?:marido|esposo)(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'esposa': RegExp(
            r'(?:minha|sua|nossa|a)\s+(?:esposa|mulher)(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:a\s+)?(?:esposa|mulher)|(?:a|uma)\s+(?:esposa|mulher)(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'filho': RegExp(
            r'(?:meu|seu|nosso|o)\s+[Ff]ilho(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:o\s+)?filho|(?:o|um)\s+filho(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'filha': RegExp(
            r'(?:minha|sua|nossa|a)\s+[Ff]ilha(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:a\s+)?filha|(?:a|uma)\s+filha(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'irmão': RegExp(
            r'(?:meu|seu|nosso|o)\s+(?:irmão|irmao)(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:o\s+)?(?:irmão|irmao)|(?:o|um)\s+(?:irmão|irmao)(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'irmã': RegExp(
            r'(?:minha|sua|nossa|a)\s+(?:irmã|irma)(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:a\s+)?(?:irmã|irma)|(?:a|uma)\s+(?:irmã|irma)(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'sogro': RegExp(
            r'(?:meu|seu|nosso|o)\s+sogro(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:o\s+)?sogro|(?:a|o)\s+sogro(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'sogra': RegExp(
            r'(?:minha|sua|nossa|a)\s+sogra(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:a\s+)?sogra|(?:a|uma)\s+sogra(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'amigo': RegExp(
            r'(?:meu|seu|nosso|o)\s+amigo(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:um\s+)?amigo|(?:o|um)\s+amigo(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'amiga': RegExp(
            r'(?:minha|sua|nossa|a)\s+amiga(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:uma\s+)?amiga|(?:a|uma)\s+amiga(?:,)?\s+' +
                name,
            caseSensitive: false,
          ),
          'vizinho': RegExp(
            r'(?:o|um)\s+vizinho(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:o\s+)?vizinho',
            caseSensitive: false,
          ),
          'vizinha': RegExp(
            r'(?:a|uma)\s+vizinha(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:a\s+)?vizinha',
            caseSensitive: false,
          ),
          'professor': RegExp(
            r'(?:o|um)\s+professor(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:um\s+)?professor',
            caseSensitive: false,
          ),
          'professora': RegExp(
            r'(?:a|uma)\s+professora(?:,)?\s+' +
                name +
                r'|' +
                name +
                r'(?:,)?\s+(?:uma\s+)?professora',
            caseSensitive: false,
          ),
        };

        for (final entry in relationPatterns.entries) {
          if (entry.value.hasMatch(generatedText)) {
            currentRoles.add(entry.key);
          }
        }

        // PADRÃO 2: "Nome, [relação] de [outra pessoa]"
        final contexts = [
          'irmã de',
          'irmão de',
          'filho de',
          'filha de',
          'pai de',
          'mãe de',
          'esposa de',
          'esposo de',
          'marido de',
          'neto de',
          'neta de',
          'tio de',
          'tia de',
          'primo de',
          'prima de',
          'avô de',
          'avó de',
          'amiga de',
          'amigo de',
          'vizinha de',
          'vizinho de',
        ];

        for (final context in contexts) {
          final pattern = RegExp(
            name +
                r',?\s+' +
                context +
                r'\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
            caseSensitive: false,
          );
          final match = pattern.firstMatch(generatedText);

          if (match != null) {
            final relatedPerson = match.group(1);
            currentRoles.add('$context $relatedPerson');
          }
        }

        // 🚨 DETECÇÃO: Se encontrou papéis no texto atual
        if (currentRoles.isNotEmpty) {
          final currentRolesStr = currentRoles.join(', ');

          // 🔥 CORREÇÃO BUG ALBERTO: Validar mesmo se existingRole é null
          if (existingRole == null || existingRole == 'indefinido') {
            // ⚠️ Nome existia SEM papel definido, agora tem papel
            debugPrint(
              '⚠️⚠️⚠️ ALERTA: NOME SEM PAPEL ANTERIOR - BLOCO $blockNumber ⚠️⚠️⚠️',
            );
            debugPrint(
              '   📝 Nome "$name" estava no tracker SEM papel definido',
            );
            debugPrint('   🔍 Papéis detectados AGORA: $currentRolesStr');

            // 🚨 CRÍTICO: Verificar se há múltiplos papéis CONFLITANTES no texto atual
            if (currentRoles.length > 1) {
              _debugLogger.error(
                "Múltiplos papéis para '$name' no mesmo bloco",
                blockNumber: blockNumber,
                details:
                    "Nome '$name' aparece com papéis conflitantes no mesmo bloco:\n"
                    "- Papéis detectados: $currentRolesStr",
                metadata: {'nome': name, 'papeis': currentRoles},
              );

              debugPrint(
                '🚨🚨🚨 ERRO CRÍTICO: MÚLTIPLOS PAPÉIS NO MESMO BLOCO 🚨🚨🚨',
              );
              debugPrint('   ❌ Nome "$name" com MÚLTIPLOS papéis diferentes:');
              for (final role in currentRoles) {
                debugPrint('      - $role');
              }
              debugPrint(
                '   💡 SOLUÇÃO: Verificar se são realmente a mesma pessoa!',
              );
              debugPrint(
                '   💡 Exemplo: "Alberto" como marido E como cunhado = ERRO!',
              );
              debugPrint('🚨🚨🚨 FIM DO ALERTA 🚨🚨🚨');
            } else {
              debugPrint('   ℹ️ Único papel detectado: ${currentRoles.first}');
              debugPrint('   ✅ Atualizando papel no tracker...');
            }
            debugPrint('⚠️⚠️⚠️ FIM DO ALERTA ⚠️⚠️⚠️');
          } else {
            // Papel anterior existe - verificar CONFLITO
            var hasConflict = false;

            // Conflito se: nenhum papel atual aparece no papel existente
            if (!currentRoles.any(
              (role) => existingRole.toLowerCase().contains(role.toLowerCase()),
            )) {
              hasConflict = true;
            }

            if (hasConflict) {
              // 🐛 DEBUG: Log erro crítico de reutilização
              _debugLogger.error(
                "Reutilização de nome: '$name'",
                blockNumber: blockNumber,
                details:
                    "Nome '$name' usado em múltiplos papéis diferentes:\n"
                    "- Papel anterior: $existingRole\n"
                    "- Papéis novos: $currentRolesStr",
                metadata: {
                  'nome': name,
                  'papelAnterior': existingRole,
                  'papeisNovos': currentRoles,
                },
              );

              debugPrint(
                '🚨🚨🚨 ERRO CRÍTICO DE REUTILIZAÇÃO DE NOME - BLOCO $blockNumber 🚨🚨🚨',
              );
              debugPrint(
                '   ❌ Nome "$name" está sendo REUTILIZADO EM PAPÉIS DIFERENTES!',
              );
              debugPrint('   📋 Papel anterior: "$name" como $existingRole');
              debugPrint('   ⚠️ Papéis novos detectados: $currentRolesStr');
              debugPrint(
                '   💡 SOLUÇÃO: Cada personagem precisa de nome ÚNICO!',
              );
              debugPrint(
                '   💡 Exemplo: "Regina" não pode ser sogra E amiga ao mesmo tempo',
              );
              debugPrint(
                '   💡 Sugestão: Trocar segundo "$name" por outro nome diferente',
              );
              debugPrint('🚨🚨🚨 FIM DO ALERTA DE REUTILIZAÇÃO 🚨🚨🚨');
            }
          }
        }
      }
    }

    // 🐛 DEBUG: Log validação de nomes completa
    _debugLogger.validation(
      "Validação de reutilização completa",
      blockNumber: blockNumber,
      details: "${foundNames.length} nomes verificados",
      metadata: {'nomesVerificados': foundNames.length},
    );
  }

  /// 🆕 NOVA VALIDAÇÃO: Detecta inconsistências em relações familiares
  /// Exemplo: "meu Pai Francisco" vs "meu marido Francisco" = CONFUSÃO
  void _validateFamilyRelations(String generatedText, int blockNumber) {
    // Extrair nomes mencionados no texto
    final namePattern = RegExp(r'\b([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]{2,})\b');
    final names = <String>{};

    for (final match in namePattern.allMatches(generatedText)) {
      final name = match.group(1)?.trim();
      if (name != null && _looksLikePersonName(name)) {
        names.add(name);
      }
    }

    // Para cada nome, verificar se aparece com múltiplas relações conflitantes
    for (final name in names) {
      final relations = <String>[];

      // Padrões de relações familiares
      final relationPatterns = {
        'pai': RegExp(
          '(?:meu|seu|nosso|o)\\s+[Pp]ai(?:,)?\\s+$name',
          caseSensitive: false,
        ),
        'mãe': RegExp(
          '(?:minha|sua|nossa|a)\\s+[Mm]ãe(?:,)?\\s+$name',
          caseSensitive: false,
        ),
        'marido': RegExp(
          '(?:meu|seu|nosso|o)\\s+(?:marido|esposo)(?:,)?\\s+$name',
          caseSensitive: false,
        ),
        'esposa': RegExp(
          '(?:minha|sua|nossa|a)\\s+(?:esposa|mulher)(?:,)?\\s+$name',
          caseSensitive: false,
        ),
        'filho': RegExp(
          '(?:meu|seu|nosso|o)\\s+[Ff]ilho(?:,)?\\s+$name',
          caseSensitive: false,
        ),
        'filha': RegExp(
          '(?:minha|sua|nossa|a)\\s+[Ff]ilha(?:,)?\\s+$name',
          caseSensitive: false,
        ),
        'irmão': RegExp(
          '(?:meu|seu|nosso|o)\\s+(?:irmão|irmao)(?:,)?\\s+$name',
          caseSensitive: false,
        ),
        'irmã': RegExp(
          '(?:minha|sua|nossa|a)\\s+(?:irmã|irma)(?:,)?\\s+$name',
          caseSensitive: false,
        ),
      };

      // Verificar quais relações aparecem para este nome
      for (final entry in relationPatterns.entries) {
        if (entry.value.hasMatch(generatedText)) {
          relations.add(entry.key);
        }
      }

      // 🚨 DETECTAR CONFLITOS: Mesmo nome com relações incompatíveis
      final conflicts = _detectRelationConflicts(relations);

      if (conflicts.isNotEmpty) {
        _debugLogger.error(
          "Confusão em relação familiar: '$name'",
          blockNumber: blockNumber,
          details:
              "Nome '$name' aparece como: ${relations.join(', ')}\n"
              "Conflito: ${conflicts.join(', ')}",
          metadata: {
            'nome': name,
            'relacoes': relations,
            'conflitos': conflicts,
          },
        );

        debugPrint(
          '🚨🚨🚨 ERRO CRÍTICO DE RELAÇÃO FAMILIAR - BLOCO $blockNumber 🚨🚨🚨',
        );
        debugPrint('   ❌ Nome "$name" tem relações conflitantes!');
        debugPrint('   📋 Relações encontradas: ${relations.join(", ")}');
        debugPrint('   ⚠️ Conflitos: ${conflicts.join(", ")}');
        debugPrint(
          '   💡 SOLUÇÃO: Definir claramente se é pai, marido, filho, etc.',
        );
        debugPrint('🚨🚨🚨 FIM DO ALERTA DE RELAÇÃO FAMILIAR 🚨🚨🚨');
      }
    }
  }

  /// 🔥 NOVA VALIDAÇÃO CRÍTICA v7.6.16: Detecta mudanças de nome de personagens
  /// Compara papéis conhecidos (tracker) com novos nomes mencionados no texto
  /// Retorna lista de mudanças detectadas para rejeição do bloco
  List<Map<String, String>> _detectCharacterNameChanges(
    String generatedText,
    _CharacterTracker tracker,
    int blockNumber,
  ) {
    final changes = <Map<String, String>>[];

    // Padrões de relações familiares para detectar personagens
    final relationPatterns = {
      'pai': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Pp]ai(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'mãe': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Mm]ãe(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'marido': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:marido|esposo)(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'esposa': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:esposa|mulher)(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'filho': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Ff]ilho(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'filha': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Ff]ilha(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'irmão': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:irmão|irmao)(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'irmã': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:irmã|irma)(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'advogado': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Aa]dvogad[oa](?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'investigador': RegExp(
        r'(?:o|um)\s+[Ii]nvestigador(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
    };

    // Para cada papel rastreado, verificar se o nome mudou
    for (final entry in relationPatterns.entries) {
      final role = entry.key;
      final pattern = entry.value;
      final matches = pattern.allMatches(generatedText);

      for (final match in matches) {
        final newName = match.group(1)?.trim();
        if (newName == null || !_looksLikePersonName(newName)) continue;

        // Verificar se este papel já tem um nome no tracker
        final existingName = tracker.getNameForRole(role);

        if (existingName != null && existingName != newName) {
          // 🚨 MUDANÇA DETECTADA!
          changes.add({
            'role': role,
            'oldName': existingName,
            'newName': newName,
          });

          if (kDebugMode) {
            debugPrint(
              '🚨 MUDANÇA DE NOME: "$role" era "$existingName" → agora "$newName"!',
            );
          }
        }
      }
    }

    return changes;
  }

  /// Detecta conflitos entre relações familiares
  /// Retorna lista de descrições de conflitos encontrados
  List<String> _detectRelationConflicts(List<String> relations) {
    final conflicts = <String>[];

    if (relations.length < 2) {
      return conflicts; // Sem conflito se há apenas 1 relação
    }

    // Grupos de relações mutuamente exclusivas
    final exclusiveGroups = [
      {'pai', 'marido', 'filho', 'irmão'}, // Relações masculinas diferentes
      {'mãe', 'esposa', 'filha', 'irmã'}, // Relações femininas diferentes
      {'pai', 'mãe'}, // Pais não podem ser a mesma pessoa
      {'marido', 'esposa'}, // Cônjuges não podem ser a mesma pessoa
      {'filho', 'pai'}, // Filho não pode ser pai do narrador
      {'filha', 'mãe'}, // Filha não pode ser mãe do narrador
    ];

    for (final group in exclusiveGroups) {
      final found = relations.where((r) => group.contains(r)).toList();
      if (found.length > 1) {
        conflicts.add('${found.join(" + ")} são incompatíveis');
      }
    }

    return conflicts;
  }

  bool _looksLikePersonName(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return false;

    // v7.6.63: Validação estrutural simples (Gemini é o Casting Director)
    // Aceitar se parece nome próprio e não é palavra comum
    if (_isLikelyName(cleaned) && !_isCommonWord(cleaned)) {
      return true;
    }

    // Fallback: estrutura válida
    if (_hasValidNameStructure(cleaned) && !_isCommonWord(cleaned)) {
      return true;
    }

    return false;
  }

  /// v7.6.63: Validação simples de nome (aceita criatividade do LLM)
  /// Resolve bug de rejeitar nomes coreanos, compostos, etc.
  bool _isLikelyName(String text) {
    if (text.isEmpty) return false;
    // Aceita qualquer string que comece com letra maiuscula
    // e contenha apenas letras, espacos, hifens ou apostrofos
    final nameRegex = RegExp(
      r"^[A-Z\u00C0-\u00DC\u0100-\u017F\uAC00-\uD7AF][a-zA-Z\u00C0-\u00FF\u0100-\u017F\uAC00-\uD7AF\s\-\']+$",
    );
    return nameRegex.hasMatch(text.trim());
  }

  /// 🆕 v7.6.17: Verifica estrutura válida de nome próprio
  bool _hasValidNameStructure(String name) {
    // Mínimo 2 caracteres, máximo 15
    if (name.length < 2 || name.length > 15) return false;

    // Primeira letra maiúscula
    if (name[0] != name[0].toUpperCase()) return false;

    // Resto em minúsculas (permite acentos)
    final rest = name.substring(1);
    if (rest != rest.toLowerCase()) return false;

    // Apenas letras (permite acentuação)
    final validPattern = RegExp(r'^[A-ZÀ-Ü][a-zà-ÿ]+$');
    return validPattern.hasMatch(name);
  }

  /// 🆕 v7.6.17: Verifica se é palavra comum (não-nome)
  bool _isCommonWord(String word) {
    final lower = word.toLowerCase();

    // Palavras comuns em múltiplos idiomas (sem duplicações)
    final commonWords = {
      // Português
      'então', 'quando', 'depois', 'antes', 'agora', 'hoje',
      'ontem', 'sempre', 'nunca', 'muito', 'pouco', 'nada',
      'tudo', 'algo', 'alguém', 'ninguém', 'mesmo', 'outra',
      'outro', 'cada', 'toda', 'todo', 'todos', 'onde', 'como',
      'porque', 'porém', 'mas', 'para', 'com', 'sem', 'por',
      'sobre', 'entre', 'durante', 'embora', 'enquanto',
      // English
      'then', 'when', 'after', 'before', 'now', 'today',
      'yesterday', 'always', 'never', 'much', 'little', 'nothing',
      'everything', 'something', 'someone', 'nobody', 'same', 'other',
      'each', 'every', 'where', 'because', 'however', 'though',
      'while', 'about', 'between',
      // Español (apenas palavras exclusivas, sem sobreposição com PT/EN)
      'entonces', 'después', 'ahora', 'hoy', 'ayer', 'siempre',
      'mucho', 'alguien', 'nadie', 'mismo', 'pero', 'sin', 'aunque',
      'mientras',
    };

    return commonWords.contains(lower);
  }

  static final Set<String> _nameStopwords = {
    // Plataformas/sites
    'youtube',
    'internet',
    'instagram',
    'facebook',
    'whatsapp',
    'tiktok',
    'google',
    'cta',

    // Países/lugares
    'brasil', 'portugal', 'portugues',

    // Pronomes e palavras comuns capitalizadas no início de frases
    'ele',
    'ela',
    'eles',
    'elas',
    'nao',
    'sim',
    'mas',
    'mais',
    'cada',
    'todo',
    'toda',
    'todos',
    'meu',
    'minha',
    'meus',
    'minhas',
    'seu',
    'sua',
    'seus',
    'suas',
    'nosso',
    'nossa',
    'esse',
    'essa',
    'esses',
    'essas',
    'aquele',
    'aquela',
    'aquilo',
    'isto',
    'isso',
    'tudo',
    'nada',
    'algo',
    'alguem',
    'ninguem',
    'qualquer',
    'outro',
    'outra',
    'mesmo',
    'mesma',
    'esta', 'este', 'estes', 'estas',

    // Substantivos comuns que podem ser capitalizados
    'filho',
    'filha',
    'filhos',
    'pai',
    'mae',
    'pais',
    'irmao',
    'irma',
    'tio',
    'tia',
    'avo', 'neto', 'neta', 'marido', 'esposa', 'noivo', 'noiva',
    'amigo', 'amiga', 'primo', 'prima', 'sobrinho', 'sobrinha',
    'senhor',
    'senhora',
    'doutor',
    'doutora',
    'cliente',
    'pessoa',
    'pessoas',
    'gente',
    'familia', 'casa', 'mundo', 'vida', 'tempo', 'dia', 'noite', 'momento',

    // Advérbios/conjunções/preposições comuns no início de frase
    'entao',
    'depois',
    'antes',
    'agora',
    'hoje',
    'ontem',
    'amanha',
    'sempre',
    'nunca',
    'talvez',
    'porem',
    'contudo',
    'entretanto',
    'portanto',
    'enquanto',
    'quando',
    'onde',
    'havia', 'houve', 'tinha', 'foram', 'eram', 'estava', 'estavam',
    'dentro',
    'fora',
    'acima',
    'abaixo',
    'perto',
    'longe',
    'aqui',
    'ali',
    'alem',
    'apenas',
    'somente',
    'tambem',
    'inclusive',
    'ate',
    'ainda',
    'logo',
    'ja',
    'nem',

    // Preposições e artigos (raramente, mas podem aparecer)
    'com', 'sem', 'sobre', 'para', 'pela', 'pelo', 'uma', 'umas', 'uns', 'por',

    // 🔥 FIX CRÍTICO: Palavras que a AI usou como NOMES FANTASMA (do roteiro analisado)
    'lagrimas',
    'lágrimas',
    'justica',
    'justiça',
    'ponto',
    'semanas',
    'aconteceu',
    'todas', 'ajuda', 'consolo', 'vamos', 'conheço', 'conheco', 'lembra',

    // 🆕 v7.6.39: Palavras em inglês que NÃO são nomes (evitar "Grand" etc.)
    'grand', 'grandfather', 'grandmother', 'grandpa', 'grandma',
    'father', 'mother', 'brother', 'sister', 'uncle', 'aunt',
    'cousin', 'nephew', 'niece', 'husband', 'wife', 'spouse',
    'son', 'daughter', 'child', 'children', 'parent', 'parents',
    'lawyer', 'attorney', 'doctor', 'nurse', 'teacher', 'professor',
    'judge', 'officer', 'detective', 'manager', 'boss', 'therapist',
    'someone', 'anyone', 'everyone', 'nobody', 'somebody', 'anybody',
    'nothing', 'something', 'everything', 'anything',
    'said', 'told', 'asked', 'replied', 'explained', 'answered',
    'speaking', 'talking', 'calling', 'waiting', 'looking',
    'morning', 'afternoon', 'evening', 'night', 'today', 'tomorrow',
    'office', 'house', 'home', 'room', 'building', 'street', 'city',
    'the', 'and', 'but', 'for', 'with', 'from', 'about', 'into',
    'just', 'only', 'even', 'still', 'already', 'always', 'never',

    // Verbos comuns no início de frase (EXPANDIDO)
    'era', 'foi', 'seria', 'pode', 'podia', 'deve', 'devia',
    'senti', 'sentiu', 'pensei', 'pensou', 'vi', 'viu', 'ouvi', 'ouviu',
    'fiz', 'fez', 'disse', 'falou', 'quis', 'pude', 'pôde',
    'tive',
    'teve',
    'sabia',
    'soube',
    'imaginei',
    'imaginou',
    'acreditei',
    'acreditou',
    'percebi', 'percebeu', 'notei', 'notou', 'lembrei', 'lembrou',
    'passei', 'abri', 'olhei', 'escrevo', 'escreveu', 'podes',
    'queria', 'quer', 'tenho', 'tem',
    'levei', 'levou', 'trouxe', 'deixei', 'deixou', 'encontrei', 'encontrou',
    'cheguei', 'chegou', 'sai', 'saiu', 'entrei', 'entrou',
    'peguei',
    'pegou',
    'coloquei',
    'colocou',
    'tirei',
    'tirou',
    'guardei',
    'guardou',
    'voltei',
    'voltou',
    'segui',
    'seguiu',
    'comecei',
    'começou',
    'terminei',
    'terminou',
  };

  static String perspectiveLabel(String perspective) {
    final perspectiveLower = perspective.toLowerCase();

    // 🔥 FIX: Detectar primeira pessoa em qualquer formato
    if (perspectiveLower.contains('primeira_pessoa') ||
        perspectiveLower == 'first') {
      if (perspectiveLower.contains('mulher_idosa')) {
        return 'Primeira pessoa - Mulher Idosa (50+)';
      }
      if (perspectiveLower.contains('mulher_madura')) {
        return 'Primeira pessoa - Mulher Madura (35-50)';
      }
      if (perspectiveLower.contains('mulher_jovem')) {
        return 'Primeira pessoa - Mulher Jovem (20-35)';
      }
      if (perspectiveLower.contains('homem_idoso')) {
        return 'Primeira pessoa - Homem Idoso (50+)';
      }
      if (perspectiveLower.contains('homem_maduro')) {
        return 'Primeira pessoa - Homem Maduro (35-50)';
      }
      if (perspectiveLower.contains('homem_jovem')) {
        return 'Primeira pessoa - Homem Jovem (20-35)';
      }
      return 'Primeira pessoa';
    }

    // Terceira pessoa (padrão)
    return 'Terceira pessoa';
  }

  // 🎯 CORRIGIDO: Instrução CLARA de perspectiva com contexto do protagonista
  String _getPerspectiveInstruction(String perspective, ScriptConfig config) {
    final protagonistInfo = config.protagonistName.trim().isNotEmpty
        ? ' O protagonista é "${config.protagonistName}".'
        : '';

    // 🔥 FIX: Aceitar valores reais da interface (primeira_pessoa_*, terceira_pessoa)
    final perspectiveLower = perspective.toLowerCase();

    // 🚨 DETECTAR GÊNERO DO NARRADOR BASEADO NA PERSPECTIVA
    if (perspectiveLower.contains('mulher')) {
      // FEMININO (ela)
    } else if (perspectiveLower.contains('homem')) {
      // MASCULINO (ele)
    }

    // Detectar primeira pessoa (qualquer variação)
    if (perspectiveLower.contains('primeira_pessoa') ||
        perspectiveLower == 'first') {
      // Definir pronomes baseado no tipo de primeira pessoa
      String pronomes = 'EU, MEU, MINHA, COMIGO';
      String exemplos =
          '"EU vendi a casa...", "MEU coração batia forte...", "COMIGO ela nunca foi honesta..."';
      String nomeInstrucao = '';

      if (perspectiveLower.contains('mulher')) {
        exemplos =
            '"EU vendi a casa...", "MINHA nora me traiu...", "COMIGO ela nunca foi honesta..."';

        // 🎯 DETECTAR FAIXA ETÁRIA E ADICIONAR INSTRUÇÕES ESPECÍFICAS
        String idadeInstrucao = '';
        if (perspectiveLower.contains('jovem')) {
          idadeInstrucao = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 FAIXA ETÁRIA OBRIGATÓRIA: MULHER JOVEM (20-35 ANOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ IDADE CORRETA: Entre 20 e 35 anos
✅ PERFIL: Mulher adulta jovem, início/meio da carreira, possivelmente casada/solteira, energética
✅ CONTEXTO: Pode ter filhos pequenos, focada em crescimento profissional/pessoal
✅ VOCABULÁRIO: Moderno, atual, referências contemporâneas

❌ PROIBIDO: Mencionar aposentadoria, netos, memórias de décadas atrás
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
        } else if (perspectiveLower.contains('madura')) {
          idadeInstrucao = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 FAIXA ETÁRIA OBRIGATÓRIA: MULHER MADURA (35-50 ANOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ IDADE CORRETA: Entre 35 e 50 anos
✅ PERFIL: Mulher experiente, consolidada profissionalmente, possivelmente com filhos adolescentes
✅ CONTEXTO: Pode ter divórcio, segundo casamento, filhos crescidos, auge da carreira
✅ VOCABULÁRIO: Equilibrado, maduro, experiente mas ainda contemporâneo

❌ PROIBIDO: Mencionar aposentadoria, netos adultos, velhice
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
        } else if (perspectiveLower.contains('idosa')) {
          idadeInstrucao = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 FAIXA ETÁRIA OBRIGATÓRIA: MULHER IDOSA (50+ ANOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ IDADE CORRETA: Acima de 50 anos
✅ PERFIL: Mulher com muita experiência de vida, possivelmente aposentada ou perto
✅ CONTEXTO: Pode ter netos, viuvez, legado familiar, reflexões sobre a vida
✅ VOCABULÁRIO: Sábio, reflexivo, com histórias de décadas atrás

❌ PROIBIDO: Agir como jovem, usar gírias recentes inadequadas à idade
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
        }

        nomeInstrucao =
            '''
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🚨🚨🚨 GÊNERO OBRIGATÓRIO: FEMININO (MULHER) - CONFIGURAÇÃO DO USUÁRIO 🚨🚨🚨 ║
╚══════════════════════════════════════════════════════════════════════════════╝

⚠️⚠️⚠️ REGRA ABSOLUTA - NÃO NEGOCIÁVEL ⚠️⚠️⚠️

O USUÁRIO CONFIGUROU EXPLICITAMENTE: "Primeira Pessoa MULHER"
VOCÊ DEVE, OBRIGATORIAMENTE, GERAR UM PROTAGONISTA FEMININO!

🚨 VALIDAÇÃO ANTES DE ESCREVER A PRIMEIRA FRASE:
❓ "O protagonista que vou criar é MULHER?" 
   → Se SIM = Prossiga
   → Se NÃO = PARE! Você está DESOBEDECENDO a configuração do usuário!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 REGRAS DE NOMES:

1️⃣ SE O TÍTULO MENCIONAR UM NOME ESPECÍFICO (ex: "Você é Maria?"):
   ✅ USE ESTE NOME para a protagonista
   ✅ Exemplo: Se título diz "Maria", protagonista é "Maria"

2️⃣ SE O TÍTULO NÃO MENCIONAR NENHUM NOME (ex: "Un milliardaire m'a donné..."):
   ✅ VOCÊ DEVE CRIAR um nome FEMININO apropriado para o idioma
   
   📋 Nomes femininos por idioma:
   • Français: Sophie, Marie, Amélie, Claire, Camille, Emma, Louise, Chloé
   • Português: Maria, Ana, Sofia, Helena, Clara, Beatriz, Julia, Laura
   • English: Emma, Sarah, Jennifer, Emily, Jessica, Ashley, Michelle, Amanda
   • Español: María, Carmen, Laura, Ana, Isabel, Rosa, Elena, Sofia
   • 한국어 (Korean): Kim Ji-young, Park Soo-yeon, Lee Min-ji, Choi Hye-jin, Jung Yoo-na
     ⚠️ COREANO: SEMPRE use SOBRENOME + NOME (ex: "Kim Ji-young", NÃO "Ji-young")
   
   ❌ PROIBIDO: João, Pedro, Carlos, Michael, Roberto, Pierre, Jean, Marc
   ❌ JAMAIS use nomes MASCULINOS quando o narrador é MULHER!

$idadeInstrucao

🔴 SE VOCÊ CRIAR UM PROTAGONISTA MASCULINO, O ROTEIRO SERÁ REJEITADO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

''';
      } else if (perspectiveLower.contains('homem')) {
        exemplos =
            '"EU construí esse negócio...", "MEU filho me abandonou...", "COMIGO ele sempre foi desleal..."';

        // 🎯 DETECTAR FAIXA ETÁRIA E ADICIONAR INSTRUÇÕES ESPECÍFICAS
        String idadeInstrucao = '';
        if (perspectiveLower.contains('jovem')) {
          idadeInstrucao = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 FAIXA ETÁRIA OBRIGATÓRIA: HOMEM JOVEM (20-35 ANOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ IDADE CORRETA: Entre 20 e 35 anos
✅ PERFIL: Homem adulto jovem, início/meio da carreira, possivelmente casado/solteiro, energético
✅ CONTEXTO: Pode ter filhos pequenos, focado em crescimento profissional/pessoal
✅ VOCABULÁRIO: Moderno, atual, referências contemporâneas

❌ PROIBIDO: Mencionar aposentadoria, netos, memórias de décadas atrás
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
        } else if (perspectiveLower.contains('maduro')) {
          idadeInstrucao = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 FAIXA ETÁRIA OBRIGATÓRIA: HOMEM MADURO (35-50 ANOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ IDADE CORRETA: Entre 35 e 50 anos
✅ PERFIL: Homem experiente, consolidado profissionalmente, possivelmente com filhos adolescentes
✅ CONTEXTO: Pode ter divórcio, segundo casamento, filhos crescidos, auge da carreira
✅ VOCABULÁRIO: Equilibrado, maduro, experiente mas ainda contemporâneo

❌ PROIBIDO: Mencionar aposentadoria, netos adultos, velhice
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
        } else if (perspectiveLower.contains('idoso')) {
          idadeInstrucao = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 FAIXA ETÁRIA OBRIGATÓRIA: HOMEM IDOSO (50+ ANOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ IDADE CORRETA: Acima de 50 anos
✅ PERFIL: Homem com muita experiência de vida, possivelmente aposentado ou perto
✅ CONTEXTO: Pode ter netos, viuvez, legado familiar, reflexões sobre a vida
✅ VOCABULÁRIO: Sábio, reflexivo, com histórias de décadas atrás

❌ PROIBIDO: Agir como jovem, usar gírias recentes inadequadas à idade
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
        }

        nomeInstrucao =
            '''
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🚨🚨🚨 GÊNERO OBRIGATÓRIO: MASCULINO (HOMEM) - CONFIGURAÇÃO DO USUÁRIO 🚨🚨🚨 ║
╚══════════════════════════════════════════════════════════════════════════════╝

⚠️⚠️⚠️ REGRA ABSOLUTA - NÃO NEGOCIÁVEL ⚠️⚠️⚠️

O USUÁRIO CONFIGUROU EXPLICITAMENTE: "Primeira Pessoa HOMEM"
VOCÊ DEVE, OBRIGATORIAMENTE, GERAR UM PROTAGONISTA MASCULINO!

🚨 VALIDAÇÃO ANTES DE ESCREVER A PRIMEIRA FRASE:
❓ "O protagonista que vou criar é HOMEM?" 
   → Se SIM = Prossiga
   → Se NÃO = PARE! Você está DESOBEDECENDO a configuração do usuário!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 REGRAS DE NOMES:

1️⃣ SE O TÍTULO MENCIONAR UM NOME ESPECÍFICO (ex: "Você é Michael?"):
   ✅ USE ESTE NOME para o protagonista
   ✅ Exemplo: Se título diz "Michael", protagonista é "Michael"

2️⃣ SE O TÍTULO NÃO MENCIONAR NENHUM NOME (ex: "Un milliardaire m'a donné..."):
   ✅ VOCÊ DEVE CRIAR um nome MASCULINO apropriado para o idioma
   
   📋 Nomes masculinos por idioma:
   • Français: Pierre, Jean, Marc, Luc, Antoine, Thomas, Nicolas, Julien
   • Português: João, Pedro, Carlos, Roberto, Alberto, Paulo, Fernando, Ricardo
   • English: John, Michael, David, James, Robert, William, Richard, Thomas
   • Español: Juan, Pedro, Carlos, José, Luis, Miguel, Antonio, Francisco
   • 한국어 (Korean): Kim Seon-woo, Park Jae-hyun, Lee Min-ho, Choi Dong-wook, Jung Tae-hyun
     ⚠️ COREANO: SEMPRE use SOBRENOME + NOME (ex: "Kim Seon-woo", NÃO "Seon-woo")
   
   ❌ PROIBIDO: Maria, Ana, Sofia, Sophie, Mônica, Clara, Helena, Emma
   ❌ JAMAIS use nomes FEMININOS quando o narrador é HOMEM!

$idadeInstrucao

🔴 SE VOCÊ CRIAR UM PROTAGONISTA FEMININO, O ROTEIRO SERÁ REJEITADO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

''';
      }

      return '''PERSPECTIVA NARRATIVA: PRIMEIRA PESSOA$protagonistInfo
$nomeInstrucao
⚠️ CRÍTICO: O PROTAGONISTA conta SUA PRÓPRIA HISTÓRIA usando "$pronomes".
🚫 PROIBIDO usar "ELE", "ELA", "DELE", "DELA" para o protagonista!
✅ CORRETO: $exemplos
O protagonista É o narrador. Ele/Ela está contando os eventos da SUA perspectiva em primeira pessoa.''';
    }

    // Terceira pessoa (padrão)
    return '''PERSPECTIVA NARRATIVA: TERCEIRA PESSOA$protagonistInfo
⚠️ IMPORTANTE: Um NARRADOR EXTERNO conta a história do protagonista usando "ELE", "ELA", "DELE", "DELA".
Exemplo: "ELA vendeu a casa...", "O coração DELE batia forte...", "COM ELA, ninguém foi honesto...".
O narrador observa e conta, mas NÃO é o protagonista.''';
  }

  /// 🚀 OTIMIZAÇÃO: Limita contexto aos últimos blocos para evitar timeouts
  /// Mantém apenas os últimos N blocos + resumo inicial para continuidade
  String _buildLimitedContext(
    String fullContext,
    int currentBlock,
    int maxRecentBlocks,
  ) {
    if (fullContext.isEmpty || currentBlock <= maxRecentBlocks) {
      return fullContext; // Blocos iniciais usam tudo
    }

    // 🔥 LIMITE ABSOLUTO OTIMIZADO: Reduzido para evitar timeout em idiomas pesados
    // 🚨 CRÍTICO: 5.6k palavras causava timeout API 503 nos blocos 7-8
    // 3.5k palavras = ~21k caracteres cirílico (mais seguro para Gemini)
    const maxContextWords = 3500; // REDUZIDO de 4500 para 3500
    final currentWords = _countWords(fullContext);

    if (currentWords <= maxContextWords) {
      return fullContext; // Contexto ainda está em tamanho seguro
    }

    // Separar em blocos (parágrafos duplos ou mais)
    final blocks = fullContext.split(RegExp(r'\n{2,}'));
    if (blocks.length <= maxRecentBlocks + 5) {
      return fullContext; // Ainda não tem muitos blocos
    }

    // Pegar resumo inicial (primeiros 3 parágrafos - REDUZIDO de 5 para 3)
    final initialSummary = blocks.take(3).join('\n\n');

    // Pegar últimos N blocos completos (REDUZIDO multiplicador de 5 para 3)
    final recentBlocks = blocks
        .skip(max(0, blocks.length - maxRecentBlocks * 3))
        .join('\n\n');

    final result = '$initialSummary\n\n[...]\n\n$recentBlocks';

    // Verificar se ainda está muito grande
    if (_countWords(result) > maxContextWords) {
      // Reduzir ainda mais - só últimos blocos (REDUZIDO multiplicador de 3 para 2)
      return blocks
          .skip(max(0, blocks.length - maxRecentBlocks * 2))
          .join('\n\n');
    }

    return result;
  }

  // 🌍 MULTIPLICADORES DE VERBOSIDADE POR IDIOMA
  // Baseado em análise de quantas palavras cada idioma precisa para expressar a mesma ideia
  // Português = 1.0 (baseline) funciona perfeitamente
  double _getLanguageVerbosityMultiplier(String language) {
    final normalized = language.toLowerCase().trim();

    // 🇲🇽 ESPANHOL: Tende a ser ~15-20% mais verboso que português
    if (normalized.contains('espanhol') ||
        normalized.contains('spanish') ||
        normalized.contains('español') ||
        normalized == 'es' ||
        normalized == 'es-mx') {
      return 0.85; // Pedir 15% menos para compensar
    }

    // 🇬🇧 INGLÊS: Tende a ser ~15-20% mais CONCISO que português
    // RAZÃO: Inglês usa menos palavras para expressar mesma ideia
    // EXEMPLO: "Eu estava pensando nisso" = 4 palavras → "I was thinking" = 3 palavras
    // SOLUÇÃO: Pedir um pouco MAIS palavras para compensar a concisão
    // 🔧 AJUSTE: Reduzido de 1.18x → 1.05x (estava gerando +21% a mais)
    if (normalized.contains('inglês') ||
        normalized.contains('ingles') ||
        normalized.contains('english') ||
        normalized == 'en' ||
        normalized == 'en-us') {
      return 1.05; // Pedir 5% MAIS para compensar concisão
    }

    // 🇫🇷 FRANCÊS: Tende a ser ~10-15% mais verboso que português
    if (normalized.contains('franc') ||
        normalized.contains('french') ||
        normalized == 'fr') {
      return 0.90; // Pedir 10% menos para compensar
    }

    // 🇮🇹 ITALIANO: Tende a ser ~10% mais verboso que português
    if (normalized.contains('italia') ||
        normalized.contains('italian') ||
        normalized == 'it') {
      return 0.92; // Pedir 8% menos para compensar
    }

    // 🇩🇪 ALEMÃO: Similar ao português (palavras compostas compensam artigos)
    if (normalized.contains('alem') ||
        normalized.contains('german') ||
        normalized == 'de') {
      return 1.0; // Sem ajuste
    }

    // 🇷🇺 RUSSO: Muito conciso (sem artigos, casos gramaticais)
    if (normalized.contains('russo') ||
        normalized.contains('russian') ||
        normalized == 'ru') {
      return 1.15; // Pedir 15% mais para compensar
    }

    // 🇵🇱 POLONÊS: Ligeiramente mais conciso que português
    if (normalized.contains('polon') ||
        normalized.contains('polish') ||
        normalized == 'pl') {
      return 1.05; // Pedir 5% mais para compensar
    }

    // 🇹🇷 TURCO: Muito conciso (aglutinação de palavras)
    if (normalized.contains('turco') ||
        normalized.contains('turk') ||
        normalized == 'tr') {
      return 1.20; // Pedir 20% mais para compensar
    }

    // 🇧🇬 BÚLGARO: Similar ao russo, conciso
    if (normalized.contains('búlgar') ||
        normalized.contains('bulgar') ||
        normalized == 'bg') {
      return 1.12; // Pedir 12% mais para compensar
    }

    // 🇭🇷 CROATA: Ligeiramente mais conciso
    if (normalized.contains('croat') ||
        normalized.contains('hrvat') ||
        normalized == 'hr') {
      return 1.08; // Pedir 8% mais para compensar
    }

    // 🇷🇴 ROMENO: Similar ao português (língua latina)
    if (normalized.contains('romen') ||
        normalized.contains('roman') ||
        normalized == 'ro') {
      return 1.0; // Sem ajuste
    }

    // 🇰🇷 COREANO: Muito conciso (aglutinação) + Modelo tende a ser preguiçoso
    // ANÁLISE: Pedindo 1.0x, ele entrega ~70% da meta.
    // SOLUÇÃO: Pedir 1.55x (55% a mais) para forçar expansão ou atingir o teto natural.
    if (normalized.contains('coreano') ||
        normalized.contains('korean') ||
        normalized.contains('한국어') ||
        normalized == 'ko') {
      return 1.55;
    }

    // 🇧🇷 PORTUGUÊS ou OUTROS: Baseline perfeito
    return 1.0;
  }

  Future<String> _generateBlockContent(
    String previous,
    int target,
    String phase,
    ScriptConfig c,
    _CharacterTracker tracker,
    int blockNumber,
    int totalBlocks, {
    bool avoidRepetition =
        false, // 🔥 NOVO: Flag para regeneração anti-repetição
    WorldState? worldState, // 🏗️ v7.6.64: Usa WorldState do módulo (SOLID)
  }) async {
    // 🔧 IMPORTANTE: target vem SEMPRE em PALAVRAS de _calculateTargetForBlock()
    // Mesmo quando measureType='caracteres', _calculateTargetForBlock já converteu caracteres→palavras
    // O Gemini trabalha melhor com contagem de PALAVRAS, então sempre pedimos palavras no prompt
    // Depois contamos caracteres no resultado final para validar se atingiu a meta do usuário
    final needed = target;
    if (needed <= 0) return '';

    // 🔥 OTIMIZAÇÃO CRÍTICA: Limitar contexto aos últimos N blocos
    // v6.0: Português usa MENOS contexto (3 blocos) para evitar erro 503
    // Outros idiomas: 4 blocos (padrão)
    // RATIONALE: Português = mais tokens → precisa contexto menor
    final isPortuguese = c.language.toLowerCase().contains('portugu');
    final maxContextBlocks = isPortuguese
        ? 3
        : 4; // PORTUGUÊS: 3 blocos (era 4)

    // Blocos iniciais (1-4): contexto completo
    // Blocos médios/finais (5+): últimos N blocos apenas
    String contextoPrevio = previous.isEmpty
        ? ''
        : _buildLimitedContext(previous, blockNumber, maxContextBlocks);

    if (kDebugMode && previous.isNotEmpty) {
      final contextUsed = contextoPrevio.length;
      final contextType = blockNumber <= maxContextBlocks
          ? 'COMPLETO'
          : 'LIMITADO (últimos $maxContextBlocks blocos)';
      debugPrint(
        '📚 CONTEXTO $contextType: $contextUsed chars (${_countWords(contextoPrevio)} palavras)',
      );
      if (blockNumber > maxContextBlocks) {
        debugPrint(
          '   Original: ${previous.length} chars → Reduzido: $contextUsed chars (${((1 - contextUsed / previous.length) * 100).toStringAsFixed(0)}% menor)',
        );
      }
    }

    // 🔥 SOLUÇÃO 3: Reforçar os nomes confirmados no prompt para manter consistência
    String trackerInfo = '';

    // 🆕 v7.6.36: LEMBRETE CRÍTICO DE NOMES - Muito mais agressivo!
    // Aparece no INÍCIO de cada bloco para evitar que Gemini "esqueça" nomes
    if (tracker.confirmedNames.isNotEmpty && blockNumber > 1) {
      final nameReminder = StringBuffer();
      nameReminder.writeln('');
      nameReminder.writeln(
        '🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨',
      );
      nameReminder.writeln(
        '⚠️ LEMBRETE OBRIGATÓRIO DE NOMES - LEIA ANTES DE CONTINUAR! ⚠️',
      );
      nameReminder.writeln(
        '🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨',
      );
      nameReminder.writeln('');
      nameReminder.writeln(
        '📋 PERSONAGENS DESTA HISTÓRIA (USE SEMPRE ESTES NOMES):',
      );
      nameReminder.writeln('');

      // Listar cada personagem com seu papel de forma MUITO clara
      for (final name in tracker.confirmedNames) {
        final role = tracker.getRole(name) ?? 'personagem';
        nameReminder.writeln('   ✅ $name = $role');
      }

      nameReminder.writeln('');
      nameReminder.writeln('❌ PROIBIDO MUDAR ESTES NOMES! ❌');
      nameReminder.writeln('');

      // Adicionar protagonista de forma EXTRA enfática
      final protagonistName = c.protagonistName.trim();
      if (protagonistName.isNotEmpty) {
        nameReminder.writeln(
          '🔴 A PROTAGONISTA/NARRADORA SE CHAMA: $protagonistName',
        );
        nameReminder.writeln('   → Quando ela fala de si mesma: "i" ou "me"');
        nameReminder.writeln(
          '   → Quando outros falam dela: "$protagonistName"',
        );
        nameReminder.writeln(
          '   → NUNCA mude para Emma, Jessica, Lauren, Sarah, etc!',
        );
        nameReminder.writeln('');
      }

      // Listar mapeamento reverso (papel → nome) para reforçar
      final roleMap = tracker.roleToNameMap;
      if (roleMap.isNotEmpty) {
        nameReminder.writeln('📌 MAPEAMENTO PAPEL → NOME (CONSULTE SEMPRE):');
        for (final entry in roleMap.entries) {
          nameReminder.writeln('   • ${entry.key} → ${entry.value}');
        }
        nameReminder.writeln('');
      }

      nameReminder.writeln(
        '⚠️ SE VOCÊ TROCAR UM NOME, O ROTEIRO SERÁ REJEITADO! ⚠️',
      );
      nameReminder.writeln(
        '🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨',
      );
      nameReminder.writeln('');

      trackerInfo = nameReminder.toString();

      if (kDebugMode) {
        debugPrint('🔥 Bloco $blockNumber - LEMBRETE DE NOMES INJETADO:');
        debugPrint('   Personagens: ${tracker.confirmedNames.join(", ")}');
        debugPrint('   Protagonista: $protagonistName');
      }
    } else if (tracker.confirmedNames.isNotEmpty) {
      // Bloco 1: lista mais simples
      trackerInfo =
          '\n🚫 NOMES JÁ USADOS - NUNCA REUTILIZE: ${tracker.confirmedNames.join(", ")}\n';
      trackerInfo +=
          '⚠️ Se precisa de novo personagem, use NOME TOTALMENTE DIFERENTE!\n';

      final mapping = tracker.getCharacterMapping();
      if (mapping.isNotEmpty) {
        trackerInfo += mapping;
        trackerInfo +=
            '\n⚠️ REGRA CRÍTICA: NUNCA use o mesmo nome para personagens diferentes!\n';
      }
    }

    // 🚨 CORREÇÃO CRÍTICA: SEMPRE injetar nome da protagonista, mesmo que não esteja no tracker
    final protagonistName = c.protagonistName.trim();
    if (protagonistName.isNotEmpty && !trackerInfo.contains(protagonistName)) {
      trackerInfo +=
          '\n🔥 ATENÇÃO ABSOLUTA: O NOME DA PROTAGONISTA É "$protagonistName"!\n';
      trackerInfo += '   ❌ NUNCA mude para outro nome (Wanessa, Carla, etc)\n';
      trackerInfo +=
          '   ✅ SEMPRE use "$protagonistName" quando se referir à protagonista!\n';
    }
    final characterGuidance = _buildCharacterGuidance(c, tracker);

    // 🆕 v7.6.52: WORLD STATE CONTEXT - Memória Infinita
    // Adiciona contexto estruturado de personagens, inventário e fatos
    String worldStateContext = '';
    if (worldState != null && blockNumber > 1) {
      worldStateContext = worldState.getContextForPrompt();
      if (kDebugMode && worldStateContext.isNotEmpty) {
        debugPrint(
          '🌍 World State injetado no prompt (${worldStateContext.length} chars)',
        );
      }
    }

    // 🔧 IMPORTANTE: Limitar palavras por bloco para estabilidade
    // O Gemini funciona melhor com targets de PALAVRAS, não caracteres
    // Limite máximo: 3500 palavras/bloco (≈ 19.250 caracteres)
    final limitedNeeded = min(needed, 3500); // Sempre limitar em palavras

    // 📊 SEMPRE pedir palavras no prompt (Gemini trabalha melhor assim)
    // O sistema converterá caracteres→palavras antes de chegar aqui (_calculateTargetForBlock)
    // E validará caracteres no resultado final

    // 🔥 AJUSTE POR IDIOMA: Compensar verbosidade natural de cada idioma
    // Português (baseline 1.0) funciona perfeitamente, outros ajustam proporcionalmente
    final languageMultiplier = _getLanguageVerbosityMultiplier(c.language);
    final adjustedTarget = (limitedNeeded * languageMultiplier).round();

    // Detectar se é espanhol para mensagem específica
    final isSpanish =
        c.language.toLowerCase().contains('espanhol') ||
        c.language.toLowerCase().contains('spanish') ||
        c.language.toLowerCase().contains('español');

    // 🎯 CONTROLE RIGOROSO DE CONTAGEM: ±8% aceitável (ajustado de ±10%)
    // RAZÃO: Multiplicador 1.08 deve manter resultado entre 92-108% da meta
    final minAcceptable = (adjustedTarget * 0.92).round();
    final maxAcceptable = (adjustedTarget * 1.08).round();

    final measure = isSpanish
        ? 'GERE EXATAMENTE $adjustedTarget palabras (MÍNIMO $minAcceptable, MÁXIMO $maxAcceptable). É MELHOR ficar perto de $adjustedTarget do que muito abaixo!'
        : 'GERE EXATAMENTE $adjustedTarget palavras (MÍNIMO $minAcceptable, MÁXIMO $maxAcceptable). É MELHOR ficar perto de $adjustedTarget do que muito abaixo!';
    final localizationGuidance = _buildLocalizationGuidance(c);
    final narrativeStyleGuidance = _getNarrativeStyleGuidance(c);

    // 🔍 DEBUG: Verificar se modo GLOBAL está sendo passado corretamente
    if (kDebugMode) {
      debugPrint('🌍 MODO DE LOCALIZAÇÃO: ${c.localizationLevel.displayName}');
      if (c.localizationLevel == LocalizationLevel.global) {
        debugPrint(
          '✅ MODO GLOBAL ATIVO - Prompt deve evitar nomes/comidas brasileiras',
        );
        debugPrint(
          '📝 Preview do prompt GLOBAL: ${localizationGuidance.substring(0, min(200, localizationGuidance.length))}...',
        );
      }
    }

    // 🎯 INTEGRAR TÍTULO COMO HOOK IMPACTANTE NO INÍCIO
    String instruction;
    if (previous.isEmpty) {
      if (c.startWithTitlePhrase && c.title.trim().isNotEmpty) {
        instruction = _getStartInstruction(
          c.language,
          withTitle: true,
          title: c.title,
        );
      } else {
        instruction = _getStartInstruction(c.language, withTitle: false);
      }
    } else {
      instruction = _getContinueInstruction(c.language);
    }

    // v7.6.63: Gemini é o Casting Director - cria nomes apropriados para o idioma
    // Removido banco de nomes estático em favor de geração dinâmica via LLM
    final nameList = ''; // Não mais necessário - LLM gera nomes contextualmente

    // 🌍 Obter labels traduzidos para os metadados
    final labels = _getMetadataLabels(c.language);

    //  Definir se inclui tema/subtema ou modo livre
    final temaSection = c.tema == 'Livre (Sem Tema)'
        ? '// Modo Livre: Desenvolva o roteiro baseado APENAS no título e contexto fornecidos\n'
        : '${labels['theme']}: ${c.tema}\n${labels['subtheme']}: ${c.subtema}\n';

    // 🆕 v7.6.44: SEMPRE incluir título como base da história
    // O título NÃO é apenas decorativo - é a PREMISSA da história!
    final titleSection = c.title.trim().isNotEmpty
        ? '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
              '🎯 TÍTULO/PREMISSA OBRIGATÓRIA DA HISTÓRIA:\n'
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
              '"${c.title}"\n'
              '\n'
              '⚠️ REGRA ABSOLUTA:\n'
              '   • A história DEVE desenvolver os elementos deste título\n'
              '   • Personagens, ações e contexto do título são OBRIGATÓRIOS\n'
              '   • NÃO invente uma história diferente da proposta no título\n'
              '   • O título é a PROMESSA feita ao espectador - CUMPRA-A!\n'
              '\n'
              '📋 EXEMPLOS:\n'
              '   ✅ Título: "굶고 있는 노인에게 도시락을 나눠준 편의점 알바생"\n'
              '      → História DEVE ter: funcionário de conveniência + idoso faminto + marmita compartilhada\n'
              '   \n'
              '   ✅ Título: "Bilionário me ofereceu emprego após eu ajudar um mendigo"\n'
              '      → História DEVE ter: protagonista + mendigo ajudado + revelação (mendigo = bilionário)\n'
              '   \n'
              '   ❌ ERRO: Ignorar título e criar história sobre CEO infiltrado em empresa\n'
              '      → Isso QUEBRA a promessa feita ao espectador!\n'
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
        : '';

    // 🚫 CONSTRUIR LISTA DE NOMES PROIBIDOS (já usados nesta história)
    String forbiddenNamesWarning = '';
    if (tracker.confirmedNames.isNotEmpty) {
      final forbiddenList = tracker.confirmedNames.join(', ');
      forbiddenNamesWarning =
          '🚫🚫🚫 NOMES PROIBIDOS - NÃO USE ESTES NOMES! 🚫🚫🚫\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '⛔ Os seguintes nomes JÁ ESTÃO EM USO nesta história:\n'
          '   ❌ $forbiddenList\n'
          '\n'
          '🚨 REGRA ABSOLUTA:\n'
          '   • NUNCA reutilize os nomes acima!\n'
          '   • Cada nome = 1 personagem único\n'
          '   • Se precisar de novo personagem, escolha nome DIFERENTE\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '\n';
    }

    // 🎯 Adicionar informações específicas de blocos (não estava no template)
    // 🆕 v7.6.22: Adicionar lista de personagens sem fechamento no bloco final
    String closureWarning = '';
    if (blockNumber == totalBlocks) {
      final unresolved = tracker.getUnresolvedCharacters();
      if (unresolved.isNotEmpty) {
        closureWarning =
            '\n'
            '🚨🚨🚨 ATENÇÃO CRÍTICA - BLOCO FINAL 🚨🚨🚨\n'
            '\n'
            '⚠️ OS SEGUINTES PERSONAGENS AINDA NÃO TIVERAM FECHAMENTO:\n'
            '   ${unresolved.map((name) => '• $name').join('\n   ')}\n'
            '\n'
            '✅ VOCÊ DEVE INCLUIR NESTE BLOCO FINAL:\n'
            '   Para CADA personagem acima, escreva:\n'
            '   1. O que aconteceu com ele/ela no final\n'
            '   2. Seu estado emocional/físico final\n'
            '   3. Resolução do seu arco narrativo\n'
            '\n'
            '📋 EXEMPLOS DE FECHAMENTO CORRETO:\n'
            '   • "Blake finalmente reconciliou com Taylor"\n'
            '   • "Nicholas viu justiça ser feita contra Arthur"\n'
            '   • "Robert encontrou paz sabendo que a verdade veio à tona"\n'
            '\n'
            '❌ NÃO É PERMITIDO:\n'
            '   • Terminar a história sem mencionar esses personagens\n'
            '   • Deixar seus destinos vagos ou implícitos\n'
            '   • Assumir que o leitor "vai entender"\n'
            '\n'
            '🎯 REGRA: Personagem importante = Fechamento explícito OBRIGATÓRIO\n'
            '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
            '\n';
      } else {
        if (kDebugMode) {
          debugPrint('✅ TODOS os personagens importantes já têm fechamento!');
          debugPrint(
            '   Taxa de fechamento: ${(tracker.getClosureRate() * 100).toStringAsFixed(1)}%',
          );
        }
      }
    }

    final blockInfo =
        '\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '📊 INFORMAÇÃO DE BLOCOS (CRÍTICO PARA PLANEJAMENTO):\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '   • Total de blocos planejados: $totalBlocks\n'
        '   • Bloco atual: bloco número $blockNumber de $totalBlocks\n'
        '   ${blockNumber < totalBlocks ? '• Status: CONTINUAÇÃO - Este NÃO é o último bloco!' : '• Status: BLOCO FINAL - Conclua a história agora!'}\n'
        '\n'
        '$closureWarning'
        '${blockNumber < totalBlocks ? '❌ PROIBIDO NESTE BLOCO:\n   • NÃO finalize a história ainda!\n   • NÃO escreva "THE END" ou equivalente\n   • NÃO crie uma resolução completa e definitiva\n   • NÃO conclua todos os arcos narrativos\n   \n✅ OBRIGATÓRIO NESTE BLOCO:\n   • CONTINUE desenvolvendo a trama\n   • Mantenha tensão e progressão narrativa\n   • Deixe ganchos para os próximos blocos\n   • A história DEVE ter continuação nos blocos seguintes\n   • Apenas desenvolva, NÃO conclua!\n' : '✅ OBRIGATÓRIO NESTE BLOCO FINAL:\n   • AGORA SIM finalize completamente a história\n   • Resolva TODOS os conflitos pendentes\n   • Dê fechamento a TODOS os personagens\n   • Este é o ÚLTIMO bloco - conclusão definitiva!\n'}\n'
        '� ATENÇÃO ESPECIAL:\n'
        '   • Histórias longas precisam de TODOS os blocos planejados\n'
        '   • NÃO termine prematuramente só porque "parece completo"\n'
        '   • Cada bloco é parte de um roteiro maior - respeite o planejamento\n'
        '   • Finais prematuros PREJUDICAM a qualidade e a experiência do ouvinte\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '\n'
        '🎯 REGRA ABSOLUTA:\n'
        '   UMA HISTÓRIA = UM CONFLITO CENTRAL = UM ARCO COMPLETO = UMA RESOLUÇÃO\n'
        '   PARÁGRAFOS CURTOS = PAUSAS = DRAMATICIDADE = RETENÇÃO ALTA\n'
        '   UM NOME = UM PERSONAGEM = NUNCA REUTILIZAR = VERIFICAR SEMPRE\n'
        '   DIÁLOGOS + MOTIVAÇÕES + CLOSURE = HISTÓRIA COMPLETA E SATISFATÓRIA\n'
        '\n'
        '🚫 NUNCA crie duas histórias separadas dentro do mesmo roteiro!\n'
        '🚫 NUNCA escreva parágrafos com mais de 180 palavras!\n'
        '🚫 NUNCA reutilize nomes de personagens já mencionados!\n'
        '🚫 NUNCA deixe personagens importantes sem destino final!\n'
        '🚫 NUNCA faça traições/conflitos sem motivação clara!\n'
        '🚫 NUNCA repita a mesma frase/metáfora mais de 2 vezes no roteiro!\n'
        '🚫 NUNCA introduza personagens secundários que desaparecem sem explicação!\n'
        '${blockNumber < totalBlocks ? '🚫 NUNCA finalize a história antes do bloco final ($totalBlocks)!\n' : ''}'
        '\n'
        '📋 REGRAS DE REPETIÇÃO E VARIAÇÃO:\n'
        '   • Frases marcantes do protagonista: máximo 2 repetições no roteiro inteiro\n'
        '   • Após primeira menção: use VARIAÇÕES ou referências INDIRETAS\n'
        '   • Exemplo: "lies are like cracks" → depois: "his foundation was crumbling" ou "the truth had started to show"\n'
        '   • Metáforas do pai/mentor: primeira vez completa, depois apenas alusões\n'
        '   • Evite eco narrativo: não repita descrições já feitas (humilhação inicial, etc.)\n'
        '\n'
        '📋 REGRAS DE PERSONAGENS SECUNDÁRIOS:\n'
        '   • TODO personagem introduzido DEVE ter resolução clara:\n'
        '   • Se aparece na investigação → DEVE aparecer no clímax/desfecho\n'
        '   • Se fornece informação crucial → DEVE testemunhar/ajudar no final\n'
        '   • Se é vítima/testemunha do passado → DEVE ter papel na justiça/vingança\n'
        '   • PROIBIDO: introduzir personagem importante e depois abandoná-lo\n'
        '   • Exemplo: Se Robert Peterson revela segredo → ele DEVE aparecer no tribunal/confronto final\n'
        '\n'
        '   🚨 LISTA DE VERIFICAÇÃO ANTES DO BLOCO FINAL:\n'
        '   \n'
        '   Personagens que NÃO PODEM desaparecer:\n'
        '   ☐ Quem forneceu evidência crucial (documentos, testemunho)\n'
        '   ☐ Quem foi vítima do antagonista no passado\n'
        '   ☐ Quem ajudou o protagonista na investigação\n'
        '   ☐ Quem tem conhecimento direto do crime/segredo\n'
        '   ☐ Familiar/amigo importante mencionado múltiplas vezes\n'
        '   \n'
        '   📋 EXEMPLOS DE FECHAMENTO OBRIGATÓRIO:\n'
        '   \n'
        '   ✅ Se "Robert revelou que seu pai Harold foi enganado":\n'
        '      → No clímax: "Robert entrou no tribunal. Olhou Alan nos olhos..."\n'
        '      → No desfecho: "Robert finalmente tinha paz. A verdade sobre Harold veio à tona."\n'
        '   \n'
        '   ✅ Se "Kimberly, a paralegal, guardou cópias dos documentos":\n'
        '      → No clímax: "Kimberly testemunhou. \'Alan me ordenou falsificar a assinatura\'..."\n'
        '      → No desfecho: "Kimberly foi elogiada por sua coragem em preservar as evidências."\n'
        '   \n'
        '   ✅ Se "David, o contador, descobriu a fraude primeiro":\n'
        '      → No clímax: "David apresentou os registros financeiros alterados..."\n'
        '      → No desfecho: "David foi promovido a CFO após a queda de Alan."\n'
        '   \n'
        '   ❌ NUNCA faça isso:\n'
        '      • "Robert me deu o documento" → [nunca mais mencionado] ← ERRO!\n'
        '      • "Kimberly tinha as provas" → [some da história] ← ERRO!\n'
        '      • "David descobriu tudo" → [não aparece no final] ← ERRO!\n'
        '\n'
        '⏰ REGRAS DE MARCADORES TEMPORAIS:\n'
        '   • Entre mudanças de cena/localização: SEMPRE incluir marcador temporal\n'
        '   • Exemplos: "três dias depois...", "na manhã seguinte...", "uma semana se passou..."\n'
        '   • Flashbacks: iniciar com "anos atrás..." ou "naquele dia em [ano]..."\n'
        '   • Saltos grandes (meses/anos): ser específico: "seis meses depois" não "algum tempo depois"\n'
        '   • Isso mantém o leitor orientado na linha temporal da história\n'
        '\n'
        '👨‍👩‍👧‍👦 REGRAS DE COERÊNCIA DE RELACIONAMENTOS FAMILIARES:\n'
        '   🚨 ERRO CRÍTICO: Relacionamentos familiares inconsistentes!\n'
        '   \n'
        '   ANTES de introduzir QUALQUER relação familiar, VALIDE:\n'
        '   \n'
        '   ✅ CORRETO - Lógica familiar coerente:\n'
        '      • "meu irmão Paul casou com Megan" → Megan é minha CUNHADA\n'
        '      • "Paul é meu irmão" + "Megan é esposa de Paul" = "Megan é minha cunhada"\n'
        '      • "minha irmã Maria casou com João" → João é meu CUNHADO\n'
        '   \n'
        '   ❌ ERRADO - Contradições:\n'
        '      • Chamar de "my sister-in-law" (cunhada) E depois "my brother married her" ← CONFUSO!\n'
        '      • "meu sogro Carlos" mas nunca mencionar cônjuge ← QUEM é casado com filho/filha dele?\n'
        '      • "my father-in-law Alan" mas protagonista solteiro ← IMPOSSÍVEL!\n'
        '   \n'
        '   📋 TABELA DE VALIDAÇÃO (USE ANTES DE ESCREVER):\n'
        '   \n'
        '   SE escrever: "my brother Paul married Megan"\n'
        '   → Megan é: "my sister-in-law" (cunhada)\n'
        '   → Alan (pai de Megan) é: "my brother\'s father-in-law" (sogro do meu irmão)\n'
        '   → NUNCA chamar Alan de "my father-in-law" (seria se EU casasse com Megan)\n'
        '   \n'
        '   SE escrever: "my wife Sarah\'s father Robert"\n'
        '   → Robert é: "my father-in-law" (meu sogro)\n'
        '   → Sarah é: "my wife" (minha esposa)\n'
        '   → Irmão de Sarah é: "my brother-in-law" (meu cunhado)\n'
        '   \n'
        '   🔴 REGRA DE OURO:\n'
        '      Antes de usar "cunhado/cunhada/sogro/sogra/genro/nora":\n'
        '      1. Pergunte: QUEM é casado com QUEM?\n'
        '      2. Desenhe mentalmente a árvore genealógica\n'
        '      3. Valide se a relação faz sentido matemático\n'
        '      4. Se confuso, use nomes próprios em vez de relações\n'
        '   \n'
        '   ⚠️ SE HOUVER DÚVIDA: Use "Megan" em vez de tentar definir relação familiar!\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';

    // 🔥 CRITICAL: ADICIONAR INSTRUÇÃO DE PERSPECTIVA/GÊNERO NO INÍCIO DO PROMPT
    final perspectiveInstruction = _getPerspectiveInstruction(c.perspective, c);

    // 🔥 NOVO: Combinar prompt do template (compacto) + informações de bloco
    final prompt =
        perspectiveInstruction + // ✅ AGORA A INSTRUÇÃO DE GÊNERO VEM PRIMEIRO!
        '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n' +
        worldStateContext + // 🆕 v7.6.52: WORLD STATE CONTEXT - Memória Infinita
        titleSection + // 🆕 v7.6.44: TÍTULO SEMPRE INCLUÍDO PARA GARANTIR COERÊNCIA
        MainPromptTemplate.buildCompactPrompt(
          language: _getLanguageInstruction(c.language),
          instruction: instruction,
          temaSection: temaSection,
          localizacao: c.localizacao,
          localizationGuidance: localizationGuidance,
          narrativeStyleGuidance: narrativeStyleGuidance,
          customPrompt: c.customPrompt,
          useCustomPrompt: c.useCustomPrompt,
          nameList: nameList,
          trackerInfo: trackerInfo,
          measure: measure,
          isSpanish: isSpanish,
          adjustedTarget: adjustedTarget,
          minAcceptable: minAcceptable,
          maxAcceptable: maxAcceptable,
          limitedNeeded: limitedNeeded,
          contextoPrevio: contextoPrevio,
          avoidRepetition: avoidRepetition,
          characterGuidance: characterGuidance,
          forbiddenNamesWarning: forbiddenNamesWarning,
          labels: labels,
        ) +
        blockInfo;

    if (kDebugMode) {
      debugPrint(
        '[$_instanceId] Gerando bloco balanceado: $limitedNeeded ${c.measureType}',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[$_instanceId] Gerando bloco balanceado: $limitedNeeded ${c.measureType}',
      );
    }

    try {
      // 🚀 GEMINI 2.5 PRO: Suporta até 65.535 tokens de saída!
      // Aumentado para 50.000 tokens (76% da capacidade) para idiomas cirílicos

      // 🌐 AJUSTE: Idiomas não-latinos (cirílico, etc.) consomem mais tokens
      final languageNormalized = c.language.toLowerCase().trim();
      final isCyrillic =
          languageNormalized.contains('russo') ||
          languageNormalized.contains('búlgar') ||
          languageNormalized.contains('bulgar') ||
          languageNormalized == 'ru' ||
          languageNormalized == 'bg';
      final isTurkish =
          languageNormalized.contains('turco') || languageNormalized == 'tr';

      // Cirílico e turco precisam de 5x mais tokens por caractere (aumentado de 4x)
      // Idiomas latinos mantêm 2.5x (aumentado de 2x) para mais margem
      final tokenMultiplier = c.measureType == 'caracteres'
          ? (isCyrillic || isTurkish ? 5.0 : 2.5)
          : 12.0; // Aumentado de 10.0 para 12.0 para palavras

      final maxTokensCalculated = (needed * tokenMultiplier).ceil();
      final maxTokensLimit = 50000; // Aumentado de 32.768 para 50.000 tokens
      final finalMaxTokens = maxTokensCalculated > maxTokensLimit
          ? maxTokensLimit
          : maxTokensCalculated;

      // 🤖 SELEÇÃO DE MODELO BASEADA EM qualityMode
      // 🎯 v7.6.51: Arquitetura Pipeline Modelo Único - usar helper centralizado
      final selectedModel = _getSelectedModel(c.qualityMode);

      if (kDebugMode) {
        debugPrint('[$_instanceId] 🎯 qualityMode = "${c.qualityMode}"');
        debugPrint('[$_instanceId] 🤖 selectedModel = "$selectedModel"');
      }

      final data = await _makeApiRequest(
        apiKey: c.apiKey,
        model: selectedModel,
        prompt: prompt,
        maxTokens: finalMaxTokens,
        tryOpenAIOnFail:
            false, // 🚫 v7.6.19: Desabilitado - usar apenas API selecionada
      );

      // 🚀 v7.6.20: Registrar sucesso da API para Adaptive Delay Manager
      if (data != null && data.isNotEmpty) {
        _recordApiSuccess();
      }

      final text = data ?? '';
      final filtered = text.isNotEmpty
          ? await _filterDuplicateParagraphs(previous, text)
          : '';

      // 🚨 v7.6.21: VALIDAÇÃO CRÍTICA - Nome da protagonista
      if (filtered.isNotEmpty) {
        final isValidProtagonist = _validateProtagonistName(
          filtered,
          c,
          blockNumber,
        );
        if (!isValidProtagonist) {
          if (kDebugMode) {
            debugPrint(
              '❌ BLOCO $blockNumber REJEITADO: Nome errado da protagonista!',
            );
            debugPrint('   🔄 Forçando regeneração...');
          }
          return ''; // Forçar regeneração
        }

        // 🚨 v7.6.22: VALIDAÇÃO CRÍTICA - Relacionamentos familiares
        final hasValidRelationships = _validateFamilyRelationships(
          filtered,
          blockNumber,
        );
        if (!hasValidRelationships) {
          if (kDebugMode) {
            debugPrint(
              '❌ BLOCO $blockNumber REJEITADO: Relacionamentos familiares inconsistentes!',
            );
            debugPrint('   🔄 Forçando regeneração...');
          }
          return ''; // Forçar regeneração
        }

        // 🚨 v7.6.22: RASTREAMENTO - Detectar resolução de personagens
        tracker.detectResolutionInText(filtered, blockNumber);

        // 🚨 v7.6.23: VALIDAÇÃO CRÍTICA - Taxa de fechamento no bloco final
        if (blockNumber == totalBlocks) {
          final closureRate = tracker.getClosureRate();
          final minimumClosureRate = 0.90; // 90% mínimo

          if (closureRate < minimumClosureRate) {
            final unresolved = tracker.getUnresolvedCharacters();
            if (kDebugMode) {
              debugPrint(
                '❌ BLOCO FINAL REJEITADO: Taxa de fechamento insuficiente!',
              );
              debugPrint(
                '   Taxa atual: ${(closureRate * 100).toStringAsFixed(1)}% (mínimo: ${(minimumClosureRate * 100).toInt()}%)',
              );
              debugPrint(
                '   Personagens sem fechamento: ${unresolved.join(", ")}',
              );
              debugPrint(
                '   🔄 Forçando regeneração com fechamentos obrigatórios...',
              );
            }
            return ''; // Força regeneração do bloco final
          } else {
            if (kDebugMode) {
              debugPrint(
                '✅ BLOCO FINAL ACEITO: Taxa de fechamento suficiente!',
              );
              debugPrint('   Taxa: ${(closureRate * 100).toStringAsFixed(1)}%');
            }
          }
        }
      }

      // 🔥 VALIDAÇÃO DE TAMANHO: Rejeitar blocos que ultrapassem muito o limite
      // Aplicável a TODOS os idiomas, não só espanhol
      if (filtered.isNotEmpty && languageMultiplier != 1.0) {
        final wordCount = _countWords(filtered);
        // 🔧 CORREÇÃO: Comparar com adjustedTarget (COM multiplicador), não limitedNeeded (SEM multiplicador)
        final overage = wordCount - adjustedTarget;
        final overagePercent = (overage / adjustedTarget) * 100;

        // 🔥 FIX: Aumentado de 10% → 35% porque API Gemini frequentemente excede 20-30%
        // Rejeitar se ultrapassar mais de 35% do limite AJUSTADO
        if (overagePercent > 35) {
          if (kDebugMode) {
            debugPrint(
              '❌ BLOCO $blockNumber REJEITADO (${c.language.toUpperCase()}):',
            );
            debugPrint('   Multiplicador do idioma: ${languageMultiplier}x');
            debugPrint(
              '   Pedido: $adjustedTarget palavras (limite máximo ajustado)',
            );
            debugPrint(
              '   Recebido: $wordCount palavras (+${overagePercent.toStringAsFixed(1)}%)',
            );
            debugPrint('   🔄 Retornando vazio para forçar regeneração...');
          }
          return ''; // Forçar regeneração
        }

        if (kDebugMode && overage > 0) {
          debugPrint(
            '✅ BLOCO $blockNumber ACEITO (${c.language.toUpperCase()}):',
          );
          debugPrint(
            '   Multiplicador: ${languageMultiplier}x | Pedido: $adjustedTarget palavras',
          );
          debugPrint(
            '   Recebido: $wordCount palavras (+${overagePercent.toStringAsFixed(1)}%)',
          );
        }
      }

      // 🔥 LOGGING: Detectar quando bloco retorna vazio
      if (filtered.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ BLOCO $blockNumber VAZIO DETECTADO!');
          if (data == null) {
            debugPrint(
              '   Causa: API retornou null (bloqueio de conteúdo ou erro)',
            );
          } else if (text.isEmpty) {
            debugPrint('   Causa: Resposta da API estava vazia');
          } else {
            debugPrint('   Causa: Conteúdo filtrado como duplicado');
            debugPrint('   Texto original: ${text.length} chars');
          }
        }
      }

      return filtered.isNotEmpty ? '\n$filtered' : '';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ERRO no bloco $blockNumber: $e');
      }
      return '';
    }
  }

  Future<String?> _makeApiRequest({
    required String apiKey,
    required String model,
    required String prompt,
    required int maxTokens,
    bool tryOpenAIOnFail = false, // 🤖 Novo parâmetro
  }) async {
    try {
      // 🚀 Gemini 2.5 Pro suporta até 65.535 tokens de saída
      // Usando limite generoso para aproveitar capacidade total
      final adjustedMaxTokens = maxTokens < 8192
          ? 8192
          : min(maxTokens * 2, 32768);

      final resp = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': adjustedMaxTokens,
          },
        },
      );

      // Debug completo da resposta
      debugPrint('GeminiService: Status Code: ${resp.statusCode}');
      debugPrint('GeminiService: Response Data: ${resp.data}');

      // Verificar se há erro na resposta
      if (resp.data['error'] != null) {
        debugPrint('GeminiService: API Error: ${resp.data['error']}');
        throw Exception('API Error: ${resp.data['error']['message']}');
      }

      // 🚨 VERIFICAR BLOQUEIO DE CONTEÚDO
      final promptFeedback = resp.data['promptFeedback'];
      if (promptFeedback != null && promptFeedback['blockReason'] != null) {
        final blockReason = promptFeedback['blockReason'];
        debugPrint(
          '🚫 GeminiService: CONTEÚDO BLOQUEADO - Razão: $blockReason',
        );
        debugPrint(
          '⚠️ GeminiService: Contexto contém conteúdo sensível detectado pela API',
        );
        // Retornar null para que o sistema continue sem este bloco
        // O sistema vai tentar continuar com contexto reduzido
        return null;
      }

      // Verificar finish reason
      final finishReason = resp.data['candidates']?[0]?['finishReason'];
      if (finishReason == 'MAX_TOKENS') {
        debugPrint(
          'GeminiService: Aviso - Resposta cortada por limite de tokens',
        );
      }

      // Tentar extrair o texto da estrutura de resposta
      String? result;
      final candidate = resp.data['candidates']?[0];

      if (candidate != null) {
        // Primeiro tentar a estrutura padrão com parts
        result = candidate['content']?['parts']?[0]?['text'] as String?;

        // Se não encontrou, tentar outras estruturas possíveis
        if (result == null || result.isEmpty) {
          result = candidate['content']?['text'] as String?;
        }

        // Se ainda não encontrou, tentar diretamente no candidate
        if (result == null || result.isEmpty) {
          result = candidate['text'] as String?;
        }
      }

      debugPrint('GeminiService: Extracted text: ${result?.length ?? 0} chars');
      debugPrint('GeminiService: Finish reason: $finishReason');

      // Limpar o texto de marcações indesejadas
      if (result != null) {
        result = _cleanGeneratedText(result);
      }

      return result;
    } catch (e) {
      // 🚫 v7.6.19: Fallback OpenAI REMOVIDO - respeitar escolha do usuário
      // Sempre re-throw o erro para que o sistema de retry padrão funcione
      rethrow;
    }
  }

  // Limpar texto de marcações indesejadas
  String _cleanGeneratedText(String text) {
    return text
        // Remove "CONTINUAÇÃO:" no início ou meio do texto
        .replaceAll(RegExp(r'CONTINUAÇÃO:\s*', caseSensitive: false), '')
        // Remove "CONTEXTO FINAL:" se aparecer
        .replaceAll(RegExp(r'CONTEXTO FINAL:\s*', caseSensitive: false), '')
        // Remove linhas vazias duplas
        .replaceAll(RegExp(r'\n\n\n+'), '\n\n')
        // Remove espaços desnecessários no início
        .trim();
  }

  // 🆕 SISTEMA DE RASTREAMENTO DE NOMES - v4 (SOLUÇÃO TÉCNICA)
  /// Extrai nomes próprios capitalizados do texto gerado
  /// Retorna Set de nomes encontrados (não duplicados)
  Set<String> _extractNamesFromText(String text) {
    final names = <String>{};

    // 🎯 v7.6.30: DETECTAR NOMES COMPOSTOS PRIMEIRO (Arthur Evans, Mary Jane, etc)
    // Prioridade: 2-3 palavras capitalizadas consecutivas = nome completo
    final compoundNamePattern = RegExp(
      r'\b([A-ZÀ-Ü][a-zà-ÿ]{1,14}(?:\s+[A-ZÀ-Ü][a-zà-ÿ]{1,14}){1,2})\b',
      multiLine: true,
    );

    final compoundMatches = compoundNamePattern.allMatches(text);
    final processedWords = <String>{}; // Rastrear palavras já processadas

    for (final match in compoundMatches) {
      final fullName = match.group(1);
      if (fullName != null && !_isCommonPhrase(fullName)) {
        names.add(fullName);
        // Marcar cada palavra do nome composto como processada
        for (final word in fullName.split(' ')) {
          processedWords.add(word);
        }
      }
    }

    // 🎯 REGEX v7.6.17 CORRIGIDA: Detectar nomes simples EM QUALQUER POSIÇÃO
    // - Palavra capitalizada (primeira letra maiúscula)
    // - 2-15 letras
    // - ✅ NOVO: Detecta no início de frases, parágrafos E no meio
    // - Filtro: Remove palavras comuns depois
    final namePattern = RegExp(
      r'\b([A-ZÀ-Ü][a-zà-ÿ]{1,14})\b',
      multiLine: true,
    );

    final matches = namePattern.allMatches(text);

    for (final match in matches) {
      final potentialName = match.group(1);
      if (potentialName != null) {
        // 🆕 v7.6.30: Pular se já processado como parte de nome composto
        if (processedWords.contains(potentialName)) {
          continue;
        }

        // 🔥 FILTRO EXPANDIDO: Remover palavras comuns que não são nomes
        // Com a nova regra de capitalização, isso não deveria mais ser necessário,
        // mas mantemos como backup caso o Gemini ignore a instrução
        final commonWords = {
          // Pronomes
          'He', 'She', 'It', 'They', 'We', 'You', 'I',
          // Possessivos
          'My', 'Your', 'His', 'Her', 'Their', 'Our', 'Its',
          // Conjunções
          'And', 'But', 'Or', 'Because', 'So', 'Yet', 'For',
          // Artigos
          'The', 'A', 'An',
          // Preposições comuns
          'In', 'On', 'At', 'To', 'From', 'With', 'By', 'Of', 'As',
          // Advérbios temporais
          'Then',
          'When',
          'After',
          'Before',
          'Now',
          'Today',
          'Tomorrow',
          'Yesterday',
          'While', 'During', 'Since', 'Until', 'Although', 'Though',
          // Advérbios de frequência
          'Always', 'Never', 'Often', 'Sometimes', 'Usually', 'Rarely',
          'Maybe', 'Perhaps', 'Almost', 'Just', 'Only', 'Even', 'Still',
          // Quantificadores
          'Much', 'Many', 'Few', 'Little', 'Some', 'Any', 'All', 'Most',
          'Both', 'Each', 'Every', 'Either', 'Neither', 'One', 'Two', 'Three',
          // Outros comuns
          'This', 'That', 'These', 'Those', 'There', 'Here', 'Where',
          'What', 'Which', 'Who', 'Whose', 'Whom', 'Why', 'How',
          // Verbos comuns no início de frase (menos comum, mas pode acontecer)
          'Was', 'Were', 'Is', 'Are', 'Am', 'Has', 'Have', 'Had',
          'Do', 'Does', 'Did', 'Will', 'Would', 'Could', 'Should',
          'Can', 'May', 'Might', 'Must',
          // Dias da semana (por via das dúvidas)
          'Monday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
          'Mondays',
          'Tuesdays',
          'Wednesdays',
          'Thursdays',
          'Fridays',
          'Saturdays',
          'Sundays',
          // Meses
          'January', 'February', 'March', 'April', 'June',
          'July', 'August', 'September', 'October', 'November', 'December',
          // Palavras portuguesas comuns (backup)
          'Então',
          'Quando',
          'Depois',
          'Antes',
          'Agora',
          'Hoje',
          'Amanhã',
          'Ontem',
          'Naquela',
          'Aquela',
          'Aquele',
          'Naquele',
          'Enquanto',
          'Durante',
          'Embora',
          'Porém', 'Portanto', 'Assim', 'Nunca', 'Sempre', 'Talvez', 'Quase',
          'Apenas', 'Mesmo', 'Também', 'Muito', 'Pouco', 'Tanto', 'Onde',
          'Como', 'Porque', 'Mas', 'Ou', 'Para', 'Com', 'Sem', 'Por',
          // Termos técnicos/financeiros que podem aparecer capitalizados
          'Tax', 'Certificate', 'Bearer', 'Shares', 'Switzerland',
          'Consider', 'Tucked',
        };

        if (!commonWords.contains(potentialName)) {
          names.add(potentialName);
        }
      }
    }

    return names;
  }

  /// 🆕 v7.6.30: Verifica se frase composta é nome real ou expressão comum
  bool _isCommonPhrase(String phrase) {
    final phraseLower = phrase.toLowerCase();

    // Frases comuns que não são nomes de pessoas
    final commonPhrases = {
      'new york', 'los angeles', 'san francisco', 'las vegas',
      'united states', 'north carolina', 'south carolina',
      'good morning', 'good night', 'good afternoon',
      'thank you', 'excuse me', 'oh my',
      'dear god', 'holy shit', 'oh well',
      'right now', 'just then', 'back then',
      'even though', 'as if', 'so much',
      'too much', 'very much', 'much more',
      // Português
      'são paulo', 'rio de', 'belo horizonte',
      'bom dia', 'boa tarde', 'boa noite',
      'meu deus', 'nossa senhora', 'por favor',
      'de repente', 'de novo', 'tão pouco',
    };

    return commonPhrases.contains(phraseLower);
  }

  /// Valida se há nomes duplicados em papéis diferentes
  /// Retorna lista de nomes duplicados encontrados
  List<String> _validateNamesInText(
    String newBlock,
    Set<String> previousNames,
  ) {
    final duplicates = <String>[];
    final newNames = _extractNamesFromText(newBlock);

    for (final name in newNames) {
      if (previousNames.contains(name)) {
        // 🚨 Nome já usado anteriormente!
        if (!duplicates.contains(name)) {
          duplicates.add(name);
        }
      }
    }

    // 🔥 NOVA CAMADA: Validação case-insensitive para nomes em minúsculas
    // Detecta casos como "my lawyer, mark" onde "mark" deveria ser "Mark"
    final previousNamesLower = previousNames
        .map((n) => n.toLowerCase())
        .toSet();

    // Buscar palavras em minúsculas que correspondem a nomes confirmados
    final lowercasePattern = RegExp(r'\b([a-z][a-z]{1,14})\b');
    final lowercaseMatches = lowercasePattern.allMatches(newBlock);

    for (final match in lowercaseMatches) {
      final word = match.group(1);
      if (word != null && previousNamesLower.contains(word.toLowerCase())) {
        // Verificar se não é palavra comum (conjunção, preposição, etc)
        final commonLowerWords = {
          'the',
          'and',
          'but',
          'for',
          'with',
          'from',
          'about',
          'into',
          'through',
          'during',
          'before',
          'after',
          'above',
          'below',
          'between',
          'under',
          'again',
          'further',
          'then',
          'once',
          'here',
          'there',
          'when',
          'where',
          'why',
          'how',
          'all',
          'each',
          'other',
          'some',
          'such',
          'only',
          'own',
          'same',
          'than',
          'too',
          'very',
          'can',
          'will',
          'just',
          'now',
          'like',
          'back',
          'even',
          'still',
          'also',
          'well',
          'way',
          'because',
          'while',
          'since',
          'until',
          'both',
          'was',
          'were',
          'been',
          'being',
          'have',
          'has',
          'had',
          'having',
          'does',
          'did',
          'doing',
          'would',
          'could',
          'should',
          'might',
          'must',
          'shall',
          'may',
        };

        if (!commonLowerWords.contains(word.toLowerCase())) {
          // Encontrar o nome original (capitalizado) na lista
          final originalName = previousNames.firstWhere(
            (n) => n.toLowerCase() == word.toLowerCase(),
            orElse: () => word,
          );

          if (!duplicates.contains(originalName)) {
            duplicates.add(originalName);
            if (kDebugMode) {
              debugPrint(
                '🚨 DUPLICAÇÃO DETECTADA (case-insensitive): "$word" → já existe como "$originalName"',
              );
              debugPrint(
                '   ⚠️ Gemini escreveu nome em minúsculas, mas já foi usado capitalizado antes!',
              );
            }
          }
        }
      }
    }

    return duplicates;
  }

  /// Adiciona nomes novos ao rastreador global
  void _addNamesToTracker(String text) {
    final names = _extractNamesFromText(text);
    _namesUsedInCurrentStory.addAll(names);

    if (kDebugMode && names.isNotEmpty) {
      debugPrint('📝 Nomes extraídos do bloco: ${names.join(", ")}');
      debugPrint(
        '📊 Total de nomes únicos na história: ${_namesUsedInCurrentStory.length}',
      );
    }
  }

  /// Reseta o rastreador de nomes (início de nova história)
  void _resetNameTracker() {
    _namesUsedInCurrentStory.clear();
    if (kDebugMode) {
      debugPrint('🔄 Rastreador de nomes resetado para nova história');
    }
  }

  // Método público para uso nos providers - OTIMIZADO PARA CONTEXTO
  // 🎯 v7.6.51: Suporte a qualityMode para Pipeline Modelo Único
  Future<String> generateTextWithApiKey({
    required String prompt,
    required String apiKey,
    String? model, // Se null, usa qualityMode
    String qualityMode =
        'pro', // 🎯 NOVO: Para determinar modelo automaticamente
    int maxTokens =
        16384, // AUMENTADO: Era 8192, agora 16384 para contextos mais ricos
  }) async {
    // Determinar modelo: usar explícito se fornecido, senão calcular via qualityMode
    final effectiveModel = model ?? _getSelectedModel(qualityMode);
    // CORREÇÃO: Reset de estado para evitar conflitos com geração de scripts
    if (_isCancelled) _isCancelled = false;

    return await _retryOnRateLimit(() async {
      try {
        debugPrint(
          'GeminiService: Iniciando requisição para modelo $effectiveModel',
        );
        final result = await _makeApiRequest(
          apiKey: apiKey,
          model: effectiveModel,
          prompt: prompt,
          maxTokens: maxTokens,
          tryOpenAIOnFail:
              false, // 🚫 v7.6.19: Desabilitado - usar apenas API selecionada
        );

        // 🚀 v7.6.20: Registrar sucesso da API para Adaptive Delay Manager
        if (result != null && result.isNotEmpty) {
          _recordApiSuccess();
        }

        debugPrint(
          'GeminiService: Resposta recebida - ${result != null ? 'Success' : 'Null'}',
        );
        if (result != null) {
          debugPrint('GeminiService: Length: ${result.length}');
        }

        // Aplicar limpeza adicional se necessário
        final cleanResult = result != null ? _cleanGeneratedText(result) : '';
        return cleanResult;
      } catch (e) {
        debugPrint('GeminiService: Erro ao gerar texto: $e');
        throw Exception('Erro ao gerar texto: ${e.toString()}');
      }
    });
  }

  // ===================== SISTEMA ANTI-REPETIÇÃO =====================

  /// Verifica se há duplicação LITERAL de blocos inteiros (cópia exata)
  /// Retorna true se encontrar blocos de 200+ palavras duplicados
  /// 🔥 FORTALECIDO: Detecta duplicações literais com múltiplas camadas
  bool _hasLiteralDuplication(String newBlock, String previousContent) {
    if (previousContent.isEmpty || newBlock.isEmpty) return false;
    if (previousContent.length < 500) {
      return false; // 🔥 REDUZIDO: Era implícito, agora 500
    }

    // 🆕 CAMADA 1: Verificar parágrafos completos duplicados
    final newParagraphs = newBlock
        .split('\n\n')
        .where(
          (p) =>
              p.trim().isNotEmpty && p.trim().split(RegExp(r'\s+')).length > 30,
        )
        .map((p) => p.trim().toLowerCase())
        .toList();

    final prevParagraphs = previousContent
        .split('\n\n')
        .where(
          (p) =>
              p.trim().isNotEmpty && p.trim().split(RegExp(r'\s+')).length > 30,
        )
        .map((p) => p.trim().toLowerCase())
        .toList();

    // 🔥 CRÍTICO: Detectar parágrafos idênticos
    for (final newPara in newParagraphs) {
      for (final prevPara in prevParagraphs) {
        if (newPara == prevPara) {
          if (kDebugMode) {
            debugPrint('🚨 PARÁGRAFO DUPLICADO EXATO DETECTADO!');
            debugPrint(
              '   Preview: ${newPara.substring(0, min(100, newPara.length))}...',
            );
          }
          return true; // Parágrafo duplicado exato
        }

        // 🆕 Verificar início idêntico (primeiras 50 palavras)
        final newWords = newPara.split(RegExp(r'\s+'));
        final prevWords = prevPara.split(RegExp(r'\s+'));

        if (newWords.length > 50 && prevWords.length > 50) {
          final newStart = newWords.take(50).join(' ');
          final prevStart = prevWords.take(50).join(' ');

          if (newStart == prevStart) {
            if (kDebugMode) {
              debugPrint('🚨 INÍCIO DE PARÁGRAFO DUPLICADO DETECTADO!');
              debugPrint('   Primeiras 50 palavras são idênticas');
            }
            return true;
          }
        }
      }
    }

    // 🆕 CAMADA 2: Verificar sequências de palavras (original, mas fortalecido)
    final newWords = newBlock.trim().split(RegExp(r'\s+'));
    final prevWords = previousContent.trim().split(RegExp(r'\s+'));

    if (newWords.length < 150 || prevWords.length < 150) {
      return false; // 🔥 REDUZIDO: Era 200
    }

    // 🔥 OTIMIZADO: Verificar sequências menores (150 palavras)
    for (int i = 0; i <= newWords.length - 150; i++) {
      final newSequence = newWords.sublist(i, i + 150).join(' ').toLowerCase();

      for (int j = 0; j <= prevWords.length - 150; j++) {
        final prevSequence = prevWords
            .sublist(j, j + 150)
            .join(' ')
            .toLowerCase();

        if (newSequence == prevSequence) {
          if (kDebugMode) {
            debugPrint('🚨 DUPLICAÇÃO LITERAL DE 150 PALAVRAS DETECTADA!');
            debugPrint(
              '   Preview: ${newSequence.substring(0, min(100, newSequence.length))}...',
            );
          }
          return true;
        }
      }
    }

    return false;
  }

  /// Calcula similaridade entre dois textos usando n-grams
  /// Retorna valor entre 0.0 (totalmente diferente) e 1.0 (idêntico)
  double _calculateSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    // Normalizar textos (remover espaços extras, lowercase)
    final normalized1 = text1.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final normalized2 = text2.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (normalized1 == normalized2) return 1.0; // Idênticos

    // Criar n-grams (sequências de N palavras)
    const nGramSize =
        8; // 🔥 AUMENTADO: Era 5, agora 8 para detectar blocos maiores
    final words1 = normalized1.split(' ');
    final words2 = normalized2.split(' ');

    if (words1.length < nGramSize || words2.length < nGramSize) {
      // Textos muito curtos, comparar palavra por palavra
      final commonWords = words1.toSet().intersection(words2.toSet()).length;
      return commonWords / max(words1.length, words2.length);
    }

    // Gerar n-grams
    final ngrams1 = <String>{};
    for (int i = 0; i <= words1.length - nGramSize; i++) {
      ngrams1.add(words1.sublist(i, i + nGramSize).join(' '));
    }

    final ngrams2 = <String>{};
    for (int i = 0; i <= words2.length - nGramSize; i++) {
      ngrams2.add(words2.sublist(i, i + nGramSize).join(' '));
    }

    // Calcular interseção (n-grams em comum)
    final intersection = ngrams1.intersection(ngrams2).length;
    final union = ngrams1.union(ngrams2).length;

    return union > 0 ? intersection / union : 0.0;
  }

  /// Verifica se novo bloco é muito similar aos blocos anteriores
  /// Retorna true se similaridade > threshold (padrão 85%) OU se há duplicação literal
  bool _isTooSimilar(
    String newBlock,
    String previousContent, {
    double threshold = 0.85,
  }) {
    if (previousContent.isEmpty) return false;

    // 🔥 PRIORIDADE 1: Verificar duplicação literal de blocos grandes (cópia exata)
    if (_hasLiteralDuplication(newBlock, previousContent)) {
      if (kDebugMode) {
        debugPrint(
          '🚨 BLOQUEIO CRÍTICO: Duplicação literal de bloco inteiro detectada!',
        );
      }
      return true; // Bloquear imediatamente
    }

    // 🚀 OTIMIZAÇÃO: Limitar contexto anterior para comparação
    // 🚨 CRÍTICO: 20k caracteres ainda causava timeout nos blocos finais
    // Reduzido para 12k caracteres (~2k palavras) - suficiente para detectar repetições
    final limitedPrevious = previousContent.length > 12000
        ? previousContent.substring(previousContent.length - 12000)
        : previousContent;

    // Dividir conteúdo anterior em parágrafos
    final paragraphs = limitedPrevious
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    // 🚀 OTIMIZAÇÃO CRÍTICA: Limitar a 10 últimos parágrafos (era 20)
    // Reduzido para eliminar travamentos "não respondendo"
    final recentParagraphs = paragraphs.length > 10
        ? paragraphs.sublist(paragraphs.length - 10)
        : paragraphs;

    // Dividir novo bloco em parágrafos
    final newParagraphs = newBlock
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    // Verificar cada parágrafo novo contra os RECENTES (não todos)
    int highSimilarityCount = 0;

    for (final newPara in newParagraphs) {
      if (newPara.trim().length < 100) {
        continue; // Ignorar parágrafos muito curtos
      }

      // 🚀 OTIMIZAÇÃO: Parar se já encontrou repetição suficiente
      if (highSimilarityCount >= 2) break;

      for (final oldPara in recentParagraphs) {
        if (oldPara.trim().length < 100) continue;

        final similarity = _calculateSimilarity(newPara, oldPara);

        if (similarity >= threshold) {
          highSimilarityCount++;
          if (kDebugMode) {
            debugPrint(
              '⚠️ REPETIÇÃO DETECTADA (parágrafo $highSimilarityCount)!',
            );
            debugPrint(
              '   Similaridade: ${(similarity * 100).toStringAsFixed(1)}% (threshold: ${(threshold * 100).toInt()}%)',
            );
          }

          // 🔥 Se encontrar 2+ parágrafos muito similares = bloco repetido
          if (highSimilarityCount >= 2) {
            if (kDebugMode) {
              debugPrint(
                '🚨 BLOQUEIO: $highSimilarityCount parágrafos com alta similaridade!',
              );
            }
            return true;
          }
          break; // Não precisa comparar esse parágrafo com outros
        }
      }
    }

    return false;
  }

  // Cache para evitar reprocessamento em contagens frequentes
  final Map<int, int> _wordCountCache = {};

  int _countWords(String text) {
    if (text.isEmpty) return 0;

    // Cache baseado no hash do texto (economiza memória vs armazenar string completa)
    final hash = text.hashCode;
    if (_wordCountCache.containsKey(hash)) {
      return _wordCountCache[hash]!;
    }

    // Otimização: trim() uma única vez
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;

    // Conta palavras usando split otimizado
    final count = trimmed.split(RegExp(r'\s+')).length;

    // Limita cache a 100 entradas (previne vazamento de memória)
    if (_wordCountCache.length > 100) {
      _wordCountCache.clear();
    }
    _wordCountCache[hash] = count;

    return count;
  }

  // Método estático para compatibilidade
  static void setApiTier(String tier) {
    // Implementação vazia para compatibilidade
  }

  // =============================================================================
  // 🆕 v7.6.52: WORLD STATE UPDATE - Atualização de Estado via IA (Modelo Único)
  // =============================================================================
  // Arquitetura Pipeline de Modelo Único: O MESMO modelo selecionado pelo usuário
  // é usado para gerar o texto E para atualizar o JSON de estado do mundo.
  // Isso garante consistência de estilo e respeita a configuração do cliente.
  // =============================================================================

  /// 🌍 v7.6.52: Atualiza o World State após gerar um bloco
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏗️ v7.6.64: Métodos _updateWorldState e _generateCompressedSynopsis
  // movidos para WorldStateManager (lib/data/services/scripting/)
  // ===================== MÉTODOS CTA E FERRAMENTAS AUXILIARES =====================

  // 🎯 v7.6.51: Adicionado qualityMode para Pipeline Modelo Único
  Future<Map<String, String>> generateCtasForScript({
    required String scriptContent,
    required String apiKey,
    required List<String> ctaTypes,
    String? customTheme,
    String language = 'Português',
    String perspective =
        'terceira_pessoa', // PERSPECTIVA CONFIGURADA PELO USUÁRIO
    String qualityMode = 'pro', // 🎯 NOVO: Para Pipeline Modelo Único
  }) async {
    try {
      // Usar idioma e perspectiva configurados pelo usuário (não detectar)
      final finalLanguage = language;

      // Analisar contexto da história (Flash para tarefa simples)
      final scriptContext = await _analyzeScriptContext(
        scriptContent,
        apiKey,
        finalLanguage,
        'flash', // v7.6.62: Forcar Flash para analise simples
      );

      // Gerar CTAs contextualizados COM A PERSPECTIVA CONFIGURADA
      final prompt = _buildAdvancedCtaPrompt(
        scriptContent,
        ctaTypes,
        customTheme,
        finalLanguage,
        scriptContext,
        perspective, // USAR PERSPECTIVA DO CONFIG
      );

      final result = await generateTextWithApiKey(
        prompt: prompt,
        apiKey: apiKey,
        qualityMode:
            'flash', // v7.6.62: CTAs sempre usam Flash (tarefa simples)
        maxTokens: 3072,
      );

      if (result.isEmpty) {
        throw Exception('Resposta vazia do Gemini');
      }

      // 🔍 Passar scriptContent para validação de consistência
      return _parseCtaResponseWithValidation(result, ctaTypes, scriptContent);
    } catch (e) {
      if (kDebugMode) debugPrint('Erro generateCtasForScript: $e');
      return {};
    }
  }

  // 🎯 v7.6.51: Adicionado qualityMode para Pipeline Modelo Único
  Future<String> _analyzeScriptContext(
    String scriptContent,
    String apiKey,
    String language,
    String qualityMode, // 🎯 NOVO: Para usar modelo selecionado
  ) async {
    final prompt =
        '''
Analise rapidamente este roteiro em $language e identifique:
1. Tema principal (1-2 palavras)
2. Público-alvo (ex: jovens, adultos, famílias)
3. Tom (ex: motivacional, informativo, dramático)

Responda em formato simples: "Tema: X, Público: Y, Tom: Z"

ROTEIRO:
${scriptContent.substring(0, scriptContent.length > 1000 ? 1000 : scriptContent.length)}
''';

    try {
      final result = await generateTextWithApiKey(
        prompt: prompt,
        apiKey: apiKey,
        qualityMode: qualityMode, // 🎯 Usar modelo selecionado pelo usuário
        maxTokens: 100,
      );
      return result.trim();
    } catch (e) {
      return '';
    }
  }

  String _buildAdvancedCtaPrompt(
    String scriptContent,
    List<String> ctaTypes,
    String? customTheme,
    String language,
    String scriptContext,
    String perspective, // PERSPECTIVA CONFIGURADA PELO USUÁRIO
  ) {
    final ctaDescriptions = _getCtaTypeDescriptions(language);
    final requestedTypes = ctaTypes
        .map(
          (type) =>
              '"$type": ${ctaDescriptions[type] ?? "Call-to-action personalizado"}',
        )
        .join('\n');

    // ⚡ USAR PERSPECTIVA CONFIGURADA PELO USUÁRIO (não detectar)
    final isPrimeiraPessoa = perspective.contains('primeira_pessoa');

    if (kDebugMode) {
      debugPrint('🎯 Perspectiva Configurada pelo Usuário: $perspective');
      debugPrint(
        '   → ${isPrimeiraPessoa ? "PRIMEIRA PESSOA" : "TERCEIRA PESSOA"}',
      );
    }

    final perspectiveInstruction = isPrimeiraPessoa
        ? '''
╔════════════════════════════════════════════════════════════════╗
║ ⚠️ OBRIGATÓRIO: PRIMEIRA PESSOA - NARRADOR = PROTAGONISTA     ║
╚════════════════════════════════════════════════════════════════╝

O NARRADOR É O PROTAGONISTA CONTANDO SUA PRÓPRIA HISTÓRIA.

🚨 REGRA ABSOLUTA: CTAs devem falar como se o PERSONAGEM estivesse pedindo apoio.

✅ CAPITALIZAÇÃO CORRETA:
- "eu", "meu/minha" (MINÚSCULAS no meio da frase!)
- "Eu" (Maiúscula APENAS no início da frase)
- ❌ ERRADO: "EU pensei", "MEU filho", "MINHA casa"
- ✅ CERTO: "Eu pensei", "meu filho", "minha casa"

✅ PALAVRAS OBRIGATÓRIAS:
- "eu", "meu/minha", "minha história", "meu relato", "comigo", "me"

✅ EXEMPLOS CORRETOS (Primeira Pessoa):
• CTA INÍCIO: "Eu estava sem-teto e herdei 47 milhões. Mas a fortuna veio com um diário de vingança. Inscreva-se e deixe seu like para ver onde isso me levou."
• CTA INÍCIO: "Um estranho na rua mudou minha vida em um segundo. Quer saber o que ele me ofereceu? Inscreva-se e deixe seu like!"
• CTA MEIO: "O que você faria no meu lugar? Descobri que meu tio foi traído pelo próprio irmão. Comente o que você acha e compartilhe."
• CTA FINAL: "Minha jornada da rua à redenção acabou. O que você achou dessa reviravolta? Inscreva-se para mais histórias intensas como esta."

❌ PROIBIDO (quebra a perspectiva):
• Falar sobre "o protagonista", "ele/ela", "a história dele/dela"
• Usar "esta história" → Use "minha história"
• Usar nomes próprios em 3ª pessoa → Use "eu/meu"
• Capitalizar tudo: "EU/MEU/MINHA" → Use "eu/meu/minha"
• 🚨 NUNCA use "Se essa reviravolta ME atingiu" → O narrador ESTÁ vivendo a história, não assistindo!
• 🚨 NUNCA use "Se isso TE impactou..." sem contexto específico → Muito genérico!
'''
        : '''
╔════════════════════════════════════════════════════════════════╗
║ ⚠️ OBRIGATÓRIO: TERCEIRA PESSOA - NARRADOR EXTERNO ENVOLVENTE ║
╚════════════════════════════════════════════════════════════════╝

O NARRADOR É UM OBSERVADOR EXTERNO contando a história de outras pessoas.

🚨 REGRA ABSOLUTA: CTAs devem falar dos PERSONAGENS de forma externa, MAS mantendo a INTENSIDADE EMOCIONAL do roteiro!

✅ CAPITALIZAÇÃO CORRETA:
- "esta/esse/essa" (minúsculas no meio da frase!)
- "Esta/Este/Essa" (Maiúscula APENAS no início da frase)
- Nomes próprios sempre com inicial maiúscula: "Kátia", "William"

✅ PALAVRAS OBRIGATÓRIAS:
- Nomes dos personagens (Kátia, William, etc.)
- "ela/dele", "esta história"
- Tom DRAMÁTICO, não jornalístico!

✅ EXEMPLOS CORRETOS (Terceira Pessoa ENVOLVENTE):
• "Kátia descobriu que seu próprio filho transformou sua casa em uma arma. Se esta traição te chocou, inscreva-se e deixe seu like"
• "William escondeu segredos nas paredes por anos. O que você faria no lugar de Kátia? Comente o que está achando"
• "A história de Kátia chegou ao fim com um desfecho poderoso. O que você achou? Inscreva-se para mais histórias como esta"
• "Esta família foi destroçada pela vingança. Compartilhe com quem entende dor de verdade"

❌ EXEMPLOS RUINS (muito formais/distantes):
• "A jornada de [personagem] revelou..." → Parece documentário chato
• "Narrativas que exploram..." → Parece crítica literária
• "Compartilhe esta história com quem aprecia..." → Muito genérico

❌ PROIBIDO (quebra a perspectiva):
• Usar "eu", "meu/minha", "comigo" → Isso é primeira pessoa!
• "Se minha história te tocou" → Use "Se a história de [personagem] te tocou"
• "O que você faria no meu lugar?" → Use "no lugar de [personagem]"

🔥 REGRA DE OURO: Use DETALHES ESPECÍFICOS DO ROTEIRO nos CTAs!
- Não diga "segredo chocante" → Diga "dispositivo de metal corrosivo nas paredes"
- Não diga "decisão difícil" → Diga "expulsar o próprio filho de casa"
- Não diga "jornada emocional" → Diga "descobrir que seu filho é um vingador"
''';

    // 🔥 CORREÇÃO CRÍTICA: Enviar INÍCIO + FINAL do roteiro
    // Para que CTAs de início usem detalhes iniciais E CTAs finais reflitam o desfecho real
    final scriptLength = scriptContent.length;
    final initialChunk = scriptContent.substring(
      0,
      scriptLength > 2000 ? 2000 : scriptLength,
    );

    // Extrair últimos 1500 caracteres (para CTA final analisar o desfecho)
    final finalChunk = scriptLength > 1500
        ? scriptContent.substring(scriptLength - 1500)
        : ''; // Se roteiro for muito curto, final chunk fica vazio

    return '''
🚨🚨🚨 REGRA #0: IDIOMA OBRIGATÓRIO - $language 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ERRO CRÍTICO REAL DETECTADO EM GERAÇÕES ANTERIORES:

❌ ROTEIRO em Français (French), mas CTAs em Português (PT-BR):
   Roteiro: "ma femme m'a quitté pour son patron..."
   CTA ERRADO: "De um professor humilhado a uma fortuna que apaga o passado..."
   → IDIOMA INCONSISTENTE! CTA REJEITADO! ❌

✅ REGRA ABSOLUTA DE IDIOMA:
   • Se roteiro está em $language → TODOS os CTAs em $language
   • ZERO palavras em outro idioma
   • ZERO mistura de idiomas
   • 100% pureza linguística!

🚨 VALIDAÇÃO ANTES DE GERAR:
   1. ❓ "O roteiro está em $language?"
   2. ❓ "Vou escrever os CTAs em $language?"
   3. ❓ "Há alguma palavra em outro idioma nos meus CTAs?"
   → Se SIM na pergunta 3 = PARE! Reescreva em $language!

⚠️ CUIDADO ESPECIAL - ERROS COMUNS POR IDIOMA:
   • English → Não misture: português ("mas", "quando"), espanhol ("pero")
   • Français → Não misture: português ("mas", "de", "para"), inglês ("but", "from")
   • Español → Não misture: português ("mas", "quando"), inglês ("but", "when")
   • Português → Não misture: inglês ("but", "when"), espanhol ("pero", "cuando")

🔴 SE HOUVER UMA ÚNICA PALAVRA EM OUTRO IDIOMA, TODOS OS CTAs SERÃO REJEITADOS!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️⚠️⚠️ ATENÇÃO CRÍTICA: PERSPECTIVA NARRATIVA É A REGRA #1 ⚠️⚠️⚠️

$perspectiveInstruction

═══════════════════════════════════════════════════════════════

Gere CTAs (calls-to-action) personalizados em $language para este roteiro.

CONTEXTO DO ROTEIRO: $scriptContext
TEMA PERSONALIZADO: ${customTheme ?? 'Não especificado'}

ROTEIRO - TRECHO INICIAL (para CTAs de início/meio):
$initialChunk

${finalChunk.isNotEmpty ? '''
═══════════════════════════════════════════════════════════════
ROTEIRO - TRECHO FINAL (para CTA de conclusão):
$finalChunk
═══════════════════════════════════════════════════════════════
''' : ''}
═══════════════════════════════════════════════════════════════
🎯 PROPÓSITO ESPECÍFICO DE CADA TIPO DE CTA:
═══════════════════════════════════════════════════════════════

📌 "subscription" (CTA DE INÍCIO):
   • Objetivo: Pedir INSCRIÇÃO no canal + LIKE
   • Momento: Logo no INÍCIO da história, após o gancho inicial
   
   🚨 ERRO COMUM A EVITAR:
   ❌ "Se essa reviravolta ME atingiu..." → Narrador falando de si mesmo em 3ª pessoa (ERRADO!)
   ❌ "Se essa reviravolta TE atingiu..." → Muito genérico, sem gancho específico
   ❌ "No meu aniversário, meu marido levou tudo..." → NÃO REPITA A PRIMEIRA FRASE DO ROTEIRO! (ERRO FATAL!)
   
   🚨 REGRA CRÍTICA - EXTRAIR DETALHES DO ROTEIRO:
   ❌ PROIBIDO copiar ou parafrasear a primeira frase do roteiro
   ❌ PROIBIDO usar frases genéricas desconectadas do conteúdo
   ✅ OBRIGATÓRIO ler os primeiros 3-5 parágrafos e extrair:
      • Objetos específicos mencionados (bolo, tapete persa, envelope, carro, etc.)
      • Ações concretas (ele saiu, ela encontrou, queimaram, esconderam)
      • Nomes de personagens secundários que aparecem logo no início
      • Locações específicas (sala vazia, escritório, rua X)
   ✅ Use ESSES detalhes para criar o gancho (não invente detalhes!)
   
   💡 MÉTODO CORRETO - ANÁLISE DO INÍCIO DO ROTEIRO:
   1. Leia os primeiros 3-5 parágrafos do roteiro
   2. Liste mentalmente: Quais objetos? Quais ações? Quais nomes?
   3. Escolha 2-3 detalhes MARCANTES (não a primeira frase)
   4. Monte o CTA usando ESSES detalhes específicos
   
   • Exemplo ERRADO (genérico, desconectado):
     ❌ "Minha vida virou do avesso. Inscreva-se para ver o que aconteceu."
   
   • Exemplo CERTO (detalhes reais do roteiro):
     ✅ "Eles levaram tudo, até o tapete persa que herdei. Mas esqueceram meu celular com a gravação. Inscreva-se e deixe seu like para ver minha vingança."
     ✅ "Um bolo de 45 velinhas intacto, uma casa vazia e um envelope pardo. Inscreva-se para descobrir como transformei essa traição em justiça."
   
   ✅ ESTRUTURA CORRETA:
   [2-3 detalhes específicos DO ROTEIRO] + [Promessa de reviravolta/vingança] + "Inscreva-se e deixe seu like"
   
   • Exemplo (1ª pessoa): "Encontrei documentos escondidos no sótão e uma chave que não reconheci. Inscreva-se e deixe seu like para descobrir o que eles revelaram."
   • Exemplo (3ª pessoa): "Kátia descobriu um dispositivo nos canos instalado pelo próprio filho. Inscreva-se para ver sua vingança."

📌 "engagement" (CTA DE MEIO):
   • Objetivo: Pedir COMENTÁRIOS sobre o que estão achando + COMPARTILHAMENTOS
   • Momento: No MEIO da história, após uma reviravolta importante
   • Estrutura: Pergunta direta sobre opinião + "comente o que está achando" + "compartilhe"
   • Exemplo (1ª pessoa): "O que você faria no meu lugar? Comente o que está achando dessa situação e compartilhe com quem entenderia."
   • Exemplo (3ª pessoa): "O que você acha da decisão de Kátia? Comente o que está achando e compartilhe com amigos."

📌 "final" (CTA DE CONCLUSÃO):
   • Objetivo: CTA CONCLUSIVO - história acabou, pedir FEEDBACK + INSCRIÇÃO para mais histórias
   • Momento: No FINAL da história, após a resolução
   
   🚨🚨🚨 ERRO CRÍTICO QUE VOCÊ COMETE SEMPRE:
   ❌ "Levaram tudo... O que você achou dessa frieza?" → Fala como se protagonista ainda estivesse PERDENDO!
   ❌ "Eles me destruíram... Inscreva-se..." → Ignora que a história JÁ TEVE RESOLUÇÃO!
   ❌ Focar na TRAGÉDIA INICIAL em vez do DESFECHO REAL!
   
   🚨 REGRA ABSOLUTA - CTA DEVE REFLETIR O FINAL REAL:
   ✅ OBRIGATÓRIO usar o TRECHO FINAL DO ROTEIRO fornecido acima
   ✅ Identificar o DESFECHO REAL no trecho final:
      • Protagonista venceu? → CTA de VITÓRIA
      • Protagonista perdeu? → CTA de DERROTA
      • Final ambíguo? → CTA de REFLEXÃO
   ✅ Mencionar COMO a história terminou (prisão do vilão, vingança concluída, fuga, morte, reconciliação)
   
   💡 MÉTODO CORRETO - ANÁLISE DO TRECHO FINAL:
   1. Leia o TRECHO FINAL DO ROTEIRO fornecido acima
   2. Pergunte: "Como a protagonista está AGORA?"
      • Vencedora? → "Consegui fazer justiça"
      • Destruída? → "Perdi tudo"
      • Reconstruindo? → "Estou começando de novo"
   3. O CTA deve COMBINAR com esse estado final!
   
   ❌ EXEMPLO ERRADO (final de vitória com CTA de derrota):
   Final do roteiro: "Marcos foi preso. Recuperei meu dinheiro. Era justiça."
   CTA ERRADO: "Levaram tudo e me deixaram sem nada. O que você achou?" ❌
   
   ✅ EXEMPLO CERTO (final de vitória com CTA de vitória):
   Final do roteiro: "Marcos foi preso. Recuperei meu dinheiro. Era justiça."
   CTA CERTO: "Da casa vazia à prisão dele. Recuperei tudo e o coloquei atrás das grades. O que você achou da minha vingança? Inscreva-se para mais histórias de justiça como esta." ✅
   
   ✅ ESTRUTURA CORRETA:
   [Resumo do DESFECHO REAL] + [Mencionar resultado final] + "O que você achou?" + "Inscreva-se para mais histórias"
   
   • Exemplo (final de vitória - 1ª pessoa): 
     ✅ "De vítima a vencedora. Ele está preso, eu recuperei o que era meu. O que você achou dessa virada? Inscreva-se para mais histórias de vingança como esta."
   
   • Exemplo (final de derrota - 1ª pessoa):
     ✅ "Perdi tudo, mas ganhei minha liberdade. Às vezes, recomeçar é a única vitória possível. O que você achou? Inscreva-se para mais histórias intensas."
   
   • Exemplo (final ambíguo - 3ª pessoa):
     ✅ "Kátia expulsou o filho, mas a casa ficou vazia. Será que valeu a pena? O que você acha? Inscreva-se para mais dilemas como este."
   
   🔥 CHECKLIST DO CTA FINAL:
   □ Li o TRECHO FINAL DO ROTEIRO fornecido acima?
   □ Identifiquei se protagonista venceu/perdeu/ficou no meio-termo?
   □ Meu CTA reflete esse desfecho REAL?
   □ Mencionei o resultado concreto (prisão, vitória, perda, fuga)?
   □ Não estou falando da tragédia inicial quando a história já teve resolução?

═══════════════════════════════════════════════════════════════

GERE OS SEGUINTES TIPOS DE CTA:
$requestedTypes

═══════════════════════════════════════════════════════════════

FORMATO DE RESPOSTA (JSON):
{
  "subscription": "texto do CTA aqui",
  "engagement": "texto do CTA aqui",
  "pre_conclusion": "texto do CTA aqui",
  "final": "texto do CTA aqui"
}

═══════════════════════════════════════════════════════════════

REQUISITOS OBRIGATÓRIOS:
1. ⚠️ PERSPECTIVA NARRATIVA É PRIORIDADE #1 - RELEIA AS INSTRUÇÕES NO TOPO AGORA!
2. ⚠️ CAPITALIZAÇÃO CORRETA - "eu/meu/minha" em MINÚSCULAS (não "EU/MEU/MINHA")!
3. 🎯 CADA CTA TEM UM PROPÓSITO ESPECÍFICO - Releia a seção "PROPÓSITO ESPECÍFICO" acima!
   • subscription = inscrição + like
   • engagement = comentários + compartilhamento
   • final = feedback + inscrição para mais histórias
4. 🔥 CTA DE INÍCIO: Extraia detalhes REAIS do TRECHO INICIAL fornecido (objetos, ações, nomes)
5. 🔥 CTA FINAL: Use o TRECHO FINAL fornecido e reflita o DESFECHO REAL (vitória/derrota/recomeço)
6. 🚫 PROIBIDO usar palavras genéricas: "jornada", "narrativa", "explorar", "revelar"
7. ✅ OBRIGATÓRIO mencionar ELEMENTOS CHOCANTES: nomes, objetos, ações específicas
8. Cada CTA: 25-45 palavras (DIRETO E IMPACTANTE, com espaço para CTAs completos)
9. Linguagem VISCERAL e DRAMÁTICA em $language (não formal/acadêmica)
10. Tom emocional IGUAL ao do roteiro (se é intenso, CTA é intenso; se é suave, CTA é suave)
11. Se protagonista tomou DECISÃO EXTREMA (expulsar filho, confrontar vilão), mencione isso!
12. NÃO prometa eventos futuros que já aconteceram no roteiro
13. Retorne JSON válido apenas

⚠️⚠️⚠️ CHECKLIST FINAL - RESPONDA ANTES DE GERAR: ⚠️⚠️⚠️
□ 🚨 TODOS os CTAs estão 100% em $language (ZERO palavras em outro idioma)?
□ Reli as instruções de PERSPECTIVA NARRATIVA no topo?
□ ${isPrimeiraPessoa ? "Vou usar 'eu/meu/minha' em MINÚSCULAS (não EU/MEU/MINHA)?" : "Vou usar nomes próprios/ela/ele/esta história?"}
□ Cada CTA segue seu PROPÓSITO ESPECÍFICO?
  • subscription = inscrição + like?
  • engagement = comentários + compartilhamento?
  • final = feedback + inscrição para mais histórias?
□ No CTA DE INÍCIO: Extraí detalhes REAIS do TRECHO INICIAL fornecido (objetos, ações, nomes)?
□ No CTA DE INÍCIO: NÃO repeti/parafraseei a primeira frase do roteiro?
□ No CTA FINAL: Li o TRECHO FINAL DO ROTEIRO fornecido e identifiquei o DESFECHO REAL?
□ No CTA FINAL: Meu CTA reflete se protagonista venceu/perdeu/está recomeçando?
□ Mencionei DETALHES ESPECÍFICOS do roteiro (nomes, objetos-chave, ações concretas)?
□ EVITEI palavras genéricas ("jornada", "narrativa", "revelar", "explorar")?
□ O tom do CTA está TÃO INTENSO quanto o roteiro?
□ Formato JSON está correto?

🚨 ERROS FATAIS A EVITAR NO CTA DE INÍCIO:
❌ "Se essa reviravolta ME atingiu, inscreva-se..." → Narrador falando de si em 3ª pessoa!
❌ "Se essa história TE impactou..." → Muito genérico, sem gancho!
❌ "No meu aniversário, meu marido levou tudo..." → NUNCA REPITA A PRIMEIRA FRASE DO ROTEIRO! (ERRO CRÍTICO!)
❌ Copiar ou parafrasear a frase de abertura do roteiro → Use OUTROS detalhes específicos!
❌ Frases genéricas desconectadas do texto → Leia os primeiros parágrafos e extraia objetos/ações REAIS!
✅ CORRETO: Extrair 2-3 detalhes específicos dos primeiros parágrafos + promessa de reviravolta
✅ Exemplo: "Eles levaram até o tapete persa. Mas esqueceram meu celular com a gravação. Inscreva-se para ver minha vingança."
✅ Exemplo: "45 velinhas, um bolo intacto e documentos escondidos no sótão. Inscreva-se para descobrir o que eles revelaram."

🚨 ERROS FATAIS A EVITAR NO CTA FINAL:
❌ "Levaram tudo... O que você achou dessa frieza?" → Fala do início quando história já teve resolução!
❌ Ignorar o desfecho real e focar na tragédia inicial → Use o TRECHO FINAL fornecido!
❌ CTA de vítima quando protagonista VENCEU → Desonesto com a história!
❌ CTA de vitória quando protagonista PERDEU → Também desonesto!

🔴 ERRO REAL DETECTADO - AMBIGUIDADE FATAL:
❌ "Da caixa de papelão aos portões da prisão" → Quem foi preso? Protagonista ou vilão?
   • Se VILÃO foi preso: "Da caixa de papelão ao império - e ele atrás das grades"
   • Se PROTAGONISTA foi preso: "Da caixa de papelão à prisão - minha vingança falhou"
   
❌ "Do fracasso à redenção" → Redenção de quem? Protagonista ou antagonista?
   • SEMPRE especifique: "Do fracasso à MINHA redenção" ou "Do fracasso à redenção DELE"

⚠️ REGRA ABSOLUTA DE CLAREZA:
   • CTAs finais DEVEM especificar quem sofreu/venceu
   • Use "EU" (1ª pessoa) ou NOME/ELE/ELA (3ª pessoa)
   • Nunca deixe ambíguo quem foi preso/derrotado/venceu
   
✅ CORRETO: Resumir o DESFECHO REAL do TRECHO FINAL (prisão, vingança concluída, perda, recomeço)
✅ Exemplo (vitória): "Da casa vazia à prisão DELE. Recuperei tudo e o coloquei atrás das grades. O que você achou?"
✅ Exemplo (derrota): "Perdi tudo, mas ganhei liberdade. Recomeçar é a única vitória. O que você achou?"
✅ Exemplo (vitória 3ª pessoa): "Robert passou de mendigo a milionário - e Marcus está na cadeia. O que você achou?"

🚨 SE VOCÊ USAR LINGUAGEM GENÉRICA, CAPITALIZAÇÃO ERRADA, QUEBRAR A PERSPECTIVA OU MISTURAR IDIOMAS, O CTA SERÁ REJEITADO! 🚨

🔴🔴🔴 VALIDAÇÃO FINAL DE IDIOMA ANTES DE ENVIAR: 🔴🔴🔴
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ANTES DE ENVIAR O JSON, RELEIA CADA CTA E PERGUNTE:
❓ "Este CTA está 100% em $language?"
❓ "Há alguma palavra em português/inglês/espanhol/francês (outro idioma)?"
❓ "Se o roteiro é em français, meus CTAs estão em français?"
❓ "Se o roteiro é em english, meus CTAs estão em english?"

SE VOCÊ ENCONTRAR UMA PALAVRA EM IDIOMA ERRADO:
🛑 PARE AGORA!
🛑 REESCREVA O CTA INTEIRO EM $language!
🛑 NÃO ENVIE COM IDIOMA MISTURADO!

⚠️ EXEMPLOS DE ERROS FATAIS:
❌ Roteiro em French, CTA: "De um professor humilhado..." ← Português! ERRO!
❌ Roteiro em Spanish, CTA: "But when everything changed..." ← Inglês! ERRO!
❌ Roteiro em English, CTA: "mas quando tudo mudou..." ← Português! ERRO!

✅ VALIDAÇÃO PASSOU SE:
• Cada CTA usa APENAS palavras de $language
• ZERO palavras de outro idioma
• Linguagem 100% coerente com o roteiro

🚨 LEMBRE-SE: Um único erro de idioma invalida TODOS os CTAs! 🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXEMPLOS DE DETALHES ESPECÍFICOS (use este nível de concretude):
❌ RUIM: "A protagonista descobriu um segredo"
✅ BOM: "Kátia encontrou um dispositivo corrosivo escondido nos canos por William"

❌ RUIM: "Uma decisão difícil foi tomada"
✅ BOM: "Kátia expulsou o próprio filho de casa após descobrir sua vingança"

❌ RUIM: "Se esta história te impactou"
✅ BOM: "Se a traição de William dentro das paredes te chocou"
''';
  }

  Map<String, String> _getCtaTypeDescriptions(String language) {
    return {
      'subscription': 'CTA para inscrição no canal',
      'engagement': 'CTA para interação (like, comentário)',
      'pre_conclusion': 'CTA antes da conclusão',
      'final': 'CTA de fechamento',
    };
  }

  // 🏗️ v7.6.64: _parseCtaResponse removido (não era usado diretamente)

  /// Parse CTA response with script content for validation
  Map<String, String> _parseCtaResponseWithValidation(
    String response,
    List<String> ctaTypes,
    String scriptContent,
  ) {
    try {
      if (kDebugMode) {
        debugPrint(
          '🎯 CTA Response original: ${response.substring(0, response.length > 200 ? 200 : response.length)}...',
        );
      }

      // Remover markdown code blocks (```json ... ```)
      String cleanedResponse = response;
      cleanedResponse = cleanedResponse.replaceAll(RegExp(r'```json\s*'), '');
      cleanedResponse = cleanedResponse.replaceAll(RegExp(r'```\s*'), '');
      cleanedResponse = cleanedResponse.trim();

      if (kDebugMode) {
        debugPrint(
          '🎯 CTA Response limpa: ${cleanedResponse.substring(0, cleanedResponse.length > 200 ? 200 : cleanedResponse.length)}...',
        );
      }

      // Tentar extrair JSON da resposta
      final jsonStart = cleanedResponse.indexOf('{');
      final jsonEnd = cleanedResponse.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('Formato JSON não encontrado na resposta');
      }

      final jsonString = cleanedResponse.substring(jsonStart, jsonEnd + 1);
      if (kDebugMode) {
        debugPrint('🎯 JSON extraído: ${jsonString.length} chars');
      }

      final Map<String, String> ctas = {};
      for (final type in ctaTypes) {
        // Parse multiline: permite quebras de linha e espaços dentro do valor
        // Captura tudo entre as aspas, incluindo quebras de linha
        final pattern = '"$type"\\s*:\\s*"([^"]*(?:\\\\.[^"]*)*)"';
        final regex = RegExp(pattern, multiLine: true, dotAll: true);
        final match = regex.firstMatch(jsonString);
        if (match != null) {
          String ctaText = match.group(1) ?? '';
          // Limpar quebras de linha escapadas e espaços extras
          ctaText = ctaText.replaceAll(RegExp(r'\s+'), ' ').trim();

          // 🔍 VALIDAÇÃO: Se for CTA final e temos conteúdo do roteiro, validar consistência
          if (type == 'final' && scriptContent.isNotEmpty) {
            final inconsistency = _validateFinalCtaConsistency(
              ctaText,
              scriptContent,
            );
            if (inconsistency != null) {
              if (kDebugMode) {
                debugPrint(
                  '⚠️ CTA final inconsistente detectado: $inconsistency',
                );
                debugPrint('   Removendo frases problemáticas...');
              }
              // Remover frases específicas problemáticas automaticamente
              ctaText = ctaText.replaceAll(
                RegExp(
                  'He.s behind bars[^.]*\\.|Ele está preso[^.]*\\.',
                  caseSensitive: false,
                ),
                '',
              );
              ctaText = ctaText.replaceAll(
                RegExp(
                  'behind bars[^,]*,?|atrás das grades[^,]*,?',
                  caseSensitive: false,
                ),
                '',
              );
              ctaText = ctaText.trim();
              if (kDebugMode) {
                debugPrint(
                  '   CTA corrigido: ${ctaText.substring(0, ctaText.length > 100 ? 100 : ctaText.length)}',
                );
              }
            }
          }

          ctas[type] = ctaText;
          if (kDebugMode) {
            debugPrint(
              '✅ CTA extraído [$type]: ${ctaText.substring(0, ctaText.length > 50 ? 50 : ctaText.length)}...',
            );
          }
        } else {
          if (kDebugMode) debugPrint('⚠️ CTA não encontrado para tipo: $type');
        }
      }

      if (kDebugMode) {
        debugPrint(
          '🎯 Total de CTAs extraídos: ${ctas.length}/${ctaTypes.length}',
        );
      }
      return ctas;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao fazer parse dos CTAs: $e');
        debugPrint('Stack trace: $stack');
      }
      return {};
    }
  }

  /// 🔍 Valida consistência do CTA final com o roteiro
  /// Detecta menções a eventos que não aconteceram (ex: "behind bars" sem prisão)
  String? _validateFinalCtaConsistency(String finalCta, String scriptContent) {
    if (kDebugMode) {
      debugPrint('🔍 Validando consistência do CTA final...');
    }

    // Lista de padrões problemáticos e suas validações
    final inconsistencyChecks = [
      {
        'pattern': RegExp(
          r'behind bars|atrás das grades|na cadeia|preso|imprisoned|arrested|jail',
          caseSensitive: false,
        ),
        'requiredInScript': RegExp(
          r'foi preso|was arrested|prisão|prison|cadeia|jail|condenado|sentenced|behind bars|atrás das grades',
          caseSensitive: false,
        ),
        'errorMessage':
            'CTA menciona prisão, mas roteiro não indica que alguém foi preso',
      },
      {
        'pattern': RegExp(
          r"he's dead|ela? morreu|she's dead|morte del[ea]|death|dead",
          caseSensitive: false,
        ),
        'requiredInScript': RegExp(
          r'morreu|died|death|funeral|enterro|corpo|body|faleceu|passed away',
          caseSensitive: false,
        ),
        'errorMessage':
            'CTA menciona morte, mas roteiro não indica que alguém morreu',
      },
      {
        'pattern': RegExp(
          r'lost everything|perdi tudo|left with nothing|fiquei sem nada',
          caseSensitive: false,
        ),
        'requiredInScript': RegExp(
          r'perdi tudo|lost everything|nada restou|nothing left|destruíd[oa]',
          caseSensitive: false,
        ),
        'errorMessage':
            'CTA menciona perda total, mas roteiro sugere vitória ou recuperação',
      },
    ];

    // Verificar cada inconsistência potencial
    for (final check in inconsistencyChecks) {
      final pattern = check['pattern'] as RegExp;
      final required = check['requiredInScript'] as RegExp;
      final errorMsg = check['errorMessage'] as String;

      // Se CTA menciona o padrão problemático
      if (pattern.hasMatch(finalCta)) {
        // Mas o roteiro NÃO contém o evento correspondente
        if (!required.hasMatch(scriptContent)) {
          if (kDebugMode) {
            debugPrint('⚠️ INCONSISTÊNCIA DETECTADA: $errorMsg');
            debugPrint(
              '   CTA: ${finalCta.substring(0, finalCta.length > 100 ? 100 : finalCta.length)}',
            );
          }
          return errorMsg;
        }
      }
    }

    if (kDebugMode) {
      debugPrint('✅ CTA final validado - sem inconsistências detectadas');
    }
    return null; // Sem inconsistências
  }
}

// 🔥 SOLUÇÃO 3: Tracker GLOBAL para manter personagens entre blocos
/// 📝 Classe para armazenar uma nota sobre um personagem em um bloco específico
class _CharacterNote {
  final int blockNumber;
  final String observation;
  final DateTime timestamp;

  _CharacterNote(this.blockNumber, this.observation)
    : timestamp = DateTime.now();

  @override
  String toString() => '[Bloco $blockNumber] $observation';
}

/// 📚 Classe para armazenar o histórico completo de um personagem
class _CharacterHistory {
  final String name;
  final List<_CharacterNote> timeline = [];

  _CharacterHistory(this.name);

  /// Adiciona uma nova observação sobre o personagem
  void addNote(int blockNumber, String observation) {
    if (observation.isEmpty) return;
    timeline.add(_CharacterNote(blockNumber, observation));
    if (kDebugMode) {
      debugPrint('📝 Nota adicionada: "$name" → [B$blockNumber] $observation');
    }
  }

  /// Retorna o histórico completo formatado
  String getFullHistory() {
    if (timeline.isEmpty) return '';
    return timeline.map((e) => e.toString()).join('\n   ');
  }

  /// Verifica se uma nova observação contradiz o histórico
  bool contradicts(String newObservation) {
    if (timeline.isEmpty) return false;

    // Extrair palavras-chave da nova observação
    final newKeywords = _extractRelationshipKeywords(newObservation);

    // Verificar se contradiz alguma nota anterior
    for (final note in timeline) {
      final existingKeywords = _extractRelationshipKeywords(note.observation);

      // Se ambos têm palavras de relacionamento, verificar contradição
      if (newKeywords.isNotEmpty && existingKeywords.isNotEmpty) {
        // Relacionamentos diferentes para o mesmo tipo = contradição
        if (_areContradictoryRelationships(existingKeywords, newKeywords)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Extrai palavras-chave de relacionamento de uma observação
  Set<String> _extractRelationshipKeywords(String text) {
    final keywords = <String>{};
    final lowerText = text.toLowerCase();

    // Padrões de relacionamento
    final patterns = {
      'irmã': r'irmã\s+de\s+(\w+)',
      'irmão': r'irmão\s+de\s+(\w+)',
      'filho': r'filh[oa]\s+de\s+(\w+)',
      'pai': r'pai\s+de\s+(\w+)',
      'mãe': r'mãe\s+de\s+(\w+)',
      'esposa': r'esposa\s+de\s+(\w+)',
      'marido': r'marido\s+de\s+(\w+)',
      'neto': r'net[oa]\s+de\s+(\w+)',
      'tio': r'ti[oa]\s+de\s+(\w+)',
      'primo': r'prim[oa]\s+de\s+(\w+)',
      'avô': r'av[ôó]\s+de\s+(\w+)',
    };

    for (final entry in patterns.entries) {
      final regex = RegExp(entry.value, caseSensitive: false);
      final match = regex.firstMatch(lowerText);
      if (match != null) {
        keywords.add('${entry.key}_${match.group(1)}');
      }
    }

    return keywords;
  }

  /// Verifica se dois conjuntos de relacionamentos são contraditórios
  bool _areContradictoryRelationships(Set<String> existing, Set<String> new_) {
    for (final existingRel in existing) {
      final existingType = existingRel.split('_')[0];

      for (final newRel in new_) {
        final newType = newRel.split('_')[0];

        // Mesmo tipo de relacionamento mas com pessoas diferentes = contradição
        if (existingType == newType && existingRel != newRel) {
          if (kDebugMode) {
            debugPrint('🚨 CONTRADIÇÃO DETECTADA:');
            debugPrint('   Existente: $existingRel');
            debugPrint('   Nova: $newRel');
          }
          return true;
        }
      }
    }

    return false;
  }

  /// Retorna a primeira nota (papel inicial do personagem)
  String? get initialRole {
    return timeline.isEmpty ? null : timeline.first.observation;
  }

  /// Retorna número de aparições do personagem
  int get appearanceCount => timeline.length;
}

class _CharacterTracker {
  final Set<String> _confirmedNames = {};
  // 🔥 NOVO: Mapear cada nome ao seu papel para prevenir confusão e reuso
  final Map<String, String> _characterRoles = {};
  // � v1.7 NOVO: MAPEAMENTO REVERSO papel → nome (detecta nomes múltiplos por papel)
  final Map<String, String> _roleToName = {};
  // �📚 SISTEMA DE NOTAS: Histórico completo de cada personagem
  final Map<String, _CharacterHistory> _characterHistories = {};
  // 🆕 v7.6.17: Nome da protagonista detectado automaticamente no Bloco 1
  String? _detectedProtagonistName;

  /// 🆕 v7.6.25: Retorna false se nome foi rejeitado (papel duplicado)
  bool addName(String name, {String? role, int? blockNumber}) {
    if (name.isEmpty || name.length <= 2) return true; // Nome vazio não é erro

    // 🆕 v7.6.30: VALIDAÇÃO DE SIMILARIDADE - Detectar variações de nomes
    // Evita: "Arthur" vs "Arthur Evans", "John" vs "John Smith"
    final nameLower = name.toLowerCase();
    final nameWords = nameLower.split(' ');

    for (final existingName in _confirmedNames) {
      final existingLower = existingName.toLowerCase();
      final existingWords = existingLower.split(' ');

      // Caso 1: Nome exato (case-insensitive)
      if (nameLower == existingLower) {
        if (kDebugMode) {
          final existingRole = _characterRoles[existingName] ?? 'desconhecido';
          debugPrint(
            '❌ v7.6.30 BLOQUEIO: "$name" já usado como "$existingRole"!',
          );
        }
        return true; // Duplicata exata
      }

      // Caso 2: Sobreposição de palavras (Arthur ⊂ Arthur Evans)
      // "Arthur" está contido em "Arthur Evans" ou vice-versa
      bool overlap = false;

      if (nameWords.length == 1 && existingWords.length > 1) {
        // Novo nome simples, já existe composto
        if (existingWords.contains(nameLower)) {
          overlap = true;
        }
      } else if (nameWords.length > 1 && existingWords.length == 1) {
        // Novo nome composto, já existe simples
        if (nameWords.contains(existingLower)) {
          overlap = true;
        }
      } else if (nameWords.length > 1 && existingWords.length > 1) {
        // Ambos compostos - verificar se compartilham palavras
        final commonWords = nameWords.toSet().intersection(
          existingWords.toSet(),
        );
        if (commonWords.isNotEmpty) {
          overlap = true;
        }
      }

      if (overlap) {
        if (kDebugMode) {
          final existingRole = _characterRoles[existingName] ?? 'desconhecido';
          debugPrint('🚨🚨🚨 v7.6.30: CONFLITO DE NOMES DETECTADO! 🚨🚨🚨');
          debugPrint('   ❌ Nome novo: "$name"');
          debugPrint(
            '   ❌ Nome existente: "$existingName" (papel: $existingRole)',
          );
          debugPrint('   ⚠️ PROBLEMA: Nomes com sobreposição de palavras!');
          debugPrint('   💡 EXEMPLO: "Arthur" conflita com "Arthur Evans"');
          debugPrint('   💡 SOLUÇÃO: Use nomes COMPLETAMENTE diferentes');
          debugPrint('   ❌ BLOQUEANDO adição de "$name"!');
          debugPrint('🚨🚨🚨 FIM DO ALERTA 🚨🚨🚨');
        }
        return true; // Bloquear sobreposição
      }
    }

    // 🔒 VALIDAÇÃO CRÍTICA: Bloquear reuso de nomes
    if (_confirmedNames.contains(name)) {
      if (kDebugMode) {
        final existingRole = _characterRoles[name] ?? 'desconhecido';
        debugPrint(
          '❌ BLOQUEIO DE REUSO: "$name" já usado como "$existingRole"!',
        );
        if (role != null && role != existingRole) {
          debugPrint(
            '   ⚠️ Tentativa de reusar "$name" como "$role" → REJEITADO!',
          );
        }
      }
      return true; // Nome duplicado, mas não é erro de papel
    }

    // 🚨 v7.6.25: VALIDAÇÃO REVERSA - Um papel pode ter apenas UM nome
    if (role != null && role.isNotEmpty && role != 'indefinido') {
      // Normalizar papel (remover detalhes específicos para comparação)
      final normalizedRole = _normalizeRole(role);

      if (_roleToName.containsKey(normalizedRole)) {
        final existingName = _roleToName[normalizedRole]!;

        if (existingName != name) {
          // 🚨 ERRO CRÍTICO: Mesmo papel com nomes diferentes!
          if (kDebugMode) {
            debugPrint(
              '🚨🚨🚨 ERRO CRÍTICO v7.6.25: MÚLTIPLOS NOMES PARA MESMO PAPEL 🚨🚨🚨',
            );
            debugPrint('   ❌ Papel: "$normalizedRole"');
            debugPrint('   ❌ Nome original: "$existingName"');
            debugPrint('   ❌ Nome novo (CONFLITANTE): "$name"');
            debugPrint(
              '   💡 EXEMPLO DO BUG: "advogado" sendo Martin no bloco 2 e Richard no bloco 7!',
            );
            debugPrint(
              '   ⚠️ BLOQUEANDO adição de "$name" - usar apenas "$existingName"!',
            );
            debugPrint('🚨🚨🚨 FIM DO ALERTA 🚨🚨🚨');
          }
          return false; // ❌ RETORNA FALSE = ERRO DETECTADO
        }
      } else {
        // Primeiro nome para este papel - registrar no mapeamento reverso
        _roleToName[normalizedRole] = name;
        if (kDebugMode) {
          debugPrint('🔗 MAPEAMENTO REVERSO: "$normalizedRole" → "$name"');
        }
      }
    }

    _confirmedNames.add(name);
    if (role != null && role.isNotEmpty) {
      _characterRoles[name] = role;
      if (kDebugMode) {
        debugPrint('✅ MAPEAMENTO: "$name" = "$role"');
      }

      // 📚 SISTEMA DE NOTAS: Adicionar ao histórico
      if (blockNumber != null) {
        addNoteToCharacter(name, blockNumber, role);
      }
    }

    return true; // ✅ SUCESSO
  }

  /// 🔧 v7.6.26: Normaliza papel SELETIVAMENTE (evita falsos positivos)
  ///
  /// PAPÉIS FAMILIARES: Mantém completo "mãe de Emily" ≠ "mãe de Michael"
  /// PAPÉIS GENÉRICOS: Normaliza "advogado de Sarah" → "advogado"
  String _normalizeRole(String role) {
    final roleLower = role.toLowerCase().trim();

    // 🔥 v7.6.26: PAPÉIS FAMILIARES - NÃO normalizar (manter contexto familiar)
    final familyRoles = [
      'mãe',
      'pai',
      'filho',
      'filha',
      'irmão',
      'irmã',
      'avô',
      'avó',
      'tio',
      'tia',
      'primo',
      'prima',
      'sogro',
      'sogra',
      'cunhado',
      'cunhada',
      'mother',
      'father',
      'son',
      'daughter',
      'brother',
      'sister',
      'grandfather',
      'grandmother',
      'uncle',
      'aunt',
      'cousin',
      'father-in-law',
      'mother-in-law',
      'brother-in-law',
      'sister-in-law',
      'mère',
      'père',
      'fils',
      'fille',
      'frère',
      'sœur',
      'grand-père',
      'grand-mère',
      'oncle',
      'tante',
      'cousin',
      'cousine',
    ];

    // Verificar se é papel familiar
    for (final familyRole in familyRoles) {
      if (roleLower.contains(familyRole)) {
        return roleLower; // Manter completo
      }
    }

    // 🔧 PAPÉIS GENÉRICOS: Normalizar
    final normalized = roleLower
        .replaceAll(RegExp(r'\s+de\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇa-záàâãéêíóôõúç]+.*$'), '')
        .trim();

    return normalized;
  }

  /// 📝 Adiciona uma nota sobre um personagem
  void addNoteToCharacter(String name, int blockNumber, String observation) {
    if (!_characterHistories.containsKey(name)) {
      _characterHistories[name] = _CharacterHistory(name);
    }

    // Verificar se a nova observação contradiz o histórico
    final history = _characterHistories[name]!;
    if (history.contradicts(observation)) {
      if (kDebugMode) {
        debugPrint('🚨🚨🚨 CONTRADIÇÃO NO HISTÓRICO DE "$name" 🚨🚨🚨');
        debugPrint('   📚 Histórico existente:');
        debugPrint('   ${history.getFullHistory()}');
        debugPrint('   ⚠️ Nova observação contraditória: $observation');
        debugPrint('   💡 Esta observação NÃO será adicionada!');
        debugPrint('🚨🚨🚨 FIM DO ALERTA 🚨🚨🚨');
      }
      return; // Bloqueia adição de observação contraditória
    }

    history.addNote(blockNumber, observation);
  }

  /// 📖 Obtém o histórico completo de um personagem
  String? getCharacterHistory(String name) {
    final history = _characterHistories[name];
    return history?.getFullHistory();
  }

  /// 📊 Obtém estatísticas de um personagem
  Map<String, dynamic> getCharacterStats(String name) {
    final history = _characterHistories[name];
    if (history == null) return {};

    return {
      'name': name,
      'initial_role': history.initialRole,
      'appearances': history.appearanceCount,
      'full_history': history.getFullHistory(),
    };
  }

  void addNames(List<String> names) {
    for (final name in names) {
      addName(name);
    }
  }

  Set<String> get confirmedNames => Set.unmodifiable(_confirmedNames);

  bool hasName(String name) => _confirmedNames.contains(name);

  String? getRole(String name) => _characterRoles[name];

  /// 🆕 v7.6.35: Expõe o mapa roleToName para o PostGenerationFixer
  Map<String, String> get roleToNameMap => Map.unmodifiable(_roleToName);

  /// 🔍 v1.7: Obtém o nome associado a um papel (mapeamento reverso)
  String? getNameForRole(String role) {
    final normalizedRole = _normalizeRole(role);
    return _roleToName[normalizedRole];
  }

  /// 🔍 v1.7: Verifica se um papel já tem nome definido
  bool roleHasName(String role) {
    final normalizedRole = _normalizeRole(role);
    return _roleToName.containsKey(normalizedRole);
  }

  // 🔥 v7.6.28: Obter mapeamento completo de personagens + LISTA DE NOMES PROIBIDOS
  String getCharacterMapping() {
    if (_characterRoles.isEmpty && _characterHistories.isEmpty) return '';

    final buffer = StringBuffer('\n🎭 PERSONAGENS JÁ DEFINIDOS:\n');

    // 🚨 v7.6.28: LISTA CRÍTICA DE NOMES JÁ USADOS (NUNCA REUTILIZAR!)
    if (_confirmedNames.isNotEmpty) {
      buffer.writeln('\n🚫 NOMES JÁ USADOS - NUNCA REUTILIZE ESTES NOMES:');
      final namesList = _confirmedNames.toList()..sort();
      for (final name in namesList) {
        final role = _characterRoles[name] ?? 'indefinido';
        buffer.writeln('   ❌ "$name" (já é: $role)');
      }
      buffer.writeln('\n⚠️ REGRA ABSOLUTA: Cada nome deve ser ÚNICO!');
      buffer.writeln('⚠️ Se precisa de novo personagem, use NOME DIFERENTE!');
      buffer.writeln(
        '⚠️ NUNCA use "Mark", "Charles", etc se já estão acima!\n',
      );
    }

    // v1.7: Mostrar mapeamento reverso (papel → nome) para reforçar consistência
    if (_roleToName.isNotEmpty) {
      buffer.writeln(
        '\n📋 MAPEAMENTO PAPEL → NOME (use SEMPRE os mesmos nomes):',
      );
      for (final entry in _roleToName.entries) {
        buffer.writeln(
          '   "${entry.key}" = "${entry.value}" ⚠️ NUNCA mude este nome!',
        );
      }
      buffer.writeln();
    }

    // Para cada personagem, mostrar histórico completo se disponível
    for (final name in _confirmedNames) {
      final history = _characterHistories[name];

      if (history != null && history.timeline.isNotEmpty) {
        // Mostrar histórico completo
        buffer.writeln('\n👤 $name:');
        buffer.writeln('   ${history.getFullHistory()}');
        buffer.writeln(
          '   ⚠️ NUNCA mude este personagem! Use outro nome para novos personagens.',
        );
      } else {
        // Mostrar apenas papel básico
        final role = _characterRoles[name] ?? 'personagem';
        buffer.writeln('   "$name" = $role');
      }
    }

    return buffer.toString();
  }

  /// 🆕 v7.6.17: Registra o nome da protagonista detectado no Bloco 1
  void setProtagonistName(String name) {
    if (_detectedProtagonistName == null) {
      _detectedProtagonistName = name.trim();
      if (kDebugMode) {
        debugPrint('✅ Protagonista detectada: "$_detectedProtagonistName"');
      }
    }
  }

  /// 🆕 v7.6.17: Retorna o nome da protagonista registrado
  String? getProtagonistName() => _detectedProtagonistName;

  /// 🆕 v7.6.22: RASTREAMENTO DE FECHAMENTO DE PERSONAGENS
  /// Marca um personagem como "resolvido" no final da história
  final Map<String, bool> _characterResolution = {};

  /// Marca um personagem como tendo recebido fechamento/resolução
  void markCharacterAsResolved(String name) {
    if (_confirmedNames.contains(name)) {
      _characterResolution[name] = true;
      if (kDebugMode) {
        debugPrint('✅ PERSONAGEM RESOLVIDO: $name');
      }
    }
  }

  /// Detecta automaticamente personagens que receberam fechamento no texto
  void detectResolutionInText(String text, int blockNumber) {
    // Padrões que indicam fechamento de personagem
    final resolutionPatterns = [
      // Conclusão física/localização
      RegExp(
        r'([A-Z][a-z]+)\s+(?:foi embora|left|partiu|morreu|died|desapareceu|vanished)',
        caseSensitive: false,
      ),
      RegExp(
        r'([A-Z][a-z]+)\s+(?:nunca mais|never again|jamais)',
        caseSensitive: false,
      ),

      // Justiça/vingança
      RegExp(
        r'([A-Z][a-z]+)\s+(?:foi preso|was arrested|foi condenado|was convicted)',
        caseSensitive: false,
      ),
      RegExp(
        r'([A-Z][a-z]+)\s+(?:confessou|confessed|admitiu|admitted)',
        caseSensitive: false,
      ),

      // Reconciliação/paz
      RegExp(
        r'([A-Z][a-z]+)\s+(?:me perdoou|forgave me|fez as pazes|made peace)',
        caseSensitive: false,
      ),
      RegExp(
        r'([A-Z][a-z]+)\s+(?:finalmente|finally|por fim|at last)\s+(?:tinha|had|conseguiu|achieved)',
        caseSensitive: false,
      ),

      // Estado emocional final
      RegExp(
        r'([A-Z][a-z]+)\s+(?:estava feliz|was happy|encontrou paz|found peace)',
        caseSensitive: false,
      ),
      RegExp(
        r'([A-Z][a-z]+)\s+(?:seguiu em frente|moved on|superou|overcame)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in resolutionPatterns) {
      for (final match in pattern.allMatches(text)) {
        final name = match.group(1);
        if (name != null && _confirmedNames.contains(name)) {
          markCharacterAsResolved(name);
          addNoteToCharacter(name, blockNumber, 'RESOLUÇÃO: ${match.group(0)}');
        }
      }
    }
  }

  /// Retorna lista de personagens sem fechamento
  List<String> getUnresolvedCharacters() {
    final unresolved = <String>[];

    for (final name in _confirmedNames) {
      // Ignorar protagonista (sempre tem fechamento implícito)
      if (name == _detectedProtagonistName) continue;

      final role = _characterRoles[name]?.toLowerCase() ?? '';

      // 🐛 FIX v7.6.24: Ignorar personagens SEM histórico OU muito secundários (≤1 aparição)
      final history = _characterHistories[name];
      if (history == null || history.appearanceCount <= 1) continue;

      // Personagens importantes que precisam de fechamento:
      // - Família próxima (pai, mãe, irmão, filho, cônjuge)
      // - Antagonistas/vilões
      // - Ajudantes/aliados que apareceram múltiplas vezes (3+)
      final needsClosure =
          role.contains('marido') ||
          role.contains('esposa') ||
          role.contains('pai') ||
          role.contains('mãe') ||
          role.contains('filho') ||
          role.contains('filha') ||
          role.contains('irmão') ||
          role.contains('irmã') ||
          role.contains('husband') ||
          role.contains('wife') ||
          role.contains('father') ||
          role.contains('mother') ||
          role.contains('son') ||
          role.contains('daughter') ||
          role.contains('brother') ||
          role.contains('sister') ||
          role.contains('amigo') ||
          role.contains('friend') ||
          role.contains('advogad') ||
          role.contains('lawyer') ||
          role.contains('sócio') ||
          role.contains('partner') ||
          history.appearanceCount >= 3; // history guaranteed non-null here

      if (needsClosure && !(_characterResolution[name] ?? false)) {
        unresolved.add(name);
      }
    }

    return unresolved;
  }

  /// Calcula taxa de fechamento de personagens (0.0 a 1.0)
  double getClosureRate() {
    final important = _confirmedNames.where((name) {
      if (name == _detectedProtagonistName) return false;
      final history = _characterHistories[name];
      // 🐛 FIX v7.6.24: Excluir personagens SEM histórico OU com 1 aparição
      if (history == null || history.appearanceCount <= 1) return false;
      return true;
    }).toList();

    if (important.isEmpty) return 1.0;

    final resolved = important
        .where((name) => _characterResolution[name] ?? false)
        .length;
    return resolved / important.length;
  }

  void clear() {
    _confirmedNames.clear();
    _detectedProtagonistName = null;
    _characterRoles.clear();
    _roleToName.clear(); // v1.7: Limpar mapeamento reverso
    _characterHistories.clear();
    _characterResolution.clear(); // v7.6.22: Limpar resoluções
  }
}

// =============================================================================
// 🏗️ v7.6.64: WORLD STATE migrado para scripting/world_state_manager.dart
// =============================================================================
// As classes WorldState e WorldCharacter agora estão no módulo dedicado.
// Import: package:flutter_gerador/data/services/scripting/scripting_modules.dart
// =============================================================================
