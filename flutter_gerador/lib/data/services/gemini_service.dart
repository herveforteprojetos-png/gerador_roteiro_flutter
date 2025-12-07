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

// ?? NOVOS M�DULOS DE PROMPTS (Refatora��o v2.0)
import 'package:flutter_gerador/data/services/prompts/main_prompt_template.dart';

// ??? v7.6.64: M�DULOS REFATORADOS (Arquitetura SOLID)
import 'package:flutter_gerador/data/services/scripting/scripting_modules.dart';

// ??? v7.6.65: M�DULOS EXTRA�DOS (Refatora��o SOLID - Fase 1)
import 'package:flutter_gerador/data/services/gemini/detection/detection_modules.dart';
// ignore: unused_import
import 'package:flutter_gerador/data/services/gemini/infra/infra_modules.dart'; // Para uso futuro

// 🏗️ v7.6.66: MÓDULOS EXTRAÍDOS (Refatoração SOLID - Fase 2)
import 'package:flutter_gerador/data/services/gemini/tools/tools_modules.dart';

// 🏗️ v7.6.67: MÓDULOS DE VALIDAÇÃO (Refatoração SOLID - Fase 5)
import 'package:flutter_gerador/data/services/gemini/validation/relationship_patterns.dart';
import 'package:flutter_gerador/data/services/gemini/validation/role_patterns.dart';

/// ?? Helper padronizado para logs (mant�m emojis em debug, limpa em produ��o)
void _log(String message, {String level = 'info'}) {
  if (kDebugMode) {
    // Debug: mant�m emojis e formata��o original
    debugPrint(message);
  } else if (level == 'error' || level == 'critical') {
    // Produ��o: apenas erros cr�ticos, sem emojis
    final cleaned = message
        .replaceAll(RegExp(r'[????????????????????]'), '')
        .trim();
    debugPrint('[${level.toUpperCase()}] $cleaned');
  }
  // Produ��o: info/warning n�o logam (evita spam)
}

/// ??? v7.6.65: FUN��ES TOP-LEVEL DELEGANDO PARA M�DULOS (Refatora��o SOLID)
/// ?? FUN��O TOP-LEVEL para filtrar par�grafos duplicados em Isolate
String _filterDuplicateParagraphsStatic(Map<String, dynamic> params) {
  return filterDuplicateParagraphsIsolate(params);
}

/// ?? FUN��O TOP-LEVEL para execu��o em Isolate separado
/// Evita travar UI thread durante verifica��o de repeti��o
Map<String, dynamic> _isTooSimilarInIsolate(Map<String, dynamic> params) {
  return isTooSimilarIsolate(params);
}

/// Implementa��o consolidada limpa do GeminiService
class GeminiService {
  final Dio _dio;
  final String _instanceId;
  bool _isCancelled = false;

  // ??? v7.6.64: M�DULOS REFATORADOS (Arquitetura SOLID)
  late final LlmClient _llmClient;
  late final WorldStateManager _worldStateManager;
  late final ScriptValidator _scriptValidator;

  // ??? v7.6.65: M�DULOS EXTRA�DOS (Refatora��o SOLID - Fase 1)
  // Nota: DuplicationDetector e TextCleaner s�o classes est�ticas
  // NameTracker e RateLimiter dispon�veis para uso futuro via imports

  // ?? v7.6.20: Adaptive Delay Manager (economia de 40-50% do tempo)
  DateTime? _lastSuccessfulCall;
  int _consecutive503Errors = 0;
  int _consecutiveSuccesses = 0;

  // Debug Logger
  final _debugLogger = DebugLogManager();

  // ?? SISTEMA DE RASTREAMENTO DE NOMES - v4 (SOLU��O T�CNICA)
  // Armazena todos os nomes usados na hist�ria atual para prevenir duplica��es
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
  // OTIMIZADO: Configura��o mais agressiva baseada nos limites reais do Gemini
  static int _globalRequestCount = 0;
  static DateTime _globalLastRequestTime = DateTime.now();
  static const Duration _rateLimitWindow = Duration(
    seconds: 60,
  ); // AUMENTADO: Era 10s, agora 60s
  static const int _maxRequestsPerWindow =
      50; // AUMENTADO: Era 8, agora 50 (mais próximo dos limites reais)
  static bool _rateLimitBusy = false;

  // Watchdog
  Timer? _watchdogTimer;
  bool _isOperationRunning = false;
  static const Duration _maxOperationTime = Duration(
    minutes: 60,
  ); // AUMENTADO: 60 min para roteiros longos (13k+ palavras = 35+ blocos)

