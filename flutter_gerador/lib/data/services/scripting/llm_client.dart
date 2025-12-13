import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 🤖 LlmClient - Cliente para comunicação com APIs de LLM (Gemini)
///
/// Responsável por:
/// - Inicialização e configuração do cliente HTTP
/// - Gestão de API Keys
/// - Chamadas à API Gemini
/// - Métodos simplificados: `generateText` e `generateJson`
///
/// Parte da refatoração SOLID do GeminiService v7.6.64
class LlmClient {
  final Dio _dio;
  final String _instanceId;

  /// 📝 Helper padronizado para logs (mantém emojis em debug, limpa em produção)
  static void _log(String message, {String level = 'info'}) {
    if (kDebugMode) {
      debugPrint(message);
    } else if (level == 'error' || level == 'critical') {
      final cleaned = message
          .replaceAll(RegExp(r'[🚨🔥✅❌⚠️💡📊🎯📝🔗📚🤖🌐]'), '')
          .trim();
      debugPrint('[${level.toUpperCase()}] $cleaned');
    }
  }

  /// Modelos disponíveis no Gemini
  static const String modelFlash = 'gemini-2.5-flash';
  static const String modelPro = 'gemini-2.5-pro';
  static const String modelUltra = 'gemini-3-pro-preview';

  /// Construtor com injeção de dependências opcional
  LlmClient({Dio? dio, String? instanceId})
    : _dio = dio ?? _createDefaultDio(),
      _instanceId = instanceId ?? _genInstanceId();

