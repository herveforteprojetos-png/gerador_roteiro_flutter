import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// 🚦 RateLimiter - Controle de taxa de requisições e circuit breaker
///
/// Responsável por:
/// - Rate limiting global para múltiplas instâncias
/// - Circuit breaker para falhas consecutivas
/// - Watchdog para timeout de operações longas
/// - Adaptive delay baseado em comportamento da API
/// - Retry com backoff exponencial
///
/// Parte da refatoração SOLID do GeminiService v7.6.66
class RateLimiter {
  final String instanceId;

  // Circuit breaker
  bool _isCircuitOpen = false;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  static const int _maxFailures = 5;
  static const Duration _circuitResetTime = Duration(seconds: 30);

  // Rate limiting global
  static int _globalRequestCount = 0;
  static DateTime _globalLastRequestTime = DateTime.now();
  static const Duration _rateLimitWindow = Duration(seconds: 60);
  static const int _maxRequestsPerWindow = 50;
  static bool _rateLimitBusy = false;

  // Watchdog
  Timer? _watchdogTimer;
  bool _isOperationRunning = false;
  static const Duration _maxOperationTime = Duration(minutes: 60);

  // Adaptive delay
  DateTime? _lastSuccessfulCall;
  int _consecutive503Errors = 0;
  int _consecutiveSuccesses = 0;

  /// Flag para indicar se a operação foi cancelada
  bool isCancelled = false;

  RateLimiter({required this.instanceId});

  /// Reset do circuit breaker
  void resetCircuit() {
    _isCircuitOpen = false;
    _failureCount = 0;
    _lastFailureTime = null;
  }