  // ?? v7.6.51: HELPER PARA MODELO �NICO - Arquitetura Pipeline Modelo �nico
  // O modelo selecionado pelo usu�rio deve ser usado em TODAS as etapas
  // para garantir consist�ncia de estilo e respeitar a configura��o do cliente
  static String _getSelectedModel(String qualityMode) {
    return qualityMode == 'flash'
        ? 'gemini-2.5-flash' // STABLE - R�pido e eficiente
        : qualityMode == 'ultra'
        ? 'gemini-3-pro-preview' // PREVIEW - Modelo mais avan�ado (Jan 2025)
        : 'gemini-2.5-pro'; // STABLE - M�xima qualidade (default)
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
    // ??? v7.6.64: Inicializar m�dulos refatorados
    _llmClient = LlmClient(instanceId: _instanceId);
    _worldStateManager = WorldStateManager(llmClient: _llmClient);
    _scriptValidator = ScriptValidator(llmClient: _llmClient);

    // ??? v7.6.65: M�dulos DuplicationDetector e TextCleaner s�o est�ticos
    // NameTracker e RateLimiter dispon�veis via imports para uso futuro

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

  // ===================== API PÚBLICA =====================
  Future<ScriptResult> generateScript(
    ScriptConfig config,
    void Function(GenerationProgress) onProgress,
  ) async {
    // ?? v7.6.19: RESPEITAR SELE��O DO USU�RIO - N�o usar fallback autom�tico
    // Se selecionou Gemini ? usar APENAS Gemini
    // Se selecionou OpenAI ? usar APENAS OpenAI (implementar no futuro)
    // _useOpenAIFallback = false; // ? REMOVIDO - OpenAI descontinuado

    if (kDebugMode) {
      debugPrint(
        '[$_instanceId] ?? Provider selecionado: ${config.selectedProvider}',
      );
      debugPrint(
        '[$_instanceId] ?? Fallback autom�tico: DESABILITADO (usar apenas API selecionada)',
      );
    }

    // ?? CORRE��O CR�TICA: Resetar vari�veis globais ANTES de verificar rate limit
    // Isso garante que cada nova gera��o comece do zero
    _resetGlobalRateLimit();

    // ?? v4: Resetar rastreador de nomes para nova hist�ria
    _resetNameTracker();

    // ?? v7.6.37: Resetar personagens introduzidos para detec��o de duplicatas
    PostGenerationFixer.resetIntroducedCharacters();

    if (!_canMakeRequest()) {
      return ScriptResult.error(
        errorMessage:
            'Serviço temporariamente indisponível. Tente mais tarde.',
      );
    }

    // CORREÇÃO: Reset completo do estado para nova geração
    resetState();

    // Tracker global alimentado com os nomes definidos pelo usuário/contexto
    final persistentTracker = _CharacterTracker();
    _bootstrapCharacterTracker(persistentTracker, config);

    // ??? v7.6.64: WORLD STATE - Agora usa WorldState do m�dulo (SOLID)
    // Rastreia personagens, invent�rio, fatos e resumo da hist�ria
    // Usa o MESMO modelo selecionado pelo usu�rio (Pipeline Modelo �nico)
    final worldState = WorldState();

    // ??? v7.6.64: Reset e inicializa��o do WorldStateManager (SOLID)
    _worldStateManager.reset();
    _worldStateManager.initializeProtagonist(config.protagonistName);

    // Inicializar protagonista no World State usando classe do m�dulo
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

    // ?? v7.6.53: CAMADA 1 - Gerar Sinopse Comprimida UMA VEZ no in�cio
    // Usa o MESMO modelo selecionado pelo usu�rio (Pipeline Modelo �nico)
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
        debugPrint('?? Erro ao gerar sinopse (n�o-cr�tico): $e');
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
    // Gera uma frase de impacto antes de come�ar a escrever a hist�ria
    // CONDI��O: S� gera se startWithTitlePhrase = false (usu�rio n�o quer come�ar com t�tulo)
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
          model: LlmClient.modelFlash, // Usa modelo r�pido e barato
          maxTokens: 150,
        );

        // Limpeza b�sica
        viralHook = viralHook.replaceAll('"', '').trim();

        if (kDebugMode && viralHook.isNotEmpty) {
          debugPrint('?? Hook Gerado: "$viralHook"');
        }
      } catch (e) {
        // Se o hook falhar, n�o trava o roteiro. Apenas segue sem hook.
        if (kDebugMode) {
          debugPrint('?? Erro n�o-cr�tico no Hook (ignorando): $e');
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
        // ?? YIELD CR�TICO: Liberar UI thread completamente antes de cada bloco
        // Aumentado de 5ms ? 100ms para garantir anima��es suaves
        await Future.delayed(const Duration(milliseconds: 100));

        // ?? DEBUG: Log in�cio de bloco
        _debugLogger.block(
          block,
          "Iniciando gera��o",
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

        // ?? OTIMIZA��O CR�TICA: Reduzir frequ�ncia de onProgress ap�s 50%
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

          // ?? YIELD OTIMIZADO: 50ms para UI respirar sem bloquear gera��o
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
              debugPrint('   ? API r�pida detectada - usando delay m�nimo');
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

        // ?? v7.6.35: CORRE��O P�S-GERA��O - Corrigir nomes trocados automaticamente
        // Executa ANTES de qualquer valida��o para garantir consist�ncia
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

        // ?? YIELD P�S-API: M�nimo delay para UI
        await Future.delayed(const Duration(milliseconds: 10));

        // ?? RETRY PARA BLOCOS VAZIOS: Se bloco retornou vazio, tentar novamente at� 6 vezes
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
            // Primeiros 3 retries: r�pido (5s, 10s, 15s)
            // �ltimos 3 retries: moderado (20s, 30s, 40s) para dar tempo ao servidor
            final retryDelay = retry <= 3 ? 5 * retry : 15 + (retry - 3) * 10;
            if (kDebugMode) {
              debugPrint(
                '?? Aguardando ${retryDelay}s antes do retry (${retry <= 3 ? "r�pido" : "moderado"})...',
              );
            }
            await Future.delayed(Duration(seconds: retryDelay));

            // ?? AUMENTADO: Contexto de 3000 para 8000 chars para manter nomes em mem�ria
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

          // ?? CORRE��O CR�TICA: Se ap�s 6 tentativas ainda estiver vazio, ABORTAR gera��o
          if (added.trim().isEmpty) {
            _log(
              '? ERRO CR�TICO: Bloco $block permaneceu vazio ap�s 6 retries!',
              level: 'critical',
            );
            _log(
              '?? ABORTANDO GERA��O: Servidor Gemini pode estar sobrecarregado.',
              level: 'critical',
            );
            _log(
              '?? SOLU��O: Aguarde 10-15 minutos e tente novamente, ou use OpenAI GPT-4o.',
              level: 'critical',
            );

            // ?? RETORNAR ERRO em vez de continuar
            return ScriptResult.error(
              errorMessage:
                  '?? ERRO: Bloco $block falhou ap�s 6 tentativas (total ~2min de espera).\n\n'
                  'O servidor Gemini est� temporariamente sobrecarregado.\n'
                  'Aguarde 10-15 minutos e tente novamente, ou:\n'
                  '� Troque para OpenAI GPT-4o nas configura��es\n'
                  '� Tente em hor�rio de menor tr�fego\n\n'
                  'Progresso salvo: ${_countWords(acc)} palavras (bloco $block de $totalBlocks).',
            );
          }
        }

        // ?? YIELD: Liberar UI thread antes de valida��o pesada
        await Future.delayed(const Duration(milliseconds: 10));

        // ? VALIDA��O ANTI-REPETI��O EM ISOLATE: Verificar sem travar UI
        if (added.trim().isNotEmpty && acc.length > 500) {
          // Executar em isolate separado para n�o bloquear UI thread
          final result = await compute(_isTooSimilarInIsolate, {
            'newBlock': added,
            'previousContent': acc,
            'threshold':
                0.80, // ?? AJUSTADO: Era 0.85, agora 0.80 para maior sensibilidade
          });

          final isSimilar = result['isSimilar'] as bool;

          if (isSimilar) {
            // ?? DEBUG: Log repeti��o detectada
            _debugLogger.warning(
              "Repeti��o detectada no bloco $block",
              details: result['reason'] as String,
              metadata: {
                'bloco': block,
                'tamanho': _countWords(added),
                'threshold': 0.80,
              },
            );

            if (kDebugMode) {
              debugPrint(
                '? BLOCO $block REJEITADO: Muito similar ao conte�do anterior!',
              );
              debugPrint(
                '   ?? Tamanho do bloco: ${_countWords(added)} palavras',
              );
              debugPrint('   ?? Motivo: ${result['reason']}');
              debugPrint(
                '   ?? Regenerando com aviso expl�cito contra repeti��o...',
              );
            }

            // ?? TENTATIVA 1: Regenerar com prompt espec�fico contra repeti��o
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
                  '?? TENTATIVA 1 FALHOU: Ainda h� similaridade alta!',
                );
                debugPrint(
                  '   ?? TENTATIVA 2: Regenerando novamente com contexto reduzido...',
                );
              }

              // ?? AUMENTADO: Contexto de 3000 para 8000 chars para manter nomes em mem�ria
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
                    '   ?? DECIS�O: Usando vers�o menos similar (tentativa 1)',
                  );
                }
                acc +=
                    regenerated; // Usar primeira tentativa (menos similar que original)
              } else {
                if (kDebugMode) {
                  debugPrint('? TENTATIVA 2 BEM-SUCEDIDA: Bloco �nico gerado!');
                }
                acc += regenerated2;
              }
            } else {
              if (kDebugMode) {
                debugPrint('? REGENERA��O BEM-SUCEDIDA: Bloco agora � �nico!');
              }
              acc += regenerated;
            }
          } else {
            // ? Bloco passou na valida��o anti-repeti��o
            acc += added; // Usar vers�o original
          }
        } else {
          // ? Primeiro bloco ou contexto pequeno - adicionar direto
          acc += added;
        }

        // ?? INSERIR HOOK VIRAL no in�cio do Bloco 1 (se dispon�vel)
        if (block == 1 && viralHook.isNotEmpty && added.trim().isNotEmpty) {
          // Remove o added que acabou de ser adicionado
          acc = acc.substring(0, acc.length - added.length);
          // Adiciona com o hook no topo
          acc += '?? GANCHO VIRAL:\n$viralHook\n\n$added';
          if (kDebugMode) {
            debugPrint('?? Hook Viral inserido no in�cio do roteiro!');
          }
        }

        if (added.trim().isNotEmpty) {
          // ?? VALIDA��O CR�TICA 1: Detectar e registrar protagonista no Bloco 1
          if (block == 1) {
            _detectAndRegisterProtagonist(added, config, persistentTracker);
          }

          // ?? VALIDA��O CR�TICA 2: Verificar se protagonista mudou de nome
          final protagonistChanged = _detectProtagonistNameChange(
            added,
            config,
            persistentTracker,
            block,
          );

          // ?? VALIDA��O CR�TICA 3: Verificar se algum nome foi reutilizado
          _validateNameReuse(added, persistentTracker, block);

          // ?? VALIDA��O CR�TICA 4: REJEITAR BLOCO se protagonista mudou ou personagens trocaram de nome
          final characterNameChanges = _detectCharacterNameChanges(
            added,
            persistentTracker,
            block,
          );
          if (protagonistChanged || characterNameChanges.isNotEmpty) {
            if (kDebugMode) {
              debugPrint(
                '?????? BLOCO $block REJEITADO - MUDAN�A DE NOME DETECTADA! ??????',
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

            // ?? v7.6.17: LIMITE DE REGENERA��ES para evitar loop infinito
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
                  debugPrint('   ? Regenera��o $regenAttempt retornou vazia!');
                }
                continue; // Tentar novamente
              }

              // Validar se regenera��o corrigiu o problema
              final stillChanged = _detectProtagonistNameChange(
                regenerated,
                config,
                persistentTracker,
                block,
              );

              if (!stillChanged) {
                if (kDebugMode) {
                  debugPrint('   ? Regenera��o $regenAttempt bem-sucedida!');
                }
                break; // Sucesso! Sair do loop
              } else {
                if (kDebugMode) {
                  debugPrint(
                    '   ?? Regenera��o $regenAttempt ainda tem erro de nome!',
                  );
                }
                if (regenAttempt == maxRegenerations) {
                  if (kDebugMode) {
                    debugPrint(
                      '   ? Limite de regenera��es atingido! Aceitando bloco...',
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
              // Manter bloco original se todas regenera��es falharam
            }
          }

          // ?? v7.6.17: VALIDA��O UNIVERSAL DE TODOS OS NOMES (prim�rios + secund�rios)
          final allNamesInBlock = _extractNamesFromText(
            added,
          ).where((n) => _looksLikePersonName(n)).toList();

          // Detectar nomes novos n�o registrados no tracker
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

          // ?? v4: EXTRA��O E RASTREAMENTO DE NOMES
          final duplicatedNames = _validateNamesInText(
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
                '   ?? Isso pode indicar personagens com mesmo nome em pap�is diferentes!',
              );
            }
            _debugLogger.warning(
              "Poss�vel duplica��o de nomes no bloco $block",
              details: "Nomes: ${duplicatedNames.join(", ")}",
              metadata: {'bloco': block, 'nomes': duplicatedNames},
            );
          }
          _addNamesToTracker(added);

          // ?? VALIDA��O CR�TICA 4: Verificar inconsist�ncias em rela��es familiares
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

          // ?? v7.6.28: VALIDA��O DE NOMES DUPLICADOS (antes da v7.6.25)
          // OBJETIVO: Detectar quando MESMO NOME aparece em PAP�IS DIFERENTES
          // EXEMPLO: "Mark" como boyfriend + "Mark" como attorney
          final duplicateNameConflict = _validateUniqueNames(
            added,
            persistentTracker,
            block,
          );

          if (duplicateNameConflict) {
            // ? BLOCO REJEITADO: Nome duplicado em pap�is diferentes
            if (kDebugMode) {
              debugPrint(
                '? v7.6.28: BLOCO $block REJEITADO por NOME DUPLICADO!',
              );
              debugPrint(
                '   ?? EXEMPLO: "Mark" aparece como boyfriend E attorney (nomes devem ser �nicos)',
              );
              debugPrint('   ?? For�ando regenera��o do bloco...');
            }

            _debugLogger.warning(
              "Bloco $block rejeitado por nome duplicado",
              details: "Mesmo nome usado para personagens diferentes",
              metadata: {'bloco': block},
            );

            // ?? For�ar regenera��o: bloco vazio = retry autom�tico
            added = '';
          } else {
            // ? v7.6.28: Nomes �nicos, prosseguir para valida��o de pap�is

            // ?? v7.6.25: VALIDA��O DE CONFLITOS DE PAPEL
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
                debugPrint('   ?? For�ando regenera��o do bloco...');
              }

              _debugLogger.warning(
                "Bloco $block rejeitado por conflito de papel",
                details: "Um personagem mudou de nome no mesmo papel",
                metadata: {'bloco': block},
              );

              // ?? For�ar regenera��o: bloco vazio = retry autom�tico
              added = '';
            } else {
              // ? v7.6.25: Tracker v�lido, atualizar mapeamento j� foi feito
              if (kDebugMode) {
                debugPrint(
                  '? v7.6.28 + v7.6.25: Bloco $block ACEITO (nomes �nicos + sem conflitos de papel)',
                );
              }

              // ?? v7.6.52: ATUALIZAR WORLD STATE - Pipeline Modelo �nico
              // O MESMO modelo selecionado pelo usu�rio atualiza o JSON de estado
              // Isso garante consist�ncia e respeita a config do cliente
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

        // OTIMIZADO: Checkpoint de estabilidade ultra-r�pido
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

          // ?? RETRY AUTOM�TICO: Tentar novamente at� 3x quando bloco vazio
          // AUMENTADO: Era 2, agora 3 retries para dar mais chance de sucesso
          int retryCount = 0;
          const maxRetries = 3;

          while (retryCount < maxRetries && added.trim().isEmpty) {
            retryCount++;
            if (kDebugMode) {
              debugPrint(
                '[$_instanceId] ?? Retry autom�tico $retryCount/$maxRetries para bloco $block',
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
                  added = ''; // For�ar nova tentativa
                  continue; // Tentar pr�ximo retry
                }

                // ?? v7.6.25: VALIDAR conflitos de papel DEPOIS
                final retryTrackerValid = _updateTrackerFromContextSnippet(
                  persistentTracker,
                  config,
                  added,
                );

                if (!retryTrackerValid) {
                  // ? Bloco regenerado tamb�m tem conflito de papel
                  if (kDebugMode) {
                    debugPrint(
                      '[$_instanceId] ? v7.6.25: Retry $retryCount REJEITADO (conflito de papel)',
                    );
                  }
                  added = ''; // For�ar nova tentativa
                  continue; // Tentar pr�ximo retry
                }

                if (kDebugMode) {
                  debugPrint(
                    '[$_instanceId] ? v7.6.28 + v7.6.25: Retry v�lido! Bloco $block aceito.',
                  );
                }
                break; // Sucesso, sair do loop de retry
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                  '[$_instanceId] ? Retry autom�tico $retryCount falhou: $e',
                );
              }
            }
          }

          // ?? CORRE��O CR�TICA: Se ainda vazio ap�s retries, ABORTAR em vez de continuar
          if (added.trim().isEmpty) {
            if (kDebugMode) {
              debugPrint(
                '[$_instanceId] ? ERRO CR�TICO: Bloco $block falhou ap�s $maxRetries retries - ABORTANDO',
              );
            }

            return ScriptResult.error(
              errorMessage:
                  '?? ERRO CR�TICO: Bloco $block permaneceu vazio ap�s 6 tentativas.\n\n'
                  'O servidor Gemini est� temporariamente sobrecarregado.\n'
                  'Aguarde 10-15 minutos e tente novamente, ou troque para OpenAI.\n\n'
                  'Progresso salvo: ${_countWords(acc)} palavras de ${config.quantity} (bloco $block de $totalBlocks).',
            );
          }
        }

        // Limpeza de memória otimizada
        if (kDebugMode) {
          debugPrint(
            '[$_instanceId] Checkpoint bloco $block - Limpeza memória',
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

      // 🚫 EXPANSÃO FORÇADA DESATIVADA
      // Sistema de expansão removido para evitar múltiplos finais empilhados.
      // A meta de caracteres deve ser atingida através do ajuste dos blocos iniciais,
      // não forçando continuações após a história já ter concluído naturalmente.
      // Isso preserva a qualidade narrativa e evita finais duplicados.

      if (!_isCancelled && !_checkTargetMet(acc, config)) {
        final needed = config.measureType == 'caracteres'
            ? (config.quantity - acc.length)
            : (config.quantity - _countWords(acc));

        if (kDebugMode) {
          debugPrint(
            '[$_instanceId] ⚠️ Meta não atingida - Faltam $needed ${config.measureType}',
          );
          debugPrint(
            '[$_instanceId] � DICA: Aumente o tamanho dos blocos iniciais para atingir a meta',
          );
        }
      }

      if (_isCancelled) {
        return ScriptResult.error(errorMessage: 'Gera��o cancelada');
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

      // ?? v7.6.43: REMOVER PAR�GRAFOS DUPLICADOS DO ROTEIRO FINAL
      var deduplicatedScript = _removeAllDuplicateParagraphs(cleanedAcc);

      // ?? DETEC��O FINAL: Verificar se h� par�grafos duplicados restantes (apenas LOG)
      if (kDebugMode) {
        _detectDuplicateParagraphsInFinalScript(deduplicatedScript);
      }

      // ?? v7.6.45: VALIDA��O RIGOROSA DE COER�NCIA COM T�TULO
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
          '?? Valida��o de coer�ncia t�tulo-hist�ria',
          details:
              '''
T�tulo: "${config.title}"
Resultado: ${isCoherent ? '? COERENTE' : '? INCOERENTE'}
Confian�a: $confidence%

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

        // ?? FALLBACK: Se incoerente E confian�a baixa, tentar regenerar �LTIMO bloco
        if (!isCoherent && confidence < 50 && missingElements.isNotEmpty) {
          _debugLogger.warning(
            '?? Tentando regenera��o com �nfase nos elementos faltantes',
            details:
                'Elementos cr�ticos ausentes: ${missingElements.take(3).join(", ")}',
          );

          try {
            // Extrair �ltimos 2 blocos para contexto
            final blocks = deduplicatedScript.split('\n\n');
            final contextBlocks = blocks.length > 2
                ? blocks.sublist(blocks.length - 2)
                : blocks;
            final context = contextBlocks.join('\n\n');

            // ??? v7.6.64: Usar ScriptPromptBuilder para criar prompt de recupera��o (SOLID)
            final recoveryPrompt = ScriptPromptBuilder.buildRecoveryPrompt(
              config.title,
              missingElements,
              context,
              config.language,
            );

            // ??? v7.6.64: Usar LlmClient para gerar bloco de recupera��o (SOLID)
            // ?? v7.6.51: Arquitetura Modelo �nico - usar config.qualityMode
            final recoveryResponse = await _llmClient.generateText(
              apiKey: config.apiKey,
              model: _getSelectedModel(config.qualityMode),
              prompt: recoveryPrompt,
              maxTokens: 500, // Bloco pequeno de recupera��o
            );

            if (recoveryResponse.isNotEmpty) {
              // Adicionar bloco de recupera��o ao final
              deduplicatedScript = '$deduplicatedScript\n\n$recoveryResponse';
              _debugLogger.success(
                '? Bloco de recupera��o adicionado',
                details: 'Novos elementos incorporados � hist�ria',
              );
            }
          } catch (e) {
            _debugLogger.warning(
              '?? Falha na regenera��o',
              details: 'Mantendo hist�ria original: $e',
            );
          }
        }
      }

      // ?? DEBUG: Log estat�sticas finais
      final stats = _debugLogger.getStatistics();
      _debugLogger.success(
        "Gera��o completa!",
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
        return ScriptResult.error(errorMessage: 'Gera��o cancelada');
      }
      return ScriptResult.error(errorMessage: 'Erro: $e');
    }
  }

  void cancelGeneration() {
    if (kDebugMode) debugPrint('[$_instanceId] Cancelando geração...');
    _isCancelled = true;
    _stopWatchdog();

    // CORRE��O: N�o fechar o Dio aqui, pois pode ser reutilizado
    // Apenas marcar como cancelado e limpar estado se necess�rio
    if (kDebugMode) {
      debugPrint('[$_instanceId] Gera��o cancelada pelo usu�rio');
    }
  }

  /// ?? Configura OpenAI como fallback para erro 503 (DESCONTINUADO)
  void setOpenAIKey(String? apiKey) {
    // REMOVIDO - OpenAI n�o � mais usado
    if (kDebugMode) {
      debugPrint('[$_instanceId] OpenAI fallback descontinuado');
    }
  }

  // M�todo para limpar recursos quando o service n�o for mais usado
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

  // CORREÇÃO: Método para resetar completamente o estado interno
  void resetState() {
    if (kDebugMode) debugPrint('[$_instanceId] Resetando estado interno...');
    _isCancelled = false;
    _isOperationRunning = false;
    _failureCount = 0;
    _isCircuitOpen = false;
    _lastFailureTime = null;
    _stopWatchdog();

    // ?? NOVO: Resetar vari�veis static tamb�m (rate limiting global)
    _resetGlobalRateLimit();

    if (kDebugMode) {
      debugPrint(
        '[$_instanceId] ? Estado completamente resetado (incluindo rate limit global)',
      );
    }
  }

  // ?? NOVO: M�todo para resetar rate limiting global entre gera��es
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
      if (kDebugMode) debugPrint('Erro na geração de texto: $e');
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
            '[$_instanceId] Watchdog timeout - cancelando operação após ${_maxOperationTime.inMinutes} min',
          );
        }
        _isCancelled = true;
      }
    });
  }

  /// ?? v7.6.41: Resetar watchdog a cada bloco bem-sucedido
  /// Evita timeout em roteiros longos quando a gera��o est� funcionando
  void _resetWatchdog() {
    if (_isOperationRunning && !_isCancelled) {
      _startWatchdog(); // Reinicia o timer
      if (kDebugMode) {
        debugPrint('[$_instanceId] Watchdog resetado - opera��o ativa');
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
    // CRÍTICO: Rate limiting global para múltiplas instâncias/workspaces
    // Tentativa com timeout para evitar deadlocks
    int attempts = 0;
    const maxAttempts = 100; // 5 segundos máximo de espera

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

      // Se atingiu limite, aguarda até o fim da janela
      if (_globalRequestCount >= _maxRequestsPerWindow) {
        final wait = _rateLimitWindow - diff;
        if (wait > Duration.zero && wait < Duration(seconds: 30)) {
          // Máximo 30s de espera
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
  /// Reduz tempo de gera��o em 40-50% quando API est� r�pida
  Duration _getAdaptiveDelay({required int blockNumber}) {
    // ?? v7.6.46: DELAYS ULTRA-OTIMIZADOS para velocidade m�xima
    // Se �ltima chamada foi sucesso R�PIDO (< 3s atr�s), delay m�nimo
    if (_lastSuccessfulCall != null &&
        DateTime.now().difference(_lastSuccessfulCall!) <
            Duration(seconds: 3)) {
      _consecutiveSuccesses++;

      // Ap�s 2 sucessos r�pidos consecutivos, usar delays m�nimos
      if (_consecutiveSuccesses >= 2) {
        // API est� r�pida - usar delays m�nimos (0.3-0.8s)
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

    // Padr�o: delays M�NIMOS (0.5s-2s em vez de 3s-6s)
    _consecutiveSuccesses = 0;
    _consecutive503Errors = max(0, _consecutive503Errors - 1); // Decay gradual

    if (blockNumber <= 5) return Duration(milliseconds: 500); // 0.5s
    if (blockNumber <= 15) return Duration(milliseconds: 1000); // 1s
    if (blockNumber <= 25) return Duration(milliseconds: 1500); // 1.5s
    return Duration(seconds: 2); // 2s m�ximo
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
    // ?? AUMENTADO: Era 4, agora 6 para erro 503 (servidor indispon�vel)
    // RATIONALE: Erro 503 � transit�rio, servidor pode voltar em 30-60s
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (_isCancelled) {
          throw Exception('Operação cancelada');
        }

        await _ensureRateLimit();

        if (_isCancelled) {
          throw Exception('Operação cancelada');
        }

        return await op();
      } catch (e) {
        if (_isCancelled) {
          throw Exception('Operação cancelada');
        }

        final errorStr = e.toString().toLowerCase();

        // ?? CORRE��O CR�TICA: Tratar erro 503 (servidor indispon�vel) especificamente
        // Erro 503 = "Service Unavailable" (transit�rio, n�o � rate limit)
        if (errorStr.contains('503') ||
            errorStr.contains('server error') ||
            errorStr.contains('service unavailable')) {
          // ?? v7.6.20: Registrar erro 503 para Adaptive Delay Manager
          _recordApi503Error();

          // ?? v7.6.19: Fallback OpenAI REMOVIDO - respeitar sele��o do usu�rio
          // Se usu�rio escolheu Gemini, usar APENAS Gemini (mesmo com erros 503)
          // Se usu�rio escolheu OpenAI, implementar chamada direta do OpenAI (futuro)

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
                '[$_instanceId] ?? ERRO 503 (Servidor Indispon�vel) - Aguardando ${delay.inSeconds}s antes de retry ${attempt + 2}/$maxRetries',
              );
              debugPrint(
                '[$_instanceId] ?? Backoff otimizado: 10s ? 20s ? 40s ? 60s ? 90s',
              );
            }
            await Future.delayed(delay);
            continue;
          } else {
            // ?? AP�S 6 TENTATIVAS, desistir com mensagem clara
            final totalWaitTime = (10 + 20 + 40 + 60 + 90); // Total: ~3.7 min
            throw Exception(
              '?? ERRO CR�TICO: Servidor do Gemini permanece indispon�vel ap�s $maxRetries tentativas (~${(totalWaitTime / 60).toStringAsFixed(1)} min de espera total).\n'
              '\n'
              '?? SOLU��ES POSS�VEIS:\n'
              '  1?? Aguarde 5-10 minutos e tente novamente\n'
              '  2?? Troque para OpenAI GPT-4o nas configura��es\n'
              '  3?? Tente novamente em hor�rio de menor tr�fego\n'
              '\n'
              '?? Seu progresso foi salvo e pode ser continuado.',
            );
          }
        }

        // ?? CORRE��O: Diferentes delays para diferentes tipos de erro
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

        // ? Timeout/Connection = Retry muito r�pido (1s por tentativa)
        if ((errorStr.contains('timeout') || errorStr.contains('connection')) &&
            attempt < maxRetries - 1) {
          final delay = Duration(seconds: attempt + 1); // OTIMIZADO: era * 2
          if (kDebugMode) {
            debugPrint(
              '[$_instanceId] ? Retry r�pido (timeout/connection) - ${delay.inSeconds}s (tentativa ${attempt + 1}/$maxRetries)',
            );
          }
          await Future.delayed(delay);
          continue;
        }

        if (kDebugMode) {
          debugPrint(
            '[$_instanceId] Erro final após $maxRetries tentativas: $e',
          );
        }
        rethrow;
      }
    }
    throw Exception(
      'Limite de tentativas excedido após $maxRetries tentativas',
    );
  }

  // ===================== Narrativa =====================
  final List<String> _phases = const [
    'Prepara��o',
    'Introdu��o',
    'Desenvolvimento',
    'Cl�max',
    'Resolu��o',
    'Finaliza��o',
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
    // OTIMIZADO: Delays m�nimos para maximizar velocidade (sem afetar qualidade)
    if (p <= 0.15) return 50; // Reduzido de 100ms para 50ms
    if (p <= 0.30) return 75; // Reduzido de 150ms para 75ms
    if (p <= 0.65) return 100; // Reduzido de 200ms para 100ms
    if (p <= 0.80) return 125; // Reduzido de 250ms para 125ms
    if (p <= 0.95) return 75; // Reduzido de 150ms para 75ms
    return 50; // Reduzido de 100ms para 50ms
  }

  bool _checkTargetMet(String text, ScriptConfig c) {
    if (c.measureType == 'caracteres') {
      // TOLERÂNCIA ZERO: Só aceita se atingir pelo menos 99.5% da meta
      final tol = max(
        50,
        (c.quantity * 0.005).round(),
      ); // Máximo 0.5% ou 50 chars, o que for maior
      return text.length >= (c.quantity - tol);
    }
    final wc = _countWords(text);
    // TOLERÂNCIA ZERO: Só aceita se atingir pelo menos 99% da meta
    final tol = max(
      10,
      (c.quantity * 0.01).round(),
    ); // Máximo 1% ou 10 palavras, o que for maior
    return wc >= (c.quantity - tol);
  }

  int _calculateTotalBlocks(ScriptConfig c) {
    // ?? NORMALIZA��O: Converter tudo para palavras equivalentes
    // Isso garante que quantidades equivalentes de conte�do recebam blocos similares
    // ?? IMPORTANTE: N�O aplicar multiplicador de idioma aqui!
    //    O multiplicador � aplicado por bloco, n�o no total de blocos.
    //    Caso contr�rio, ingl�s (1.05x) geraria blocos extras desnecess�rios.

    // ???? AJUSTE ESPECIAL PARA COREANO: Densidade de caracteres menor
    // Hangul: 1 caractere = 1 s�laba completa ? menos chars por palavra
    // F�rmula coreano: 4.2 chars/palavra (vs ingl�s/PT: 5.5)
    final isKoreanMeasure =
        c.language.contains('???') ||
        c.language.toLowerCase().contains('coreano') ||
        c.language.toLowerCase().contains('korean');

    final charToWordRatio = (c.measureType == 'caracteres' && isKoreanMeasure)
        ? 4.2 // Coreano: alta densidade sil�bica
        : 5.5; // Outros idiomas: padr�o

    int wordsEquivalent = c.measureType == 'caracteres'
        ? (c.quantity / charToWordRatio)
              .round() // Convers�o: chars ? palavras
        : c.quantity;

    if (kDebugMode) {
      debugPrint('?? C�LCULO DE BLOCOS (DEBUG):');
      debugPrint('   Idioma: "${c.language}"');
      debugPrint('   IsKoreanMeasure? $isKoreanMeasure');
      debugPrint('   Ratio: $charToWordRatio');
      debugPrint('   WordsEquivalent: $wordsEquivalent');
    }

    // ?? AJUSTE AUTOM�TICO PARA IDIOMAS COM ALFABETOS PESADOS
    // IMPORTANTE: Este ajuste s� deve ser aplicado para medida em CARACTERES!
    // Para medida em PALAVRAS, n�o aplicar redu��o (o multiplicador 1.20 j� compensa)
    // Diferentes alfabetos ocupam diferentes quantidades de bytes em UTF-8
    // Ajustamos palavras equivalentes para evitar timeout de contexto em roteiros longos

    // ?? N�VEL 2: Cir�lico e Alfabetos Pesados - 2-3 bytes/char ? Redu��o de 12%
    final cyrillicLanguages = [
      'Russo', 'B�lgaro', 'S�rvio', // Cir�lico
    ];

    // ?? N�VEL 2B: Outros N�o-Latinos - 2-3 bytes/char ? Redu��o de 15%
    // ATEN��O: Coreano FOI REMOVIDO desta lista (usa estrat�gia de blocos m�ltiplos)
    final otherNonLatinLanguages = [
      'Hebraico', 'Grego', 'Tailand�s', // Sem�ticos e outros
    ];

    // ?? N�VEL 1: Latinos com Diacr�ticos Pesados - 1.2-1.5 bytes/char ? Redu��o de 8%
    final heavyDiacriticLanguages = [
      'Turco',
      'Polon�s',
      'Tcheco',
      'Vietnamita',
      'H�ngaro',
    ];

    // ?? CORRE��O: Aplicar ajuste SOMENTE para 'caracteres', nunca para 'palavras'
    // Motivo: O problema de timeout s� ocorre com caracteres (tokens UTF-8)
    // Para palavras, o multiplicador 1.20 j� � suficiente para compensar varia��o
    if (c.measureType == 'caracteres' && wordsEquivalent > 6000) {
      double adjustmentFactor = 1.0;
      String adjustmentLevel = '';

      if (cyrillicLanguages.contains(c.language)) {
        adjustmentFactor = 0.88; // -12% (AJUSTADO: era -20%)
        adjustmentLevel = 'CIR�LICO';
      } else if (otherNonLatinLanguages.contains(c.language)) {
        adjustmentFactor = 0.85; // -15%
        adjustmentLevel = 'N�O-LATINO';
      } else if (heavyDiacriticLanguages.contains(c.language)) {
        adjustmentFactor = 0.92; // -8% (AJUSTADO: era -10%)
        adjustmentLevel = 'DIACR�TICOS';
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
    // ?? v7.6.53: CHUNKING OTIMIZADO POR IDIOMA - Pipeline de Modelo �nico
    // ?????????????????????????????????????????????????????????????????????????????
    //
    // ESPECIFICA��O DE PALAVRAS POR BLOCO (pal/bloco):
    //   ???? PORTUGU�S:     1.200 - 1.500 pal/bloco (verboso, latino)
    //   ???? COREANO:       600 - 800 pal/bloco (Hangul, alta densidade)
    //   ???????? CIR�LICOS:  900 - 1.100 pal/bloco (tokens pesados)
    //   ???? TURCO:         1.000 - 1.200 pal/bloco (aglutinante)
    //   ???? POLON�S:       1.000 - 1.200 pal/bloco (diacr�ticos)
    //   ???? ALEM�O:        1.000 - 1.200 pal/bloco (palavras compostas)
    //   ?? LATINOS:        1.200 - 1.500 pal/bloco (EN, ES, FR, IT, RO)
    //
    // F�RMULA: blocos = wordsEquivalent / target_pal_bloco
    // ?????????????????????????????????????????????????????????????????????????????

    final langLower = c.language.toLowerCase();

    // ?? DETEC��O DE IDIOMA
    final isPortuguese = langLower.contains('portugu') || langLower == 'pt';
    final isKorean =
        c.language.contains('???') ||
        langLower.contains('coreano') ||
        langLower.contains('korean') ||
        langLower == 'ko';
    final isRussian = langLower.contains('russo') || langLower == 'ru';
    final isBulgarian =
        langLower.contains('b�lgar') ||
        langLower.contains('bulgar') ||
        langLower == 'bg';
    final isCyrillic = isRussian || isBulgarian;
    final isTurkish = langLower.contains('turco') || langLower == 'tr';
    final isPolish = langLower.contains('polon') || langLower == 'pl';
    final isGerman = langLower.contains('alem') || langLower == 'de';
    // Latinos: en, es-mx, fr, it, ro (usam valores similares ao portugu�s)
    final isLatin =
        langLower.contains('ingl�s') ||
        langLower.contains('english') ||
        langLower == 'en' ||
        langLower.contains('espanhol') ||
        langLower.contains('espa�ol') ||
        langLower.contains('es') ||
        langLower.contains('franc�s') ||
        langLower.contains('fran�ais') ||
        langLower == 'fr' ||
        langLower.contains('italiano') ||
        langLower == 'it' ||
        langLower.contains('romeno') ||
        langLower.contains('rom�n') ||
        langLower == 'ro';

    // ?? TARGET DE PALAVRAS POR BLOCO (centro do range)
    int targetPalBloco;
    String langCategory;

    if (isKorean) {
      targetPalBloco = 700; // 600-800 pal/bloco
      langCategory = '???? COREANO';
    } else if (isCyrillic) {
      targetPalBloco = 1000; // 900-1100 pal/bloco
      langCategory = '?? CIR�LICO';
    } else if (isTurkish) {
      targetPalBloco = 1100; // 1000-1200 pal/bloco
      langCategory = '???? TURCO';
    } else if (isPolish) {
      targetPalBloco = 1100; // 1000-1200 pal/bloco
      langCategory = '???? POLON�S';
    } else if (isGerman) {
      targetPalBloco = 1100; // 1000-1200 pal/bloco
      langCategory = '???? ALEM�O';
    } else if (isPortuguese) {
      targetPalBloco = 1350; // 1200-1500 pal/bloco
      langCategory = '???? PORTUGU�S';
    } else if (isLatin) {
      targetPalBloco = 1350; // 1200-1500 pal/bloco
      langCategory = '?? LATINO';
    } else {
      // Fallback para idiomas n�o especificados
      targetPalBloco = 1200;
      langCategory = '?? OUTROS';
    }

    // ?? C�LCULO DE BLOCOS: words / target
    int calculatedBlocks = (wordsEquivalent / targetPalBloco).ceil();

    // ?? LIMITES DE SEGURAN�A
    // M�nimo: 2 blocos (intro + conclus�o)
    // M�ximo: varia por idioma para evitar erro 503
    int minBlocks = 2;
    int maxBlocks;

    if (isKorean) {
      maxBlocks = 50; // Coreano precisa de mais blocos menores
    } else if (isCyrillic) {
      maxBlocks = 30; // Cir�licos s�o mais pesados
    } else {
      maxBlocks = 25; // Latinos e outros s�o eficientes
    }

    // Aplicar limites
    int finalBlocks = calculatedBlocks.clamp(minBlocks, maxBlocks);

    // ???? COMPENSA��O COREANO: +18% blocos para compensar sub-gera��o natural
    if (isKorean) {
      finalBlocks = (finalBlocks * 1.18).ceil().clamp(minBlocks, maxBlocks);
    }

    if (kDebugMode) {
      final actualPalBloco = (wordsEquivalent / finalBlocks).round();
      debugPrint(
        '   $langCategory: $wordsEquivalent palavras � $targetPalBloco target = $calculatedBlocks ? $finalBlocks blocos (~$actualPalBloco pal/bloco)',
      );
    }

    return finalBlocks;
  }

  int _calculateTargetForBlock(int current, int total, ScriptConfig c) {
    // ?? CALIBRA��O AJUSTADA: Multiplicador reduzido de 1.20 para 0.95 (95%)
    // PROBLEMA DETECTADO: Roteiros saindo 30% maiores (Wanessa +28%, Quit�ria +30%)
    // AN�LISE: Gemini est� gerando MAIS do que o pedido, n�o menos
    // SOLU��O: Reduzir multiplicador para evitar sobre-gera��o
    // Target: Ficar entre -5% e +10% do alvo (�10% aceit�vel)

    // ?? CORRE��O: Usar a mesma l�gica de normaliza��o que _calculateTotalBlocks
    // ???? AJUSTE ESPECIAL PARA COREANO: Densidade de caracteres menor
    final isKoreanTarget =
        c.language.contains('???') ||
        c.language.toLowerCase().contains('coreano') ||
        c.language.toLowerCase().contains('korean');

    final charToWordRatio = (c.measureType == 'caracteres' && isKoreanTarget)
        ? 4.2 // Coreano: alta densidade sil�bica
        : 5.5; // Outros idiomas: padr�o

    int targetQuantity = c.measureType == 'caracteres'
        ? (c.quantity / charToWordRatio)
              .round() // Convers�o: chars ? palavras
        : c.quantity;

    // ?? v10: REMOVIDO boost artificial
    // Li��o: Gemini ignora multiplicadores - gera naturalmente
    // Solu��o: Usar mesma tabela de blocos do portugu�s (comprovada)

    // ?? Aplicar os mesmos ajustes de idioma que em _calculateTotalBlocks
    // IMPORTANTE: S� aplicar para 'caracteres', nunca para 'palavras'
    // ATEN��O: Coreano usa estrat�gia de blocos m�ltiplos, n�o redu��o percentual
    if (c.measureType == 'caracteres' && targetQuantity > 6000) {
      final cyrillicLanguages = ['Russo', 'B�lgaro', 'S�rvio'];
      final otherNonLatinLanguages = ['Hebraico', 'Grego', 'Tailand�s'];
      final heavyDiacriticLanguages = [
        'Turco',
        'Polon�s',
        'Tcheco',
        'Vietnamita',
        'H�ngaro',
      ];

      if (cyrillicLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.88).round();
      } else if (otherNonLatinLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.85).round();
      } else if (heavyDiacriticLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.92).round();
      }
    }

    // ?? AJUSTE CR�TICO: Multiplicador calibrado por idioma
    // HIST�RICO:
    //   v1: 1.05 ? Gerou 86.7% (d�ficit de -13.3%) ?
    //   v2: 1.15 ? Gerou 116% (excesso de +16%) ?
    //   v3: 1.08 ? Gerou 112% (excesso de +12%) ??
    //   v4.1: 0.98 ? Esperado: 98-105% (ideal) ?
    //   v5.0: 1.08 ? Gerava bem (100%+) MAS erro 503 (10 blocos grandes) ?
    //   v6.0: 0.85 ? N�o d� 503 MAS gera s� 82% (8700/10600) ?
    //   v6.1: 0.95 ? Ainda baixo, gera s� 87% (9200/10600) ?
    //   v6.2: 1.00 ? Melhorou mas ainda 91% (9600/10600) ?
    //   v6.3: 1.05 ? Melhor, mas ainda 100% (10600) ou 77% (8500) vari�vel ??
    //   v6.4: 1.08 ? Volta ao valor do v5.0 MAS ainda d� 503 com 12 blocos ?
    //   v6.5: 1.05 ? Reduz para 1.05 + AUMENTA blocos (12?14) = blocos 25% menores ??
    //   v7.6.42: 1.18 ? Coreano espec�fico para compensar sub-gera��o de ~15%
    //
    // ???? COREANO v12: Multiplicador 1.18 para compensar sub-gera��o natural
    // AN�LISE: Coreano gera apenas ~84.6% do pedido (11k de 13k)
    // SOLU��O: Pedir 18% a mais para compensar
    double multiplier;
    if (isKoreanTarget) {
      multiplier = 1.18; // ???? v12: Compensar sub-gera��o de ~15%
    } else if (c.language.toLowerCase().contains('portugu')) {
      multiplier = 1.05; // v6.5: Portugu�s
    } else {
      multiplier = 1.05; // Outros idiomas
    }

    // Calcular target acumulado at� este bloco (com margem ajustada)
    final cumulativeTarget = (targetQuantity * (current / total) * multiplier)
        .round();

    // Calcular target acumulado do bloco anterior
    final previousCumulativeTarget = current > 1
        ? (targetQuantity * ((current - 1) / total) * multiplier).round()
        : 0;

    // DELTA = palavras necess�rias NESTE bloco espec�fico
    final baseTarget = cumulativeTarget - previousCumulativeTarget;

    // LIMITES por bloco individual (aumentado para evitar cortes)
    final maxBlockSize = c.measureType == 'caracteres' ? 15000 : 5000;

    // Para o �ltimo bloco, usar o multiplicador ajustado por idioma
    // Portugu�s: 1.05 para compensar leve sub-gera��o (~105% do target)
    // Outros: 0.95 para evitar sobre-gera��o
    if (current == total) {
      final wordsPerBlock = (targetQuantity / total).ceil();
      return min((wordsPerBlock * multiplier).round(), maxBlockSize);
    }

    return baseTarget > maxBlockSize ? maxBlockSize : baseTarget;
  }

  // ===================== Gera��o de Blocos =====================

  /// ?? WRAPPER: Chama o novo m�dulo BaseRules
  String _getLanguageInstruction(String l) {
    return BaseRules.getLanguageInstruction(l);
  }

  /// ?? WRAPPER: Chama o novo m�dulo BaseRules
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

  /// ?? WRAPPER: Chama o novo m�dulo BaseRules
  String _getContinueInstruction(String language) {
    return BaseRules.getContinueInstruction(language);
  }

  /// ?? Traduz labels de metadados (TEMA, SUBTEMA, etc) para o idioma selecionado
  /// ?? WRAPPER: Chama o novo m�dulo BaseRules
  Map<String, String> _getMetadataLabels(String language) {
    return BaseRules.getMetadataLabels(language);
  }

  /// ?? WRAPPER: Chama o novo m�dulo BaseRules
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

    // Context removido - n�o h� mais nomes para extrair do contexto manual

    // ?? NOVO: Extrair g�nero e rela��es de personagens do t�tulo
    final titleNames = _extractCharacterHintsFromTitle(config.title, '');
    names.addAll(titleNames);
    fromTitle.addAll(titleNames);

    // ?? CORRE��O BUG ALBERTO: Adicionar nomes COM pap�is ao tracker
    for (final name in names) {
      // Context removido - papel n�o pode mais ser extra�do do contexto manual

      // Para protagonista e secund�rio, usar pap�is expl�citos
      if (fromProtagonist.contains(name)) {
        tracker.addName(name, role: 'protagonista');
      } else if (fromSecondary.contains(name)) {
        tracker.addName(name, role: 'secund�rio');
      } else {
        tracker.addName(name, role: 'indefinido');
      }
    }

    // ?? LOG DETALHADO: Mostrar origem de cada nome carregado
    if (kDebugMode && tracker.confirmedNames.isNotEmpty) {
      debugPrint(
        '?? TRACKER BOOTSTRAP - ${tracker.confirmedNames.length} nome(s) carregado(s):',
      );
      if (fromProtagonist.isNotEmpty) {
        debugPrint('   ?? Protagonista: ${fromProtagonist.join(", ")}');
      }
      if (fromSecondary.isNotEmpty) {
        debugPrint('   ?? Secund�rio: ${fromSecondary.join(", ")}');
      }
      if (fromContext.isNotEmpty) {
        debugPrint('   ?? Do contexto: ${fromContext.join(", ")}');
      }
      if (fromTitle.isNotEmpty) {
        debugPrint('   ?? Do t�tulo: ${fromTitle.join(", ")}');
      }
      debugPrint('   ? Total: ${tracker.confirmedNames.join(", ")}');
    } else if (kDebugMode) {
      debugPrint(
        '?? TRACKER BOOTSTRAP: Nenhum nome inicial fornecido (ser� detectado no bloco 1)',
      );
    }
  }

  /// ?? v7.6.25: Atualiza tracker, RETORNA FALSE se houve conflito de papel
  bool _updateTrackerFromContextSnippet(
    _CharacterTracker tracker,
    ScriptConfig config,
    String snippet,
  ) {
    if (snippet.trim().isEmpty) return true; // Snippet vazio = sem erro

    bool hasRoleConflict = false; // ?? v7.6.25: Flag de erro

    final existingLower = tracker.confirmedNames
        .map((n) => n.toLowerCase())
        .toSet();
    final locationLower = config.localizacao.trim().toLowerCase();
    final candidateCounts = _extractNamesFromSnippet(snippet);

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
      if (_nameStopwords.contains(normalized)) return;

      // v7.6.63: Valida��o estrutural (aceita nomes do LLM)
      if (!_isLikelyName(name)) {
        if (kDebugMode) {
          debugPrint('Tracker ignorou texto invalido: "$name"');
        }
        return;
      }

      // ?? CORRE��O BUG ALBERTO: Extrair papel antes de adicionar
      final role = _extractRoleForName(name, snippet);

      if (role != null) {
        final success = tracker.addName(name, role: role); // ?? v7.6.25
        if (kDebugMode) {
          if (success) {
            debugPrint(
              '?? v7.6.31: Tracker adicionou personagem COM PAPEL: "$name" = "$role" (ocorr�ncias: $count)',
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
            '?? v7.6.31: Tracker adicionou personagem SEM PAPEL: "$name" (indefinido - ocorr�ncias: $count)',
          );
        }
      }
      if (kDebugMode) {
        debugPrint(
          '?? v7.6.31: Tracker adicionou personagem detectado: $name (ocorr�ncias: $count)',
        );
      }
    });

    return !hasRoleConflict; // ? true = OK, ? false = ERRO
  }

  /// ?? Traduz termos de parentesco do portugu�s para o idioma do roteiro
  /// ?? WRAPPER: Chama o novo m�dulo BaseRules
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
        '- Protagonista: "$translatedProtagonist" � mantenha exatamente este nome e sua fun��o.',
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
        '- Personagem secund�rio: "$translatedSecondary" � preserve o mesmo nome em todos os blocos.',
      );
      baseNames.add(secondary.toLowerCase());
    }

    final additional =
        tracker.confirmedNames
            .where((n) => !baseNames.contains(n.toLowerCase()))
            .toList()
          ..sort((a, b) => a.compareTo(b));

    for (final name in additional) {
      // ?? CORRIGIDO: Adicionar personagens mencionados (n�o s�o hints de narrador)
      if (name.startsWith('PERSONAGEM MENCIONADO')) {
        // Remover marcador e traduzir termo familiar antes de adicionar ao prompt
        final cleanName = name.replaceFirst('PERSONAGEM MENCIONADO: ', '');
        final translatedName = _translateFamilyTerms(
          cleanName,
          config.language,
        );
        lines.add(
          '- Personagem mencionado: $translatedName (manter como refer�ncia familiar)',
        );
      } else {
        final translatedName = _translateFamilyTerms(name, config.language);
        lines.add(
          '- Personagem estabelecido: "$translatedName" � n�o altere este nome nem invente apelidos.',
        );
      }
    }

    if (lines.isEmpty) return '';

    return 'PERSONAGENS ESTABELECIDOS:\n${lines.join('\n')}\nNunca substitua esses nomes por varia��es ou apelidos.\n';
  }

  // ?? CORRIGIDO: Extrair hints de g�nero/rela��es APENAS como contexto, N�O como narrador
  // O t�tulo � apenas o GANCHO da hist�ria, n�o define quem narra!
  // Quem narra � definido por: Perspectiva + Campo Protagonista + Contexto do usu�rio
  Set<String> _extractCharacterHintsFromTitle(String title, String context) {
    final hints = <String>{};
    if (title.trim().isEmpty) return hints;

    final titleLower = title.toLowerCase();
    final contextLower = context.toLowerCase();

    // ?? DETECTAR: 1) Rela��es familiares e 2) Nomes pr�prios mencionados no t�tulo

    // 1?? RELA��ES FAMILIARES
    final charactersInTitle = {
      'm�e': 'PERSONAGEM MENCIONADO: M�e',
      'pai': 'PERSONAGEM MENCIONADO: Pai',
      'filho': 'PERSONAGEM MENCIONADO: Filho',
      'filha': 'PERSONAGEM MENCIONADO: Filha',
      'esposa': 'PERSONAGEM MENCIONADO: Esposa',
      'marido': 'PERSONAGEM MENCIONADO: Marido',
      'irm�': 'PERSONAGEM MENCIONADO: Irm�',
      'irm�o': 'PERSONAGEM MENCIONADO: Irm�o',
      'av�': 'PERSONAGEM MENCIONADO: Av�',
      'av�': 'PERSONAGEM MENCIONADO: Av�',
      'tia': 'PERSONAGEM MENCIONADO: Tia',
      'tio': 'PERSONAGEM MENCIONADO: Tio',
    };

    for (final entry in charactersInTitle.entries) {
      if (titleLower.contains(entry.key) || contextLower.contains(entry.key)) {
        hints.add(entry.value);
        if (kDebugMode) {
          debugPrint(
            '?? Personagem detectado no t�tulo: ${entry.key} ? ${entry.value}',
          );
        }
      }
    }

    // 2?? NOMES PR�PRIOS MENCIONADOS NO T�TULO
    // Detectar padr�es como: "Voc� � Michael?" ou "chamado Jo�o" ou "nome: Maria"
    final namePatterns = [
      RegExp(
        r'(?:�|chamad[oa]|nome:|sou)\s+([A-Z������������][a-z������������]+(?:\s+[A-Z������������][a-z������������]+)?)',
        caseSensitive: false,
      ),
      RegExp(r'"([A-Z������������][a-z������������]+)"'), // Nomes entre aspas
      RegExp(
        r'protagonista\s+([A-Z������������][a-z������������]+)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in namePatterns) {
      for (final match in pattern.allMatches(title)) {
        final name = match.group(1)?.trim() ?? '';
        if (_looksLikePersonName(name) && name.length >= 3) {
          hints.add('NOME MENCIONADO NO T�TULO: $name');
          if (kDebugMode) {
            debugPrint('?? Nome pr�prio detectado no t�tulo: $name');
          }
        }
      }
    }

    return hints;
  }

  // ??????????????????????????????????????????????????????????????????
  // ?? SISTEMA DE ESTILOS NARRATIVOS
  // ??????????????????????????????????????????????????????????????????

  /// Extrai ano de strings como "Ano 1890, Velho Oeste" ou "1920, Nova York"
  String _extractYear(String localizacao) {
    if (localizacao.trim().isEmpty) return '';

    // Padr�es: "Ano 1890", "ano 1920", "Year 1850", "1776"
    final yearRegex = RegExp(r'(?:Ano|ano|Year|year)?\s*(\d{4})');
    final match = yearRegex.firstMatch(localizacao);

    if (match != null) {
      final year = match.group(1)!;
      final yearInt = int.tryParse(year);

      // Validar se � um ano razo�vel (1000-2100)
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

    // Tecnologias por per�odo (data da inven��o/populariza��o)
    if (yearInt < 1876) anachronisms.add('Telefone (inventado em 1876)');
    if (yearInt < 1879) {
      anachronisms.add('L�mpada el�trica (inventada em 1879)');
    }
    if (yearInt < 1886) {
      anachronisms.add('Autom�vel a gasolina (inventado em 1886)');
    }
    if (yearInt < 1895) anachronisms.add('Cinema (inventado em 1895)');
    if (yearInt < 1903) anachronisms.add('Avi�o (inventado em 1903)');
    if (yearInt < 1920) {
      anachronisms.add('R�dio comercial (popularizado em 1920)');
    }
    if (yearInt < 1927) anachronisms.add('Cinema sonoro (1927)');
    if (yearInt < 1936) anachronisms.add('Televis�o comercial (1936)');
    if (yearInt < 1946) anachronisms.add('Computador eletr�nico (ENIAC 1946)');
    if (yearInt < 1950) anachronisms.add('Cart�o de cr�dito (1950)');
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

  /// Retorna elementos de �poca que DEVEM ser inclu�dos
  List<String> _getPeriodElements(String year, String? genre) {
    if (year.isEmpty) return [];

    final yearInt = int.tryParse(year);
    if (yearInt == null) return [];

    final elements = <String>[];

    // ?? WESTERN (1850-1900)
    if (genre == 'western' && yearInt >= 1850 && yearInt <= 1900) {
      elements.addAll([
        'Rev�lver (Colt Peacemaker comum ap�s 1873)',
        'Saloon com portas batentes',
        'Cavalo como transporte principal',
        'Dilig�ncia (stagecoach)',
        'Xerife e delegados',
        'Lei do mais r�pido',
      ]);

      if (yearInt >= 1869) {
        elements.add('Ferrovia transcontinental (completada em 1869)');
      }
      if (yearInt >= 1844) {
        elements.add('Tel�grafo para comunica��o � dist�ncia');
      }
    }

    // ?? ELEMENTOS GERAIS POR PER�ODO
    if (yearInt < 1850) {
      // Era pr�-industrial
      elements.addAll([
        'Ilumina��o a vela ou lampi�o a �leo',
        'Transporte por carro�a ou cavalo',
        'Cartas entregues por mensageiro',
        'Vestimentas formais e conservadoras',
        'Sociedade rigidamente hier�rquica',
      ]);
    } else if (yearInt >= 1850 && yearInt < 1900) {
      // Era vitoriana/industrial
      elements.addAll([
        'Ilumina��o a g�s nas cidades',
        'Trem a vapor (ferrovias em expans�o)',
        'Tel�grafo para comunica��o',
        'Fotografia (daguerre�tipo)',
        'Jornais impressos',
      ]);
    } else if (yearInt >= 1900 && yearInt < 1920) {
      // Belle �poque / Era Eduardiana
      elements.addAll([
        'Primeiros autom�veis (ainda raros)',
        'Telefone fixo (casas ricas)',
        'Cinema mudo',
        'Ilumina��o el�trica nas cidades',
        'Fon�grafo (m�sica gravada)',
      ]);
    } else if (yearInt >= 1920 && yearInt < 1945) {
      // Entre-guerras
      elements.addAll([
        'R�dio como principal entretenimento',
        'Cinema sonoro (ap�s 1927)',
        'Autom�veis mais comuns',
        'Telefone residencial',
        'Avi�es comerciais (raros)',
      ]);
    } else if (yearInt >= 1945 && yearInt < 1970) {
      // P�s-guerra / Era de ouro
      elements.addAll([
        'Televis�o em preto e branco',
        'Autom�vel como padr�o',
        'Eletrodom�sticos modernos',
        'Cinema em cores',
        'Discos de vinil',
      ]);
    } else if (yearInt >= 1970 && yearInt < 1990) {
      // Era moderna
      elements.addAll([
        'Televis�o em cores',
        'Telefone residencial fixo',
        'Fitas cassete e VHS',
        'Primeiros computadores pessoais (ap�s 1981)',
        'Walkman (m�sica port�til)',
      ]);
    } else if (yearInt >= 1990 && yearInt < 2007) {
      // Era digital inicial
      elements.addAll([
        'Internet discada/banda larga',
        'Celular b�sico (sem smartphone)',
        'E-mail',
        'CDs e DVDs',
        'Computadores pessoais comuns',
      ]);
    } else if (yearInt >= 2007 && yearInt <= 2025) {
      // Era dos smartphones
      elements.addAll([
        'Smartphone touchscreen',
        'Redes sociais (Facebook, Twitter, Instagram)',
        'Wi-Fi ub�quo',
        'Streaming de v�deo/m�sica',
        'Apps para tudo',
      ]);
    }

    return elements;
  }

  /// Gera orienta��o de estilo narrativo baseado na configura��o
  String _getNarrativeStyleGuidance(ScriptConfig config) {
    final style = config.narrativeStyle;

    switch (style) {
      case 'reflexivo_memorias':
        return '''
??????????????????????????????????????????????????????????????????
?? ESTILO NARRATIVO: REFLEXIVO (MEM�RIAS)
??????????????????????????????????????????????????????????????????

**Tom:** Nost�lgico, pausado, introspectivo, suave
**Ritmo:** Lento e contemplativo, com pausas naturais
**Perspectiva emocional:** Olhar do presente para o passado com sabedoria

**ESTRUTURA NARRATIVA:**
1. Come�ar com gatilhos de mem�ria: "Eu me lembro...", "Naquele tempo...", "Era uma �poca em que..."
2. Intercalar presente e passado sutilmente
3. Usar pausas reflexivas (retic�ncias, sil�ncios)
4. Incluir detalhes sensoriais: cheiro, textura, luz, sons
5. Mencionar pequenas coisas que marcam �poca (objetos, costumes)

**VOCABUL�RIO:**
- Palavras suaves: "gentil", "singelo", "sutil", "delicado"
- Express�es temporais: "naqueles dias", "antigamente", "costumava"
- Verbos no imperfeito: "era", "tinha", "fazia", "lembrava"

**T�CNICAS:**
- Digress�es naturais (como algu�m contando hist�ria oral)
- Compara��es passado � presente
- Admitir falhas de mem�ria: "Se n�o me engano...", "Creio que..."
- Tom de sabedoria adquirida com o tempo

**EXEMPLO DE NARRA��O:**
"Eu me lembro... O cheiro do caf� coado na manh�, ainda quente na caneca de porcelana.
As m�os da minha av�, calejadas mas gentis, preparando o p�o caseiro.
Naquela �poca, as coisas eram mais simples. N�o t�nhamos pressa.
O tempo... ah, o tempo parecia se mover de outra forma.
Hoje, quando sinto o aroma de caf�, sou transportada de volta �queles dias..."

**EVITE:**
? A��o fren�tica ou tens�o extrema
? Vocabul�rio t�cnico ou moderno demais
? Narrativa onisciente (manter ponto de vista pessoal)
? Tom jovial ou energia excessiva
? Certezas absolutas (mem�rias s�o fluidas)
''';

      case 'epico_periodo':
        final year = _extractYear(config.localizacao);
        final anachronisms = _getAnachronismList(year);
        final periodElements = _getPeriodElements(year, config.genre);

        String anachronismSection = '';
        if (anachronisms.isNotEmpty) {
          anachronismSection =
              '''

**?? ANACRONISMOS A EVITAR (N�o existiam em $year):**
${anachronisms.map((a) => '  ? $a').join('\n')}
''';
        }

        String periodSection = '';
        if (periodElements.isNotEmpty) {
          periodSection =
              '''

**? ELEMENTOS DO PER�ODO A INCLUIR (Existiam em $year):**
${periodElements.map((e) => '  ? $e').join('\n')}
''';
        }

        return '''
??????????????????????????????????????????????????????????????????
?? ESTILO NARRATIVO: �PICO DE PER�ODO${year.isNotEmpty ? ' (Ano: $year)' : ''}
??????????????????????????????????????????????????????????????????

**Tom:** Grandioso, formal, heroico, majestoso
**Ritmo:** Cadenciado e majestoso, com constru��o dram�tica
**Perspectiva:** Narrador que conhece a import�ncia hist�rica dos eventos

**ESTRUTURA NARRATIVA:**
1. Descri��es detalhadas e v�vidas do per�odo hist�rico
2. Di�logos formais e apropriados � �poca (sem g�rias modernas)
3. Enfatizar valores, honra e c�digos morais da �poca
4. Usar linguagem elevada mas compreens�vel
5. Construir tens�o com descri��es atmosf�ricas

**VOCABUL�RIO:**
- Palavras de peso: "honra", "destino", "coragem", "sacrif�cio"
- Descri��es grandiosas: "sob o sol escaldante", "nas sombras da hist�ria"
- Evitar contra��es: "n�o havia" em vez de "n�o tinha"

**T�CNICAS:**
- Come�ar com estabelecimento de �poca e lugar
- Usar marcos hist�ricos reais quando poss�vel
- Descrever vestimentas, armas, tecnologia da �poca
- Criar senso de inevitabilidade hist�rica
- Pausas dram�ticas antes de momentos cruciais$anachronismSection$periodSection

**EXEMPLO DE NARRA��O:**
"${year.isNotEmpty ? 'No ano de $year' : 'Naquele tempo'}, sob o sol escaldante do Velho Oeste,
Jake ajustou o rev�lver no coldre de couro gasto. O duelo seria ao meio-dia.
A cidade inteira observava em sil�ncio das janelas empoeiradas,
sabendo que a justi�a seria feita pela lei do mais r�pido.
O vento quente soprava pela rua deserta, levantando nuvens de poeira vermelha.
Dois homens. Um c�digo. Um destino."

**EVITE:**
? Anacronismos (tecnologias que n�o existiam na �poca)
? G�rias modernas ou linguagem informal
? Refer�ncias contempor�neas
? Tom humor�stico ou irreverente
? Ritmo apressado (�pico requer peso)
''';

      case 'educativo_curioso':
        return '''
??????????????????????????????????????????????????????????????????
?? ESTILO NARRATIVO: EDUCATIVO (CURIOSIDADES)
??????????????????????????????????????????????????????????????????

**Tom:** Entusiasta, acess�vel, did�tico, fascinante
**Ritmo:** Moderado, com pausas para absor��o de conceitos
**Perspectiva:** Guia amig�vel que revela conhecimento surpreendente

**ESTRUTURA NARRATIVA (Framework de 4 Passos):**
1. **PERGUNTA INTRIGANTE:** Despertar curiosidade
2. **FATO SURPREENDENTE:** Resposta que causa "Uau!"
3. **EXPLICA��O COM CONTEXTO:** Como/Por que funciona
4. **IMPACTO/APLICA��O:** Por que isso importa

**FRASES-GATILHO (Use frequentemente):**
- "Voc� sabia que...?"
- "Mas aqui est� o fascinante..."
- "E � por isso que..."
- "Isso explica por que..."
- "Surpreendentemente..."
- "O interessante � que..."
- "Aqui est� a parte incr�vel..."

**T�CNICAS DE ENGAJAMENTO:**
- Fazer perguntas ret�ricas para o espectador
- Usar analogias com coisas do cotidiano
- Compara��es de escala (tamanho, tempo, dist�ncia)
- Fatos num�ricos impressionantes
- Conex�es inesperadas entre conceitos

**VOCABUL�RIO:**
- Palavras de descoberta: "revelador", "surpreendente", "fascinante"
- Verbos ativos: "descobrir", "revelar", "transformar", "conectar"
- Evitar jarg�o t�cnico SEM explica��o simples

**EXEMPLO DE NARRA��O:**
"Voc� sabia que o c�u � azul por causa de um fen�meno chamado espalhamento de Rayleigh?

Mas aqui est� o fascinante: quando a luz solar entra na atmosfera,
ela colide com mol�culas min�sculas de ar. A luz � composta de diferentes cores,
cada uma com seu pr�prio comprimento de onda.

A luz azul tem ondas menores e mais curtas, ent�o ela se espalha mais facilmente
ao colidir com as mol�culas. � como jogar bolinhas de diferentes tamanhos
atrav�s de uma peneira - as menores ricocheteiam mais!

E � por isso que vemos azul durante o dia, mas laranja e vermelho no p�r do sol.
No final do dia, a luz precisa atravessar MUITO mais atmosfera,
ent�o at� as ondas maiores (vermelhas e laranjas) come�am a se espalhar."

**EVITE:**
? Jarg�o t�cnico sem explica��o
? Tom professoral ou autorit�rio ("voc�s DEVEM saber...")
? Exemplos muito abstratos ou acad�micos
? Informa��o sem contexto pr�tico
? Monotonia (variar ritmo e entusiasmo)
''';

      case 'acao_rapida':
        return '''
??????????????????????????????????????????????????????????????????
? ESTILO NARRATIVO: A��O R�PIDA
??????????????????????????????????????????????????????????????????

**Tom:** Urgente, intenso, visceral, adrenalina pura
**Ritmo:** FREN�TICO - frases curtas e impactantes
**Perspectiva:** Imers�o total no momento presente

**ESTRUTURA NARRATIVA:**
1. Frases CURTAS (5-10 palavras m�ximo)
2. Verbos de a��o fortes e diretos
3. Tempo presente para imediatismo
4. Elimina��o de adjetivos desnecess�rios
5. Foco em MOVIMENTO e IMPACTO

**T�CNICA DE ESCRITA:**
- Cortar conjun��es: "Jake corre. Pula. Rola." (n�o "Jake corre, pula e rola")
- Um verbo forte por frase
- Frases fragmentadas para urg�ncia
- Pontua��o agressiva: ponto final, n�o v�rgula
- Onomatopeias quando apropriado: BAM! CRASH! BANG!

**VERBOS PREFERIDOS:**
- Movimento: corre, salta, mergulha, voa, derrapa
- Impacto: explode, estilha�a, rompe, perfura, esmaga
- Combate: ataca, esquiva, bloqueia, contra-ataca, elimina

**EXEMPLO DE NARRA��O:**
"O tiro ecoa. Jake rola. Esquiva.
Vidro explode atr�s dele. CRASH!
Levanta. Corre. Tr�s passos.
Mira. Dispara. BAM!
O oponente cambaleia. Cai.
Sil�ncio.
Vit�ria."

**T�CNICAS AVAN�ADAS:**
- Frases de uma palavra para picos: "Agora." "Fogo!" "Corre!"
- Eliminar artigos: "Bala rasga ar" (n�o "A bala rasga o ar")
- Usar presente simples: "Ele ataca" (n�o "Ele est� atacando")
- Staccato verbal: ritmo de metralhadora

**ESTRUTURA DE CENA DE A��O:**
1. Estabelecer perigo (2 frases)
2. Rea��o instintiva (3-4 frases ultra-curtas)
3. Escalada (mais movimento, mais perigo)
4. Cl�max (1-2 frases de impacto)
5. Resolu��o (1 frase de al�vio)

**EVITE:**
? Descri��es longas de cen�rio
? Reflex�es filos�ficas ou emocionais
? Di�logos extensos (m�ximo 3-4 palavras)
? Adjetivos m�ltiplos ("a bela e majestosa espada" ? "a espada")
? Subordinadas complexas
? Explica��es de motiva��o (a��o pura)
''';

      case 'lirico_poetico':
        return '''
??????????????????????????????????????????????????????????????????
?? ESTILO NARRATIVO: L�RICO PO�TICO
??????????????????????????????????????????????????????????????????

**Tom:** Melanc�lico, suave, contemplativo, et�reo
**Ritmo:** Cadenciado e musical, quase como versos livres
**Perspectiva:** Olhar art�stico que transforma realidade em poesia

**ESTRUTURA NARRATIVA:**
1. Imagens sensoriais ricas e sinest�sicas
2. Met�foras da natureza e elementos
3. Ritmo quase musical (aten��o � sonoridade)
4. Simbolismo em vez de descri��o direta
5. Repeti��es para �nfase emocional

**RECURSOS PO�TICOS:**

**Met�foras:**
- Comparar emo��es com natureza: "dor como tempestade", "alegria como aurora"
- Personificar elementos: "o vento sussurra", "a noite abra�a"
- Transformar concreto em abstrato: "olhos eram janelas de alma"

**Sinestesia (Misturar Sentidos):**
- "Som aveludado da voz"
- "Sil�ncio pesado"
- "Luz quente das palavras"
- "Sabor amargo da saudade"

**Alitera��o e Asson�ncia:**
- "Suave som do sil�ncio sussurra"
- "Lua l�nguida lamenta"
- Aten��o ao ritmo das palavras

**VOCABUL�RIO:**
- Palavras suaves: "et�reo", "ef�mero", "sublime", "t�nue"
- Natureza: "aurora", "crep�sculo", "orvalho", "brisa"
- Emo��o profunda: "melancolia", "nostalgia", "anseio", "enlevo"

**EXEMPLO DE NARRA��O:**
"A lua, p�lida testemunha da noite eterna,
derramava sua luz prateada sobre os campos adormecidos.
O vento, esse mensageiro de segredos antigos,
sussurrava entre as folhas trementes das �rvores.

E o tempo, esse eterno viajante sem repouso,
seguia seu curso inexor�vel,
levando consigo os momentos como p�talas ao vento,
enquanto as estrelas bordavam seus poemas silenciosos
no vasto manto azul do infinito."

**T�CNICAS AVAN�ADAS:**
- Repeti��o para �nfase: "Esperava. Sempre esperava. Como se esperar fosse seu destino."
- Frases longas e fluidas (contr�rio da a��o r�pida)
- Usar v�rgulas para criar ritmo de respira��o
- Imagens visuais como pinturas
- Deixar espa�o para interpreta��o (n�o explicar tudo)

**ESTRUTURA EMOCIONAL:**
- Come�ar com imagem sensorial
- Construir camadas de significado
- Cl�max emocional (n�o de a��o)
- Resolu��o contemplativa ou em aberto

**EVITE:**
? Linguagem t�cnica ou prosaica
? A��o fren�tica ou viol�ncia expl�cita
? Di�logos diretos e funcionais
? Explica��es literais
? Ritmo apressado ou urgente
? Jarg�o ou coloquialismo
''';

      default: // ficcional_livre
        return '''
??????????????????????????????????????????????????????????????????
?? ESTILO NARRATIVO: FIC��O LIVRE (SEM RESTRI��ES)
??????????????????????????????????????????????????????????????????

**Tom:** Flex�vel - adapta-se ao tema e g�nero
**Ritmo:** Balanceado - varia conforme necessidade
**Perspectiva:** Liberdade criativa total

**ORIENTA��ES GERAIS:**
? Misturar estilos conforme necess�rio (a��o + reflex�o + descri��o)
? Adaptar tom ao tema escolhido (drama, com�dia, suspense, etc.)
? Usar t�cnicas narrativas variadas
? Focar em contar uma boa hist�ria sem restri��es formais
? Priorizar engajamento e fluidez

**ESTRUTURA SUGERIDA:**
1. Estabelecimento (contexto e personagens)
2. Desenvolvimento (conflito e progress�o)
3. Cl�max (momento de maior tens�o)
4. Resolu��o (desfecho satisfat�rio)

**FLEXIBILIDADE:**
- Pode usar di�logos extensos ou ausentes
- Pode alternar entre a��o e contempla��o
- Pode misturar tempos verbais se necess�rio
- Pode variar entre formal e coloquial

**DICA:** Use os elementos dos outros estilos conforme a cena:
- Momentos intensos? T�cnicas de "A��o R�pida"
- Momentos emotivos? Toques de "L�rico Po�tico"
- Flashbacks? Elementos de "Reflexivo Mem�rias"
- Per�odo hist�rico? Cuidado com anacronismos do "�pico"
- Explicar algo? Clareza do "Educativo"
''';
    }
  }

  Map<String, int> _extractNamesFromSnippet(String snippet) {
    final counts = <String, int>{};
    final regex = RegExp(
      r'\b([A-Z������������][a-z������������]+(?:\s+[A-Z������������][a-z������������]+)*)\b',
    );

    for (final match in regex.allMatches(snippet)) {
      final candidate = match.group(1)?.trim() ?? '';
      if (!_looksLikePersonName(candidate)) continue;
      final normalized = candidate.replaceAll(RegExp(r'\s+'), ' ');
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }

    return counts;
  }

  // ?? EXECUTAR EM ISOLATE para n�o travar UI
  Future<String> _filterDuplicateParagraphs(
    String existing,
    String addition,
  ) async {
    if (addition.trim().isEmpty) return '';

    // Para textos pequenos, executar direto (mais r�pido que spawn isolate)
    if (existing.length < 3000 && addition.length < 1000) {
      return _filterDuplicateParagraphsSync(existing, addition);
    }

    // Textos grandes: processar em isolate separado
    return await compute(_filterDuplicateParagraphsStatic, {
      'existing': existing,
      'addition': addition,
    });
  }

  // Vers�o s�ncrona para casos r�pidos
  String _filterDuplicateParagraphsSync(String existing, String addition) {
    if (addition.trim().isEmpty) return '';

    // ?? OTIMIZA��O CR�TICA: Comparar apenas �ltimos ~5000 caracteres
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

  /// ?? Detecta par�grafos duplicados no roteiro final (apenas para LOG)
  /// N�O remove nada, apenas alerta no console para debugging
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

        debugPrint('?? DUPLICA��O DETECTADA:');
        debugPrint(
          '   ?? Par�grafo #${firstIndex + 1} repetido no par�grafo #${i + 1}',
        );
        debugPrint('   ?? Pr�via: "$preview"');
      } else {
        seen[paragraph] = i;
      }
    }

    if (duplicateCount > 0) {
      debugPrint(
        '?? TOTAL: $duplicateCount par�grafo(s) duplicado(s) encontrado(s) no roteiro final!',
      );
      debugPrint(
        '   ?? DICA: Fortale�a as instru��es anti-repeti��o no prompt',
      );
    } else {
      debugPrint(
        '? VERIFICA��O: Nenhuma duplica��o de par�grafo detectada no roteiro final',
      );
    }
  }

  // ??? v7.6.64: _removeDuplicateConsecutiveParagraphs removido (n�o era usado)

  /// ?? v7.6.43: Remove TODAS as duplicatas de par�grafos (n�o apenas consecutivas)
  /// Mant�m a primeira ocorr�ncia e remove todas as repeti��es posteriores
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

      // Normalizar para compara��o (ignorar espa�os extras)
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
          debugPrint('?? REMOVIDO duplicata exata: "$preview"');
        }
        continue;
      }

      // Verificar duplicata normalizada (ignora case e espa�os)
      if (seenNormalized.contains(normalized)) {
        removedCount++;
        if (kDebugMode) {
          debugPrint('?? REMOVIDO duplicata similar (case/espa�os diferentes)');
        }
        continue;
      }

      seen.add(paragraph);
      seenNormalized.add(normalized);
      result.add(paragraph);
    }

    if (removedCount > 0) {
      debugPrint(
        '? v7.6.43: Total de $removedCount par�grafo(s) duplicado(s) removido(s) do roteiro final',
      );
    }

    return result.join('\n\n');
  }

  // ??? v7.6.64: _buildRecoveryPrompt migrado para ScriptPromptBuilder.buildRecoveryPrompt()

  /// ?? v7.6.17: Detecta e registra o nome da protagonista no Bloco 1
  /// Extrai o primeiro nome pr�prio encontrado e registra no tracker
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
        debugPrint('? Bloco 1: Protagonista "$configName" confirmada');
      }
    } else {
      // Se nome configurado n�o apareceu, pegar primeiro nome v�lido
      final validNames = names.where((n) => _looksLikePersonName(n)).toList();
      if (validNames.isNotEmpty) {
        final detectedName = validNames.first;
        tracker.setProtagonistName(detectedName);
        if (kDebugMode) {
          debugPrint(
            '?? Bloco 1: Nome configurado "$configName" n�o usado, '
            'detectado "$detectedName" como protagonista',
          );
        }
      }
    }
  }

  /// ?? v7.6.17: Valida se protagonista manteve o mesmo nome
  /// Retorna true se mudan�a detectada (bloco deve ser rejeitado)
  bool _detectProtagonistNameChange(
    String generatedText,
    ScriptConfig config,
    _CharacterTracker tracker,
    int blockNumber,
  ) {
    if (blockNumber == 1) return false; // Bloco 1 sempre v�lido

    final registeredName = tracker.getProtagonistName();
    if (registeredName == null) return false; // Sem protagonista registrada

    // Extrair todos os nomes do bloco atual
    final currentNames = _extractNamesFromText(generatedText);

    // Verificar se protagonista registrada aparece
    final protagonistPresent = currentNames.contains(registeredName);

    // Verificar se h� outros nomes v�lidos (poss�vel troca)
    final otherValidNames = currentNames
        .where((n) => n != registeredName && _looksLikePersonName(n))
        .toList();

    // ?? DETEC��O: Se protagonista n�o apareceu MAS h� outros nomes v�lidos
    if (!protagonistPresent && otherValidNames.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '?? Bloco $blockNumber: Protagonista "$registeredName" ausente!',
        );
        debugPrint('   Nomes encontrados: ${otherValidNames.join(", ")}');
        debugPrint('   ?? Poss�vel mudan�a de nome!');
      }

      _debugLogger.error(
        'Mudan�a de protagonista detectada',
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

  /// ?? VALIDA��O CR�TICA: Detecta reutiliza��o de nomes de personagens
  /// Cada personagem deve ter apenas 1 nome �nico
  /// Retorna true se valida��o passou, false se detectou erro cr�tico
  bool _validateProtagonistName(
    String generatedText,
    ScriptConfig config,
    int blockNumber,
  ) {
    final protagonistName = config.protagonistName.trim();
    if (protagonistName.isEmpty) {
      return true; // Sem protagonista configurada = ok
    }

    // ?? NOVA VALIDA��O: Detectar auto-apresenta��es com nomes errados
    // Padr�es: "my name is X", "i'm X", "call me X"
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
            '?? ERRO CR�TICO: AUTO-APRESENTA��O COM NOME ERRADO!',
            level: 'critical',
          );
          _log(
            '   ? Protagonista configurada: "$protagonistName"',
            level: 'critical',
          );
          _log(
            '   ? Nome na auto-apresenta��o: "$introducedName"',
            level: 'critical',
          );
          _log('   ?? Trecho: "${match.group(0)}"', level: 'critical');
          _log('   ?? BLOCO SER� REJEITADO E REGENERADO', level: 'critical');

          return false; // ?? REJEITAR BLOCO
        }
      }
    }

    // ?? PARTE 1: Validar protagonista espec�fica
    final suspiciousNames = [
      'Wanessa',
      'Carla',
      'Beatriz',
      'Fernanda',
      'Juliana',
      'Mariana',
      'Patr�cia',
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
      // Nomes comuns em ingl�s (caso do roteiro gerado)
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
        continue; // Nome suspeito � o pr�prio protagonista configurado
      }

      if (generatedText.contains(suspiciousName)) {
        // ?? DEBUG: Log erro cr�tico de nome
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
          '?? ERRO CR�TICO DETECTADO NO BLOCO $blockNumber:',
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
          '   ?? POSS�VEL TROCA DE NOME DA PROTAGONISTA!',
          level: 'critical',
        );
        _log('   ?? BLOCO SER� REJEITADO E REGENERADO', level: 'critical');

        return false; // ?? REJEITAR BLOCO
      }
    }

    if (!hasProtagonist && blockNumber <= 2) {
      // ?? DEBUG: Log aviso de protagonista ausente
      _debugLogger.warning(
        "Protagonista ausente",
        details: "'$protagonistName' n�o apareceu no bloco $blockNumber",
        metadata: {'bloco': blockNumber, 'protagonista': protagonistName},
      );

      debugPrint(
        '?? AVISO: Protagonista "$protagonistName" n�o apareceu no bloco $blockNumber',
      );
    } else if (hasProtagonist) {
      // ?? DEBUG: Log valida��o bem-sucedida
      _debugLogger.validation(
        "Protagonista validada",
        blockNumber: blockNumber,
        details: "'$protagonistName' presente no bloco",
        metadata: {'protagonista': protagonistName},
      );
    }

    return true; // Valida��o passou
  }

  /// 🔗 v7.6.22: VALIDAÇÃO DE RELACIONAMENTOS FAMILIARES
  /// 🏗️ v7.6.67: Refatorado para usar RelationshipPatterns module
  /// Detecta contradições lógicas em árvores genealógicas
  /// Retorna true se relacionamentos são consistentes, false se há erros
  bool _validateFamilyRelationships(String text, int blockNumber) {
    if (text.isEmpty) return true;

    // Mapa de relacionamentos encontrados: pessoa → relação → pessoa relacionada
    final Map<String, Map<String, Set<String>>> relationships = {};

    // 🏗️ v7.6.67: Usa padrões do módulo RelationshipPatterns
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

    // Validar relacionamentos l�gicos
    bool hasError = false;

    // REGRA 1: Se X � meu cunhado/cunhada, ent�o:
    //   - X deve ser irm�o/irm� do meu c�njuge OU
    //   - X deve ser c�njuge do meu irm�o/irm�
    final brotherInLaw = relationships['protagonist']?['cunhado'] ?? {};
    final sisterInLaw = relationships['protagonist']?['cunhada'] ?? {};
    final husband = relationships['protagonist']?['marido'] ?? {};
    final wife = relationships['protagonist']?['esposa'] ?? {};
    final brother = relationships['protagonist']?['irm�o'] ?? {};
    final sister = relationships['protagonist']?['irm�'] ?? {};

    for (final inLaw in [...brotherInLaw, ...sisterInLaw]) {
      // Se X � cunhado mas nunca mencionamos c�njuge nem irm�os = ERRO
      if (husband.isEmpty &&
          wife.isEmpty &&
          brother.isEmpty &&
          sister.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '?? ERRO: $inLaw � cunhado/cunhada mas n�o h� c�njuge nem irm�os mencionados!',
          );
        }
        hasError = true;
      }
    }

    // REGRA 2: Se X � meu sogro/sogra, ent�o:
    //   - Eu DEVO ter c�njuge (marido/esposa)
    //   - X deve ser pai/m�e do meu c�njuge
    final fatherInLaw = relationships['protagonist']?['sogro'] ?? {};
    final motherInLaw = relationships['protagonist']?['sogra'] ?? {};

    if (fatherInLaw.isNotEmpty || motherInLaw.isNotEmpty) {
      if (husband.isEmpty && wife.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '?? ERRO: Tem sogro/sogra mas protagonista n�o tem c�njuge!',
          );
          debugPrint('   ? Se X � sogro, protagonista DEVE ter esposa/marido');
        }
        hasError = true;
      }
    }

    // REGRA 3: Se X � meu genro/nora, ent�o:
    //   - Eu DEVO ter filho/filha
    //   - X deve ser c�njuge do meu filho/filha
    final sonInLaw = relationships['protagonist']?['genro'] ?? {};
    final daughterInLaw = relationships['protagonist']?['nora'] ?? {};

    if (sonInLaw.isNotEmpty || daughterInLaw.isNotEmpty) {
      // Verificar se menciona filhos (procurar padr�o mais amplo)
      final hasChildren = text.contains(
        RegExp(
          r'meu filho|minha filha|my son|my daughter',
          caseSensitive: false,
        ),
      );

      if (!hasChildren) {
        if (kDebugMode) {
          debugPrint('?? ERRO: Tem genro/nora mas n�o menciona filhos!');
          debugPrint(
            '   ? Se X � genro/nora, protagonista DEVE ter filho/filha',
          );
        }
        hasError = true;
      }
    }

    // REGRA 4: Se X � meu neto/neta, ent�o:
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
          debugPrint('?? ERRO: Tem neto/neta mas n�o menciona filhos!');
          debugPrint(
            '   ? Se X � neto/neta, protagonista DEVE ter filho/filha',
          );
        }
        hasError = true;
      }
    }

    // REGRA 5: Detectar contradi��es com sufixos -in-law
    // Exemplo: "my brother Paul married Megan" + "my father-in-law Alan"
    // Se Megan � filha de Alan, ent�o Alan � sogro de Paul (n�o do protagonista)
    final marriedPattern = RegExp(
      r'my (brother|sister)(?:,)?\s+([A-Z][a-z]+)\s+(?:married|casou com)\s+([A-Z][a-z]+)',
      caseSensitive: false,
    );

    for (final match in marriedPattern.allMatches(text)) {
      final sibling = match.group(2); // Nome do irm�o/irm�
      final spouse = match.group(3); // Nome do c�njuge do irm�o/irm�

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
              debugPrint('?? ERRO DE RELACIONAMENTO GENEAL�GICO!');
              debugPrint(
                '   ? $parentName � pai de $spouse (c�njuge de $sibling)',
              );
              debugPrint(
                '   ? Mas texto chama $parentName de "my father-in-law"',
              );
              debugPrint(
                '   ? CORRETO seria: "$parentName � sogro do meu irm�o $sibling"',
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
          '   ?? For�ando regenera��o com l�gica geneal�gica correta...',
        );
      }
    }

    return !hasError; // Retorna true se n�o h� erros
  }

  /// ?? EXTRA��O DE PAPEL: Identifica o papel/rela��o de um nome em um texto
  /// Retorna o primeiro papel encontrado ou null se n�o detectar nenhum
  /// ?? v7.6.28: Valida se h� nomes duplicados em pap�is diferentes
  /// ?? v7.6.32: NOVA VALIDA��O - Detecta quando MESMO PAPEL tem NOMES DIFERENTES
  /// ?? v7.6.33: PAP�IS POSSESSIVOS SINGULARES - Detecta "my lawyer" como papel �nico
  /// ?? v7.6.34: FIX MULTI-WORD ROLES - Corrige detec��o de "executive assistant", "financial advisor"
  ///
  /// OBJETIVO 1 (v7.6.28): Detectar quando MESMO NOME aparece para PERSONAGENS DIFERENTES
  /// EXEMPLO RUIM: "Mark" como boyfriend + "Mark" como attorney
  ///
  /// OBJETIVO 2 (v7.6.32): Detectar quando MESMO PAPEL � atribu�do a NOMES DIFERENTES
  /// EXEMPLO RUIM: "Ashley" como protagonista + "Emily" como protagonista
  ///
  /// OBJETIVO 3 (v7.6.33/34): Detectar quando PAPEL POSSESSIVO tem NOMES DIFERENTES
  /// EXEMPLOS RUINS:
  ///   - "my lawyer, Richard" (Bloco 5) ? "my lawyer, Mark" (Bloco 10)
  ///   - "my executive assistant, Lauren" (Bloco 7) ? "my executive assistant, Danielle" (Bloco 12)
  /// L�GICA: "my X" = possessivo singular = papel �nico (n�o pode ter m�ltiplos)
  /// ?? v7.6.34: Agora captura corretamente multi-word roles (executive assistant, financial advisor, etc.)
  ///
  /// Retorna TRUE se houver conflito (bloco deve ser rejeitado)
  /// Retorna FALSE se nomes s�o �nicos (bloco pode ser aceito)
  bool _validateUniqueNames(
    String blockText,
    _CharacterTracker tracker,
    int blockNumber,
  ) {
    if (blockText.trim().isEmpty) return false; // Texto vazio = sem erro

    // Extrair nomes do bloco atual
    final namesInBlock = _extractNamesFromText(blockText);

    // Verificar cada nome extra�do
    for (final name in namesInBlock) {
      // ---------------------------------------------------------------
      // VALIDA��O 1 (v7.6.28): MESMO NOME em PAP�IS DIFERENTES
      // ---------------------------------------------------------------
      if (tracker.hasName(name)) {
        // Nome j� existe - verificar se � o MESMO personagem ou REUSO indevido

        // Extrair papel atual deste nome no bloco
        final currentRole = _extractRoleForName(name, blockText);

        // Extrair papel registrado anteriormente
        final previousRole = tracker.getRole(name);

        if (currentRole != null && previousRole != null) {
          // Normalizar pap�is para compara��o
          final normalizedCurrent = _normalizeRole(currentRole);
          final normalizedPrevious = _normalizeRole(previousRole);

          // Se pap�is s�o DIFERENTES = NOME DUPLICADO (ERRO!)
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
                '   ?? Bloco $blockNumber ser� REJEITADO e REGENERADO',
              );
              debugPrint('?????? FIM DO ALERTA ??????');
            }

            _debugLogger.error(
              "Nome duplicado em pap�is diferentes - Bloco $blockNumber",
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
      // ?? VALIDA��O 2 (v7.6.32): MESMO PAPEL em NOMES DIFERENTES
      // ---------------------------------------------------------------
      final currentRole = _extractRoleForName(name, blockText);

      if (currentRole != null && currentRole != 'indefinido') {
        final normalizedCurrent = _normalizeRole(currentRole);

        // Verificar se este PAPEL j� existe com um NOME DIFERENTE
        for (final existingName in tracker.confirmedNames) {
          if (existingName.toLowerCase() == name.toLowerCase()) {
            continue; // Mesmo nome = OK (j� validado acima)
          }

          final existingRole = tracker.getRole(existingName);
          if (existingRole == null) continue;

          final normalizedExisting = _normalizeRole(existingRole);

          // ?? PAP�IS CR�TICOS que DEVEM ser �nicos (1 nome por papel)
          final uniqueRoles = {
            'protagonista',
            'protagonist',
            'main character',
            'narradora',
            'narrador',
            'narrator',
            'hero',
            'heroine',
            'her�i',
            'hero�na',
          };

          // Se MESMO PAPEL com NOMES DIFERENTES = ERRO CR�TICO!
          if (normalizedCurrent == normalizedExisting) {
            // Verificar se � papel cr�tico que deve ser �nico
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
                  '   ?? Bloco $blockNumber ser� REJEITADO e REGENERADO',
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

              return true; // ? CONFLITO CR�TICO DETECTADO
            }
          }
        }
      }

      // ---------------------------------------------------------------
      // ?? VALIDA��O 3 (v7.6.33): PAP�IS POSSESSIVOS SINGULARES
      // ---------------------------------------------------------------
      // OBJETIVO: Detectar pap�is �nicos indicados por possessivos singulares
      // EXEMPLO RUIM: "my lawyer, Richard" (Bloco 5) ? "my lawyer, Mark" (Bloco 10)
      //
      // Quando texto usa "my X" (possessive singular), indica papel �nico
      // N�o pode haver m�ltiplas inst�ncias: "my lawyer" = apenas 1 advogado
      //
      // ?? Detecta padr�es:
      // - "my lawyer", "my attorney", "my doctor"
      // - "my therapist", "my accountant", "my agent"
      // - "my boss", "my mentor", "my partner"
      //
      // ?? IMPORTANTE: "my lawyers" (plural) N�O � considerado �nico
      // ---------------------------------------------------------------

      // Padr�o para detectar possessivos singulares
      // Captura: "my [role]" mas N�O "my [role]s" (plural)
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

        // Verificar se J� existe este papel possessivo com NOME DIFERENTE
        for (final existingName in tracker.confirmedNames) {
          if (existingName.toLowerCase() == name.toLowerCase()) {
            continue; // Mesmo nome = OK
          }

          final existingRole = tracker.getRole(existingName);
          if (existingRole == null) continue;

          final normalizedExisting = _normalizeRole(existingRole).toLowerCase();

          // ?? v7.6.34: Match exato ou cont�m o papel completo (executive assistant, etc.)
          final possessiveRoleNormalized = possessiveRole.replaceAll(
            RegExp(r'\s+'),
            ' ',
          );

          // Verificar se papel possessivo j� existe
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
                '   ?? "my X" indica papel �NICO - n�o pode haver m�ltiplos!',
              );
              debugPrint(
                '   ?? Bloco $blockNumber ser� REJEITADO e REGENERADO',
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

    return false; // ? Nenhum conflito de nomes ou pap�is
  }

  /// ?? v7.6.26: Normaliza papel SELETIVAMENTE (evita falsos positivos)
  ///
  /// PAP�IS FAMILIARES: Mant�m completo "m�e de Emily" ? "m�e de Michael"
  /// PAP�IS GEN�RICOS: Normaliza "advogado de Sarah" ? "advogado"
  ///
  /// Exemplo:
  /// - "m�e de Emily" ? "m�e de emily" (mant�m rela��o)
  /// - "irm�o de Jo�o" ? "irm�o de jo�o" (mant�m rela��o)
  /// - "advogado de Sarah" ? "advogado" (remove rela��o)
  /// - "m�dico de Michael" ? "m�dico" (remove rela��o)
  String _normalizeRole(String role) {
    final roleLower = role.toLowerCase().trim();

    // ?? v7.6.26: PAP�IS FAMILIARES - N�O normalizar (manter contexto familiar)
    // Permite m�ltiplas fam�lias na mesma hist�ria sem falsos positivos
    final familyRoles = [
      'm�e',
      'pai',
      'filho',
      'filha',
      'irm�o',
      'irm�',
      'av�',
      'av�',
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
      'm�re',
      'p�re',
      'fils',
      'fille',
      'fr�re',
      's�ur',
      'grand-p�re',
      'grand-m�re',
      'oncle',
      'tante',
      'cousin',
      'cousine',
    ];

    // Verificar se � papel familiar
    for (final familyRole in familyRoles) {
      if (roleLower.contains(familyRole)) {
        // ? MANTER COMPLETO: "m�e de Emily" permanece "m�e de emily"
        // Isso permite Sarah ser "m�e de Emily" e Jennifer ser "m�e de Michael"
        if (kDebugMode) {
          debugPrint(
            '??????????? v7.6.26: Papel familiar detectado, mantendo completo: "$roleLower"',
          );
        }
        return roleLower;
      }
    }

    // ?? PAP�IS GEN�RICOS: Normalizar (remover sufixo "de [Nome]")
    // "advogado de Sarah" ? "advogado"
    // "m�dico de Jo�o" ? "m�dico"
    final normalized = roleLower
        .replaceAll(RegExp(r'\s+de\s+[A-Z������������a-z������������]+.*$'), '')
        .trim();

    if (kDebugMode && normalized != roleLower) {
      debugPrint(
        '?? v7.6.26: Papel gen�rico normalizado: "$roleLower" ? "$normalized"',
      );
    }

    return normalized;
  }

  /// 🏗️ v7.6.67: Delegando para módulo RolePatterns
  String? _extractRoleForName(String name, String text) {
    return RolePatterns.extractRoleForName(name, text);
  }

  /// 🔍 VALIDAÇÃO FORTALECIDA: Detecta quando um nome é reutilizado para outro personagem
  /// 🏗️ v7.6.67: Refatorado para usar RolePatterns module
  /// Exemplo: "Regina" sendo usada para sogra E amiga, "Marta" para irmã de A e irmã de B
  void _validateNameReuse(
    String generatedText,
    _CharacterTracker tracker,
    int blockNumber,
  ) {
    // Extrair todos os nomes do texto gerado
    final namePattern = RegExp(r'\b([A-ZÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇa-záàâãéèêíìîóòôõúùûç]{2,})\b');
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

        // 🏗️ v7.6.67: Usar RolePatterns para extrair papel atual
        final currentRole = RolePatterns.extractRoleForName(name, generatedText);
        
        if (currentRole != null) {
          // DETECÇÃO: Se papel atual difere do existente
          if (existingRole == null || existingRole == 'indefinido') {
            // Nome existia SEM papel definido, agora tem papel
            if (kDebugMode) {
              debugPrint('⚠️ Nome "$name" definido como $currentRole (bloco $blockNumber)');
            }
          } else if (!RolePatterns.areRolesEquivalent(currentRole, existingRole)) {
            // Conflito de papéis
            _debugLogger.error(
              "Reutilização de nome: '$name'",
              blockNumber: blockNumber,
              details:
                  "Nome '$name' usado em múltiplos papéis diferentes:\n"
                  "- Papel anterior: $existingRole\n"
                  "- Papel atual: $currentRole",
              metadata: {
                'nome': name,
                'papelAnterior': existingRole,
                'papelAtual': currentRole,
              },
            );

            if (kDebugMode) {
              debugPrint('❌ ERRO: Nome "$name" reutilizado!');
              debugPrint('   Papel anterior: $existingRole');
              debugPrint('   Papel atual: $currentRole');
            }
          }
        }
      }
    }

    // DEBUG: Log validação completa
    _debugLogger.validation(
      "Validação de reutilização completa",
      blockNumber: blockNumber,
      details: "${foundNames.length} nomes verificados",
      metadata: {'nomesVerificados': foundNames.length},
    );
  }

  /// 🔍 NOVA VALIDAÇÃO: Detecta inconsistências em relações familiares
  /// 🏗️ v7.6.67: Refatorado para usar RolePatterns module
  /// Exemplo: "meu Pai Francisco" vs "meu marido Francisco" = CONFUSÃO
  void _validateFamilyRelations(String generatedText, int blockNumber) {
    // Extrair nomes mencionados no texto
    final namePattern = RegExp(r'\b([A-ZÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇ][a-záàâãéèêíìîóòôõúùûç]{2,})\b');
    final names = <String>{};

    for (final match in namePattern.allMatches(generatedText)) {
      final name = match.group(1)?.trim();
      if (name != null && _looksLikePersonName(name)) {
        names.add(name);
      }
    }

    // Para cada nome, usar RolePatterns para detectar papel
    for (final name in names) {
      final role = RolePatterns.extractRoleForName(name, generatedText);
      
      // Se detectou papel, verificar se há conflitos
      if (role != null) {
        // Verificar se mesmo nome aparece em contextos conflitantes
        // usando lógica simplificada baseada no módulo
        if (kDebugMode) {
          debugPrint('📋 Nome "$name" detectado como: $role (bloco $blockNumber)');
        }
      }
    }
  }

  /// 🔍 NOVA VALIDAÇÃO CRÍTICA v7.6.16: Detecta mudanças de nome de personagens
  /// Compara pap�is conhecidos (tracker) com novos nomes mencionados no texto
  /// Retorna lista de mudan�as detectadas para rejei��o do bloco
  List<Map<String, String>> _detectCharacterNameChanges(
    String generatedText,
    _CharacterTracker tracker,
    int blockNumber,
  ) {
    final changes = <Map<String, String>>[];

    // Padr�es de rela��es familiares para detectar personagens
    final relationPatterns = {
      'pai': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Pp]ai(?:,)?\s+([A-Z������������][a-z������������]+)',
        caseSensitive: false,
      ),
      'm�e': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Mm]�e(?:,)?\s+([A-Z������������][a-z������������]+)',
        caseSensitive: false,
      ),
      'marido': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:marido|esposo)(?:,)?\s+([A-Z������������][a-z������������]+)',
        caseSensitive: false,
      ),
      'esposa': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:esposa|mulher)(?:,)?\s+([A-Z������������][a-z������������]+)',
        caseSensitive: false,
      ),
      'filho': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Ff]ilho(?:,)?\s+([A-Z������������][a-z������������]+)',
        caseSensitive: false,
      ),
      'filha': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Ff]ilha(?:,)?\s+([A-Z������������][a-z������������]+)',
        caseSensitive: false,
      ),
      'irm�o': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:irm�o|irmao)(?:,)?\s+([A-Z������������][a-z������������]+)',
        caseSensitive: false,
      ),
      'irm�': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:irm�|irma)(?:,)?\s+([A-Z������������][a-z������������]+)',
        caseSensitive: false,
      ),
      'advogado': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Aa]dvogad[oa](?:,)?\s+([A-Z������������][a-z������������]+)',
        caseSensitive: false,
      ),
      'investigador': RegExp(
        r'(?:o|um)\s+[Ii]nvestigador(?:,)?\s+([A-Z������������][a-z������������]+)',
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

        // Verificar se este papel j� tem um nome no tracker
        final existingName = tracker.getNameForRole(role);

        if (existingName != null && existingName != newName) {
          // ?? MUDAN�A DETECTADA!
          changes.add({
            'role': role,
            'oldName': existingName,
            'newName': newName,
          });

          if (kDebugMode) {
            debugPrint(
              '?? MUDAN�A DE NOME: "$role" era "$existingName" ? agora "$newName"!',
            );
          }
        }
      }
    }

    return changes;
  }

  bool _looksLikePersonName(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return false;

    // v7.6.63: Valida��o estrutural simples (Gemini � o Casting Director)
    // Aceitar se parece nome pr�prio e n�o � palavra comum
    if (_isLikelyName(cleaned) && !_isCommonWord(cleaned)) {
      return true;
    }

    // Fallback: estrutura v�lida
    if (_hasValidNameStructure(cleaned) && !_isCommonWord(cleaned)) {
      return true;
    }

    return false;
  }

  /// v7.6.63: Valida��o simples de nome (aceita criatividade do LLM)
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

  /// ?? v7.6.17: Verifica estrutura v�lida de nome pr�prio
  bool _hasValidNameStructure(String name) {
    // M�nimo 2 caracteres, m�ximo 15
    if (name.length < 2 || name.length > 15) return false;

    // Primeira letra mai�scula
    if (name[0] != name[0].toUpperCase()) return false;

    // Resto em min�sculas (permite acentos)
    final rest = name.substring(1);
    if (rest != rest.toLowerCase()) return false;

    // Apenas letras (permite acentua��o)
    final validPattern = RegExp(r'^[A-Z�-�][a-z�-�]+$');
    return validPattern.hasMatch(name);
  }

  /// ?? v7.6.17: Verifica se � palavra comum (n�o-nome)
  bool _isCommonWord(String word) {
    final lower = word.toLowerCase();

    // Palavras comuns em m�ltiplos idiomas (sem duplica��es)
    final commonWords = {
      // Portugu�s
      'ent�o', 'quando', 'depois', 'antes', 'agora', 'hoje',
      'ontem', 'sempre', 'nunca', 'muito', 'pouco', 'nada',
      'tudo', 'algo', 'algu�m', 'ningu�m', 'mesmo', 'outra',
      'outro', 'cada', 'toda', 'todo', 'todos', 'onde', 'como',
      'porque', 'por�m', 'mas', 'para', 'com', 'sem', 'por',
      'sobre', 'entre', 'durante', 'embora', 'enquanto',
      // English
      'then', 'when', 'after', 'before', 'now', 'today',
      'yesterday', 'always', 'never', 'much', 'little', 'nothing',
      'everything', 'something', 'someone', 'nobody', 'same', 'other',
      'each', 'every', 'where', 'because', 'however', 'though',
      'while', 'about', 'between',
      // Espa�ol (apenas palavras exclusivas, sem sobreposi��o com PT/EN)
      'entonces', 'despu�s', 'ahora', 'hoy', 'ayer', 'siempre',
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

    // Pa�ses/lugares
    'brasil', 'portugal', 'portugues',

    // Pronomes e palavras comuns capitalizadas no in�cio de frases
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

    // Adv�rbios/conjun��es/preposi��es comuns no in�cio de frase
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

    // Preposi��es e artigos (raramente, mas podem aparecer)
    'com', 'sem', 'sobre', 'para', 'pela', 'pelo', 'uma', 'umas', 'uns', 'por',

    // ?? FIX CR�TICO: Palavras que a AI usou como NOMES FANTASMA (do roteiro analisado)
    'lagrimas',
    'l�grimas',
    'justica',
    'justi�a',
    'ponto',
    'semanas',
    'aconteceu',
    'todas', 'ajuda', 'consolo', 'vamos', 'conhe�o', 'conheco', 'lembra',

    // ?? v7.6.39: Palavras em ingl�s que N�O s�o nomes (evitar "Grand" etc.)
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

    // Verbos comuns no in�cio de frase (EXPANDIDO)
    'era', 'foi', 'seria', 'pode', 'podia', 'deve', 'devia',
    'senti', 'sentiu', 'pensei', 'pensou', 'vi', 'viu', 'ouvi', 'ouviu',
    'fiz', 'fez', 'disse', 'falou', 'quis', 'pude', 'p�de',
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
    'come�ou',
    'terminei',
    'terminou',
  };

  static String perspectiveLabel(String perspective) {
    final perspectiveLower = perspective.toLowerCase();

    // ?? FIX: Detectar primeira pessoa em qualquer formato
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

    // Terceira pessoa (padr�o)
    return 'Terceira pessoa';
  }

  // ?? CORRIGIDO: Instru��o CLARA de perspectiva com contexto do protagonista
  String _getPerspectiveInstruction(String perspective, ScriptConfig config) {
    final protagonistInfo = config.protagonistName.trim().isNotEmpty
        ? ' O protagonista � "${config.protagonistName}".'
        : '';

    // ?? FIX: Aceitar valores reais da interface (primeira_pessoa_*, terceira_pessoa)
    final perspectiveLower = perspective.toLowerCase();

    // ?? DETECTAR G�NERO DO NARRADOR BASEADO NA PERSPECTIVA
    if (perspectiveLower.contains('mulher')) {
      // FEMININO (ela)
    } else if (perspectiveLower.contains('homem')) {
      // MASCULINO (ele)
    }

    // Detectar primeira pessoa (qualquer varia��o)
    if (perspectiveLower.contains('primeira_pessoa') ||
        perspectiveLower == 'first') {
      // Definir pronomes baseado no tipo de primeira pessoa
      String pronomes = 'EU, MEU, MINHA, COMIGO';
      String exemplos =
          '"EU vendi a casa...", "MEU cora��o batia forte...", "COMIGO ela nunca foi honesta..."';
      String nomeInstrucao = '';

      if (perspectiveLower.contains('mulher')) {
        exemplos =
            '"EU vendi a casa...", "MINHA nora me traiu...", "COMIGO ela nunca foi honesta..."';

        // ?? DETECTAR FAIXA ET�RIA E ADICIONAR INSTRU��ES ESPEC�FICAS
        String idadeInstrucao = '';
        if (perspectiveLower.contains('jovem')) {
          idadeInstrucao = '''
????????????????????????????????????????????????????????????????????????
?? FAIXA ET�RIA OBRIGAT�RIA: MULHER JOVEM (20-35 ANOS)
????????????????????????????????????????????????????????????????????????

? IDADE CORRETA: Entre 20 e 35 anos
? PERFIL: Mulher adulta jovem, in�cio/meio da carreira, possivelmente casada/solteira, energ�tica
? CONTEXTO: Pode ter filhos pequenos, focada em crescimento profissional/pessoal
? VOCABUL�RIO: Moderno, atual, refer�ncias contempor�neas

? PROIBIDO: Mencionar aposentadoria, netos, mem�rias de d�cadas atr�s
????????????????????????????????????????????????????????????????????????
''';
        } else if (perspectiveLower.contains('madura')) {
          idadeInstrucao = '''
????????????????????????????????????????????????????????????????????????
?? FAIXA ET�RIA OBRIGAT�RIA: MULHER MADURA (35-50 ANOS)
????????????????????????????????????????????????????????????????????????

? IDADE CORRETA: Entre 35 e 50 anos
? PERFIL: Mulher experiente, consolidada profissionalmente, possivelmente com filhos adolescentes
? CONTEXTO: Pode ter div�rcio, segundo casamento, filhos crescidos, auge da carreira
? VOCABUL�RIO: Equilibrado, maduro, experiente mas ainda contempor�neo

? PROIBIDO: Mencionar aposentadoria, netos adultos, velhice
????????????????????????????????????????????????????????????????????????
''';
        } else if (perspectiveLower.contains('idosa')) {
          idadeInstrucao = '''
????????????????????????????????????????????????????????????????????????
?? FAIXA ET�RIA OBRIGAT�RIA: MULHER IDOSA (50+ ANOS)
????????????????????????????????????????????????????????????????????????

? IDADE CORRETA: Acima de 50 anos
? PERFIL: Mulher com muita experi�ncia de vida, possivelmente aposentada ou perto
? CONTEXTO: Pode ter netos, viuvez, legado familiar, reflex�es sobre a vida
? VOCABUL�RIO: S�bio, reflexivo, com hist�rias de d�cadas atr�s

? PROIBIDO: Agir como jovem, usar g�rias recentes inadequadas � idade
????????????????????????????????????????????????????????????????????????
''';
        }

        nomeInstrucao =
            '''
+------------------------------------------------------------------------------+
� ?????? G�NERO OBRIGAT�RIO: FEMININO (MULHER) - CONFIGURA��O DO USU�RIO ?????? �
+------------------------------------------------------------------------------+

?????? REGRA ABSOLUTA - N�O NEGOCI�VEL ??????

O USU�RIO CONFIGUROU EXPLICITAMENTE: "Primeira Pessoa MULHER"
VOC� DEVE, OBRIGATORIAMENTE, GERAR UM PROTAGONISTA FEMININO!

?? VALIDA��O ANTES DE ESCREVER A PRIMEIRA FRASE:
? "O protagonista que vou criar � MULHER?" 
   ? Se SIM = Prossiga
   ? Se N�O = PARE! Voc� est� DESOBEDECENDO a configura��o do usu�rio!

????????????????????????????????????????????????????????????????????????

?? REGRAS DE NOMES:

1?? SE O T�TULO MENCIONAR UM NOME ESPEC�FICO (ex: "Voc� � Maria?"):
   ? USE ESTE NOME para a protagonista
   ? Exemplo: Se t�tulo diz "Maria", protagonista � "Maria"

2?? SE O T�TULO N�O MENCIONAR NENHUM NOME (ex: "Un milliardaire m'a donn�..."):
   ? VOC� DEVE CRIAR um nome FEMININO apropriado para o idioma
   
   ?? Nomes femininos por idioma:
   � Fran�ais: Sophie, Marie, Am�lie, Claire, Camille, Emma, Louise, Chlo�
   � Portugu�s: Maria, Ana, Sofia, Helena, Clara, Beatriz, Julia, Laura
   � English: Emma, Sarah, Jennifer, Emily, Jessica, Ashley, Michelle, Amanda
   � Espa�ol: Mar�a, Carmen, Laura, Ana, Isabel, Rosa, Elena, Sofia
   � ??? (Korean): Kim Ji-young, Park Soo-yeon, Lee Min-ji, Choi Hye-jin, Jung Yoo-na
     ?? COREANO: SEMPRE use SOBRENOME + NOME (ex: "Kim Ji-young", N�O "Ji-young")
   
   ? PROIBIDO: Jo�o, Pedro, Carlos, Michael, Roberto, Pierre, Jean, Marc
   ? JAMAIS use nomes MASCULINOS quando o narrador � MULHER!

$idadeInstrucao

?? SE VOC� CRIAR UM PROTAGONISTA MASCULINO, O ROTEIRO SER� REJEITADO!
????????????????????????????????????????????????????????????????????????

''';
      } else if (perspectiveLower.contains('homem')) {
        exemplos =
            '"EU constru� esse neg�cio...", "MEU filho me abandonou...", "COMIGO ele sempre foi desleal..."';

        // ?? DETECTAR FAIXA ET�RIA E ADICIONAR INSTRU��ES ESPEC�FICAS
        String idadeInstrucao = '';
        if (perspectiveLower.contains('jovem')) {
          idadeInstrucao = '''
????????????????????????????????????????????????????????????????????????
?? FAIXA ET�RIA OBRIGAT�RIA: HOMEM JOVEM (20-35 ANOS)
????????????????????????????????????????????????????????????????????????

? IDADE CORRETA: Entre 20 e 35 anos
? PERFIL: Homem adulto jovem, in�cio/meio da carreira, possivelmente casado/solteiro, energ�tico
? CONTEXTO: Pode ter filhos pequenos, focado em crescimento profissional/pessoal
? VOCABUL�RIO: Moderno, atual, refer�ncias contempor�neas

? PROIBIDO: Mencionar aposentadoria, netos, mem�rias de d�cadas atr�s
????????????????????????????????????????????????????????????????????????
''';
        } else if (perspectiveLower.contains('maduro')) {
          idadeInstrucao = '''
????????????????????????????????????????????????????????????????????????
?? FAIXA ET�RIA OBRIGAT�RIA: HOMEM MADURO (35-50 ANOS)
????????????????????????????????????????????????????????????????????????

? IDADE CORRETA: Entre 35 e 50 anos
? PERFIL: Homem experiente, consolidado profissionalmente, possivelmente com filhos adolescentes
? CONTEXTO: Pode ter div�rcio, segundo casamento, filhos crescidos, auge da carreira
? VOCABUL�RIO: Equilibrado, maduro, experiente mas ainda contempor�neo

? PROIBIDO: Mencionar aposentadoria, netos adultos, velhice
????????????????????????????????????????????????????????????????????????
''';
        } else if (perspectiveLower.contains('idoso')) {
          idadeInstrucao = '''
????????????????????????????????????????????????????????????????????????
?? FAIXA ET�RIA OBRIGAT�RIA: HOMEM IDOSO (50+ ANOS)
????????????????????????????????????????????????????????????????????????

? IDADE CORRETA: Acima de 50 anos
? PERFIL: Homem com muita experi�ncia de vida, possivelmente aposentado ou perto
? CONTEXTO: Pode ter netos, viuvez, legado familiar, reflex�es sobre a vida
? VOCABUL�RIO: S�bio, reflexivo, com hist�rias de d�cadas atr�s

? PROIBIDO: Agir como jovem, usar g�rias recentes inadequadas � idade
????????????????????????????????????????????????????????????????????????
''';
        }

        nomeInstrucao =
            '''
+------------------------------------------------------------------------------+
� ?????? G�NERO OBRIGAT�RIO: MASCULINO (HOMEM) - CONFIGURA��O DO USU�RIO ?????? �
+------------------------------------------------------------------------------+

?????? REGRA ABSOLUTA - N�O NEGOCI�VEL ??????

O USU�RIO CONFIGUROU EXPLICITAMENTE: "Primeira Pessoa HOMEM"
VOC� DEVE, OBRIGATORIAMENTE, GERAR UM PROTAGONISTA MASCULINO!

?? VALIDA��O ANTES DE ESCREVER A PRIMEIRA FRASE:
? "O protagonista que vou criar � HOMEM?" 
   ? Se SIM = Prossiga
   ? Se N�O = PARE! Voc� est� DESOBEDECENDO a configura��o do usu�rio!

????????????????????????????????????????????????????????????????????????

?? REGRAS DE NOMES:

1?? SE O T�TULO MENCIONAR UM NOME ESPEC�FICO (ex: "Voc� � Michael?"):
   ? USE ESTE NOME para o protagonista
   ? Exemplo: Se t�tulo diz "Michael", protagonista � "Michael"

2?? SE O T�TULO N�O MENCIONAR NENHUM NOME (ex: "Un milliardaire m'a donn�..."):
   ? VOC� DEVE CRIAR um nome MASCULINO apropriado para o idioma
   
   ?? Nomes masculinos por idioma:
   � Fran�ais: Pierre, Jean, Marc, Luc, Antoine, Thomas, Nicolas, Julien
   � Portugu�s: Jo�o, Pedro, Carlos, Roberto, Alberto, Paulo, Fernando, Ricardo
   � English: John, Michael, David, James, Robert, William, Richard, Thomas
   � Espa�ol: Juan, Pedro, Carlos, Jos�, Luis, Miguel, Antonio, Francisco
   � ??? (Korean): Kim Seon-woo, Park Jae-hyun, Lee Min-ho, Choi Dong-wook, Jung Tae-hyun
     ?? COREANO: SEMPRE use SOBRENOME + NOME (ex: "Kim Seon-woo", N�O "Seon-woo")
   
   ? PROIBIDO: Maria, Ana, Sofia, Sophie, M�nica, Clara, Helena, Emma
   ? JAMAIS use nomes FEMININOS quando o narrador � HOMEM!

$idadeInstrucao

?? SE VOC� CRIAR UM PROTAGONISTA FEMININO, O ROTEIRO SER� REJEITADO!
????????????????????????????????????????????????????????????????????????

''';
      }

      return '''PERSPECTIVA NARRATIVA: PRIMEIRA PESSOA$protagonistInfo
$nomeInstrucao
?? CR�TICO: O PROTAGONISTA conta SUA PR�PRIA HIST�RIA usando "$pronomes".
?? PROIBIDO usar "ELE", "ELA", "DELE", "DELA" para o protagonista!
? CORRETO: $exemplos
O protagonista � o narrador. Ele/Ela est� contando os eventos da SUA perspectiva em primeira pessoa.''';
    }

    // Terceira pessoa (padr�o)
    return '''PERSPECTIVA NARRATIVA: TERCEIRA PESSOA$protagonistInfo
?? IMPORTANTE: Um NARRADOR EXTERNO conta a hist�ria do protagonista usando "ELE", "ELA", "DELE", "DELA".
Exemplo: "ELA vendeu a casa...", "O cora��o DELE batia forte...", "COM ELA, ningu�m foi honesto...".
O narrador observa e conta, mas N�O � o protagonista.''';
  }

  /// ?? OTIMIZA��O: Limita contexto aos �ltimos blocos para evitar timeouts
  /// Mant�m apenas os �ltimos N blocos + resumo inicial para continuidade
  String _buildLimitedContext(
    String fullContext,
    int currentBlock,
    int maxRecentBlocks,
  ) {
    if (fullContext.isEmpty || currentBlock <= maxRecentBlocks) {
      return fullContext; // Blocos iniciais usam tudo
    }

    // ?? LIMITE ABSOLUTO OTIMIZADO: Reduzido para evitar timeout em idiomas pesados
    // ?? CR�TICO: 5.6k palavras causava timeout API 503 nos blocos 7-8
    // 3.5k palavras = ~21k caracteres cir�lico (mais seguro para Gemini)
    const maxContextWords = 3500; // REDUZIDO de 4500 para 3500
    final currentWords = _countWords(fullContext);

    if (currentWords <= maxContextWords) {
      return fullContext; // Contexto ainda est� em tamanho seguro
    }

    // Separar em blocos (par�grafos duplos ou mais)
    final blocks = fullContext.split(RegExp(r'\n{2,}'));
    if (blocks.length <= maxRecentBlocks + 5) {
      return fullContext; // Ainda n�o tem muitos blocos
    }

    // Pegar resumo inicial (primeiros 3 par�grafos - REDUZIDO de 5 para 3)
    final initialSummary = blocks.take(3).join('\n\n');

    // Pegar �ltimos N blocos completos (REDUZIDO multiplicador de 5 para 3)
    final recentBlocks = blocks
        .skip(max(0, blocks.length - maxRecentBlocks * 3))
        .join('\n\n');

    final result = '$initialSummary\n\n[...]\n\n$recentBlocks';

    // Verificar se ainda est� muito grande
    if (_countWords(result) > maxContextWords) {
      // Reduzir ainda mais - s� �ltimos blocos (REDUZIDO multiplicador de 3 para 2)
      return blocks
          .skip(max(0, blocks.length - maxRecentBlocks * 2))
          .join('\n\n');
    }

    return result;
  }

  // ?? MULTIPLICADORES DE VERBOSIDADE POR IDIOMA
  // Baseado em an�lise de quantas palavras cada idioma precisa para expressar a mesma ideia
  // Portugu�s = 1.0 (baseline) funciona perfeitamente
  double _getLanguageVerbosityMultiplier(String language) {
    final normalized = language.toLowerCase().trim();

    // ???? ESPANHOL: Tende a ser ~15-20% mais verboso que portugu�s
    if (normalized.contains('espanhol') ||
        normalized.contains('spanish') ||
        normalized.contains('espa�ol') ||
        normalized == 'es' ||
        normalized == 'es-mx') {
      return 0.85; // Pedir 15% menos para compensar
    }

    // ???? INGL�S: Tende a ser ~15-20% mais CONCISO que portugu�s
    // RAZ�O: Ingl�s usa menos palavras para expressar mesma ideia
    // EXEMPLO: "Eu estava pensando nisso" = 4 palavras ? "I was thinking" = 3 palavras
    // SOLU��O: Pedir um pouco MAIS palavras para compensar a concis�o
    // ?? AJUSTE: Reduzido de 1.18x ? 1.05x (estava gerando +21% a mais)
    if (normalized.contains('ingl�s') ||
        normalized.contains('ingles') ||
        normalized.contains('english') ||
        normalized == 'en' ||
        normalized == 'en-us') {
      return 1.05; // Pedir 5% MAIS para compensar concis�o
    }

    // ???? FRANC�S: Tende a ser ~10-15% mais verboso que portugu�s
    if (normalized.contains('franc') ||
        normalized.contains('french') ||
        normalized == 'fr') {
      return 0.90; // Pedir 10% menos para compensar
    }

    // ???? ITALIANO: Tende a ser ~10% mais verboso que portugu�s
    if (normalized.contains('italia') ||
        normalized.contains('italian') ||
        normalized == 'it') {
      return 0.92; // Pedir 8% menos para compensar
    }

    // ???? ALEM�O: Similar ao portugu�s (palavras compostas compensam artigos)
    if (normalized.contains('alem') ||
        normalized.contains('german') ||
        normalized == 'de') {
      return 1.0; // Sem ajuste
    }

    // ???? RUSSO: Muito conciso (sem artigos, casos gramaticais)
    if (normalized.contains('russo') ||
        normalized.contains('russian') ||
        normalized == 'ru') {
      return 1.15; // Pedir 15% mais para compensar
    }

    // ???? POLON�S: Ligeiramente mais conciso que portugu�s
    if (normalized.contains('polon') ||
        normalized.contains('polish') ||
        normalized == 'pl') {
      return 1.05; // Pedir 5% mais para compensar
    }

    // ???? TURCO: Muito conciso (aglutina��o de palavras)
    if (normalized.contains('turco') ||
        normalized.contains('turk') ||
        normalized == 'tr') {
      return 1.20; // Pedir 20% mais para compensar
    }

    // ???? B�LGARO: Similar ao russo, conciso
    if (normalized.contains('b�lgar') ||
        normalized.contains('bulgar') ||
        normalized == 'bg') {
      return 1.12; // Pedir 12% mais para compensar
    }

    // ???? CROATA: Ligeiramente mais conciso
    if (normalized.contains('croat') ||
        normalized.contains('hrvat') ||
        normalized == 'hr') {
      return 1.08; // Pedir 8% mais para compensar
    }

    // ???? ROMENO: Similar ao portugu�s (l�ngua latina)
    if (normalized.contains('romen') ||
        normalized.contains('roman') ||
        normalized == 'ro') {
      return 1.0; // Sem ajuste
    }

    // ???? COREANO: Muito conciso (aglutina��o) + Modelo tende a ser pregui�oso
    // AN�LISE: Pedindo 1.0x, ele entrega ~70% da meta.
    // SOLU��O: Pedir 1.55x (55% a mais) para for�ar expans�o ou atingir o teto natural.
    if (normalized.contains('coreano') ||
        normalized.contains('korean') ||
        normalized.contains('???') ||
        normalized == 'ko') {
      return 1.55;
    }

    // ???? PORTUGU�S ou OUTROS: Baseline perfeito
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
        false, // ?? NOVO: Flag para regenera��o anti-repeti��o
    WorldState? worldState, // ??? v7.6.64: Usa WorldState do m�dulo (SOLID)
  }) async {
    // ?? IMPORTANTE: target vem SEMPRE em PALAVRAS de _calculateTargetForBlock()
    // Mesmo quando measureType='caracteres', _calculateTargetForBlock j� converteu caracteres?palavras
    // O Gemini trabalha melhor com contagem de PALAVRAS, ent�o sempre pedimos palavras no prompt
    // Depois contamos caracteres no resultado final para validar se atingiu a meta do usu�rio
    final needed = target;
    if (needed <= 0) return '';

    // ?? OTIMIZA��O CR�TICA: Limitar contexto aos �ltimos N blocos
    // v6.0: Portugu�s usa MENOS contexto (3 blocos) para evitar erro 503
    // Outros idiomas: 4 blocos (padr�o)
    // RATIONALE: Portugu�s = mais tokens ? precisa contexto menor
    final isPortuguese = c.language.toLowerCase().contains('portugu');
    final maxContextBlocks = isPortuguese
        ? 3
        : 4; // PORTUGU�S: 3 blocos (era 4)

    // Blocos iniciais (1-4): contexto completo
    // Blocos m�dios/finais (5+): �ltimos N blocos apenas
    String contextoPrevio = previous.isEmpty
        ? ''
        : _buildLimitedContext(previous, blockNumber, maxContextBlocks);

    if (kDebugMode && previous.isNotEmpty) {
      final contextUsed = contextoPrevio.length;
      final contextType = blockNumber <= maxContextBlocks
          ? 'COMPLETO'
          : 'LIMITADO (�ltimos $maxContextBlocks blocos)';
      debugPrint(
        '?? CONTEXTO $contextType: $contextUsed chars (${_countWords(contextoPrevio)} palavras)',
      );
      if (blockNumber > maxContextBlocks) {
        debugPrint(
          '   Original: ${previous.length} chars ? Reduzido: $contextUsed chars (${((1 - contextUsed / previous.length) * 100).toStringAsFixed(0)}% menor)',
        );
      }
    }

    // ?? SOLU��O 3: Refor�ar os nomes confirmados no prompt para manter consist�ncia
    String trackerInfo = '';

    // ?? v7.6.36: LEMBRETE CR�TICO DE NOMES - Muito mais agressivo!
    // Aparece no IN�CIO de cada bloco para evitar que Gemini "esque�a" nomes
    if (tracker.confirmedNames.isNotEmpty && blockNumber > 1) {
      final nameReminder = StringBuffer();
      nameReminder.writeln('');
      nameReminder.writeln(
        '????????????????????????????????????????????????????????????',
      );
      nameReminder.writeln(
        '?? LEMBRETE OBRIGAT�RIO DE NOMES - LEIA ANTES DE CONTINUAR! ??',
      );
      nameReminder.writeln(
        '????????????????????????????????????????????????????????????',
      );
      nameReminder.writeln('');
      nameReminder.writeln(
        '?? PERSONAGENS DESTA HIST�RIA (USE SEMPRE ESTES NOMES):',
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

      // Adicionar protagonista de forma EXTRA enf�tica
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

      // Listar mapeamento reverso (papel ? nome) para refor�ar
      final roleMap = tracker.roleToNameMap;
      if (roleMap.isNotEmpty) {
        nameReminder.writeln('?? MAPEAMENTO PAPEL ? NOME (CONSULTE SEMPRE):');
        for (final entry in roleMap.entries) {
          nameReminder.writeln('   � ${entry.key} ? ${entry.value}');
        }
        nameReminder.writeln('');
      }

      nameReminder.writeln(
        '?? SE VOC� TROCAR UM NOME, O ROTEIRO SER� REJEITADO! ??',
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
          '\n?? NOMES J� USADOS - NUNCA REUTILIZE: ${tracker.confirmedNames.join(", ")}\n';
      trackerInfo +=
          '?? Se precisa de novo personagem, use NOME TOTALMENTE DIFERENTE!\n';

      final mapping = tracker.getCharacterMapping();
      if (mapping.isNotEmpty) {
        trackerInfo += mapping;
        trackerInfo +=
            '\n?? REGRA CR�TICA: NUNCA use o mesmo nome para personagens diferentes!\n';
      }
    }

    // ?? CORRE��O CR�TICA: SEMPRE injetar nome da protagonista, mesmo que n�o esteja no tracker
    final protagonistName = c.protagonistName.trim();
    if (protagonistName.isNotEmpty && !trackerInfo.contains(protagonistName)) {
      trackerInfo +=
          '\n?? ATEN��O ABSOLUTA: O NOME DA PROTAGONISTA � "$protagonistName"!\n';
      trackerInfo += '   ? NUNCA mude para outro nome (Wanessa, Carla, etc)\n';
      trackerInfo +=
          '   ? SEMPRE use "$protagonistName" quando se referir � protagonista!\n';
    }
    final characterGuidance = _buildCharacterGuidance(c, tracker);

    // ?? v7.6.52: WORLD STATE CONTEXT - Mem�ria Infinita
    // Adiciona contexto estruturado de personagens, invent�rio e fatos
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
    // O Gemini funciona melhor com targets de PALAVRAS, n�o caracteres
    // Limite m�ximo: 3500 palavras/bloco (� 19.250 caracteres)
    final limitedNeeded = min(needed, 3500); // Sempre limitar em palavras

    // ?? SEMPRE pedir palavras no prompt (Gemini trabalha melhor assim)
    // O sistema converter� caracteres?palavras antes de chegar aqui (_calculateTargetForBlock)
    // E validar� caracteres no resultado final

    // ?? AJUSTE POR IDIOMA: Compensar verbosidade natural de cada idioma
    // Portugu�s (baseline 1.0) funciona perfeitamente, outros ajustam proporcionalmente
    final languageMultiplier = _getLanguageVerbosityMultiplier(c.language);
    final adjustedTarget = (limitedNeeded * languageMultiplier).round();

    // Detectar se � espanhol para mensagem espec�fica
    final isSpanish =
        c.language.toLowerCase().contains('espanhol') ||
        c.language.toLowerCase().contains('spanish') ||
        c.language.toLowerCase().contains('espa�ol');

    // ?? CONTROLE RIGOROSO DE CONTAGEM: �8% aceit�vel (ajustado de �10%)
    // RAZ�O: Multiplicador 1.08 deve manter resultado entre 92-108% da meta
    final minAcceptable = (adjustedTarget * 0.92).round();
    final maxAcceptable = (adjustedTarget * 1.08).round();

    final measure = isSpanish
        ? 'GERE EXATAMENTE $adjustedTarget palabras (M�NIMO $minAcceptable, M�XIMO $maxAcceptable). � MELHOR ficar perto de $adjustedTarget do que muito abaixo!'
        : 'GERE EXATAMENTE $adjustedTarget palavras (M�NIMO $minAcceptable, M�XIMO $maxAcceptable). � MELHOR ficar perto de $adjustedTarget do que muito abaixo!';
    final localizationGuidance = _buildLocalizationGuidance(c);
    final narrativeStyleGuidance = _getNarrativeStyleGuidance(c);

    // ?? DEBUG: Verificar se modo GLOBAL est� sendo passado corretamente
    if (kDebugMode) {
      debugPrint('?? MODO DE LOCALIZA��O: ${c.localizationLevel.displayName}');
      if (c.localizationLevel == LocalizationLevel.global) {
        debugPrint(
          '? MODO GLOBAL ATIVO - Prompt deve evitar nomes/comidas brasileiras',
        );
        debugPrint(
          '?? Preview do prompt GLOBAL: ${localizationGuidance.substring(0, min(200, localizationGuidance.length))}...',
        );
      }
    }

    // ?? INTEGRAR T�TULO COMO HOOK IMPACTANTE NO IN�CIO
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

    // v7.6.63: Gemini � o Casting Director - cria nomes apropriados para o idioma
    // Removido banco de nomes est�tico em favor de gera��o din�mica via LLM
    final nameList = ''; // N�o mais necess�rio - LLM gera nomes contextualmente

    // ?? Obter labels traduzidos para os metadados
    final labels = _getMetadataLabels(c.language);

    //  Definir se inclui tema/subtema ou modo livre
    final temaSection = c.tema == 'Livre (Sem Tema)'
        ? '// Modo Livre: Desenvolva o roteiro baseado APENAS no t�tulo e contexto fornecidos\n'
        : '${labels['theme']}: ${c.tema}\n${labels['subtheme']}: ${c.subtema}\n';

    // ?? v7.6.44: SEMPRE incluir t�tulo como base da hist�ria
    // O t�tulo N�O � apenas decorativo - � a PREMISSA da hist�ria!
    final titleSection = c.title.trim().isNotEmpty
        ? '\n????????????????????????????????????????????????????\n'
              '?? T�TULO/PREMISSA OBRIGAT�RIA DA HIST�RIA:\n'
              '????????????????????????????????????????????????????\n'
              '"${c.title}"\n'
              '\n'
              '?? REGRA ABSOLUTA:\n'
              '   � A hist�ria DEVE desenvolver os elementos deste t�tulo\n'
              '   � Personagens, a��es e contexto do t�tulo s�o OBRIGAT�RIOS\n'
              '   � N�O invente uma hist�ria diferente da proposta no t�tulo\n'
              '   � O t�tulo � a PROMESSA feita ao espectador - CUMPRA-A!\n'
              '\n'
              '?? EXEMPLOS:\n'
              '   ? T�tulo: "?? ?? ???? ???? ??? ??? ???"\n'
              '      ? Hist�ria DEVE ter: funcion�rio de conveni�ncia + idoso faminto + marmita compartilhada\n'
              '   \n'
              '   ? T�tulo: "Bilion�rio me ofereceu emprego ap�s eu ajudar um mendigo"\n'
              '      ? Hist�ria DEVE ter: protagonista + mendigo ajudado + revela��o (mendigo = bilion�rio)\n'
              '   \n'
              '   ? ERRO: Ignorar t�tulo e criar hist�ria sobre CEO infiltrado em empresa\n'
              '      ? Isso QUEBRA a promessa feita ao espectador!\n'
              '????????????????????????????????????????????????????\n\n'
        : '';

    // ?? CONSTRUIR LISTA DE NOMES PROIBIDOS (j� usados nesta hist�ria)
    String forbiddenNamesWarning = '';
    if (tracker.confirmedNames.isNotEmpty) {
      final forbiddenList = tracker.confirmedNames.join(', ');
      forbiddenNamesWarning =
          '?????? NOMES PROIBIDOS - N�O USE ESTES NOMES! ??????\n'
          '????????????????????????????????????????????????????\n'
          '? Os seguintes nomes J� EST�O EM USO nesta hist�ria:\n'
          '   ? $forbiddenList\n'
          '\n'
          '?? REGRA ABSOLUTA:\n'
          '   � NUNCA reutilize os nomes acima!\n'
          '   � Cada nome = 1 personagem �nico\n'
          '   � Se precisar de novo personagem, escolha nome DIFERENTE\n'
          '????????????????????????????????????????????????????\n'
          '\n';
    }

    // ?? Adicionar informa��es espec�ficas de blocos (n�o estava no template)
    // ?? v7.6.22: Adicionar lista de personagens sem fechamento no bloco final
    String closureWarning = '';
    if (blockNumber == totalBlocks) {
      final unresolved = tracker.getUnresolvedCharacters();
      if (unresolved.isNotEmpty) {
        closureWarning =
            '\n'
            '?????? ATEN��O CR�TICA - BLOCO FINAL ??????\n'
            '\n'
            '?? OS SEGUINTES PERSONAGENS AINDA N�O TIVERAM FECHAMENTO:\n'
            '   ${unresolved.map((name) => '� $name').join('\n   ')}\n'
            '\n'
            '? VOC� DEVE INCLUIR NESTE BLOCO FINAL:\n'
            '   Para CADA personagem acima, escreva:\n'
            '   1. O que aconteceu com ele/ela no final\n'
            '   2. Seu estado emocional/f�sico final\n'
            '   3. Resolu��o do seu arco narrativo\n'
            '\n'
            '?? EXEMPLOS DE FECHAMENTO CORRETO:\n'
            '   � "Blake finalmente reconciliou com Taylor"\n'
            '   � "Nicholas viu justi�a ser feita contra Arthur"\n'
            '   � "Robert encontrou paz sabendo que a verdade veio � tona"\n'
            '\n'
            '? N�O � PERMITIDO:\n'
            '   � Terminar a hist�ria sem mencionar esses personagens\n'
            '   � Deixar seus destinos vagos ou impl�citos\n'
            '   � Assumir que o leitor "vai entender"\n'
            '\n'
            '?? REGRA: Personagem importante = Fechamento expl�cito OBRIGAT�RIO\n'
            '????????????????????????????????????????????????????\n'
            '\n';
      } else {
        if (kDebugMode) {
          debugPrint('? TODOS os personagens importantes j� t�m fechamento!');
          debugPrint(
            '   Taxa de fechamento: ${(tracker.getClosureRate() * 100).toStringAsFixed(1)}%',
          );
        }
      }
    }

    final blockInfo =
        '\n'
        '????????????????????????????????????????????????????\n'
        '?? INFORMA��O DE BLOCOS (CR�TICO PARA PLANEJAMENTO):\n'
        '????????????????????????????????????????????????????\n'
        '   � Total de blocos planejados: $totalBlocks\n'
        '   � Bloco atual: bloco n�mero $blockNumber de $totalBlocks\n'
        '   ${blockNumber < totalBlocks ? '� Status: CONTINUA��O - Este N�O � o �ltimo bloco!' : '� Status: BLOCO FINAL - Conclua a hist�ria agora!'}\n'
        '\n'
        '$closureWarning'
        '${blockNumber < totalBlocks ? '? PROIBIDO NESTE BLOCO:\n   � N�O finalize a hist�ria ainda!\n   � N�O escreva "THE END" ou equivalente\n   � N�O crie uma resolu��o completa e definitiva\n   � N�O conclua todos os arcos narrativos\n   \n? OBRIGAT�RIO NESTE BLOCO:\n   � CONTINUE desenvolvendo a trama\n   � Mantenha tens�o e progress�o narrativa\n   � Deixe ganchos para os pr�ximos blocos\n   � A hist�ria DEVE ter continua��o nos blocos seguintes\n   � Apenas desenvolva, N�O conclua!\n' : '? OBRIGAT�RIO NESTE BLOCO FINAL:\n   � AGORA SIM finalize completamente a hist�ria\n   � Resolva TODOS os conflitos pendentes\n   � D� fechamento a TODOS os personagens\n   � Este � o �LTIMO bloco - conclus�o definitiva!\n'}\n'
        '? ATEN��O ESPECIAL:\n'
        '   � Hist�rias longas precisam de TODOS os blocos planejados\n'
        '   � N�O termine prematuramente s� porque "parece completo"\n'
        '   � Cada bloco � parte de um roteiro maior - respeite o planejamento\n'
        '   � Finais prematuros PREJUDICAM a qualidade e a experi�ncia do ouvinte\n'
        '????????????????????????????????????????????????????\n'
        '\n'
        '?? REGRA ABSOLUTA:\n'
        '   UMA HIST�RIA = UM CONFLITO CENTRAL = UM ARCO COMPLETO = UMA RESOLU��O\n'
        '   PAR�GRAFOS CURTOS = PAUSAS = DRAMATICIDADE = RETEN��O ALTA\n'
        '   UM NOME = UM PERSONAGEM = NUNCA REUTILIZAR = VERIFICAR SEMPRE\n'
        '   DI�LOGOS + MOTIVA��ES + CLOSURE = HIST�RIA COMPLETA E SATISFAT�RIA\n'
        '\n'
        '?? NUNCA crie duas hist�rias separadas dentro do mesmo roteiro!\n'
        '?? NUNCA escreva par�grafos com mais de 180 palavras!\n'
        '?? NUNCA reutilize nomes de personagens j� mencionados!\n'
        '?? NUNCA deixe personagens importantes sem destino final!\n'
        '?? NUNCA fa�a trai��es/conflitos sem motiva��o clara!\n'
        '?? NUNCA repita a mesma frase/met�fora mais de 2 vezes no roteiro!\n'
        '?? NUNCA introduza personagens secund�rios que desaparecem sem explica��o!\n'
        '${blockNumber < totalBlocks ? '?? NUNCA finalize a hist�ria antes do bloco final ($totalBlocks)!\n' : ''}'
        '\n'
        '?? REGRAS DE REPETI��O E VARIA��O:\n'
        '   � Frases marcantes do protagonista: m�ximo 2 repeti��es no roteiro inteiro\n'
        '   � Ap�s primeira men��o: use VARIA��ES ou refer�ncias INDIRETAS\n'
        '   � Exemplo: "lies are like cracks" ? depois: "his foundation was crumbling" ou "the truth had started to show"\n'
        '   � Met�foras do pai/mentor: primeira vez completa, depois apenas alus�es\n'
        '   � Evite eco narrativo: n�o repita descri��es j� feitas (humilha��o inicial, etc.)\n'
        '\n'
        '?? REGRAS DE PERSONAGENS SECUND�RIOS:\n'
        '   � TODO personagem introduzido DEVE ter resolu��o clara:\n'
        '   � Se aparece na investiga��o ? DEVE aparecer no cl�max/desfecho\n'
        '   � Se fornece informa��o crucial ? DEVE testemunhar/ajudar no final\n'
        '   � Se � v�tima/testemunha do passado ? DEVE ter papel na justi�a/vingan�a\n'
        '   � PROIBIDO: introduzir personagem importante e depois abandon�-lo\n'
        '   � Exemplo: Se Robert Peterson revela segredo ? ele DEVE aparecer no tribunal/confronto final\n'
        '\n'
        '   ?? LISTA DE VERIFICA��O ANTES DO BLOCO FINAL:\n'
        '   \n'
        '   Personagens que N�O PODEM desaparecer:\n'
        '   ? Quem forneceu evid�ncia crucial (documentos, testemunho)\n'
        '   ? Quem foi v�tima do antagonista no passado\n'
        '   ? Quem ajudou o protagonista na investiga��o\n'
        '   ? Quem tem conhecimento direto do crime/segredo\n'
        '   ? Familiar/amigo importante mencionado m�ltiplas vezes\n'
        '   \n'
        '   ?? EXEMPLOS DE FECHAMENTO OBRIGAT�RIO:\n'
        '   \n'
        '   ? Se "Robert revelou que seu pai Harold foi enganado":\n'
        '      ? No cl�max: "Robert entrou no tribunal. Olhou Alan nos olhos..."\n'
        '      ? No desfecho: "Robert finalmente tinha paz. A verdade sobre Harold veio � tona."\n'
        '   \n'
        '   ? Se "Kimberly, a paralegal, guardou c�pias dos documentos":\n'
        '      ? No cl�max: "Kimberly testemunhou. \'Alan me ordenou falsificar a assinatura\'..."\n'
        '      ? No desfecho: "Kimberly foi elogiada por sua coragem em preservar as evid�ncias."\n'
        '   \n'
        '   ? Se "David, o contador, descobriu a fraude primeiro":\n'
        '      ? No cl�max: "David apresentou os registros financeiros alterados..."\n'
        '      ? No desfecho: "David foi promovido a CFO ap�s a queda de Alan."\n'
        '   \n'
        '   ? NUNCA fa�a isso:\n'
        '      � "Robert me deu o documento" ? [nunca mais mencionado] ? ERRO!\n'
        '      � "Kimberly tinha as provas" ? [some da hist�ria] ? ERRO!\n'
        '      � "David descobriu tudo" ? [n�o aparece no final] ? ERRO!\n'
        '\n'
        '? REGRAS DE MARCADORES TEMPORAIS:\n'
        '   � Entre mudan�as de cena/localiza��o: SEMPRE incluir marcador temporal\n'
        '   � Exemplos: "tr�s dias depois...", "na manh� seguinte...", "uma semana se passou..."\n'
        '   � Flashbacks: iniciar com "anos atr�s..." ou "naquele dia em [ano]..."\n'
        '   � Saltos grandes (meses/anos): ser espec�fico: "seis meses depois" n�o "algum tempo depois"\n'
        '   � Isso mant�m o leitor orientado na linha temporal da hist�ria\n'
        '\n'
        '??????????? REGRAS DE COER�NCIA DE RELACIONAMENTOS FAMILIARES:\n'
        '   ?? ERRO CR�TICO: Relacionamentos familiares inconsistentes!\n'
        '   \n'
        '   ANTES de introduzir QUALQUER rela��o familiar, VALIDE:\n'
        '   \n'
        '   ? CORRETO - L�gica familiar coerente:\n'
        '      � "meu irm�o Paul casou com Megan" ? Megan � minha CUNHADA\n'
        '      � "Paul � meu irm�o" + "Megan � esposa de Paul" = "Megan � minha cunhada"\n'
        '      � "minha irm� Maria casou com Jo�o" ? Jo�o � meu CUNHADO\n'
        '   \n'
        '   ? ERRADO - Contradi��es:\n'
        '      � Chamar de "my sister-in-law" (cunhada) E depois "my brother married her" ? CONFUSO!\n'
        '      � "meu sogro Carlos" mas nunca mencionar c�njuge ? QUEM � casado com filho/filha dele?\n'
        '      � "my father-in-law Alan" mas protagonista solteiro ? IMPOSS�VEL!\n'
        '   \n'
        '   ?? TABELA DE VALIDA��O (USE ANTES DE ESCREVER):\n'
        '   \n'
        '   SE escrever: "my brother Paul married Megan"\n'
        '   ? Megan �: "my sister-in-law" (cunhada)\n'
        '   ? Alan (pai de Megan) �: "my brother\'s father-in-law" (sogro do meu irm�o)\n'
        '   ? NUNCA chamar Alan de "my father-in-law" (seria se EU casasse com Megan)\n'
        '   \n'
        '   SE escrever: "my wife Sarah\'s father Robert"\n'
        '   ? Robert �: "my father-in-law" (meu sogro)\n'
        '   ? Sarah �: "my wife" (minha esposa)\n'
        '   ? Irm�o de Sarah �: "my brother-in-law" (meu cunhado)\n'
        '   \n'
        '   ?? REGRA DE OURO:\n'
        '      Antes de usar "cunhado/cunhada/sogro/sogra/genro/nora":\n'
        '      1. Pergunte: QUEM � casado com QUEM?\n'
        '      2. Desenhe mentalmente a �rvore geneal�gica\n'
        '      3. Valide se a rela��o faz sentido matem�tico\n'
        '      4. Se confuso, use nomes pr�prios em vez de rela��es\n'
        '   \n'
        '   ?? SE HOUVER D�VIDA: Use "Megan" em vez de tentar definir rela��o familiar!\n'
        '????????????????????????????????????????????????????\n';

    // ?? CRITICAL: ADICIONAR INSTRU��O DE PERSPECTIVA/G�NERO NO IN�CIO DO PROMPT
    final perspectiveInstruction = _getPerspectiveInstruction(c.perspective, c);

    // ?? NOVO: Combinar prompt do template (compacto) + informa��es de bloco
    final compactPrompt = MainPromptTemplate.buildCompactPrompt(
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
      // ?? GEMINI 2.5 PRO: Suporta at� 65.535 tokens de sa�da!
      // Aumentado para 50.000 tokens (76% da capacidade) para idiomas cir�licos

      // ?? AJUSTE: Idiomas n�o-latinos (cir�lico, etc.) consomem mais tokens
      final languageNormalized = c.language.toLowerCase().trim();
      final isCyrillic =
          languageNormalized.contains('russo') ||
          languageNormalized.contains('b�lgar') ||
          languageNormalized.contains('bulgar') ||
          languageNormalized == 'ru' ||
          languageNormalized == 'bg';
      final isTurkish =
          languageNormalized.contains('turco') || languageNormalized == 'tr';

      // Cir�lico e turco precisam de 5x mais tokens por caractere (aumentado de 4x)
      // Idiomas latinos mant�m 2.5x (aumentado de 2x) para mais margem
      final tokenMultiplier = c.measureType == 'caracteres'
          ? (isCyrillic || isTurkish ? 5.0 : 2.5)
          : 12.0; // Aumentado de 10.0 para 12.0 para palavras

      final maxTokensCalculated = (needed * tokenMultiplier).ceil();
      final maxTokensLimit = 50000; // Aumentado de 32.768 para 50.000 tokens
      final finalMaxTokens = maxTokensCalculated > maxTokensLimit
          ? maxTokensLimit
          : maxTokensCalculated;

      // ?? SELE��O DE MODELO BASEADA EM qualityMode
      // ?? v7.6.51: Arquitetura Pipeline Modelo �nico - usar helper centralizado
      final selectedModel = _getSelectedModel(c.qualityMode);

      if (kDebugMode) {
        debugPrint('[$_instanceId] ?? qualityMode = "${c.qualityMode}"');
        debugPrint('[$_instanceId] ?? selectedModel = "$selectedModel"');
      }

      // ??? v7.6.64: Usar LlmClient para gera��o principal (SOLID)
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
          ? await _filterDuplicateParagraphs(previous, text)
          : '';

      // ?? v7.6.21: VALIDA��O CR�TICA - Nome da protagonista
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
            debugPrint('   ?? For�ando regenera��o...');
          }
          return ''; // For�ar regenera��o
        }

        // ?? v7.6.22: VALIDA��O CR�TICA - Relacionamentos familiares
        final hasValidRelationships = _validateFamilyRelationships(
          filtered,
          blockNumber,
        );
        if (!hasValidRelationships) {
          if (kDebugMode) {
            debugPrint(
              '? BLOCO $blockNumber REJEITADO: Relacionamentos familiares inconsistentes!',
            );
            debugPrint('   ?? For�ando regenera��o...');
          }
          return ''; // For�ar regenera��o
        }

        // ?? v7.6.22: RASTREAMENTO - Detectar resolu��o de personagens
        tracker.detectResolutionInText(filtered, blockNumber);

        // ?? v7.6.23: VALIDA��O CR�TICA - Taxa de fechamento no bloco final
        if (blockNumber == totalBlocks) {
          final closureRate = tracker.getClosureRate();
          final minimumClosureRate = 0.90; // 90% m�nimo

          if (closureRate < minimumClosureRate) {
            final unresolved = tracker.getUnresolvedCharacters();
            if (kDebugMode) {
              debugPrint(
                '? BLOCO FINAL REJEITADO: Taxa de fechamento insuficiente!',
              );
              debugPrint(
                '   Taxa atual: ${(closureRate * 100).toStringAsFixed(1)}% (m�nimo: ${(minimumClosureRate * 100).toInt()}%)',
              );
              debugPrint(
                '   Personagens sem fechamento: ${unresolved.join(", ")}',
              );
              debugPrint(
                '   ?? For�ando regenera��o com fechamentos obrigat�rios...',
              );
            }
            return ''; // For�a regenera��o do bloco final
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

      // ?? VALIDA��O DE TAMANHO: Rejeitar blocos que ultrapassem muito o limite
      // Aplic�vel a TODOS os idiomas, n�o s� espanhol
      if (filtered.isNotEmpty && languageMultiplier != 1.0) {
        final wordCount = _countWords(filtered);
        // ?? CORRE��O: Comparar com adjustedTarget (COM multiplicador), n�o limitedNeeded (SEM multiplicador)
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
              '   Pedido: $adjustedTarget palavras (limite m�ximo ajustado)',
            );
            debugPrint(
              '   Recebido: $wordCount palavras (+${overagePercent.toStringAsFixed(1)}%)',
            );
            debugPrint('   ?? Retornando vazio para for�ar regenera��o...');
          }
          return ''; // For�ar regenera��o
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
            debugPrint('   Causa: Conte�do filtrado como duplicado');
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

  // ??? v7.6.65: DELEGA��O para TextCleaner (Refatora��o SOLID)
  // Limpar texto de marca��es indesejadas
  String _cleanGeneratedText(String text) {
    return TextCleaner.cleanGeneratedText(text);
  }

  // ?? SISTEMA DE RASTREAMENTO DE NOMES - v4 (SOLU��O T�CNICA)
  /// Extrai nomes pr�prios capitalizados do texto gerado
  /// Retorna Set de nomes encontrados (n�o duplicados)
  Set<String> _extractNamesFromText(String text) {
    final names = <String>{};

    // ?? v7.6.30: DETECTAR NOMES COMPOSTOS PRIMEIRO (Arthur Evans, Mary Jane, etc)
    // Prioridade: 2-3 palavras capitalizadas consecutivas = nome completo
    final compoundNamePattern = RegExp(
      r'\b([A-Z�-�][a-z�-�]{1,14}(?:\s+[A-Z�-�][a-z�-�]{1,14}){1,2})\b',
      multiLine: true,
    );

    final compoundMatches = compoundNamePattern.allMatches(text);
    final processedWords = <String>{}; // Rastrear palavras j� processadas

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

    // ?? REGEX v7.6.17 CORRIGIDA: Detectar nomes simples EM QUALQUER POSI��O
    // - Palavra capitalizada (primeira letra mai�scula)
    // - 2-15 letras
    // - ? NOVO: Detecta no in�cio de frases, par�grafos E no meio
    // - Filtro: Remove palavras comuns depois
    final namePattern = RegExp(
      r'\b([A-Z�-�][a-z�-�]{1,14})\b',
      multiLine: true,
    );

    final matches = namePattern.allMatches(text);

    for (final match in matches) {
      final potentialName = match.group(1);
      if (potentialName != null) {
        // ?? v7.6.30: Pular se j� processado como parte de nome composto
        if (processedWords.contains(potentialName)) {
          continue;
        }

        // ?? FILTRO EXPANDIDO: Remover palavras comuns que n�o s�o nomes
        // Com a nova regra de capitaliza��o, isso n�o deveria mais ser necess�rio,
        // mas mantemos como backup caso o Gemini ignore a instru��o
        final commonWords = {
          // Pronomes
          'He', 'She', 'It', 'They', 'We', 'You', 'I',
          // Possessivos
          'My', 'Your', 'His', 'Her', 'Their', 'Our', 'Its',
          // Conjun��es
          'And', 'But', 'Or', 'Because', 'So', 'Yet', 'For',
          // Artigos
          'The', 'A', 'An',
          // Preposi��es comuns
          'In', 'On', 'At', 'To', 'From', 'With', 'By', 'Of', 'As',
          // Adv�rbios temporais
          'Then',
          'When',
          'After',
          'Before',
          'Now',
          'Today',
          'Tomorrow',
          'Yesterday',
          'While', 'During', 'Since', 'Until', 'Although', 'Though',
          // Adv�rbios de frequ�ncia
          'Always', 'Never', 'Often', 'Sometimes', 'Usually', 'Rarely',
          'Maybe', 'Perhaps', 'Almost', 'Just', 'Only', 'Even', 'Still',
          // Quantificadores
          'Much', 'Many', 'Few', 'Little', 'Some', 'Any', 'All', 'Most',
          'Both', 'Each', 'Every', 'Either', 'Neither', 'One', 'Two', 'Three',
          // Outros comuns
          'This', 'That', 'These', 'Those', 'There', 'Here', 'Where',
          'What', 'Which', 'Who', 'Whose', 'Whom', 'Why', 'How',
          // Verbos comuns no in�cio de frase (menos comum, mas pode acontecer)
          'Was', 'Were', 'Is', 'Are', 'Am', 'Has', 'Have', 'Had',
          'Do', 'Does', 'Did', 'Will', 'Would', 'Could', 'Should',
          'Can', 'May', 'Might', 'Must',
          // Dias da semana (por via das d�vidas)
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
          'Ent�o',
          'Quando',
          'Depois',
          'Antes',
          'Agora',
          'Hoje',
          'Amanh�',
          'Ontem',
          'Naquela',
          'Aquela',
          'Aquele',
          'Naquele',
          'Enquanto',
          'Durante',
          'Embora',
          'Por�m', 'Portanto', 'Assim', 'Nunca', 'Sempre', 'Talvez', 'Quase',
          'Apenas', 'Mesmo', 'Tamb�m', 'Muito', 'Pouco', 'Tanto', 'Onde',
          'Como', 'Porque', 'Mas', 'Ou', 'Para', 'Com', 'Sem', 'Por',
          // Termos t�cnicos/financeiros que podem aparecer capitalizados
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

  /// ?? v7.6.30: Verifica se frase composta � nome real ou express�o comum
  bool _isCommonPhrase(String phrase) {
    final phraseLower = phrase.toLowerCase();

    // Frases comuns que n�o s�o nomes de pessoas
    final commonPhrases = {
      'new york', 'los angeles', 'san francisco', 'las vegas',
      'united states', 'north carolina', 'south carolina',
      'good morning', 'good night', 'good afternoon',
      'thank you', 'excuse me', 'oh my',
      'dear god', 'holy shit', 'oh well',
      'right now', 'just then', 'back then',
      'even though', 'as if', 'so much',
      'too much', 'very much', 'much more',
      // Portugu�s
      's�o paulo', 'rio de', 'belo horizonte',
      'bom dia', 'boa tarde', 'boa noite',
      'meu deus', 'nossa senhora', 'por favor',
      'de repente', 'de novo', 't�o pouco',
    };

    return commonPhrases.contains(phraseLower);
  }

  /// Valida se h� nomes duplicados em pap�is diferentes
  /// Retorna lista de nomes duplicados encontrados
  List<String> _validateNamesInText(
    String newBlock,
    Set<String> previousNames,
  ) {
    final duplicates = <String>[];
    final newNames = _extractNamesFromText(newBlock);

    for (final name in newNames) {
      if (previousNames.contains(name)) {
        // ?? Nome j� usado anteriormente!
        if (!duplicates.contains(name)) {
          duplicates.add(name);
        }
      }
    }

    // ?? NOVA CAMADA: Valida��o case-insensitive para nomes em min�sculas
    // Detecta casos como "my lawyer, mark" onde "mark" deveria ser "Mark"
    final previousNamesLower = previousNames
        .map((n) => n.toLowerCase())
        .toSet();

    // Buscar palavras em min�sculas que correspondem a nomes confirmados
    final lowercasePattern = RegExp(r'\b([a-z][a-z]{1,14})\b');
    final lowercaseMatches = lowercasePattern.allMatches(newBlock);

    for (final match in lowercaseMatches) {
      final word = match.group(1);
      if (word != null && previousNamesLower.contains(word.toLowerCase())) {
        // Verificar se n�o � palavra comum (conjun��o, preposi��o, etc)
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
                '?? DUPLICA��O DETECTADA (case-insensitive): "$word" ? j� existe como "$originalName"',
              );
              debugPrint(
                '   ?? Gemini escreveu nome em min�sculas, mas j� foi usado capitalizado antes!',
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
      debugPrint('?? Nomes extra�dos do bloco: ${names.join(", ")}');
      debugPrint(
        '?? Total de nomes �nicos na hist�ria: ${_namesUsedInCurrentStory.length}',
      );
    }
  }

  /// Reseta o rastreador de nomes (in�cio de nova hist�ria)
  void _resetNameTracker() {
    _namesUsedInCurrentStory.clear();
    if (kDebugMode) {
      debugPrint('?? Rastreador de nomes resetado para nova hist�ria');
    }
  }

  // M�todo p�blico para uso nos providers - OTIMIZADO PARA CONTEXTO
  // ?? v7.6.51: Suporte a qualityMode para Pipeline Modelo �nico
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
    // Determinar modelo: usar expl�cito se fornecido, sen�o calcular via qualityMode
    final effectiveModel = model ?? _getSelectedModel(qualityMode);
    // CORRE��O: Reset de estado para evitar conflitos com gera��o de scripts
    if (_isCancelled) _isCancelled = false;

    return await _retryOnRateLimit(() async {
      try {
        debugPrint(
          'GeminiService: Iniciando requisi��o para modelo $effectiveModel',
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

        // Aplicar limpeza adicional se necess�rio
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

  // ===================== SISTEMA ANTI-REPETI��O =====================
  // ??? v7.6.65: M�todos delegados para DuplicationDetector (Refatora��o SOLID)

  // ??? v7.6.65: DELEGA��O para DuplicationDetector (Refatora��o SOLID)
  /// Verifica se novo bloco � muito similar aos blocos anteriores
  /// Retorna true se similaridade > threshold (padr�o 85%) OU se h� duplica��o literal
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

    // Cache baseado no hash do texto (economiza mem�ria vs armazenar string completa)
    final hash = text.hashCode;
    if (_wordCountCache.containsKey(hash)) {
      return _wordCountCache[hash]!;
    }

    // Otimiza��o: trim() uma �nica vez
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;

    // Conta palavras usando split otimizado
    final count = trimmed.split(RegExp(r'\s+')).length;

    // Limita cache a 100 entradas (previne vazamento de mem�ria)
    if (_wordCountCache.length > 100) {
      _wordCountCache.clear();
    }
    _wordCountCache[hash] = count;

    return count;
  }

  // M�todo est�tico para compatibilidade
  static void setApiTier(String tier) {
    // Implementa��o vazia para compatibilidade
  }

  // =============================================================================
  // ?? v7.6.52: WORLD STATE UPDATE - Atualiza��o de Estado via IA (Modelo �nico)
  // =============================================================================
  // Arquitetura Pipeline de Modelo �nico: O MESMO modelo selecionado pelo usu�rio
  // � usado para gerar o texto E para atualizar o JSON de estado do mundo.
  // Isso garante consist�ncia de estilo e respeita a configura��o do cliente.
  // =============================================================================

  /// ?? v7.6.52: Atualiza o World State ap�s gerar um bloco
  // ?????????????????????????????????????????????????????????????????????????????
  // ??? v7.6.64: M�todos _updateWorldState e _generateCompressedSynopsis
  // movidos para WorldStateManager (lib/data/services/scripting/)
  // ===================== M�TODOS CTA E FERRAMENTAS AUXILIARES =====================

  // ?? v7.6.51: Adicionado qualityMode para Pipeline Modelo �nico
  Future<Map<String, String>> generateCtasForScript({
    required String scriptContent,
    required String apiKey,
    required List<String> ctaTypes,
    String? customTheme,
    String language = 'Portugu�s',
    String perspective =
        'terceira_pessoa', // PERSPECTIVA CONFIGURADA PELO USU�RIO
    String qualityMode = 'pro', // ?? NOVO: Para Pipeline Modelo �nico
  }) async {
    try {
      // Usar idioma e perspectiva configurados pelo usu�rio (n�o detectar)
      final finalLanguage = language;

      // Analisar contexto da hist�ria (Flash para tarefa simples)
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

  // ?? v7.6.51: Adicionado qualityMode para Pipeline Modelo �nico
  Future<String> _analyzeScriptContext(
    String scriptContent,
    String apiKey,
    String language,
    String qualityMode,
  ) async {
    // ??? v7.6.66: Usar CtaGenerator para construir prompt de an�lise
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

  // 🏗️ v7.6.66: Métodos _buildAdvancedCtaPrompt, _getCtaTypeDescriptions,
  // _parseCtaResponseWithValidation e _validateFinalCtaConsistency
  // movidos para CtaGenerator (lib/data/services/gemini/tools/)
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

/// ?? Classe para armazenar o hist�rico completo de um personagem
class _CharacterHistory {
  final String name;
  final List<_CharacterNote> timeline = [];

  _CharacterHistory(this.name);

  /// Adiciona uma nova observa��o sobre o personagem
  void addNote(int blockNumber, String observation) {
    if (observation.isEmpty) return;
    timeline.add(_CharacterNote(blockNumber, observation));
    if (kDebugMode) {
      debugPrint('?? Nota adicionada: "$name" ? [B$blockNumber] $observation');
    }
  }

  /// Retorna o hist�rico completo formatado
  String getFullHistory() {
    if (timeline.isEmpty) return '';
    return timeline.map((e) => e.toString()).join('\n   ');
  }

  /// Verifica se uma nova observa��o contradiz o hist�rico
  bool contradicts(String newObservation) {
    if (timeline.isEmpty) return false;

    // Extrair palavras-chave da nova observa��o
    final newKeywords = _extractRelationshipKeywords(newObservation);

    // Verificar se contradiz alguma nota anterior
    for (final note in timeline) {
      final existingKeywords = _extractRelationshipKeywords(note.observation);

      // Se ambos t�m palavras de relacionamento, verificar contradi��o
      if (newKeywords.isNotEmpty && existingKeywords.isNotEmpty) {
        // Relacionamentos diferentes para o mesmo tipo = contradi��o
        if (_areContradictoryRelationships(existingKeywords, newKeywords)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Extrai palavras-chave de relacionamento de uma observa��o
  Set<String> _extractRelationshipKeywords(String text) {
    final keywords = <String>{};
    final lowerText = text.toLowerCase();

    // Padr�es de relacionamento
    final patterns = {
      'irm�': r'irm�\s+de\s+(\w+)',
      'irm�o': r'irm�o\s+de\s+(\w+)',
      'filho': r'filh[oa]\s+de\s+(\w+)',
      'pai': r'pai\s+de\s+(\w+)',
      'm�e': r'm�e\s+de\s+(\w+)',
      'esposa': r'esposa\s+de\s+(\w+)',
      'marido': r'marido\s+de\s+(\w+)',
      'neto': r'net[oa]\s+de\s+(\w+)',
      'tio': r'ti[oa]\s+de\s+(\w+)',
      'primo': r'prim[oa]\s+de\s+(\w+)',
      'av�': r'av[��]\s+de\s+(\w+)',
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

  /// Verifica se dois conjuntos de relacionamentos s�o contradit�rios
  bool _areContradictoryRelationships(Set<String> existing, Set<String> new_) {
    for (final existingRel in existing) {
      final existingType = existingRel.split('_')[0];

      for (final newRel in new_) {
        final newType = newRel.split('_')[0];

        // Mesmo tipo de relacionamento mas com pessoas diferentes = contradi��o
        if (existingType == newType && existingRel != newRel) {
          if (kDebugMode) {
            debugPrint('?? CONTRADI��O DETECTADA:');
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

  /// Retorna n�mero de apari��es do personagem
  int get appearanceCount => timeline.length;
}

class _CharacterTracker {
  final Set<String> _confirmedNames = {};
  // ?? NOVO: Mapear cada nome ao seu papel para prevenir confus�o e reuso
  final Map<String, String> _characterRoles = {};
  // ? v1.7 NOVO: MAPEAMENTO REVERSO papel ? nome (detecta nomes m�ltiplos por papel)
  final Map<String, String> _roleToName = {};
  // ??? SISTEMA DE NOTAS: Hist�rico completo de cada personagem
  final Map<String, _CharacterHistory> _characterHistories = {};
  // ?? v7.6.17: Nome da protagonista detectado automaticamente no Bloco 1
  String? _detectedProtagonistName;

  /// ?? v7.6.25: Retorna false se nome foi rejeitado (papel duplicado)
  bool addName(String name, {String? role, int? blockNumber}) {
    if (name.isEmpty || name.length <= 2) return true; // Nome vazio n�o � erro

    // ?? v7.6.30: VALIDA��O DE SIMILARIDADE - Detectar varia��es de nomes
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
            '? v7.6.30 BLOQUEIO: "$name" j� usado como "$existingRole"!',
          );
        }
        return true; // Duplicata exata
      }

      // Caso 2: Sobreposi��o de palavras (Arthur ? Arthur Evans)
      // "Arthur" est� contido em "Arthur Evans" ou vice-versa
      bool overlap = false;

      if (nameWords.length == 1 && existingWords.length > 1) {
        // Novo nome simples, j� existe composto
        if (existingWords.contains(nameLower)) {
          overlap = true;
        }
      } else if (nameWords.length > 1 && existingWords.length == 1) {
        // Novo nome composto, j� existe simples
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
          debugPrint('?????? v7.6.30: CONFLITO DE NOMES DETECTADO! ??????');
          debugPrint('   ? Nome novo: "$name"');
          debugPrint(
            '   ? Nome existente: "$existingName" (papel: $existingRole)',
          );
          debugPrint('   ?? PROBLEMA: Nomes com sobreposi��o de palavras!');
          debugPrint('   ?? EXEMPLO: "Arthur" conflita com "Arthur Evans"');
          debugPrint('   ?? SOLU��O: Use nomes COMPLETAMENTE diferentes');
          debugPrint('   ? BLOQUEANDO adi��o de "$name"!');
          debugPrint('?????? FIM DO ALERTA ??????');
        }
        return true; // Bloquear sobreposi��o
      }
    }

    // ?? VALIDA��O CR�TICA: Bloquear reuso de nomes
    if (_confirmedNames.contains(name)) {
      if (kDebugMode) {
        final existingRole = _characterRoles[name] ?? 'desconhecido';
        debugPrint(
          '? BLOQUEIO DE REUSO: "$name" j� usado como "$existingRole"!',
        );
        if (role != null && role != existingRole) {
          debugPrint(
            '   ?? Tentativa de reusar "$name" como "$role" ? REJEITADO!',
          );
        }
      }
      return true; // Nome duplicado, mas n�o � erro de papel
    }

    // ?? v7.6.25: VALIDA��O REVERSA - Um papel pode ter apenas UM nome
    if (role != null && role.isNotEmpty && role != 'indefinido') {
      // Normalizar papel (remover detalhes espec�ficos para compara��o)
      final normalizedRole = _normalizeRole(role);

      if (_roleToName.containsKey(normalizedRole)) {
        final existingName = _roleToName[normalizedRole]!;

        if (existingName != name) {
          // ?? ERRO CR�TICO: Mesmo papel com nomes diferentes!
          if (kDebugMode) {
            debugPrint(
              '?????? ERRO CR�TICO v7.6.25: M�LTIPLOS NOMES PARA MESMO PAPEL ??????',
            );
            debugPrint('   ? Papel: "$normalizedRole"');
            debugPrint('   ? Nome original: "$existingName"');
            debugPrint('   ? Nome novo (CONFLITANTE): "$name"');
            debugPrint(
              '   ?? EXEMPLO DO BUG: "advogado" sendo Martin no bloco 2 e Richard no bloco 7!',
            );
            debugPrint(
              '   ?? BLOQUEANDO adi��o de "$name" - usar apenas "$existingName"!',
            );
            debugPrint('?????? FIM DO ALERTA ??????');
          }
          return false; // ? RETORNA FALSE = ERRO DETECTADO
        }
      } else {
        // Primeiro nome para este papel - registrar no mapeamento reverso
        _roleToName[normalizedRole] = name;
        if (kDebugMode) {
          debugPrint('?? MAPEAMENTO REVERSO: "$normalizedRole" ? "$name"');
        }
      }
    }

    _confirmedNames.add(name);
    if (role != null && role.isNotEmpty) {
      _characterRoles[name] = role;
      if (kDebugMode) {
        debugPrint('? MAPEAMENTO: "$name" = "$role"');
      }

      // ?? SISTEMA DE NOTAS: Adicionar ao hist�rico
      if (blockNumber != null) {
        addNoteToCharacter(name, blockNumber, role);
      }
    }

    return true; // ? SUCESSO
  }

  /// ?? v7.6.26: Normaliza papel SELETIVAMENTE (evita falsos positivos)
  ///
  /// PAP�IS FAMILIARES: Mant�m completo "m�e de Emily" ? "m�e de Michael"
  /// PAP�IS GEN�RICOS: Normaliza "advogado de Sarah" ? "advogado"
  String _normalizeRole(String role) {
    final roleLower = role.toLowerCase().trim();

    // ?? v7.6.26: PAP�IS FAMILIARES - N�O normalizar (manter contexto familiar)
    final familyRoles = [
      'm�e',
      'pai',
      'filho',
      'filha',
      'irm�o',
      'irm�',
      'av�',
      'av�',
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
      'm�re',
      'p�re',
      'fils',
      'fille',
      'fr�re',
      's�ur',
      'grand-p�re',
      'grand-m�re',
      'oncle',
      'tante',
      'cousin',
      'cousine',
    ];

    // Verificar se � papel familiar
    for (final familyRole in familyRoles) {
      if (roleLower.contains(familyRole)) {
        return roleLower; // Manter completo
      }
    }

    // ?? PAP�IS GEN�RICOS: Normalizar
    final normalized = roleLower
        .replaceAll(RegExp(r'\s+de\s+[A-Z������������a-z������������]+.*$'), '')
        .trim();

    return normalized;
  }

  /// ?? Adiciona uma nota sobre um personagem
  void addNoteToCharacter(String name, int blockNumber, String observation) {
    if (!_characterHistories.containsKey(name)) {
      _characterHistories[name] = _CharacterHistory(name);
    }

    // Verificar se a nova observa��o contradiz o hist�rico
    final history = _characterHistories[name]!;
    if (history.contradicts(observation)) {
      if (kDebugMode) {
        debugPrint('?????? CONTRADI��O NO HIST�RICO DE "$name" ??????');
        debugPrint('   ?? Hist�rico existente:');
        debugPrint('   ${history.getFullHistory()}');
        debugPrint('   ?? Nova observa��o contradit�ria: $observation');
        debugPrint('   ?? Esta observa��o N�O ser� adicionada!');
        debugPrint('?????? FIM DO ALERTA ??????');
      }
      return; // Bloqueia adi��o de observa��o contradit�ria
    }

    history.addNote(blockNumber, observation);
  }

  /// ?? Obt�m o hist�rico completo de um personagem
  String? getCharacterHistory(String name) {
    final history = _characterHistories[name];
    return history?.getFullHistory();
  }

  /// ?? Obt�m estat�sticas de um personagem
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

  /// ?? v7.6.35: Exp�e o mapa roleToName para o PostGenerationFixer
  Map<String, String> get roleToNameMap => Map.unmodifiable(_roleToName);

  /// ?? v1.7: Obt�m o nome associado a um papel (mapeamento reverso)
  String? getNameForRole(String role) {
    final normalizedRole = _normalizeRole(role);
    return _roleToName[normalizedRole];
  }

  /// ?? v1.7: Verifica se um papel j� tem nome definido
  bool roleHasName(String role) {
    final normalizedRole = _normalizeRole(role);
    return _roleToName.containsKey(normalizedRole);
  }

  // ?? v7.6.28: Obter mapeamento completo de personagens + LISTA DE NOMES PROIBIDOS
  String getCharacterMapping() {
    if (_characterRoles.isEmpty && _characterHistories.isEmpty) return '';

    final buffer = StringBuffer('\n?? PERSONAGENS J� DEFINIDOS:\n');

    // ?? v7.6.28: LISTA CR�TICA DE NOMES J� USADOS (NUNCA REUTILIZAR!)
    if (_confirmedNames.isNotEmpty) {
      buffer.writeln('\n?? NOMES J� USADOS - NUNCA REUTILIZE ESTES NOMES:');
      final namesList = _confirmedNames.toList()..sort();
      for (final name in namesList) {
        final role = _characterRoles[name] ?? 'indefinido';
        buffer.writeln('   ? "$name" (j� �: $role)');
      }
      buffer.writeln('\n?? REGRA ABSOLUTA: Cada nome deve ser �NICO!');
      buffer.writeln('?? Se precisa de novo personagem, use NOME DIFERENTE!');
      buffer.writeln(
        '?? NUNCA use "Mark", "Charles", etc se j� est�o acima!\n',
      );
    }

    // v1.7: Mostrar mapeamento reverso (papel ? nome) para refor�ar consist�ncia
    if (_roleToName.isNotEmpty) {
      buffer.writeln(
        '\n?? MAPEAMENTO PAPEL ? NOME (use SEMPRE os mesmos nomes):',
      );
      for (final entry in _roleToName.entries) {
        buffer.writeln(
          '   "${entry.key}" = "${entry.value}" ?? NUNCA mude este nome!',
        );
      }
      buffer.writeln();
    }

    // Para cada personagem, mostrar hist�rico completo se dispon�vel
    for (final name in _confirmedNames) {
      final history = _characterHistories[name];

      if (history != null && history.timeline.isNotEmpty) {
        // Mostrar hist�rico completo
        buffer.writeln('\n?? $name:');
        buffer.writeln('   ${history.getFullHistory()}');
        buffer.writeln(
          '   ?? NUNCA mude este personagem! Use outro nome para novos personagens.',
        );
      } else {
        // Mostrar apenas papel b�sico
        final role = _characterRoles[name] ?? 'personagem';
        buffer.writeln('   "$name" = $role');
      }
    }

    return buffer.toString();
  }

  /// ?? v7.6.17: Registra o nome da protagonista detectado no Bloco 1
  void setProtagonistName(String name) {
    if (_detectedProtagonistName == null) {
      _detectedProtagonistName = name.trim();
      if (kDebugMode) {
        debugPrint('? Protagonista detectada: "$_detectedProtagonistName"');
      }
    }
  }

  /// ?? v7.6.17: Retorna o nome da protagonista registrado
  String? getProtagonistName() => _detectedProtagonistName;

  /// ?? v7.6.22: RASTREAMENTO DE FECHAMENTO DE PERSONAGENS
  /// Marca um personagem como "resolvido" no final da hist�ria
  final Map<String, bool> _characterResolution = {};

  /// Marca um personagem como tendo recebido fechamento/resolu��o
  void markCharacterAsResolved(String name) {
    if (_confirmedNames.contains(name)) {
      _characterResolution[name] = true;
      if (kDebugMode) {
        debugPrint('? PERSONAGEM RESOLVIDO: $name');
      }
    }
  }

  /// Detecta automaticamente personagens que receberam fechamento no texto
  void detectResolutionInText(String text, int blockNumber) {
    // Padr�es que indicam fechamento de personagem
    final resolutionPatterns = [
      // Conclus�o f�sica/localiza��o
      RegExp(
        r'([A-Z][a-z]+)\s+(?:foi embora|left|partiu|morreu|died|desapareceu|vanished)',
        caseSensitive: false,
      ),
      RegExp(
        r'([A-Z][a-z]+)\s+(?:nunca mais|never again|jamais)',
        caseSensitive: false,
      ),

      // Justi�a/vingan�a
      RegExp(
        r'([A-Z][a-z]+)\s+(?:foi preso|was arrested|foi condenado|was convicted)',
        caseSensitive: false,
      ),
      RegExp(
        r'([A-Z][a-z]+)\s+(?:confessou|confessed|admitiu|admitted)',
        caseSensitive: false,
      ),

      // Reconcilia��o/paz
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
          addNoteToCharacter(name, blockNumber, 'RESOLU��O: ${match.group(0)}');
        }
      }
    }
  }

  /// Retorna lista de personagens sem fechamento
  List<String> getUnresolvedCharacters() {
    final unresolved = <String>[];

    for (final name in _confirmedNames) {
      // Ignorar protagonista (sempre tem fechamento impl�cito)
      if (name == _detectedProtagonistName) continue;

      final role = _characterRoles[name]?.toLowerCase() ?? '';

      // ?? FIX v7.6.24: Ignorar personagens SEM hist�rico OU muito secund�rios (=1 apari��o)
      final history = _characterHistories[name];
      if (history == null || history.appearanceCount <= 1) continue;

      // Personagens importantes que precisam de fechamento:
      // - Fam�lia pr�xima (pai, m�e, irm�o, filho, c�njuge)
      // - Antagonistas/vil�es
      // - Ajudantes/aliados que apareceram m�ltiplas vezes (3+)
      final needsClosure =
          role.contains('marido') ||
          role.contains('esposa') ||
          role.contains('pai') ||
          role.contains('m�e') ||
          role.contains('filho') ||
          role.contains('filha') ||
          role.contains('irm�o') ||
          role.contains('irm�') ||
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
          role.contains('s�cio') ||
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
      // ?? FIX v7.6.24: Excluir personagens SEM hist�rico OU com 1 apari��o
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
    _characterResolution.clear(); // v7.6.22: Limpar resolu��es
  }
}

// =============================================================================
// ??? v7.6.64: WORLD STATE migrado para scripting/world_state_manager.dart
// =============================================================================
// As classes WorldState e WorldCharacter agora est�o no m�dulo dedicado.
// Import: package:flutter_gerador/data/services/scripting/scripting_modules.dart
// =============================================================================
