// 🔧 v7.6.105: Módulo de Construção de Contexto (SOLID - SRP)
// Extraído de gemini_service.dart para Single Responsibility

import 'dart:math';
import 'package:flutter/foundation.dart';

/// 🎯 Módulo de Construção de Contexto
/// Responsável por limitar e otimizar contexto para geração
class ContextBuilder {
  /// 📦 OTIMIZAÇÃO: Limita contexto aos últimos blocos para evitar timeouts
  /// Mantém apenas os últimos N blocos + resumo inicial para continuidade
  ///
  /// [countWords] é uma função para contar palavras (injetada para evitar dependência circular)
  static String buildLimitedContext(
    String fullContext,
    int currentBlock,
    int maxRecentBlocks,
    int Function(String) countWords,
  ) {
    if (fullContext.isEmpty || currentBlock <= maxRecentBlocks) {
      return fullContext; // Blocos iniciais usam tudo
    }

    // ⚡ LIMITE ABSOLUTO OTIMIZADO: Reduzido para evitar timeout em idiomas pesados
    // 🛡️ CRÍTICO: 5.6k palavras causava timeout API 503 nos blocos 7-8
    // 3.5k palavras = ~21k caracteres cirílico (mais seguro para Gemini)
    const maxContextWords = 3500; // REDUZIDO de 4500 para 3500
    final currentWords = countWords(fullContext);

    if (currentWords <= maxContextWords) {
      return fullContext; // Contexto ainda está em tamanho seguro
    }

    // Separar em blocos (parágrafos duplos ou mais)
    final blocks = fullContext.split(RegExp(r'\n{2,}'));
    if (blocks.length <= maxRecentBlocks + 5) {
      return fullContext; // Ainda não tem muitos blocos
    }

    // Pegar resumo inicial (primeiros 3 parágrafos - REDUZIDO de 5 para 3)
    final initialSummary = blocks.take(3).join('\n\n');

    // Pegar últimos N blocos completos (REDUZIDO multiplicador de 5 para 3)
    final recentBlocks = blocks
        .skip(max(0, blocks.length - maxRecentBlocks * 3))
        .join('\n\n');

    final result = '$initialSummary\n\n[...]\n\n$recentBlocks';

    // Verificar se ainda está muito grande
    if (countWords(result) > maxContextWords) {
      // Reduzir ainda mais - só últimos blocos (REDUZIDO multiplicador de 3 para 2)
      return blocks
          .skip(max(0, blocks.length - maxRecentBlocks * 2))
          .join('\n\n');
    }

    return result;
  }

  /// 🔍 Determina número máximo de blocos de contexto por idioma
  static int getMaxContextBlocks(String language) {
    final isPortuguese = language.toLowerCase().contains('portugu');
    // PORTUGUÊS: 3 blocos (mais tokens por palavra)
    // Outros idiomas: 4 blocos (padrão)
    return isPortuguese ? 3 : 4;
  }

  /// 📊 Log de debug para contexto usado
  static void logContextUsage(
    String contextoPrevio,
    int blockNumber,
    int maxContextBlocks,
    int Function(String) countWords,
  ) {
    if (kDebugMode && contextoPrevio.isNotEmpty) {
      final contextUsed = contextoPrevio.length;
      final contextType = blockNumber <= maxContextBlocks
          ? 'COMPLETO'
          : 'LIMITADO (últimos $maxContextBlocks blocos)';
      debugPrint(
        '📦 CONTEXTO $contextType: $contextUsed chars (${countWords(contextoPrevio)} palavras)',
      );
    }
  }
}
