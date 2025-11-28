import 'package:flutter/foundation.dart';
import 'package:flutter_gerador/data/services/gemini/utils/similarity_calculator.dart';

/// 🔥 Validador anti-repetição - detecta blocos duplicados ou muito similares
class AntiRepetitionValidator {
  /// Verifica se novo bloco é muito similar aos blocos anteriores
  /// Retorna mapa com 'isSimilar' (bool) e 'reason' (String)
  static Map<String, dynamic> validate({
    required String newBlock,
    required String previousContent,
    double threshold = 0.80,
  }) {
    if (previousContent.isEmpty) {
      return {'isSimilar': false, 'reason': 'No previous content'};
    }

    // 🔥 PRIORIDADE 1: Verificar duplicação literal de blocos grandes
    final hasLiteral = hasLiteralDuplication(newBlock, previousContent);
    if (hasLiteral) {
      return {'isSimilar': true, 'reason': 'Literal duplication detected'};
    }

    // 🚀 OTIMIZAÇÃO: Limitar contexto anterior para comparação
    final limitedPrevious = previousContent.length > 12000
        ? previousContent.substring(previousContent.length - 12000)
        : previousContent;

    // Dividir conteúdo anterior em parágrafos
    final paragraphs = limitedPrevious
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    // 🚀 OTIMIZAÇÃO CRÍTICA: Limitar a 10 últimos parágrafos
    final recentParagraphs = paragraphs.length > 10
        ? paragraphs.sublist(paragraphs.length - 10)
        : paragraphs;

    // Dividir novo bloco em parágrafos
    final newParagraphs = newBlock
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    // 🎯 AJUSTE FINO: Verificar cada parágrafo novo contra os RECENTES
    int highSimilarityCount = 0;

    for (final newPara in newParagraphs) {
      // 🔥 AJUSTE: Detectar parágrafos de 50+ palavras
      final wordCount = newPara.trim().split(RegExp(r'\s+')).length;
      if (wordCount < 50) continue;

      if (highSimilarityCount >= 2) break;

      for (final oldPara in recentParagraphs) {
        final oldWordCount = oldPara.trim().split(RegExp(r'\s+')).length;
        if (oldWordCount < 50) continue;

        final similarity = SimilarityCalculator.calculate(newPara, oldPara);

        // 🔥 AJUSTE: Threshold reduzido de 85% para 80%
        if (similarity >= threshold) {
          highSimilarityCount++;

          if (highSimilarityCount >= 2) {
            return {
              'isSimilar': true,
              'reason':
                  '$highSimilarityCount paragraphs with ${(similarity * 100).toStringAsFixed(1)}% similarity',
            };
          }
          break;
        }
      }
    }

    return {'isSimilar': false, 'reason': 'Content is unique'};
  }

  /// Versão síncrona (para uso direto sem isolate)
  static bool isTooSimilar(
    String newBlock,
    String previousContent, {
    double threshold = 0.85,
  }) {
    if (previousContent.isEmpty) return false;

    // 🔥 PRIORIDADE 1: Verificar duplicação literal
    if (hasLiteralDuplication(newBlock, previousContent)) {
      if (kDebugMode) {
        debugPrint(
          '🚨 BLOQUEIO CRÍTICO: Duplicação literal de bloco inteiro detectada!',
        );
      }
      return true;
    }

    // 🚀 OTIMIZAÇÃO: Limitar contexto anterior
    final limitedPrevious = previousContent.length > 12000
        ? previousContent.substring(previousContent.length - 12000)
        : previousContent;

    final paragraphs = limitedPrevious
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final recentParagraphs = paragraphs.length > 10
        ? paragraphs.sublist(paragraphs.length - 10)
        : paragraphs;
    final newParagraphs = newBlock
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    int highSimilarityCount = 0;

    for (final newPara in newParagraphs) {
      if (newPara.trim().length < 100) continue;
      if (highSimilarityCount >= 2) break;

      for (final oldPara in recentParagraphs) {
        if (oldPara.trim().length < 100) continue;

        final similarity = SimilarityCalculator.calculate(newPara, oldPara);

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
  /// 🔥 FORTALECIDO: Detecta duplicações literais com mais agressividade
  static bool hasLiteralDuplication(String newBlock, String previousContent) {
    if (previousContent.length < 500) {
      return false; // 🔥 REDUZIDO: Era 1000, agora 500
    }

    // 🆕 NOVO: Verificar parágrafos completos duplicados
    final newParagraphs = newBlock
        .split('\n\n')
        .where(
          (p) =>
              p.trim().isNotEmpty && p.trim().split(RegExp(r'\s+')).length > 30,
        )
        .map((p) => p.trim().toLowerCase())
        .toList();

    final prevParagraphs = previousContent
        .split('\n\n')
        .where(
          (p) =>
              p.trim().isNotEmpty && p.trim().split(RegExp(r'\s+')).length > 30,
        )
        .map((p) => p.trim().toLowerCase())
        .toList();

    // 🔥 CRÍTICO: Detectar parágrafos idênticos
    for (final newPara in newParagraphs) {
      for (final prevPara in prevParagraphs) {
        // Similaridade exata
        if (newPara == prevPara) {
          return true;
        }

        // 🆕 Verificar similaridade estrutural (mesmas primeiras 50 palavras)
        final newWords = newPara.split(RegExp(r'\s+'));
        final prevWords = prevPara.split(RegExp(r'\s+'));

        if (newWords.length > 50 && prevWords.length > 50) {
          final newStart = newWords.take(50).join(' ');
          final prevStart = prevWords.take(50).join(' ');

          if (newStart == prevStart) {
            return true;
          }
        }
      }
    }

    // 🔥 Verificação de sequências de palavras (original)
    final newWords = newBlock.split(RegExp(r'\s+'));
    if (newWords.length < 150) return false;

    final prevWords = previousContent.split(RegExp(r'\s+'));
    if (prevWords.length < 150) return false;

    // 🔥 OTIMIZADO: Verificar sequências menores (150 palavras)
    for (int i = 0; i <= newWords.length - 150; i++) {
      final newSequence = newWords.sublist(i, i + 150).join(' ').toLowerCase();

      for (int j = 0; j <= prevWords.length - 150; j++) {
        final prevSequence = prevWords
            .sublist(j, j + 150)
            .join(' ')
            .toLowerCase();

        if (newSequence == prevSequence) {
          return true;
        }
      }
    }

    return false;
  }
}
