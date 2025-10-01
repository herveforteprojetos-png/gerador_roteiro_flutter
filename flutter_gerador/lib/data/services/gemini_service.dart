import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/script_result.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';
import 'package:flutter_gerador/data/models/localization_level.dart';

/// ImplementaÃ§Ã£o consolidada limpa do GeminiService
class GeminiService {
  final Dio _dio;
  final String _instanceId;
  bool _isCancelled = false;

  // Circuit breaker
  bool _isCircuitOpen = false;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  static const int _maxFailures = 5; // Aumentado de 3 para 5
  static const Duration _circuitResetTime = Duration(seconds: 30); // Reduzido de 2 min para 30s

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
  static const Duration _maxOperationTime = Duration(minutes: 15); // REDUZIDO: Era 25, agora 15 min

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
        final added = await _retryOnRateLimit(() => _generateBlockContent(acc, targetForBlock, phase, config, persistentTracker, block));
        acc += added;
        if (added.trim().isNotEmpty) {
          _updateTrackerFromContextSnippet(persistentTracker, config, added);
        }
        
        // INSERIR GANCHO + CTA APÃ“S A INTRODUÃ‡ÃƒO (aproximadamente 20% do conteÃºdo)
        if (config.includeCallToAction && block == 2 && totalBlocks >= 5) {
          // Gerar gancho de 4 linhas
          final hook = await _generateHook(acc, config);
          acc += '\n\n$hook\n\n';
          _updateTrackerFromContextSnippet(persistentTracker, config, hook);
          
          // Adicionar CTA depois do gancho
          final cta = _getCta(config.language);
          acc += '$cta\n\n';
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

      // Adicionar CTA Final se habilitado
      if (config.includeFinalCta) {
        final ctaFinal = _getCtaFinal(config.language);
        acc += '\n\n$ctaFinal';
      }

      _stopWatchdog();
      
      // 🧹 LIMPAR MARCADORES DE DEBUG DO TEXTO FINAL
      final cleanedAcc = acc.replaceAll(RegExp(r'PERSONAGEM MENCIONADO:\s*'), '');
      
      return ScriptResult(
        scriptText: cleanedAcc,
        wordCount: _countWords(cleanedAcc),
        charCount: cleanedAcc.length,
        paragraphCount: cleanedAcc.split('\n').length,
        readingTime: (_countWords(acc) / 150).ceil(),
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
    _stopWatchdog();
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
    // OTIMIZADO: Delays menores para clientes com Gemini Billing
    if(p <= 0.15) return 100;  // Era 200ms, agora 100ms 
    if(p <= 0.30) return 150;  // Era 300ms, agora 150ms
    if(p <= 0.65) return 200;  // Era 400ms, agora 200ms
    if(p <= 0.80) return 250;  // Era 500ms, agora 250ms
    if(p <= 0.95) return 150;  // Era 300ms, agora 150ms
    return 100; // Era 200ms, agora 100ms
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
    // ðŸ”¥ FIX: MUITO MAIS blocos para compensar IA gerando menos que o solicitado
    if(c.measureType == 'caracteres') { 
      if(c.quantity <= 5000) return 4;    // 1250 chars/bloco
      if(c.quantity <= 15000) return 7;   // 2142 chars/bloco
      if(c.quantity <= 30000) return 10;  // 3000 chars/bloco
      if(c.quantity <= 50000) return 12;  // 4166 chars/bloco
      if(c.quantity <= 80000) return 15;  // 5333 chars/bloco
      return 18; // Para textos enormes, atÃ© 18 blocos
    } else { 
      if(c.quantity <= 1000) return 4;    // 250 palavras/bloco
      if(c.quantity <= 3000) return 6;    // 500 palavras/bloco
      if(c.quantity <= 6000) return 10;   // 600 palavras/bloco
      if(c.quantity <= 10000) return 24;  // 555 palavras/bloco - ï¿½ OTIMIZADO: 8600 palavras = 18 blocos (era 14)
      if(c.quantity <= 15000) return 22;  // 681 palavras/bloco - Aumentado de 16 para 22
      if(c.quantity <= 20000) return 26;  // 769 palavras/bloco - Novo escalÃ£o
      if(c.quantity <= 25000) return 30;  // 833 palavras/bloco - Aumentado de 20 para 30
      return 36; // MÃ¡ximo 36 blocos para textos muito grandes (era 25)
    } 
  }
  
  int _calculateTargetForBlock(int current, int total, ScriptConfig c) {
    // ï¿½ GEMINI 2.5 PRO: Com 32.768 tokens disponÃ­veis, voltamos ao 2.0x!
    // IA gera ~60% do solicitado, entÃ£o 2.0x compensa perfeitamente
    final baseTarget = (c.quantity * (current / total) * 3.5).round(); // AUMENTADO: 2.0x â†’ 3.5x
    
    // LIMITES AUMENTADOS DRASTICAMENTE para garantir espaÃ§o
    final maxBlockSize = c.measureType == 'caracteres' ? 25000 : 6000; // AUMENTADO: 18000â†’25000, 4000â†’6000
    
    // Para o Ãºltimo bloco, usar o mesmo multiplicador para consistÃªncia
    if (current == total) {
      return (c.quantity * 3.5).round(); // AUMENTADO: 2.0x â†’ 3.5x
    }
    
    return baseTarget > maxBlockSize ? maxBlockSize : baseTarget;
  }

  // ===================== GeraÃ§Ã£o de Blocos =====================
  String _getCta(String l) { 
    switch(l.toLowerCase()) { 
      case 'portuguÃªs': 
        return 'Antes de continuar, nÃ£o esqueÃ§a de curtir este Ã¡udio e se inscrever no canal clicando no Ã­cone que aparece no canto inferior direito da sua tela! E me conta nos comentÃ¡rios: de onde vocÃª estÃ¡ nos ouvindo? Eu adoro saber com quem estou compartilhando este momento. Agora, vamos com a histÃ³ria.'; 
      case 'inglÃªs': 
        return 'Before we continue, don\'t forget to like this audio and subscribe to the channel by clicking the icon that appears in the bottom right corner of your screen! And tell me in the comments: where are you listening from? I love knowing who I\'m sharing this moment with. Now, let\'s get to the story.'; 
      case 'espanhol(mexicano)': 
        return 'Â¡Antes de continuar, no olvides dar like a este audio y suscribirte al canal haciendo clic en el Ã­cono que aparece en la esquina inferior derecha de tu pantalla! Y cuÃ©ntame en los comentarios: Â¿desde dÃ³nde nos estÃ¡s oyendo? Me encanta saber con quiÃ©n estoy compartiendo este momento. Ahora, vamos con el cuento.'; 
      case 'francÃªs': 
        return 'Avant de continuer, n\'oubliez pas d\'aimer cet audio et de vous abonner Ã  la chaÃ®ne en cliquant sur l\'icÃ´ne qui apparaÃ®t dans le coin infÃ©rieur droit de votre Ã©cran ! Et dites-moi dans les commentaires : d\'oÃ¹ nous Ã©coutez-vous ? J\'adore savoir avec qui je partage ce moment. Maintenant, passons Ã  l\'histoire.'; 
      case 'alemÃ£o': 
        return 'Bevor wir fortfahren, vergessen Sie nicht, dieses Audio zu liken und den Kanal zu abonnieren, indem Sie auf das Symbol klicken, das in der unteren rechten Ecke Ihres Bildschirms erscheint! Und sagen Sie mir in den Kommentaren: Von wo hÃ¶ren Sie uns zu? Ich liebe es zu wissen, mit wem ich diesen Moment teile. Jetzt zur Geschichte.'; 
      case 'italiano': 
        return 'Prima di continuare, non dimenticare di mettere like a questo audio e iscriverti al canale cliccando sull\'icona che appare nell\'angolo in basso a destra del tuo schermo! E dimmi nei commenti: da dove ci stai ascoltando? Adoro sapere con chi sto condividendo questo momento. Ora, andiamo con la storia.'; 
      case 'polonÃªs': 
        return 'Zanim przejdziemy dalej, nie zapomnij polubiÄ‡ tego nagrania i zasubskrybowaÄ‡ kanaÅ‚, klikajÄ…c ikonÄ™, ktÃ³ra pojawia siÄ™ w prawym dolnym rogu ekranu! I powiedz mi w komentarzach: skÄ…d nas sÅ‚uchasz? Uwielbiam wiedzieÄ‡, z kim dzielÄ™ tÄ™ chwilÄ™. Teraz przejdÅºmy do historii.'; 
      case 'bÃºlgaro': 
        return 'ÐŸÑ€ÐµÐ´Ð¸ Ð´Ð° Ð¿Ñ€Ð¾Ð´ÑŠÐ»Ð¶Ð¸Ð¼, Ð½Ðµ Ð·Ð°Ð±Ñ€Ð°Ð²ÑÐ¹Ñ‚Ðµ Ð´Ð° Ñ…Ð°Ñ€ÐµÑÐ°Ñ‚Ðµ Ñ‚Ð¾Ð²Ð° Ð°ÑƒÐ´Ð¸Ð¾ Ð¸ Ð´Ð° ÑÐµ Ð°Ð±Ð¾Ð½Ð¸Ñ€Ð°Ñ‚Ðµ Ð·Ð° ÐºÐ°Ð½Ð°Ð»Ð°, ÐºÐ°Ñ‚Ð¾ Ñ‰Ñ€Ð°ÐºÐ½ÐµÑ‚Ðµ Ð²ÑŠÑ€Ñ…Ñƒ Ð¸ÐºÐ¾Ð½Ð°Ñ‚Ð°, ÐºÐ¾ÑÑ‚Ð¾ ÑÐµ Ð¿Ð¾ÑÐ²ÑÐ²Ð° Ð² Ð´Ð¾Ð»Ð½Ð¸Ñ Ð´ÐµÑÐµÐ½ ÑŠÐ³ÑŠÐ» Ð½Ð° ÐµÐºÑ€Ð°Ð½Ð° Ð²Ð¸! Ð˜ Ð¼Ð¸ ÐºÐ°Ð¶ÐµÑ‚Ðµ Ð² ÐºÐ¾Ð¼ÐµÐ½Ñ‚Ð°Ñ€Ð¸Ñ‚Ðµ: Ð¾Ñ‚ÐºÑŠÐ´Ðµ Ð½Ð¸ ÑÐ»ÑƒÑˆÐ°Ñ‚Ðµ? ÐžÐ±Ð¾Ð¶Ð°Ð²Ð°Ð¼ Ð´Ð° Ð·Ð½Ð°Ð¼ Ñ ÐºÐ¾Ð³Ð¾ ÑÐ¿Ð¾Ð´ÐµÐ»ÑÐ¼ Ñ‚Ð¾Ð·Ð¸ Ð¼Ð¾Ð¼ÐµÐ½Ñ‚. Ð¡ÐµÐ³Ð° Ð½ÐµÐºÐ° Ð¿Ñ€ÐµÐ¼Ð¸Ð½ÐµÐ¼ ÐºÑŠÐ¼ Ð¸ÑÑ‚Ð¾Ñ€Ð¸ÑÑ‚Ð°.'; 
      case 'croata': 
        return 'Prije nego Å¡to nastavimo, ne zaboravite lajkati ovaj audio i pretplatiti se na kanal klikom na ikonu koja se pojavljuje u donjem desnom uglu vaÅ¡eg ekrana! I recite mi u komentarima: odakle nas sluÅ¡ate? Volim da znam s kim dijeljim ovaj trenutak. Sada, idemo na priÄu.'; 
      case 'turco': 
        return 'Devam etmeden Ã¶nce, bu sesi beÄŸenmeyi ve ekranÄ±nÄ±zÄ±n saÄŸ alt kÃ¶ÅŸesinde gÃ¶rÃ¼nen simgeye tÄ±klayarak kanala abone olmayÄ± unutmayÄ±n! Ve yorumlarda bana sÃ¶yleyin: bizi nereden dinliyorsunuz? Bu anÄ± kiminle paylaÅŸtÄ±ÄŸÄ±mÄ± bilmeyi seviyorum. Åžimdi, hikayeye geÃ§elim.'; 
      case 'romeno': 
        return 'ÃŽnainte de a continua, nu uitaÈ›i sÄƒ daÈ›i like acestui audio È™i sÄƒ vÄƒ abonaÈ›i la canal fÄƒcÃ¢nd clic pe iconiÈ›a care apare Ã®n colÈ›ul din dreapta jos al ecranului! È˜i spuneÈ›i-mi Ã®n comentarii: de unde ne ascultaÈ›i? ÃŽmi place sÄƒ È™tiu cu cine Ã®mpart acest moment. Acum, sÄƒ trecem la poveste.'; 
      default: 
        return 'Before we continue, don\'t forget to like this audio and subscribe to the channel by clicking the icon that appears in the bottom right corner of your screen! And tell me in the comments: where are you listening from? I love knowing who I\'m sharing this moment with. Now, let\'s get to the story.'; 
    } 
  }

  // ===================== CTA Final =====================
  String _getCtaFinal(String l) { 
    switch(l.toLowerCase()) { 
      case 'portuguÃªs': 
        return 'E aÃ­, o que achou? Se curtiu a histÃ³ria, deixa o like e se inscreve no canal! Nos vemos no prÃ³ximo episÃ³dio!'; 
      case 'inglÃªs': 
        return 'So, what did you think? If you enjoyed the story, hit that like button and subscribe to the channel! See you in the next episode!'; 
      case 'espanhol(mexicano)': 
        return 'Â¿Y bien, quÃ© te pareciÃ³? Si te gustÃ³ la historia, Â¡dale like y suscrÃ­bete al canal! Â¡Nos vemos en el prÃ³ximo episodio!'; 
      case 'francÃªs': 
        return 'Alors, qu\'est-ce que vous en avez pensÃ© ? Si vous avez aimÃ© l\'histoire, mettez un like et abonnez-vous Ã  la chaÃ®ne ! On se retrouve dans le prochain Ã©pisode !'; 
      case 'alemÃ£o': 
        return 'Na, was denkst du? Wenn dir die Geschichte gefallen hat, gib einen Like und abonniere den Kanal! Wir sehen uns in der nÃ¤chsten Folge!'; 
      case 'italiano': 
        return 'Allora, che ne pensi? Se ti Ã¨ piaciuta la storia, metti like e iscriviti al canale! Ci vediamo nel prossimo episodio!'; 
      case 'polonÃªs': 
        return 'No i jak ci siÄ™ podobaÅ‚o? JeÅ›li historia ci siÄ™ spodobaÅ‚a, zostaw like i subskrybuj kanaÅ‚! Do zobaczenia w nastÄ™pnym odcinku!'; 
      case 'bÃºlgaro': 
        return 'Ð•, ÐºÐ°ÐºÐ²Ð¾ Ð¼Ð¸ÑÐ»Ð¸Ñˆ? ÐÐºÐ¾ Ñ‚Ð¸ Ñ…Ð°Ñ€ÐµÑÐ° Ð¸ÑÑ‚Ð¾Ñ€Ð¸ÑÑ‚Ð°, Ð¾ÑÑ‚Ð°Ð²Ð¸ like Ð¸ ÑÐµ Ð°Ð±Ð¾Ð½Ð¸Ñ€Ð°Ð¹ Ð·Ð° ÐºÐ°Ð½Ð°Ð»Ð°! Ð”Ð¾ ÑÐºÐ¾Ñ€Ð¾ Ð² ÑÐ»ÐµÐ´Ð²Ð°Ñ‰Ð¸Ñ ÐµÐ¿Ð¸Ð·Ð¾Ð´!'; 
      case 'croata': 
        return 'Pa, Å¡to misliÅ¡? Ako ti se svidjela priÄa, stavi like i pretplati se na kanal! Vidimo se u sljedeÄ‡oj epizodi!'; 
      case 'turco': 
        return 'Peki, ne dÃ¼ÅŸÃ¼nÃ¼yorsun? Hikayeyi beÄŸendiysen, beÄŸen ve kanala abone ol! Bir sonraki bÃ¶lÃ¼mde gÃ¶rÃ¼ÅŸÃ¼rÃ¼z!'; 
      case 'romeno': 
        return 'Ei bine, ce pÄƒrere ai? DacÄƒ È›i-a plÄƒcut povestea, dÄƒ like È™i aboneazÄƒ-te la canal! Ne vedem Ã®n urmÄƒtorul episod!'; 
      default: 
        return 'So, what did you think? If you enjoyed the story, hit that like button and subscribe to the channel! See you in the next episode!'; 
    } 
  }

  // ===================== GeraÃ§Ã£o de Gancho =====================
  Future<String> _generateHook(String storyContent, ScriptConfig config) async {
    final localizationGuidance = _buildLocalizationGuidance(config);
    final hookPrompt = '''
Com base no seguinte conteÃºdo da histÃ³ria, crie uma introduÃ§Ã£o de EXATAMENTE 4 linhas que captura os elementos mais intrigantes da narrativa DE MODO QUE O OUVINTE FIQUE BASTANTE CURIOSO EM CONTINUAR ESCUTANDO.

A introduÃ§Ã£o deve:
- Capturar os elementos mais dramÃ¡ticos e intrigantes
- Criar suspense e curiosidade
- Terminar com uma pergunta direta ao ouvinte
- Criar um gancho psicolÃ³gico que desperta curiosidade e envolve emocionalmente
- USAR LINGUAGEM SIMPLES E COTIDIANA: Evite palavras difÃ­ceis, termos rebuscados ou vocabulÃ¡rio erudito. Use palavras que qualquer pessoa entende no dia a dia.
$localizationGuidance

CONTEÃšDO DA HISTÃ“RIA:
${storyContent.length > 500 ? '${storyContent.substring(0, 500)}...' : storyContent}

ðŸ”¤ REGRAS DE CAPITALIZAÃ‡ÃƒO:
- MaiÃºsculas APENAS em: nomes prÃ³prios, inÃ­cio de frases
- NUNCA capitalize substantivos comuns: marido, filho, avÃ³, pai, mÃ£e
- NUNCA capitalize: apenas, nÃ³s, ele, ela
- Conjugue corretamente: "eu vi" (NÃƒO "eu viu")

IMPORTANTE: 
- Responda APENAS as 4 linhas do gancho
- Termine com uma pergunta direcionada ao ouvinte
- Use linguagem envolvente, curiosa E SIMPLES
- Mantenha o tom alinhado com: ${config.tema} - ${config.subtema}
- SEMPRE use palavras fáceis de entender
''';

    try {
      final response = await generateTextWithApiKey(
        prompt: hookPrompt,
        apiKey: config.apiKey,
        model: config.model,
      );
      return response.trim();
    } catch (e) {
      debugPrint('Erro ao gerar gancho: $e');
      return 'Uma história que vai mudar tudo o que você pensa sobre ${config.tema.toLowerCase()}. Segredos serão revelados, verdades ocultas virão à tona. Você está preparado para descobrir o que realmente aconteceu? Fique comigo até o final desta narrativa.';
    }
  }
  
  String _getLanguageInstruction(String l) { 
    switch(l.toLowerCase()) { 
      case 'português': 
        return 'Português brasileiro natural e simples - use palavras que qualquer pessoa entende no dia a dia, evite vocabulário rebuscado ou erudito'; 
      case 'inglês': 
        return 'Simple, natural English - use everyday words that anyone can understand, avoid complex vocabulary'; 
      case 'espanhol(mexicano)': 
        return 'Español mexicano natural y sencillo - usa palabras cotidianas que cualquiera entiende, evita vocabulario rebuscado'; 
      case 'francês': 
        return 'Français naturel et simple - utilisez des mots quotidiens que tout le monde comprend, évitez le vocabulaire complexe'; 
      case 'alemão': 
        return 'Natürliches, einfaches Deutsch - verwenden Sie alltägliche Wörter, die jeder versteht, vermeiden Sie komplexes Vokabular'; 
      case 'italiano': 
        return 'Italiano naturale e semplice - usa parole quotidiane che tutti capiscono, evita vocabolario complesso'; 
      case 'polonês': 
        return 'Naturalny, prosty polski - używaj codziennych słów, które każdy rozumie, unikaj skomplikowanego słownictwa'; 
      case 'búlgaro': 
        return 'Естествен, прост български - използвайте ежедневни думи, които всеки разбира, избягвайте сложна лексика'; 
      case 'croata': 
        return 'Prirodni, jednostavan hrvatski - koristite svakodnevne riječi koje svatko razumije, izbjegavajte složen vokabular'; 
      case 'turco': 
        return 'Doğal, basit Türkçe - herkesin anlayabileceği günlük kelimeler kullanın, karmaşık kelime dağarcığından kaçının'; 
      case 'romeno': 
        return 'Română naturală și simplă - folosiți cuvinte de zi cu zi pe care oricine le înțelege, evitați vocabularul complicat'; 
      default: 
        return 'Português brasileiro natural e simples - use palavras que qualquer pessoa entende no dia a dia'; 
    } 
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
    if (config.protagonistName.trim().isNotEmpty) {
      names.add(config.protagonistName.trim());
    }
    if (config.secondaryCharacterName.trim().isNotEmpty) {
      names.add(config.secondaryCharacterName.trim());
    }
    names.addAll(_extractCharacterNamesFromContext(config.context));
    
    // 🎯 NOVO: Extrair gênero e relações de personagens do título
    names.addAll(_extractCharacterHintsFromTitle(config.title, config.context));

    for (final name in names) {
      tracker.addName(name);
    }

    if (kDebugMode && tracker.confirmedNames.isNotEmpty) {
      debugPrint('🔐 Tracker inicial: ${tracker.confirmedNames.join(", ")}');
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

      tracker.addName(name);
      if (kDebugMode) {
        debugPrint('🔍 Tracker adicionou personagem detectado: $name (ocorrências: $count)');
      }
    });
  }

