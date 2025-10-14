import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/script_result.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';
import 'package:flutter_gerador/data/models/localization_level.dart';
import 'package:flutter_gerador/data/services/name_generator_service.dart';
import 'package:flutter_gerador/data/models/debug_log.dart';

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
  final paragraphs = limitedPrevious.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
  
  // 🚀 OTIMIZAÇÃO CRÍTICA: Limitar a 10 últimos parágrafos
  final recentParagraphs = paragraphs.length > 10 
      ? paragraphs.sublist(paragraphs.length - 10)
      : paragraphs;
  
  // Dividir novo bloco em parágrafos
  final newParagraphs = newBlock.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
  
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
            'reason': '$highSimilarityCount paragraphs with ${(similarity * 100).toStringAsFixed(1)}% similarity'
          };
        }
        break;
      }
    }
  }
  
  return {'isSimilar': false, 'reason': 'Content is unique'};
}

/// Versão estática de _hasLiteralDuplication para usar em Isolate
bool _hasLiteralDuplicationStatic(String newBlock, String previousContent) {
  if (previousContent.length < 1000) return false;
  
  final newWords = newBlock.split(RegExp(r'\s+'));
  if (newWords.length < 200) return false;
  
  final prevWords = previousContent.split(RegExp(r'\s+'));
  if (prevWords.length < 200) return false;
  
  for (int i = 0; i <= newWords.length - 200; i++) {
    final newSequence = newWords.sublist(i, i + 200).join(' ').toLowerCase();
    
    for (int j = 0; j <= prevWords.length - 200; j++) {
      final prevSequence = prevWords.sublist(j, j + 200).join(' ').toLowerCase();
      
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
  
  final normalized1 = text1.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  final normalized2 = text2.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  
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

/// 🌍 Mapa de traduções de termos de parentesco por idioma
const Map<String, Map<String, String>> _familyTermsTranslations = {
  'português': {
    'Pai': 'pai', 'pai': 'pai',
    'Mãe': 'mãe', 'mãe': 'mãe',
    'Filho': 'filho', 'filho': 'filho',
    'Filha': 'filha', 'filha': 'filha',
    'Avô': 'avô', 'avô': 'avô',
    'Avó': 'avó', 'avó': 'avó',
    'Esposa': 'esposa', 'esposa': 'esposa',
    'Marido': 'marido', 'marido': 'marido',
    'Irmão': 'irmão', 'irmão': 'irmão',
    'Irmã': 'irmã', 'irmã': 'irmã',
    'Tio': 'tio', 'tio': 'tio',
    'Tia': 'tia', 'tia': 'tia',
  },
  'inglês': {
    'Pai': 'father', 'pai': 'father',
    'Mãe': 'mother', 'mãe': 'mother',
    'Filho': 'son', 'filho': 'son',
    'Filha': 'daughter', 'filha': 'daughter',
    'Avô': 'grandfather', 'avô': 'grandfather',
    'Avó': 'grandmother', 'avó': 'grandmother',
    'Esposa': 'wife', 'esposa': 'wife',
    'Marido': 'husband', 'marido': 'husband',
    'Irmão': 'brother', 'irmão': 'brother',
    'Irmã': 'sister', 'irmã': 'sister',
    'Tio': 'uncle', 'tio': 'uncle',
    'Tia': 'aunt', 'tia': 'aunt',
  },
  'espanhol(mexicano)': {
    'Pai': 'padre', 'pai': 'padre',
    'Mãe': 'madre', 'mãe': 'madre',
    'Filho': 'hijo', 'filho': 'hijo',
    'Filha': 'hija', 'filha': 'hija',
    'Avô': 'abuelo', 'avô': 'abuelo',
    'Avó': 'abuela', 'avó': 'abuela',
    'Esposa': 'esposa', 'esposa': 'esposa',
    'Marido': 'esposo', 'marido': 'esposo',
    'Irmão': 'hermano', 'irmão': 'hermano',
    'Irmã': 'hermana', 'irmã': 'hermana',
    'Tio': 'tío', 'tio': 'tío',
    'Tia': 'tía', 'tia': 'tía',
  },
  'francês': {
    'Pai': 'père', 'pai': 'père',
    'Mãe': 'mère', 'mãe': 'mère',
    'Filho': 'fils', 'filho': 'fils',
    'Filha': 'fille', 'filha': 'fille',
    'Avô': 'grand-père', 'avô': 'grand-père',
    'Avó': 'grand-mère', 'avó': 'grand-mère',
    'Esposa': 'épouse', 'esposa': 'épouse',
    'Marido': 'mari', 'marido': 'mari',
    'Irmão': 'frère', 'irmão': 'frère',
    'Irmã': 'sœur', 'irmã': 'sœur',
    'Tio': 'oncle', 'tio': 'oncle',
    'Tia': 'tante', 'tia': 'tante',
  },
  'alemão': {
    'Pai': 'Vater', 'pai': 'Vater',
    'Mãe': 'Mutter', 'mãe': 'Mutter',
    'Filho': 'Sohn', 'filho': 'Sohn',
    'Filha': 'Tochter', 'filha': 'Tochter',
    'Avô': 'Großvater', 'avô': 'Großvater',
    'Avó': 'Großmutter', 'avó': 'Großmutter',
    'Esposa': 'Ehefrau', 'esposa': 'Ehefrau',
    'Marido': 'Ehemann', 'marido': 'Ehemann',
    'Irmão': 'Bruder', 'irmão': 'Bruder',
    'Irmã': 'Schwester', 'irmã': 'Schwester',
    'Tio': 'Onkel', 'tio': 'Onkel',
    'Tia': 'Tante', 'tia': 'Tante',
  },
  'italiano': {
    'Pai': 'padre', 'pai': 'padre',
    'Mãe': 'madre', 'mãe': 'madre',
    'Filho': 'figlio', 'filho': 'figlio',
    'Filha': 'figlia', 'filha': 'figlia',
    'Avô': 'nonno', 'avô': 'nonno',
    'Avó': 'nonna', 'avó': 'nonna',
    'Esposa': 'moglie', 'esposa': 'moglie',
    'Marido': 'marito', 'marido': 'marito',
    'Irmão': 'fratello', 'irmão': 'fratello',
    'Irmã': 'sorella', 'irmã': 'sorella',
    'Tio': 'zio', 'tio': 'zio',
    'Tia': 'zia', 'tia': 'zia',
  },
  'russo': {
    'Pai': 'отец', 'pai': 'отец',
    'Mãe': 'мать', 'mãe': 'мать',
    'Filho': 'сын', 'filho': 'сын',
    'Filha': 'дочь', 'filha': 'дочь',
    'Avô': 'дедушка', 'avô': 'дедушка',
    'Avó': 'бабушка', 'avó': 'бабушка',
    'Esposa': 'жена', 'esposa': 'жена',
    'Marido': 'муж', 'marido': 'муж',
    'Irmão': 'брат', 'irmão': 'брат',
    'Irmã': 'сестра', 'irmã': 'сестра',
    'Tio': 'дядя', 'tio': 'дядя',
    'Tia': 'тётя', 'tia': 'тётя',
  },
  'polonês': {
    'Pai': 'ojciec', 'pai': 'ojciec',
    'Mãe': 'matka', 'mãe': 'matka',
    'Filho': 'syn', 'filho': 'syn',
    'Filha': 'córka', 'filha': 'córka',
    'Avô': 'dziadek', 'avô': 'dziadek',
    'Avó': 'babcia', 'avó': 'babcia',
    'Esposa': 'żona', 'esposa': 'żona',
    'Marido': 'mąż', 'marido': 'mąż',
    'Irmão': 'brat', 'irmão': 'brat',
    'Irmã': 'siostra', 'irmã': 'siostra',
    'Tio': 'wujek', 'tio': 'wujek',
    'Tia': 'ciocia', 'tia': 'ciocia',
  },
  'croata': {
    'Pai': 'otac', 'pai': 'otac',
    'Mãe': 'majka', 'mãe': 'majka',
    'Filho': 'sin', 'filho': 'sin',
    'Filha': 'kći', 'filha': 'kći',
    'Avô': 'djed', 'avô': 'djed',
    'Avó': 'baka', 'avó': 'baka',
    'Esposa': 'supruga', 'esposa': 'supruga',
    'Marido': 'suprug', 'marido': 'suprug',
    'Irmão': 'brat', 'irmão': 'brat',
    'Irmã': 'sestra', 'irmã': 'sestra',
    'Tio': 'ujak', 'tio': 'ujak',
    'Tia': 'teta', 'tia': 'teta',
  },
  'búlgaro': {
    'Pai': 'баща', 'pai': 'баща',
    'Mãe': 'майка', 'mãe': 'майка',
    'Filho': 'син', 'filho': 'син',
    'Filha': 'дъщеря', 'filha': 'дъщеря',
    'Avô': 'дядо', 'avô': 'дядо',
    'Avó': 'баба', 'avó': 'баба',
    'Esposa': 'съпруга', 'esposa': 'съпруга',
    'Marido': 'съпруг', 'marido': 'съпруг',
    'Irmão': 'брат', 'irmão': 'брат',
    'Irmã': 'сестра', 'irmã': 'сестра',
    'Tio': 'чичо', 'tio': 'чичо',
    'Tia': 'леля', 'tia': 'леля',
  },
  'turco': {
    'Pai': 'baba', 'pai': 'baba',
    'Mãe': 'anne', 'mãe': 'anne',
    'Filho': 'oğul', 'filho': 'oğul',
    'Filha': 'kız', 'filha': 'kız',
    'Avô': 'dede', 'avô': 'dede',
    'Avó': 'nine', 'avó': 'nine',
    'Esposa': 'eş', 'esposa': 'eş',
    'Marido': 'koca', 'marido': 'koca',
    'Irmão': 'erkek kardeş', 'irmão': 'erkek kardeş',
    'Irmã': 'kız kardeş', 'irmã': 'kız kardeş',
    'Tio': 'amca', 'tio': 'amca',
    'Tia': 'teyze', 'tia': 'teyze',
  },
  'romeno': {
    'Pai': 'tată', 'pai': 'tată',
    'Mãe': 'mamă', 'mãe': 'mamă',
    'Filho': 'fiu', 'filho': 'fiu',
    'Filha': 'fiică', 'filha': 'fiică',
    'Avô': 'bunic', 'avô': 'bunic',
    'Avó': 'bunică', 'avó': 'bunică',
    'Esposa': 'soție', 'esposa': 'soție',
    'Marido': 'soț', 'marido': 'soț',
    'Irmão': 'frate', 'irmão': 'frate',
    'Irmã': 'soră', 'irmã': 'soră',
    'Tio': 'unchi', 'tio': 'unchi',
    'Tia': 'mătușă', 'tia': 'mătușă',
  },
  // Adicione mais idiomas conforme necessário
};

/// ImplementaÃ§Ã£o consolidada limpa do GeminiService
class GeminiService {
  final Dio _dio;
  final String _instanceId;
  bool _isCancelled = false;

  // Debug Logger
  final _debugLogger = DebugLogManager();

  // Circuit breaker
  bool _isCircuitOpen = false;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  static const int _maxFailures = 5; // Aumentado de 3 para 5
  static const Duration _circuitResetTime = Duration(seconds: 30); // Reduzido de 2 min para 30s

  // 🚨 Controle de bloqueio de conteúdo
  int _consecutiveBlocks = 0;
  static const int _maxConsecutiveBlocks = 3; // Após 3 bloqueios, reduzir contexto drasticamente

  // ===== RATE LIMITING GLOBAL OTIMIZADO PARA GEMINI BILLING =====
  // OTIMIZADO: ConfiguraÃ§Ã£o mais agressiva baseada nos limites reais do Gemini
  static int _globalRequestCount = 0;
  static DateTime _globalLastRequestTime = DateTime.now();
  static const Duration _rateLimitWindow = Duration(seconds: 60); // AUMENTADO: Era 10s, agora 60s
  static const int _maxRequestsPerWindow = 50; // AUMENTADO: Era 8, agora 50 (mais prÃ³ximo dos limites reais)
  static bool _rateLimitBusy = false;

  // Watchdog
  Timer? _watchdogTimer;
  bool _isOperationRunning = false;
  static const Duration _maxOperationTime = Duration(minutes: 30); // Aumentado para 30 min para idiomas complexos (russo, chinês)

  GeminiService({String? instanceId})
      : _instanceId = instanceId ?? _genId(),
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 45),     // AUMENTADO: Era 30s, agora 45s
          receiveTimeout: const Duration(minutes: 5),      // AUMENTADO: Era 3min, agora 5min (para contextos grandes)
          sendTimeout: const Duration(seconds: 45),        // AUMENTADO: Era 30s, agora 45s
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
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
    ));
  }

  // ===================== API PÃšBLICA =====================
  Future<ScriptResult> generateScript(
    ScriptConfig config,
    void Function(GenerationProgress) onProgress,
  ) async {
    // 🔥 CORREÇÃO CRÍTICA: Resetar variáveis globais ANTES de verificar rate limit
    // Isso garante que cada nova geração comece do zero
    _resetGlobalRateLimit();
    
    if (!_canMakeRequest()) {
      return ScriptResult.error(errorMessage: 'ServiÃ§o temporariamente indisponÃ­vel. Tente mais tarde.');
    }
    
    // CORREÃ‡ÃƒO: Reset completo do estado para nova geraÃ§Ã£o
    resetState();
    
  // Tracker global alimentado com os nomes definidos pelo usuÃ¡rio/contexto
  final persistentTracker = _CharacterTracker();
  _bootstrapCharacterTracker(persistentTracker, config);
    
    _startWatchdog();
    final start = DateTime.now();
    try {
      final totalBlocks = _calculateTotalBlocks(config);
      var acc = '';
      
      for (var block = 1; block <= totalBlocks && !_isCancelled; block++) {
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
        final estTotal = progress > 0 ? Duration(milliseconds: (elapsed.inMilliseconds / progress).round()) : Duration.zero;
        final remaining = estTotal - elapsed;
        final logs = _generateBlockLogs(phase, block, totalBlocks, config);
        onProgress(GenerationProgress(
          percentage: progress,
          currentPhase: phase,
          phaseIndex: phaseIdx,
          totalPhases: _phases.length,
          currentBlock: block,
          totalBlocks: totalBlocks,
          estimatedTimeRemaining: remaining,
          logs: logs,
          wordsGenerated: _countWords(acc),
        ));
        final targetForBlock = _calculateTargetForBlock(block, totalBlocks, config);
        var added = await _retryOnRateLimit(() => _generateBlockContent(acc, targetForBlock, phase, config, persistentTracker, block));
        
        // 🔥 RETRY PARA BLOCOS VAZIOS: Se bloco retornou vazio, tentar novamente até 3 vezes
        if (added.trim().isEmpty && acc.length > 0) {
          if (kDebugMode) {
            debugPrint('⚠️ BLOCO $block VAZIO! Iniciando tentativas de retry...');
          }
          
          for (int retry = 1; retry <= 3; retry++) {
            if (kDebugMode) {
              debugPrint('🔄 Retry $retry/3 para bloco $block...');
            }
            
            // Aguardar 2 segundos antes de retry
            await Future.delayed(Duration(seconds: 2));
            
            // 🔥 AUMENTADO: Contexto de 3000 para 8000 chars para manter nomes em memória
            final contextForRetry = retry > 1 && acc.length > 8000
                ? acc.substring(acc.length - 8000)
                : acc;
            
            added = await _retryOnRateLimit(() => _generateBlockContent(
              contextForRetry, 
              targetForBlock, 
              phase, 
              config, 
              persistentTracker, 
              block
            ));
            
            if (added.trim().isNotEmpty) {
              if (kDebugMode) {
                debugPrint('✅ Retry $retry bem-sucedido! Bloco $block gerado.');
              }
              break;
            }
          }
          
          // Se após 3 tentativas ainda estiver vazio, logar aviso crítico
          if (added.trim().isEmpty) {
            if (kDebugMode) {
              debugPrint('❌ CRÍTICO: Bloco $block permaneceu vazio após 3 retries!');
              debugPrint('   Sistema continuará com próximo bloco...');
            }
          }
        }
        
        // � VALIDAÇÃO ANTI-REPETIÇÃO EM ISOLATE: Verificar sem travar UI
        if (added.trim().isNotEmpty && acc.length > 500) {
          // Executar em isolate separado para não bloquear UI thread
          final result = await compute(_isTooSimilarInIsolate, {
            'newBlock': added,
            'previousContent': acc,
            'threshold': 0.80, // 🔥 AJUSTADO: Era 0.85, agora 0.80 para maior sensibilidade
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
              debugPrint('❌ BLOCO $block REJEITADO: Muito similar ao conteúdo anterior!');
              debugPrint('   📊 Tamanho do bloco: ${_countWords(added)} palavras');
              debugPrint('   🔍 Motivo: ${result['reason']}');
              debugPrint('   🔄 Regenerando com aviso explícito contra repetição...');
            }
            
            // 🔥 TENTATIVA 1: Regenerar com prompt específico contra repetição
            final regenerated = await _retryOnRateLimit(() => _generateBlockContent(
              acc, 
              targetForBlock, 
              phase, 
              config, 
              persistentTracker, 
              block,
              avoidRepetition: true, // Flag especial
            ));
            
            // Verificar novamente com threshold ainda mais alto (90%)
            final retryResult = await compute(_isTooSimilarInIsolate, {
              'newBlock': regenerated,
              'previousContent': acc,
              'threshold': 0.85, // 🔥 AJUSTADO: Era 0.90, agora 0.85
            });
            
            final stillSimilar = retryResult['isSimilar'] as bool;
            
            if (stillSimilar) {
              if (kDebugMode) {
                debugPrint('⚠️ TENTATIVA 1 FALHOU: Ainda há similaridade alta!');
                debugPrint('   🔄 TENTATIVA 2: Regenerando novamente com contexto reduzido...');
              }
              
              // 🔥 AUMENTADO: Contexto de 3000 para 8000 chars para manter nomes em memória
              final contextoPrevioReduzido = acc.length > 8000 
                  ? acc.substring(acc.length - 8000) 
                  : acc;
              
              final regenerated2 = await _retryOnRateLimit(() => _generateBlockContent(
                contextoPrevioReduzido, 
                targetForBlock, 
                phase, 
                config, 
                persistentTracker, 
                block,
                avoidRepetition: true,
              ));
              
              final stillSimilar2 = _isTooSimilar(regenerated2, acc, threshold: 0.90);
              
              if (stillSimilar2) {
                if (kDebugMode) {
                  debugPrint('⚠️ TENTATIVA 2 FALHOU: Similaridade persiste!');
                  debugPrint('   ⚠️ DECISÃO: Usando versão menos similar (tentativa 1)');
                }
                acc += regenerated; // Usar primeira tentativa (menos similar que original)
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
            acc += added; // Usar versão original
          }
        } else {
          acc += added;
        }
        
        if (added.trim().isNotEmpty) {
          // 🚨 VALIDAÇÃO CRÍTICA 1: Verificar se nome da protagonista mudou
          _validateProtagonistName(added, config, block);
          
          // 🚨 VALIDAÇÃO CRÍTICA 2: Verificar se algum nome foi reutilizado
          _validateNameReuse(added, persistentTracker, block);
          
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
          
          _updateTrackerFromContextSnippet(persistentTracker, config, added);
          
          // 🔒 TRACKING APRIMORADO: Extrair TODOS os nomes após cada bloco
          // Isso captura personagens secundários que aparecem em blocos distantes (ex: Sônia no bloco 5, depois bloco 15)
          final allNamesInBlock = _extractNamesFromSnippet(added);
          for (final entry in allNamesInBlock.entries) {
            final name = entry.key;
            final count = entry.value;
            // Threshold mais baixo (1+) para personagens secundários
            if (count >= 1) {
              // 🔥 BLOQUEIO DE REUSO: Se nome já existe, não adicionar novamente
              if (persistentTracker.hasName(name)) {
                if (kDebugMode && count >= 2) {
                  debugPrint('✅ CONFIRMAÇÃO: "$name" reapareceu $count vez(es) no bloco $block');
                }
                continue; // Já rastreado, pular
              }
              
              // Verificar se não é stopword ou localização
              final normalized = name.toLowerCase();
              if (!_nameStopwords.contains(normalized) && 
                  normalized != config.localizacao.trim().toLowerCase()) {
                // 🔥 VALIDAÇÃO EXTRA: Verificar se nome está no banco curado
                if (NameGeneratorService.isValidName(name)) {
                  // 📚 SISTEMA DE NOTAS: Adicionar com número do bloco
                  persistentTracker.addName(name, blockNumber: block);
                  
                  // 🐛 DEBUG: Log personagem detectado
                  _debugLogger.character(
                    name,
                    "Personagem detectado",
                    blockNumber: block,
                    metadata: {
                      'frequencia': count,
                      'primeiraAparicao': block,
                    },
                  );
                  
                  if (kDebugMode) {
                    debugPrint('🔒 TRACKING SECUNDÁRIO (bloco $block): "$name" detectado $count vez(es)');
                  }
                } else if (kDebugMode) {
                  debugPrint('⚠️ NOME IGNORADO (não está no banco): "$name" (bloco $block)');
                }
              }
            }
          }
        }
        
        // OTIMIZADO: Checkpoint de estabilidade mais rÃ¡pido para Gemini Billing
        await Future.delayed(const Duration(milliseconds: 150)); // REDUZIDO: Era 300ms, agora 150ms
        
        // VerificaÃ§Ã£o de sanidade do resultado
        if (added.trim().isEmpty) {
          if (kDebugMode) debugPrint('[$_instanceId] AVISO: Bloco $block retornou vazio - continuando geraÃ§Ã£o');
          // CORREÃ‡ÃƒO: NÃ£o parar por causa de bloco vazio, apenas continuar
          await Future.delayed(const Duration(milliseconds: 200));
          continue; // Continuar para o prÃ³ximo bloco
        }
        
        // Limpeza de memÃ³ria otimizada
        if (kDebugMode) debugPrint('[$_instanceId] Checkpoint bloco $block - Limpeza memÃ³ria');
        await Future.delayed(const Duration(milliseconds: 50)); // REDUZIDO: Era 100ms, agora 50ms
        
        // Delay adicional entre blocos para evitar sobrecarga
        await Future.delayed(Duration(milliseconds: _getBlockDelay(block, totalBlocks)));
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
          debugPrint('[$_instanceId] âš ï¸ Meta nÃ£o atingida - Faltam $needed ${config.measureType}');
          debugPrint('[$_instanceId] ï¿½ DICA: Aumente o tamanho dos blocos iniciais para atingir a meta');
        }
      }

      if (_isCancelled) return ScriptResult.error(errorMessage: 'GeraÃ§Ã£o cancelada');



      _stopWatchdog();
      
      // 📊 LOG FINAL: Resumo de personagens rastreados
      if (kDebugMode && persistentTracker.confirmedNames.isNotEmpty) {
        debugPrint('📊 RESUMO FINAL DE PERSONAGENS:');
        debugPrint('   Total rastreado: ${persistentTracker.confirmedNames.length} personagem(ns)');
        debugPrint('   Nomes: ${persistentTracker.confirmedNames.join(", ")}');
      }
      
      // 🧹 LIMPAR MARCADORES DE DEBUG DO TEXTO FINAL
      final cleanedAcc = acc.replaceAll(RegExp(r'PERSONAGEM MENCIONADO:\s*'), '');
      
      // 🔍 DETECÇÃO FINAL: Verificar se há parágrafos duplicados (apenas LOG, não remove)
      if (kDebugMode) {
        _detectDuplicateParagraphsInFinalScript(cleanedAcc);
      }
      
      // 🐛 DEBUG: Log estatísticas finais
      final stats = _debugLogger.getStatistics();
      _debugLogger.success(
        "Geração completa!",
        details: "Roteiro finalizado com sucesso\n"
                "- Palavras: ${_countWords(cleanedAcc)}\n"
                "- Caracteres: ${cleanedAcc.length}\n"
                "- Personagens: ${persistentTracker.confirmedNames.length}\n"
                "- Logs gerados: ${stats['total']}",
        metadata: {
          'palavras': _countWords(cleanedAcc),
          'caracteres': cleanedAcc.length,
          'personagens': persistentTracker.confirmedNames.length,
          'logsTotal': stats['total'],
          'erros': stats['error'],
          'avisos': stats['warning'],
        },
      );
      
      return ScriptResult(
        scriptText: cleanedAcc,
        wordCount: _countWords(cleanedAcc),
        charCount: cleanedAcc.length,
        paragraphCount: cleanedAcc.split('\n').length,
        readingTime: (_countWords(cleanedAcc) / 150).ceil(),
      );
    } catch (e) {
      _stopWatchdog();
      if (_isCancelled) return ScriptResult.error(errorMessage: 'GeraÃ§Ã£o cancelada');
      return ScriptResult.error(errorMessage: 'Erro: $e');
    }
  }

  void cancelGeneration() { 
    if (kDebugMode) debugPrint('[$_instanceId] Cancelando geraÃ§Ã£o...');
    _isCancelled = true; 
    _stopWatchdog();
    
    // CORREÃ‡ÃƒO: NÃ£o fechar o Dio aqui, pois pode ser reutilizado
    // Apenas marcar como cancelado e limpar estado se necessÃ¡rio
    if (kDebugMode) debugPrint('[$_instanceId] GeraÃ§Ã£o cancelada pelo usuÃ¡rio');
  }
  
  // MÃ©todo para limpar recursos quando o service nÃ£o for mais usado
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
    _consecutiveBlocks = 0;  // 🔧 NOVO: Resetar contador de bloqueios de conteúdo
    _stopWatchdog();
    
    // 🔧 NOVO: Resetar variáveis static também (rate limiting global)
    _resetGlobalRateLimit();
    
    if (kDebugMode) debugPrint('[$_instanceId] ✅ Estado completamente resetado (incluindo rate limit global)');
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
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent',
        queryParameters: {'key': 'demo_key'},
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
            'maxOutputTokens': 1000,
          }
        }
      );
      
      return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    } catch (e) {
      if (kDebugMode) debugPrint('Erro na geraÃ§Ã£o de texto: $e');
      return '';
    }
  }

  void cancel() {
    cancelGeneration();
  }

  // ===================== Infra =====================
  static String _genId() => 'gemini_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
  void _resetCircuit() { _isCircuitOpen = false; _failureCount = 0; _lastFailureTime = null; }
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
    if (_lastFailureTime != null && DateTime.now().difference(_lastFailureTime!) > _circuitResetTime) { 
      _resetCircuit(); 
      return true; 
    } 
    return false; 
  }
  
  void _startWatchdog() { 
    _stopWatchdog(); 
    _isOperationRunning = true; 
    if (kDebugMode) debugPrint('[$_instanceId] Iniciando watchdog (${_maxOperationTime.inMinutes} min)');
    
    _watchdogTimer = Timer(_maxOperationTime, () { 
      if (_isOperationRunning && !_isCancelled) { 
        if (kDebugMode) debugPrint('[$_instanceId] Watchdog timeout - cancelando operaÃ§Ã£o apÃ³s ${_maxOperationTime.inMinutes} min');
        _isCancelled = true; 
      } 
    }); 
  }
  
  void _stopWatchdog() { 
    if (_watchdogTimer != null) {
      _watchdogTimer!.cancel(); 
      if (kDebugMode && _isOperationRunning) debugPrint('[$_instanceId] Parando watchdog');
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
      if (kDebugMode) debugPrint('[$_instanceId] Rate limit timeout, proceeding anyway');
      return; // Evita deadlock total
    }
    
    _rateLimitBusy = true;
    
    try {
      final now = DateTime.now();
      final diff = now.difference(_globalLastRequestTime);
      
  if (kDebugMode) debugPrint('[$_instanceId] Rate limit check: $_globalRequestCount/$_maxRequestsPerWindow requests in window');
      
      // Reset contador se passou da janela de rate limit
      if (diff > _rateLimitWindow) {
        _globalRequestCount = 0;
        if (kDebugMode) debugPrint('[$_instanceId] Rate limit window reset');
      }
      
      // Se atingiu limite, aguarda atÃ© o fim da janela
      if (_globalRequestCount >= _maxRequestsPerWindow) {
        final wait = _rateLimitWindow - diff;
        if (wait > Duration.zero && wait < Duration(seconds: 30)) { // MÃ¡ximo 30s de espera
          if (kDebugMode) debugPrint('[$_instanceId] Rate limit hit, waiting ${wait.inSeconds}s');
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
            if (kDebugMode) debugPrint('[$_instanceId] Could not reacquire rate limit lock, proceeding');
            return;
          }
        }
      }
      
      _globalRequestCount++;
      _globalLastRequestTime = now;
      
  if (kDebugMode) debugPrint('[$_instanceId] Request $_globalRequestCount/$_maxRequestsPerWindow approved for instance');
      
    } finally {
      _rateLimitBusy = false;
    }
  }

  Future<T> _retryOnRateLimit<T>(Future<T> Function() op, {int maxRetries = 4}) async { // AUMENTADO: Era 2, agora 4 para erro 503
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
        
        // CORREÃ‡ÃƒO: Tratar erro 503 (servidor indisponÃ­vel) especificamente
        if (errorStr.contains('503') || errorStr.contains('server error') || errorStr.contains('service unavailable')) {
          if (attempt < maxRetries - 1) {
            final delay = Duration(seconds: (attempt + 1) * 8); // Delay maior para 503
            if (kDebugMode) debugPrint('[$_instanceId] Servidor indisponÃ­vel (503) - tentando novamente em ${delay.inSeconds}s (attempt ${attempt + 1}/$maxRetries)');
            await Future.delayed(delay);
            continue;
          } else {
            throw Exception('Servidor do Gemini temporariamente indisponÃ­vel. Verifique sua conexÃ£o e tente novamente em alguns minutos.');
          }
        }
        
        // CORREÃ‡ÃƒO: Falha rÃ¡pida para evitar travamentos
        if ((errorStr.contains('429') || errorStr.contains('timeout') || errorStr.contains('connection')) && attempt < maxRetries - 1) {
          final delay = Duration(seconds: (attempt + 1) * 2); // REDUZIDO: Era 3, agora 2 segundos
          if (kDebugMode) debugPrint('[$_instanceId] Retry rÃ¡pido (attempt ${attempt + 1}/$maxRetries): $e');
          await Future.delayed(delay);
          continue;
        }
        
        if (kDebugMode) debugPrint('[$_instanceId] Erro final apÃ³s $maxRetries tentativas: $e');
        rethrow;
      }
    }
    throw Exception('Limite de tentativas excedido apÃ³s $maxRetries tentativas');
  }

  // ===================== Narrativa =====================
  final List<String> _phases = const ['Preparação','Introdução','Desenvolvimento','Clímax','Resolução','Finalização'];
  
  int _getPhaseIndexFromProgress(double p) { 
    if(p<=0.15) return 0; 
    if(p<=0.30) return 1; 
    if(p<=0.65) return 2; 
    if(p<=0.80) return 3; 
    if(p<=0.95) return 4; 
    return 5; 
  }
  
  List<String> _generateBlockLogs(String phase, int block, int total, ScriptConfig c) { 
    return ['Fase: $phase','Bloco $block/$total','Meta: ${c.quantity} ${c.measureType}']; 
  }
  
  int _getBlockDelay(int block, int total) { 
    final p = block / total; 
    // OTIMIZADO: Delays mínimos para maximizar velocidade (sem afetar qualidade)
    if(p <= 0.15) return 50;   // Reduzido de 100ms para 50ms
    if(p <= 0.30) return 75;   // Reduzido de 150ms para 75ms
    if(p <= 0.65) return 100;  // Reduzido de 200ms para 100ms
    if(p <= 0.80) return 125;  // Reduzido de 250ms para 125ms
    if(p <= 0.95) return 75;   // Reduzido de 150ms para 75ms
    return 50; // Reduzido de 100ms para 50ms
  }
  
  bool _checkTargetMet(String text, ScriptConfig c) { 
    if(c.measureType == 'caracteres') { 
      // TOLERÃ‚NCIA ZERO: SÃ³ aceita se atingir pelo menos 99.5% da meta
      final tol = max(50, (c.quantity * 0.005).round()); // MÃ¡ximo 0.5% ou 50 chars, o que for maior
      return text.length >= (c.quantity - tol);
    } 
    final wc = _countWords(text); 
    // TOLERÃ‚NCIA ZERO: SÃ³ aceita se atingir pelo menos 99% da meta
    final tol = max(10, (c.quantity * 0.01).round()); // MÃ¡ximo 1% ou 10 palavras, o que for maior
    return wc >= (c.quantity - tol);
  }
  
  int _calculateTotalBlocks(ScriptConfig c) { 
    // 🎯 NORMALIZAÇÃO: Converter tudo para palavras equivalentes (5.5 chars = 1 palavra)
    // Isso garante que quantidades equivalentes de conteúdo recebam blocos similares
    int wordsEquivalent = c.measureType == 'caracteres' 
        ? (c.quantity / 5.5).round()  // Conversão: chars → palavras
        : c.quantity;
    
    // 🌍 AJUSTE AUTOMÁTICO PARA IDIOMAS COM ALFABETOS PESADOS
    // IMPORTANTE: Este ajuste só deve ser aplicado para medida em CARACTERES!
    // Para medida em PALAVRAS, não aplicar redução (o multiplicador 1.20 já compensa)
    // Diferentes alfabetos ocupam diferentes quantidades de bytes em UTF-8
    // Ajustamos palavras equivalentes para evitar timeout de contexto em roteiros longos
    
    // 🔴 NÍVEL 2: Cirílico e Alfabetos Pesados - 2-3 bytes/char → Redução de 12%
    final cyrillicLanguages = [
      'Russo', 'Búlgaro', 'Sérvio'  // Cirílico
    ];
    
    // 🔴 NÍVEL 2B: Outros Não-Latinos - 2-3 bytes/char → Redução de 15%
    final otherNonLatinLanguages = [
      'Hebraico', 'Grego', 'Tailandês'  // Semíticos e outros
    ];
    
    // 🟡 NÍVEL 1: Latinos com Diacríticos Pesados - 1.2-1.5 bytes/char → Redução de 8%
    final heavyDiacriticLanguages = [
      'Turco', 'Polonês', 'Tcheco', 'Vietnamita', 'Húngaro'
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
          debugPrint('   $originalWords → $wordsEquivalent palavras equiv. (${(adjustmentFactor * 100).toInt()}%)');
        }
      }
    }
    
    // 📊 CÁLCULO OTIMIZADO: Blocos maiores = mais rápido, mas deve completar meta
    // Sistema TESTADO e VALIDADO - NÃO aumentar blocos sem testes extensivos!
    
    if(wordsEquivalent <= 1000) return 3;    // ~333 palavras/bloco
    if(wordsEquivalent <= 3000) return 4;    // ~750 palavras/bloco  
    if(wordsEquivalent <= 6000) return 5;    // ~1200 palavras/bloco
    if(wordsEquivalent <= 10000) return 8;   // ~1250 palavras/bloco (9k usa 8 blocos - TESTADO!)
    if(wordsEquivalent <= 15000) return 10;  // ~1500 palavras/bloco
    if(wordsEquivalent <= 20000) return 12;  // ~1666 palavras/bloco
    if(wordsEquivalent <= 25000) return 14;  // ~1785 palavras/bloco
    return 16; // Máximo 16 blocos para textos enormes
  }

  int _calculateTargetForBlock(int current, int total, ScriptConfig c) {
  // AJUSTE CRÍTICO: Multiplicador de 1.20 para compensar variação natural do Gemini
  // Análise dos logs mostra que Gemini gera 85-90% do pedido em média
  // Pedindo 20% a mais, atingimos ~100% da meta real (1.15 gerou apenas 78%)
  
  // 🔧 CORREÇÃO: Usar a mesma lógica de normalização que _calculateTotalBlocks
  int targetQuantity = c.measureType == 'caracteres' 
      ? (c.quantity / 5.5).round()  // Conversão: chars → palavras
      : c.quantity;
  
  // 🌍 Aplicar os mesmos ajustes de idioma que em _calculateTotalBlocks
  // IMPORTANTE: Só aplicar para 'caracteres', nunca para 'palavras'
  if (c.measureType == 'caracteres' && targetQuantity > 6000) {
    final cyrillicLanguages = ['Russo', 'Búlgaro', 'Sérvio'];
    final otherNonLatinLanguages = ['Hebraico', 'Grego', 'Tailandês'];
    final heavyDiacriticLanguages = ['Turco', 'Polonês', 'Tcheco', 'Vietnamita', 'Húngaro'];
    
    if (cyrillicLanguages.contains(c.language)) {
      targetQuantity = (targetQuantity * 0.88).round();
    } else if (otherNonLatinLanguages.contains(c.language)) {
      targetQuantity = (targetQuantity * 0.85).round();
    } else if (heavyDiacriticLanguages.contains(c.language)) {
      targetQuantity = (targetQuantity * 0.92).round();
    }
  }
  
  // Calcular target acumulado até este bloco (com margem de 20%)
  final cumulativeTarget = (targetQuantity * (current / total) * 1.20).round();
  
  // Calcular target acumulado do bloco anterior
  final previousCumulativeTarget = current > 1 
      ? (targetQuantity * ((current - 1) / total) * 1.20).round() 
      : 0;
  
  // DELTA = palavras necessárias NESTE bloco específico
  final baseTarget = cumulativeTarget - previousCumulativeTarget;
  
  // LIMITES por bloco individual (aumentado para evitar cortes)
  final maxBlockSize = c.measureType == 'caracteres' ? 15000 : 5000;
  
  // Para o último bloco, usar o mesmo multiplicador
  // AJUSTE: Pedimos 20% a mais por bloco para compensar variação natural do Gemini
  // (Gemini tende a gerar 85-90% do pedido, especialmente em blocos finais)
  if (current == total) {
    final wordsPerBlock = (targetQuantity / total).ceil();
    return min((wordsPerBlock * 1.20).round(), maxBlockSize); // Multiplicador 1.20 (era 1.15)
  }
  
  return baseTarget > maxBlockSize ? maxBlockSize : baseTarget;
}

