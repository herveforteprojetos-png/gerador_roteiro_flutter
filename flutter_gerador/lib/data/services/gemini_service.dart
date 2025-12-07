import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/script_result.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';
import 'package:flutter_gerador/data/models/localization_level.dart';
import 'package:flutter_gerador/data/models/debug_log.dart';
import 'gemini/gemini_modules.dart'; // ?? v7.6.35: Inclui PostGenerationFixer via barrel

// ?? NOVOS M?DULOS DE PROMPTS (Refatora??o v2.0)
import 'package:flutter_gerador/data/services/prompts/main_prompt_template.dart';

// ??? v7.6.64: M?DULOS REFATORADOS (Arquitetura SOLID)
import 'package:flutter_gerador/data/services/scripting/scripting_modules.dart';

// ??? v7.6.65: M?DULOS EXTRA?DOS (Refatora??o SOLID - Fase 1)
import 'package:flutter_gerador/data/services/gemini/detection/detection_modules.dart';
// ignore: unused_import
import 'package:flutter_gerador/data/services/gemini/infra/infra_modules.dart'; // Para uso futuro

// ??? v7.6.66: M�DULOS EXTRA�DOS (Refatora��o SOLID - Fase 2)
import 'package:flutter_gerador/data/services/gemini/tools/tools_modules.dart';

// 🏗️ v7.6.67: MÓDULOS DE VALIDAÇÃO (Refatoração SOLID - Fase 5)
import 'package:flutter_gerador/data/services/gemini/validation/name_constants.dart';
// name_validator.dart exportado via gemini_modules.dart
import 'package:flutter_gerador/data/services/gemini/validation/relationship_patterns.dart';
import 'package:flutter_gerador/data/services/gemini/validation/role_patterns.dart';

// 🏗️ v7.6.70: MÓDULOS DE PROMPTS (Refatoração SOLID)
// narrative_styles.dart exportado via gemini_modules.dart
// perspective_builder.dart exportado via gemini_modules.dart

// ??? v7.6.72: M�DULO TRACKING (Refatora��o SOLID)
// character_tracker.dart exportado via gemini_modules.dart

/// ?? Helper padronizado para logs (mant�m emojis em debug, limpa em produ��o)
void _log(String message, {String level = 'info'}) {
  if (kDebugMode) {
    // Debug: mant?m emojis e formata??o original
    debugPrint(message);
  } else if (level == 'error' || level == 'critical') {
    // Produ??o: apenas erros cr?ticos, sem emojis
    final cleaned = message
        .replaceAll(RegExp(r'[????????????????????]'), '')
        .trim();
    debugPrint('[${level.toUpperCase()}] $cleaned');
  }
  // Produção: info/warning não logam (evita spam)
}

/// 🏗️ v7.6.65: FUNÇÕES TOP-LEVEL DELEGANDO PARA MÓDULOS (Refatoração SOLID)
/// 🔧 v7.6.78: _filterDuplicateParagraphsStatic removido (delegado ao TextFilter)

/// 🚀 FUNÇÃO TOP-LEVEL para execução em Isolate separado
/// Evita travar UI thread durante verificação de repetição
Map<String, dynamic> _isTooSimilarInIsolate(Map<String, dynamic> params) {
  return isTooSimilarIsolate(params);
}

/// Implementação consolidada limpa do GeminiService
class GeminiService {
  final Dio _dio;
  final String _instanceId;
  bool _isCancelled = false;

  // ??? v7.6.64: M?DULOS REFATORADOS (Arquitetura SOLID)
  late final LlmClient _llmClient;
  late final WorldStateManager _worldStateManager;
  late final ScriptValidator _scriptValidator;

  // ??? v7.6.65: M?DULOS EXTRA?DOS (Refatora??o SOLID - Fase 1)
  // Nota: DuplicationDetector e TextCleaner s?o classes est?ticas
  // NameTracker e RateLimiter dispon?veis para uso futuro via imports

  // ?? v7.6.20: Adaptive Delay Manager (economia de 40-50% do tempo)
  DateTime? _lastSuccessfulCall;
  int _consecutive503Errors = 0;
  int _consecutiveSuccesses = 0;

  // Debug Logger
  final _debugLogger = DebugLogManager();

  // ?? SISTEMA DE RASTREAMENTO DE NOMES - v4 (SOLU??O T?CNICA)
  // Armazena todos os nomes usados na hist?ria atual para prevenir duplica??es
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
  // OTIMIZADO: Configura??o mais agressiva baseada nos limites reais do Gemini
  static int _globalRequestCount = 0;
  static DateTime _globalLastRequestTime = DateTime.now();
  static const Duration _rateLimitWindow = Duration(
    seconds: 60,
  ); // AUMENTADO: Era 10s, agora 60s
  static const int _maxRequestsPerWindow =
      50; // AUMENTADO: Era 8, agora 50 (mais pr�ximo dos limites reais)
  static bool _rateLimitBusy = false;

  // Watchdog
  Timer? _watchdogTimer;
  bool _isOperationRunning = false;
  static const Duration _maxOperationTime = Duration(
    minutes: 60,
  ); // AUMENTADO: 60 min para roteiros longos (13k+ palavras = 35+ blocos)

  // ?? v7.6.51: HELPER PARA MODELO ?NICO - Arquitetura Pipeline Modelo ?nico
  // O modelo selecionado pelo usu?rio deve ser usado em TODAS as etapas
  // para garantir consist?ncia de estilo e respeitar a configura??o do cliente
  static String _getSelectedModel(String qualityMode) {
    return qualityMode == 'flash'
        ? 'gemini-2.5-flash' // STABLE - R?pido e eficiente
        : qualityMode == 'ultra'
        ? 'gemini-3-pro-preview' // PREVIEW - Modelo mais avan?ado (Jan 2025)
        : 'gemini-2.5-pro'; // STABLE - M?xima qualidade (default)
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
    // ??? v7.6.64: Inicializar m?dulos refatorados
    _llmClient = LlmClient(instanceId: _instanceId);
    _worldStateManager = WorldStateManager(llmClient: _llmClient);
    _scriptValidator = ScriptValidator(llmClient: _llmClient);

    // ??? v7.6.65: M?dulos DuplicationDetector e TextCleaner s?o est?ticos
    // NameTracker e RateLimiter dispon?veis via imports para uso futuro

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

  // ===================== API P�BLICA =====================
  Future<ScriptResult> generateScript(
    ScriptConfig config,
    void Function(GenerationProgress) onProgress,
  ) async {
    // ?? v7.6.19: RESPEITAR SELE??O DO USU?RIO - N?o usar fallback autom?tico
    // Se selecionou Gemini ? usar APENAS Gemini
    // Se selecionou OpenAI ? usar APENAS OpenAI (implementar no futuro)
    // _useOpenAIFallback = false; // ? REMOVIDO - OpenAI descontinuado

    if (kDebugMode) {
      debugPrint(
        '[$_instanceId] ?? Provider selecionado: ${config.selectedProvider}',
      );
      debugPrint(
        '[$_instanceId] ?? Fallback autom?tico: DESABILITADO (usar apenas API selecionada)',
      );
    }

    // ?? CORRE??O CR?TICA: Resetar vari?veis globais ANTES de verificar rate limit
    // Isso garante que cada nova gera??o comece do zero
    _resetGlobalRateLimit();

    // ?? v4: Resetar rastreador de nomes para nova hist?ria
    _resetNameTracker();

    // ?? v7.6.37: Resetar personagens introduzidos para detec??o de duplicatas
    PostGenerationFixer.resetIntroducedCharacters();

    if (!_canMakeRequest()) {
      return ScriptResult.error(
        errorMessage:
            'Servi�o temporariamente indispon�vel. Tente mais tarde.',
      );
    }

    // CORREÇÃO: Reset completo do estado para nova geração
    resetState();

    // Tracker global alimentado com os nomes definidos pelo usuário/contexto
    final persistentTracker = CharacterTracker();
    CharacterTracker.bootstrap(persistentTracker, config);

    // 🔧 v7.6.64: WORLD STATE - Agora usa WorldState do módulo (SOLID)
    // Rastreia personagens, inventário, fatos e resumo da história
    // Usa o MESMO modelo selecionado pelo usuário (Pipeline Modelo Único)
    final worldState = WorldState();

    // ??? v7.6.64: Reset e inicializa??o do WorldStateManager (SOLID)
    _worldStateManager.reset();
    _worldStateManager.initializeProtagonist(config.protagonistName);

    // Inicializar protagonista no World State usando classe do m?dulo
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

    // ?? v7.6.53: CAMADA 1 - Gerar Sinopse Comprimida UMA VEZ no in?cio
    // Usa o MESMO modelo selecionado pelo usu?rio (Pipeline Modelo ?nico)
    // ??? v7.6.64: Migrado para usar WorldStateManager (SOLID)
    try {
      worldState.sinopseComprimida = await _worldStateManager
          .generateCompressedSynopsis(
            tema: config.tema,
            title: config.title,
            protagonistName: config.protagonistName,
            language: config.language,
            apiKey: config.apiKey,
            qualityMode: config.qualityMode,
          );
      if (kDebugMode) {
        debugPrint(
          '?? Camada 1 (Sinopse) gerada: ${worldState.sinopseComprimida.length} chars',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? Erro ao gerar sinopse (n?o-cr?tico): $e');
      }
      // Fallback: usar tema truncado
      final fallbackSynopsis = config.tema.length > 500
          ? '${config.tema.substring(0, 500)}...'
          : config.tema;
      worldState.sinopseComprimida = fallbackSynopsis;
      // ??? v7.6.64: Sincronizar fallback para WorldStateManager
      _worldStateManager.setSynopsis(fallbackSynopsis);
    }

    // -----------------------------------------------------------------------
    // ?? HOOK VIRAL (Feature Nova)
    // Gera uma frase de impacto antes de come?ar a escrever a hist?ria
    // CONDI??O: S? gera se startWithTitlePhrase = false (usu?rio n?o quer come?ar com t?tulo)
    // -----------------------------------------------------------------------
    String viralHook = "";
    if (!config.startWithTitlePhrase && config.title.trim().isNotEmpty) {
      try {
        if (kDebugMode) debugPrint('?? Gerando Hook Viral...');

        // 1. Monta o prompt usando o Builder novo
        final hookPrompt = ScriptPromptBuilder.buildViralHookPrompt(
          title: config.title,
          tema: config.tema,
          language: config.language,
        );

        // 2. Chama API usando o Client novo (Flash para rapidez)
        viralHook = await _llmClient.generateText(
          prompt: hookPrompt,
          apiKey: config.apiKey,
          model: LlmClient.modelFlash, // Usa modelo r?pido e barato
          maxTokens: 150,
        );

        // Limpeza b?sica
        viralHook = viralHook.replaceAll('"', '').trim();

        if (kDebugMode && viralHook.isNotEmpty) {
          debugPrint('?? Hook Gerado: "$viralHook"');
        }
      } catch (e) {
        // Se o hook falhar, n?o trava o roteiro. Apenas segue sem hook.
        if (kDebugMode) {
          debugPrint('?? Erro n?o-cr?tico no Hook (ignorando): $e');
        }
      }
    } else if (kDebugMode) {
      debugPrint(
        '?? Hook Viral DESABILITADO (startWithTitlePhrase = ${config.startWithTitlePhrase})',
      );
    }

    _startWatchdog();
    final start = DateTime.now();
    try {
      final totalBlocks = _calculateTotalBlocks(config);
      var acc = '';

      for (var block = 1; block <= totalBlocks && !_isCancelled; block++) {
        // ?? YIELD CR?TICO: Liberar UI thread completamente antes de cada bloco
        // Aumentado de 5ms ? 100ms para garantir anima??es suaves
        await Future.delayed(const Duration(milliseconds: 100));

        // ?? DEBUG: Log in?cio de bloco
        _debugLogger.block(
          block,
          "Iniciando gera??o",
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

        // ?? OTIMIZA??O CR?TICA: Reduzir frequ?ncia de onProgress ap?s 50%
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

          // ?? YIELD OTIMIZADO: 50ms para UI respirar sem bloquear gera??o
          await Future.delayed(Duration(milliseconds: 50));
        }

        // ?? DELAY INTELIGENTE ENTRE BLOCOS: Sistema Adaptativo v7.6.20
        // Aprende com o comportamento da API e ajusta delays automaticamente
        if (block > 1) {
          final adaptiveDelay = _getAdaptiveDelay(blockNumber: block);

          if (kDebugMode) {
            debugPrint(
              '?? Delay adaptativo de ${adaptiveDelay.inSeconds}s antes do bloco $block',
            );
            if (_consecutiveSuccesses >= 3) {
              debugPrint('   ? API r?pida detectada - usando delay m?nimo');
            } else if (_consecutive503Errors > 0) {
              debugPrint('   ?? API lenta detectada - usando delay maior');
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
            worldState: worldState, // ?? v7.6.52: World State
          ),
        );

        // ?? v7.6.35: CORRE??O P?S-GERA??O - Corrigir nomes trocados automaticamente
        // Executa ANTES de qualquer valida??o para garantir consist?ncia
        if (added.trim().isNotEmpty && block > 1) {
          // ?? DEBUG v7.6.36: Verificar mapa antes de chamar fixer
          if (kDebugMode) {
            final roleMap = persistentTracker.roleToNameMap;
            debugPrint('?? [Bloco $block] Chamando PostGenerationFixer');
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

        // ?? YIELD P?S-API: M?nimo delay para UI
        await Future.delayed(const Duration(milliseconds: 10));

        // ?? RETRY PARA BLOCOS VAZIOS: Se bloco retornou vazio, tentar novamente at? 6 vezes
        if (added.trim().isEmpty && acc.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              '?? BLOCO $block VAZIO! Iniciando tentativas de retry...',
            );
          }

          for (int retry = 1; retry <= 6; retry++) {
            if (kDebugMode) {
              debugPrint('?? Retry $retry/6 para bloco $block...');
            }

            // ?? v7.6.47: DELAY PROGRESSIVO INTELIGENTE
            // Primeiros 3 retries: r?pido (5s, 10s, 15s)
            // ?ltimos 3 retries: moderado (20s, 30s, 40s) para dar tempo ao servidor
            final retryDelay = retry <= 3 ? 5 * retry : 15 + (retry - 3) * 10;
            if (kDebugMode) {
              debugPrint(
                '?? Aguardando ${retryDelay}s antes do retry (${retry <= 3 ? "r?pido" : "moderado"})...',
              );
            }
            await Future.delayed(Duration(seconds: retryDelay));

            // ?? AUMENTADO: Contexto de 3000 para 8000 chars para manter nomes em mem?ria
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
                worldState: worldState, // ?? v7.6.52
              ),
            );

            if (added.trim().isNotEmpty) {
              if (kDebugMode) {
                debugPrint('? Retry $retry bem-sucedido! Bloco $block gerado.');
              }
              break;
            }
          }

          // ?? CORRE??O CR?TICA: Se ap?s 6 tentativas ainda estiver vazio, ABORTAR gera??o
          if (added.trim().isEmpty) {
            _log(
              '? ERRO CR?TICO: Bloco $block permaneceu vazio ap?s 6 retries!',
              level: 'critical',
            );
            _log(
              '?? ABORTANDO GERA??O: Servidor Gemini pode estar sobrecarregado.',
              level: 'critical',
            );
            _log(
              '?? SOLU??O: Aguarde 10-15 minutos e tente novamente, ou use OpenAI GPT-4o.',
              level: 'critical',
            );

            // ?? RETORNAR ERRO em vez de continuar
            return ScriptResult.error(
              errorMessage:
                  '?? ERRO: Bloco $block falhou ap?s 6 tentativas (total ~2min de espera).\n\n'
                  'O servidor Gemini est? temporariamente sobrecarregado.\n'
                  'Aguarde 10-15 minutos e tente novamente, ou:\n'
                  '? Troque para OpenAI GPT-4o nas configura??es\n'
                  '? Tente em hor?rio de menor tr?fego\n\n'
                  'Progresso salvo: ${_countWords(acc)} palavras (bloco $block de $totalBlocks).',
            );
          }
        }

        // ?? YIELD: Liberar UI thread antes de valida??o pesada
        await Future.delayed(const Duration(milliseconds: 10));

        // ? VALIDA??O ANTI-REPETI??O EM ISOLATE: Verificar sem travar UI
        if (added.trim().isNotEmpty && acc.length > 500) {
          // Executar em isolate separado para n?o bloquear UI thread
          final result = await compute(_isTooSimilarInIsolate, {
            'newBlock': added,
            'previousContent': acc,
            'threshold':
                0.80, // ?? AJUSTADO: Era 0.85, agora 0.80 para maior sensibilidade
          });

          final isSimilar = result['isSimilar'] as bool;

          if (isSimilar) {
            // ?? DEBUG: Log repeti??o detectada
            _debugLogger.warning(
              "Repeti??o detectada no bloco $block",
              details: result['reason'] as String,
              metadata: {
                'bloco': block,
                'tamanho': _countWords(added),
                'threshold': 0.80,
              },
            );

            if (kDebugMode) {
              debugPrint(
                '? BLOCO $block REJEITADO: Muito similar ao conte?do anterior!',
              );
              debugPrint(
                '   ?? Tamanho do bloco: ${_countWords(added)} palavras',
              );
              debugPrint('   ?? Motivo: ${result['reason']}');
              debugPrint(
                '   ?? Regenerando com aviso expl?cito contra repeti??o...',
              );
            }

            // ?? TENTATIVA 1: Regenerar com prompt espec?fico contra repeti??o
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
                worldState: worldState, // ?? v7.6.52
              ),
            );

            // Verificar novamente com threshold ainda mais alto (90%)
            final retryResult = await compute(_isTooSimilarInIsolate, {
              'newBlock': regenerated,
              'previousContent': acc,
              'threshold': 0.85, // ?? AJUSTADO: Era 0.90, agora 0.85
            });

            final stillSimilar = retryResult['isSimilar'] as bool;

            if (stillSimilar) {
              if (kDebugMode) {
                debugPrint(
                  '?? TENTATIVA 1 FALHOU: Ainda h? similaridade alta!',
                );
                debugPrint(
                  '   ?? TENTATIVA 2: Regenerando novamente com contexto reduzido...',
                );
              }

              // ?? AUMENTADO: Contexto de 3000 para 8000 chars para manter nomes em mem?ria
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
                  worldState: worldState, // ?? v7.6.52
                ),
              );

              final stillSimilar2 = _isTooSimilar(
                regenerated2,
                acc,
                threshold: 0.90,
              );

              if (stillSimilar2) {
                if (kDebugMode) {
                  debugPrint('?? TENTATIVA 2 FALHOU: Similaridade persiste!');
                  debugPrint(
                    '   ?? DECIS?O: Usando vers?o menos similar (tentativa 1)',
                  );
                }
                acc +=
                    regenerated; // Usar primeira tentativa (menos similar que original)
              } else {
                if (kDebugMode) {
                  debugPrint('? TENTATIVA 2 BEM-SUCEDIDA: Bloco ?nico gerado!');
                }
                acc += regenerated2;
              }
            } else {
              if (kDebugMode) {
                debugPrint('? REGENERA??O BEM-SUCEDIDA: Bloco agora ? ?nico!');
              }
              acc += regenerated;
            }
          } else {
            // ? Bloco passou na valida??o anti-repeti??o
            acc += added; // Usar vers?o original
          }
        } else {
          // ? Primeiro bloco ou contexto pequeno - adicionar direto
          acc += added;
        }

