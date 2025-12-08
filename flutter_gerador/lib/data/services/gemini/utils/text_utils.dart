// 🔧 v7.6.106: Módulo de Utilidades de Texto (SOLID - SRP)
// Extraído de gemini_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_gerador/data/services/gemini/detection/duplication_detector.dart';

/// Utilidades para verificação de similaridade textual
class TextUtils {
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
  static Map<String, dynamic> isTooSimilarInIsolate(Map<String, dynamic> params) {
    // params: { 'newBlock': String, 'previousContent': String, 'threshold': double }
    return isTooSimilarIsolate(params);
  }
}