// ===================== Geração de Blocos =====================

  String _getLanguageInstruction(String l) {
    final normalized = l.toLowerCase().trim();
    
    if (kDebugMode) {
      debugPrint('🌍 _getLanguageInstruction: input="$l" → normalized="$normalized"');
      debugPrint('🌍 Code units: ${normalized.codeUnits}');
    }
    
    // Normalizar variações de escrita
    if (normalized.contains('portugu') || normalized == 'pt') {
      return 'Português brasileiro natural e simples - use palavras que qualquer pessoa entende no dia a dia, evite vocabulário rebuscado ou erudito';
    }
    
    if (normalized.contains('ingl') || normalized == 'en' || normalized == 'english') {
      return 'Simple, natural English - use everyday words that anyone can understand, avoid complex vocabulary';
    }
    
    if (normalized.contains('espanhol') || normalized.contains('spanish') || normalized.contains('español') || normalized == 'es' || normalized == 'es-mx') {
      return 'Español mexicano natural y sencillo - usa palabras cotidianas que cualquiera entiende, evita vocabulario rebuscado';
    }
    
    if (normalized.contains('franc') || normalized.contains('french') || normalized == 'fr') {
      return 'Français naturel et simple - utilisez des mots quotidiens que tout le monde comprend, évitez le vocabulaire complexe';
    }
    
    if (normalized.contains('alem') || normalized.contains('german') || normalized == 'de') {
      return 'Natürliches, einfaches Deutsch - verwenden Sie alltägliche Wörter, die jeder versteht, vermeiden Sie komplexes Vokabular';
    }
    
    if (normalized.contains('italia') || normalized.contains('italian') || normalized == 'it') {
      return 'Italiano naturale e semplice - usa parole quotidiane che tutti capiscono, evita vocabolario complesso';
    }
    
    if (normalized.contains('polon') || normalized.contains('polish') || normalized == 'pl') {
      return 'Naturalny, prosty polski - używaj codziennych słów, które każdy rozumie, unikaj skomplikowanego słownictwa';
    }
    
    if (normalized.contains('búlgar') || normalized.contains('bulgar') || normalized == 'bg') {
      return 'Естествен, прост български - използвайте ежедневни думи, които всеки разбира, избягвайте сложна лексика';
    }
    
    if (normalized.contains('croat') || normalized.contains('hrvat') || normalized == 'hr') {
      return 'Prirodni, jednostavan hrvatski - koristite svakodnevne riječi koje svatko razumije, izbjegavajte složen vokabular';
    }
    
    if (normalized.contains('turco') || normalized.contains('turk') || normalized == 'tr') {
      return 'Doğal, basit Türkçe - herkesin anlayabileceği günlük kelimeler kullanın, karmaşık kelime dağarcığından kaçının';
    }
    
    if (normalized.contains('romen') || normalized.contains('roman') || normalized == 'ro') {
      return 'Română naturală și simplă - folosiți cuvinte de zi cu zi pe care oricine le înțelege, evitați vocabularul complicat';
    }
    
    if (normalized.contains('russo') || normalized.contains('russian') || normalized == 'ru') {
      return 'Естественный, простой русский - используйте повседневные слова, которые все понимают, избегайте сложной лексики';
    }
    
    // Default para português
    if (kDebugMode) {
      debugPrint('⚠️ Idioma não reconhecido: "$l" → usando português como fallback');
    }
    return 'Português brasileiro natural e simples - use palavras que qualquer pessoa entende no dia a dia';
  }

  /// 🌍 Retorna instrução de início internacionalizada
  String _getStartInstruction(String language, {required bool withTitle, String? title}) {
    final normalized = language.toLowerCase().trim();
    
    // 🇺🇸 INGLÊS
    if (normalized.contains('ingl') || normalized == 'en' || normalized == 'english') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Begin a new story using EXACTLY this phrase as the opening hook: "$title". This phrase should start the first paragraph naturally and engagingly, as if it were part of the narrative';
      }
      return 'Begin a new story';
    }
    
    // 🇲🇽 ESPANHOL
    if (normalized.contains('espanhol') || normalized.contains('spanish') || normalized.contains('español') || normalized == 'es' || normalized == 'es-mx') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Comienza una nueva historia usando EXACTAMENTE esta frase como gancho de apertura: "$title". Esta frase debe iniciar el primer párrafo de forma natural y envolvente, como si fuera parte de la narrativa';
      }
      return 'Comienza una nueva historia';
    }
    
    // 🇫🇷 FRANCÊS
    if (normalized.contains('franc') || normalized.contains('french') || normalized == 'fr') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Commencez une nouvelle histoire en utilisant EXACTEMENT cette phrase comme accroche d\'ouverture: "$title". Cette phrase doit commencer le premier paragraphe de manière naturelle et engageante, comme si elle faisait partie du récit';
      }
      return 'Commencez une nouvelle histoire';
    }
    
    // 🇩🇪 ALEMÃO
    if (normalized.contains('alem') || normalized.contains('german') || normalized == 'de') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Beginnen Sie eine neue Geschichte und verwenden Sie GENAU diesen Satz als Eröffnungshaken: "$title". Dieser Satz sollte den ersten Absatz auf natürliche und ansprechende Weise beginnen, als wäre er Teil der Erzählung';
      }
      return 'Beginnen Sie eine neue Geschichte';
    }
    
    // 🇮🇹 ITALIANO
    if (normalized.contains('italia') || normalized.contains('italian') || normalized == 'it') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Inizia una nuova storia usando ESATTAMENTE questa frase come gancio di apertura: "$title". Questa frase dovrebbe iniziare il primo paragrafo in modo naturale e coinvolgente, come se facesse parte della narrativa';
      }
      return 'Inizia una nuova storia';
    }
    
    // 🇵🇱 POLONÊS
    if (normalized.contains('polon') || normalized.contains('polish') || normalized == 'pl') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Rozpocznij nową historię używając DOKŁADNIE tego zdania jako haczyka otwierającego: "$title". To zdanie powinno rozpoczynać pierwszy akapit w naturalny i angażujący sposób, jakby było częścią narracji';
      }
      return 'Rozpocznij nową historię';
    }
    
    // 🇧🇬 BÚLGARO
    if (normalized.contains('búlgar') || normalized.contains('bulgar') || normalized == 'bg') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Започнете нова история, използвайки ТОЧНО тази фраза като начална кука: "$title". Тази фраза трябва да започне първия параграф естествено и ангажиращо, сякаш е част от разказа';
      }
      return 'Започнете нова история';
    }
    
    // 🇭🇷 CROATA
    if (normalized.contains('croat') || normalized.contains('hrvat') || normalized == 'hr') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Započnite novu priču koristeći TOČNO ovu frazu kao početnu kuku: "$title". Ova fraza bi trebala započeti prvi paragraf prirodno i privlačno, kao da je dio pripovijesti';
      }
      return 'Započnite novu priču';
    }
    
    // 🇹🇷 TURCO
    if (normalized.contains('turco') || normalized.contains('turk') || normalized == 'tr') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'TAM OLARAK bu cümleyi açılış kancası olarak kullanarak yeni bir hikaye başlatın: "$title". Bu cümle, anlatının bir parçasıymış gibi doğal ve ilgi çekici bir şekilde ilk paragrafı başlatmalıdır';
      }
      return 'Yeni bir hikaye başlatın';
    }
    
    // 🇷🇴 ROMENO
    if (normalized.contains('romen') || normalized.contains('roman') || normalized == 'ro') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Începeți o nouă poveste folosind EXACT această frază ca cârlig de deschidere: "$title". Această frază ar trebui să înceapă primul paragraf în mod natural și captivant, ca și cum ar face parte din narațiune';
      }
      return 'Începeți o nouă poveste';
    }
    
    // 🇷🇺 RUSSO
    if (normalized.contains('russo') || normalized.contains('russian') || normalized == 'ru') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Начните новую историю, используя ТОЧНО эту фразу в качестве вступительного крючка: "$title". Эта фраза должна начинать первый абзац естественно и увлекательно, как будто она является частью повествования';
      }
      return 'Начните новую историю';
    }
    
    // 🇧🇷 PORTUGUÊS (default)
    if (withTitle && title != null && title.trim().isNotEmpty) {
      return 'Comece uma nova história usando EXATAMENTE esta frase como gancho de abertura: "$title". Esta frase deve iniciar o primeiro parágrafo de forma natural e envolvente, como se fosse parte da narrativa';
    }
    return 'Comece uma nova história';
  }

  /// 🌍 Retorna instrução de continuação internacionalizada
  String _getContinueInstruction(String language) {
    final normalized = language.toLowerCase().trim();
    
    if (normalized.contains('ingl') || normalized == 'en' || normalized == 'english') return 'Continue the story';
    if (normalized.contains('espanhol') || normalized.contains('spanish') || normalized.contains('español') || normalized == 'es' || normalized == 'es-mx') return 'Continúa la historia';
    if (normalized.contains('franc') || normalized.contains('french') || normalized == 'fr') return 'Continuez l\'histoire';
    if (normalized.contains('alem') || normalized.contains('german') || normalized == 'de') return 'Setzen Sie die Geschichte fort';
    if (normalized.contains('italia') || normalized.contains('italian') || normalized == 'it') return 'Continua la storia';
    if (normalized.contains('polon') || normalized.contains('polish') || normalized == 'pl') return 'Kontynuuj historię';
    if (normalized.contains('búlgar') || normalized.contains('bulgar') || normalized == 'bg') return 'Продължете историята';
    if (normalized.contains('croat') || normalized.contains('hrvat') || normalized == 'hr') return 'Nastavite priču';
    if (normalized.contains('turco') || normalized.contains('turk') || normalized == 'tr') return 'Hikayeye devam edin';
    if (normalized.contains('romen') || normalized.contains('roman') || normalized == 'ro') return 'Continuați povestea';
    if (normalized.contains('russo') || normalized.contains('russian') || normalized == 'ru') return 'Продолжите историю';
    
    return 'Continue a história'; // Português (default)
  }

  /// 🌍 Traduz labels de metadados (TEMA, SUBTEMA, etc) para o idioma selecionado
  Map<String, String> _getMetadataLabels(String language) {
    final normalized = language.toLowerCase().trim();
    
    // 🇺🇸 INGLÊS
    if (normalized.contains('ingl') || normalized == 'en' || normalized == 'english') {
      return {
        'theme': 'THEME',
        'subtheme': 'SUBTHEME',
        'location': 'LOCATION',
        'locationNotSpecified': 'Not specified',
        'additionalContext': 'ADDITIONAL CONTEXT',
      };
    }
    
    // 🇲🇽 ESPANHOL
    if (normalized.contains('espanhol') || normalized.contains('spanish') || normalized.contains('español') || normalized == 'es' || normalized == 'es-mx') {
      return {
        'theme': 'TEMA',
        'subtheme': 'SUBTEMA',
        'location': 'UBICACIÓN',
        'locationNotSpecified': 'No especificada',
        'additionalContext': 'CONTEXTO ADICIONAL',
      };
    }
    
    // 🇫🇷 FRANCÊS
    if (normalized.contains('franc') || normalized.contains('french') || normalized == 'fr') {
      return {
        'theme': 'THÈME',
        'subtheme': 'SOUS-THÈME',
        'location': 'LIEU',
        'locationNotSpecified': 'Non spécifié',
        'additionalContext': 'CONTEXTE SUPPLÉMENTAIRE',
      };
    }
    
    // 🇩🇪 ALEMÃO
    if (normalized.contains('alem') || normalized.contains('german') || normalized == 'de') {
      return {
        'theme': 'THEMA',
        'subtheme': 'UNTERTHEMA',
        'location': 'ORT',
        'locationNotSpecified': 'Nicht angegeben',
        'additionalContext': 'ZUSÄTZLICHER KONTEXT',
      };
    }
    
    // 🇮🇹 ITALIANO
    if (normalized.contains('italia') || normalized.contains('italian') || normalized == 'it') {
      return {
        'theme': 'TEMA',
        'subtheme': 'SOTTOTEMA',
        'location': 'POSIZIONE',
        'locationNotSpecified': 'Non specificato',
        'additionalContext': 'CONTESTO AGGIUNTIVO',
      };
    }
    
    // 🇵🇱 POLONÊS
    if (normalized.contains('polon') || normalized.contains('polish') || normalized == 'pl') {
      return {
        'theme': 'TEMAT',
        'subtheme': 'PODTEMAT',
        'location': 'LOKALIZACJA',
        'locationNotSpecified': 'Nie określono',
        'additionalContext': 'DODATKOWY KONTEKST',
      };
    }
    
    // 🇧🇬 BÚLGARO
    if (normalized.contains('búlgar') || normalized.contains('bulgar') || normalized == 'bg') {
      return {
        'theme': 'ТЕМА',
        'subtheme': 'ПОДТЕМА',
        'location': 'МЕСТОПОЛОЖЕНИЕ',
        'locationNotSpecified': 'Не е посочено',
        'additionalContext': 'ДОПЪЛНИТЕЛЕН КОНТЕКСТ',
      };
    }
    
    // 🇭🇷 CROATA
    if (normalized.contains('croat') || normalized.contains('hrvat') || normalized == 'hr') {
      return {
        'theme': 'TEMA',
        'subtheme': 'PODTEMA',
        'location': 'LOKACIJA',
        'locationNotSpecified': 'Nije navedeno',
        'additionalContext': 'DODATNI KONTEKST',
      };
    }
    
    // 🇹🇷 TURCO
    if (normalized.contains('turco') || normalized.contains('turk') || normalized == 'tr') {
      return {
        'theme': 'TEMA',
        'subtheme': 'ALT TEMA',
        'location': 'KONUM',
        'locationNotSpecified': 'Belirtilmemiş',
        'additionalContext': 'EK BAĞLAM',
      };
    }
    
    // 🇷🇴 ROMENO
    if (normalized.contains('romen') || normalized.contains('roman') || normalized == 'ro') {
      return {
        'theme': 'TEMĂ',
        'subtheme': 'SUBTEMĂ',
        'location': 'LOCAȚIE',
        'locationNotSpecified': 'Nespecificat',
        'additionalContext': 'CONTEXT SUPLIMENTAR',
      };
    }
    
    // 🇷🇺 RUSSO
    if (normalized.contains('russo') || normalized.contains('russian') || normalized == 'ru') {
      return {
        'theme': 'ТЕМА',
        'subtheme': 'ПОДТЕМА',
        'location': 'МЕСТОПОЛОЖЕНИЕ',
        'locationNotSpecified': 'Не указано',
        'additionalContext': 'ДОПОЛНИТЕЛЬНЫЙ КОНТЕКСТ',
      };
    }
    
    // 🇧🇷 PORTUGUÊS (default)
    return {
      'theme': 'TEMA',
      'subtheme': 'SUBTEMA',
      'location': 'LOCALIZAÇÃO',
      'locationNotSpecified': 'Não especificada',
      'additionalContext': 'CONTEXTO ADICIONAL',
    };
  }

  /// Retorna instrução para traduzir contexto se idioma não for português
  String _getContextTranslationInstruction(String language) {
    final normalized = language.toLowerCase().trim();
    
    // Se é português, não precisa traduzir
    if (normalized.contains('portugu') || normalized == 'pt' || normalized == 'portuguese') {
      return '';
    }
    
    // Para outros idiomas, instrui o Gemini a traduzir automaticamente
    // 🇺🇸 INGLÊS
    if (normalized.contains('ingl') || normalized == 'en' || normalized == 'english') {
      return '⚠️ TRANSLATION NOTE: The context below is written in Portuguese. Automatically translate it to English and use the translated version in your narrative.\n';
    }
    
    // 🇲🇽 ESPANHOL
    if (normalized.contains('espanhol') || normalized.contains('spanish') || normalized.contains('español') || normalized == 'es' || normalized == 'es-mx') {
      return '⚠️ NOTA DE TRADUCCIÓN: El contexto a continuación está escrito en portugués. Tradúcelo automáticamente al español y usa la versión traducida en tu narrativa.\n';
    }
    
    // 🇫🇷 FRANCÊS
    if (normalized.contains('franc') || normalized.contains('french') || normalized == 'fr') {
      return '⚠️ NOTE DE TRADUCTION: Le contexte ci-dessous est écrit en portugais. Traduisez-le automatiquement en français et utilisez la version traduite dans votre récit.\n';
    }
    
    // 🇩🇪 ALEMÃO
    if (normalized.contains('alem') || normalized.contains('german') || normalized == 'de') {
      return '⚠️ ÜBERSETZUNGSHINWEIS: Der untenstehende Kontext ist auf Portugiesisch geschrieben. Übersetzen Sie ihn automatisch ins Deutsche und verwenden Sie die übersetzte Version in Ihrer Erzählung.\n';
    }
    
    // 🇮🇹 ITALIANO
    if (normalized.contains('italia') || normalized.contains('italian') || normalized == 'it') {
      return '⚠️ NOTA DI TRADUZIONE: Il contesto qui sotto è scritto in portoghese. Traducilo automaticamente in italiano e usa la versione tradotta nella tua narrativa.\n';
    }
    
    // 🇵🇱 POLONÊS
    if (normalized.contains('polon') || normalized.contains('polish') || normalized == 'pl') {
      return '⚠️ UWAGA DOTYCZĄCA TŁUMACZENIA: Poniższy kontekst jest napisany w języku portugalskim. Automatycznie przetłumacz go na polski i użyj przetłumaczonej wersji w swojej narracji.\n';
    }
    
    // 🇧🇬 BÚLGARO
    if (normalized.contains('búlgar') || normalized.contains('bulgar') || normalized == 'bg') {
      return '⚠️ БЕЛЕЖКА ЗА ПРЕВОД: Контекстът по-долу е написан на португалски. Преведете го автоматично на български и използвайте преведената версия в своето повествование.\n';
    }
    
    // 🇭🇷 CROATA
    if (normalized.contains('croat') || normalized.contains('hrvat') || normalized == 'hr') {
      return '⚠️ NAPOMENA O PRIJEVODU: Kontekst u nastavku napisan je na portugalskom. Automatski ga prevedite na hrvatski i koristite prevedenu verziju u svojoj priči.\n';
    }
    
    // 🇹🇷 TURCO
    if (normalized.contains('turco') || normalized.contains('turk') || normalized == 'tr') {
      return '⚠️ ÇEVİRİ NOTU: Aşağıdaki bağlam Portekizce yazılmıştır. Otomatik olarak Türkçe\'ye çevirin ve çevrilmiş versiyonu anlatınızda kullanın.\n';
    }
    
    // 🇷🇴 ROMENO
    if (normalized.contains('romen') || normalized.contains('roman') || normalized == 'ro') {
      return '⚠️ NOTĂ DE TRADUCERE: Contextul de mai jos este scris în portugheză. Traduceți-l automat în română și folosiți versiunea tradusă în narațiunea dvs.\n';
    }
    
    // 🇷🇺 RUSSO
    if (normalized.contains('russo') || normalized.contains('russian') || normalized == 'ru') {
      return '⚠️ ПРИМЕЧАНИЕ О ПЕРЕВОДЕ: Контекст ниже написан на португальском языке. Автоматически переведите его на русский и используйте переведённую версию в своём повествовании.\n';
    }
    
    // Fallback (inglês)
    return '⚠️ TRANSLATION NOTE: The context below is in Portuguese. Automatically translate it to the target language and use the translated version.\n';
  }

  String _buildLocalizationGuidance(ScriptConfig config) {
    final levelInstruction = config.localizationLevel.geminiInstruction.trim();
    final location = config.localizacao.trim();

    String additionalGuidance;
    switch (config.localizationLevel) {
      case LocalizationLevel.global:
        additionalGuidance = location.isEmpty
            ? 'NÃO mencione países, cidades, moedas, instituições ou gírias específicas. O cenário deve soar universal e funcionar em QUALQUER lugar do mundo.'
            : 'Use "$location" apenas como inspiração ampla. Transforme qualquer detalhe específico em descrições neutras e universais, sem citar nomes de cidades, moedas, instituições ou gírias locais.';
        break;
      case LocalizationLevel.national:
        additionalGuidance = location.isEmpty
            ? 'Você pode mencionar o país e elementos culturais reconhecíveis nacionalmente, evitando estados, cidades ou gírias muito específicas.'
            : 'Trate "$location" como referência nacional ampla. Cite costumes e elementos que qualquer pessoa do país reconheça, evitando bairros ou gírias extremamente locais.';
        break;
      case LocalizationLevel.regional:
        additionalGuidance = location.isEmpty
            ? 'Escolha uma região coerente com o tema e traga gírias, hábitos, pontos de referência e clima típico da região.'
            : 'Inclua gírias, hábitos, pontos de referência e sensações autênticas de "$location" para reforçar o sabor regional.';
        break;
    }

    final locationLabel = location.isEmpty ? 'Não especificada' : location;
    return '''INSTRUÇÕES DE REGIONALISMO:
${levelInstruction.isEmpty ? '' : '$levelInstruction\n'}$additionalGuidance
LOCALIZAÇÃO INFORMADA: $locationLabel
''';
  }

  void _bootstrapCharacterTracker(_CharacterTracker tracker, ScriptConfig config) {
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
    
    final contextNames = _extractCharacterNamesFromContext(config.context);
    names.addAll(contextNames);
    fromContext.addAll(contextNames);
    
    // 🎯 NOVO: Extrair gênero e relações de personagens do título
    final titleNames = _extractCharacterHintsFromTitle(config.title, config.context);
    names.addAll(titleNames);
    fromTitle.addAll(titleNames);

    for (final name in names) {
      tracker.addName(name);
    }

    // 📊 LOG DETALHADO: Mostrar origem de cada nome carregado
    if (kDebugMode && tracker.confirmedNames.isNotEmpty) {
      debugPrint('🔐 TRACKER BOOTSTRAP - ${tracker.confirmedNames.length} nome(s) carregado(s):');
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
      debugPrint('⚠️ TRACKER BOOTSTRAP: Nenhum nome inicial fornecido (será detectado no bloco 1)');
    }
  }

  void _updateTrackerFromContextSnippet(
    _CharacterTracker tracker,
    ScriptConfig config,
    String snippet,
  ) {
    if (snippet.trim().isEmpty) return;

    final existingLower = tracker.confirmedNames.map((n) => n.toLowerCase()).toSet();
    final locationLower = config.localizacao.trim().toLowerCase();
    final candidateCounts = _extractNamesFromSnippet(snippet);

    candidateCounts.forEach((name, count) {
      final normalized = name.toLowerCase();
      if (existingLower.contains(normalized)) return;
      if (count < 2) return; // exige recorrência para evitar falsos positivos
      if (locationLower.isNotEmpty && normalized == locationLower) return;
      if (_nameStopwords.contains(normalized)) return;

      // 🔥 VALIDAÇÃO RIGOROSA: Só adicionar se estiver no banco curado
      if (!NameGeneratorService.isValidName(name)) {
        if (kDebugMode) {
          debugPrint('⚠️ Tracker REJEITOU nome não validado: "$name" (não está no banco curado)');
        }
        return;
      }

      tracker.addName(name);
      if (kDebugMode) {
        debugPrint('🔍 Tracker adicionou personagem detectado: $name (ocorrências: $count)');
      }
    });
  }

  /// 🌍 Traduz termos de parentesco do português para o idioma do roteiro
  String _translateFamilyTerms(String text, String language) {
    final lang = language.toLowerCase().trim();
    
    // Se for português, retornar original
    if (lang.contains('portugu') || lang == 'pt') {
      return text;
    }
    
    // Obter mapa de traduções para o idioma
    final translations = _familyTermsTranslations[lang];
    if (translations == null) {
      // Idioma não mapeado, retornar original
      if (kDebugMode) {
        debugPrint('⚠️ Traduções de termos familiares não encontradas para: $lang');
      }
      return text;
    }
    
    // Substituir todos os termos encontrados
    var result = text;
    for (final entry in translations.entries) {
      // Substituir tanto com inicial maiúscula quanto minúscula
      result = result.replaceAll(entry.key, entry.value);
    }
    
    if (kDebugMode && result != text) {
      debugPrint('🌍 Termos familiares traduzidos para $lang');
    }
    
    return result;
  }

  String _buildCharacterGuidance(ScriptConfig config, _CharacterTracker tracker) {
    final lines = <String>[];
    final baseNames = <String>{};

    final protagonist = config.protagonistName.trim();
    if (protagonist.isNotEmpty) {
      final translatedProtagonist = _translateFamilyTerms(protagonist, config.language);
      lines.add('- Protagonista: "$translatedProtagonist" — mantenha exatamente este nome e sua função.');
      baseNames.add(protagonist.toLowerCase());
    }

    final secondary = config.secondaryCharacterName.trim();
    if (secondary.isNotEmpty) {
      final translatedSecondary = _translateFamilyTerms(secondary, config.language);
      lines.add('- Personagem secundário: "$translatedSecondary" — preserve o mesmo nome em todos os blocos.');
      baseNames.add(secondary.toLowerCase());
    }

    final additional = tracker.confirmedNames
        .where((n) => !baseNames.contains(n.toLowerCase()))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    for (final name in additional) {
      // 🎯 CORRIGIDO: Adicionar personagens mencionados (não são hints de narrador)
      if (name.startsWith('PERSONAGEM MENCIONADO')) {
        // Remover marcador e traduzir termo familiar antes de adicionar ao prompt
        final cleanName = name.replaceFirst('PERSONAGEM MENCIONADO: ', '');
        final translatedName = _translateFamilyTerms(cleanName, config.language);
        lines.add('- Personagem mencionado: $translatedName (manter como referência familiar)');
      } else {
        final translatedName = _translateFamilyTerms(name, config.language);
        lines.add('- Personagem estabelecido: "$translatedName" — não altere este nome nem invente apelidos.');
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
    
    // 🎯 APENAS detectar relações/personagens mencionados no título
    // NÃO inferir quem é o narrador (isso vem da configuração do usuário)
    
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
          debugPrint('🎯 Personagem detectado no título: ${entry.key} → ${entry.value}');
        }
      }
    }
    
    return hints;
  }
  
  Set<String> _extractCharacterNamesFromContext(String context) {
    final names = <String>{};
    if (context.trim().isEmpty) return names;

    final patterns = <RegExp>[
      RegExp(r'PROTAGONISTA[^"]*"([^\"]+)"', caseSensitive: false),
      RegExp(r'PERSONAGEM[^"]*"([^\"]+)"', caseSensitive: false),
      RegExp(r'ANTAGONISTA[^"]*"([^\"]+)"', caseSensitive: false),
      RegExp(r'C[ÚU]MPLICE[^"]*"([^\"]+)"', caseSensitive: false),
      RegExp(r'ALIAD[OA][^"]*"([^\"]+)"', caseSensitive: false),
      RegExp(r'MARIDO[^"]*"([^\"]+)"', caseSensitive: false),
      RegExp(r'ESPOSA[^"]*"([^\"]+)"', caseSensitive: false),
      RegExp(r'FILH[AO][^"]*"([^\"]+)"', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(context)) {
        final candidate = match.group(1)?.trim() ?? '';
        if (_looksLikePersonName(candidate)) {
          names.add(candidate);
        }
      }
    }

    final inlinePattern = RegExp(
      r'(protagonista|antagonista|c[úu]mplice|aliad[oa]|amig[oa]|marido|esposa|filh[ao]|rival|mentor|vil[ãa]o)\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][A-Za-zÁ-ú]+(?:\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][A-Za-zÁ-ú]+)*)',
      caseSensitive: false,
    );

    for (final match in inlinePattern.allMatches(context)) {
      final candidate = match.group(2)?.trim() ?? '';
      if (_looksLikePersonName(candidate)) {
        names.add(candidate);
      }
    }

    return names;
  }

  Map<String, int> _extractNamesFromSnippet(String snippet) {
    final counts = <String, int>{};
    final regex = RegExp(r'\b([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+(?:\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)*)\b');

    for (final match in regex.allMatches(snippet)) {
      final candidate = match.group(1)?.trim() ?? '';
      if (!_looksLikePersonName(candidate)) continue;
      final normalized = candidate.replaceAll(RegExp(r'\s+'), ' ');
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }

    return counts;
  }

  String _filterDuplicateParagraphs(String existing, String addition) {
    if (addition.trim().isEmpty) return '';

    final existingSet = existing
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
        debugPrint('   📍 Parágrafo #${firstIndex + 1} repetido no parágrafo #${i + 1}');
        debugPrint('   📝 Prévia: "$preview"');
      } else {
        seen[paragraph] = i;
      }
    }
    
    if (duplicateCount > 0) {
      debugPrint('🚨 TOTAL: $duplicateCount parágrafo(s) duplicado(s) encontrado(s) no roteiro final!');
      debugPrint('   💡 DICA: Fortaleça as instruções anti-repetição no prompt');
    } else {
      debugPrint('✅ VERIFICAÇÃO: Nenhuma duplicação de parágrafo detectada no roteiro final');
    }
  }

  /// 🚨 VALIDAÇÃO CRÍTICA: Detecta reutilização de nomes de personagens
  /// Cada personagem deve ter apenas 1 nome único
  void _validateProtagonistName(String generatedText, ScriptConfig config, int blockNumber) {
    final protagonistName = config.protagonistName.trim();
    if (protagonistName.isEmpty) return;
    
    // 🔥 PARTE 1: Validar protagonista específica
    final suspiciousNames = ['Wanessa', 'Carla', 'Beatriz', 'Fernanda', 'Juliana', 
                             'Mariana', 'Patrícia', 'Roberta', 'Silvia', 'Tatiana',
                             'Carlos', 'Eduardo', 'Fernando', 'Gustavo', 'Henrique',
                             'Leonardo', 'Marcelo', 'Rafael', 'Rodrigo', 'Thiago'];
    
    final hasProtagonist = generatedText.contains(protagonistName);
    
    for (final suspiciousName in suspiciousNames) {
      if (suspiciousName.toLowerCase() == protagonistName.toLowerCase()) continue;
      
      if (generatedText.contains(suspiciousName)) {
        // 🐛 DEBUG: Log erro crítico de nome
        _debugLogger.error(
          "Troca de nome detectada!",
          characterName: suspiciousName,
          blockNumber: blockNumber,
          details: "Protagonista deveria ser '$protagonistName' mas encontrei '$suspiciousName'",
        );
        
        debugPrint('🚨 ERRO CRÍTICO DETECTADO NO BLOCO $blockNumber:');
        debugPrint('   ❌ Protagonista deveria ser: "$protagonistName"');
        debugPrint('   ❌ Mas encontrei nome suspeito: "$suspiciousName"');
        debugPrint('   ⚠️ POSSÍVEL TROCA DE NOME DA PROTAGONISTA!');
        break;
      }
    }
    
    if (!hasProtagonist && blockNumber <= 2) {
      // 🐛 DEBUG: Log aviso de protagonista ausente
      _debugLogger.warning(
        "Protagonista ausente",
        details: "'$protagonistName' não apareceu no bloco $blockNumber",
        metadata: {'bloco': blockNumber, 'protagonista': protagonistName},
      );
      
      debugPrint('⚠️ AVISO: Protagonista "$protagonistName" não apareceu no bloco $blockNumber');
    } else if (hasProtagonist) {
      // 🐛 DEBUG: Log validação bem-sucedida
      _debugLogger.validation(
        "Protagonista validada",
        blockNumber: blockNumber,
        details: "'$protagonistName' presente no bloco",
        metadata: {'protagonista': protagonistName},
      );
    }
  }
  
  /// � NOVA VALIDAÇÃO: Detecta quando um nome é reutilizado para outro personagem
  /// Exemplo: "Marta" sendo usada para irmã da protagonista E irmã da antagonista
  void _validateNameReuse(String generatedText, _CharacterTracker tracker, int blockNumber) {
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
        
        // Verificar se o nome aparece em contexto diferente no texto atual
        // Exemplo: "Marta, irmã de Daniela" quando já existe "Marta, irmã de Angela"
        final contexts = [
          'irmã de', 'irmão de', 'filho de', 'filha de', 'pai de', 'mãe de',
          'esposa de', 'esposo de', 'marido de', 'neto de', 'neta de',
          'tio de', 'tia de', 'primo de', 'prima de', 'avô de', 'avó de'
        ];
        
        for (final context in contexts) {
          final pattern = RegExp('$name,?\\s+$context\\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)', caseSensitive: false);
          final match = pattern.firstMatch(generatedText);
          
          if (match != null) {
            final relatedPerson = match.group(1);
            
            // Se o papel existente não menciona essa pessoa, é reutilização!
            if (existingRole != null && relatedPerson != null && !existingRole.contains(relatedPerson)) {
              // 🐛 DEBUG: Log erro crítico de reutilização
              _debugLogger.error(
                "Reutilização de nome detectada!",
                characterName: name,
                blockNumber: blockNumber,
                details: "Nome '$name' usado em múltiplos contextos:\n"
                        "- Anterior: $existingRole\n"
                        "- Novo: $context $relatedPerson",
              );
              
              debugPrint('🚨🚨🚨 ERRO CRÍTICO DE REUTILIZAÇÃO DE NOME - BLOCO $blockNumber 🚨🚨🚨');
              debugPrint('   ❌ Nome "$name" está sendo REUTILIZADO!');
              debugPrint('   📋 Uso anterior: "$name" = $existingRole');
              debugPrint('   ⚠️ Novo uso detectado: "$name, $context $relatedPerson"');
              debugPrint('   💡 SOLUÇÃO: Cada personagem precisa de nome ÚNICO!');
              debugPrint('   💡 Sugestão: Trocar segundo "$name" por outro nome diferente');
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

  bool _looksLikePersonName(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return false;

    // 🔥 VALIDAÇÃO RIGOROSA E DEFINITIVA:
    // 🎯 APENAS aceitar nomes que estão no banco de dados curado do NameGeneratorService
    // Isso elimina TODOS os falsos positivos (verbos, advérbios, palavras comuns)
    
    // Verificar se está no banco curado
    if (NameGeneratorService.isValidName(cleaned)) {
      return true; // ✅ Nome 100% confirmado no banco de dados curado
    }

    // 🚫 Se NÃO está no banco curado, REJEITAR imediatamente
    // NÃO vamos mais aceitar "nomes" que a AI inventou
    if (kDebugMode) {
      debugPrint('⚠️ NOME REJEITADO (não está no banco curado): "$cleaned"');
    }
    return false;
  }

  static final Set<String> _nameStopwords = {
    // Plataformas/sites
    'youtube', 'internet', 'instagram', 'facebook', 'whatsapp', 'tiktok', 'google', 'cta',
    
    // Países/lugares
    'brasil', 'portugal', 'portugues',
    
    // Pronomes e palavras comuns capitalizadas no início de frases
    'ele', 'ela', 'eles', 'elas', 'nao', 'sim', 'mas', 'mais', 'cada', 'todo', 'toda', 'todos',
    'meu', 'minha', 'meus', 'minhas', 'seu', 'sua', 'seus', 'suas', 'nosso', 'nossa',
    'esse', 'essa', 'esses', 'essas', 'aquele', 'aquela', 'aquilo', 'isto', 'isso',
    'tudo', 'nada', 'algo', 'alguem', 'ninguem', 'qualquer', 'outro', 'outra', 'mesmo', 'mesma',
    'esta', 'este', 'estes', 'estas',
    
    // Substantivos comuns que podem ser capitalizados
    'filho', 'filha', 'filhos', 'pai', 'mae', 'pais', 'irmao', 'irma', 'tio', 'tia',
    'avo', 'neto', 'neta', 'marido', 'esposa', 'noivo', 'noiva',
    'amigo', 'amiga', 'primo', 'prima', 'sobrinho', 'sobrinha',
    'senhor', 'senhora', 'doutor', 'doutora', 'cliente', 'pessoa', 'pessoas', 'gente',
    'familia', 'casa', 'mundo', 'vida', 'tempo', 'dia', 'noite', 'momento',
    
    // Advérbios/conjunções/preposições comuns no início de frase
    'entao', 'depois', 'antes', 'agora', 'hoje', 'ontem', 'amanha', 'sempre', 'nunca',
    'talvez', 'porem', 'contudo', 'entretanto', 'portanto', 'enquanto', 'quando', 'onde',
    'havia', 'houve', 'tinha', 'foram', 'eram', 'estava', 'estavam',
    'dentro', 'fora', 'acima', 'abaixo', 'perto', 'longe', 'aqui', 'ali', 'alem',
    'apenas', 'somente', 'tambem', 'inclusive', 'ate', 'ainda', 'logo', 'ja', 'nem',
    
    // Preposições e artigos (raramente, mas podem aparecer)
    'com', 'sem', 'sobre', 'para', 'pela', 'pelo', 'uma', 'umas', 'uns', 'por',
    
    // 🔥 FIX CRÍTICO: Palavras que a AI usou como NOMES FANTASMA (do roteiro analisado)
    'lagrimas', 'lágrimas', 'justica', 'justiça', 'ponto', 'semanas', 'aconteceu',
    'todas', 'ajuda', 'consolo', 'vamos', 'conheço', 'conheco', 'lembra',
    
    // Verbos comuns no início de frase (EXPANDIDO)
    'era', 'foram', 'foi', 'seria', 'pode', 'podia', 'deve', 'devia',
    'senti', 'sentiu', 'pensei', 'pensou', 'vi', 'viu', 'ouvi', 'ouviu',
    'fiz', 'fez', 'disse', 'falou', 'quis', 'quiz', 'pude', 'pôde',
    'tive', 'teve', 'sabia', 'soube', 'imaginei', 'imaginou', 'acreditei', 'acreditou',
    'percebi', 'percebeu', 'notei', 'notou', 'lembrei', 'lembrou',
    'passei', 'abri', 'olhei', 'escrevo', 'escreveu', 'podes', 'pode',
    'queria', 'quer', 'quiz', 'quis', 'tinha', 'tenho', 'tem',
    'levei', 'levou', 'trouxe', 'deixei', 'deixou', 'encontrei', 'encontrou',
    'cheguei', 'chegou', 'sai', 'saiu', 'entrei', 'entrou',
    'peguei', 'pegou', 'coloquei', 'colocou', 'tirei', 'tirou', 'guardei', 'guardou',
    'voltei', 'voltou', 'segui', 'seguiu', 'comecei', 'começou', 'terminei', 'terminou',
  };

  static String perspectiveLabel(String perspective) {
    final perspectiveLower = perspective.toLowerCase();
    
    // 🔥 FIX: Detectar primeira pessoa em qualquer formato
    if (perspectiveLower.contains('primeira_pessoa') || perspectiveLower == 'first') {
      if (perspectiveLower.contains('mulher_idosa')) return 'Primeira pessoa - Mulher Idosa';
      if (perspectiveLower.contains('mulher_jovem')) return 'Primeira pessoa - Mulher Jovem';
      if (perspectiveLower.contains('homem_idoso')) return 'Primeira pessoa - Homem Idoso';
      if (perspectiveLower.contains('homem_jovem')) return 'Primeira pessoa - Homem Jovem';
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
    
    // Detectar primeira pessoa (qualquer variação)
    if (perspectiveLower.contains('primeira_pessoa') || perspectiveLower == 'first') {
      // Definir pronomes baseado no tipo de primeira pessoa
      String pronomes = 'EU, MEU, MINHA, COMIGO';
      String exemplos = '"EU vendi a casa...", "MEU coração batia forte...", "COMIGO ela nunca foi honesta..."';
      
      if (perspectiveLower.contains('mulher')) {
        exemplos = '"EU vendi a casa...", "MINHA nora me traiu...", "COMIGO ela nunca foi honesta..."';
      } else if (perspectiveLower.contains('homem')) {
        exemplos = '"EU construí esse negócio...", "MEU filho me abandonou...", "COMIGO ele sempre foi desleal..."';
      }
      
      return '''PERSPECTIVA NARRATIVA: PRIMEIRA PESSOA$protagonistInfo
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
  String _buildLimitedContext(String fullContext, int currentBlock, int maxRecentBlocks) {
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
    final recentBlocks = blocks.skip(max(0, blocks.length - maxRecentBlocks * 3)).join('\n\n');
    
    final result = '$initialSummary\n\n[...]\n\n$recentBlocks';
    
    // Verificar se ainda está muito grande
    if (_countWords(result) > maxContextWords) {
      // Reduzir ainda mais - só últimos blocos (REDUZIDO multiplicador de 3 para 2)
      return blocks.skip(max(0, blocks.length - maxRecentBlocks * 2)).join('\n\n');
    }
    
    return result;
  }

  // 🌍 MULTIPLICADORES DE VERBOSIDADE POR IDIOMA
  // Baseado em análise de quantas palavras cada idioma precisa para expressar a mesma ideia
  // Português = 1.0 (baseline) funciona perfeitamente
  double _getLanguageVerbosityMultiplier(String language) {
    final normalized = language.toLowerCase().trim();
    
    // 🇲🇽 ESPANHOL: Tende a ser ~15-20% mais verboso que português
    if (normalized.contains('espanhol') || normalized.contains('spanish') || normalized.contains('español') || normalized == 'es' || normalized == 'es-mx') {
      return 0.85; // Pedir 15% menos para compensar
    }
    
    // 🇬🇧 INGLÊS: Tende a ser ~35% mais verboso que português (ajustado após testes reais)
    if (normalized.contains('inglês') || normalized.contains('ingles') || normalized.contains('english') || normalized == 'en' || normalized == 'en-us') {
      return 0.73; // Pedir 27% menos para compensar a verbosidade excessiva
    }
    
    // 🇫🇷 FRANCÊS: Tende a ser ~10-15% mais verboso que português
    if (normalized.contains('franc') || normalized.contains('french') || normalized == 'fr') {
      return 0.90; // Pedir 10% menos para compensar
    }
    
    // 🇮🇹 ITALIANO: Tende a ser ~10% mais verboso que português
    if (normalized.contains('italia') || normalized.contains('italian') || normalized == 'it') {
      return 0.92; // Pedir 8% menos para compensar
    }
    
    // 🇩🇪 ALEMÃO: Similar ao português (palavras compostas compensam artigos)
    if (normalized.contains('alem') || normalized.contains('german') || normalized == 'de') {
      return 1.0; // Sem ajuste
    }
    
    // 🇷🇺 RUSSO: Muito conciso (sem artigos, casos gramaticais)
    if (normalized.contains('russo') || normalized.contains('russian') || normalized == 'ru') {
      return 1.15; // Pedir 15% mais para compensar
    }
    
    // 🇵🇱 POLONÊS: Ligeiramente mais conciso que português
    if (normalized.contains('polon') || normalized.contains('polish') || normalized == 'pl') {
      return 1.05; // Pedir 5% mais para compensar
    }
    
    // 🇹🇷 TURCO: Muito conciso (aglutinação de palavras)
    if (normalized.contains('turco') || normalized.contains('turk') || normalized == 'tr') {
      return 1.20; // Pedir 20% mais para compensar
    }
    
    // 🇧🇬 BÚLGARO: Similar ao russo, conciso
    if (normalized.contains('búlgar') || normalized.contains('bulgar') || normalized == 'bg') {
      return 1.12; // Pedir 12% mais para compensar
    }
    
    // 🇭🇷 CROATA: Ligeiramente mais conciso
    if (normalized.contains('croat') || normalized.contains('hrvat') || normalized == 'hr') {
      return 1.08; // Pedir 8% mais para compensar
    }
    
    // 🇷🇴 ROMENO: Similar ao português (língua latina)
    if (normalized.contains('romen') || normalized.contains('roman') || normalized == 'ro') {
      return 1.0; // Sem ajuste
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
    int blockNumber, {
    bool avoidRepetition = false, // 🔥 NOVO: Flag para regeneração anti-repetição
  }) async {
    // 🔧 IMPORTANTE: target vem SEMPRE em PALAVRAS de _calculateTargetForBlock()
    // Mesmo quando measureType='caracteres', _calculateTargetForBlock já converteu caracteres→palavras
    // O Gemini trabalha melhor com contagem de PALAVRAS, então sempre pedimos palavras no prompt
    // Depois contamos caracteres no resultado final para validar se atingiu a meta do usuário
    final needed = target;
    if (needed <= 0) return '';
    
    // 🔥 OTIMIZAÇÃO CRÍTICA: Limitar contexto aos últimos 4 blocos (reduzido de 5)
    // Para idiomas pesados (russo, chinês), contexto menor = menos timeout
    // Blocos iniciais (1-4): contexto completo
    // Blocos médios/finais (5+): últimos 4 blocos apenas
    String contextoPrevio = previous.isEmpty ? '' : _buildLimitedContext(previous, blockNumber, 4);
    
    if (kDebugMode && previous.isNotEmpty) {
      final contextUsed = contextoPrevio.length;
      final contextType = blockNumber <= 4 ? 'COMPLETO' : 'LIMITADO (últimos 4 blocos)';
      debugPrint('📚 CONTEXTO $contextType: $contextUsed chars (${_countWords(contextoPrevio)} palavras)');
      if (blockNumber > 4) {
        debugPrint('   Original: ${previous.length} chars → Reduzido: $contextUsed chars (${((1 - contextUsed / previous.length) * 100).toStringAsFixed(0)}% menor)');
      }
    }
    
    // 🔥 SOLUÇÃO 3: Reforçar os nomes confirmados no prompt para manter consistência
    String trackerInfo = '';
    if (tracker.confirmedNames.isNotEmpty) {
      trackerInfo = '\n⚠️ MANTENHA estes nomes exatamente como definidos: ${tracker.confirmedNames.join(", ")}\n';
      // 🔥 NOVO: Adicionar mapeamento personagem-papel
      final mapping = tracker.getCharacterMapping();
      if (mapping.isNotEmpty) {
        trackerInfo += mapping;
        trackerInfo += '⚠️ NUNCA confunda ou reutilize estes nomes! Cada nome = 1 personagem!\n';
      }
      if (kDebugMode) {
        debugPrint('🔥 Bloco $blockNumber - Nomes no tracker: ${tracker.confirmedNames.join(", ")}');
        if (mapping.isNotEmpty) {
          debugPrint('🎭 Mapeamento: ${tracker.confirmedNames.map((n) => "$n=${tracker.getRole(n) ?? '?'}").join(", ")}');
        }
      }
    }
    
    // 🚨 CORREÇÃO CRÍTICA: SEMPRE injetar nome da protagonista, mesmo que não esteja no tracker
    final protagonistName = c.protagonistName.trim();
    if (protagonistName.isNotEmpty && !trackerInfo.contains(protagonistName)) {
      trackerInfo += '\n🔥 ATENÇÃO ABSOLUTA: O NOME DA PROTAGONISTA É "$protagonistName"!\n';
      trackerInfo += '   ❌ NUNCA mude para outro nome (Wanessa, Carla, etc)\n';
      trackerInfo += '   ✅ SEMPRE use "$protagonistName" quando se referir à protagonista!\n';
    }
    final characterGuidance = _buildCharacterGuidance(c, tracker);
    
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
  final isSpanish = c.language.toLowerCase().contains('espanhol') || 
                    c.language.toLowerCase().contains('spanish') || 
                    c.language.toLowerCase().contains('español');
  
  final measure = isSpanish 
      ? 'GERE EXATAMENTE $adjustedTarget palabras (NO MÁXIMO $limitedNeeded - SE ULTRAPASSAR SERÁ REJEITADO!)'
      : 'GERE EXATAMENTE $adjustedTarget palavras';
  final localizationGuidance = _buildLocalizationGuidance(c);
    
    // 🔍 DEBUG: Verificar se modo GLOBAL está sendo passado corretamente
    if (kDebugMode) {
      debugPrint('🌍 MODO DE LOCALIZAÇÃO: ${c.localizationLevel.displayName}');
      if (c.localizationLevel == LocalizationLevel.global) {
        debugPrint('✅ MODO GLOBAL ATIVO - Prompt deve evitar nomes/comidas brasileiras');
        debugPrint('📝 Preview do prompt GLOBAL: ${localizationGuidance.substring(0, min(200, localizationGuidance.length))}...');
      }
    }
    
    // 🎯 INTEGRAR TÍTULO COMO HOOK IMPACTANTE NO INÍCIO
    String instruction;
    if (previous.isEmpty) {
      if (c.startWithTitlePhrase && c.title.trim().isNotEmpty) {
        instruction = _getStartInstruction(c.language, withTitle: true, title: c.title);
      } else {
        instruction = _getStartInstruction(c.language, withTitle: false);
      }
    } else {
      instruction = _getContinueInstruction(c.language);
    }
    
    // Gerar lista de nomes curados do banco de dados
    final nameList = NameGeneratorService.getNameListForPrompt(
      language: c.language,
      genre: c.genre, // NOVO: Usa genre do config (null = nomes do idioma, 'western' = nomes western)
      maxNamesPerCategory: 30,
    );
    
    // 🌍 Obter labels traduzidos para os metadados
    final labels = _getMetadataLabels(c.language);
    
    // 🌐 Preparar contexto com instrução de tradução se necessário
    final contextTranslationNote = c.context.trim().isNotEmpty 
        ? _getContextTranslationInstruction(c.language) 
        : '';
    
    // 🎯 Definir se inclui tema/subtema ou modo livre
    final temaSection = c.tema == 'Livre (Sem Tema)' 
        ? '// Modo Livre: Desenvolva o roteiro baseado APENAS no título e contexto fornecidos\n'
        : '${labels['theme']}: ${c.tema}\n${labels['subtheme']}: ${c.subtema}\n';
    
    // Prompt otimizado para ROTEIRO DE NARRAÇÃO limpo e com target específico
    final prompt = '⭐ IDIOMA OBRIGATÓRIO: ${_getLanguageInstruction(c.language)}\n' // 🚀 IDIOMA NA PRIMEIRA LINHA!
    '\n'
    '${contextoPrevio.isNotEmpty ? 'CONTEXTO:\n$contextoPrevio\n\n' : ''}'
  '$trackerInfo'
  '${avoidRepetition ? '\n🚨 AVISO URGENTE: O bloco anterior foi REJEITADO por repetição!\n⚠️ VOCÊ COPIOU PARÁGRAFOS DO CONTEXTO! Isso é PROIBIDO!\n✅ AGORA: Escreva conteúdo 100% NOVO, SEM copiar frases anteriores!\n   Use palavras DIFERENTES, estruturas DIFERENTES, avance a história!\n\n' : ''}'
  '${characterGuidance.isEmpty ? '' : characterGuidance}'
        '$instruction.\n' // ← Título JÁ está na instruction se withTitle=true
        '$temaSection'
    '${c.localizacao.trim().isEmpty ? '${labels['location']}: ${labels['locationNotSpecified']}' : '${labels['location']}: ${c.localizacao}'}\n'
        '${contextTranslationNote}${labels['additionalContext']}: ${c.context}\n'
    '$localizationGuidance'
    '\n'
    '$nameList\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '🚨 ATENÇÃO: A lista de nomes acima é sua ÚNICA fonte de nomes!\n'
    '   COPIE os nomes EXATAMENTE daquela lista ao criar personagens.\n'
    '   Se você usar palavras como "Observei", "Quero", "Pergunte" como nomes,\n'
    '   você está FALHANDO nesta tarefa. Esses são VERBOS, não NOMES!\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '\n'
    '⚠️ OBRIGATÓRIO: $measure - ESTE É UM REQUISITO ABSOLUTO!\n'
    '${isSpanish ? '🚨 ESPAÑOL - CONTROL ESTRICTO DE EXTENSIÓN:\n   • Tu bloque NO PUEDE superar las $limitedNeeded palabras\n   • Si generas más de $limitedNeeded palabras, el bloque será RECHAZADO\n   • Cuenta mentalmente mientras escribes y PARA cuando llegues al límite\n   • Es MEJOR terminar con ${adjustedTarget} palabras que pasarte del límite\n\n' : ''}'
        'FORMATO: ROTEIRO PARA NARRAÇÃO DE VÍDEO - apenas texto corrido para ser lido em voz alta.\n'
        'PROIBIDO: Emojis, símbolos, formatação markdown (incluindo backticks `), títulos, bullets, calls-to-action, hashtags, elementos visuais.\n'
        'OBRIGATÓRIO: Texto limpo, narrativo, fluido, pronto para narração direta. NUNCA use backticks (`) ou qualquer marcação ao redor de palavras.\n'
    '\n'
    '📖 ESTILO DE NARRATIVA PARA VÍDEOS LONGOS:\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '✅ PERMITIDO E ENCORAJADO para roteiros longos e envolventes:\n'
    '   • Reflexões profundas dos personagens sobre suas emoções e motivações\n'
    '   • Descrições detalhadas de ambientes e atmosferas\n'
    '   • Monólogos internos que revelam pensamentos complexos\n'
    '   • Desenvolvimento gradual de tensão ao longo de múltiplos parágrafos\n'
    '   • Digressões narrativas que enriquecem a história\n'
    '   • Análises psicológicas dos personagens\n'
    '   • Metáforas e simbolismos elaborados\n'
    '\n'
    '⏱️ TRANSIÇÕES TEMPORAIS: Use marcadores quando pular no tempo\n'
    '   ✅ BOM: "Três dias depois...", "Na manhã seguinte...", "Semanas se passaram..."\n'
    '\n'
    '🎭 DESENVOLVIMENTO DE CENAS:\n'
    '   • PODE descrever a mesma cena por vários parágrafos para criar imersão\n'
    '   • PODE alternar entre ação e reflexão para variar o ritmo\n'
    '   • PODE usar descrições longas para criar atmosfera\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '\n'
    'REGRAS DE CONSISTÊNCIA:\n'
    '- Continue exatamente do ponto onde o CONTEXTO parou; não reinicie a história.\n'
    '- Não repita parágrafos, cenas, diálogos ou cartas já escritos anteriormente.\n'
    '- Desenvolva a narrativa de forma rica e detalhada.\n'
    '- Use tanto AÇÃO quanto REFLEXÃO para criar uma narrativa completa e envolvente.\n'
    '\n'
    '🚨 PRESERVAÇÃO DE NOMES - REGRA ABSOLUTA E INEGOCIÁVEL:\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '⚠️ OS NOMES DE PERSONAGENS JÁ ESTABELECIDOS NO CONTEXTO ACIMA SÃO PERMANENTES!\n'
    '⚠️ VOCÊ NÃO PODE MUDAR, ALTERAR, OU SUBSTITUIR ESSES NOMES EM HIPÓTESE ALGUMA!\n'
    '⚠️ SE VOCÊ CRIAR NOVOS NOMES PARA PERSONAGENS JÁ EXISTENTES, O TEXTO SERÁ REJEITADO!\n'
    '\n'
    '✅ CORRETO: \"Daniela pegou o telefone\" (se Daniela já existe no contexto)\n'
    '❌ ERRADO: \"Sofia pegou o telefone\" (mudou o nome de Daniela para Sofia - PROIBIDO!)\n'
    '❌ ERRADO: \"A nora pegou o telefone\" (usou descrição genérica em vez do nome - PROIBIDO!)\n'
    '\n'
    '⚠️ ATENÇÃO ESPECIAL: PERSONAGENS SECUNDÁRIOS EM BLOCOS DISTANTES:\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    'Se um personagem secundário (advogado, amigo, vizinho, esposa de alguém, etc.)\n'
    'foi mencionado em blocos anteriores com um nome específico, você DEVE usar\n'
    'EXATAMENTE o mesmo nome se esse personagem aparecer novamente, MESMO que\n'
    'seja muitos blocos depois!\n'
    '\n'
    '📌 EXEMPLOS DE ERROS QUE VOCÊ DEVE EVITAR:\n'
    '\n'
    '❌ ERRADO: Bloco 5 menciona \"Sônia, a esposa do vilão\" e no Bloco 15 você escreve\n'
    '           \"Cláudia, a esposa do vilão\" — ISSO É PROIBIDO! Use \"Sônia\" novamente!\n'
    '\n'
    '❌ ERRADO: Bloco 3 apresenta \"Dr. Roberto, o médico\" e no Bloco 12 você escreve\n'
    '           \"Dr. Carlos atendeu a ligação\" — PROIBIDO! Continue usando \"Dr. Roberto\"!\n'
    '\n'
    '❌ ERRADO: Bloco 7 menciona \"Ricardo, o advogado\" e no Bloco 17 você apresenta\n'
    '           \"Ricardo, o arquiteto\" — PROIBIDO! Use OUTRO nome para o arquiteto!\n'
    '\n'
    '✅ CORRETO: Se \"Sônia\" apareceu no Bloco 5, use \"Sônia\" em TODOS os blocos seguintes\n'
    '            onde essa personagem aparecer, mesmo que seja no Bloco 15 ou 18!\n'
    '\n'
    '✅ CORRETO: Se \"Ricardo\" já é o advogado, o novo namorado deve ter OUTRO nome\n'
    '            (por exemplo: \"Fernando, o arquiteto\").\n'
    '\n'
    '🔍 ANTES DE CRIAR UM NOVO NOME: Releia o contexto acima e verifique se esse\n'
    '   personagem já foi mencionado com outro nome. Se sim, USE O NOME ORIGINAL!\n'
    '\n'
    '🚨 ATENÇÃO CRÍTICA - MEMBROS DA MESMA FAMÍLIA:\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '⚠️ NUNCA, EM HIPÓTESE ALGUMA, use o MESMO NOME para dois membros da família!\n'
    '\n'
    '❌ PROIBIDO: \"Mônica\" (protagonista) + \"minha irmã, Mônica\" = IMPOSSÍVEL!\n'
    '❌ PROIBIDO: \"Carlos\" (pai) + \"meu filho Carlos\" = CONFUSO E ABSURDO!\n'
    '❌ PROIBIDO: \"Helena\" (mãe) + \"minha sogra Helena\" = NÃO PODE!\n'
    '\n'
    '✅ REGRA: CADA personagem da família precisa de um nome ÚNICO e DIFERENTE!\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
    '🚨 NOMES DE PERSONAGENS - REGRA CRÍTICA E OBRIGATÓRIA:\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    'VOCÊ DEVE COPIAR E COLAR os nomes EXATAMENTE da lista "NOMES DISPONÍVEIS" acima.\n'
    '⚠️ ESTA É UMA REGRA ABSOLUTA - NÃO HÁ EXCEÇÕES!\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '\n'
    '✅ CORRETO - Exemplos de como usar:\n'
    '  • "Helena pegou o casaco" (Helena está na lista)\n'
    '  • "Lucas entrou na sala" (Lucas está na lista)\n'
    '  • "Sofia olhou para mim" (Sofia está na lista)\n'
    '\n'
    '❌ PROIBIDO - NUNCA faça isso:\n'
    '  • "Observei o casaco" → "Observei" NÃO é nome! Use "Marta observou"\n'
    '  • "Quero saber a verdade" → "Quero" NÃO é nome! Use "Carlos quer saber"\n'
    '  • "Pergunte a ele" → "Pergunte" NÃO é verbo! Use "Roberto perguntou"\n'
    '  • "Apenas sorriu" → "Apenas" NÃO é nome! Use "Ana apenas sorriu"\n'
    '  • "Imaginei que era tarde" → "Imaginei" é verbo! Use "Eu imaginei"\n'
    '\n'
    '🚨 ERROS REAIS QUE VOCÊ COMETEU ANTES (NUNCA REPITA):\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '❌ "Lágrimas" como nome de pessoa → É uma PALAVRA COMUM! Use "Marina" ou "Júlia"\n'
    '❌ "Justiça" como nome de pessoa → É um SUBSTANTIVO! Use "Beatriz" ou "Fernanda"\n'
    '❌ "Vamos" como nome de pessoa → É um VERBO! Use "Rafael" ou "André"\n'
    '❌ "Aconteceu" como nome de pessoa → É um VERBO! Use "Carlos" ou "Miguel"\n'
    '❌ "Ponto" como nome de pessoa → É uma PALAVRA! Use "Paulo" ou "Antônio"\n'
    '❌ "Semanas" como nome de pessoa → É uma PALAVRA! Use "Pedro" ou "José"\n'
    '❌ "Todas" como nome de pessoa → É um PRONOME! Use "Manuel" ou "Luís"\n'
    '❌ "Ajuda" e "Consolo" como nomes de irmãs → São SUBSTANTIVOS! Use "Rita e Clara"\n'
    '\n'
    '⚠️ REGRA: Se uma palavra NÃO está na lista "NOMES DISPONÍVEIS", NÃO É NOME!\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '\n'
    '📋 PROCESSO OBRIGATÓRIO para nomear personagens:\n'
    '1. PAUSE e OLHE para a lista "NOMES DISPONÍVEIS" acima\n'
    '2. IDENTIFIQUE: personagem é masculino ou feminino? Jovem, maduro ou idoso?\n'
    '3. ESCOLHA um nome da categoria apropriada\n'
    '4. COPIE o nome EXATAMENTE como está escrito na lista\n'
    '5. VERIFIQUE: este nome já foi usado para OUTRO personagem? Se SIM, escolha outro!\n'
    '\n'
    '⚠️ REGRA CRÍTICA: NUNCA use o mesmo nome para dois personagens diferentes!\n'
    '   ❌ ERRADO: \"Ricardo, o advogado\" (bloco 3) e depois \"Ricardo, o namorado\" (bloco 17)\n'
    '   ✅ CORRETO: \"Ricardo, o advogado\" (bloco 3) e depois \"Fernando, o namorado\" (bloco 17)\n'
    '\n'
    '🚨 REGRA ESPECIAL - PERSONAGENS DA MESMA FAMÍLIA:\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '⚠️ ATENÇÃO MÁXIMA: Membros da mesma família NUNCA podem ter o mesmo nome!\n'
    '\n'
    '❌ ERRADO: \"Mônica\" (protagonista) + \"minha irmã, Mônica\" = IMPOSSÍVEL!\n'
    '   → Se a narradora é Mônica, a irmã deve ser \"Sílvia\", \"Clara\" ou \"Maria\"\n'
    '\n'
    '❌ ERRADO: \"Carlos\" (pai) + \"meu filho Carlos\" = CONFUSO!\n'
    '   → Se o pai é Carlos, o filho deve ser \"André\", \"Pedro\" ou \"Lucas\"\n'
    '\n'
    '❌ ERRADO: \"Helena\" (avó) + \"minha neta Helena\" = NÃO FAZ SENTIDO!\n'
    '   → Se a avó é Helena, a neta deve ser \"Sofia\", \"Laura\" ou \"Julia\"\n'
    '\n'
    '✅ REGRA: Em uma mesma história, CADA PERSONAGEM precisa de um nome ÚNICO!\n'
    '   Isso vale ESPECIALMENTE para familiares: pais, filhos, irmãos, tios, avós.\n'
    '\n'
    '🚨 ERROS GRAVÍSSIMOS DE DUPLICAÇÃO QUE VOCÊ JÁ COMETEU:\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '❌ "Ricardo" usado para DOIS personagens: cobrador + gangster = PROIBIDO!\n'
    '   → Se Ricardo já é o cobrador, o gangster deve ser "Marcos" ou "Fernando"\n'
    '\n'
    '❌ "Sérgio" usado para DOIS personagens: policial + criminoso = ABSURDO!\n'
    '   → Se Sérgio é o policial gentil, o criminoso deve ser "Carlos" ou "Renato"\n'
    '\n'
    '❌ "Roberto" usado para DOIS personagens: taxista + médico = IMPOSSÍVEL!\n'
    '   → Se Roberto é o taxista, o médico deve ser "Dr. Alberto" ou "Dr. Henrique"\n'
    '\n'
    '🔥 ERRO NOVO DETECTADO - CONFUSÃO DE NOMES ENTRE PERSONAGENS:\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '❌ Bloco 7: Introduziu \"Daniela\" como estudante universitária\n'
    '❌ Bloco 13: Introduziu \"Larissa\" como ex-noiva de Theo\n'
    '❌ Bloco 14: Chamou a ex-noiva de \"Daniela\" (ERRADO! É \"Larissa\")\n'
    '❌ Bloco 18: Reutilizou \"Larissa\" para uma criança (JÁ USADO!)\n'
    '\n'
    '✅ SOLUÇÃO CORRETA:\n'
    '   • Daniela = sempre estudante universitária (nunca mudar!)\n'
    '   • Larissa = sempre ex-noiva de Theo (nunca mudar!)\n'
    '   • Criança do bloco 18 = usar \"Mariana\" ou \"Isabela\" (nome NOVO!)\n'
    '\n'
    '⚠️ REGRA DE OURO: Cada nome pertence a UM personagem ESPECÍFICO!\n'
    '   Se você introduziu \"Larissa\" como ex-noiva no bloco 13,\n'
    '   ela SEMPRE será a ex-noiva. NUNCA chame outro personagem de \"Larissa\"!\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '\n'
    '✅ SOLUÇÃO GERAL: Antes de dar um nome a um personagem novo, RELEIA o contexto\n'
    '   e verifique se esse nome JÁ FOI USADO. Se sim, escolha OUTRO nome!\n'
    '   E NUNCA confunda qual nome pertence a qual personagem!\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '\n'
    '🚨 ERRO CRÍTICO DETECTADO - REPETIÇÃO LITERAL DE PARÁGRAFOS:\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '🔥 ATENÇÃO MÁXIMA: Antes de escrever QUALQUER parágrafo, verifique:\n'
    '   "Eu JÁ escrevi algo parecido ou igual no contexto anterior?"\n'
    '   Se a resposta for SIM → MUDE COMPLETAMENTE as palavras e estrutura!\n'
    '\n'
    '❌ NUNCA copie parágrafos inteiros do contexto anterior!\n'
    '❌ NUNCA repita frases ou descrições que já foram escritas!\n'
    '❌ NUNCA use "Os dias/meses/semanas que se seguiram" se já usou antes!\n'
    '❌ NUNCA repita descrições de emoções ou ações já narradas!\n'
    '\n'
    '📋 EXEMPLOS DE REPETIÇÕES PROIBIDAS:\n'
    '❌ ERRADO: Copiar "Depois que Ian se foi, o quarto ficou mergulhado..."\n'
    '           palavra por palavra de um bloco anterior\n'
    '✅ CORRETO: Parafrasear com palavras DIFERENTES:\n'
    '           "Ian havia partido. Agora, apenas o silêncio preenchia..."\n'
    '\n'
    '❌ ERRADO: Repetir reflexões já feitas:\n'
    '           "O carrinho era sólido, real..." (se já escreveu isso antes)\n'
    '✅ CORRETO: Avançar a narrativa com NOVOS eventos:\n'
    '           "Guardei o carrinho na gaveta e fui preparar o jantar..."\n'
    '\n'
    '❌ ERRADO: Repetir parágrafos de transição temporal:\n'
    '           "Os meses que se seguiram foram..." → JÁ USADO? NÃO REPITA!\n'
    '           "Os dias que se seguiram foram..." → JÁ USADO? NÃO REPITA!\n'
    '           "As semanas que se seguiram..." → JÁ USADO? NÃO REPITA!\n'
    '           "Pedro mal falava. Ele se movia..." → JÁ USADO? NÃO REPITA!\n'
    '           QUALQUER parágrafo que você JÁ escreveu antes → NUNCA COPIE!\n'
    '✅ CORRETO: Use uma nova forma de transição:\n'
    '           "Aquele inverno foi diferente dos anteriores..."\n'
    '           "Um ano depois, a rotina tinha mudado completamente..."\n'
    '           "A primavera trouxe mudanças inesperadas..."\n'
    '\n'
    '⚠️ REGRA ABSOLUTA: Cada bloco deve ter conteúdo 100% NOVO!\n'
    '   • Se já descreveu um objeto → Não descreva novamente\n'
    '   • Se já fez uma reflexão → Avance para a próxima cena\n'
    '   • Se já narrou um evento → Conte o que aconteceu DEPOIS\n'
    '\n'
    '✅ TÉCNICAS PARA EVITAR REPETIÇÃO:\n'
    '   1. Ler o contexto e RESUMIR mentalmente o que já foi dito\n'
    '   2. Perguntar: "Este parágrafo avança a história?"\n'
    '   3. Usar sinônimos e estruturas de frase DIFERENTES\n'
    '   4. Focar em AÇÃO e DIÁLOGO, não apenas reflexões\n'
    '   5. Introduzir novos elementos: personagens, locais, eventos\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '\n'
    '⚠️ TESTE ANTES DE ESCREVER:\n'
    'Antes de usar qualquer palavra como nome, pergunte:\n'
    '"Esta palavra está na lista NOMES DISPONÍVEIS acima?"\n'
    'Se a resposta é NÃO → NÃO USE como nome!\n'
    '\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
        '${_getPerspectiveInstruction(c.perspective, c)}\n\n'
        '⚠️ LINGUAGEM ACESSÍVEL PARA TODAS AS IDADES (OBRIGATÓRIO):\n'
        '🎯 PÚBLICO-ALVO: Pessoas de 60+ anos, nível ensino fundamental\n'
        'Use APENAS vocabulário que seus AVÓS entendem facilmente!\n'
        '\n'
        '📌 REGRA DE OURO:\n'
        'Se você não usaria essa palavra conversando com sua AVÓ de 70 anos → NÃO USE!\n'
        '\n'
        '🚫 PALAVRAS PROIBIDAS (substitua por alternativas simples):\n'
        '- "embargada" → "trêmula", "falhando"\n'
        '- "cenográfica" → "teatral", "fingida"\n'
        '- "fulminante" → "fatal", "mortal"\n'
        '- "filantropo" → "pessoa que ajuda os outros"\n'
        '- "pária" → "rejeitado", "excluído"\n'
        '- "intimação" → "aviso", "chamado"\n'
        '- "insinuar" → "sugerir", "dar a entender"\n'
        '- "paranoico" → "desconfiado", "com medo"\n'
        '- "sibilar" → "sussurrar com raiva"\n'
        '- "carnificina" → "destruição", "massacre"\n'
        '- "estridência" → "barulho alto", "grito agudo"\n'
        '- "metodologia" → "jeito de fazer", "método"\n'
        '- "espécime" → "exemplo", "caso"\n'
        '- "catalisador" → "causa", "motivo"\n'
        '- "titã" → "gigante", "pessoa poderosa"\n'
        '- "fissura" → "rachadura", "brecha"\n'
        '\n'
        '✅ REGRAS DE SIMPLICIDADE (SEMPRE):\n'
        '1. FRASES CURTAS: Máximo 20-25 palavras por frase (mais fácil de acompanhar)\n'
        '2. VOCABULÁRIO DO DIA A DIA: Palavras de conversa com família, não de livro\n'
        '3. VERBOS SIMPLES: "eu fiz", "ele disse", "nós vimos" (sem complicação)\n'
        '4. SEM TERMOS TÉCNICOS: Explique tudo com palavras comuns\n'
        '5. TESTE MENTAL: "Minha avó de 70 anos entenderia facilmente?"\n'
        '6. EVITE: Palavras literárias, filosóficas, poéticas demais\n'
        '\n'
        '📝 EXEMPLOS DE SIMPLIFICAÇÃO:\n'
        '❌ "A confissão foi proferida com uma solenidade que beirava o absurdo"\n'
        '✅ "Ele confessou de um jeito quase ridículo de tão sério"\n'
        '\n'
        '❌ "Ela sibilou uma resposta embargada pela emoção"\n'
        '✅ "Ela sussurrou com raiva, a voz tremendo de emoção"\n'
        '\n'
        '❌ "Minha metodologia era simples e metódica"\n'
        '✅ "Comecei devagar, do jeito que aprendi no arquivo"\n'
        '\n'
        '❌ "A dor foi engolida por uma clareza fria e assustadora"\n'
        '✅ "Doeu muito. Mas logo virou raiva. Uma raiva gelada"\n'
        '\n'
        '❌ "Éramos curadores de um museu particular de dor"\n'
        '✅ "Nós dois vivíamos presos naquela dor, cada um no seu canto"\n'
        '\n'
        '❌ "Todo titã tem fissuras em sua armadura"\n'
        '✅ "Todo mundo tem um ponto fraco. Eu só precisava achar o dele"\n'
        '\n'
        '⭐ IMPORTANTE: Desenvolva a narrativa com riqueza de detalhes, diálogos, descrições e desenvolvimento de personagens para atingir EXATAMENTE o número de ${c.measureType} solicitado. SEMPRE use frases curtas (máximo 20-25 palavras), palavras simples que seus avós entendem, e linguagem de conversa natural familiar.\n'
        '\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '🎭 REGRAS PARA TWISTS E REVELAÇÕES (CRÍTICO PARA YOUTUBE):\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '\n'
        '⚠️ ATENÇÃO: Público do YouTube precisa de CLAREZA, não ambiguidade filosófica!\n'
        '\n'
        '✅ SE VOCÊ INCLUIR UM TWIST (revelação surpreendente):\n'
        '\n'
        '1️⃣ PREPARE O TERRENO (Foreshadowing):\n'
        '   ❌ ERRADO: Revelar do nada no final que "tudo era mentira"\n'
        '   ✅ CORRETO: Plantar 2-3 pistas sutis nos blocos anteriores\n'
        '   \n'
        '   Exemplo de pista sutil:\n'
        '   - "Ele parecia nervoso ultimamente, mas eu ignorei"\n'
        '   - "Encontrei um recibo estranho, mas não dei importância"\n'
        '   - "Seus amigos novos me pareciam suspeitos"\n'
        '\n'
        '2️⃣ DÊ POSIÇÃO CLARA AO NARRADOR:\n'
        '   ❌ ERRADO: "Eu não sei mais o que pensar... talvez ele fosse culpado... ou não..."\n'
        '   ✅ CORRETO: "Agora eu sei a verdade. Ele errou, mas isso não justifica o que fizeram"\n'
        '   \n'
        '   O narrador DEVE ter uma conclusão clara, mesmo que dolorosa:\n'
        '   - "Mesmo sabendo disso, minha dor continua válida"\n'
        '   - "A verdade mudou como vejo, mas não mudou meu amor"\n'
        '   - "Ambos eram culpados, cada um à sua maneira"\n'
        '\n'
        '3️⃣ RESOLUÇÃO EMOCIONAL OBRIGATÓRIA:\n'
        '   ❌ ERRADO: Terminar com "...e eu fiquei pensando nisso" [fim abrupto]\n'
        '   ✅ CORRETO: "Aprendi que a verdade não é simples, mas encontrei minha paz"\n'
        '   \n'
        '   O espectador PRECISA saber:\n'
        '   - Como o narrador se sente AGORA sobre tudo\n'
        '   - Qual lição foi aprendida (mesmo que dolorosa)\n'
        '   - Se há paz, aceitação, ou continuação da luta\n'
        '\n'
        '4️⃣ EVITE CONTRADIÇÕES COM O INÍCIO:\n'
        '   ❌ ERRADO: \n'
        '   - Blocos 1-6: "Ele era inocente, vou vingar!"\n'
        '   - Bloco 7: "Na verdade ele era culpado e mereceu"\n'
        '   [Espectador se sente ENGANADO]\n'
        '   \n'
        '   ✅ CORRETO:\n'
        '   - Blocos 1-6: "Ele era inocente... ou eu pensava isso"\n'
        '   - Bloco 7: "Descobri que havia mais na história"\n'
        '   [Espectador se sente INTRIGADO, não traído]\n'
        '\n'
        '5️⃣ TESTE DO "ESPECTADOR SATISFEITO":\n'
        '   Antes de finalizar, pergunte:\n'
        '   - ✅ "O espectador entende CLARAMENTE o que aconteceu?"\n'
        '   - ✅ "O narrador tem uma POSIÇÃO DEFINIDA sobre os eventos?"\n'
        '   - ✅ "Há um FECHAMENTO EMOCIONAL (paz, aceitação, ou decisão clara)?"\n'
        '   - ✅ "A jornada do início ao fim faz SENTIDO COMPLETO?"\n'
        '   \n'
        '   Se QUALQUER resposta for NÃO → Reescreva o final!\n'
        '\n'
        '📌 REGRA DE OURO PARA YOUTUBE:\n'
        'Complexidade moral é BEM-VINDA, mas AMBIGUIDADE SEM RESOLUÇÃO é PROIBIDA!\n'
        'O espectador pode aceitar "a verdade era complicada", mas NÃO aceita "não sei o que pensar".\n'
        '\n'
        '✅ EXEMPLO BOM de final com twist:\n'
        '"Descobri que meu filho tinha culpa também. Isso não apaga minha dor,\n'
        'mas mudou minha raiva. Ele errou, mas não merecia morrer. E ela,\n'
        'mesmo tendo razões, escolheu o pior caminho. Ambos pagaram o preço\n'
        'de suas escolhas. Eu aprendi que a verdade raramente é simples,\n'
        'mas isso não significa que devo viver na dúvida. Fiz as pazes com\n'
        'a memória imperfeita do meu filho. E essa é a minha paz."\n'
        '\n'
        '❌ EXEMPLO RUIM de final ambíguo:\n'
        '"Agora não sei mais o que pensar. Talvez ele fosse culpado, talvez não.\n'
        'Talvez ela fosse vítima, talvez não. Fico aqui pensando nisso."\n'
        '[ESPECTADOR FRUSTRANDO - NÃO FAÇA ISSO!]\n'
        '\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
        
    if (kDebugMode) debugPrint('[$_instanceId] Gerando bloco balanceado: $limitedNeeded ${c.measureType}');
    
    try {
      // 🚀 GEMINI 2.5 PRO: Suporta até 65.535 tokens de saída!
      // Aumentado para 50.000 tokens (76% da capacidade) para idiomas cirílicos
      
      // 🌐 AJUSTE: Idiomas não-latinos (cirílico, etc.) consomem mais tokens
      final languageNormalized = c.language.toLowerCase().trim();
      final isCyrillic = languageNormalized.contains('russo') || 
                         languageNormalized.contains('búlgar') || 
                         languageNormalized.contains('bulgar') ||
                         languageNormalized == 'ru' || 
                         languageNormalized == 'bg';
      final isTurkish = languageNormalized.contains('turco') || languageNormalized == 'tr';
      
      // Cirílico e turco precisam de 5x mais tokens por caractere (aumentado de 4x)
      // Idiomas latinos mantêm 2.5x (aumentado de 2x) para mais margem
      final tokenMultiplier = c.measureType == 'caracteres' 
          ? (isCyrillic || isTurkish ? 5.0 : 2.5) 
          : 12.0; // Aumentado de 10.0 para 12.0 para palavras
      
      final maxTokensCalculated = (needed * tokenMultiplier).ceil();
      final maxTokensLimit = 50000; // Aumentado de 32.768 para 50.000 tokens
      final finalMaxTokens = maxTokensCalculated > maxTokensLimit ? maxTokensLimit : maxTokensCalculated;
      
      // 🤖 SELEÇÃO DE MODELO BASEADA EM qualityMode
      final selectedModel = c.qualityMode == 'flash' ? 'gemini-2.5-flash' : 'gemini-2.5-pro';
      
      final data = await _makeApiRequest(
        apiKey: c.apiKey,
        model: selectedModel,
        prompt: prompt,
        maxTokens: finalMaxTokens,
      );
  final text = data ?? '';
  final filtered = text.isNotEmpty ? _filterDuplicateParagraphs(previous, text) : '';
  
  // 🔥 VALIDAÇÃO DE TAMANHO: Rejeitar blocos que ultrapassem muito o limite
  // Aplicável a TODOS os idiomas, não só espanhol
  if (filtered.isNotEmpty && languageMultiplier != 1.0) {
    final wordCount = _countWords(filtered);
    final overage = wordCount - limitedNeeded;
    final overagePercent = (overage / limitedNeeded) * 100;
    
    // Rejeitar se ultrapassar mais de 10% do limite
    if (overagePercent > 10) {
      if (kDebugMode) {
        debugPrint('❌ BLOCO $blockNumber REJEITADO (${c.language.toUpperCase()}):');
        debugPrint('   Multiplicador do idioma: ${languageMultiplier}x');
        debugPrint('   Pedido: $adjustedTarget palavras (limite máximo: $limitedNeeded)');
        debugPrint('   Recebido: $wordCount palavras (+${overagePercent.toStringAsFixed(1)}%)');
        debugPrint('   🔄 Retornando vazio para forçar regeneração...');
      }
      return ''; // Forçar regeneração
    }
    
    if (kDebugMode && overage > 0) {
      debugPrint('✅ BLOCO $blockNumber ACEITO (${c.language.toUpperCase()}):');
      debugPrint('   Multiplicador: ${languageMultiplier}x | Pedido: $adjustedTarget palavras');
      debugPrint('   Recebido: $wordCount palavras (+${overagePercent.toStringAsFixed(1)}%)');
    }
  }
  
  // 🔥 LOGGING: Detectar quando bloco retorna vazio
  if (filtered.isEmpty) {
    if (kDebugMode) {
      debugPrint('⚠️ BLOCO $blockNumber VAZIO DETECTADO!');
      if (data == null) {
        debugPrint('   Causa: API retornou null (bloqueio de conteúdo ou erro)');
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

  Future<String> _generateExpansion(
    String original, 
    double targetAdd, 
    ScriptConfig c,
    _CharacterTracker tracker,  // 🔥 FIX: Adicionar tracker para manter personagens consistentes
  ) async {
    final needed = targetAdd.round();
    
    // 🔥 FIX: Passar TODO o contexto (não apenas 200 palavras) para manter personagens
    String contextoExpansao = original.isNotEmpty ? original : '';
    
    if (kDebugMode && original.isNotEmpty) {
      debugPrint('📚 EXPANSÃO - CONTEXTO COMPLETO: ${original.length} chars (${_countWords(original)} palavras)');
    }
    
    // 🔥 FIX: Adicionar nomes confirmados para reforçar consistência
    String trackerInfo = '';
    if (tracker.confirmedNames.isNotEmpty) {
      trackerInfo = '\n⚠️ MANTENHA estes nomes exatamente como definidos: ${tracker.confirmedNames.join(", ")}\n';
      if (kDebugMode) {
        debugPrint('🔥 EXPANSÃO - Nomes no tracker: ${tracker.confirmedNames.join(", ")}');
      }
    }
    final characterGuidance = _buildCharacterGuidance(c, tracker);
    
  final measure = c.measureType == 'caracteres' ? 'Adicione EXATAMENTE $needed caracteres ou mais' : 'Adicione EXATAMENTE $needed palavras ou mais';
  final localizationGuidance = _buildLocalizationGuidance(c);
  
  // Gerar lista de nomes curados do banco de dados
  final nameList = NameGeneratorService.getNameListForPrompt(
    language: c.language,
    genre: c.genre, // NOVO: Usa genre do config (null = nomes do idioma, 'western' = nomes western)
    maxNamesPerCategory: 30,
  );
  
  // 🌍 Obter labels traduzidos para os metadados
  final labels = _getMetadataLabels(c.language);
  
    final prompt = 'Continue a narrativa de forma natural e fluida:\n\n$contextoExpansao\n\n'
  '$trackerInfo'
  '${characterGuidance.isEmpty ? '' : characterGuidance}'
        '$measure\n'
        '${labels['theme']}: ${c.tema}\n'
        '${labels['subtheme']}: ${c.subtema}\n'
    '${c.localizacao.trim().isEmpty ? '${labels['location']}: ${labels['locationNotSpecified']}' : '${labels['location']}: ${c.localizacao}'}\n'
    '$localizationGuidance'
    '\n'
    '⭐ IDIOMA OBRIGATÓRIO: ${_getLanguageInstruction(c.language)}\n'
    '\n'
    '$nameList\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '🚨 ATENÇÃO: A lista de nomes acima é sua ÚNICA fonte de nomes!\n'
    '   COPIE os nomes EXATAMENTE daquela lista ao criar personagens.\n'
    '   Se você usar palavras como "Observei", "Quero", "Pergunte" como nomes,\n'
    '   você está FALHANDO nesta tarefa. Esses são VERBOS, não NOMES!\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '\n'
    '⚠️ IMPORTANTE: Continue a história mantendo exatamente os mesmos nomes e relações dos personagens confirmados. Novos personagens só se forem indispensáveis, mas nunca renomeie os já existentes.\n'
    '\n'
    '🚨 NOMES DE PERSONAGENS - REGRA CRÍTICA:\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '✅ CORRETO: "Helena pegou", "Lucas entrou", "Sofia olhou" (nomes da lista)\n'
    '❌ PROIBIDO: "Observei o casaco", "Quero saber", "Pergunte a ele" (são VERBOS!)\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '\n'
        '⚠️ LINGUAGEM ACESSÍVEL (OBRIGATÓRIO):\n'
        '- Use APENAS palavras SIMPLES que pessoas comuns conhecem\n'
        '- Frases CURTAS: máximo 25-30 palavras por frase\n'
        '- EVITE: palavras difíceis, termos técnicos, futuro do pretérito\n'
        '- PREFIRA: presente simples, passado simples, palavras do dia a dia\n'
        '- Exemplos de substituição: "embargada"→"trêmula", "filantropo"→"pessoa que ajuda", "pária"→"rejeitado"\n'
        '- Teste: "Alguém que só vê YouTube entenderia essa palavra?" Se não, troque por uma mais simples.\n'
        '- PROIBIDO: Usar backticks (`) ou qualquer marcação de formatação no texto narrativo.\n'
        '\n'
        'Mantenha a consistência com o tema, subtema e localização estabelecidos.\n'
        'REGRAS DE CONSISTÊNCIA:\n'
        '- Não repita parágrafos, cenas, diálogos ou cartas já presentes no texto original.\n'
        '- Nunca reinicie a história; avance a partir do ponto atual.\n'
        '\n'
        'Continue escrevendo sem usar títulos, marcadores ou palavras como "CONTINUAÇÃO". Apenas prossiga com a história de forma natural usando frases curtas e palavras simples.';
    
    try {
      // 🤖 SELEÇÃO DE MODELO BASEADA EM qualityMode
      final selectedModel = c.qualityMode == 'flash' ? 'gemini-2.5-flash' : 'gemini-2.5-pro';
      
      final data = await _makeApiRequest(
        apiKey: c.apiKey,
        model: selectedModel,
        prompt: prompt,
        maxTokens: max(8192, (targetAdd * 3.0).ceil()), // Gemini 2.5 Pro: Mínimo 8192, ou 3x o target
      );
  final text = data ?? '';
  final filtered = text.isNotEmpty ? _filterDuplicateParagraphs(original, text) : '';
  return filtered.isNotEmpty ? '\n$filtered' : '';
    } catch (_) { 
      return ''; 
    }
  }

  Future<String?> _makeApiRequest({
    required String apiKey, 
    required String model, 
    required String prompt, 
    required int maxTokens
  }) async {
    // 🚀 Gemini 2.5 Pro suporta até 65.535 tokens de saída
    // Usando limite generoso para aproveitar capacidade total
    final adjustedMaxTokens = maxTokens < 8192 ? 8192 : min(maxTokens * 2, 32768);
    
    final resp = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        'contents': [ {'parts': [ {'text': prompt} ]} ],
        'generationConfig': {
          'temperature': 0.8,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': adjustedMaxTokens,
        }
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
      debugPrint('🚫 GeminiService: CONTEÚDO BLOQUEADO - Razão: $blockReason');
      debugPrint('⚠️ GeminiService: Contexto contém conteúdo sensível detectado pela API');
      // Retornar null para que o sistema continue sem este bloco
      // O sistema vai tentar continuar com contexto reduzido
      return null;
    }
    
    // Verificar finish reason
    final finishReason = resp.data['candidates']?[0]?['finishReason'];
    if (finishReason == 'MAX_TOKENS') {
      debugPrint('GeminiService: Aviso - Resposta cortada por limite de tokens');
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

  // Método público para uso nos providers - OTIMIZADO PARA CONTEXTO
  Future<String> generateTextWithApiKey({
    required String prompt,
    required String apiKey,
    String model = 'gemini-2.5-pro',
    int maxTokens = 16384, // AUMENTADO: Era 8192, agora 16384 para contextos mais ricos
  }) async {
    // CORREÇÃO: Reset de estado para evitar conflitos com geração de scripts
    if (_isCancelled) _isCancelled = false;
    
    return await _retryOnRateLimit(() async {
      try {
        debugPrint('GeminiService: Iniciando requisição para modelo $model');
        final result = await _makeApiRequest(
          apiKey: apiKey,
          model: model,
          prompt: prompt,
          maxTokens: maxTokens,
        );
        debugPrint('GeminiService: Resposta recebida - ${result != null ? 'Success' : 'Null'}');
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
  bool _hasLiteralDuplication(String newBlock, String previousContent) {
    if (previousContent.isEmpty || newBlock.isEmpty) return false;
    
    // Dividir em blocos de 200 palavras
    final newWords = newBlock.trim().split(RegExp(r'\s+'));
    final prevWords = previousContent.trim().split(RegExp(r'\s+'));
    
    if (newWords.length < 200 || prevWords.length < 200) return false;
    
    // Verificar se há sequências de 200+ palavras idênticas
    for (int i = 0; i <= newWords.length - 200; i++) {
      final newSequence = newWords.sublist(i, i + 200).join(' ').toLowerCase();
      
      for (int j = 0; j <= prevWords.length - 200; j++) {
        final prevSequence = prevWords.sublist(j, j + 200).join(' ').toLowerCase();
        
        // Se encontrar sequência idêntica de 200+ palavras = DUPLICAÇÃO LITERAL
        if (newSequence == prevSequence) {
          if (kDebugMode) {
            debugPrint('🚨 DUPLICAÇÃO LITERAL DETECTADA!');
            debugPrint('   Sequência de 200 palavras copiada exatamente!');
            debugPrint('   Preview: ${newSequence.substring(0, min(100, newSequence.length))}...');
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
    final normalized1 = text1.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalized2 = text2.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    
    if (normalized1 == normalized2) return 1.0; // Idênticos
    
    // Criar n-grams (sequências de N palavras)
    const nGramSize = 8; // 🔥 AUMENTADO: Era 5, agora 8 para detectar blocos maiores
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
  bool _isTooSimilar(String newBlock, String previousContent, {double threshold = 0.85}) {
    if (previousContent.isEmpty) return false;
    
    // 🔥 PRIORIDADE 1: Verificar duplicação literal de blocos grandes (cópia exata)
    if (_hasLiteralDuplication(newBlock, previousContent)) {
      if (kDebugMode) {
        debugPrint('🚨 BLOQUEIO CRÍTICO: Duplicação literal de bloco inteiro detectada!');
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
    final paragraphs = limitedPrevious.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    
    // 🚀 OTIMIZAÇÃO CRÍTICA: Limitar a 10 últimos parágrafos (era 20)
    // Reduzido para eliminar travamentos "não respondendo"
    final recentParagraphs = paragraphs.length > 10 
        ? paragraphs.sublist(paragraphs.length - 10)
        : paragraphs;
    
    // Dividir novo bloco em parágrafos
    final newParagraphs = newBlock.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    
    // Verificar cada parágrafo novo contra os RECENTES (não todos)
    int highSimilarityCount = 0;
    
    for (final newPara in newParagraphs) {
      if (newPara.trim().length < 100) continue; // Ignorar parágrafos muito curtos
      
      // 🚀 OTIMIZAÇÃO: Parar se já encontrou repetição suficiente
      if (highSimilarityCount >= 2) break;
      
      for (final oldPara in recentParagraphs) {
        if (oldPara.trim().length < 100) continue;
        
        final similarity = _calculateSimilarity(newPara, oldPara);
        
        if (similarity >= threshold) {
          highSimilarityCount++;
          if (kDebugMode) {
            debugPrint('⚠️ REPETIÇÃO DETECTADA (parágrafo $highSimilarityCount)!');
            debugPrint('   Similaridade: ${(similarity * 100).toStringAsFixed(1)}% (threshold: ${(threshold * 100).toInt()}%)');
          }
          
          // 🔥 Se encontrar 2+ parágrafos muito similares = bloco repetido
          if (highSimilarityCount >= 2) {
            if (kDebugMode) {
              debugPrint('🚨 BLOQUEIO: $highSimilarityCount parágrafos com alta similaridade!');
            }
            return true;
          }
          break; // Não precisa comparar esse parágrafo com outros
        }
      }
    }
    
    return false;
  }

  /// Extrai frases únicas do contexto para evitar repetição
  Set<String> _extractUniqueSentences(String text) {
    final sentences = text.split(RegExp(r'[.!?]\s+'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.length > 20) // Apenas frases com mais de 20 chars
        .toSet();
    return sentences;
  }

  int _countWords(String text) => text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  // Método estático para compatibilidade
  static void setApiTier(String tier) {
    // Implementação vazia para compatibilidade
  }

  // ===================== MÉTODOS CTA E FERRAMENTAS AUXILIARES =====================

  Future<Map<String, String>> generateCtasForScript({
    required String scriptContent,
    required String apiKey,
    required List<String> ctaTypes,
    String? customTheme,
    String language = 'Português',
    String perspective = 'terceira_pessoa', // PERSPECTIVA CONFIGURADA PELO USUÁRIO
  }) async {
    try {
      // Usar idioma e perspectiva configurados pelo usuário (não detectar)
      final finalLanguage = language;
      
      // Analisar contexto da história
      final scriptContext = await _analyzeScriptContext(scriptContent, apiKey, finalLanguage);
      
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
        model: 'gemini-2.5-flash-lite', // Flash-lite é mais rápido e OBEDECE melhor a instruções de perspectiva
        maxTokens: 3072,
      );
      
      if (result.isEmpty) {
        throw Exception('Resposta vazia do Gemini');
      }

      return _parseCtaResponse(result, ctaTypes);
    } catch (e) {
      if (kDebugMode) debugPrint('Erro generateCtasForScript: $e');
      return {};
    }
  }

  Future<String> _detectScriptLanguage(String scriptContent, String apiKey) async {
    final prompt = '''
Analise o texto abaixo e identifique APENAS o idioma.
Responda com UMA PALAVRA: Português, Inglês, Espanhol, Francês, Alemão, Italiano, Russo, Polonês, Búlgaro, Croata, Romeno, Turco, ou Outro.

TEXTO:
${scriptContent.substring(0, scriptContent.length > 500 ? 500 : scriptContent.length)}
''';

    try {
      final result = await generateTextWithApiKey(
        prompt: prompt,
        apiKey: apiKey,
        model: 'gemini-2.5-flash-lite', // Ultra rápido para detecção simples
        maxTokens: 50,
      );
      return result.trim();
    } catch (e) {
      return '';
    }
  }

  Future<String> _analyzeScriptContext(String scriptContent, String apiKey, String language) async {
    final prompt = '''
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
        model: 'gemini-2.5-flash-lite', // Ultra rápido para análise simples
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
    final requestedTypes = ctaTypes.map((type) => 
        '"$type": ${ctaDescriptions[type] ?? "Call-to-action personalizado"}').join('\n');

    // ⚡ USAR PERSPECTIVA CONFIGURADA PELO USUÁRIO (não detectar)
    final isPrimeiraPessoa = perspective.contains('primeira_pessoa');
    
    if (kDebugMode) {
      debugPrint('🎯 Perspectiva Configurada pelo Usuário: $perspective');
      debugPrint('   → ${isPrimeiraPessoa ? "PRIMEIRA PESSOA" : "TERCEIRA PESSOA"}');
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
• "Se minha jornada te emocionou, inscreva-se e deixe seu like para seguir meu caminho"
• "O que você faria no meu lugar? Deixe sua opinião nos comentários"
• "Minha história está só começando. Ative o sininho para não perder nada"
• "Eu preciso da sua ajuda para continuar. Compartilhe meu relato"

❌ PROIBIDO (quebra a perspectiva):
• Falar sobre "o protagonista", "ele/ela", "a história dele/dela"
• Usar "esta história" → Use "minha história"
• Usar nomes próprios em 3ª pessoa → Use "eu/meu"
• Capitalizar tudo: "EU/MEU/MINHA" → Use "eu/meu/minha"
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

    return '''
⚠️⚠️⚠️ ATENÇÃO CRÍTICA: PERSPECTIVA NARRATIVA É A REGRA #1 ⚠️⚠️⚠️

$perspectiveInstruction

═══════════════════════════════════════════════════════════════

Gere CTAs (calls-to-action) personalizados em $language para este roteiro.

CONTEXTO DO ROTEIRO: $scriptContext
TEMA PERSONALIZADO: ${customTheme ?? 'Não especificado'}

ROTEIRO (trecho inicial):
${scriptContent.substring(0, scriptContent.length > 2000 ? 2000 : scriptContent.length)}

═══════════════════════════════════════════════════════════════
🎯 PROPÓSITO ESPECÍFICO DE CADA TIPO DE CTA:
═══════════════════════════════════════════════════════════════

📌 "subscription" (CTA DE INÍCIO):
   • Objetivo: Pedir INSCRIÇÃO no canal + LIKE
   • Momento: Logo no INÍCIO da história, após o gancho inicial
   • Estrutura: [Gancho emocional do início] + "Inscreva-se e deixe seu like"
   • Exemplo (1ª pessoa): "Eu descobri algo nas paredes que mudou tudo. Se minha angústia te tocou, inscreva-se e deixe seu like para acompanhar."
   • Exemplo (3ª pessoa): "Kátia descobriu algo nas paredes que mudou tudo. Inscreva-se e deixe seu like para não perder essa história."

📌 "engagement" (CTA DE MEIO):
   • Objetivo: Pedir COMENTÁRIOS sobre o que estão achando + COMPARTILHAMENTOS
   • Momento: No MEIO da história, após uma reviravolta importante
   • Estrutura: Pergunta direta sobre opinião + "comente o que está achando" + "compartilhe"
   • Exemplo (1ª pessoa): "O que você faria no meu lugar? Comente o que está achando dessa situação e compartilhe com quem entenderia."
   • Exemplo (3ª pessoa): "O que você acha da decisão de Kátia? Comente o que está achando e compartilhe com amigos."

📌 "final" (CTA DE CONCLUSÃO):
   • Objetivo: CTA CONCLUSIVO - história acabou, pedir FEEDBACK + INSCRIÇÃO para mais histórias
   • Momento: No FINAL da história, após a resolução
   • Estrutura: [Resumo do desfecho] + "O que você achou?" + "Inscreva-se para mais histórias como esta"
   • Exemplo (1ª pessoa): "Minha jornada finalmente chegou ao fim. O que você achou do meu desfecho? Inscreva-se para acompanhar mais histórias emocionantes como esta."
   • Exemplo (3ª pessoa): "A história de Kátia chegou ao fim. O que você achou desse desfecho? Inscreva-se para mais histórias impactantes como esta."

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
4. 🔥 CTAs devem usar DETALHES ESPECÍFICOS do roteiro (objetos, ações, revelações CONCRETAS)
5. 🚫 PROIBIDO usar palavras genéricas: "jornada", "narrativa", "explorar", "revelar"
6. ✅ OBRIGATÓRIO mencionar ELEMENTOS CHOCANTES: nomes, objetos, ações específicas
7. Cada CTA: 25-45 palavras (DIRETO E IMPACTANTE, com espaço para CTAs completos)
8. Linguagem VISCERAL e DRAMÁTICA em $language (não formal/acadêmica)
9. Tom emocional IGUAL ao do roteiro (se é intenso, CTA é intenso; se é suave, CTA é suave)
10. Se protagonista tomou DECISÃO EXTREMA (expulsar filho, confrontar vilão), mencione isso!
11. NÃO prometa eventos futuros que já aconteceram no roteiro
12. Retorne JSON válido apenas

⚠️⚠️⚠️ CHECKLIST FINAL - RESPONDA ANTES DE GERAR: ⚠️⚠️⚠️
□ Reli as instruções de PERSPECTIVA NARRATIVA no topo?
□ ${isPrimeiraPessoa ? "Vou usar 'eu/meu/minha' em MINÚSCULAS (não EU/MEU/MINHA)?" : "Vou usar nomes próprios/ela/ele/esta história?"}
□ Cada CTA segue seu PROPÓSITO ESPECÍFICO?
  • subscription = inscrição + like?
  • engagement = comentários + compartilhamento?
  • final = feedback + inscrição para mais histórias?
□ Mencionei DETALHES ESPECÍFICOS do roteiro (nomes, objetos-chave, ações concretas)?
□ EVITEI palavras genéricas ("jornada", "narrativa", "revelar", "explorar")?
□ O tom do CTA está TÃO INTENSO quanto o roteiro?
□ Formato JSON está correto?

🚨 SE VOCÊ USAR LINGUAGEM GENÉRICA, CAPITALIZAÇÃO ERRADA OU QUEBRAR A PERSPECTIVA, O CTA SERÁ REJEITADO! 🚨

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
      'final': 'CTA de fechamento'
    };
  }

  Map<String, String> _parseCtaResponse(String response, List<String> ctaTypes) {
    try {
      if (kDebugMode) debugPrint('🎯 CTA Response original: ${response.substring(0, response.length > 200 ? 200 : response.length)}...');
      
      // Remover markdown code blocks (```json ... ```)
      String cleanedResponse = response;
      cleanedResponse = cleanedResponse.replaceAll(RegExp(r'```json\s*'), '');
      cleanedResponse = cleanedResponse.replaceAll(RegExp(r'```\s*'), '');
      cleanedResponse = cleanedResponse.trim();
      
      if (kDebugMode) debugPrint('🎯 CTA Response limpa: ${cleanedResponse.substring(0, cleanedResponse.length > 200 ? 200 : cleanedResponse.length)}...');
      
      // Tentar extrair JSON da resposta
      final jsonStart = cleanedResponse.indexOf('{');
      final jsonEnd = cleanedResponse.lastIndexOf('}');
      
      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('Formato JSON não encontrado na resposta');
      }
      
      final jsonString = cleanedResponse.substring(jsonStart, jsonEnd + 1);
      if (kDebugMode) debugPrint('🎯 JSON extraído: ${jsonString.length} chars');
      
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
          ctas[type] = ctaText;
          if (kDebugMode) debugPrint('✅ CTA extraído [$type]: ${ctaText.substring(0, ctaText.length > 50 ? 50 : ctaText.length)}...');
        } else {
          if (kDebugMode) debugPrint('⚠️ CTA não encontrado para tipo: $type');
        }
      }
      
      if (kDebugMode) debugPrint('🎯 Total de CTAs extraídos: ${ctas.length}/${ctaTypes.length}');
      return ctas;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao fazer parse dos CTAs: $e');
        debugPrint('Stack trace: $stack');
      }
      return {};
    }
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
  // 📚 SISTEMA DE NOTAS: Histórico completo de cada personagem
  final Map<String, _CharacterHistory> _characterHistories = {};
  
  void addName(String name, {String? role, int? blockNumber}) {
    if (name.isEmpty || name.length <= 2) return;
    
    // 🔒 VALIDAÇÃO CRÍTICA: Bloquear reuso de nomes
    if (_confirmedNames.contains(name)) {
      if (kDebugMode) {
        final existingRole = _characterRoles[name] ?? 'desconhecido';
        debugPrint('❌ BLOQUEIO DE REUSO: "$name" já usado como "$existingRole"!');
        if (role != null && role != existingRole) {
          debugPrint('   ⚠️ Tentativa de reusar "$name" como "$role" → REJEITADO!');
        }
      }
      return; // Bloqueia adição
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
  
  // 🔥 NOVO: Obter mapeamento completo de personagens com histórico
  String getCharacterMapping() {
    if (_characterRoles.isEmpty && _characterHistories.isEmpty) return '';
    
    final buffer = StringBuffer('\n🎭 PERSONAGENS JÁ DEFINIDOS:\n');
    
    // Para cada personagem, mostrar histórico completo se disponível
    for (final name in _confirmedNames) {
      final history = _characterHistories[name];
      
      if (history != null && history.timeline.isNotEmpty) {
        // Mostrar histórico completo
        buffer.writeln('\n👤 $name:');
        buffer.writeln('   ${history.getFullHistory()}');
        buffer.writeln('   ⚠️ NUNCA mude este personagem! Use outro nome para novos personagens.');
      } else {
        // Mostrar apenas papel básico
        final role = _characterRoles[name] ?? 'personagem';
        buffer.writeln('   "$name" = $role');
      }
    }
    
    return buffer.toString();
  }
  
  void clear() {
    _confirmedNames.clear();
    _characterRoles.clear();
    _characterHistories.clear();
  }
}