  /// Cria instância padrão do Dio com configurações otimizadas
  static Dio _createDefaultDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(seconds: 45),
      ),
    );
  }

  /// Gera ID único para a instância
  static String _genInstanceId() {
    final random = Random();
    return 'llm_${random.nextInt(9999).toString().padLeft(4, '0')}';
  }

  /// 🎯 Helper para selecionar modelo baseado no qualityMode
  ///
  /// - 'flash': Rápido e eficiente (gemini-2.5-flash)
  /// - 'pro': Máxima qualidade (gemini-2.5-pro) - PADRÃO
  /// - 'ultra': Modelo mais avançado (gemini-3-pro-preview)
  static String getModelForQuality(String qualityMode) {
    switch (qualityMode.toLowerCase()) {
      case 'flash':
        return modelFlash;
      case 'ultra':
        return modelUltra;
      case 'pro':
      default:
        return modelPro;
    }
  }

  /// 🔧 Gera texto usando a API Gemini
  ///
  /// [prompt]: O prompt a ser enviado
  /// [apiKey]: Chave da API Gemini
  /// [model]: Modelo a ser usado (use [getModelForQuality] para obter)
  /// [maxTokens]: Máximo de tokens na resposta
  /// [temperature]: Temperatura (criatividade) - padrão ajustado por modelo
  ///
  /// Retorna: Texto gerado ou string vazia em caso de erro
  Future<String> generateText({
    required String prompt,
    required String apiKey,
    required String model,
    int maxTokens = 8192,
    double? temperature,
  }) async {
    try {
      // Ajustar temperatura baseado no modelo se não especificado
      final effectiveTemperature = temperature ?? _getDefaultTemperature(model);

      final response = await _makeRequest(
        apiKey: apiKey,
        model: model,
        prompt: prompt,
        maxTokens: maxTokens,
        temperature: effectiveTemperature,
      );

      return response ?? '';
    } catch (e) {
      _log('❌ Erro em generateText: $e', level: 'error');
      rethrow;
    }
  }

  /// 🎯 Obtém temperatura padrão otimizada por modelo
  double _getDefaultTemperature(String model) {
    if (model == modelFlash) {
      // Flash: temperatura balanceada (0.6 causava muitas repetições)
      return 0.7;
    } else if (model == modelPro) {
      // Pro: temperatura alta para máxima criatividade
      return 0.8;
    } else {
      // Ultra: temperatura balanceada
      return 0.7;
    }
  }

  /// 🔧 Gera JSON estruturado usando a API Gemini
  ///
  /// Útil para extração de dados estruturados (ex: World State)
  ///
  /// [prompt]: O prompt a ser enviado (deve instruir formato JSON)
  /// [apiKey]: Chave da API Gemini
  /// [model]: Modelo a ser usado
  /// [maxTokens]: Máximo de tokens na resposta
  ///
  /// Retorna: Texto JSON ou string vazia em caso de erro
  Future<String> generateJson({
    required String prompt,
    required String apiKey,
    required String model,
    int maxTokens = 2048,
  }) async {
    try {
      // Temperatura mais baixa para JSON consistente
      final response = await _makeRequest(
        apiKey: apiKey,
        model: model,
        prompt: prompt,
        maxTokens: maxTokens,
        temperature: 0.3, // Baixa temperatura para JSON estruturado
      );

      return response ?? '';
    } catch (e) {
      _log('❌ Erro em generateJson: $e', level: 'error');
      rethrow;
    }
  }

  /// 🔧 Faz requisição à API Gemini
  ///
  /// Método interno que realiza a chamada HTTP
  Future<String?> _makeRequest({
    required String apiKey,
    required String model,
    required String prompt,
    required int maxTokens,
    double temperature = 0.8,
  }) async {
    try {
      // Ajustar maxTokens para limites da API
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
            'temperature': temperature,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': adjustedMaxTokens,
          },
        },
      );

      if (kDebugMode) {
        debugPrint('[$_instanceId] Status Code: ${resp.statusCode}');
      }

      // Verificar erro na resposta
      if (resp.data['error'] != null) {
        debugPrint('[$_instanceId] API Error: ${resp.data['error']}');
        throw Exception('API Error: ${resp.data['error']['message']}');
      }

      // Verificar bloqueio de conteúdo
      final promptFeedback = resp.data['promptFeedback'];
      if (promptFeedback != null && promptFeedback['blockReason'] != null) {
        final blockReason = promptFeedback['blockReason'];
        _log('🚫 CONTEÚDO BLOQUEADO - Razão: $blockReason', level: 'error');
        return null;
      }

      // Verificar finish reason
      final finishReason = resp.data['candidates']?[0]?['finishReason'];
      if (finishReason == 'MAX_TOKENS' && kDebugMode) {
        debugPrint(
          '[$_instanceId] Aviso - Resposta cortada por limite de tokens',
        );
      }

      // Extrair texto da resposta
      String? result;
      final candidate = resp.data['candidates']?[0];

      if (candidate != null) {
        result = candidate['content']?['parts']?[0]?['text'] as String?;

        if (result == null || result.isEmpty) {
          result = candidate['content']?['text'] as String?;
        }

        if (result == null || result.isEmpty) {
          result = candidate['text'] as String?;
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[$_instanceId] Extracted text: ${result?.length ?? 0} chars',
        );
      }

      // Limpar texto de marcações indesejadas
      if (result != null) {
        result = _cleanGeneratedText(result);
      }

      return result;
    } catch (e) {
      _log('❌ Erro na requisição API: $e', level: 'error');
      
      // 🚨 Tratamento especial para erro 429 (Rate Limit)
      if (e.toString().contains('429')) {
        _log('⚠️ Rate Limit atingido - aguarde antes de nova tentativa', level: 'warning');
      }
      
      rethrow;
    }
  }

  /// Limpa texto de marcações indesejadas
  String _cleanGeneratedText(String text) {
    return text
        .replaceAll(RegExp(r'CONTINUAÇÃO:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'CONTEXTO FINAL:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\n\n\n+'), '\n\n')
        .trim();
  }

  /// 🔧 Verifica se a API key é válida fazendo uma requisição simples
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelFlash:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': 'Hello'},
              ],
            },
          ],
          'generationConfig': {'maxOutputTokens': 10},
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Libera recursos
  void dispose() {
    _dio.close();
  }
}