  /// Registra uma falha
  void registerFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    if (_failureCount >= _maxFailures) {
      _isCircuitOpen = true;
      if (kDebugMode) debugPrint('[$instanceId] Circuit aberto');
    }
  }

  /// Verifica se pode fazer requisição
  bool canMakeRequest() {
    if (!_isCircuitOpen) return true;
    if (_lastFailureTime != null &&
        DateTime.now().difference(_lastFailureTime!) > _circuitResetTime) {
      resetCircuit();
      return true;
    }
    return false;
  }

  /// Inicia watchdog para timeout
  void startWatchdog({void Function()? onTimeout}) {
    stopWatchdog();
    _isOperationRunning = true;
    if (kDebugMode) {
      debugPrint(
        '[$instanceId] Iniciando watchdog (${_maxOperationTime.inMinutes} min)',
      );
    }

    _watchdogTimer = Timer(_maxOperationTime, () {
      if (_isOperationRunning && !isCancelled) {
        if (kDebugMode) {
          debugPrint(
            '[$instanceId] Watchdog timeout - cancelando operação após ${_maxOperationTime.inMinutes} min',
          );
        }
        isCancelled = true;
        onTimeout?.call();
      }
    });
  }

  /// Reseta watchdog (para operações longas em progresso)
  void resetWatchdog({void Function()? onTimeout}) {
    if (_isOperationRunning && !isCancelled) {
      startWatchdog(onTimeout: onTimeout);
      if (kDebugMode) {
        debugPrint('[$instanceId] Watchdog resetado - operação ativa');
      }
    }
  }

  /// Para watchdog
  void stopWatchdog() {
    if (_watchdogTimer != null) {
      _watchdogTimer!.cancel();
      if (kDebugMode && _isOperationRunning) {
        debugPrint('[$instanceId] Parando watchdog');
      }
    }
    _isOperationRunning = false;
  }

  /// Garante rate limit antes de requisição
  Future<void> ensureRateLimit() async {
    int attempts = 0;
    const maxAttempts = 100;

    while (_rateLimitBusy && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    if (attempts >= maxAttempts) {
      if (kDebugMode) {
        debugPrint('[$instanceId] Rate limit timeout, proceeding anyway');
      }
      return;
    }

    _rateLimitBusy = true;

    try {
      final now = DateTime.now();
      final diff = now.difference(_globalLastRequestTime);

      if (kDebugMode) {
        debugPrint(
          '[$instanceId] Rate limit check: $_globalRequestCount/$_maxRequestsPerWindow requests in window',
        );
      }

      // Reset contador se passou da janela
      if (diff > _rateLimitWindow) {
        _globalRequestCount = 0;
        if (kDebugMode) debugPrint('[$instanceId] Rate limit window reset');
      }

      // Se atingiu limite, aguarda
      if (_globalRequestCount >= _maxRequestsPerWindow) {
        final wait = _rateLimitWindow - diff;
        if (wait > Duration.zero && wait < const Duration(seconds: 30)) {
          if (kDebugMode) {
            debugPrint(
              '[$instanceId] Rate limit hit, waiting ${wait.inSeconds}s',
            );
          }
          _rateLimitBusy = false;
          await Future.delayed(wait);

          attempts = 0;
          while (_rateLimitBusy && attempts < 20) {
            await Future.delayed(const Duration(milliseconds: 50));
            attempts++;
          }

          if (attempts < 20) {
            _rateLimitBusy = true;
            _globalRequestCount = 0;
          } else {
            if (kDebugMode) {
              debugPrint(
                '[$instanceId] Could not reacquire rate limit lock, proceeding',
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
          '[$instanceId] Request $_globalRequestCount/$_maxRequestsPerWindow approved',
        );
      }
    } finally {
      _rateLimitBusy = false;
    }
  }

  /// Obtém delay adaptativo baseado em comportamento da API
  Duration getAdaptiveDelay({required int blockNumber}) {
    // Se última chamada foi sucesso rápido, delay mínimo
    if (_lastSuccessfulCall != null &&
        DateTime.now().difference(_lastSuccessfulCall!) <
            const Duration(seconds: 3)) {
      _consecutiveSuccesses++;

      if (_consecutiveSuccesses >= 2) {
        if (blockNumber <= 10) return const Duration(milliseconds: 300);
        return const Duration(milliseconds: 800);
      }
    }

    // Se teve erro 503 recente, aumentar delay
    if (_consecutive503Errors > 0) {
      _consecutiveSuccesses = 0;
      final delaySeconds = min(5 * _consecutive503Errors, 15);
      return Duration(seconds: delaySeconds);
    }

    // Padrão: delays mínimos
    _consecutiveSuccesses = 0;
    _consecutive503Errors = max(0, _consecutive503Errors - 1);

    if (blockNumber <= 5) return const Duration(milliseconds: 500);
    if (blockNumber <= 15) return const Duration(milliseconds: 1000);
    if (blockNumber <= 25) return const Duration(milliseconds: 1500);
    return const Duration(seconds: 2);
  }

  /// Registra sucesso de chamada
  void recordApiSuccess() {
    _lastSuccessfulCall = DateTime.now();
    _consecutive503Errors = max(0, _consecutive503Errors - 1);
  }

  /// Registra erro 503
  void recordApi503Error() {
    _consecutive503Errors++;
    _consecutiveSuccesses = 0;
  }

  /// Reset global do rate limit (para nova geração)
  static void resetGlobalRateLimit() {
    _globalRequestCount = 0;
    _globalLastRequestTime = DateTime.now();
    _rateLimitBusy = false;
  }

  /// Retry com backoff exponencial
  Future<T> retryOnRateLimit<T>(
    Future<T> Function() operation, {
    int maxRetries = 6,
  }) async {
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (isCancelled) {
          throw Exception('Operação cancelada');
        }

        await ensureRateLimit();

        if (isCancelled) {
          throw Exception('Operação cancelada');
        }

        return await operation();
      } catch (e) {
        if (isCancelled) {
          throw Exception('Operação cancelada');
        }

        String errorMsg = e.toString().toLowerCase();

        // Erro 503 (servidor indisponível)
        if (errorMsg.contains('503') ||
            errorMsg.contains('server error') ||
            errorMsg.contains('service unavailable')) {
          recordApi503Error();

          if (attempt < maxRetries - 1) {
            final baseDelay = 10;
            final exponentialDelay = baseDelay * (1 << attempt);
            final delay = Duration(seconds: min(exponentialDelay, 90));

            if (kDebugMode) {
              debugPrint(
                '[$instanceId] 🔴 ERRO 503 - Aguardando ${delay.inSeconds}s (retry ${attempt + 2}/$maxRetries)',
              );
            }
            await Future.delayed(delay);
            continue;
          } else {
            throw Exception(
              '🔴 ERRO CRÍTICO: Servidor indisponível após $maxRetries tentativas.\n'
              '💡 Aguarde alguns minutos e tente novamente.',
            );
          }
        }

        // Erro 429 (rate limit)
        if (errorMsg.contains('429') && attempt < maxRetries - 1) {
          final delay = Duration(seconds: (attempt + 1) * 5);
          if (kDebugMode) {
            debugPrint(
              '[$instanceId] 🔴 ERRO 429 - Aguardando ${delay.inSeconds}s (tentativa ${attempt + 1}/$maxRetries)',
            );
          }
          await Future.delayed(delay);
          continue;
        }

        // Timeout/Connection
        if ((errorMsg.contains('timeout') || errorMsg.contains('connection')) &&
            attempt < maxRetries - 1) {
          final delay = const Duration(seconds: 1);
          if (kDebugMode) {
            debugPrint(
              '[$instanceId] ⚡ Timeout - Retry rápido em ${delay.inSeconds}s',
            );
          }
          await Future.delayed(delay);
          continue;
        }

        // Outros erros
        rethrow;
      }
    }

    throw Exception('Máximo de tentativas atingido');
  }

  /// Dispose
  void dispose() {
    stopWatchdog();
  }
}
