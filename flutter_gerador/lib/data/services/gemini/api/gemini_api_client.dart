import 'dart:developer' show log;
import 'dart:math' show min;
import 'package:dio/dio.dart';

class GeminiApiClient {
  final Dio dio;
  final String instanceId;

  GeminiApiClient(this.dio, this.instanceId);

  Future<String?> generateContent({
    required String prompt,
    required String apiKey,
    required String model,
    required int maxTokens,
  }) async {
    try {
      final adjustedMaxTokens = maxTokens < 8192
          ? 8192
          : min(maxTokens * 2, 32768);
      final response = await dio.post(
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

      if (response.data['error'] != null) {
        throw Exception(response.data['error']['message']);
      }

      final promptFeedback = response.data['promptFeedback'];
      if (promptFeedback?['blockReason'] != null) {
        log('🚫 Conteúdo bloqueado: ${promptFeedback['blockReason']}');
        return null;
      }

      String? result =
          response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (result == null || result.isEmpty) {
        result = response.data['candidates']?[0]?['text'];
      }

      return result
          ?.replaceAll(RegExp(r'CONTINUAÇÃO:\s*', caseSensitive: false), '')
          .trim();
    } catch (e) {
      log('[$instanceId] Erro API: $e');
      rethrow;
    }
  }

  Future<String> generateSimple(String prompt, {required String apiKey}) async {
    return await generateContent(
          prompt: prompt,
          apiKey: apiKey,
          model: 'gemini-2.5-pro',
          maxTokens: 1000,
        ) ??
        '';
  }
}