  String _buildCharacterGuidance(ScriptConfig config, _CharacterTracker tracker) {
    final lines = <String>[];
    final baseNames = <String>{};

    final protagonist = config.protagonistName.trim();
    if (protagonist.isNotEmpty) {
      lines.add('- Protagonista: "$protagonist" — mantenha exatamente este nome e sua função.');
      baseNames.add(protagonist.toLowerCase());
    }

    final secondary = config.secondaryCharacterName.trim();
    if (secondary.isNotEmpty) {
      lines.add('- Personagem secundário: "$secondary" — preserve o mesmo nome em todos os blocos.');
      baseNames.add(secondary.toLowerCase());
    }

    final additional = tracker.confirmedNames
        .where((n) => !baseNames.contains(n.toLowerCase()))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    for (final name in additional) {
      // 🎯 CORRIGIDO: Adicionar personagens mencionados (não são hints de narrador)
      if (name.startsWith('PERSONAGEM MENCIONADO')) {
        // Remover marcador antes de adicionar ao prompt
        final cleanName = name.replaceFirst('PERSONAGEM MENCIONADO: ', '');
        lines.add('- Personagem mencionado: $cleanName (manter como referência familiar)');
      } else {
        lines.add('- Personagem estabelecido: "$name" — não altere este nome nem invente apelidos.');
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

  bool _looksLikePersonName(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return false;

    // 🚫 Filtrar stopwords (palavras comuns que não são nomes)
    if (_nameStopwords.contains(cleaned.toLowerCase())) return false;

    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length > 3) return false; // Nomes raramente têm mais de 3 partes

    // 🚫 REGRA ADICIONAL: Palavras isoladas muito curtas provavelmente não são nomes
    if (parts.length == 1 && cleaned.length < 4) {
      // Exceção: alguns nomes curtos são válidos (Ana, Lia, Eva, etc)
      final validShortNames = {'ana', 'lia', 'eva', 'leo', 'rui', 'noa', 'ian', 'ivo', 'ada'};
      if (!validShortNames.contains(cleaned.toLowerCase())) {
        return false;
      }
    }

    // Verificar cada parte do nome
    for (final part in parts) {
      // 🚫 Rejeitar se alguma parte está na lista de stopwords
      if (_nameStopwords.contains(part.toLowerCase())) return false;
      
      final sanitized = part.replaceAll(RegExp(r'[^A-Za-zÁ-ú-]'), '');
      if (sanitized.length < 2) return false; // Nome muito curto
      if (!RegExp(r'^[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ]').hasMatch(sanitized)) return false; // Deve começar com maiúscula
      if (!RegExp(r'^[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+(-[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)?$').hasMatch(sanitized)) {
        return false; // Formato inválido
      }
    }

    return true;
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
    
    // Substantivos comuns que podem ser capitalizados
    'filho', 'filha', 'filhos', 'pai', 'mae', 'pais', 'irmao', 'irma', 'tio', 'tia',
    'avo', 'neto', 'neta', 'marido', 'esposa', 'noivo', 'noiva',
    'amigo', 'amiga', 'primo', 'prima', 'sobrinho', 'sobrinha',
    'senhor', 'senhora', 'doutor', 'doutora', 'cliente', 'pessoa', 'pessoas', 'gente',
    'familia', 'casa', 'mundo', 'vida', 'tempo', 'dia', 'noite', 'momento',
    
    // Advérbios/conjunções comuns no início de frase
    'entao', 'depois', 'antes', 'agora', 'hoje', 'ontem', 'amanha', 'sempre', 'nunca',
    'talvez', 'porem', 'contudo', 'entretanto', 'portanto', 'enquanto', 'quando', 'onde',
    'havia', 'houve', 'tinha', 'foram', 'eram', 'estava', 'estavam',
    
    // Preposições e artigos (raramente, mas podem aparecer)
    'com', 'sem', 'sobre', 'para', 'pela', 'pelo', 'uma', 'umas', 'uns', 'por',
    
    // Verbos comuns no início de frase (conjugados em vários tempos)
    'era', 'foram', 'foi', 'seria', 'pode', 'podia', 'deve', 'devia',
    'senti', 'sentiu', 'pensei', 'pensou', 'vi', 'viu', 'ouvi', 'ouviu',
    'fiz', 'fez', 'disse', 'falou', 'quis', 'quiz', 'pude', 'pôde',
    'tive', 'teve', 'sabia', 'soube', 'imaginei', 'imaginou', 'acreditei', 'acreditou',
    'percebi', 'percebeu', 'notei', 'notou', 'lembrei', 'lembrou',
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
    
    // Separar em blocos (parágrafos duplos ou mais)
    final blocks = fullContext.split(RegExp(r'\n{2,}'));
    if (blocks.length <= maxRecentBlocks + 5) {
      return fullContext; // Ainda não tem muitos blocos
    }
    
    // Pegar resumo inicial (primeiros 3-5 parágrafos)
    final initialSummary = blocks.take(5).join('\n\n');
    
    // Pegar últimos N blocos completos
    final recentBlocks = blocks.skip(max(0, blocks.length - maxRecentBlocks * 5)).join('\n\n');
    
    return '$initialSummary\n\n[...]\n\n$recentBlocks';
  }

  Future<String> _generateBlockContent(
    String previous, 
    int target, 
    String phase, 
    ScriptConfig c,
    _CharacterTracker tracker,
    int blockNumber,
  ) async {
    final needed = c.measureType == 'caracteres' ? target - previous.length : target - _countWords(previous);
    if (needed <= 0) return '';
    
    // � OTIMIZAÇÃO: Limitar contexto aos últimos 3 blocos para evitar timeouts
    // Blocos iniciais (1-4): contexto completo
    // Blocos médios/finais (5+): últimos 3 blocos + resumo inicial
    String contextoPrevio = previous.isEmpty ? '' : _buildLimitedContext(previous, blockNumber, 3);
    
    if (kDebugMode && previous.isNotEmpty) {
      final contextUsed = contextoPrevio.length;
      final contextType = blockNumber <= 4 ? 'COMPLETO' : 'LIMITADO (últimos 3 blocos)';
      debugPrint('📚 CONTEXTO $contextType: $contextUsed chars (${_countWords(contextoPrevio)} palavras)');
      if (blockNumber > 4) {
        debugPrint('   Original: ${previous.length} chars → Reduzido: $contextUsed chars (${((1 - contextUsed / previous.length) * 100).toStringAsFixed(0)}% menor)');
      }
    }
    
    // 🔥 SOLUÇÃO 3: Reforçar os nomes confirmados no prompt para manter consistência
    String trackerInfo = '';
    if (tracker.confirmedNames.isNotEmpty) {
      trackerInfo = '\n⚠️ MANTENHA estes nomes exatamente como definidos: ${tracker.confirmedNames.join(", ")}\n';
      if (kDebugMode) {
        debugPrint('🔥 Bloco $blockNumber - Nomes no tracker: ${tracker.confirmedNames.join(", ")}');
      }
    }
    final characterGuidance = _buildCharacterGuidance(c, tracker);
    
    // Limitar target para manter estabilidade mas permitir qualidade
    final limitedNeeded = min(needed, c.measureType == 'caracteres' ? 15000 : 3500); // AUMENTADO: Era 6000/1000, agora 15000/3500
  final measure = c.measureType == 'caracteres' ? 'GERE EXATAMENTE $limitedNeeded caracteres' : 'GERE EXATAMENTE $limitedNeeded palavras';
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
        instruction = 'Comece uma nova história usando EXATAMENTE esta frase como gancho de abertura: "${c.title}". Esta frase deve iniciar o primeiro parágrafo de forma natural e envolvente, como se fosse parte da narrativa';
      } else {
        instruction = 'Comece uma nova história';
      }
    } else {
      instruction = 'Continue a história';
    }
    
    // Prompt otimizado para ROTEIRO DE NARRAÇÃO limpo e com target específico
    final prompt = '${contextoPrevio.isNotEmpty ? 'CONTEXTO:\n$contextoPrevio\n\n' : ''}'
  '$trackerInfo'
  '${characterGuidance.isEmpty ? '' : characterGuidance}'
        '$instruction${previous.isEmpty && !c.startWithTitlePhrase ? ' sobre "${c.title}"' : ''}.\n'
        'TEMA: ${c.tema}\n'
        'SUBTEMA: ${c.subtema}\n'
    '${c.localizacao.trim().isEmpty ? 'LOCALIZAÇÃO: Não especificada' : 'LOCALIZAÇÃO: ${c.localizacao}'}\n'
        'CONTEXTO ADICIONAL: ${c.context}\n'
    '$localizationGuidance'
        '⚠️ OBRIGATÓRIO: $measure - ESTE É UM REQUISITO ABSOLUTO!\n'
        'FORMATO: ROTEIRO PARA NARRAÇÃO DE VÍDEO - apenas texto corrido para ser lido em voz alta.\n'
        'PROIBIDO: Emojis, símbolos, formatação markdown, títulos, bullets, calls-to-action, hashtags, elementos visuais.\n'
        'OBRIGATÓRIO: Texto limpo, narrativo, fluido, pronto para narração direta.\n'
    'REGRAS DE CONSISTÊNCIA:\n'
    '- Continue exatamente do ponto onde o CONTEXTO parou; não reinicie a história.\n'
    '- Não repita parágrafos, cenas, diálogos ou cartas já escritos anteriormente.\n'
    '- Preserve nomes e relações dos personagens confirmados sem apelidos ou variações.\n\n'
    '⭐ NOMES DE PERSONAGENS SECUNDÁRIOS:\n'
    '- Se precisar criar personagens secundários (advogados, médicos, funcionários, vizinhos, etc), DÊ A ELES NOMES PRÓPRIOS REALISTAS.\n'
    '- EXEMPLOS CORRETOS: "Dr. Paulo, nosso contador", "senhor Magalhães, meu advogado", "Túlia, minha governanta", "Nonato, meu motorista", "Sérgio, o diretor".\n'
    '- NUNCA use palavras comuns como nomes: "Por, nosso contador", "Imaginei, advogado", "Tudo, governanta", "Não, motorista", "Senti, diretor".\n'
    '- Use nomes brasileiros comuns e realistas para todos os personagens com função definida na história.\n\n'
        '${_getPerspectiveInstruction(c.perspective, c)}\n\n'
        '⚠️ LINGUAGEM ACESSÍVEL (OBRIGATÓRIO):\n'
        'Use APENAS vocabulário SIMPLES, nível ensino fundamental. O público-alvo são pessoas comuns que assistem YouTube.\n'
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
        '\n'
        '✅ REGRAS DE SIMPLICIDADE:\n'
        '1. FRASES CURTAS: Máximo 25-30 palavras por frase\n'
        '2. VOCABULÁRIO: Apenas palavras que você usaria conversando com um amigo\n'
        '3. VERBOS SIMPLES: Prefira presente/passado simples, evite futuro do pretérito\n'
        '4. SEM TERMOS TÉCNICOS: "advogado" OK, "obstrução da justiça" NÃO\n'
        '5. TESTE MENTAL: "Uma pessoa que só vê YouTube entenderia esta palavra?"\n'
        '\n'
        '📝 EXEMPLOS DE SIMPLIFICAÇÃO:\n'
        '❌ "A confissão foi proferida com uma solenidade que beirava o absurdo"\n'
        '✅ "Ele confessou de um jeito quase ridículo de tão sério"\n'
        '\n'
        '❌ "Ela sibilou uma resposta embargada pela emoção"\n'
        '✅ "Ela sussurrou com raiva, a voz tremendo de emoção"\n'
        '\n'
        'Idioma: ${_getLanguageInstruction(c.language)}\n\n'
        '⭐ IMPORTANTE: Desenvolva a narrativa com riqueza de detalhes, diálogos, descrições e desenvolvimento de personagens para atingir EXATAMENTE o número de ${c.measureType} solicitado. SEMPRE use frases curtas, palavras simples e linguagem de conversa natural.';
        
    if (kDebugMode) debugPrint('[$_instanceId] Gerando bloco balanceado: $limitedNeeded ${c.measureType}');
    
    try {
      // 🚀 GEMINI 2.5 PRO: Suporta até 65.535 tokens de saída!
      // Usando 32.768 (50%) para ter margem de segurança
      final maxTokensCalculated = c.measureType == 'caracteres' ? (needed * 2.0).ceil() : (needed * 10).ceil();
      final maxTokensLimit = 32768; // Gemini 2.5 Pro permite até 65.535 tokens de saída
      final finalMaxTokens = maxTokensCalculated > maxTokensLimit ? maxTokensLimit : maxTokensCalculated;
      
      final data = await _makeApiRequest(
        apiKey: c.apiKey,
        model: c.model,
        prompt: prompt,
        maxTokens: finalMaxTokens,
      );
  final text = data ?? '';
  final filtered = text.isNotEmpty ? _filterDuplicateParagraphs(previous, text) : '';
  return filtered.isNotEmpty ? '\n$filtered' : '';
    } catch (_) { 
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
    final prompt = 'Continue a narrativa de forma natural e fluida:\n\n$contextoExpansao\n\n'
  '$trackerInfo'
  '${characterGuidance.isEmpty ? '' : characterGuidance}'
        '$measure\n'
        'TEMA: ${c.tema}\n'
        'SUBTEMA: ${c.subtema}\n'
    '${c.localizacao.trim().isEmpty ? 'LOCALIZAÇÃO: Não especificada' : 'LOCALIZAÇÃO: ${c.localizacao}'}\n'
    '$localizationGuidance'
        '⚠️ IMPORTANTE: Continue a história mantendo exatamente os mesmos nomes e relações dos personagens confirmados. Novos personagens só se forem indispensáveis, mas nunca renomeie os já existentes.\n'
        '⭐ NOMES DE PERSONAGENS: Se criar novos personagens secundários, use NOMES PRÓPRIOS REALISTAS (Paulo, Magalhães, Túlia, etc), NUNCA palavras comuns (Por, Imaginei, Tudo, Não, Senti).\n'
        '\n'
        '⚠️ LINGUAGEM ACESSÍVEL (OBRIGATÓRIO):\n'
        '- Use APENAS palavras SIMPLES que pessoas comuns conhecem\n'
        '- Frases CURTAS: máximo 25-30 palavras por frase\n'
        '- EVITE: palavras difíceis, termos técnicos, futuro do pretérito\n'
        '- PREFIRA: presente simples, passado simples, palavras do dia a dia\n'
        '- Exemplos de substituição: "embargada"→"trêmula", "filantropo"→"pessoa que ajuda", "pária"→"rejeitado"\n'
        '- Teste: "Alguém que só vê YouTube entenderia essa palavra?" Se não, troque por uma mais simples.\n'
        '\n'
        'Mantenha a consistência com o tema, subtema e localização estabelecidos.\n'
        'REGRAS DE CONSISTÊNCIA:\n'
        '- Não repita parágrafos, cenas, diálogos ou cartas já presentes no texto original.\n'
        '- Nunca reinicie a história; avance a partir do ponto atual.\n'
        'Idioma: ${_getLanguageInstruction(c.language)}\n\n'
        'Continue escrevendo sem usar títulos, marcadores ou palavras como "CONTINUAÇÃO". Apenas prossiga com a história de forma natural usando frases curtas e palavras simples.';
    
    try {
      final data = await _makeApiRequest(
        apiKey: c.apiKey,
        model: c.model,
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
  }) async {
    try {
      // Detectar idioma do roteiro
      final detectedLanguage = await _detectScriptLanguage(scriptContent, apiKey);
      final finalLanguage = detectedLanguage.isNotEmpty ? detectedLanguage : 'Português';
      
      // Analisar contexto da história
      final scriptContext = await _analyzeScriptContext(scriptContent, apiKey, finalLanguage);
      
      // Gerar CTAs contextualizados
      final prompt = _buildAdvancedCtaPrompt(scriptContent, ctaTypes, customTheme, finalLanguage, scriptContext);
      
      final result = await generateTextWithApiKey(
        prompt: prompt,
        apiKey: apiKey,
        model: 'gemini-2.0-flash-exp',
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
        model: 'gemini-2.0-flash-exp',
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
        model: 'gemini-2.0-flash-exp',
        maxTokens: 100,
      );
      return result.trim();
    } catch (e) {
      return '';
    }
  }

  String _buildAdvancedCtaPrompt(String scriptContent, List<String> ctaTypes, 
                                 String? customTheme, String language, String scriptContext) {
    final ctaDescriptions = _getCtaTypeDescriptions(language);
    final requestedTypes = ctaTypes.map((type) => 
        '"$type": ${ctaDescriptions[type] ?? "Call-to-action personalizado"}').join('\n');

    // Detectar perspectiva narrativa do roteiro
    final isPrimeirapessoa = scriptContent.contains(RegExp(r'\b(eu|me|meu|minha|comigo)\b', caseSensitive: false));
    final perspectiveInstruction = isPrimeirapessoa 
        ? '''
PERSPECTIVA NARRATIVA: PRIMEIRA PESSOA
- O narrador é um personagem da história que conta em primeira pessoa
- CTAs devem manter essa perspectiva: use "EU", "MINHA história", "MEU relato"
- Exemplo CORRETO: "Se minha história te tocou, inscreva-se para não perder os próximos capítulos"
- Exemplo CORRETO: "O que você achou da minha decisão? Deixe seu comentário"
- Exemplo ERRADO: "O que você achou do personagem?" (quebra a perspectiva narrativa)
''' 
        : '''
PERSPECTIVA NARRATIVA: TERCEIRA PESSOA
- O narrador é observador externo que conta a história
- CTAs podem usar referência aos personagens de forma externa
- Exemplo: "O que você achou da atitude do Alexandre?"
''';

    return '''
Gere CTAs (calls-to-action) personalizados em $language para este roteiro.

CONTEXTO DO ROTEIRO: $scriptContext
TEMA PERSONALIZADO: ${customTheme ?? 'Não especificado'}

$perspectiveInstruction

ROTEIRO (trecho inicial):
${scriptContent.substring(0, scriptContent.length > 2000 ? 2000 : scriptContent.length)}

GERE OS SEGUINTES TIPOS DE CTA:
$requestedTypes

FORMATO DE RESPOSTA (JSON):
{
  "subscription": "texto do CTA aqui",
  "engagement": "texto do CTA aqui",
  "pre_conclusion": "texto do CTA aqui",
  "final": "texto do CTA aqui"
}

REQUISITOS OBRIGATÓRIOS:
- Cada CTA deve ter 20-40 palavras
- Linguagem natural e persuasiva
- Adequado ao contexto do roteiro
- Em $language nativo
- ⚠️ MANTENHA A MESMA PERSPECTIVA NARRATIVA DO ROTEIRO (primeira ou terceira pessoa)
- Se o roteiro usa "EU", o CTA deve usar "MINHA história", "MEU relato"
- ⚠️ MANTENHA O MESMO TOM EMOCIONAL DO ROTEIRO:
  * Se o roteiro é elegante/estratégico, CTAs devem ser sofisticados, NÃO sensacionalistas
  * Se o roteiro é dramático/intenso, CTAs podem ser mais emocionais
  * Se o roteiro é humorístico/leve, CTAs devem ser descontraídos
  * EVITE tom de clickbait sensacionalista ("explosivo", "chocante") se o roteiro é sutil
  * EVITE fazer CTAs parecerem mais agressivos/vingativos do que o roteiro realmente é
- ⚠️ CTAs devem REFLETIR a jornada emocional da história, não distorcê-la
- ⚠️ PROTAGONISMO vs. VITIMIZAÇÃO:
  * Se protagonista é FORTE/EMPODERADO, CTAs devem reforçar FORÇA ("minha estratégia", "minha jornada")
  * EVITE tom vitimista ("minha dor", "meu sofrimento") quando roteiro é de superação
  * EVITE "choramingar" quando personagem é estratégico/inteligente
  * Protagonista = ATIVO. Vítima = PASSIVO. Mantenha protagonismo!
- ⚠️ DESFECHO DO CTA = DESFECHO DA HISTÓRIA:
  * Se história termina em PAZ/RECONSTRUÇÃO, CTA deve ser INSPIRADOR, não punitivo
  * Se história termina em VINGANÇA, CTA pode ser mais assertivo
  * NUNCA use tom de "alerta/punição" quando história termina em reconciliação
  * CTA Final deve REFLETIR o estado emocional do FIM da história, não do meio
- Se o roteiro terminou, NÃO prometa eventos futuros que já aconteceram
- Formato JSON válido apenas
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
class _CharacterTracker {
  final Set<String> _confirmedNames = {};
  
  void addName(String name) {
    if (name.isNotEmpty && name.length > 2) {
      _confirmedNames.add(name);
    }
  }
  
  void addNames(List<String> names) {
    for (final name in names) {
      addName(name);
    }
  }
  
  Set<String> get confirmedNames => Set.unmodifiable(_confirmedNames);
  
  bool hasName(String name) => _confirmedNames.contains(name);
  
  void clear() => _confirmedNames.clear();
}
