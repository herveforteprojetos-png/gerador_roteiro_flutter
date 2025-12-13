import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/script_result.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';
import 'package:flutter_gerador/data/models/debug_log.dart';
import 'package:flutter_gerador/data/utils/text_capitalizer.dart';
import 'gemini/gemini_modules.dart';
import 'package:flutter_gerador/data/services/prompts/main_prompt_template.dart';
import 'package:flutter_gerador/data/services/prompts/structure_rules.dart';
import 'package:flutter_gerador/data/services/scripting/scripting_modules.dart';
import 'package:flutter_gerador/data/services/gemini/detection/detection_modules.dart';
import 'package:flutter_gerador/data/services/gemini/tools/tools_modules.dart';
import 'package:flutter_gerador/data/services/gemini/validation/character_validation.dart';
import 'package:flutter_gerador/data/services/gemini/validation/paragraph_validator.dart';
import 'package:flutter_gerador/data/services/gemini/generation/block_calculator.dart';
import 'package:flutter_gerador/data/services/gemini/generation/context_builder.dart';
import 'package:flutter_gerador/data/services/gemini/utils/text_utils.dart';

// ===================== FUNÇÕES TOP-LEVEL PARA ISOLATES =====================
// Funções estáticas para uso com compute() - não podem acessar membros da instância

/// Remove duplicatas de parágrafos em Isolate
String _removeAllDuplicateParagraphsIsolate(String fullScript) {
  final paragraphs = fullScript.split(RegExp(r'\n{2,}'));
  if (paragraphs.length < 2) return fullScript;

  final seen = <String>{};
  final seenNormalized = <String>{};
  final result = <String>[];

  for (final rawParagraph in paragraphs) {
    final paragraph = rawParagraph.trim();
    if (paragraph.isEmpty) continue;

    final normalized = paragraph.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

    if (seen.contains(paragraph) || seenNormalized.contains(normalized)) {
      continue;
    }

    seen.add(paragraph);
    seenNormalized.add(normalized);
    result.add(paragraph);
  }

  return result.join('\n\n');
}

/// 🆕 v7.6.124: Isolate atualizado para suportar nomes conhecidos
Map<String, dynamic> _extractNamesIsolate(Map<String, dynamic> params) {
  final text = params['text'] as String;
  final knownNamesList = params['knownNames'] as List<dynamic>?;
  final knownNames = knownNamesList?.cast<String>().toSet() ?? <String>{};
  final names = NameValidator.extractNamesFromText(text, knownNames).toList();
  return {'names': names};
}

class GeminiService {
  final Dio _dio;
  final String _instanceId;
  bool _isCancelled = false;

  late final LlmClient _llmClient;
  late final WorldStateManager _worldStateManager;
  late final ScriptValidator _scriptValidator;
  late final CharacterValidation _characterValidation;

  DateTime? _lastSuccessfulCall;
  int _consecutive503Errors = 0;
  int _consecutiveSuccesses = 0;

  final _debugLogger = DebugLogManager();
  final Set<String> _namesUsedInCurrentStory = {};

  // 🆕 v7.6.123: Contador de mantras em tempo real
  final Map<String, int> _mantraCounterRealTime = {};

  bool _isCircuitOpen = false;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  static const int _maxFailures = 5;
  static const Duration _circuitResetTime = Duration(seconds: 30);

  static int _globalRequestCount = 0;
  static DateTime _globalLastRequestTime = DateTime.now();
  static const Duration _rateLimitWindow = Duration(seconds: 60);
  static const int _maxRequestsPerWindow = 50;
  static bool _rateLimitBusy = false;

  Timer? _watchdogTimer;
  bool _isOperationRunning = false;
  static const Duration _maxOperationTime = Duration(minutes: 60);

  /// 🆕 v7.6.136: Normaliza output do Gemini se estiver no formato minúsculo + NOMES
  /// Retorna texto normalizado e opcionalmente extrai nomes detectados
  static String _normalizeGeminiBlock(String text, {int? blockNumber}) {
    if (text.trim().isEmpty) return text;

    if (TextCapitalizer.isGeminiFormat(text)) {
      final extractedNames = <String>{};
      final normalized = TextCapitalizer.normalizeGeminiOutput(
        text,
        extractedNames: extractedNames,
      );

      if (kDebugMode && extractedNames.isNotEmpty && blockNumber != null) {
        debugPrint(
          '📝 [Bloco $blockNumber] TextCapitalizer: ${extractedNames.length} nomes → ${extractedNames.take(3).join(', ')}${extractedNames.length > 3 ? '...' : ''}',
        );
      }

      return normalized;
    }

    return text;
  }

  static String _getSelectedModel(String qualityMode) {
    return qualityMode == 'flash'
        ? 'gemini-2.5-flash'
        : qualityMode == 'ultra'
        ? 'gemini-3-pro-preview'
        : 'gemini-2.5-pro';
  }

