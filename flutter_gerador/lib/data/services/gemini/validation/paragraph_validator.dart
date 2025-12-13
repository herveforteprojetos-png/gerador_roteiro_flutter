// 🔧 v7.6.110: Módulo de Validação de Parágrafos (SOLID - SRP)
// Detecta padrões repetitivos em início de parágrafos

import 'package:flutter/foundation.dart';

/// 🎯 Validador de Padrões de Parágrafos
/// Detecta início repetitivo de parágrafos (violação de estilo)
class ParagraphValidator {
  /// 🔍 Detecta se há 3+ parágrafos consecutivos começando com mesmo padrão
  /// Retorna true se houver violação (bloco deve ser rejeitado)
  static bool hasRepetitiveStarts(String blockText) {
    final paragraphs = blockText
        .split(RegExp(r'\n{1,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.length < 3) return false; // Precisa de 3+ parágrafos

    // Detectar padrões comuns de início
    final patterns = <String>[];

    for (final paragraph in paragraphs) {
      final pattern = _extractStartPattern(paragraph);
      patterns.add(pattern);
    }

    // Verificar se há 3+ consecutivos com mesmo padrão
    int consecutiveCount = 1;
    String? lastPattern;

    for (final pattern in patterns) {
      if (pattern == lastPattern && pattern != 'other') {
        consecutiveCount++;
        if (consecutiveCount >= 3) {
          if (kDebugMode) {
            debugPrint('🚨 v7.6.110: INÍCIO REPETITIVO DETECTADO!');
            debugPrint(
              '   Padrão "$pattern" repetido $consecutiveCount vezes consecutivas',
            );
            debugPrint(
              '   ⚠️ VIOLAÇÃO: É PROIBIDO começar 3+ parágrafos com mesmo padrão',
            );
          }
          return true; // Violação detectada
        }
      } else {
        consecutiveCount = 1;
        lastPattern = pattern;
      }
    }

    return false; // Nenhuma violação
  }

  /// 🔍 Extrai padrão de início do parágrafo
  /// Retorna categoria: 'name', 'pronoun', 'article', 'connector', 'other'
  static String _extractStartPattern(String paragraph) {
    if (paragraph.isEmpty) return 'other';

    // Remover aspas/pontuação inicial
    var text = paragraph.trim();
    if (text.startsWith('"') || text.startsWith('—') || text.startsWith('–')) {
      text = text.substring(1).trim();
    }

    final words = text.split(RegExp(r'\s+'));
    if (words.isEmpty) return 'other';

    final firstWord = words[0].toLowerCase();

    // Padrão: Nome próprio (capitalizado)
    if (RegExp(r'^[A-ZÀ-Ü][a-zà-ü]+$').hasMatch(words[0])) {
      // Se segunda palavra também é nome, considerar nome completo
      if (words.length > 1 &&
          RegExp(r'^[A-ZÀ-Ü][a-zà-ü]+$').hasMatch(words[1])) {
        return 'name:${words[0]}_${words[1]}';
      }
      return 'name:${words[0]}';
    }

    // Padrão: Pronomes
    final pronouns = {
      'ele',
      'ela',
      'eles',
      'elas',
      'eu',
      'nós',
      'você',
      'vocês',
    };
    if (pronouns.contains(firstWord)) {
      return 'pronoun:$firstWord';
    }

    // Padrão: Artigos + substantivo
    final articles = {'o', 'a', 'os', 'as', 'um', 'uma', 'uns', 'umas'};
    if (articles.contains(firstWord) && words.length > 1) {
      return 'article:${words[1]}';
    }

    // Padrão: Conectivos (OK - variação desejável)
    final connectors = {
      'de repente',
      'subitamente',
      'naquele instante',
      'no entanto',
      'porém',
      'contudo',
      'todavia',
      'enquanto isso',
      'ao mesmo tempo',
      'segundos depois',
      'apesar',
      'mesmo',
      'embora',
      'quando',
      'depois',
    };

    for (final connector in connectors) {
      if (text.toLowerCase().startsWith(connector)) {
        return 'connector'; // Conectivos são BONS - não contar como repetição
      }
    }

    return 'other';
  }

  /// 📊 Gera relatório de diagnóstico dos padrões de início
  static Map<String, dynamic> analyzeStartPatterns(String fullScript) {
    final paragraphs = fullScript
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final patternCounts = <String, int>{};
    final consecutiveViolations = <String>[];

    String? lastPattern;
    int consecutiveCount = 1;

    for (var i = 0; i < paragraphs.length; i++) {
      final pattern = _extractStartPattern(paragraphs[i]);
      patternCounts[pattern] = (patternCounts[pattern] ?? 0) + 1;

      if (pattern == lastPattern &&
          pattern != 'other' &&
          pattern != 'connector') {
        consecutiveCount++;
        if (consecutiveCount >= 3) {
          consecutiveViolations.add(
            'Parágrafos ${i - consecutiveCount + 2}-${i + 1}: "$pattern" × $consecutiveCount',
          );
        }
      } else {
        consecutiveCount = 1;
        lastPattern = pattern;
      }
    }

    return {
      'totalParagraphs': paragraphs.length,
      'patternCounts': patternCounts,
      'consecutiveViolations': consecutiveViolations,
      'hasViolations': consecutiveViolations.isNotEmpty,
    };
  }

  /// 🛠️ Sugestões de correção para padrões repetitivos
  static List<String> getSuggestions(String repetitivePattern) {
    if (repetitivePattern.startsWith('name:')) {
      return [
        'Use pronomes: "Ele", "Ela", "O funcionário"',
        'Use conectivos: "De repente, ${repetitivePattern.split(':')[1]}..."',
        'Descreva ação: "Com o coração acelerado, ${repetitivePattern.split(':')[1]}..."',
      ];
    }

    if (repetitivePattern.startsWith('pronoun:')) {
      return [
        'Use o nome do personagem',
        'Use conectivos temporais: "Naquele instante, ele..."',
        'Inicie com contexto: "Com medo, ele...", "Sem hesitar, ela..."',
      ];
    }

    return [
      'Varie estruturas de início',
      'Use conectivos de tempo e ação',
      'Alterne entre nome, pronome e contexto',
    ];
  }
}