        // ?? INSERIR HOOK VIRAL no in?cio do Bloco 1 (se dispon?vel)
        if (block == 1 && viralHook.isNotEmpty && added.trim().isNotEmpty) {
          // Remove o added que acabou de ser adicionado
          acc = acc.substring(0, acc.length - added.length);
          // Adiciona com o hook no topo
          acc += '?? GANCHO VIRAL:\n$viralHook\n\n$added';
          if (kDebugMode) {
            debugPrint('?? Hook Viral inserido no in?cio do roteiro!');
          }
        }

        if (added.trim().isNotEmpty) {
          // ?? VALIDA??O CR?TICA 1: Detectar e registrar protagonista no Bloco 1
          if (block == 1) {
            _detectAndRegisterProtagonist(added, config, persistentTracker);
          }

          // ?? VALIDA??O CR?TICA 2: Verificar se protagonista mudou de nome
          final protagonistChanged = _detectProtagonistNameChange(
            added,
            config,
            persistentTracker,
            block,
          );

          // ?? VALIDA??O CR?TICA 3: Verificar se algum nome foi reutilizado
          _validateNameReuse(added, persistentTracker, block);

          // ?? VALIDA??O CR?TICA 4: REJEITAR BLOCO se protagonista mudou ou personagens trocaram de nome
          final characterNameChanges = _detectCharacterNameChanges(
            added,
            persistentTracker,
            block,
          );
          if (protagonistChanged || characterNameChanges.isNotEmpty) {
            if (kDebugMode) {
              debugPrint(
                '?????? BLOCO $block REJEITADO - MUDAN?A DE NOME DETECTADA! ??????',
              );
              if (protagonistChanged) {
                final detected = persistentTracker.getProtagonistName();
                debugPrint(
                  '   ? PROTAGONISTA: "$detected" mudou para outro nome!',
                );
              }
              for (final change in characterNameChanges) {
                final role = change['role'] ?? 'personagem';
                final oldName = change['oldName'] ?? '';
                final newName = change['newName'] ?? '';
                debugPrint('   ? $role: "$oldName" ? "$newName"');
              }
              debugPrint('   ?? Regenerando bloco (tentativa 1/3)...');
            }

            // ?? v7.6.17: LIMITE DE REGENERA??ES para evitar loop infinito
            const maxRegenerations = 3;
            String? regenerated;

            for (
              int regenAttempt = 1;
              regenAttempt <= maxRegenerations;
              regenAttempt++
            ) {
              if (kDebugMode && regenAttempt > 1) {
                debugPrint(
                  '   ?? Tentativa $regenAttempt/$maxRegenerations...',
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
                worldState: worldState, // ?? v7.6.52
              );

              if (regenerated.trim().isEmpty) {
                if (kDebugMode) {
                  debugPrint('   ? Regenera??o $regenAttempt retornou vazia!');
                }
                continue; // Tentar novamente
              }

              // Validar se regenera??o corrigiu o problema
              final stillChanged = _detectProtagonistNameChange(
                regenerated,
                config,
                persistentTracker,
                block,
              );

              if (!stillChanged) {
                if (kDebugMode) {
                  debugPrint('   ? Regenera??o $regenAttempt bem-sucedida!');
                }
                break; // Sucesso! Sair do loop
              } else {
                if (kDebugMode) {
                  debugPrint(
                    '   ?? Regenera??o $regenAttempt ainda tem erro de nome!',
                  );
                }
                if (regenAttempt == maxRegenerations) {
                  if (kDebugMode) {
                    debugPrint(
                      '   ? Limite de regenera??es atingido! Aceitando bloco...',
                    );
                  }
                }
              }
            }

            // Substituir bloco rejeitado pelo regenerado (ou null se todas falharam)
            if (regenerated != null && regenerated.trim().isNotEmpty) {
              added = regenerated;
              if (kDebugMode) {
                debugPrint('? Bloco $block regenerado com nomes corretos!');
              }
            } else {
              if (kDebugMode) {
                debugPrint(
                  '? ERRO: Todas as $maxRegenerations tentativas falharam! Usando bloco original...',
                );
              }
              // Manter bloco original se todas regenera??es falharam
            }
          }

          // 🔧 v7.6.17: VALIDAÇÃO UNIVERSAL DE TODOS OS NOMES (primários + secundários)
          final allNamesInBlock = NameValidator.extractNamesFromText(
            added,
          ).where((n) => NameValidator.looksLikePersonName(n)).toList();

          // Detectar nomes novos n?o registrados no tracker
          final unregisteredNames = allNamesInBlock
              .where((name) => !persistentTracker.hasName(name))
              .toList();

          if (unregisteredNames.isNotEmpty && block > 1) {
            if (kDebugMode) {
              debugPrint(
                '?? Bloco $block: Nomes novos detectados: ${unregisteredNames.join(", ")}',
              );
            }
            // Registrar novos nomes no tracker
            for (final name in unregisteredNames) {
              persistentTracker.addName(name, blockNumber: block);
            }
          }

          // 🔍 v4: EXTRAÇÃO E RASTREAMENTO DE NOMES
          final duplicatedNames = NameValidator.validateNamesInText(
            added,
            _namesUsedInCurrentStory,
          );
          if (duplicatedNames.isNotEmpty) {
            if (kDebugMode) {
              debugPrint(
                '?? ALERTA: Nomes duplicados detectados no Bloco $block!',
              );
              debugPrint('   Nomes: ${duplicatedNames.join(", ")}');
              debugPrint(
                '   ?? Isso pode indicar personagens com mesmo nome em pap?is diferentes!',
              );
            }
            _debugLogger.warning(
              "Poss?vel duplica??o de nomes no bloco $block",
              details: "Nomes: ${duplicatedNames.join(", ")}",
              metadata: {'bloco': block, 'nomes': duplicatedNames},
            );
          }
          _addNamesToTracker(added);

          // ?? VALIDA??O CR?TICA 4: Verificar inconsist?ncias em rela??es familiares
          _validateFamilyRelations(added, block);

          // ?? v7.6.41: Resetar watchdog a cada bloco bem-sucedido
          // Evita timeout em roteiros longos (35+ blocos)
          _resetWatchdog();

          // ?? DEBUG: Log bloco completado com sucesso
          _debugLogger.success(
            "Bloco $block completado",
            details: "Tamanho: ${_countWords(added)} palavras",
            metadata: {
              'bloco': block,
              'palavrasNoBloco': _countWords(added),
              'contextoTotal': acc.length + added.length,
            },
          );

          // ?? v7.6.28: VALIDA??O DE NOMES DUPLICADOS (antes da v7.6.25)
          // OBJETIVO: Detectar quando MESMO NOME aparece em PAP?IS DIFERENTES
          // EXEMPLO: "Mark" como boyfriend + "Mark" como attorney
          final duplicateNameConflict = _validateUniqueNames(
            added,
            persistentTracker,
            block,
          );

          if (duplicateNameConflict) {
            // ? BLOCO REJEITADO: Nome duplicado em pap?is diferentes
            if (kDebugMode) {
              debugPrint(
                '? v7.6.28: BLOCO $block REJEITADO por NOME DUPLICADO!',
              );
              debugPrint(
                '   ?? EXEMPLO: "Mark" aparece como boyfriend E attorney (nomes devem ser ?nicos)',
              );
              debugPrint('   ?? For?ando regenera??o do bloco...');
            }

            _debugLogger.warning(
              "Bloco $block rejeitado por nome duplicado",
              details: "Mesmo nome usado para personagens diferentes",
              metadata: {'bloco': block},
            );

            // ?? For?ar regenera??o: bloco vazio = retry autom?tico
            added = '';
          } else {
            // ? v7.6.28: Nomes ?nicos, prosseguir para valida??o de pap?is

            // ?? v7.6.25: VALIDA??O DE CONFLITOS DE PAPEL
            final trackerValid = _updateTrackerFromContextSnippet(
              persistentTracker,
              config,
              added,
            );

            if (!trackerValid) {
              // ? BLOCO REJEITADO: Conflito de papel detectado (ex: advogado Martin ? Richard)
              if (kDebugMode) {
                debugPrint(
                  '? v7.6.25: BLOCO $block REJEITADO por CONFLITO DE PAPEL!',
                );
                debugPrint(
                  '   ?? EXEMPLO: Mesmo papel (advogado) com nomes diferentes (Martin vs Richard)',
                );
                debugPrint('   ?? For?ando regenera??o do bloco...');
              }

              _debugLogger.warning(
                "Bloco $block rejeitado por conflito de papel",
                details: "Um personagem mudou de nome no mesmo papel",
                metadata: {'bloco': block},
              );

              // ?? For?ar regenera??o: bloco vazio = retry autom?tico
              added = '';
            } else {
              // ? v7.6.25: Tracker v?lido, atualizar mapeamento j? foi feito
              if (kDebugMode) {
                debugPrint(
                  '? v7.6.28 + v7.6.25: Bloco $block ACEITO (nomes ?nicos + sem conflitos de papel)',
                );
              }

              // ?? v7.6.52: ATUALIZAR WORLD STATE - Pipeline Modelo ?nico
              // O MESMO modelo selecionado pelo usu?rio atualiza o JSON de estado
              // Isso garante consist?ncia e respeita a config do cliente
              // ??? v7.6.64: Migrado para usar WorldStateManager (SOLID)
              if (added.trim().isNotEmpty) {
                await _worldStateManager.updateFromGeneratedBlock(
                  generatedBlock: added,
                  blockNumber: block,
                  apiKey: config.apiKey,
                  qualityMode: config.qualityMode,
                  language: config.language,
                );
                // Sincronizar resumo de volta para o worldState local (compatibilidade)
                worldState.resumoAcumulado =
                    _worldStateManager.state.resumoAcumulado;
              }
            }
          }
        }

        // OTIMIZADO: Checkpoint de estabilidade ultra-r?pido
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

          // ?? RETRY AUTOM?TICO: Tentar novamente at? 3x quando bloco vazio
          // AUMENTADO: Era 2, agora 3 retries para dar mais chance de sucesso
          int retryCount = 0;
          const maxRetries = 3;

          while (retryCount < maxRetries && added.trim().isEmpty) {
            retryCount++;
            if (kDebugMode) {
              debugPrint(
                '[$_instanceId] ?? Retry autom?tico $retryCount/$maxRetries para bloco $block',
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
                  worldState: worldState, // ?? v7.6.52
                ),
              );

              if (added.trim().isNotEmpty) {
                // ?? v7.6.28: VALIDAR nomes duplicados PRIMEIRO
                final retryHasDuplicateNames = _validateUniqueNames(
                  added,
                  persistentTracker,
                  block,
                );

                if (retryHasDuplicateNames) {
                  // ? Bloco regenerado tem nomes duplicados
                  if (kDebugMode) {
                    debugPrint(
                      '[$_instanceId] ? v7.6.28: Retry $retryCount REJEITADO (nomes duplicados)',
                    );
                  }
                  added = ''; // For?ar nova tentativa
                  continue; // Tentar pr?ximo retry
                }

                // ?? v7.6.25: VALIDAR conflitos de papel DEPOIS
                final retryTrackerValid = _updateTrackerFromContextSnippet(
                  persistentTracker,
                  config,
                  added,
                );

                if (!retryTrackerValid) {
                  // ? Bloco regenerado tamb?m tem conflito de papel
                  if (kDebugMode) {
                    debugPrint(
                      '[$_instanceId] ? v7.6.25: Retry $retryCount REJEITADO (conflito de papel)',
                    );
                  }
                  added = ''; // For?ar nova tentativa
                  continue; // Tentar pr?ximo retry
                }

                if (kDebugMode) {
                  debugPrint(
                    '[$_instanceId] ? v7.6.28 + v7.6.25: Retry v?lido! Bloco $block aceito.',
                  );
                }
                break; // Sucesso, sair do loop de retry
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                  '[$_instanceId] ? Retry autom?tico $retryCount falhou: $e',
                );
              }
            }
          }

          // ?? CORRE??O CR?TICA: Se ainda vazio ap?s retries, ABORTAR em vez de continuar
          if (added.trim().isEmpty) {
            if (kDebugMode) {
              debugPrint(
                '[$_instanceId] ? ERRO CR?TICO: Bloco $block falhou ap?s $maxRetries retries - ABORTANDO',
              );
            }

            return ScriptResult.error(
              errorMessage:
                  '?? ERRO CR?TICO: Bloco $block permaneceu vazio ap?s 6 tentativas.\n\n'
                  'O servidor Gemini est? temporariamente sobrecarregado.\n'
                  'Aguarde 10-15 minutos e tente novamente, ou troque para OpenAI.\n\n'
                  'Progresso salvo: ${_countWords(acc)} palavras de ${config.quantity} (bloco $block de $totalBlocks).',
            );
          }
        }

        // Limpeza de mem�ria otimizada
        if (kDebugMode) {
          debugPrint(
            '[$_instanceId] Checkpoint bloco $block - Limpeza mem�ria',
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

      // ?? EXPANS�O FOR�ADA DESATIVADA
      // Sistema de expans�o removido para evitar m�ltiplos finais empilhados.
      // A meta de caracteres deve ser atingida atrav�s do ajuste dos blocos iniciais,
      // n�o for�ando continua��es ap�s a hist�ria j� ter conclu�do naturalmente.
      // Isso preserva a qualidade narrativa e evita finais duplicados.

      if (!_isCancelled && !_checkTargetMet(acc, config)) {
        final needed = config.measureType == 'caracteres'
            ? (config.quantity - acc.length)
            : (config.quantity - _countWords(acc));

        if (kDebugMode) {
          debugPrint(
            '[$_instanceId] ?? Meta n�o atingida - Faltam $needed ${config.measureType}',
          );
          debugPrint(
            '[$_instanceId] ? DICA: Aumente o tamanho dos blocos iniciais para atingir a meta',
          );
        }
      }

      if (_isCancelled) {
        return ScriptResult.error(errorMessage: 'Gera??o cancelada');
      }

      _stopWatchdog();

      // ?? LOG FINAL: Resumo de personagens rastreados
      if (kDebugMode && persistentTracker.confirmedNames.isNotEmpty) {
        debugPrint('?? RESUMO FINAL DE PERSONAGENS:');
        debugPrint(
          '   Total rastreado: ${persistentTracker.confirmedNames.length} personagem(ns)',
        );
        debugPrint('   Nomes: ${persistentTracker.confirmedNames.join(", ")}');
      }

      // ?? LIMPAR MARCADORES DE DEBUG DO TEXTO FINAL
      final cleanedAcc = acc.replaceAll(
        RegExp(r'PERSONAGEM MENCIONADO:\s*'),
        '',
      );

      // 🧹 v7.6.43: REMOVER PARÁGRAFOS DUPLICADOS DO ROTEIRO FINAL
      var deduplicatedScript = TextFilter.removeAllDuplicateParagraphs(cleanedAcc);

      // 🔍 DETECÇÃO FINAL: Verificar se há parágrafos duplicados restantes (apenas LOG)
      if (kDebugMode) {
        TextFilter.detectDuplicates(deduplicatedScript);
      }

      // ?? v7.6.45: VALIDA??O RIGOROSA DE COER?NCIA COM T?TULO
      // ??? v7.6.64: Migrado para usar ScriptValidator (SOLID)
      if (config.title.trim().isNotEmpty) {
        final validationResult = await _scriptValidator
            .validateTitleCoherenceRigorous(
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
          '?? Valida??o de coer?ncia t?tulo-hist?ria',
          details:
              '''
T?tulo: "${config.title}"
Resultado: ${isCoherent ? '? COERENTE' : '? INCOERENTE'}
Confian?a: $confidence%

?? Elementos encontrados:
${foundElements.isEmpty ? '  (nenhum)' : foundElements.map((e) => '  ? $e').join('\n')}

${missingElements.isEmpty ? '' : '?? Elementos ausentes:\n${missingElements.map((e) => '  ? $e').join('\n')}'}
''',
          metadata: {
            'isCoherent': isCoherent,
            'confidence': confidence,
            'missingCount': missingElements.length,
            'foundCount': foundElements.length,
          },
        );

        // ?? FALLBACK: Se incoerente E confian?a baixa, tentar regenerar ?LTIMO bloco
        if (!isCoherent && confidence < 50 && missingElements.isNotEmpty) {
          _debugLogger.warning(
            '?? Tentando regenera??o com ?nfase nos elementos faltantes',
            details:
                'Elementos cr?ticos ausentes: ${missingElements.take(3).join(", ")}',
          );

          try {
            // Extrair ?ltimos 2 blocos para contexto
            final blocks = deduplicatedScript.split('\n\n');
            final contextBlocks = blocks.length > 2
                ? blocks.sublist(blocks.length - 2)
                : blocks;
            final context = contextBlocks.join('\n\n');

            // ??? v7.6.64: Usar ScriptPromptBuilder para criar prompt de recupera??o (SOLID)
            final recoveryPrompt = ScriptPromptBuilder.buildRecoveryPrompt(
              config.title,
              missingElements,
              context,
              config.language,
            );

            // ??? v7.6.64: Usar LlmClient para gerar bloco de recupera??o (SOLID)
            // ?? v7.6.51: Arquitetura Modelo ?nico - usar config.qualityMode
            final recoveryResponse = await _llmClient.generateText(
              apiKey: config.apiKey,
              model: _getSelectedModel(config.qualityMode),
              prompt: recoveryPrompt,
              maxTokens: 500, // Bloco pequeno de recupera??o
            );

            if (recoveryResponse.isNotEmpty) {
              // Adicionar bloco de recupera??o ao final
              deduplicatedScript = '$deduplicatedScript\n\n$recoveryResponse';
              _debugLogger.success(
                '? Bloco de recupera??o adicionado',
                details: 'Novos elementos incorporados ? hist?ria',
              );
            }
          } catch (e) {
            _debugLogger.warning(
              '?? Falha na regenera??o',
              details: 'Mantendo hist?ria original: $e',
            );
          }
        }
      }

      // ?? DEBUG: Log estat?sticas finais
      final stats = _debugLogger.getStatistics();
      _debugLogger.success(
        "Gera??o completa!",
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
        return ScriptResult.error(errorMessage: 'Gera??o cancelada');
      }
      return ScriptResult.error(errorMessage: 'Erro: $e');
    }
  }

  void cancelGeneration() {
    if (kDebugMode) debugPrint('[$_instanceId] Cancelando gera��o...');
    _isCancelled = true;
    _stopWatchdog();

    // CORRE??O: N?o fechar o Dio aqui, pois pode ser reutilizado
    // Apenas marcar como cancelado e limpar estado se necess?rio
    if (kDebugMode) {
      debugPrint('[$_instanceId] Gera??o cancelada pelo usu?rio');
    }
  }

  /// ?? Configura OpenAI como fallback para erro 503 (DESCONTINUADO)
  void setOpenAIKey(String? apiKey) {
    // REMOVIDO - OpenAI n?o ? mais usado
    if (kDebugMode) {
      debugPrint('[$_instanceId] OpenAI fallback descontinuado');
    }
  }

  // M?todo para limpar recursos quando o service n?o for mais usado
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

  // CORRE��O: M�todo para resetar completamente o estado interno
  void resetState() {
    if (kDebugMode) debugPrint('[$_instanceId] Resetando estado interno...');
    _isCancelled = false;
    _isOperationRunning = false;
    _failureCount = 0;
    _isCircuitOpen = false;
    _lastFailureTime = null;
    _stopWatchdog();

    // ?? NOVO: Resetar vari?veis static tamb?m (rate limiting global)
    _resetGlobalRateLimit();

    if (kDebugMode) {
      debugPrint(
        '[$_instanceId] ? Estado completamente resetado (incluindo rate limit global)',
      );
    }
  }

  // ?? NOVO: M?todo para resetar rate limiting global entre gera??es
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
      if (kDebugMode) debugPrint('Erro na gera��o de texto: $e');
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
            '[$_instanceId] Watchdog timeout - cancelando opera��o ap�s ${_maxOperationTime.inMinutes} min',
          );
        }
        _isCancelled = true;
      }
    });
  }

  /// ?? v7.6.41: Resetar watchdog a cada bloco bem-sucedido
  /// Evita timeout em roteiros longos quando a gera??o est? funcionando
  void _resetWatchdog() {
    if (_isOperationRunning && !_isCancelled) {
      _startWatchdog(); // Reinicia o timer
      if (kDebugMode) {
        debugPrint('[$_instanceId] Watchdog resetado - opera??o ativa');
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
    // CR�TICO: Rate limiting global para m�ltiplas inst�ncias/workspaces
    // Tentativa com timeout para evitar deadlocks
    int attempts = 0;
    const maxAttempts = 100; // 5 segundos m�ximo de espera

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

      // Se atingiu limite, aguarda at� o fim da janela
      if (_globalRequestCount >= _maxRequestsPerWindow) {
        final wait = _rateLimitWindow - diff;
        if (wait > Duration.zero && wait < Duration(seconds: 30)) {
          // M�ximo 30s de espera
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

  /// ?? v7.6.20: Sistema de Delay Adaptativo
  /// Aprende com comportamento da API e ajusta delays automaticamente
  /// Reduz tempo de gera??o em 40-50% quando API est? r?pida
  Duration _getAdaptiveDelay({required int blockNumber}) {
    // ?? v7.6.46: DELAYS ULTRA-OTIMIZADOS para velocidade m?xima
    // Se ?ltima chamada foi sucesso R?PIDO (< 3s atr?s), delay m?nimo
    if (_lastSuccessfulCall != null &&
        DateTime.now().difference(_lastSuccessfulCall!) <
            Duration(seconds: 3)) {
      _consecutiveSuccesses++;

      // Ap?s 2 sucessos r?pidos consecutivos, usar delays m?nimos
      if (_consecutiveSuccesses >= 2) {
        // API est? r?pida - usar delays m?nimos (0.3-0.8s)
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

    // Padr?o: delays M?NIMOS (0.5s-2s em vez de 3s-6s)
    _consecutiveSuccesses = 0;
    _consecutive503Errors = max(0, _consecutive503Errors - 1); // Decay gradual

    if (blockNumber <= 5) return Duration(milliseconds: 500); // 0.5s
    if (blockNumber <= 15) return Duration(milliseconds: 1000); // 1s
    if (blockNumber <= 25) return Duration(milliseconds: 1500); // 1.5s
    return Duration(seconds: 2); // 2s m?ximo
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
    // ?? AUMENTADO: Era 4, agora 6 para erro 503 (servidor indispon?vel)
    // RATIONALE: Erro 503 ? transit?rio, servidor pode voltar em 30-60s
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (_isCancelled) {
          throw Exception('Opera��o cancelada');
        }

        await _ensureRateLimit();

        if (_isCancelled) {
          throw Exception('Opera��o cancelada');
        }

        return await op();
      } catch (e) {
        if (_isCancelled) {
          throw Exception('Opera��o cancelada');
        }

        final errorStr = e.toString().toLowerCase();

        // ?? CORRE??O CR?TICA: Tratar erro 503 (servidor indispon?vel) especificamente
        // Erro 503 = "Service Unavailable" (transit?rio, n?o ? rate limit)
        if (errorStr.contains('503') ||
            errorStr.contains('server error') ||
            errorStr.contains('service unavailable')) {
          // ?? v7.6.20: Registrar erro 503 para Adaptive Delay Manager
          _recordApi503Error();

          // ?? v7.6.19: Fallback OpenAI REMOVIDO - respeitar sele??o do usu?rio
          // Se usu?rio escolheu Gemini, usar APENAS Gemini (mesmo com erros 503)
          // Se usu?rio escolheu OpenAI, implementar chamada direta do OpenAI (futuro)

          if (attempt < maxRetries - 1) {
            // ?? v7.6.46: BACKOFF OTIMIZADO para 503:
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
                '[$_instanceId] ?? ERRO 503 (Servidor Indispon?vel) - Aguardando ${delay.inSeconds}s antes de retry ${attempt + 2}/$maxRetries',
              );
              debugPrint(
                '[$_instanceId] ?? Backoff otimizado: 10s ? 20s ? 40s ? 60s ? 90s',
              );
            }
            await Future.delayed(delay);
            continue;
          } else {
            // ?? AP?S 6 TENTATIVAS, desistir com mensagem clara
            final totalWaitTime = (10 + 20 + 40 + 60 + 90); // Total: ~3.7 min
            throw Exception(
              '?? ERRO CR?TICO: Servidor do Gemini permanece indispon?vel ap?s $maxRetries tentativas (~${(totalWaitTime / 60).toStringAsFixed(1)} min de espera total).\n'
              '\n'
              '?? SOLU??ES POSS?VEIS:\n'
              '  1?? Aguarde 5-10 minutos e tente novamente\n'
              '  2?? Troque para OpenAI GPT-4o nas configura??es\n'
              '  3?? Tente novamente em hor?rio de menor tr?fego\n'
              '\n'
              '?? Seu progresso foi salvo e pode ser continuado.',
            );
          }
        }

        // ?? CORRE??O: Diferentes delays para diferentes tipos de erro
        if (errorStr.contains('429') && attempt < maxRetries - 1) {
          // ?? ERRO 429 (Rate Limit) = Delay otimizado progressivo
          // Tentativas: 5s, 10s, 15s, 20s, 25s, 30s
          final delay = Duration(
            seconds: (attempt + 1) * 5,
          ); // OTIMIZADO: era * 15
          if (kDebugMode) {
            debugPrint(
              '[$_instanceId] ?? ERRO 429 (Rate Limit) - Aguardando ${delay.inSeconds}s (tentativa ${attempt + 1}/$maxRetries)',
            );
          }
          await Future.delayed(delay);
          continue;
        }

        // ? Timeout/Connection = Retry muito r?pido (1s por tentativa)
        if ((errorStr.contains('timeout') || errorStr.contains('connection')) &&
            attempt < maxRetries - 1) {
          final delay = Duration(seconds: attempt + 1); // OTIMIZADO: era * 2
          if (kDebugMode) {
            debugPrint(
              '[$_instanceId] ? Retry r?pido (timeout/connection) - ${delay.inSeconds}s (tentativa ${attempt + 1}/$maxRetries)',
            );
          }
          await Future.delayed(delay);
          continue;
        }

        if (kDebugMode) {
          debugPrint(
            '[$_instanceId] Erro final ap�s $maxRetries tentativas: $e',
          );
        }
        rethrow;
      }
    }
    throw Exception(
      'Limite de tentativas excedido ap�s $maxRetries tentativas',
    );
  }

  // ===================== Narrativa =====================
  final List<String> _phases = const [
    'Prepara??o',
    'Introdu??o',
    'Desenvolvimento',
    'Cl?max',
    'Resolu??o',
    'Finaliza??o',
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
    // OTIMIZADO: Delays m?nimos para maximizar velocidade (sem afetar qualidade)
    if (p <= 0.15) return 50; // Reduzido de 100ms para 50ms
    if (p <= 0.30) return 75; // Reduzido de 150ms para 75ms
    if (p <= 0.65) return 100; // Reduzido de 200ms para 100ms
    if (p <= 0.80) return 125; // Reduzido de 250ms para 125ms
    if (p <= 0.95) return 75; // Reduzido de 150ms para 75ms
    return 50; // Reduzido de 100ms para 50ms
  }

  bool _checkTargetMet(String text, ScriptConfig c) {
    if (c.measureType == 'caracteres') {
      // TOLER�NCIA ZERO: S� aceita se atingir pelo menos 99.5% da meta
      final tol = max(
        50,
        (c.quantity * 0.005).round(),
      ); // M�ximo 0.5% ou 50 chars, o que for maior
      return text.length >= (c.quantity - tol);
    }
    final wc = _countWords(text);
    // TOLER�NCIA ZERO: S� aceita se atingir pelo menos 99% da meta
    final tol = max(
      10,
      (c.quantity * 0.01).round(),
    ); // M�ximo 1% ou 10 palavras, o que for maior
    return wc >= (c.quantity - tol);
  }

  int _calculateTotalBlocks(ScriptConfig c) {
    // ?? NORMALIZA??O: Converter tudo para palavras equivalentes
    // Isso garante que quantidades equivalentes de conte?do recebam blocos similares
    // ?? IMPORTANTE: N?O aplicar multiplicador de idioma aqui!
    //    O multiplicador ? aplicado por bloco, n?o no total de blocos.
    //    Caso contr?rio, ingl?s (1.05x) geraria blocos extras desnecess?rios.

    // ???? AJUSTE ESPECIAL PARA COREANO: Densidade de caracteres menor
    // Hangul: 1 caractere = 1 s?laba completa ? menos chars por palavra
    // F?rmula coreano: 4.2 chars/palavra (vs ingl?s/PT: 5.5)
    final isKoreanMeasure =
        c.language.contains('???') ||
        c.language.toLowerCase().contains('coreano') ||
        c.language.toLowerCase().contains('korean');

    final charToWordRatio = (c.measureType == 'caracteres' && isKoreanMeasure)
        ? 4.2 // Coreano: alta densidade sil?bica
        : 5.5; // Outros idiomas: padr?o

    int wordsEquivalent = c.measureType == 'caracteres'
        ? (c.quantity / charToWordRatio)
              .round() // Convers?o: chars ? palavras
        : c.quantity;

    if (kDebugMode) {
      debugPrint('?? C?LCULO DE BLOCOS (DEBUG):');
      debugPrint('   Idioma: "${c.language}"');
      debugPrint('   IsKoreanMeasure? $isKoreanMeasure');
      debugPrint('   Ratio: $charToWordRatio');
      debugPrint('   WordsEquivalent: $wordsEquivalent');
    }

    // ?? AJUSTE AUTOM?TICO PARA IDIOMAS COM ALFABETOS PESADOS
    // IMPORTANTE: Este ajuste s? deve ser aplicado para medida em CARACTERES!
    // Para medida em PALAVRAS, n?o aplicar redu??o (o multiplicador 1.20 j? compensa)
    // Diferentes alfabetos ocupam diferentes quantidades de bytes em UTF-8
    // Ajustamos palavras equivalentes para evitar timeout de contexto em roteiros longos

    // ?? N?VEL 2: Cir?lico e Alfabetos Pesados - 2-3 bytes/char ? Redu??o de 12%
    final cyrillicLanguages = [
      'Russo', 'B?lgaro', 'S?rvio', // Cir?lico
    ];

    // ?? N?VEL 2B: Outros N?o-Latinos - 2-3 bytes/char ? Redu??o de 15%
    // ATEN??O: Coreano FOI REMOVIDO desta lista (usa estrat?gia de blocos m?ltiplos)
    final otherNonLatinLanguages = [
      'Hebraico', 'Grego', 'Tailand?s', // Sem?ticos e outros
    ];

    // ?? N?VEL 1: Latinos com Diacr?ticos Pesados - 1.2-1.5 bytes/char ? Redu??o de 8%
    final heavyDiacriticLanguages = [
      'Turco',
      'Polon?s',
      'Tcheco',
      'Vietnamita',
      'H?ngaro',
    ];

    // ?? CORRE??O: Aplicar ajuste SOMENTE para 'caracteres', nunca para 'palavras'
    // Motivo: O problema de timeout s? ocorre com caracteres (tokens UTF-8)
    // Para palavras, o multiplicador 1.20 j? ? suficiente para compensar varia??o
    if (c.measureType == 'caracteres' && wordsEquivalent > 6000) {
      double adjustmentFactor = 1.0;
      String adjustmentLevel = '';

      if (cyrillicLanguages.contains(c.language)) {
        adjustmentFactor = 0.88; // -12% (AJUSTADO: era -20%)
        adjustmentLevel = 'CIR?LICO';
      } else if (otherNonLatinLanguages.contains(c.language)) {
        adjustmentFactor = 0.85; // -15%
        adjustmentLevel = 'N?O-LATINO';
      } else if (heavyDiacriticLanguages.contains(c.language)) {
        adjustmentFactor = 0.92; // -8% (AJUSTADO: era -10%)
        adjustmentLevel = 'DIACR?TICOS';
      }

      if (adjustmentFactor < 1.0) {
        final originalWords = wordsEquivalent;
        wordsEquivalent = (wordsEquivalent * adjustmentFactor).round();
        if (kDebugMode) {
          debugPrint('?? AJUSTE $adjustmentLevel (CARACTERES): ${c.language}');
          debugPrint(
            '   $originalWords ? $wordsEquivalent palavras equiv. (${(adjustmentFactor * 100).toInt()}%)',
          );
        }
      }
    }

    // ?????????????????????????????????????????????????????????????????????????????
    // ?? v7.6.53: CHUNKING OTIMIZADO POR IDIOMA - Pipeline de Modelo ?nico
    // ?????????????????????????????????????????????????????????????????????????????
    //
    // ESPECIFICA??O DE PALAVRAS POR BLOCO (pal/bloco):
    //   ???? PORTUGU?S:     1.200 - 1.500 pal/bloco (verboso, latino)
    //   ???? COREANO:       600 - 800 pal/bloco (Hangul, alta densidade)
    //   ???????? CIR?LICOS:  900 - 1.100 pal/bloco (tokens pesados)
    //   ???? TURCO:         1.000 - 1.200 pal/bloco (aglutinante)
    //   ???? POLON?S:       1.000 - 1.200 pal/bloco (diacr?ticos)
    //   ???? ALEM?O:        1.000 - 1.200 pal/bloco (palavras compostas)
    //   ?? LATINOS:        1.200 - 1.500 pal/bloco (EN, ES, FR, IT, RO)
    //
    // F?RMULA: blocos = wordsEquivalent / target_pal_bloco
    // ?????????????????????????????????????????????????????????????????????????????

    final langLower = c.language.toLowerCase();

    // ?? DETEC??O DE IDIOMA
    final isPortuguese = langLower.contains('portugu') || langLower == 'pt';
    final isKorean =
        c.language.contains('???') ||
        langLower.contains('coreano') ||
        langLower.contains('korean') ||
        langLower == 'ko';
    final isRussian = langLower.contains('russo') || langLower == 'ru';
    final isBulgarian =
        langLower.contains('b?lgar') ||
        langLower.contains('bulgar') ||
        langLower == 'bg';
    final isCyrillic = isRussian || isBulgarian;
    final isTurkish = langLower.contains('turco') || langLower == 'tr';
    final isPolish = langLower.contains('polon') || langLower == 'pl';
    final isGerman = langLower.contains('alem') || langLower == 'de';
    // Latinos: en, es-mx, fr, it, ro (usam valores similares ao portugu?s)
    final isLatin =
        langLower.contains('ingl?s') ||
        langLower.contains('english') ||
        langLower == 'en' ||
        langLower.contains('espanhol') ||
        langLower.contains('espa?ol') ||
        langLower.contains('es') ||
        langLower.contains('franc?s') ||
        langLower.contains('fran?ais') ||
        langLower == 'fr' ||
        langLower.contains('italiano') ||
        langLower == 'it' ||
        langLower.contains('romeno') ||
        langLower.contains('rom?n') ||
        langLower == 'ro';

    // ?? TARGET DE PALAVRAS POR BLOCO (centro do range)
    int targetPalBloco;
    String langCategory;

    if (isKorean) {
      targetPalBloco = 700; // 600-800 pal/bloco
      langCategory = '???? COREANO';
    } else if (isCyrillic) {
      targetPalBloco = 1000; // 900-1100 pal/bloco
      langCategory = '?? CIR?LICO';
    } else if (isTurkish) {
      targetPalBloco = 1100; // 1000-1200 pal/bloco
      langCategory = '???? TURCO';
    } else if (isPolish) {
      targetPalBloco = 1100; // 1000-1200 pal/bloco
      langCategory = '???? POLON?S';
    } else if (isGerman) {
      targetPalBloco = 1100; // 1000-1200 pal/bloco
      langCategory = '???? ALEM?O';
    } else if (isPortuguese) {
      targetPalBloco = 1350; // 1200-1500 pal/bloco
      langCategory = '???? PORTUGU?S';
    } else if (isLatin) {
      targetPalBloco = 1350; // 1200-1500 pal/bloco
      langCategory = '?? LATINO';
    } else {
      // Fallback para idiomas n?o especificados
      targetPalBloco = 1200;
      langCategory = '?? OUTROS';
    }

    // ?? C?LCULO DE BLOCOS: words / target
    int calculatedBlocks = (wordsEquivalent / targetPalBloco).ceil();

    // ?? LIMITES DE SEGURAN?A
    // M?nimo: 2 blocos (intro + conclus?o)
    // M?ximo: varia por idioma para evitar erro 503
    int minBlocks = 2;
    int maxBlocks;

    if (isKorean) {
      maxBlocks = 50; // Coreano precisa de mais blocos menores
    } else if (isCyrillic) {
      maxBlocks = 30; // Cir?licos s?o mais pesados
    } else {
      maxBlocks = 25; // Latinos e outros s?o eficientes
    }

    // Aplicar limites
    int finalBlocks = calculatedBlocks.clamp(minBlocks, maxBlocks);

    // ???? COMPENSA??O COREANO: +18% blocos para compensar sub-gera??o natural
    if (isKorean) {
      finalBlocks = (finalBlocks * 1.18).ceil().clamp(minBlocks, maxBlocks);
    }

    if (kDebugMode) {
      final actualPalBloco = (wordsEquivalent / finalBlocks).round();
      debugPrint(
        '   $langCategory: $wordsEquivalent palavras ? $targetPalBloco target = $calculatedBlocks ? $finalBlocks blocos (~$actualPalBloco pal/bloco)',
      );
    }

    return finalBlocks;
  }

  int _calculateTargetForBlock(int current, int total, ScriptConfig c) {
    // ?? CALIBRA??O AJUSTADA: Multiplicador reduzido de 1.20 para 0.95 (95%)
    // PROBLEMA DETECTADO: Roteiros saindo 30% maiores (Wanessa +28%, Quit?ria +30%)
    // AN?LISE: Gemini est? gerando MAIS do que o pedido, n?o menos
    // SOLU??O: Reduzir multiplicador para evitar sobre-gera??o
    // Target: Ficar entre -5% e +10% do alvo (?10% aceit?vel)

    // ?? CORRE??O: Usar a mesma l?gica de normaliza??o que _calculateTotalBlocks
    // ???? AJUSTE ESPECIAL PARA COREANO: Densidade de caracteres menor
    final isKoreanTarget =
        c.language.contains('???') ||
        c.language.toLowerCase().contains('coreano') ||
        c.language.toLowerCase().contains('korean');

    final charToWordRatio = (c.measureType == 'caracteres' && isKoreanTarget)
        ? 4.2 // Coreano: alta densidade sil?bica
        : 5.5; // Outros idiomas: padr?o

    int targetQuantity = c.measureType == 'caracteres'
        ? (c.quantity / charToWordRatio)
              .round() // Convers?o: chars ? palavras
        : c.quantity;

    // ?? v10: REMOVIDO boost artificial
    // Li??o: Gemini ignora multiplicadores - gera naturalmente
    // Solu??o: Usar mesma tabela de blocos do portugu?s (comprovada)

    // ?? Aplicar os mesmos ajustes de idioma que em _calculateTotalBlocks
    // IMPORTANTE: S? aplicar para 'caracteres', nunca para 'palavras'
    // ATEN??O: Coreano usa estrat?gia de blocos m?ltiplos, n?o redu??o percentual
    if (c.measureType == 'caracteres' && targetQuantity > 6000) {
      final cyrillicLanguages = ['Russo', 'B?lgaro', 'S?rvio'];
      final otherNonLatinLanguages = ['Hebraico', 'Grego', 'Tailand?s'];
      final heavyDiacriticLanguages = [
        'Turco',
        'Polon?s',
        'Tcheco',
        'Vietnamita',
        'H?ngaro',
      ];

      if (cyrillicLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.88).round();
      } else if (otherNonLatinLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.85).round();
      } else if (heavyDiacriticLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.92).round();
      }
    }

    // ?? AJUSTE CR?TICO: Multiplicador calibrado por idioma
    // HIST?RICO:
    //   v1: 1.05 ? Gerou 86.7% (d?ficit de -13.3%) ?
    //   v2: 1.15 ? Gerou 116% (excesso de +16%) ?
    //   v3: 1.08 ? Gerou 112% (excesso de +12%) ??
    //   v4.1: 0.98 ? Esperado: 98-105% (ideal) ?
    //   v5.0: 1.08 ? Gerava bem (100%+) MAS erro 503 (10 blocos grandes) ?
    //   v6.0: 0.85 ? N?o d? 503 MAS gera s? 82% (8700/10600) ?
    //   v6.1: 0.95 ? Ainda baixo, gera s? 87% (9200/10600) ?
    //   v6.2: 1.00 ? Melhorou mas ainda 91% (9600/10600) ?
    //   v6.3: 1.05 ? Melhor, mas ainda 100% (10600) ou 77% (8500) vari?vel ??
    //   v6.4: 1.08 ? Volta ao valor do v5.0 MAS ainda d? 503 com 12 blocos ?
    //   v6.5: 1.05 ? Reduz para 1.05 + AUMENTA blocos (12?14) = blocos 25% menores ??
    //   v7.6.42: 1.18 ? Coreano espec?fico para compensar sub-gera??o de ~15%
    //
    // ???? COREANO v12: Multiplicador 1.18 para compensar sub-gera??o natural
    // AN?LISE: Coreano gera apenas ~84.6% do pedido (11k de 13k)
    // SOLU??O: Pedir 18% a mais para compensar
    double multiplier;
    if (isKoreanTarget) {
      multiplier = 1.18; // ???? v12: Compensar sub-gera??o de ~15%
    } else if (c.language.toLowerCase().contains('portugu')) {
      multiplier = 1.05; // v6.5: Portugu?s
    } else {
      multiplier = 1.05; // Outros idiomas
    }

    // Calcular target acumulado at? este bloco (com margem ajustada)
    final cumulativeTarget = (targetQuantity * (current / total) * multiplier)
        .round();

    // Calcular target acumulado do bloco anterior
    final previousCumulativeTarget = current > 1
        ? (targetQuantity * ((current - 1) / total) * multiplier).round()
        : 0;

    // DELTA = palavras necess?rias NESTE bloco espec?fico
    final baseTarget = cumulativeTarget - previousCumulativeTarget;

    // LIMITES por bloco individual (aumentado para evitar cortes)
    final maxBlockSize = c.measureType == 'caracteres' ? 15000 : 5000;

    // Para o ?ltimo bloco, usar o multiplicador ajustado por idioma
    // Portugu?s: 1.05 para compensar leve sub-gera??o (~105% do target)
    // Outros: 0.95 para evitar sobre-gera??o
    if (current == total) {
      final wordsPerBlock = (targetQuantity / total).ceil();
      return min((wordsPerBlock * multiplier).round(), maxBlockSize);
    }

    return baseTarget > maxBlockSize ? maxBlockSize : baseTarget;
  }

  // ===================== Geração de Blocos =====================
  // 🔧 v7.6.80: Wrappers de BaseRules removidos - usar BaseRules.* diretamente
  // 🔧 v7.6.81: _bootstrapCharacterTracker movido para CharacterTracker.bootstrap()

  /// 🔧 v7.6.25: Atualiza tracker, RETORNA FALSE se houve conflito de papel
  bool _updateTrackerFromContextSnippet(
    CharacterTracker tracker,
    ScriptConfig config,
    String snippet,
  ) {
    if (snippet.trim().isEmpty) return true; // Snippet vazio = sem erro

    bool hasRoleConflict = false; // ?? v7.6.25: Flag de erro

    final existingLower = tracker.confirmedNames
        .map((n) => n.toLowerCase())
        .toSet();
    final locationLower = config.localizacao.trim().toLowerCase();
    final candidateCounts = NameValidator.extractNamesFromSnippet(snippet);

    candidateCounts.forEach((name, count) {
      final normalized = name.toLowerCase();
      if (existingLower.contains(normalized)) return;

      // ?? v7.6.31: REMOVER filtro "count < 2" - BUG CR�TICO!
      // PROBLEMA: "Janice" com 1 men��o no Bloco 2 n�o entrava no tracker
      // RESULTADO: "Janice" no Bloco 9 passava na valida��o (tracker vazio)
      // SOLU��O: Adicionar TODOS os nomes v�lidos, independente de contagem
      // A valida��o isValidName() j� garante que s�o nomes reais
      // if (count < 2) return; // ? REMOVIDO - causava duplica��es

      if (locationLower.isNotEmpty && normalized == locationLower) return;
      if (NameConstants.isStopword(normalized)) return;

      // v7.6.63: Validação estrutural (aceita nomes do LLM)
      if (!NameValidator.isLikelyName(name)) {
        if (kDebugMode) {
          debugPrint('Tracker ignorou texto invalido: "$name"');
        }
        return;
      }

      // ✅ CORREÇÃO BUG ALBERTO: Extrair papel antes de adicionar
      final role = RolePatterns.extractRoleForName(name, snippet);

      if (role != null) {
        final success = tracker.addName(name, role: role); // ?? v7.6.25
        if (kDebugMode) {
          if (success) {
            debugPrint(
              '?? v7.6.31: Tracker adicionou personagem COM PAPEL: "$name" = "$role" (ocorr?ncias: $count)',
            );
          } else {
            debugPrint('? v7.6.25: CONFLITO DE PAPEL detectado!');
            debugPrint('   Nome: "$name"');
            debugPrint('   Papel tentado: "$role"');
            hasRoleConflict = true; // ?? Marca erro
          }
        }
      } else {
        tracker.addName(name, role: 'indefinido');
        if (kDebugMode) {
          debugPrint(
            '?? v7.6.31: Tracker adicionou personagem SEM PAPEL: "$name" (indefinido - ocorr?ncias: $count)',
          );
        }
      }
      if (kDebugMode) {
        debugPrint(
          '?? v7.6.31: Tracker adicionou personagem detectado: $name (ocorr?ncias: $count)',
        );
      }
    });

    return !hasRoleConflict; // ✅ true = OK, ❌ false = ERRO
  }

  // 🔧 v7.6.83: Wrappers removidos - usar diretamente:
  //   - CharacterGuidanceBuilder.buildGuidance()
  //   - NarrativeStyleBuilder.getNarrativeStyleGuidance()
  //   - NameValidator.extractNamesFromSnippet()
  //   - TextFilter.filterDuplicateParagraphs()
  //   - TextFilter.detectDuplicates()
  //   - TextFilter.removeAllDuplicateParagraphs()

  // 🏗️ v7.6.64: _buildRecoveryPrompt migrado para ScriptPromptBuilder.buildRecoveryPrompt()

  /// 🎯 v7.6.17: Detecta e registra o nome da protagonista no Bloco 1
  /// Extrai o primeiro nome próprio encontrado e registra no tracker
  void _detectAndRegisterProtagonist(
    String generatedText,
    ScriptConfig config,
    CharacterTracker tracker,
  ) {
    final configName = config.protagonistName.trim();
    if (configName.isEmpty) return;

    // Extrair todos os nomes do texto
    final names = NameValidator.extractNamesFromText(generatedText);

    // Procurar o nome configurado
    if (names.contains(configName)) {
      tracker.setProtagonistName(configName);
      if (kDebugMode) {
        debugPrint('? Bloco 1: Protagonista "$configName" confirmada');
      }
    } else {
      // Se nome configurado não apareceu, pegar primeiro nome válido
      final validNames = names.where((n) => NameValidator.looksLikePersonName(n)).toList();
      if (validNames.isNotEmpty) {
        final detectedName = validNames.first;
        tracker.setProtagonistName(detectedName);
        if (kDebugMode) {
          debugPrint(
            '?? Bloco 1: Nome configurado "$configName" n?o usado, '
            'detectado "$detectedName" como protagonista',
          );
        }
      }
    }
  }

  /// ?? v7.6.17: Valida se protagonista manteve o mesmo nome
  /// Retorna true se mudan?a detectada (bloco deve ser rejeitado)
  bool _detectProtagonistNameChange(
    String generatedText,
    ScriptConfig config,
    CharacterTracker tracker,
    int blockNumber,
  ) {
    if (blockNumber == 1) return false; // Bloco 1 sempre v?lido

    final registeredName = tracker.getProtagonistName();
    if (registeredName == null) return false; // Sem protagonista registrada

    // Extrair todos os nomes do bloco atual
    final currentNames = NameValidator.extractNamesFromText(generatedText);

    // Verificar se protagonista registrada aparece
    final protagonistPresent = currentNames.contains(registeredName);

    // Verificar se há outros nomes válidos (possível troca)
    final otherValidNames = currentNames
        .where((n) => n != registeredName && NameValidator.looksLikePersonName(n))
        .toList();

    // ?? DETEC??O: Se protagonista n?o apareceu MAS h? outros nomes v?lidos
    if (!protagonistPresent && otherValidNames.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '?? Bloco $blockNumber: Protagonista "$registeredName" ausente!',
        );
        debugPrint('   Nomes encontrados: ${otherValidNames.join(", ")}');
        debugPrint('   ?? Poss?vel mudan?a de nome!');
      }

      _debugLogger.error(
        'Mudan?a de protagonista detectada',
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

  /// ?? VALIDA??O CR?TICA: Detecta reutiliza??o de nomes de personagens
  /// Cada personagem deve ter apenas 1 nome ?nico
  /// Retorna true se valida??o passou, false se detectou erro cr?tico
  bool _validateProtagonistName(
    String generatedText,
    ScriptConfig config,
    int blockNumber,
  ) {
    final protagonistName = config.protagonistName.trim();
    if (protagonistName.isEmpty) {
      return true; // Sem protagonista configurada = ok
    }

    // ?? NOVA VALIDA??O: Detectar auto-apresenta??es com nomes errados
    // Padr?es: "my name is X", "i'm X", "call me X"
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
            '?? ERRO CR?TICO: AUTO-APRESENTA??O COM NOME ERRADO!',
            level: 'critical',
          );
          _log(
            '   ? Protagonista configurada: "$protagonistName"',
            level: 'critical',
          );
          _log(
            '   ? Nome na auto-apresenta??o: "$introducedName"',
            level: 'critical',
          );
          _log('   ?? Trecho: "${match.group(0)}"', level: 'critical');
          _log('   ?? BLOCO SER? REJEITADO E REGENERADO', level: 'critical');

          return false; // ?? REJEITAR BLOCO
        }
      }
    }

    // ?? PARTE 1: Validar protagonista espec?fica
    final suspiciousNames = [
      'Wanessa',
      'Carla',
      'Beatriz',
      'Fernanda',
      'Juliana',
      'Mariana',
      'Patr?cia',
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
      // Nomes comuns em ingl?s (caso do roteiro gerado)
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
        continue; // Nome suspeito ? o pr?prio protagonista configurado
      }

      if (generatedText.contains(suspiciousName)) {
        // ?? DEBUG: Log erro cr?tico de nome
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
          '?? ERRO CR?TICO DETECTADO NO BLOCO $blockNumber:',
          level: 'critical',
        );
        _log(
          '   ? Protagonista deveria ser: "$protagonistName"',
          level: 'critical',
        );
        _log(
          '   ? Mas encontrei nome suspeito: "$suspiciousName"',
          level: 'critical',
        );
        _log(
          '   ?? POSS?VEL TROCA DE NOME DA PROTAGONISTA!',
          level: 'critical',
        );
        _log('   ?? BLOCO SER? REJEITADO E REGENERADO', level: 'critical');

        return false; // ?? REJEITAR BLOCO
      }
    }

    if (!hasProtagonist && blockNumber <= 2) {
      // ?? DEBUG: Log aviso de protagonista ausente
      _debugLogger.warning(
        "Protagonista ausente",
        details: "'$protagonistName' n?o apareceu no bloco $blockNumber",
        metadata: {'bloco': blockNumber, 'protagonista': protagonistName},
      );

      debugPrint(
        '?? AVISO: Protagonista "$protagonistName" n?o apareceu no bloco $blockNumber',
      );
    } else if (hasProtagonist) {
      // ?? DEBUG: Log valida??o bem-sucedida
      _debugLogger.validation(
        "Protagonista validada",
        blockNumber: blockNumber,
        details: "'$protagonistName' presente no bloco",
        metadata: {'protagonista': protagonistName},
      );
    }

    return true; // Valida??o passou
  }

  /// ?? v7.6.22: VALIDA��O DE RELACIONAMENTOS FAMILIARES
  /// ??? v7.6.67: Refatorado para usar RelationshipPatterns module
  /// Detecta contradi��es l�gicas em �rvores geneal�gicas
  /// Retorna true se relacionamentos s�o consistentes, false se h� erros
  bool _validateFamilyRelationships(String text, int blockNumber) {
    if (text.isEmpty) return true;

    // Mapa de relacionamentos encontrados: pessoa ? rela��o ? pessoa relacionada
    final Map<String, Map<String, Set<String>>> relationships = {};

    // ??? v7.6.67: Usa padr�es do m�dulo RelationshipPatterns
    final patterns = RelationshipPatterns.allRelationPatterns;

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

    // Validar relacionamentos l?gicos
    bool hasError = false;

    // REGRA 1: Se X ? meu cunhado/cunhada, ent?o:
    //   - X deve ser irm?o/irm? do meu c?njuge OU
    //   - X deve ser c?njuge do meu irm?o/irm?
    final brotherInLaw = relationships['protagonist']?['cunhado'] ?? {};
    final sisterInLaw = relationships['protagonist']?['cunhada'] ?? {};
    final husband = relationships['protagonist']?['marido'] ?? {};
    final wife = relationships['protagonist']?['esposa'] ?? {};
    final brother = relationships['protagonist']?['irm?o'] ?? {};
    final sister = relationships['protagonist']?['irm?'] ?? {};

    for (final inLaw in [...brotherInLaw, ...sisterInLaw]) {
      // Se X ? cunhado mas nunca mencionamos c?njuge nem irm?os = ERRO
      if (husband.isEmpty &&
          wife.isEmpty &&
          brother.isEmpty &&
          sister.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '?? ERRO: $inLaw ? cunhado/cunhada mas n?o h? c?njuge nem irm?os mencionados!',
          );
        }
        hasError = true;
      }
    }

    // REGRA 2: Se X ? meu sogro/sogra, ent?o:
    //   - Eu DEVO ter c?njuge (marido/esposa)
    //   - X deve ser pai/m?e do meu c?njuge
    final fatherInLaw = relationships['protagonist']?['sogro'] ?? {};
    final motherInLaw = relationships['protagonist']?['sogra'] ?? {};

    if (fatherInLaw.isNotEmpty || motherInLaw.isNotEmpty) {
      if (husband.isEmpty && wife.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '?? ERRO: Tem sogro/sogra mas protagonista n?o tem c?njuge!',
          );
          debugPrint('   ? Se X ? sogro, protagonista DEVE ter esposa/marido');
        }
        hasError = true;
      }
    }

    // REGRA 3: Se X ? meu genro/nora, ent?o:
    //   - Eu DEVO ter filho/filha
    //   - X deve ser c?njuge do meu filho/filha
    final sonInLaw = relationships['protagonist']?['genro'] ?? {};
    final daughterInLaw = relationships['protagonist']?['nora'] ?? {};

    if (sonInLaw.isNotEmpty || daughterInLaw.isNotEmpty) {
      // Verificar se menciona filhos (procurar padr?o mais amplo)
      final hasChildren = text.contains(
        RegExp(
          r'meu filho|minha filha|my son|my daughter',
          caseSensitive: false,
        ),
      );

      if (!hasChildren) {
        if (kDebugMode) {
          debugPrint('?? ERRO: Tem genro/nora mas n?o menciona filhos!');
          debugPrint(
            '   ? Se X ? genro/nora, protagonista DEVE ter filho/filha',
          );
        }
        hasError = true;
      }
    }

    // REGRA 4: Se X ? meu neto/neta, ent?o:
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
          debugPrint('?? ERRO: Tem neto/neta mas n?o menciona filhos!');
          debugPrint(
            '   ? Se X ? neto/neta, protagonista DEVE ter filho/filha',
          );
        }
        hasError = true;
      }
    }

    // REGRA 5: Detectar contradi??es com sufixos -in-law
    // Exemplo: "my brother Paul married Megan" + "my father-in-law Alan"
    // Se Megan ? filha de Alan, ent?o Alan ? sogro de Paul (n?o do protagonista)
    final marriedPattern = RegExp(
      r'my (brother|sister)(?:,)?\s+([A-Z][a-z]+)\s+(?:married|casou com)\s+([A-Z][a-z]+)',
      caseSensitive: false,
    );

    for (final match in marriedPattern.allMatches(text)) {
      final sibling = match.group(2); // Nome do irm?o/irm?
      final spouse = match.group(3); // Nome do c?njuge do irm?o/irm?

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
              debugPrint('?? ERRO DE RELACIONAMENTO GENEAL?GICO!');
              debugPrint(
                '   ? $parentName ? pai de $spouse (c?njuge de $sibling)',
              );
              debugPrint(
                '   ? Mas texto chama $parentName de "my father-in-law"',
              );
              debugPrint(
                '   ? CORRETO seria: "$parentName ? sogro do meu irm?o $sibling"',
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
          '? BLOCO $blockNumber REJEITADO: Relacionamentos familiares inconsistentes!',
        );
        debugPrint(
          '   ?? For?ando regenera??o com l?gica geneal?gica correta...',
        );
      }
    }

    return !hasError; // Retorna true se n?o h? erros
  }

  /// ?? EXTRA??O DE PAPEL: Identifica o papel/rela??o de um nome em um texto
  /// Retorna o primeiro papel encontrado ou null se n?o detectar nenhum
  /// ?? v7.6.28: Valida se h? nomes duplicados em pap?is diferentes
  /// ?? v7.6.32: NOVA VALIDA??O - Detecta quando MESMO PAPEL tem NOMES DIFERENTES
  /// ?? v7.6.33: PAP?IS POSSESSIVOS SINGULARES - Detecta "my lawyer" como papel ?nico
  /// ?? v7.6.34: FIX MULTI-WORD ROLES - Corrige detec??o de "executive assistant", "financial advisor"
  ///
  /// OBJETIVO 1 (v7.6.28): Detectar quando MESMO NOME aparece para PERSONAGENS DIFERENTES
  /// EXEMPLO RUIM: "Mark" como boyfriend + "Mark" como attorney
  ///
  /// OBJETIVO 2 (v7.6.32): Detectar quando MESMO PAPEL ? atribu?do a NOMES DIFERENTES
  /// EXEMPLO RUIM: "Ashley" como protagonista + "Emily" como protagonista
  ///
  /// OBJETIVO 3 (v7.6.33/34): Detectar quando PAPEL POSSESSIVO tem NOMES DIFERENTES
  /// EXEMPLOS RUINS:
  ///   - "my lawyer, Richard" (Bloco 5) ? "my lawyer, Mark" (Bloco 10)
  ///   - "my executive assistant, Lauren" (Bloco 7) ? "my executive assistant, Danielle" (Bloco 12)
  /// L?GICA: "my X" = possessivo singular = papel ?nico (n?o pode ter m?ltiplos)
  /// ?? v7.6.34: Agora captura corretamente multi-word roles (executive assistant, financial advisor, etc.)
  ///
  /// Retorna TRUE se houver conflito (bloco deve ser rejeitado)
  /// Retorna FALSE se nomes s?o ?nicos (bloco pode ser aceito)
  bool _validateUniqueNames(
    String blockText,
    CharacterTracker tracker,
    int blockNumber,
  ) {
    if (blockText.trim().isEmpty) return false; // Texto vazio = sem erro

    // Extrair nomes do bloco atual
    final namesInBlock = NameValidator.extractNamesFromText(blockText);

    // Verificar cada nome extra?do
    for (final name in namesInBlock) {
      // ---------------------------------------------------------------
      // VALIDA??O 1 (v7.6.28): MESMO NOME em PAP?IS DIFERENTES
      // ---------------------------------------------------------------
      if (tracker.hasName(name)) {
        // Nome j? existe - verificar se ? o MESMO personagem ou REUSO indevido

        // Extrair papel atual deste nome no bloco
        final currentRole = RolePatterns.extractRoleForName(name, blockText);

        // Extrair papel registrado anteriormente
        final previousRole = tracker.getRole(name);

        if (currentRole != null && previousRole != null) {
          // Normalizar pap?is para compara??o
          final normalizedCurrent = _normalizeRole(currentRole);
          final normalizedPrevious = _normalizeRole(previousRole);

          // Se pap?is s?o DIFERENTES = NOME DUPLICADO (ERRO!)
          if (normalizedCurrent != normalizedPrevious &&
              normalizedCurrent != 'indefinido' &&
              normalizedPrevious != 'indefinido') {
            if (kDebugMode) {
              debugPrint('?????? v7.6.28: NOME DUPLICADO DETECTADO! ??????');
              debugPrint('   ? Nome: "$name"');
              debugPrint(
                '   ? Papel anterior: "$previousRole" ? "$normalizedPrevious"',
              );
              debugPrint(
                '   ? Papel atual: "$currentRole" ? "$normalizedCurrent"',
              );
              debugPrint(
                '   ?? EXEMPLO DO BUG: "Mark" sendo boyfriend E attorney!',
              );
              debugPrint(
                '   ?? Bloco $blockNumber ser? REJEITADO e REGENERADO',
              );
              debugPrint('?????? FIM DO ALERTA ??????');
            }

            _debugLogger.error(
              "Nome duplicado em pap?is diferentes - Bloco $blockNumber",
              blockNumber: blockNumber,
              details:
                  "Nome '$name': papel anterior '$previousRole', papel atual '$currentRole'",
              metadata: {
                'nome': name,
                'papelAnterior': previousRole,
                'papelAtual': currentRole,
              },
            );

            return true; // ? CONFLITO DETECTADO
          }
        }
      }

      // ---------------------------------------------------------------
      // ?? VALIDA??O 2 (v7.6.32): MESMO PAPEL em NOMES DIFERENTES
      // ---------------------------------------------------------------
      final currentRole = RolePatterns.extractRoleForName(name, blockText);

      if (currentRole != null && currentRole != 'indefinido') {
        final normalizedCurrent = _normalizeRole(currentRole);

        // Verificar se este PAPEL j? existe com um NOME DIFERENTE
        for (final existingName in tracker.confirmedNames) {
          if (existingName.toLowerCase() == name.toLowerCase()) {
            continue; // Mesmo nome = OK (j? validado acima)
          }

          final existingRole = tracker.getRole(existingName);
          if (existingRole == null) continue;

          final normalizedExisting = _normalizeRole(existingRole);

          // ?? PAP?IS CR?TICOS que DEVEM ser ?nicos (1 nome por papel)
          final uniqueRoles = {
            'protagonista',
            'protagonist',
            'main character',
            'narradora',
            'narrador',
            'narrator',
            'hero',
            'heroine',
            'her?i',
            'hero?na',
          };

          // Se MESMO PAPEL com NOMES DIFERENTES = ERRO CR?TICO!
          if (normalizedCurrent == normalizedExisting) {
            // Verificar se ? papel cr?tico que deve ser ?nico
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
                debugPrint('?????? v7.6.32: PAPEL DUPLICADO DETECTADO! ??????');
                debugPrint('   ? Papel: "$currentRole" ? "$normalizedCurrent"');
                debugPrint('   ? Nome anterior: "$existingName"');
                debugPrint('   ? Nome atual: "$name"');
                debugPrint(
                  '   ?? EXEMPLO DO BUG: "Ashley" sendo protagonista E "Emily" sendo protagonista!',
                );
                debugPrint(
                  '   ?? Bloco $blockNumber ser? REJEITADO e REGENERADO',
                );
                debugPrint('?????? FIM DO ALERTA ??????');
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

              return true; // ? CONFLITO CR?TICO DETECTADO
            }
          }
        }
      }

      // ---------------------------------------------------------------
      // ?? VALIDA??O 3 (v7.6.33): PAP?IS POSSESSIVOS SINGULARES
      // ---------------------------------------------------------------
      // OBJETIVO: Detectar pap?is ?nicos indicados por possessivos singulares
      // EXEMPLO RUIM: "my lawyer, Richard" (Bloco 5) ? "my lawyer, Mark" (Bloco 10)
      //
      // Quando texto usa "my X" (possessive singular), indica papel ?nico
      // N?o pode haver m?ltiplas inst?ncias: "my lawyer" = apenas 1 advogado
      //
      // ?? Detecta padr?es:
      // - "my lawyer", "my attorney", "my doctor"
      // - "my therapist", "my accountant", "my agent"
      // - "my boss", "my mentor", "my partner"
      //
      // ?? IMPORTANTE: "my lawyers" (plural) N?O ? considerado ?nico
      // ---------------------------------------------------------------

      // Padr?o para detectar possessivos singulares
      // Captura: "my [role]" mas N?O "my [role]s" (plural)
      // ?? v7.6.34: EXPANDIDO para capturar multi-word roles (executive assistant, financial advisor, etc.)
      final possessiveSingularPattern = RegExp(
        r'\b(?:my|nossa)\s+(?:executive\s+assistant|personal\s+assistant|financial\s+advisor|real\s+estate\s+agent|estate\s+planner|tax\s+advisor|makeup\s+artist|physical\s+therapist|occupational\s+therapist|speech\s+therapist|au\s+pair|dalai\s+lama|vice[-\s]president|lawyer|attorney|doctor|therapist|accountant|agent|boss|mentor|partner|adviser|advisor|consultant|coach|teacher|tutor|counselor|psychologist|psychiatrist|dentist|surgeon|specialist|physician|nurse|caregiver|assistant|secretary|manager|supervisor|director|ceo|cfo|cto|president|chairman|investor|banker|auditor|notary|mediator|arbitrator|investigator|detective|officer|sergeant|captain|lieutenant|judge|magistrate|prosecutor|defender|guardian|curator|executor|trustee|beneficiary|architect|engineer|contractor|builder|designer|decorator|landscaper|gardener|housekeeper|maid|butler|chef|cook|driver|chauffeur|pilot|navigator|guide|translator|interpreter|editor|publisher|producer|publicist|stylist|hairdresser|barber|beautician|esthetician|masseuse|trainer|nutritionist|dietitian|pharmacist|optometrist|veterinarian|groomer|walker|sitter|nanny|governess|babysitter|midwife|doula|chiropractor|acupuncturist|hypnotist|healer|shaman|priest|pastor|minister|rabbi|imam|monk|nun|chaplain|deacon|elder|bishop|archbishop|cardinal|pope|guru|sensei|sifu|master|grandmaster)(?![a-z])',
        caseSensitive: false,
      );

      final possessiveMatches = possessiveSingularPattern.allMatches(blockText);

      for (final match in possessiveMatches) {
        // ?? v7.6.34: Captura o grupo completo (incluindo multi-word roles)
        final possessiveRole = match
            .group(0)
            ?.replaceFirst(
              RegExp(r'\b(?:my|nossa)\s+', caseSensitive: false),
              '',
            )
            .toLowerCase()
            .trim();

        if (possessiveRole == null || possessiveRole.isEmpty) continue;

        // Verificar se J? existe este papel possessivo com NOME DIFERENTE
        for (final existingName in tracker.confirmedNames) {
          if (existingName.toLowerCase() == name.toLowerCase()) {
            continue; // Mesmo nome = OK
          }

          final existingRole = tracker.getRole(existingName);
          if (existingRole == null) continue;

          final normalizedExisting = _normalizeRole(existingRole).toLowerCase();

          // ?? v7.6.34: Match exato ou cont?m o papel completo (executive assistant, etc.)
          final possessiveRoleNormalized = possessiveRole.replaceAll(
            RegExp(r'\s+'),
            ' ',
          );

          // Verificar se papel possessivo j? existe
          if (normalizedExisting.contains(possessiveRoleNormalized) ||
              possessiveRoleNormalized.contains(
                normalizedExisting.split(' ').last,
              )) {
            if (kDebugMode) {
              debugPrint(
                '?????? v7.6.34: PAPEL POSSESSIVO SINGULAR DUPLICADO! ??????',
              );
              debugPrint('   ? Papel possessivo: "my $possessiveRole"');
              debugPrint(
                '   ? Nome anterior: "$existingName" (papel: "$existingRole")',
              );
              debugPrint('   ? Nome atual: "$name"');
              debugPrint('   ?? EXEMPLOS DO BUG:');
              debugPrint('      - "my lawyer, Richard" ? "my lawyer, Mark"');
              debugPrint(
                '      - "my executive assistant, Lauren" ? "my executive assistant, Danielle"',
              );
              debugPrint(
                '   ?? "my X" indica papel ?NICO - n?o pode haver m?ltiplos!',
              );
              debugPrint(
                '   ?? Bloco $blockNumber ser? REJEITADO e REGENERADO',
              );
              debugPrint('?????? FIM DO ALERTA ??????');
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

            return true; // ? CONFLITO POSSESSIVO DETECTADO
          }
        }
      }
    }

    return false; // ? Nenhum conflito de nomes ou pap?is
  }

  /// ?? v7.6.26: Normaliza papel SELETIVAMENTE (evita falsos positivos)
  ///
  /// PAP?IS FAMILIARES: Mant?m completo "m?e de Emily" ? "m?e de Michael"
  /// PAP?IS GEN?RICOS: Normaliza "advogado de Sarah" ? "advogado"
  ///
  /// Exemplo:
  /// - "m?e de Emily" ? "m?e de emily" (mant?m rela??o)
  /// - "irm?o de Jo?o" ? "irm?o de jo?o" (mant?m rela??o)
  /// - "advogado de Sarah" ? "advogado" (remove rela??o)
  /// - "m?dico de Michael" ? "m?dico" (remove rela??o)
  /// 🎯 v7.6.74: Delegado ao módulo RolePatterns (SOLID)
  String _normalizeRole(String role) =>
      RolePatterns.normalizeRoleSelective(role);

  // 🔧 v7.6.86: Wrapper _extractRoleForName removido
  // Usar RolePatterns.extractRoleForName() diretamente

  /// 🔍 VALIDAÇÃO FORTALECIDA: Detecta quando um nome é reutilizado para outro personagem
  /// 🔧 v7.6.67: Refatorado para usar RolePatterns module
  /// Exemplo: "Regina" sendo usada para sogra E amiga, "Marta" para irmã de A e irmã de B
  void _validateNameReuse(
    String generatedText,
    CharacterTracker tracker,
    int blockNumber,
  ) {
    // Extrair todos os nomes do texto gerado
    final namePattern = RegExp(r'\b([A-Z������������������a-z������������������]{2,})\b');
    final foundNames = <String>{};

    for (final match in namePattern.allMatches(generatedText)) {
      final name = match.group(1)?.trim();
      if (name != null && NameValidator.looksLikePersonName(name)) {
        foundNames.add(name);
      }
    }

    // Verificar se algum nome encontrado J� existe no tracker com papel diferente
    for (final name in foundNames) {
      if (tracker.hasName(name)) {
        final existingRole = tracker.getRole(name);

        // ??? v7.6.67: Usar RolePatterns para extrair papel atual
        final currentRole = RolePatterns.extractRoleForName(name, generatedText);
        
        if (currentRole != null) {
          // DETEC��O: Se papel atual difere do existente
          if (existingRole == null || existingRole == 'indefinido') {
            // Nome existia SEM papel definido, agora tem papel
            if (kDebugMode) {
              debugPrint('?? Nome "$name" definido como $currentRole (bloco $blockNumber)');
            }
          } else if (!RolePatterns.areRolesEquivalent(currentRole, existingRole)) {
            // Conflito de pap�is
            _debugLogger.error(
              "Reutiliza��o de nome: '$name'",
              blockNumber: blockNumber,
              details:
                  "Nome '$name' usado em m�ltiplos pap�is diferentes:\n"
                  "- Papel anterior: $existingRole\n"
                  "- Papel atual: $currentRole",
              metadata: {
                'nome': name,
                'papelAnterior': existingRole,
                'papelAtual': currentRole,
              },
            );

            if (kDebugMode) {
              debugPrint('? ERRO: Nome "$name" reutilizado!');
              debugPrint('   Papel anterior: $existingRole');
              debugPrint('   Papel atual: $currentRole');
            }
          }
        }
      }
    }

    // DEBUG: Log valida��o completa
    _debugLogger.validation(
      "Valida��o de reutiliza��o completa",
      blockNumber: blockNumber,
      details: "${foundNames.length} nomes verificados",
      metadata: {'nomesVerificados': foundNames.length},
    );
  }

  /// ?? NOVA VALIDA��O: Detecta inconsist�ncias em rela��es familiares
  /// ??? v7.6.67: Refatorado para usar RolePatterns module
  /// Exemplo: "meu Pai Francisco" vs "meu marido Francisco" = CONFUS�O
  void _validateFamilyRelations(String generatedText, int blockNumber) {
    // Extrair nomes mencionados no texto
    final namePattern = RegExp(r'\b([A-Z������������������][a-z������������������]{2,})\b');
    final names = <String>{};

    for (final match in namePattern.allMatches(generatedText)) {
      final name = match.group(1)?.trim();
      if (name != null && NameValidator.looksLikePersonName(name)) {
        names.add(name);
      }
    }

    // Para cada nome, usar RolePatterns para detectar papel
    for (final name in names) {
      final role = RolePatterns.extractRoleForName(name, generatedText);
      
      // Se detectou papel, verificar se h� conflitos
      if (role != null) {
        // Verificar se mesmo nome aparece em contextos conflitantes
        // usando l�gica simplificada baseada no m�dulo
        if (kDebugMode) {
          debugPrint('?? Nome "$name" detectado como: $role (bloco $blockNumber)');
        }
      }
    }
  }

  /// ?? NOVA VALIDA��O CR�TICA v7.6.16: Detecta mudan�as de nome de personagens
  /// Compara pap?is conhecidos (tracker) com novos nomes mencionados no texto
  /// Retorna lista de mudan?as detectadas para rejei??o do bloco
  List<Map<String, String>> _detectCharacterNameChanges(
    String generatedText,
    CharacterTracker tracker,
    int blockNumber,
  ) {
    final changes = <Map<String, String>>[];

    // Padr?es de rela??es familiares para detectar personagens
    final relationPatterns = {
      'pai': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Pp]ai(?:,)?\s+([A-Z????????????][a-z????????????]+)',
        caseSensitive: false,
      ),
      'm?e': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Mm]?e(?:,)?\s+([A-Z????????????][a-z????????????]+)',
        caseSensitive: false,
      ),
      'marido': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:marido|esposo)(?:,)?\s+([A-Z????????????][a-z????????????]+)',
        caseSensitive: false,
      ),
      'esposa': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:esposa|mulher)(?:,)?\s+([A-Z????????????][a-z????????????]+)',
        caseSensitive: false,
      ),
      'filho': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Ff]ilho(?:,)?\s+([A-Z????????????][a-z????????????]+)',
        caseSensitive: false,
      ),
      'filha': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Ff]ilha(?:,)?\s+([A-Z????????????][a-z????????????]+)',
        caseSensitive: false,
      ),
      'irm?o': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:irm?o|irmao)(?:,)?\s+([A-Z????????????][a-z????????????]+)',
        caseSensitive: false,
      ),
      'irm?': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:irm?|irma)(?:,)?\s+([A-Z????????????][a-z????????????]+)',
        caseSensitive: false,
      ),
      'advogado': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Aa]dvogad[oa](?:,)?\s+([A-Z????????????][a-z????????????]+)',
        caseSensitive: false,
      ),
      'investigador': RegExp(
        r'(?:o|um)\s+[Ii]nvestigador(?:,)?\s+([A-Z????????????][a-z????????????]+)',
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
        if (newName == null || !NameValidator.looksLikePersonName(newName)) continue;

        // Verificar se este papel j? tem um nome no tracker
        final existingName = tracker.getNameForRole(role);

        if (existingName != null && existingName != newName) {
          // ?? MUDAN?A DETECTADA!
          changes.add({
            'role': role,
            'oldName': existingName,
            'newName': newName,
          });

          if (kDebugMode) {
            debugPrint(
              '?? MUDAN?A DE NOME: "$role" era "$existingName" ? agora "$newName"!',
            );
          }
        }
      }
    }

    return changes;
  }

  // 🔧 v7.6.82: Wrappers _looksLikePersonName e _isLikelyName removidos
  // 🔧 v7.6.85: Wrappers perspectiveLabel e _getPerspectiveInstruction removidos
  // Usar PerspectiveBuilder.perspectiveLabel() e PerspectiveBuilder.getPerspectiveInstruction() diretamente

  /// 📦 OTIMIZAÇÃO: Limita contexto aos últimos blocos para evitar timeouts
  /// Mantém apenas os últimos N blocos + resumo inicial para continuidade
  String _buildLimitedContext(
    String fullContext,
    int currentBlock,
    int maxRecentBlocks,
  ) {
    if (fullContext.isEmpty || currentBlock <= maxRecentBlocks) {
      return fullContext; // Blocos iniciais usam tudo
    }

    // ?? LIMITE ABSOLUTO OTIMIZADO: Reduzido para evitar timeout em idiomas pesados
    // ?? CR?TICO: 5.6k palavras causava timeout API 503 nos blocos 7-8
    // 3.5k palavras = ~21k caracteres cir?lico (mais seguro para Gemini)
    const maxContextWords = 3500; // REDUZIDO de 4500 para 3500
    final currentWords = _countWords(fullContext);

    if (currentWords <= maxContextWords) {
      return fullContext; // Contexto ainda est? em tamanho seguro
    }

    // Separar em blocos (par?grafos duplos ou mais)
    final blocks = fullContext.split(RegExp(r'\n{2,}'));
    if (blocks.length <= maxRecentBlocks + 5) {
      return fullContext; // Ainda n?o tem muitos blocos
    }

    // Pegar resumo inicial (primeiros 3 par?grafos - REDUZIDO de 5 para 3)
    final initialSummary = blocks.take(3).join('\n\n');

    // Pegar ?ltimos N blocos completos (REDUZIDO multiplicador de 5 para 3)
    final recentBlocks = blocks
        .skip(max(0, blocks.length - maxRecentBlocks * 3))
        .join('\n\n');

    final result = '$initialSummary\n\n[...]\n\n$recentBlocks';

    // Verificar se ainda est? muito grande
    if (_countWords(result) > maxContextWords) {
      // Reduzir ainda mais - s? ?ltimos blocos (REDUZIDO multiplicador de 3 para 2)
      return blocks
          .skip(max(0, blocks.length - maxRecentBlocks * 2))
          .join('\n\n');
    }

    return result;
  }

  /// ?? Delegado ao m�dulo PerspectiveBuilder (SOLID)
  double _getLanguageVerbosityMultiplier(String language) =>
      PerspectiveBuilder.getLanguageVerbosityMultiplier(language);

  Future<String> _generateBlockContent(
    String previous,
    int target,
    String phase,
    ScriptConfig c,
    CharacterTracker tracker,
    int blockNumber,
    int totalBlocks, {
    bool avoidRepetition =
        false, // ?? NOVO: Flag para regenera??o anti-repeti??o
    WorldState? worldState, // ??? v7.6.64: Usa WorldState do m?dulo (SOLID)
  }) async {
    // ?? IMPORTANTE: target vem SEMPRE em PALAVRAS de _calculateTargetForBlock()
    // Mesmo quando measureType='caracteres', _calculateTargetForBlock j? converteu caracteres?palavras
    // O Gemini trabalha melhor com contagem de PALAVRAS, ent?o sempre pedimos palavras no prompt
    // Depois contamos caracteres no resultado final para validar se atingiu a meta do usu?rio
    final needed = target;
    if (needed <= 0) return '';

    // ?? OTIMIZA??O CR?TICA: Limitar contexto aos ?ltimos N blocos
    // v6.0: Portugu?s usa MENOS contexto (3 blocos) para evitar erro 503
    // Outros idiomas: 4 blocos (padr?o)
    // RATIONALE: Portugu?s = mais tokens ? precisa contexto menor
    final isPortuguese = c.language.toLowerCase().contains('portugu');
    final maxContextBlocks = isPortuguese
        ? 3
        : 4; // PORTUGU?S: 3 blocos (era 4)

    // Blocos iniciais (1-4): contexto completo
    // Blocos m?dios/finais (5+): ?ltimos N blocos apenas
    String contextoPrevio = previous.isEmpty
        ? ''
        : _buildLimitedContext(previous, blockNumber, maxContextBlocks);

    if (kDebugMode && previous.isNotEmpty) {
      final contextUsed = contextoPrevio.length;
      final contextType = blockNumber <= maxContextBlocks
          ? 'COMPLETO'
          : 'LIMITADO (?ltimos $maxContextBlocks blocos)';
      debugPrint(
        '?? CONTEXTO $contextType: $contextUsed chars (${_countWords(contextoPrevio)} palavras)',
      );
      if (blockNumber > maxContextBlocks) {
        debugPrint(
          '   Original: ${previous.length} chars ? Reduzido: $contextUsed chars (${((1 - contextUsed / previous.length) * 100).toStringAsFixed(0)}% menor)',
        );
      }
    }

    // ?? SOLU??O 3: Refor?ar os nomes confirmados no prompt para manter consist?ncia
    String trackerInfo = '';

    // ?? v7.6.36: LEMBRETE CR?TICO DE NOMES - Muito mais agressivo!
    // Aparece no IN?CIO de cada bloco para evitar que Gemini "esque?a" nomes
    if (tracker.confirmedNames.isNotEmpty && blockNumber > 1) {
      final nameReminder = StringBuffer();
      nameReminder.writeln('');
      nameReminder.writeln(
        '????????????????????????????????????????????????????????????',
      );
      nameReminder.writeln(
        '?? LEMBRETE OBRIGAT?RIO DE NOMES - LEIA ANTES DE CONTINUAR! ??',
      );
      nameReminder.writeln(
        '????????????????????????????????????????????????????????????',
      );
      nameReminder.writeln('');
      nameReminder.writeln(
        '?? PERSONAGENS DESTA HIST?RIA (USE SEMPRE ESTES NOMES):',
      );
      nameReminder.writeln('');

      // Listar cada personagem com seu papel de forma MUITO clara
      for (final name in tracker.confirmedNames) {
        final role = tracker.getRole(name) ?? 'personagem';
        nameReminder.writeln('   ? $name = $role');
      }

      nameReminder.writeln('');
      nameReminder.writeln('? PROIBIDO MUDAR ESTES NOMES! ?');
      nameReminder.writeln('');

      // Adicionar protagonista de forma EXTRA enf?tica
      final protagonistName = c.protagonistName.trim();
      if (protagonistName.isNotEmpty) {
        nameReminder.writeln(
          '?? A PROTAGONISTA/NARRADORA SE CHAMA: $protagonistName',
        );
        nameReminder.writeln('   ? Quando ela fala de si mesma: "i" ou "me"');
        nameReminder.writeln(
          '   ? Quando outros falam dela: "$protagonistName"',
        );
        nameReminder.writeln(
          '   ? NUNCA mude para Emma, Jessica, Lauren, Sarah, etc!',
        );
        nameReminder.writeln('');
      }

      // Listar mapeamento reverso (papel ? nome) para refor?ar
      final roleMap = tracker.roleToNameMap;
      if (roleMap.isNotEmpty) {
        nameReminder.writeln('?? MAPEAMENTO PAPEL ? NOME (CONSULTE SEMPRE):');
        for (final entry in roleMap.entries) {
          nameReminder.writeln('   ? ${entry.key} ? ${entry.value}');
        }
        nameReminder.writeln('');
      }

      nameReminder.writeln(
        '?? SE VOC? TROCAR UM NOME, O ROTEIRO SER? REJEITADO! ??',
      );
      nameReminder.writeln(
        '????????????????????????????????????????????????????????????',
      );
      nameReminder.writeln('');

      trackerInfo = nameReminder.toString();

      if (kDebugMode) {
        debugPrint('?? Bloco $blockNumber - LEMBRETE DE NOMES INJETADO:');
        debugPrint('   Personagens: ${tracker.confirmedNames.join(", ")}');
        debugPrint('   Protagonista: $protagonistName');
      }
    } else if (tracker.confirmedNames.isNotEmpty) {
      // Bloco 1: lista mais simples
      trackerInfo =
          '\n?? NOMES J? USADOS - NUNCA REUTILIZE: ${tracker.confirmedNames.join(", ")}\n';
      trackerInfo +=
          '?? Se precisa de novo personagem, use NOME TOTALMENTE DIFERENTE!\n';

      final mapping = tracker.getCharacterMapping();
      if (mapping.isNotEmpty) {
        trackerInfo += mapping;
        trackerInfo +=
            '\n?? REGRA CR?TICA: NUNCA use o mesmo nome para personagens diferentes!\n';
      }
    }

    // ?? CORRE??O CR?TICA: SEMPRE injetar nome da protagonista, mesmo que n?o esteja no tracker
    final protagonistName = c.protagonistName.trim();
    if (protagonistName.isNotEmpty && !trackerInfo.contains(protagonistName)) {
      trackerInfo +=
          '\n?? ATEN??O ABSOLUTA: O NOME DA PROTAGONISTA ? "$protagonistName"!\n';
      trackerInfo += '   ? NUNCA mude para outro nome (Wanessa, Carla, etc)\n';
      trackerInfo +=
          '   ? SEMPRE use "$protagonistName" quando se referir ? protagonista!\n';
    }
    final characterGuidance = CharacterGuidanceBuilder.buildGuidance(c, tracker);

    // ?? v7.6.52: WORLD STATE CONTEXT - Mem?ria Infinita
    // Adiciona contexto estruturado de personagens, invent?rio e fatos
    String worldStateContext = '';
    if (worldState != null && blockNumber > 1) {
      worldStateContext = worldState.getContextForPrompt();
      if (kDebugMode && worldStateContext.isNotEmpty) {
        debugPrint(
          '?? World State injetado no prompt (${worldStateContext.length} chars)',
        );
      }
    }

    // ?? IMPORTANTE: Limitar palavras por bloco para estabilidade
    // O Gemini funciona melhor com targets de PALAVRAS, n?o caracteres
    // Limite m?ximo: 3500 palavras/bloco (? 19.250 caracteres)
    final limitedNeeded = min(needed, 3500); // Sempre limitar em palavras

    // ?? SEMPRE pedir palavras no prompt (Gemini trabalha melhor assim)
    // O sistema converter? caracteres?palavras antes de chegar aqui (_calculateTargetForBlock)
    // E validar? caracteres no resultado final

    // ?? AJUSTE POR IDIOMA: Compensar verbosidade natural de cada idioma
    // Portugu?s (baseline 1.0) funciona perfeitamente, outros ajustam proporcionalmente
    final languageMultiplier = _getLanguageVerbosityMultiplier(c.language);
    final adjustedTarget = (limitedNeeded * languageMultiplier).round();

    // Detectar se ? espanhol para mensagem espec?fica
    final isSpanish =
        c.language.toLowerCase().contains('espanhol') ||
        c.language.toLowerCase().contains('spanish') ||
        c.language.toLowerCase().contains('espa?ol');

    // ?? CONTROLE RIGOROSO DE CONTAGEM: ?8% aceit?vel (ajustado de ?10%)
    // RAZ?O: Multiplicador 1.08 deve manter resultado entre 92-108% da meta
    final minAcceptable = (adjustedTarget * 0.92).round();
    final maxAcceptable = (adjustedTarget * 1.08).round();

    final measure = isSpanish
        ? 'GERE EXATAMENTE $adjustedTarget palabras (M?NIMO $minAcceptable, M?XIMO $maxAcceptable). ? MELHOR ficar perto de $adjustedTarget do que muito abaixo!'
        : 'GERE EXATAMENTE $adjustedTarget palavras (M?NIMO $minAcceptable, M?XIMO $maxAcceptable). ? MELHOR ficar perto de $adjustedTarget do que muito abaixo!';
    final localizationGuidance = BaseRules.buildLocalizationGuidance(c);
    final narrativeStyleGuidance = NarrativeStyleBuilder.getNarrativeStyleGuidance(c);

    // ?? DEBUG: Verificar se modo GLOBAL est? sendo passado corretamente
    if (kDebugMode) {
      debugPrint('?? MODO DE LOCALIZA??O: ${c.localizationLevel.displayName}');
      if (c.localizationLevel == LocalizationLevel.global) {
        debugPrint(
          '? MODO GLOBAL ATIVO - Prompt deve evitar nomes/comidas brasileiras',
        );
        debugPrint(
          '?? Preview do prompt GLOBAL: ${localizationGuidance.substring(0, min(200, localizationGuidance.length))}...',
        );
      }
    }

    // ?? INTEGRAR T?TULO COMO HOOK IMPACTANTE NO IN?CIO
    String instruction;
    if (previous.isEmpty) {
      if (c.startWithTitlePhrase && c.title.trim().isNotEmpty) {
        instruction = BaseRules.getStartInstruction(
          c.language,
          withTitle: true,
          title: c.title,
        );
      } else {
        instruction = BaseRules.getStartInstruction(c.language, withTitle: false);
      }
    } else {
      instruction = BaseRules.getContinueInstruction(c.language);
    }

    // v7.6.63: Gemini ? o Casting Director - cria nomes apropriados para o idioma
    // Removido banco de nomes est?tico em favor de gera??o din?mica via LLM
    final nameList = ''; // N?o mais necess?rio - LLM gera nomes contextualmente

    // ?? Obter labels traduzidos para os metadados
    final labels = BaseRules.getMetadataLabels(c.language);

    //  Definir se inclui tema/subtema ou modo livre
    final temaSection = c.tema == 'Livre (Sem Tema)'
        ? '// Modo Livre: Desenvolva o roteiro baseado APENAS no t?tulo e contexto fornecidos\n'
        : '${labels['theme']}: ${c.tema}\n${labels['subtheme']}: ${c.subtema}\n';

    // ?? v7.6.44: SEMPRE incluir t?tulo como base da hist?ria
    // O t?tulo N?O ? apenas decorativo - ? a PREMISSA da hist?ria!
    final titleSection = c.title.trim().isNotEmpty
        ? '\n????????????????????????????????????????????????????\n'
              '?? T?TULO/PREMISSA OBRIGAT?RIA DA HIST?RIA:\n'
              '????????????????????????????????????????????????????\n'
              '"${c.title}"\n'
              '\n'
              '?? REGRA ABSOLUTA:\n'
              '   ? A hist?ria DEVE desenvolver os elementos deste t?tulo\n'
              '   ? Personagens, a??es e contexto do t?tulo s?o OBRIGAT?RIOS\n'
              '   ? N?O invente uma hist?ria diferente da proposta no t?tulo\n'
              '   ? O t?tulo ? a PROMESSA feita ao espectador - CUMPRA-A!\n'
              '\n'
              '?? EXEMPLOS:\n'
              '   ? T?tulo: "?? ?? ???? ???? ??? ??? ???"\n'
              '      ? Hist?ria DEVE ter: funcion?rio de conveni?ncia + idoso faminto + marmita compartilhada\n'
              '   \n'
              '   ? T?tulo: "Bilion?rio me ofereceu emprego ap?s eu ajudar um mendigo"\n'
              '      ? Hist?ria DEVE ter: protagonista + mendigo ajudado + revela??o (mendigo = bilion?rio)\n'
              '   \n'
              '   ? ERRO: Ignorar t?tulo e criar hist?ria sobre CEO infiltrado em empresa\n'
              '      ? Isso QUEBRA a promessa feita ao espectador!\n'
              '????????????????????????????????????????????????????\n\n'
        : '';

    // ?? CONSTRUIR LISTA DE NOMES PROIBIDOS (j? usados nesta hist?ria)
    String forbiddenNamesWarning = '';
    if (tracker.confirmedNames.isNotEmpty) {
      final forbiddenList = tracker.confirmedNames.join(', ');
      forbiddenNamesWarning =
          '?????? NOMES PROIBIDOS - N?O USE ESTES NOMES! ??????\n'
          '????????????????????????????????????????????????????\n'
          '? Os seguintes nomes J? EST?O EM USO nesta hist?ria:\n'
          '   ? $forbiddenList\n'
          '\n'
          '?? REGRA ABSOLUTA:\n'
          '   ? NUNCA reutilize os nomes acima!\n'
          '   ? Cada nome = 1 personagem ?nico\n'
          '   ? Se precisar de novo personagem, escolha nome DIFERENTE\n'
          '????????????????????????????????????????????????????\n'
          '\n';
    }

    // ?? Adicionar informa??es espec?ficas de blocos (n?o estava no template)
    // ?? v7.6.22: Adicionar lista de personagens sem fechamento no bloco final
    String closureWarning = '';
    if (blockNumber == totalBlocks) {
      final unresolved = tracker.getUnresolvedCharacters();
      if (unresolved.isNotEmpty) {
        closureWarning =
            '\n'
            '?????? ATEN??O CR?TICA - BLOCO FINAL ??????\n'
            '\n'
            '?? OS SEGUINTES PERSONAGENS AINDA N?O TIVERAM FECHAMENTO:\n'
            '   ${unresolved.map((name) => '? $name').join('\n   ')}\n'
            '\n'
            '? VOC? DEVE INCLUIR NESTE BLOCO FINAL:\n'
            '   Para CADA personagem acima, escreva:\n'
            '   1. O que aconteceu com ele/ela no final\n'
            '   2. Seu estado emocional/f?sico final\n'
            '   3. Resolu??o do seu arco narrativo\n'
            '\n'
            '?? EXEMPLOS DE FECHAMENTO CORRETO:\n'
            '   ? "Blake finalmente reconciliou com Taylor"\n'
            '   ? "Nicholas viu justi?a ser feita contra Arthur"\n'
            '   ? "Robert encontrou paz sabendo que a verdade veio ? tona"\n'
            '\n'
            '? N?O ? PERMITIDO:\n'
            '   ? Terminar a hist?ria sem mencionar esses personagens\n'
            '   ? Deixar seus destinos vagos ou impl?citos\n'
            '   ? Assumir que o leitor "vai entender"\n'
            '\n'
            '?? REGRA: Personagem importante = Fechamento expl?cito OBRIGAT?RIO\n'
            '????????????????????????????????????????????????????\n'
            '\n';
      } else {
        if (kDebugMode) {
          debugPrint('? TODOS os personagens importantes j? t?m fechamento!');
          debugPrint(
            '   Taxa de fechamento: ${(tracker.getClosureRate() * 100).toStringAsFixed(1)}%',
          );
        }
      }
    }

    final blockInfo =
        '\n'
        '????????????????????????????????????????????????????\n'
        '?? INFORMA??O DE BLOCOS (CR?TICO PARA PLANEJAMENTO):\n'
        '????????????????????????????????????????????????????\n'
        '   ? Total de blocos planejados: $totalBlocks\n'
        '   ? Bloco atual: bloco n?mero $blockNumber de $totalBlocks\n'
        '   ${blockNumber < totalBlocks ? '? Status: CONTINUA??O - Este N?O ? o ?ltimo bloco!' : '? Status: BLOCO FINAL - Conclua a hist?ria agora!'}\n'
        '\n'
        '$closureWarning'
        '${blockNumber < totalBlocks ? '? PROIBIDO NESTE BLOCO:\n   ? N?O finalize a hist?ria ainda!\n   ? N?O escreva "THE END" ou equivalente\n   ? N?O crie uma resolu??o completa e definitiva\n   ? N?O conclua todos os arcos narrativos\n   \n? OBRIGAT?RIO NESTE BLOCO:\n   ? CONTINUE desenvolvendo a trama\n   ? Mantenha tens?o e progress?o narrativa\n   ? Deixe ganchos para os pr?ximos blocos\n   ? A hist?ria DEVE ter continua??o nos blocos seguintes\n   ? Apenas desenvolva, N?O conclua!\n' : '? OBRIGAT?RIO NESTE BLOCO FINAL:\n   ? AGORA SIM finalize completamente a hist?ria\n   ? Resolva TODOS os conflitos pendentes\n   ? D? fechamento a TODOS os personagens\n   ? Este ? o ?LTIMO bloco - conclus?o definitiva!\n'}\n'
        '? ATEN??O ESPECIAL:\n'
        '   ? Hist?rias longas precisam de TODOS os blocos planejados\n'
        '   ? N?O termine prematuramente s? porque "parece completo"\n'
        '   ? Cada bloco ? parte de um roteiro maior - respeite o planejamento\n'
        '   ? Finais prematuros PREJUDICAM a qualidade e a experi?ncia do ouvinte\n'
        '????????????????????????????????????????????????????\n'
        '\n'
        '?? REGRA ABSOLUTA:\n'
        '   UMA HIST?RIA = UM CONFLITO CENTRAL = UM ARCO COMPLETO = UMA RESOLU??O\n'
        '   PAR?GRAFOS CURTOS = PAUSAS = DRAMATICIDADE = RETEN??O ALTA\n'
        '   UM NOME = UM PERSONAGEM = NUNCA REUTILIZAR = VERIFICAR SEMPRE\n'
        '   DI?LOGOS + MOTIVA??ES + CLOSURE = HIST?RIA COMPLETA E SATISFAT?RIA\n'
        '\n'
        '?? NUNCA crie duas hist?rias separadas dentro do mesmo roteiro!\n'
        '?? NUNCA escreva par?grafos com mais de 180 palavras!\n'
        '?? NUNCA reutilize nomes de personagens j? mencionados!\n'
        '?? NUNCA deixe personagens importantes sem destino final!\n'
        '?? NUNCA fa?a trai??es/conflitos sem motiva??o clara!\n'
        '?? NUNCA repita a mesma frase/met?fora mais de 2 vezes no roteiro!\n'
        '?? NUNCA introduza personagens secund?rios que desaparecem sem explica??o!\n'
        '${blockNumber < totalBlocks ? '?? NUNCA finalize a hist?ria antes do bloco final ($totalBlocks)!\n' : ''}'
        '\n'
        '?? REGRAS DE REPETI??O E VARIA??O:\n'
        '   ? Frases marcantes do protagonista: m?ximo 2 repeti??es no roteiro inteiro\n'
        '   ? Ap?s primeira men??o: use VARIA??ES ou refer?ncias INDIRETAS\n'
        '   ? Exemplo: "lies are like cracks" ? depois: "his foundation was crumbling" ou "the truth had started to show"\n'
        '   ? Met?foras do pai/mentor: primeira vez completa, depois apenas alus?es\n'
        '   ? Evite eco narrativo: n?o repita descri??es j? feitas (humilha??o inicial, etc.)\n'
        '\n'
        '?? REGRAS DE PERSONAGENS SECUND?RIOS:\n'
        '   ? TODO personagem introduzido DEVE ter resolu??o clara:\n'
        '   ? Se aparece na investiga??o ? DEVE aparecer no cl?max/desfecho\n'
        '   ? Se fornece informa??o crucial ? DEVE testemunhar/ajudar no final\n'
        '   ? Se ? v?tima/testemunha do passado ? DEVE ter papel na justi?a/vingan?a\n'
        '   ? PROIBIDO: introduzir personagem importante e depois abandon?-lo\n'
        '   ? Exemplo: Se Robert Peterson revela segredo ? ele DEVE aparecer no tribunal/confronto final\n'
        '\n'
        '   ?? LISTA DE VERIFICA??O ANTES DO BLOCO FINAL:\n'
        '   \n'
        '   Personagens que N?O PODEM desaparecer:\n'
        '   ? Quem forneceu evid?ncia crucial (documentos, testemunho)\n'
        '   ? Quem foi v?tima do antagonista no passado\n'
        '   ? Quem ajudou o protagonista na investiga??o\n'
        '   ? Quem tem conhecimento direto do crime/segredo\n'
        '   ? Familiar/amigo importante mencionado m?ltiplas vezes\n'
        '   \n'
        '   ?? EXEMPLOS DE FECHAMENTO OBRIGAT?RIO:\n'
        '   \n'
        '   ? Se "Robert revelou que seu pai Harold foi enganado":\n'
        '      ? No cl?max: "Robert entrou no tribunal. Olhou Alan nos olhos..."\n'
        '      ? No desfecho: "Robert finalmente tinha paz. A verdade sobre Harold veio ? tona."\n'
        '   \n'
        '   ? Se "Kimberly, a paralegal, guardou c?pias dos documentos":\n'
        '      ? No cl?max: "Kimberly testemunhou. \'Alan me ordenou falsificar a assinatura\'..."\n'
        '      ? No desfecho: "Kimberly foi elogiada por sua coragem em preservar as evid?ncias."\n'
        '   \n'
        '   ? Se "David, o contador, descobriu a fraude primeiro":\n'
        '      ? No cl?max: "David apresentou os registros financeiros alterados..."\n'
        '      ? No desfecho: "David foi promovido a CFO ap?s a queda de Alan."\n'
        '   \n'
        '   ? NUNCA fa?a isso:\n'
        '      ? "Robert me deu o documento" ? [nunca mais mencionado] ? ERRO!\n'
        '      ? "Kimberly tinha as provas" ? [some da hist?ria] ? ERRO!\n'
        '      ? "David descobriu tudo" ? [n?o aparece no final] ? ERRO!\n'
        '\n'
        '? REGRAS DE MARCADORES TEMPORAIS:\n'
        '   ? Entre mudan?as de cena/localiza??o: SEMPRE incluir marcador temporal\n'
        '   ? Exemplos: "tr?s dias depois...", "na manh? seguinte...", "uma semana se passou..."\n'
        '   ? Flashbacks: iniciar com "anos atr?s..." ou "naquele dia em [ano]..."\n'
        '   ? Saltos grandes (meses/anos): ser espec?fico: "seis meses depois" n?o "algum tempo depois"\n'
        '   ? Isso mant?m o leitor orientado na linha temporal da hist?ria\n'
        '\n'
        '??????????? REGRAS DE COER?NCIA DE RELACIONAMENTOS FAMILIARES:\n'
        '   ?? ERRO CR?TICO: Relacionamentos familiares inconsistentes!\n'
        '   \n'
        '   ANTES de introduzir QUALQUER rela??o familiar, VALIDE:\n'
        '   \n'
        '   ? CORRETO - L?gica familiar coerente:\n'
        '      ? "meu irm?o Paul casou com Megan" ? Megan ? minha CUNHADA\n'
        '      ? "Paul ? meu irm?o" + "Megan ? esposa de Paul" = "Megan ? minha cunhada"\n'
        '      ? "minha irm? Maria casou com Jo?o" ? Jo?o ? meu CUNHADO\n'
        '   \n'
        '   ? ERRADO - Contradi??es:\n'
        '      ? Chamar de "my sister-in-law" (cunhada) E depois "my brother married her" ? CONFUSO!\n'
        '      ? "meu sogro Carlos" mas nunca mencionar c?njuge ? QUEM ? casado com filho/filha dele?\n'
        '      ? "my father-in-law Alan" mas protagonista solteiro ? IMPOSS?VEL!\n'
        '   \n'
        '   ?? TABELA DE VALIDA??O (USE ANTES DE ESCREVER):\n'
        '   \n'
        '   SE escrever: "my brother Paul married Megan"\n'
        '   ? Megan ?: "my sister-in-law" (cunhada)\n'
        '   ? Alan (pai de Megan) ?: "my brother\'s father-in-law" (sogro do meu irm?o)\n'
        '   ? NUNCA chamar Alan de "my father-in-law" (seria se EU casasse com Megan)\n'
        '   \n'
        '   SE escrever: "my wife Sarah\'s father Robert"\n'
        '   ? Robert ?: "my father-in-law" (meu sogro)\n'
        '   ? Sarah ?: "my wife" (minha esposa)\n'
        '   ? Irm?o de Sarah ?: "my brother-in-law" (meu cunhado)\n'
        '   \n'
        '   ?? REGRA DE OURO:\n'
        '      Antes de usar "cunhado/cunhada/sogro/sogra/genro/nora":\n'
        '      1. Pergunte: QUEM ? casado com QUEM?\n'
        '      2. Desenhe mentalmente a ?rvore geneal?gica\n'
        '      3. Valide se a rela??o faz sentido matem?tico\n'
        '      4. Se confuso, use nomes pr?prios em vez de rela??es\n'
        '   \n'
        '   ?? SE HOUVER D?VIDA: Use "Megan" em vez de tentar definir rela??o familiar!\n'
        '????????????????????????????????????????????????????\n';

    // 🔒 CRITICAL: ADICIONAR INSTRUÇÃO DE PERSPECTIVA/GÊNERO NO INÍCIO DO PROMPT
    final perspectiveInstruction = PerspectiveBuilder.getPerspectiveInstruction(c.perspective, c);

    // ?? NOVO: Combinar prompt do template (compacto) + informa??es de bloco
    final compactPrompt = MainPromptTemplate.buildCompactPrompt(
      language: BaseRules.getLanguageInstruction(c.language),
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
    );

    final prompt =
        '$perspectiveInstruction\n????????????????????????????????????????????????????\n\n$worldStateContext$titleSection$compactPrompt$blockInfo';

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
      // ?? GEMINI 2.5 PRO: Suporta at? 65.535 tokens de sa?da!
      // Aumentado para 50.000 tokens (76% da capacidade) para idiomas cir?licos

      // ?? AJUSTE: Idiomas n?o-latinos (cir?lico, etc.) consomem mais tokens
      final languageNormalized = c.language.toLowerCase().trim();
      final isCyrillic =
          languageNormalized.contains('russo') ||
          languageNormalized.contains('b?lgar') ||
          languageNormalized.contains('bulgar') ||
          languageNormalized == 'ru' ||
          languageNormalized == 'bg';
      final isTurkish =
          languageNormalized.contains('turco') || languageNormalized == 'tr';

      // Cir?lico e turco precisam de 5x mais tokens por caractere (aumentado de 4x)
      // Idiomas latinos mant?m 2.5x (aumentado de 2x) para mais margem
      final tokenMultiplier = c.measureType == 'caracteres'
          ? (isCyrillic || isTurkish ? 5.0 : 2.5)
          : 12.0; // Aumentado de 10.0 para 12.0 para palavras

      final maxTokensCalculated = (needed * tokenMultiplier).ceil();
      final maxTokensLimit = 50000; // Aumentado de 32.768 para 50.000 tokens
      final finalMaxTokens = maxTokensCalculated > maxTokensLimit
          ? maxTokensLimit
          : maxTokensCalculated;

      // ?? SELE??O DE MODELO BASEADA EM qualityMode
      // ?? v7.6.51: Arquitetura Pipeline Modelo ?nico - usar helper centralizado
      final selectedModel = _getSelectedModel(c.qualityMode);

      if (kDebugMode) {
        debugPrint('[$_instanceId] ?? qualityMode = "${c.qualityMode}"');
        debugPrint('[$_instanceId] ?? selectedModel = "$selectedModel"');
      }

      // ??? v7.6.64: Usar LlmClient para gera??o principal (SOLID)
      final data = await _llmClient.generateText(
        apiKey: c.apiKey,
        model: selectedModel,
        prompt: prompt,
        maxTokens: finalMaxTokens,
      );

      // ?? v7.6.20: Registrar sucesso da API para Adaptive Delay Manager
      if (data.isNotEmpty) {
        _recordApiSuccess();
      }

      final text = data;
      final filtered = text.isNotEmpty
          ? await TextFilter.filterDuplicateParagraphs(previous, text)
          : '';

      // ?? v7.6.21: VALIDA??O CR?TICA - Nome da protagonista
      if (filtered.isNotEmpty) {
        final isValidProtagonist = _validateProtagonistName(
          filtered,
          c,
          blockNumber,
        );
        if (!isValidProtagonist) {
          if (kDebugMode) {
            debugPrint(
              '? BLOCO $blockNumber REJEITADO: Nome errado da protagonista!',
            );
            debugPrint('   ?? For?ando regenera??o...');
          }
          return ''; // For?ar regenera??o
        }

        // ?? v7.6.22: VALIDA??O CR?TICA - Relacionamentos familiares
        final hasValidRelationships = _validateFamilyRelationships(
          filtered,
          blockNumber,
        );
        if (!hasValidRelationships) {
          if (kDebugMode) {
            debugPrint(
              '? BLOCO $blockNumber REJEITADO: Relacionamentos familiares inconsistentes!',
            );
            debugPrint('   ?? For?ando regenera??o...');
          }
          return ''; // For?ar regenera??o
        }

        // ?? v7.6.22: RASTREAMENTO - Detectar resolu??o de personagens
        tracker.detectResolutionInText(filtered, blockNumber);

        // ?? v7.6.23: VALIDA??O CR?TICA - Taxa de fechamento no bloco final
        if (blockNumber == totalBlocks) {
          final closureRate = tracker.getClosureRate();
          final minimumClosureRate = 0.90; // 90% m?nimo

          if (closureRate < minimumClosureRate) {
            final unresolved = tracker.getUnresolvedCharacters();
            if (kDebugMode) {
              debugPrint(
                '? BLOCO FINAL REJEITADO: Taxa de fechamento insuficiente!',
              );
              debugPrint(
                '   Taxa atual: ${(closureRate * 100).toStringAsFixed(1)}% (m?nimo: ${(minimumClosureRate * 100).toInt()}%)',
              );
              debugPrint(
                '   Personagens sem fechamento: ${unresolved.join(", ")}',
              );
              debugPrint(
                '   ?? For?ando regenera??o com fechamentos obrigat?rios...',
              );
            }
            return ''; // For?a regenera??o do bloco final
          } else {
            if (kDebugMode) {
              debugPrint(
                '? BLOCO FINAL ACEITO: Taxa de fechamento suficiente!',
              );
              debugPrint('   Taxa: ${(closureRate * 100).toStringAsFixed(1)}%');
            }
          }
        }
      }

      // ?? VALIDA??O DE TAMANHO: Rejeitar blocos que ultrapassem muito o limite
      // Aplic?vel a TODOS os idiomas, n?o s? espanhol
      if (filtered.isNotEmpty && languageMultiplier != 1.0) {
        final wordCount = _countWords(filtered);
        // ?? CORRE??O: Comparar com adjustedTarget (COM multiplicador), n?o limitedNeeded (SEM multiplicador)
        final overage = wordCount - adjustedTarget;
        final overagePercent = (overage / adjustedTarget) * 100;

        // ?? FIX: Aumentado de 10% ? 35% porque API Gemini frequentemente excede 20-30%
        // Rejeitar se ultrapassar mais de 35% do limite AJUSTADO
        if (overagePercent > 35) {
          if (kDebugMode) {
            debugPrint(
              '? BLOCO $blockNumber REJEITADO (${c.language.toUpperCase()}):',
            );
            debugPrint('   Multiplicador do idioma: ${languageMultiplier}x');
            debugPrint(
              '   Pedido: $adjustedTarget palavras (limite m?ximo ajustado)',
            );
            debugPrint(
              '   Recebido: $wordCount palavras (+${overagePercent.toStringAsFixed(1)}%)',
            );
            debugPrint('   ?? Retornando vazio para for?ar regenera??o...');
          }
          return ''; // For?ar regenera??o
        }

        if (kDebugMode && overage > 0) {
          debugPrint(
            '? BLOCO $blockNumber ACEITO (${c.language.toUpperCase()}):',
          );
          debugPrint(
            '   Multiplicador: ${languageMultiplier}x | Pedido: $adjustedTarget palavras',
          );
          debugPrint(
            '   Recebido: $wordCount palavras (+${overagePercent.toStringAsFixed(1)}%)',
          );
        }
      }

      // ?? LOGGING: Detectar quando bloco retorna vazio
      if (filtered.isEmpty) {
        if (kDebugMode) {
          debugPrint('?? BLOCO $blockNumber VAZIO DETECTADO!');
          if (text.isEmpty) {
            debugPrint('   Causa: Resposta da API estava vazia');
          } else {
            debugPrint('   Causa: Conte?do filtrado como duplicado');
            debugPrint('   Texto original: ${text.length} chars');
          }
        }
      }

      return filtered.isNotEmpty ? '\n$filtered' : '';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('? ERRO no bloco $blockNumber: $e');
      }
      return '';
    }
  }

  // ??? v7.6.64: _makeApiRequest migrado para LlmClient._makeRequest (SOLID)
  // Todas as chamadas agora usam _llmClient.generateText()

  // ??? v7.6.65: DELEGA??O para TextCleaner (Refatora??o SOLID)
  // Limpar texto de marca??es indesejadas
  String _cleanGeneratedText(String text) {
    return TextCleaner.cleanGeneratedText(text);
  }

  // 🔧 v7.6.84: Wrappers _extractNamesFromText e _validateNamesInText removidos
  // Usar NameValidator.extractNamesFromText() e NameValidator.validateNamesInText() diretamente

  /// Adiciona nomes novos ao rastreador global
  void _addNamesToTracker(String text) {
    final names = NameValidator.extractNamesFromText(text);
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
      debugPrint('?? Rastreador de nomes resetado para nova hist?ria');
    }
  }

  // M?todo p?blico para uso nos providers - OTIMIZADO PARA CONTEXTO
  // ?? v7.6.51: Suporte a qualityMode para Pipeline Modelo ?nico
  // ??? v7.6.64: Agora delega para LlmClient (SOLID)
  Future<String> generateTextWithApiKey({
    required String prompt,
    required String apiKey,
    String? model, // Se null, usa qualityMode
    String qualityMode =
        'pro', // ?? NOVO: Para determinar modelo automaticamente
    int maxTokens =
        16384, // AUMENTADO: Era 8192, agora 16384 para contextos mais ricos
  }) async {
    // Determinar modelo: usar expl?cito se fornecido, sen?o calcular via qualityMode
    final effectiveModel = model ?? _getSelectedModel(qualityMode);
    // CORRE??O: Reset de estado para evitar conflitos com gera??o de scripts
    if (_isCancelled) _isCancelled = false;

    return await _retryOnRateLimit(() async {
      try {
        debugPrint(
          'GeminiService: Iniciando requisi??o para modelo $effectiveModel',
        );
        // ??? v7.6.64: Usar LlmClient.generateText (SOLID)
        final result = await _llmClient.generateText(
          apiKey: apiKey,
          model: effectiveModel,
          prompt: prompt,
          maxTokens: maxTokens,
        );

        // ?? v7.6.20: Registrar sucesso da API para Adaptive Delay Manager
        if (result.isNotEmpty) {
          _recordApiSuccess();
        }

        debugPrint(
          'GeminiService: Resposta recebida - ${result.isNotEmpty ? 'Success' : 'Empty'}',
        );
        debugPrint('GeminiService: Length: ${result.length}');

        // Aplicar limpeza adicional se necess?rio
        final cleanResult = result.isNotEmpty
            ? _cleanGeneratedText(result)
            : '';
        return cleanResult;
      } catch (e) {
        debugPrint('GeminiService: Erro ao gerar texto: $e');
        throw Exception('Erro ao gerar texto: ${e.toString()}');
      }
    });
  }

  // ===================== SISTEMA ANTI-REPETI??O =====================
  // ??? v7.6.65: M?todos delegados para DuplicationDetector (Refatora??o SOLID)

  // ??? v7.6.65: DELEGA??O para DuplicationDetector (Refatora??o SOLID)
  /// Verifica se novo bloco ? muito similar aos blocos anteriores
  /// Retorna true se similaridade > threshold (padr?o 85%) OU se h? duplica??o literal
  bool _isTooSimilar(
    String newBlock,
    String previousContent, {
    double threshold = 0.85,
  }) {
    return DuplicationDetector.isTooSimilar(
      newBlock,
      previousContent,
      threshold: threshold,
    );
  }

  // Cache para evitar reprocessamento em contagens frequentes
  final Map<int, int> _wordCountCache = {};

  int _countWords(String text) {
    if (text.isEmpty) return 0;

    // Cache baseado no hash do texto (economiza mem?ria vs armazenar string completa)
    final hash = text.hashCode;
    if (_wordCountCache.containsKey(hash)) {
      return _wordCountCache[hash]!;
    }

    // Otimiza??o: trim() uma ?nica vez
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;

    // Conta palavras usando split otimizado
    final count = trimmed.split(RegExp(r'\s+')).length;

    // Limita cache a 100 entradas (previne vazamento de mem?ria)
    if (_wordCountCache.length > 100) {
      _wordCountCache.clear();
    }
    _wordCountCache[hash] = count;

    return count;
  }

  // M?todo est?tico para compatibilidade
  static void setApiTier(String tier) {
    // Implementa??o vazia para compatibilidade
  }

  // =============================================================================
  // ?? v7.6.52: WORLD STATE UPDATE - Atualiza??o de Estado via IA (Modelo ?nico)
  // =============================================================================
  // Arquitetura Pipeline de Modelo ?nico: O MESMO modelo selecionado pelo usu?rio
  // ? usado para gerar o texto E para atualizar o JSON de estado do mundo.
  // Isso garante consist?ncia de estilo e respeita a configura??o do cliente.
  // =============================================================================

  /// ?? v7.6.52: Atualiza o World State ap?s gerar um bloco
  // ?????????????????????????????????????????????????????????????????????????????
  // ??? v7.6.64: M?todos _updateWorldState e _generateCompressedSynopsis
  // movidos para WorldStateManager (lib/data/services/scripting/)
  // ===================== M?TODOS CTA E FERRAMENTAS AUXILIARES =====================

  // ?? v7.6.51: Adicionado qualityMode para Pipeline Modelo ?nico
  Future<Map<String, String>> generateCtasForScript({
    required String scriptContent,
    required String apiKey,
    required List<String> ctaTypes,
    String? customTheme,
    String language = 'Portugu?s',
    String perspective =
        'terceira_pessoa', // PERSPECTIVA CONFIGURADA PELO USU?RIO
    String qualityMode = 'pro', // ?? NOVO: Para Pipeline Modelo ?nico
  }) async {
    try {
      // Usar idioma e perspectiva configurados pelo usu?rio (n?o detectar)
      final finalLanguage = language;

      // Analisar contexto da hist?ria (Flash para tarefa simples)
      final scriptContext = await _analyzeScriptContext(
        scriptContent,
        apiKey,
        finalLanguage,
        'flash', // v7.6.62: Forcar Flash para analise simples
      );

      // ??? v7.6.66: Usar CtaGenerator para construir prompt
      final prompt = CtaGenerator.buildAdvancedCtaPrompt(
        scriptContent,
        ctaTypes,
        customTheme,
        finalLanguage,
        scriptContext,
        perspective,
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

      // ??? v7.6.66: Usar CtaGenerator para parse
      return CtaGenerator.parseCtaResponseWithValidation(
        result,
        ctaTypes,
        scriptContent,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Erro generateCtasForScript: $e');
      return {};
    }
  }

  // ?? v7.6.51: Adicionado qualityMode para Pipeline Modelo ?nico
  Future<String> _analyzeScriptContext(
    String scriptContent,
    String apiKey,
    String language,
    String qualityMode,
  ) async {
    // ??? v7.6.66: Usar CtaGenerator para construir prompt de an?lise
    final prompt = CtaGenerator.buildContextAnalysisPrompt(
      scriptContent,
      language,
    );

    try {
      final result = await generateTextWithApiKey(
        prompt: prompt,
        apiKey: apiKey,
        qualityMode: qualityMode,
        maxTokens: 100,
      );
      return result.trim();
    } catch (e) {
      return '';
    }
  }

  // ??? v7.6.66: M�todos _buildAdvancedCtaPrompt, _getCtaTypeDescriptions,
  // _parseCtaResponseWithValidation e _validateFinalCtaConsistency
  // movidos para CtaGenerator (lib/data/services/gemini/tools/)
}

// =============================================================================
// 🏗️ v7.6.72: CharacterTracker MIGRADO para tracking/character_tracker.dart
// =============================================================================
// Classes CharacterNote, CharacterHistory e CharacterTracker estão no módulo.
// Import: package:flutter_gerador/data/services/gemini/tracking/character_tracker.dart
// =============================================================================
