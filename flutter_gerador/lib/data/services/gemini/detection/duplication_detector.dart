import 'dart:math';
import 'package:flutter/foundation.dart';

/// 🔍 DuplicationDetector - Detecta duplicação e similaridade de texto
///
/// Responsável por:
/// - Verificar duplicação literal de parágrafos
/// - Calcular similaridade entre textos usando n-grams
/// - Filtrar parágrafos duplicados
/// - Funções estáticas para uso em Isolate
///
/// Parte da refatoração SOLID do GeminiService v7.6.66
class DuplicationDetector {
  /// Configurações padrão
  static const int minParagraphWords = 30;
  static const int minSequenceWords = 150;
  static const int nGramSize = 8;
  static const int maxContextLength = 12000;
  static const int maxRecentParagraphs = 10;

  /// Verifica se novo bloco é muito similar aos blocos anteriores
  /// Retorna true se similaridade > threshold (padrão 85%) OU se há duplicação literal
  static bool isTooSimilar(
    String newBlock,
    String previousContent, {
    double threshold = 0.85,
  }) {
    if (previousContent.isEmpty) return false;

    // 🔥 PRIORIDADE 1: Verificar duplicação literal de blocos grandes (cópia exata)
    if (hasLiteralDuplication(newBlock, previousContent)) {
      if (kDebugMode) {
        debugPrint(
          '🚨 BLOQUEIO CRÍTICO: Duplicação literal de bloco inteiro detectada!',
        );
      }
      return true;
    }

    // 🚀 OTIMIZAÇÃO: Limitar contexto anterior para comparação
    final limitedPrevious = previousContent.length > maxContextLength
        ? previousContent.substring(previousContent.length - maxContextLength)
        : previousContent;

    // Dividir conteúdo anterior em parágrafos
    final paragraphs = limitedPrevious
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    // 🚀 OTIMIZAÇÃO CRÍTICA: Limitar a últimos parágrafos
    final recentParagraphs = paragraphs.length > maxRecentParagraphs
        ? paragraphs.sublist(paragraphs.length - maxRecentParagraphs)
        : paragraphs;

    // Dividir novo bloco em parágrafos
    final newParagraphs = newBlock
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    // Verificar cada parágrafo novo contra os RECENTES
    int highSimilarityCount = 0;

    for (final newPara in newParagraphs) {
      if (newPara.trim().length < 100) {
        continue; // Ignorar parágrafos muito curtos
      }

      // 🚀 OTIMIZAÇÃO: Parar se já encontrou repetição suficiente
      if (highSimilarityCount >= 2) break;

      for (final oldPara in recentParagraphs) {
        if (oldPara.trim().length < 100) continue;

        final similarity = calculateSimilarity(newPara, oldPara);

        if (similarity >= threshold) {
          highSimilarityCount++;
          if (kDebugMode) {
            debugPrint(
              '⚠️ REPETIÇÃO DETECTADA (parágrafo $highSimilarityCount)!',
            );
            debugPrint(
              '   Similaridade: ${(similarity * 100).toStringAsFixed(1)}% (threshold: ${(threshold * 100).toInt()}%)',
            );
          }

          // 🔥 Se encontrar 2+ parágrafos muito similares = bloco repetido
          if (highSimilarityCount >= 2) {
            if (kDebugMode) {
              debugPrint(
                '🚨 BLOQUEIO: $highSimilarityCount parágrafos com alta similaridade!',
              );
            }
            return true;
          }
          break;
        }
      }
    }

    return false;
  }

