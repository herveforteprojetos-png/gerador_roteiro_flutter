import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 🤖 OpenAI Service - Integração com GPT-4o
///
/// Serve como FALLBACK quando Gemini API está indisponível (erro 503).
///
/// Features:
/// - GPT-4o (mais recente e capaz)
/// - Mesmo formato de prompt do Gemini
/// - Rate limiting inteligente
/// - Retry logic com exponential backoff
class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-4o'; // Modelo mais recente

  late final Dio _dio;
  String? _apiKey;

  // Rate limiting
  static int _globalRequestCount = 0;
  static DateTime? _globalLastRequestTime;
  static const int _maxRequestsPerMinute = 50; // OpenAI: 50 req/min para tier 1
  static bool _rateLimitBusy = false;

  OpenAIService({String? apiKey}) : _apiKey = apiKey {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor para logging
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('[OpenAI] -> ${options.method} ${options.uri}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('[OpenAI] <- ${response.statusCode}');
            return handler.next(response);
          },
          onError: (error, handler) {
            debugPrint('[OpenAI] ERROR: ${error.message}');
            return handler.next(error);
          },
        ),
      );
    }
  }

  void setApiKey(String key) {
    _apiKey = key;
  }

  /// Rate limiting similar ao Gemini
  Future<void> _ensureRateLimit() async {
    while (_rateLimitBusy) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _rateLimitBusy = true;

    try {
      final now = DateTime.now();

      if (_globalLastRequestTime != null) {
        final elapsed = now.difference(_globalLastRequestTime!);

        // Reset a cada minuto
        if (elapsed.inSeconds >= 60) {
          _globalRequestCount = 0;
          _globalLastRequestTime = now;
        } else if (_globalRequestCount >= _maxRequestsPerMinute) {
          final waitTime = 60 - elapsed.inSeconds;
          if (kDebugMode) {
            debugPrint('[OpenAI] Rate limit: aguardando ${waitTime}s...');
          }
          await Future.delayed(Duration(seconds: waitTime));
          _globalRequestCount = 0;
          _globalLastRequestTime = DateTime.now();
        }
      } else {
        _globalLastRequestTime = now;
      }

      _globalRequestCount++;

      if (kDebugMode) {
        debugPrint(
          '[OpenAI] Request $_globalRequestCount/$_maxRequestsPerMinute',
        );
      }
    } finally {
      _rateLimitBusy = false;
    }
  }

  /// Retry com exponential backoff
  Future<T> _retryOnError<T>(
    Future<T> Function() op, {
    int maxRetries = 6,
  }) async {
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await _ensureRateLimit();
        return await op();
      } catch (e) {
        final errorStr = e.toString().toLowerCase();

        // Erro 429: Rate limit
        if (errorStr.contains('429')) {
          if (attempt < maxRetries - 1) {
            final delay = Duration(seconds: (attempt + 1) * 15);
            if (kDebugMode) {
              debugPrint(
                '[OpenAI] 429 Rate Limit - aguardando ${delay.inSeconds}s',
              );
            }
            await Future.delayed(delay);
            continue;
          }
        }

        // Erro 503/500: Server error
        if (errorStr.contains('503') || errorStr.contains('500')) {
          if (attempt < maxRetries - 1) {
            final baseDelay = 30;
            final exponentialDelay = baseDelay * (1 << attempt);
            final delay = Duration(seconds: min(exponentialDelay, 300));
            if (kDebugMode) {
              debugPrint(
                '[OpenAI] Server error - aguardando ${delay.inSeconds}s',
              );
            }
            await Future.delayed(delay);
            continue;
          }
        }

        // Outros erros: retry rápido
        if (attempt < maxRetries - 1) {
          final delay = Duration(seconds: (attempt + 1) * 2);
          if (kDebugMode) {
            debugPrint('[OpenAI] Erro - retry em ${delay.inSeconds}s');
          }
          await Future.delayed(delay);
          continue;
        }

        rethrow;
      }
    }

    throw Exception('OpenAI: Falhou após $maxRetries tentativas');
  }

  /// Gera conteúdo usando GPT-4o
  Future<String> generateContent({
    required String prompt,
    required int maxTokens,
    double temperature = 0.85,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenAI API Key não configurada');
    }

    return _retryOnError(() async {
      final response = await _dio.post(
        '/chat/completions',
        options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
        data: {
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'Você é um roteirista profissional especializado em criar histórias envolventes para YouTube. Siga TODAS as instruções com precisão absoluta.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
          'top_p': 0.95,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('OpenAI retornou status ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List;

      if (choices.isEmpty) {
        throw Exception('OpenAI retornou resposta vazia');
      }

      final message = choices[0]['message'] as Map<String, dynamic>;
      final content = message['content'] as String;

      // Informações de uso
      final usage = data['usage'] as Map<String, dynamic>?;
      if (kDebugMode && usage != null) {
        debugPrint(
          '[OpenAI] Tokens: ${usage['total_tokens']} (prompt: ${usage['prompt_tokens']}, completion: ${usage['completion_tokens']})',
        );
      }

      return content.trim();
    });
  }

  /// Testa conectividade com OpenAI
  Future<bool> testConnection() async {
    try {
      await generateContent(
        prompt: 'Diga apenas "OK" para confirmar que você está funcionando.',
        maxTokens: 10,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OpenAI] Teste de conexão falhou: $e');
      }
      return false;
    }
  }
}
