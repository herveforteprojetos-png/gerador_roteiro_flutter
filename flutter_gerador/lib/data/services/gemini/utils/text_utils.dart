// 🔧 v7.6.106: Módulo de Utilidades de Texto (SOLID - SRP)
// Extraído de gemini_service.dart

import 'package:flutter_gerador/data/services/gemini/detection/duplication_detector.dart';

/// Utilidades para verificação de similaridade textual e contagem de palavras
class TextUtils {
  // 🚀 Cache ULTRA-AGRESSIVO para evitar reprocessamento
  static final Map<int, int> _wordCountCache = {};
  static int _lastHashChecked = 0;
  static int _lastCountReturned = 0;

  /// Conta palavras em um texto com cache ultra-otimizado
  static int countWords(String text) {
    if (text.isEmpty) return 0;

    // 🚀 OTIMIZAÇÃO EXTREMA: Cache de última consulta (hit rate ~90%)
    final hash = text.hashCode;
    if (hash == _lastHashChecked) {
      return _lastCountReturned;
    }

    // Cache baseado no hash do texto
    if (_wordCountCache.containsKey(hash)) {
      _lastHashChecked = hash;
      _lastCountReturned = _wordCountCache[hash]!;
      return _lastCountReturned;
    }

    // OTIMIZAÇÃO: trim() uma única vez
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;

    // Conta palavras usando split otimizado
    final count = trimmed.split(RegExp(r'\s+')).length;

    // 🚀 Cache expandido: 200 entradas para maior hit rate
    if (_wordCountCache.length > 200) {
      _wordCountCache.clear();
    }
    _wordCountCache[hash] = count;
    _lastHashChecked = hash;
    _lastCountReturned = count;

    return count;
  }

  /// Retorna true se similaridade > threshold (padrão 85%) OU se há duplicação literal
  static bool isTooSimilar(
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

  /// Função para uso em Isolate
  static Map<String, dynamic> isTooSimilarInIsolate(
    Map<String, dynamic> params,
  ) {
    // params: { 'newBlock': String, 'previousContent': String, 'threshold': double }
    return isTooSimilarIsolate(params);
  }
}