  /// Verifica se há duplicação LITERAL de blocos inteiros (cópia exata)
  /// Retorna true se encontrar blocos de 150+ palavras duplicados
  static bool hasLiteralDuplication(String newBlock, String previousContent) {
    if (previousContent.isEmpty || newBlock.isEmpty) return false;
    if (previousContent.length < 500) return false;

    // 🆕 CAMADA 1: Verificar parágrafos completos duplicados
    final newParagraphs = newBlock
        .split('\n\n')
        .where(
          (p) =>
              p.trim().isNotEmpty &&
              p.trim().split(RegExp(r'\s+')).length > minParagraphWords,
        )
        .map((p) => p.trim().toLowerCase())
        .toList();

    final prevParagraphs = previousContent
        .split('\n\n')
        .where(
          (p) =>
              p.trim().isNotEmpty &&
              p.trim().split(RegExp(r'\s+')).length > minParagraphWords,
        )
        .map((p) => p.trim().toLowerCase())
        .toList();

    // 🔥 CRÍTICO: Detectar parágrafos idênticos
    for (final newPara in newParagraphs) {
      for (final prevPara in prevParagraphs) {
        if (newPara == prevPara) {
          if (kDebugMode) {
            debugPrint('🚨 PARÁGRAFO DUPLICADO EXATO DETECTADO!');
            debugPrint(
              '   Preview: ${newPara.substring(0, min(100, newPara.length))}...',
            );
          }
          return true;
        }

        // 🆕 Verificar início idêntico (primeiras 50 palavras)
        final newWords = newPara.split(RegExp(r'\s+'));
        final prevWords = prevPara.split(RegExp(r'\s+'));

        if (newWords.length > 50 && prevWords.length > 50) {
          final newStart = newWords.take(50).join(' ');
          final prevStart = prevWords.take(50).join(' ');

          if (newStart == prevStart) {
            if (kDebugMode) {
              debugPrint('🚨 INÍCIO DE PARÁGRAFO DUPLICADO DETECTADO!');
            }
            return true;
          }
        }
      }
    }

    // 🆕 CAMADA 2: Verificar sequências de palavras
    final newWords = newBlock.trim().split(RegExp(r'\s+'));
    final prevWords = previousContent.trim().split(RegExp(r'\s+'));

    if (newWords.length < minSequenceWords ||
        prevWords.length < minSequenceWords) {
      return false;
    }

    // Verificar sequências de 150 palavras
    for (int i = 0; i <= newWords.length - minSequenceWords; i++) {
      final newSequence = newWords
          .sublist(i, i + minSequenceWords)
          .join(' ')
          .toLowerCase();

      for (int j = 0; j <= prevWords.length - minSequenceWords; j++) {
        final prevSequence = prevWords
            .sublist(j, j + minSequenceWords)
            .join(' ')
            .toLowerCase();

        if (newSequence == prevSequence) {
          if (kDebugMode) {
            debugPrint('🚨 DUPLICAÇÃO LITERAL DE $minSequenceWords PALAVRAS!');
          }
          return true;
        }
      }
    }

    return false;
  }

  /// Calcula similaridade entre dois textos usando n-grams
  /// Retorna valor entre 0.0 (totalmente diferente) e 1.0 (idêntico)
  static double calculateSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    // Normalizar textos
    final normalized1 = text1.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final normalized2 = text2.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (normalized1 == normalized2) return 1.0;

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

    // Calcular Jaccard similarity
    final intersection = ngrams1.intersection(ngrams2).length;
    final union = ngrams1.union(ngrams2).length;

    return union > 0 ? intersection / union : 0.0;
  }

  /// Filtra parágrafos duplicados de um texto em relação ao existente
  static String filterDuplicateParagraphs(String existing, String addition) {
    if (addition.trim().isEmpty) return '';

    // Comparar apenas últimos ~5000 caracteres
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
      if (paragraph.isEmpty) continue;
      if (existingSet.contains(paragraph)) continue;
      if (!seen.add(paragraph)) continue;
      buffer.add(paragraph);
    }

    return buffer.join('\n\n');
  }

  /// Remove TODOS os parágrafos duplicados de um texto completo
  static String removeAllDuplicateParagraphs(String fullScript) {
    if (fullScript.isEmpty) return fullScript;

    final paragraphs = fullScript.split(RegExp(r'\n{2,}'));
    final seen = <String>{};
    final uniqueParagraphs = <String>[];

    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) continue;

      // Normalizar para comparação (lowercase, sem espaços extras)
      final normalized = trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      if (!seen.contains(normalized)) {
        seen.add(normalized);
        uniqueParagraphs.add(trimmed);
      } else if (kDebugMode) {
        debugPrint(
          '🗑️ Parágrafo duplicado removido: ${trimmed.substring(0, min(50, trimmed.length))}...',
        );
      }
    }

    return uniqueParagraphs.join('\n\n');
  }
}

// ============================================================================
// 🚀 FUNÇÕES TOP-LEVEL PARA ISOLATE
// Essas funções são usadas para processamento em thread separada
// ============================================================================

/// Função top-level para filtrar parágrafos duplicados em Isolate
String filterDuplicateParagraphsIsolate(Map<String, dynamic> params) {
  final String existing = params['existing'] as String;
  final String addition = params['addition'] as String;
  return DuplicationDetector.filterDuplicateParagraphs(existing, addition);
}

/// Função top-level para verificar similaridade em Isolate
Map<String, dynamic> isTooSimilarIsolate(Map<String, dynamic> params) {
  final String newBlock = params['newBlock'] as String;
  final String previousContent = params['previousContent'] as String;
  final double threshold = params['threshold'] as double;

  if (previousContent.isEmpty) {
    return {'isSimilar': false, 'reason': 'No previous content'};
  }

  // Verificar duplicação literal
  if (DuplicationDetector.hasLiteralDuplication(newBlock, previousContent)) {
    return {'isSimilar': true, 'reason': 'Literal duplication detected'};
  }

  // Verificar similaridade
  final isSimilar = DuplicationDetector.isTooSimilar(
    newBlock,
    previousContent,
    threshold: threshold,
  );

  return {
    'isSimilar': isSimilar,
    'reason': isSimilar ? 'High similarity detected' : 'Content is unique',
  };
}