  GeminiService({String? instanceId})
    : _instanceId =
          instanceId ??
          'gemini_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(
            minutes: 3,
          ), // v7.6.146: Timeout reduzido para 3min
          sendTimeout: const Duration(seconds: 45),
        ),
      ) {
    _llmClient = LlmClient(instanceId: _instanceId);
    _worldStateManager = WorldStateManager(llmClient: _llmClient);
    _scriptValidator = ScriptValidator(llmClient: _llmClient);
    _characterValidation = CharacterValidation(_debugLogger);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (kDebugMode) debugPrint('[$_instanceId] -> ${o.method} ${o.path}');
          h.next(o);
        },
        onResponse: (r, h) {
          if (kDebugMode) debugPrint('[$_instanceId] <- ${r.statusCode}');
          _isCircuitOpen = false;
          _failureCount = 0;
          _lastFailureTime = null;
          h.next(r);
        },
        onError: (e, h) {
          if (kDebugMode) debugPrint('[$_instanceId] ERROR: ${e.message}');
          _failureCount++;
          _lastFailureTime = DateTime.now();
          if (_failureCount >= _maxFailures) {
            _isCircuitOpen = true;
            if (kDebugMode) debugPrint('[$_instanceId] Circuit aberto');
          }
          h.next(e);
        },
      ),
    );
  }

  Future<ScriptResult> generateScript(
    ScriptConfig config,
    void Function(GenerationProgress) onProgress,
  ) async {
    _globalRequestCount = 0;
    _globalLastRequestTime = DateTime.now();
    _rateLimitBusy = false;
    _namesUsedInCurrentStory.clear();
    PostGenerationFixer.resetIntroducedCharacters();

    if (_isCircuitOpen) {
      if (_lastFailureTime != null &&
          DateTime.now().difference(_lastFailureTime!) > _circuitResetTime) {
        _isCircuitOpen = false;
        _failureCount = 0;
        _lastFailureTime = null;
      } else {
        return ScriptResult.error(
          errorMessage:
              'Serviço temporariamente indisponível. Tente mais tarde.',
        );
      }
    }

    resetState();

    final persistentTracker = CharacterTracker();
    CharacterTracker.bootstrap(persistentTracker, config);

    final worldState = WorldState();
    _worldStateManager.reset();
    _worldStateManager.initializeProtagonist(config.protagonistName);

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
    } catch (e) {
      final fallback = config.tema.length > 500
          ? '${config.tema.substring(0, 500)}...'
          : config.tema;
      worldState.sinopseComprimida = fallback;
      _worldStateManager.setSynopsis(fallback);
    }

    String viralHook = "";
    if (!config.startWithTitlePhrase && config.title.trim().isNotEmpty) {
      try {
        final hookPrompt = ScriptPromptBuilder.buildViralHookPrompt(
          title: config.title,
          tema: config.tema,
          language: config.language,
        );
        viralHook = await _llmClient.generateText(
          prompt: hookPrompt,
          apiKey: config.apiKey,
          model: LlmClient.modelFlash,
          maxTokens: 150,
        );
        viralHook = viralHook.replaceAll('"', '').trim();
      } catch (e) {
        // Ignora erro de hook
      }
    }

    _startWatchdog();
    final start = DateTime.now();
    try {
      final totalBlocks = BlockCalculator.calculateTotalBlocks(config);
      var acc = '';

      for (var block = 1; block <= totalBlocks && !_isCancelled; block++) {
        // ⏱️ v7.6.125: CRONÔMETRO POR BLOCO
        final blockStartTime = DateTime.now();
        if (kDebugMode) {
          debugPrint('\n🔵 ═══════════════════════════════════════════');
          debugPrint('⏱️ [Bloco $block/$totalBlocks] INÍCIO');
        }

        final progress = block / totalBlocks;
        final phase = BlockCalculator.getPhase(progress);
        final elapsed = DateTime.now().difference(start);
        final estTotal = progress > 0
            ? Duration(
                milliseconds: (elapsed.inMilliseconds / progress).round(),
              )
            : Duration.zero;
        final remaining = estTotal - elapsed;
        final logs = _generateBlockLogs(phase, block, totalBlocks, config);

        // 🚀 OTIMIZAÇÃO ULTRA-AGRESSIVA: Atualizar UI apenas a cada 3-4 blocos
        // Isso reduz DRASTICAMENTE a carga na UI
        final shouldUpdateProgress =
            block == 1 || block == totalBlocks || block % 4 == 0;
        if (shouldUpdateProgress) {
          // 🚀 OTIMIZAÇÃO: Contar palavras apenas quando necessário
          final wordCount = acc.isEmpty ? 0 : TextUtils.countWords(acc);

          onProgress(
            GenerationProgress(
              percentage: progress,
              currentPhase: phase,
              phaseIndex: BlockCalculator.phases.indexOf(phase),
              totalPhases: BlockCalculator.phases.length,
              currentBlock: block,
              totalBlocks: totalBlocks,
              estimatedTimeRemaining: remaining,
              logs: logs,
              wordsGenerated: wordCount,
            ),
          );
          // 🚀 YIELD MÍNIMO: Apenas 10ms para UI respirar
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // 🚀 v7.6.118: Delay APENAS se houve erros recentes
        if (block > 1 && _consecutive503Errors > 0) {
          final delay = _getAdaptiveDelay(blockNumber: block);
          if (kDebugMode) {
            debugPrint(
              '⏱️ [Bloco $block] ⚠️ Aplicando delay adaptativo: ${delay.inMilliseconds}ms (erros 503: $_consecutive503Errors)',
            );
          }
          await Future.delayed(delay);
        }

        final targetForBlock = BlockCalculator.calculateTargetForBlock(
          block,
          totalBlocks,
          config,
        );

        // ⏱️ v7.6.125: Cronometrar geração inicial
        final genStartTime = DateTime.now();
        if (kDebugMode) {
          debugPrint(
            '⏱️ [Bloco $block] 🎬 Gerando conteúdo (meta: $targetForBlock palavras)...',
          );
        }

        var added = await _retryOnRateLimit(
          () => _generateBlockContent(
            acc,
            targetForBlock,
            phase,
            config,
            persistentTracker,
            block,
            totalBlocks,
            worldState: worldState,
          ),
        );

        final genDuration = DateTime.now().difference(genStartTime);
        if (kDebugMode) {
          debugPrint(
            '⏱️ [Bloco $block] ✅ Geração inicial: ${genDuration.inSeconds}s (${added.length} chars)',
          );
        }

        // 🆕 v7.6.136: Normaliza output do Gemini (minúsculo + NOMES → Title Case)
        added = _normalizeGeminiBlock(added, blockNumber: block);

        // 🆕 v7.6.141: Normaliza casing para evitar conflitos no validador
        // (lowercase exceto nomes próprios conhecidos)
        if (added.trim().isNotEmpty) {
          final knownNames = persistentTracker.roleToNameMap.values.toSet();
          added = PostGenerationFixer.lowercaseExceptNames(
            added,
            knownNames: knownNames,
          );
        }

        if (added.trim().isNotEmpty && block > 1) {
          added = PostGenerationFixer.fixSwappedNames(
            added,
            persistentTracker.roleToNameMap,
            block,
          );
        }

        if (added.trim().isEmpty && acc.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              '⏱️ [Bloco $block] ⚠️ VAZIO - Iniciando ciclo de retries...',
            );
          }
          // 🔥 v7.6.145: Retries com backoff exponencial CAP em 5s
          // v7.6.130: 2s, 4s, 8s = 14s total
          // v7.6.145: 2s, 4s, 5s = 11s total (cap em 5s para evitar esperas longas)
          // v7.6.162: 5 retries para blocos finais (7+), 3 para blocos iniciais
          final maxRetries = block >= 7 ? 5 : 3;
          for (int retry = 1; retry <= maxRetries; retry++) {
            final retryDelay = retry == 1
                ? 2
                : (retry == 2 ? 4 : 5); // Cap em 5s (v7.6.145)
            if (kDebugMode) {
              debugPrint(
                '⏱️ [Bloco $block] 🔄 Retry $retry/$maxRetries - Aguardando ${retryDelay}s (backoff exponencial)...',
              );
            }
            await Future.delayed(Duration(seconds: retryDelay));

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
                worldState: worldState,
                fullContextForCounter:
                    acc, // 🆕 v7.6.142.1: Passa contexto completo
              ),
            );

            // 🆕 v7.6.136: Normaliza output do retry também
            added = _normalizeGeminiBlock(added, blockNumber: block);

            // 🆕 v7.6.141: Normaliza casing no retry
            if (added.trim().isNotEmpty) {
              final knownNames = persistentTracker.roleToNameMap.values.toSet();
              added = PostGenerationFixer.lowercaseExceptNames(
                added,
                knownNames: knownNames,
              );
            }

            if (added.trim().isNotEmpty) break;
          }

          if (added.trim().isEmpty) {
            return ScriptResult.error(
              errorMessage:
                  'Bloco $block falhou após 3 tentativas. Servidor pode estar sobrecarregado.',
            );
          }
        }

        // 🚀 v7.6.118: Validações de qualidade apenas para Pro (Flash é rápido)
        final isFlashModelLoop = config.qualityMode.toLowerCase().contains(
          'flash',
        );
        if (added.trim().isNotEmpty && acc.length > 500 && !isFlashModelLoop) {
          final result = await compute(TextUtils.isTooSimilarInIsolate, {
            'newBlock': added,
            'previousContent': acc,
            'threshold': 0.80,
          });

          if (result['isSimilar'] == true) {
            final regenerated = await _retryOnRateLimit(
              () => _generateBlockContent(
                acc,
                targetForBlock,
                phase,
                config,
                persistentTracker,
                block,
                totalBlocks,
                avoidRepetition: true,
                worldState: worldState,
              ),
            );
            if (regenerated.trim().isNotEmpty) {
              added = _normalizeGeminiBlock(regenerated, blockNumber: block);
            }
          }

          // 🚨 v7.6.110: Validar início repetitivo de parágrafos
          if (ParagraphValidator.hasRepetitiveStarts(added)) {
            _debugLogger.warning(
              "Início repetitivo detectado no bloco $block - regenerando",
              blockNumber: block,
            );

            final regenerated = await _retryOnRateLimit(
              () => _generateBlockContent(
                acc,
                targetForBlock,
                phase,
                config,
                persistentTracker,
                block,
                totalBlocks,
                avoidRepetition: true,
                worldState: worldState,
              ),
            );
            final normalizedRegen = _normalizeGeminiBlock(
              regenerated,
              blockNumber: block,
            );
            if (normalizedRegen.trim().isNotEmpty &&
                !ParagraphValidator.hasRepetitiveStarts(normalizedRegen)) {
              added = normalizedRegen;
            }
          }

          // 🚨 v7.6.114: Detectar reinício da história (bloco recontan do início)
          if (block > 1 && TextFilter.isRestartingStory(added, acc)) {
            _debugLogger.warning(
              "Bloco $block está recomeçando a história do início - regenerando",
              blockNumber: block,
            );

            final regenerated = await _retryOnRateLimit(
              () => _generateBlockContent(
                acc,
                targetForBlock,
                phase,
                config,
                persistentTracker,
                block,
                totalBlocks,
                avoidRepetition: true,
                worldState: worldState,
              ),
            );
            final normalizedRestart = _normalizeGeminiBlock(
              regenerated,
              blockNumber: block,
            );
            if (normalizedRestart.trim().isNotEmpty &&
                !TextFilter.isRestartingStory(normalizedRestart, acc)) {
              added = normalizedRestart;
            } else {
              // Se ainda está reiniciando, aceitar mas logar aviso
              _debugLogger.warning(
                "Bloco $block ainda reinicia história após retry - aceitando com ressalva",
                blockNumber: block,
              );
            }
          }
        }

        // 🎯 v7.6.110: Processar bloco válido
        if (added.trim().isNotEmpty) {
          // 🎬 Inserir gancho viral no bloco 1 (antes de qualquer validação)
          if (block == 1 && viralHook.isNotEmpty) {
            added = 'GANCHO VIRAL:\n$viralHook\n\n$added';
          }

          if (block == 1) {
            _characterValidation.detectAndRegisterProtagonist(
              added,
              config,
              persistentTracker,
            );
          }

          final protagonistChanged = _characterValidation
              .detectProtagonistNameChange(
                added,
                config,
                persistentTracker,
                block,
              );
          _characterValidation.validateNameReuse(
            added,
            persistentTracker,
            block,
          );

          final characterNameChanges = _characterValidation
              .detectCharacterNameChanges(added, persistentTracker, block);
          if (protagonistChanged || characterNameChanges.isNotEmpty) {
            if (kDebugMode) {
              debugPrint(
                '⏱️ [Bloco $block] ⚠️ Mudança de nome detectada - Regenerando...',
              );
            }
            String? regenerated;
            // 🚀 v7.6.118: Apenas 1 retry (era 3) - a maioria resolve na primeira
            for (int i = 1; i <= 1; i++) {
              regenerated = await _generateBlockContent(
                acc,
                targetForBlock,
                phase,
                config,
                persistentTracker,
                block,
                totalBlocks,
                avoidRepetition: true,
                worldState: worldState,
              );
              if (regenerated.trim().isNotEmpty &&
                  !_characterValidation.detectProtagonistNameChange(
                    regenerated,
                    config,
                    persistentTracker,
                    block,
                  )) {
                break;
              }
            }
            if (regenerated != null && regenerated.trim().isNotEmpty)
              added = regenerated;
          }

          // ⏱️ v7.6.125: Cronometrar extração de nomes
          final namesStartTime = DateTime.now();

          // 🚀 OTIMIZAÇÃO: Extrair nomes em Isolate para textos grandes
          // 🆕 v7.6.124: Passando nomes conhecidos para lógica posicional
          List<String> allNames;
          if (added.length > 3000) {
            if (kDebugMode) {
              debugPrint('⏱️ [Bloco $block] 🔍 Extraindo nomes (isolate)...');
            }
            final result = await compute(_extractNamesIsolate, {
              'text': added,
              'knownNames': persistentTracker.confirmedNames.toList(),
            });
            allNames = (result['names'] as List).cast<String>();
          } else {
            if (kDebugMode) {
              debugPrint('⏱️ [Bloco $block] 🔍 Extraindo nomes...');
            }
            allNames = NameValidator.extractNamesFromText(
              added,
              persistentTracker.confirmedNames,
            ).toList();
          }

          final namesDuration = DateTime.now().difference(namesStartTime);
          if (kDebugMode) {
            debugPrint(
              '⏱️ [Bloco $block] ✅ Extração de nomes: ${namesDuration.inMilliseconds}ms (${allNames.length} nomes)',
            );
            // 🇰🇷 v7.6.150: Log detalhado DESABILITADO (causava travamento com 534+ palavras)
            // Mostrar apenas quantidade de nomes
          }

          allNames = allNames
              .where((n) => NameValidator.looksLikePersonName(n))
              .toList();
          
          // 🇰🇷 v7.6.150: DESABILITADO - log causava travamento da UI
          // (534+ palavras coreanas comuns eram detectadas como nomes)
          
          final unregistered = allNames
              .where((n) => !persistentTracker.hasName(n))
              .toList();
          for (final name in unregistered) {
            persistentTracker.addName(name, blockNumber: block);
          }

          final duplicated = NameValidator.validateNamesInText(
            added,
            _namesUsedInCurrentStory,
          );
          if (duplicated.isNotEmpty) {
            _debugLogger.warning(
              "Possível duplicação de nomes no bloco $block",
              details: duplicated.join(", "),
            );
          }
          // 🚀 OTIMIZAÇÃO: Reusar allNames ao invés de extrair novamente
          _namesUsedInCurrentStory.addAll(allNames);

          _characterValidation.validateFamilyRelations(added, block);
          _startWatchdog();

          final duplicateConflict = _characterValidation.validateUniqueNames(
            added,
            persistentTracker,
            block,
          );
          final trackerValid = _characterValidation
              .updateTrackerFromContextSnippet(
                persistentTracker,
                config,
                added,
              );

          if (duplicateConflict || !trackerValid) {
            added = '';
          } else if (added.trim().isNotEmpty) {
            // 🚀 v7.6.117: OTIMIZAÇÃO - Atualizar WorldState apenas a cada 3 blocos
            // Isso reduz chamadas à API de 8 para ~3, economizando ~40-60 segundos
            final shouldUpdateWorldState =
                block == 1 || block == totalBlocks || block % 3 == 0;

            if (shouldUpdateWorldState) {
              // ⏱️ v7.6.118: Cronometrar WorldState update
              final wsStartTime = DateTime.now();

              await _worldStateManager.updateFromGeneratedBlock(
                generatedBlock: added,
                blockNumber: block,
                apiKey: config.apiKey,
                qualityMode: config.qualityMode,
                language: config.language,
              );

              if (kDebugMode) {
                final wsDuration = DateTime.now().difference(wsStartTime);
                debugPrint(
                  '⏱️ [Bloco $block] WorldState update: ${wsDuration.inMilliseconds}ms',
                );
              }

              worldState.resumoAcumulado =
                  _worldStateManager.state.resumoAcumulado;
            }
          }
        }

        // ⏱️ v7.6.125: Log tempo total do bloco
        final blockTotalTime = DateTime.now().difference(blockStartTime);
        if (kDebugMode) {
          debugPrint(
            '⏱️ [Bloco $block] ⏹️ CONCLUÍDO em ${blockTotalTime.inSeconds}s (${blockTotalTime.inMilliseconds}ms)',
          );
          debugPrint('   📊 Palavras acumuladas: ${TextUtils.countWords(acc)}');
          debugPrint('🔵 ═══════════════════════════════════════════\n');
        }

        if (added.trim().isEmpty) {
          int retryCount = 0;
          if (kDebugMode) {
            debugPrint(
              '⏱️ [Bloco $block] ⚠️ VAZIO após validações - Segundo ciclo de retries...',
            );
          }
          // 🚀 v7.6.118: Delays reduzidos para 1s/2s/3s (era 2s/4s/6s)
          while (retryCount < 3 && added.trim().isEmpty) {
            retryCount++;
            await Future.delayed(Duration(seconds: retryCount));
            added = await _retryOnRateLimit(
              () => _generateBlockContent(
                acc,
                targetForBlock,
                phase,
                config,
                persistentTracker,
                block,
                totalBlocks,
                worldState: worldState,
              ),
            );

            if (added.trim().isNotEmpty) {
              final hasConflict = _characterValidation.validateUniqueNames(
                added,
                persistentTracker,
                block,
              );
              final trackerValid = _characterValidation
                  .updateTrackerFromContextSnippet(
                    persistentTracker,
                    config,
                    added,
                  );

              if (!hasConflict && trackerValid) {
                break;
              }
              added = '';
            }
          }
          if (added.trim().isEmpty) {
            return ScriptResult.error(
              errorMessage: 'Bloco $block falhou após múltiplas tentativas.',
            );
          }
        }

        // 📊 v7.6.112: Log de contagem de palavras por bloco
        final blockWords = TextUtils.countWords(added);
        final totalWords = TextUtils.countWords(acc + added);
        _debugLogger.info(
          "Bloco $block aceito: $blockWords palavras (total acumulado: $totalWords)",
          blockNumber: block,
        );

        // 🆕 v7.6.123: Contador de mantras em tempo real
        _trackMantrasInBlock(added, block);

        acc += added;
        await Future.delayed(const Duration(milliseconds: 50));
      }

      if (_isCancelled)
        return ScriptResult.error(errorMessage: 'Geração cancelada');

      _stopWatchdog();

      var finalScript = acc.replaceAll(
        RegExp(r'PERSONAGEM MENCIONADO:\s*'),
        '',
      );

      // 🚀 OTIMIZAÇÃO: Processar remoção de duplicatas em Isolate
      if (finalScript.length > 5000) {
        finalScript = await compute(
          _removeAllDuplicateParagraphsIsolate,
          finalScript,
        );
      } else {
        finalScript = TextFilter.removeAllDuplicateParagraphs(finalScript);
      }

      // 🚫 v7.6.123: Limitar repetições excessivas de frases-mantra (REDUZIDO para 2x)
      finalScript = TextFilter.limitMantraRepetition(
        finalScript,
        maxOccurrences: 2, // 🆕 v7.6.123: Reduzido de 4→2 (Flash repete muito)
      );

      // 🚀 v7.6.117: Validação de título apenas para Pro (Flash é rápido, não precisa validar)
      final isFlashModelFinal = config.qualityMode.toLowerCase().contains(
        'flash',
      );
      if (config.title.trim().isNotEmpty && !isFlashModelFinal) {
        final validation = await _scriptValidator
            .validateTitleCoherenceRigorous(
              title: config.title,
              story: finalScript,
              language: config.language,
              apiKey: config.apiKey,
            );

        if (!(validation['isValid'] as bool? ?? true) &&
            (validation['confidence'] as int? ?? 0) < 50) {
          final missing =
              (validation['missingElements'] as List?)?.cast<String>() ?? [];
          if (missing.isNotEmpty) {
            try {
              final blocks = finalScript.split('\n\n');
              final context = blocks.length > 2
                  ? blocks.sublist(blocks.length - 2).join('\n\n')
                  : finalScript;
              final recoveryPrompt = ScriptPromptBuilder.buildRecoveryPrompt(
                config.title,
                missing,
                context,
                config.language,
              );
              final recovery = await _llmClient.generateText(
                apiKey: config.apiKey,
                model: _getSelectedModel(config.qualityMode),
                prompt: recoveryPrompt,
                maxTokens: 500,
              );
              if (recovery.isNotEmpty)
                finalScript = '$finalScript\n\n$recovery';
            } catch (e) {
              // Ignora falha na recuperação
            }
          }
        }
      }

      return ScriptResult(
        scriptText: finalScript,
        wordCount: TextUtils.countWords(finalScript),
        charCount: finalScript.length,
        paragraphCount: finalScript.split('\n').length,
        readingTime: (TextUtils.countWords(finalScript) / 150).ceil(),
      );
    } catch (e) {
      _stopWatchdog();
      if (_isCancelled)
        return ScriptResult.error(errorMessage: 'Geração cancelada');
      return ScriptResult.error(errorMessage: 'Erro: $e');
    }
  }

  void cancelGeneration() {
    _isCancelled = true;
    _stopWatchdog();
  }

  /// 🆕 v7.6.123: Rastreia mantras em tempo real durante a geração
  void _trackMantrasInBlock(String blockText, int blockNumber) {
    // Padrões comuns de mantras (simplificados para detecção rápida)
    final mantraPatterns = [
      r'verdadeira riqueza não se mede',
      r'caráter de um homem não se mede',
      r'gentileza é uma semente',
      r'vida é um rio',
      r'bondade sempre volta',
      r'plantava uma nova semente',
      r'teste.*continuava',
      r'construir com o coração',
    ];

    for (final pattern in mantraPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(blockText)) {
        _mantraCounterRealTime[pattern] =
            (_mantraCounterRealTime[pattern] ?? 0) + 1;

        final count = _mantraCounterRealTime[pattern]!;
        if (count >= 2) {
          if (kDebugMode) {
            debugPrint(
              '⚠️ [Bloco $blockNumber] Mantra detectado ${count}x: "$pattern"',
            );
          }
        }
      }
    }
  }

  void dispose() {
    _isCancelled = true;
    _stopWatchdog();
    try {
      _dio.close(force: true);
    } catch (e) {}
  }

  void resetState() {
    _isCancelled = false;
    _isOperationRunning = false;
    _failureCount = 0;
    _isCircuitOpen = false;
    _lastFailureTime = null;
    _stopWatchdog();
    _mantraCounterRealTime.clear(); // 🆕 v7.6.123: Limpar contador de mantras
    _globalRequestCount = 0;
    _globalLastRequestTime = DateTime.now();
    _rateLimitBusy = false;
    
    // 🚨 v7.6.153: LIMPAR CACHE DO PROMPT BUILDER
    // Evita acúmulo de dados de gerações anteriores (economia de tokens!)
    try {
      BlockPromptBuilder.clearCache();
    } catch (e) {}
  }

  void _startWatchdog() {
    _stopWatchdog();
    _isOperationRunning = true;
    _watchdogTimer = Timer(_maxOperationTime, () {
      if (_isOperationRunning && !_isCancelled) _isCancelled = true;
    });
  }

  void _stopWatchdog() {
    _watchdogTimer?.cancel();
    _isOperationRunning = false;
  }

  Future<void> _ensureRateLimit() async {
    int attempts = 0;
    while (_rateLimitBusy && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }
    if (attempts >= 100) return;
    _rateLimitBusy = true;

    try {
      final now = DateTime.now();
      if (now.difference(_globalLastRequestTime) > _rateLimitWindow) {
        _globalRequestCount = 0;
      }
      if (_globalRequestCount >= _maxRequestsPerWindow) {
        final wait = _rateLimitWindow - now.difference(_globalLastRequestTime);
        if (wait > Duration.zero && wait < const Duration(seconds: 30)) {
          _rateLimitBusy = false;
          await Future.delayed(wait);
          await _ensureRateLimit();
          return;
        }
      }
      _globalRequestCount++;
      _globalLastRequestTime = now;
    } finally {
      _rateLimitBusy = false;
    }
  }

  Duration _getAdaptiveDelay({required int blockNumber}) {
    if (_lastSuccessfulCall != null &&
        DateTime.now().difference(_lastSuccessfulCall!) <
            const Duration(seconds: 3)) {
      _consecutiveSuccesses++;
      if (_consecutiveSuccesses >= 2) {
        return blockNumber <= 10
            ? const Duration(milliseconds: 300)
            : const Duration(milliseconds: 800);
      }
    }
    if (_consecutive503Errors > 0) {
      _consecutiveSuccesses = 0;
      return Duration(seconds: min(5 * _consecutive503Errors, 15));
    }
    _consecutiveSuccesses = 0;
    _consecutive503Errors = max(0, _consecutive503Errors - 1);
    // 🚀 v7.6.117: Delays reduzidos para acelerar geração
    if (blockNumber <= 5) return const Duration(milliseconds: 250);
    if (blockNumber <= 15) return const Duration(milliseconds: 500);
    if (blockNumber <= 25) return const Duration(milliseconds: 750);
    return const Duration(seconds: 1);
  }

  Future<T> _retryOnRateLimit<T>(
    Future<T> Function() op, {
    int maxRetries = 6,
  }) async {
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (_isCancelled) throw Exception('Operação cancelada');
        await _ensureRateLimit();
        if (_isCancelled) throw Exception('Operação cancelada');
        return await op();
      } catch (e) {
        if (_isCancelled) throw Exception('Operação cancelada');
        final errorStr = e.toString().toLowerCase();

        if (errorStr.contains('503') ||
            errorStr.contains('service unavailable')) {
          _consecutive503Errors++;
          _consecutiveSuccesses = 0;
          if (attempt < maxRetries - 1) {
            final delay = Duration(seconds: min(10 * (1 << attempt), 90));
            await Future.delayed(delay);
            continue;
          }
          throw Exception(
            'Servidor Gemini indisponível após múltiplas tentativas.',
          );
        }

        if (errorStr.contains('429') && attempt < maxRetries - 1) {
          // 🚨 v7.6.153: DELAY EXPONENCIAL AGRESSIVO para Rate Limit (429)
          // Gemini Free: 2 RPM → precisa esperar ~30s entre requisições
          final delaySeconds = min(60, 30 * (1 << attempt)); // 30s, 60s, 60s...
          _debugLogger.warning(
            "⚠️ Rate Limit (429) - aguardando ${delaySeconds}s antes de retry ${attempt + 1}/$maxRetries",
          );
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }

        if ((errorStr.contains('timeout') || errorStr.contains('connection')) &&
            attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Limite de tentativas excedido');
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

  Future<String> _generateBlockContent(
    String previous,
    int target,
    String phase,
    ScriptConfig c,
    CharacterTracker tracker,
    int blockNumber,
    int totalBlocks, {
    bool avoidRepetition = false,
    WorldState? worldState,
    String?
    fullContextForCounter, // 🆕 v7.6.142.1: Contexto completo para contador
  }) async {
    if (target <= 0) return '';

    final maxContextBlocks = ContextBuilder.getMaxContextBlocks(c.language);
    final rawContext = previous.isEmpty
        ? ''
        : ContextBuilder.buildLimitedContext(
            previous,
            blockNumber,
            maxContextBlocks,
            TextUtils.countWords,
          );

    // 🔧 v7.6.146: TRIM mais agressivo para economizar tokens (cap 15k chars)
    // Mantém últimos ~2.5 blocos para contexto, acelera blocos finais
    final contextoPrevio = rawContext.length > 15000
        ? '...[contexto anterior resumido]\n\n${rawContext.substring(rawContext.length - 15000)}'
        : rawContext;

    String trackerInfo = '';
    if (tracker.confirmedNames.isNotEmpty && blockNumber > 1) {
      final sb = StringBuffer();
      sb.writeln('LEMBRETE OBRIGATÓRIO DE NOMES:');
      for (final name in tracker.confirmedNames) {
        final role = tracker.getRole(name) ?? 'personagem';
        sb.writeln('  • $name = $role');
      }
      if (c.protagonistName.trim().isNotEmpty) {
        sb.writeln('  • PROTAGONISTA: ${c.protagonistName.trim()}');
      }
      sb.writeln('PROIBIDO MUDAR ESTES NOMES!');
      trackerInfo = sb.toString();
    }

    final characterGuidance = CharacterGuidanceBuilder.buildGuidance(
      c,
      tracker,
    );
    // 🔧 v7.6.147: Passa blockNumber para otimizar fatos nos blocos finais
    String worldStateContext = worldState != null && blockNumber > 1
        ? worldState.getContextForPrompt(currentBlock: blockNumber)
        : '';

    final languageMultiplier =
        PerspectiveBuilder.getLanguageVerbosityMultiplier(c.language);
    final adjustedTarget = (target * languageMultiplier).round();

    // Detectar idioma coreano
    final isKorean =
        c.language.contains('한국어') ||
        c.language.toLowerCase().contains('coreano') ||
        c.language.toLowerCase().contains('korean');

    // 📊 v7.6.120: Limites MUITO relaxados para Flash (aceita quase tudo)
    // Flash varia MUITO, então precisamos aceitar praticamente qualquer coisa
    // 🇰🇷 v7.6.149: Coreano também precisa de limites mais relaxados (API gera menos palavras)
    final isFlashModel = c.qualityMode.toLowerCase().contains('flash');
    final minPercentForPrompt = isFlashModel
        ? 0.80
        : isKorean
            ? 0.75 // 🇰🇷 Coreano: 75% (mais relaxado)
            : 0.92; // Flash: 80%, Pro: 92%
    final minPercentForValidation = isFlashModel
        ? 0.45
        : isKorean
            ? 0.50 // 🇰🇷 Coreano: 50% (mais relaxado que Pro 65%)
            : 0.65; // Flash: 45% (MUITO relaxado), Pro: 65%

    final minAcceptableForPrompt = (adjustedTarget * minPercentForPrompt)
        .round();
    final minAcceptable = (adjustedTarget * minPercentForValidation).round();
    final maxAcceptable = (adjustedTarget * 1.50)
        .round(); // 🆕 v7.6.120: Aumentado de 1.15 para 1.50 (150%)

    final isSpanish =
        c.language.toLowerCase().contains('espanhol') ||
        c.language.toLowerCase().contains('spanish');

    // 📝 v7.6.115: Instrução de extensão adaptativa (Flash e Coreano precisam de mais ênfase)
    // 🇰🇷 v7.6.149: Coreano - enfatizar MUITO mais a necessidade de blocos longos
    final extensionEmphasis = isFlashModel
        ? '\n\n⚠️ ATENÇÃO EXTENSÃO: Escreva de forma EXTREMAMENTE detalhada e descritiva!\n'
              'Desenvolva CADA cena com muitos detalhes sensoriais (sons, cheiros, texturas).\n'
              'Use diálogos longos e reflexões internas elaboradas.\n'
              'NÃO seja conciso - seja EXPANSIVO e DETALHADO!\n'
              'Meta: $adjustedTarget palavras - NÃO pare antes disso!'
        : isKorean
            ? '\n\n⚠️⚠️⚠️ 길이 주의 - 매우 중요!\n'
                  '최소 $minAcceptableForPrompt 단어 이상 작성해야 합니다!\n'
                  '목표: $adjustedTarget 단어 (이보다 적으면 거부됨)\n\n'
                  '각 장면을 매우 상세하게 묘사하세요:\n'
                  '• 감각적 세부사항 (소리, 냄새, 질감, 색상)\n'
                  '• 긴 대화와 내면적 성찰\n'
                  '• 등장인물의 감정과 생각을 깊이 있게\n'
                  '• 배경 설명을 풍부하게\n\n'
                  '간결하게 쓰지 마세요! 확장적이고 상세하게 작성하세요!'
            : '';

    // Usar minAcceptableForPrompt no prompt para incentivar mais palavras
    final measure = isSpanish
        ? 'GERE EXATAMENTE $adjustedTarget palabras (MÍNIMO $minAcceptableForPrompt, MÁXIMO $maxAcceptable)$extensionEmphasis'
        : isKorean
            ? '정확히 $adjustedTarget 단어를 생성하세요 (최소 $minAcceptableForPrompt 단어, 최대 $maxAcceptable 단어).\n'
                  '⚠️ 중요: 이 블록은 반드시 $adjustedTarget 단어에 도달해야 합니다!\n'
                  '각 장면을 자세히 설명하고, 감정과 대화를 풍부하게 표현하세요.\n'
                  '$minAcceptableForPrompt 단어보다 적게 쓰면 블록이 거부됩니다!$extensionEmphasis'
            : 'GERE EXATAMENTE $adjustedTarget palavras (MÍNIMO $minAcceptableForPrompt, MÁXIMO $maxAcceptable)$extensionEmphasis';

    final localizationGuidance = BaseRules.buildLocalizationGuidance(c);
    final narrativeStyleGuidance =
        NarrativeStyleBuilder.getNarrativeStyleGuidance(c);
    final instruction = previous.isEmpty
        ? (c.startWithTitlePhrase && c.title.trim().isNotEmpty
              ? BaseRules.getStartInstruction(
                  c.language,
                  withTitle: true,
                  title: c.title,
                )
              : BaseRules.getStartInstruction(c.language, withTitle: false))
        : BaseRules.getContinueInstruction(c.language);

    final labels = BaseRules.getMetadataLabels(c.language);
    final temaSection = c.tema == 'Livre (Sem Tema)'
        ? '// Modo Livre: Desenvolva baseado apenas no título e contexto'
        : '${labels['theme']}: ${c.tema}\n${labels['subtheme']}: ${c.subtema}';

    final titleSection = c.title.trim().isNotEmpty
        ? 'TÍTULO/PREMISSA OBRIGATÓRIA: "${c.title}"\nA história DEVE desenvolver todos os elementos do título!\n'
        : '';

    final forbiddenNamesWarning = tracker.confirmedNames.isNotEmpty
        ? 'NOMES PROIBIDOS: ${tracker.confirmedNames.join(', ')}\nNUNCA reutilize estes nomes!\n'
        : '';

    final perspectiveInstruction = PerspectiveBuilder.getPerspectiveInstruction(
      c.perspective,
      c,
    );

    final compactPrompt = MainPromptTemplate.buildCompactPrompt(
      language: BaseRules.getLanguageInstruction(c.language),
      instruction: instruction,
      temaSection: temaSection,
      localizacao: c.localizacao,
      localizationGuidance: localizationGuidance,
      narrativeStyleGuidance: narrativeStyleGuidance,
      customPrompt: c.customPrompt,
      useCustomPrompt: c.useCustomPrompt,
      nameList: '',
      trackerInfo: trackerInfo,
      measure: measure,
      isSpanish: isSpanish,
      adjustedTarget: adjustedTarget,
      minAcceptable:
          minAcceptableForPrompt, // 📊 v7.6.113: Usar limite rigoroso no prompt
      maxAcceptable: maxAcceptable,
      limitedNeeded: min(target, 3500),
      contextoPrevio: contextoPrevio,
      avoidRepetition: avoidRepetition,
      characterGuidance: characterGuidance,
      forbiddenNamesWarning: forbiddenNamesWarning,
      labels: labels,
      totalWords: c.quantity,
    );

    // 🆕 v7.6.142: CONTADOR PROGRESSIVO - Calcular e exibir info do Ato atual
    // 🆕 v7.6.142.1: Usar contexto completo se fornecido (evita bug em retries)
    final contextForCounter = fullContextForCounter ?? previous;
    final currentTotalWords = TextUtils.countWords(contextForCounter);
    final actInfo = StructureRules.getActInfo(
      currentTotalWords: currentTotalWords,
      targetTotalWords: c.quantity,
    );

    // 🔧 v7.6.148: Ajustar minAcceptable dinamicamente se ato próximo do limite
    // 🔧 v7.6.148.1: Usar o MENOR entre 35% do target OU palavras restantes do ato
    // 🇰🇷 v7.6.149: Para coreano, não ajustar (aceitar mais flexível)
    // 🎯 v7.6.151: Detectar último bloco e ser mais flexível
    final isLastBlock = blockNumber == totalBlocks;
    final isActNearLimit = actInfo.actRemainingWords < (adjustedTarget * 0.5);
    int finalMinAcceptable = minAcceptable;
    
    // 🎯 v7.6.151: Último bloco tem regras especiais (evitar retries desnecessários)
    if (isLastBlock && !isFlashModel) {
      // Para último bloco: aceitar 40% do target OU tudo que resta (o que for menor)
      final minFromTarget = (adjustedTarget * 0.40).round();
      final minFromRemaining = actInfo.actRemainingWords;
      finalMinAcceptable = min(minFromTarget, minFromRemaining);
      
      if (kDebugMode) {
        debugPrint('🎯 v7.6.151: Último bloco - minAcceptable flexível');
        debugPrint('   minFromTarget (40%): $minFromTarget');
        debugPrint('   minFromRemaining: $minFromRemaining');
        debugPrint('   finalMinAcceptable: $finalMinAcceptable');
      }
    } else if (isActNearLimit && !isFlashModel && !isKorean) {
      final adjustedMinPercent = 0.35; // 35% do target quando ato no limite
      final minFromTarget = (adjustedTarget * adjustedMinPercent).round();

      // 🎯 v7.6.148.1: Se palavras restantes < minFromTarget, usar 60% das restantes
      // Exemplo: restam 262 palavras → min = 157 palavras (60% de 262)
      final minFromRemaining = (actInfo.actRemainingWords * 0.6).round();

      // Usar o menor dos dois (evita exigir mais palavras que o ato permite)
      finalMinAcceptable = minFromTarget < minFromRemaining
          ? minFromTarget
          : minFromRemaining;
    }

    // 🇰🇷 v7.6.149: Para coreano, garantir que minAcceptable nunca seja > target
    if (isKorean && finalMinAcceptable > adjustedTarget) {
      finalMinAcceptable = (adjustedTarget * 0.50).round();
    }

    // 🇰🇷 v7.6.149: Log de debug para coreano
    if (kDebugMode && isKorean) {
      debugPrint('🇰🇷 DEBUG COREANO:');
      debugPrint('   adjustedTarget: $adjustedTarget');
      debugPrint('   minAcceptable (50%): $minAcceptable');
      debugPrint('   minAcceptableForPrompt (75%): $minAcceptableForPrompt');
      debugPrint('   finalMinAcceptable: $finalMinAcceptable');
      debugPrint('   isActNearLimit: $isActNearLimit');
    }

    // Remover cálculo duplicado de actInfo (já calculado acima para v7.6.148)
    // 📊 Log do contador progressivo
    if (kDebugMode) {
      debugPrint('');
      debugPrint(
        '📊 ════════════════════════════════════════════════════════════',
      );
      debugPrint('📊 CONTADOR PROGRESSIVO - Bloco $blockNumber/$totalBlocks');
      debugPrint(
        '📊 ════════════════════════════════════════════════════════════',
      );
      debugPrint('📍 Ato: ${actInfo.actNumber} - ${actInfo.actName}');
      debugPrint(
        '📈 Palavras do Ato: ${actInfo.actCurrentWords}/${actInfo.actMaxWords}',
      );
      debugPrint('⏳ Restantes: ${actInfo.actRemainingWords} palavras');
      debugPrint('📊 Total acumulado: $currentTotalWords palavras');
      if (isLastBlock) {
        debugPrint('🏁 ÚLTIMO BLOCO - minAcceptable flexível ($finalMinAcceptable palavras)');
      }
      if (actInfo.actNumber == 2 && actInfo.actRemainingWords < 300) {
        debugPrint('🚨 ALERTA: Ato 2 próximo do limite!');
      }
      if (actInfo.actNumber == 3 && actInfo.actRemainingWords > 500) {
        debugPrint('✅ Ato 3 com espaço suficiente');
      }
      // 🔧 v7.6.148: Log de ajuste dinâmico de mínimo
      if (isActNearLimit && !isLastBlock) {
        debugPrint(
          '⚙️ v7.6.148.1: minAcceptable ajustado para $finalMinAcceptable palavras',
        );
        debugPrint(
          '   (35% target=${(adjustedTarget * 0.35).round()}, 60% restantes=${(actInfo.actRemainingWords * 0.6).round()}, usando menor)',
        );
      }
      debugPrint(
        '📊 ════════════════════════════════════════════════════════════',
      );
      debugPrint('');
    }

    // 🚨 Construir mensagem visual do contador para o prompt
    final progressCounter = _buildProgressCounter(actInfo, isSpanish);

    final prompt =
        '$perspectiveInstruction\n\n$progressCounter\n\n$worldStateContext$titleSection$compactPrompt';

    try {
      final languageNormalized = c.language.toLowerCase();
      final isCyrillic =
          languageNormalized.contains('russo') ||
          languageNormalized.contains('búlgar');
      final tokenMultiplier = c.measureType == 'caracteres'
          ? (isCyrillic ? 5.0 : 2.5)
          : 12.0;
      final maxTokens = min((target * tokenMultiplier).ceil(), 50000);

      final selectedModel = _getSelectedModel(c.qualityMode);

      // ⏱️ v7.6.118: CRONOMETRAGEM DA API
      final apiStartTime = DateTime.now();
      if (kDebugMode) {
        debugPrint('⏱️ [Bloco $blockNumber] Iniciando chamada API...');
        debugPrint('   📦 Prompt: ${prompt.length} chars');
      }

      final data = await _llmClient.generateText(
        apiKey: c.apiKey,
        model: selectedModel,
        prompt: prompt,
        maxTokens: maxTokens,
      );

      // ⏱️ Log do tempo de resposta da API
      final apiEndTime = DateTime.now();
      final apiDuration = apiEndTime.difference(apiStartTime);
      if (kDebugMode) {
        debugPrint(
          '⏱️ [Bloco $blockNumber] API respondeu em ${apiDuration.inMilliseconds}ms (${apiDuration.inSeconds}s)',
        );
        debugPrint('   📝 Resposta: ${data.length} chars');
      }

      // 🚨 v7.6.152: LIMITE RÍGIDO DE CHARS - Rejeitar blocos com dobro de tamanho
      // Evita blocos gigantes que causam duplicação narrativa
      // v7.6.156: Ajustado por idioma (chars/palavra varia por idioma)
      // v7.6.162: 1.5× → 1.25× (muito restritivo, causou crash no Bloco 1)
      // v7.6.163: Validação diferenciada (1.35× blocos 1-6, 1.25× blocos 7+)
      // v7.6.163.1: 1.35× → 1.45× blocos 1-6 (6609 chars ainda não passava)
      // v7.6.163.2: 1.45× → 1.47× blocos 1-6 (garantir 6609 passa: 4520×1.47=6644)
      final charsPerWord = BlockPromptBuilder.getCharsPerWordForLanguage(c.language);
      final expectedMaxChars = (adjustedTarget * charsPerWord * 1.08).round();
      final validationMultiplier = blockNumber >= 7 ? 1.25 : 1.47;
      if (data.length > expectedMaxChars * validationMultiplier) {
        _debugLogger.warning(
          "Bloco $blockNumber rejeitado: resposta muito longa (${data.length} chars, máx ${(expectedMaxChars * validationMultiplier).round()})",
          blockNumber: blockNumber,
        );
        return '';
      }

      if (data.isNotEmpty) {
        _lastSuccessfulCall = DateTime.now();
        _consecutive503Errors = max(0, _consecutive503Errors - 1);
      }

      final filtered = data.isNotEmpty
          ? TextFilter.filterDuplicateParagraphs(previous, data)
          : '';

      if (filtered.isNotEmpty) {
        if (!_characterValidation.validateProtagonistName(
              filtered,
              c,
              blockNumber,
            ) ||
            !_characterValidation.validateFamilyRelationships(
              filtered,
              blockNumber,
            )) {
          return '';
        }

        if (blockNumber == totalBlocks) {
          tracker.detectResolutionInText(filtered, blockNumber);
          if (tracker.getClosureRate() < 0.90) return '';
        }

        final wordCount = TextUtils.countWords(filtered);

        // ⚠️ v7.6.120: Validar contagem de palavras com tolerância MUITO relaxada para Flash
        // Flash varia muito (pode gerar 500 ou 3000 palavras), então aceitamos quase tudo
        // 🚨 v7.6.152: LIMITE MAIS RÍGIDO - Máximo 40% acima do target (não 50%)
        final maxOveragePercent = isFlashModel
            ? 120.0
            : 40.0; // Pro: até 40% acima do target (antes era 50%)
        final overagePercent =
            ((wordCount - adjustedTarget) / adjustedTarget) * 100;
        if (overagePercent > maxOveragePercent) {
          _debugLogger.warning(
            "Bloco $blockNumber rejeitado: excedeu limite (+${overagePercent.toStringAsFixed(1)}%, máx: ${maxOveragePercent.toStringAsFixed(0)}%)",
            blockNumber: blockNumber,
          );
          return '';
        }

        // 🚨 NOVO: Rejeitar blocos muito curtos (abaixo de 80% do target)
        // 🔧 v7.6.148: Usar finalMinAcceptable (ajustado dinamicamente)
        if (wordCount < finalMinAcceptable) {
          _debugLogger.warning(
            "Bloco $blockNumber rejeitado: muito curto ($wordCount palavras, mínimo $finalMinAcceptable)",
            blockNumber: blockNumber,
          );
          return '';
        }
      }

      return filtered.isNotEmpty ? '\n$filtered' : '';
    } catch (e) {
      return '';
    }
  }

  Future<String> generateTextWithApiKey({
    required String prompt,
    required String apiKey,
    String? model,
    String qualityMode = 'pro',
    int maxTokens = 16384,
  }) async {
    final effectiveModel = model ?? _getSelectedModel(qualityMode);
    if (_isCancelled) _isCancelled = false;

    return await _retryOnRateLimit(() async {
      final result = await _llmClient.generateText(
        apiKey: apiKey,
        model: effectiveModel,
        prompt: prompt,
        maxTokens: maxTokens,
      );
      if (result.isNotEmpty) {
        _lastSuccessfulCall = DateTime.now();
        _consecutive503Errors = max(0, _consecutive503Errors - 1);
      }
      return result.isNotEmpty ? TextCleaner.cleanGeneratedText(result) : '';
    });
  }

  Future<Map<String, String>> generateCtasForScript({
    required String scriptContent,
    required String apiKey,
    required List<String> ctaTypes,
    String? customTheme,
    String language = 'Português',
    String perspective = 'terceira_pessoa',
    String qualityMode = 'pro',
  }) async {
    try {
      final scriptContext = await _analyzeScriptContext(
        scriptContent,
        apiKey,
        language,
        'flash',
      );
      final prompt = CtaGenerator.buildAdvancedCtaPrompt(
        scriptContent,
        ctaTypes,
        customTheme,
        language,
        scriptContext,
        perspective,
      );
      final result = await generateTextWithApiKey(
        prompt: prompt,
        apiKey: apiKey,
        qualityMode: 'flash',
        maxTokens: 3072,
      );
      return result.isEmpty
          ? {}
          : CtaGenerator.parseCtaResponseWithValidation(
              result,
              ctaTypes,
              scriptContent,
            );
    } catch (e) {
      return {};
    }
  }

  Future<String> _analyzeScriptContext(
    String scriptContent,
    String apiKey,
    String language,
    String qualityMode,
  ) async {
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

  /// 🆕 v7.6.142: Constrói mensagem visual do contador progressivo
  String _buildProgressCounter(ActInfo actInfo, bool isSpanish) {
    final wordLabel = isSpanish ? 'PALABRA' : 'PALAVRA';
    final wordsLabel = isSpanish ? 'PALABRAS' : 'PALAVRAS';
    final remainingLabel = isSpanish ? 'FALTAN' : 'FALTAM';
    final currentActLabel = isSpanish ? 'ACTO ACTUAL' : 'ATO ATUAL';

    // Determinar cor/urgência com base nas palavras restantes
    String urgency;
    String icon;
    if (actInfo.actNumber == 2 && actInfo.actRemainingWords < 300) {
      // Ato 2 próximo do limite - URGÊNCIA MÁXIMA
      urgency = '🚨🚨🚨 ATENÇÃO CRÍTICA 🚨🚨🚨';
      icon = '🚨';
    } else if (actInfo.actNumber == 3 && actInfo.actRemainingWords > 500) {
      // Ato 3 com muito espaço ainda - ALERTA
      urgency = '✅ ESPAÇO SUFICIENTE ✅';
      icon = '✅';
    } else {
      urgency = '📊 PROGRESSO NORMAL 📊';
      icon = '📊';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );
    buffer.writeln('$icon CONTADOR PROGRESSIVO - $currentActLabel $icon');
    buffer.writeln(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );
    buffer.writeln('');
    buffer.writeln('📍 ${actInfo.actName}');
    buffer.writeln('');
    buffer.writeln(
      '$wordLabel ${actInfo.actCurrentWords} DE ${actInfo.actMaxWords} $wordsLabel',
    );
    buffer.writeln('$remainingLabel: ${actInfo.actRemainingWords} $wordsLabel');
    buffer.writeln('');
    buffer.writeln(urgency);
    buffer.writeln('');

    // Mensagens específicas por Ato
    if (actInfo.actNumber == 1) {
      buffer.writeln('⚠️ VOCÊ ESTÁ NO ATO 1 (Setup/Preparação)');
      buffer.writeln('   • Apresente protagonista, conflito e mundo');
      buffer.writeln(
        '   • Quando atingir ${actInfo.actMaxWords} palavras → INICIE Ato 2',
      );
    } else if (actInfo.actNumber == 2) {
      if (actInfo.actRemainingWords < 300) {
        buffer.writeln('🚨 VOCÊ ESTÁ CHEGANDO NO LIMITE DO ATO 2! 🚨');
        buffer.writeln(
          '   • Faltam apenas ${actInfo.actRemainingWords} palavras!',
        );
        buffer.writeln('   • PREPARE o clímax e ENCERRE este Ato!');
        buffer.writeln('   • ATO 3 precisa de MÍNIMO 35% do roteiro total!');
        buffer.writeln(
          '   • Se ultrapassar o limite, a história ficará INCOMPLETA!',
        );
      } else {
        buffer.writeln('⚠️ VOCÊ ESTÁ NO ATO 2 (Desenvolvimento)');
        buffer.writeln('   • Desenvolva conflitos e obstáculos');
        buffer.writeln(
          '   • 🛑 LIMITE MÁXIMO: ${actInfo.actMaxWords} palavras',
        );
        buffer.writeln('   • Quando chegar perto do limite → INICIE Ato 3');
      }
    } else if (actInfo.actNumber == 3) {
      if (actInfo.actRemainingWords > 500) {
        buffer.writeln('✅ VOCÊ ESTÁ NO ATO 3 (Resolução) - ESPAÇO SUFICIENTE');
        buffer.writeln(
          '   • Você tem ${actInfo.actRemainingWords} palavras restantes!',
        );
        buffer.writeln(
          '   • DESENVOLVA clímax, resolução e desfecho COMPLETOS',
        );
        buffer.writeln(
          '   • NÃO apresse o final - USE todo o espaço disponível!',
        );
      } else {
        buffer.writeln('⚠️ VOCÊ ESTÁ NO ATO 3 (Resolução)');
        buffer.writeln('   • Conclua com clímax + resolução + desfecho');
        buffer.writeln('   • MÍNIMO: ${actInfo.actMaxWords} palavras');
        buffer.writeln('   • Faltam: ${actInfo.actRemainingWords} palavras');
      }
    }

    buffer.writeln('');
    buffer.writeln(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

    return buffer.toString();
  }
}
