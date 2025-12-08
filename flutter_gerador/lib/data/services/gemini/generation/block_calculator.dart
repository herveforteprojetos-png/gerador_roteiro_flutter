// 🔧 v7.6.104: Módulo de Cálculo de Blocos (SOLID - SRP)
// Extraído de gemini_service.dart para Single Responsibility

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_gerador/data/models/script_config.dart';

/// 🎯 Módulo de Cálculo de Blocos
/// Responsável por calcular quantidade e tamanho de blocos para geração
class BlockCalculator {
  /// 🔍 Verifica se a meta foi atingida com tolerância
  static bool checkTargetMet(String text, ScriptConfig c) {
    if (c.measureType == 'caracteres') {
      // TOLERÂNCIA ZERO: Só aceita se atingir pelo menos 99.5% da meta
      final tol = max(
        50,
        (c.quantity * 0.005).round(),
      ); // Máximo 0.5% ou 50 chars, o que for maior
      return text.length >= (c.quantity - tol);
    }
    final wc = countWords(text);
    // TOLERÂNCIA ZERO: Só aceita se atingir pelo menos 99% da meta
    final tol = max(
      10,
      (c.quantity * 0.01).round(),
    ); // Máximo 1% ou 10 palavras, o que for maior
    return wc >= (c.quantity - tol);
  }

  /// 📊 Conta palavras em um texto
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// 📦 Calcula número total de blocos necessários
  static int calculateTotalBlocks(ScriptConfig c) {
    // 🔄 NORMALIZAÇÃO: Converter tudo para palavras equivalentes
    final isKoreanMeasure =
        c.language.contains('한국어') ||
        c.language.toLowerCase().contains('coreano') ||
        c.language.toLowerCase().contains('korean');

    final charToWordRatio = (c.measureType == 'caracteres' && isKoreanMeasure)
        ? 4.2 // Coreano: alta densidade silábica
        : 5.5; // Outros idiomas: padrão

    int wordsEquivalent = c.measureType == 'caracteres'
        ? (c.quantity / charToWordRatio).round()
        : c.quantity;

    if (kDebugMode) {
      debugPrint('📊 CÁLCULO DE BLOCOS (DEBUG):');
      debugPrint('   Idioma: "${c.language}"');
      debugPrint('   IsKoreanMeasure? $isKoreanMeasure');
      debugPrint('   Ratio: $charToWordRatio');
      debugPrint('   WordsEquivalent: $wordsEquivalent');
    }

    // ⚡ AJUSTE AUTOMÁTICO PARA IDIOMAS COM ALFABETOS PESADOS
    final cyrillicLanguages = ['Russo', 'Búlgaro', 'Sérvio'];
    final otherNonLatinLanguages = ['Hebraico', 'Grego', 'Tailandês'];
    final heavyDiacriticLanguages = [
      'Turco',
      'Polonês',
      'Tcheco',
      'Vietnamita',
      'Húngaro',
    ];

    if (c.measureType == 'caracteres' && wordsEquivalent > 6000) {
      double adjustmentFactor = 1.0;
      String adjustmentLevel = '';

      if (cyrillicLanguages.contains(c.language)) {
        adjustmentFactor = 0.88; // -12%
        adjustmentLevel = 'CIRÍLICO';
      } else if (otherNonLatinLanguages.contains(c.language)) {
        adjustmentFactor = 0.85; // -15%
        adjustmentLevel = 'NÃO-LATINO';
      } else if (heavyDiacriticLanguages.contains(c.language)) {
        adjustmentFactor = 0.92; // -8%
        adjustmentLevel = 'DIACRÍTICOS';
      }

      if (adjustmentFactor < 1.0) {
        final originalWords = wordsEquivalent;
        wordsEquivalent = (wordsEquivalent * adjustmentFactor).round();
        if (kDebugMode) {
          debugPrint('⚡ AJUSTE $adjustmentLevel (CARACTERES): ${c.language}');
          debugPrint(
            '   $originalWords → $wordsEquivalent palavras equiv. (${(adjustmentFactor * 100).toInt()}%)',
          );
        }
      }
    }

    final langLower = c.language.toLowerCase();

    // 🔍 DETECÇÃO DE IDIOMA
    final isPortuguese = langLower.contains('portugu') || langLower == 'pt';
    final isKorean =
        c.language.contains('한국어') ||
        langLower.contains('coreano') ||
        langLower.contains('korean') ||
        langLower == 'ko';
    final isRussian = langLower.contains('russo') || langLower == 'ru';
    final isBulgarian =
        langLower.contains('búlgar') ||
        langLower.contains('bulgar') ||
        langLower == 'bg';
    final isCyrillic = isRussian || isBulgarian;
    final isTurkish = langLower.contains('turco') || langLower == 'tr';
    final isPolish = langLower.contains('polon') || langLower == 'pl';
    final isGerman = langLower.contains('alem') || langLower == 'de';
    final isLatin =
        langLower.contains('inglês') ||
        langLower.contains('english') ||
        langLower == 'en' ||
        langLower.contains('espanhol') ||
        langLower.contains('español') ||
        langLower.contains('es') ||
        langLower.contains('francês') ||
        langLower.contains('français') ||
        langLower == 'fr' ||
        langLower.contains('italiano') ||
        langLower == 'it' ||
        langLower.contains('romeno') ||
        langLower.contains('român') ||
        langLower == 'ro';

    // 📊 TARGET DE PALAVRAS POR BLOCO
    int targetPalBloco;
    String langCategory;

    if (isKorean) {
      targetPalBloco = 700;
      langCategory = '🇰🇷 COREANO';
    } else if (isCyrillic) {
      targetPalBloco = 1000;
      langCategory = '🇷🇺 CIRÍLICO';
    } else if (isTurkish) {
      targetPalBloco = 1100;
      langCategory = '🇹🇷 TURCO';
    } else if (isPolish) {
      targetPalBloco = 1100;
      langCategory = '🇵🇱 POLONÊS';
    } else if (isGerman) {
      targetPalBloco = 1100;
      langCategory = '🇩🇪 ALEMÃO';
    } else if (isPortuguese) {
      targetPalBloco = 1350;
      langCategory = '🇧🇷 PORTUGUÊS';
    } else if (isLatin) {
      targetPalBloco = 1350;
      langCategory = '🌍 LATINO';
    } else {
      targetPalBloco = 1200;
      langCategory = '🌐 OUTROS';
    }

    // 📦 CÁLCULO DE BLOCOS
    int calculatedBlocks = (wordsEquivalent / targetPalBloco).ceil();

    // 🛡️ LIMITES DE SEGURANÇA
    int minBlocks = 2;
    int maxBlocks;

    if (isKorean) {
      maxBlocks = 50;
    } else if (isCyrillic) {
      maxBlocks = 30;
    } else {
      maxBlocks = 25;
    }

    int finalBlocks = calculatedBlocks.clamp(minBlocks, maxBlocks);

    // 🇰🇷 COMPENSAÇÃO COREANO: +18%
    if (isKorean) {
      finalBlocks = (finalBlocks * 1.18).ceil().clamp(minBlocks, maxBlocks);
    }

    if (kDebugMode) {
      final actualPalBloco = (wordsEquivalent / finalBlocks).round();
      debugPrint(
        '   $langCategory: $wordsEquivalent palavras → $targetPalBloco target = $calculatedBlocks → $finalBlocks blocos (~$actualPalBloco pal/bloco)',
      );
    }

    return finalBlocks;
  }

  /// 🎯 Calcula target de palavras para um bloco específico
  static int calculateTargetForBlock(int current, int total, ScriptConfig c) {
    final isKoreanTarget =
        c.language.contains('한국어') ||
        c.language.toLowerCase().contains('coreano') ||
        c.language.toLowerCase().contains('korean');

    final charToWordRatio = (c.measureType == 'caracteres' && isKoreanTarget)
        ? 4.2
        : 5.5;

    int targetQuantity = c.measureType == 'caracteres'
        ? (c.quantity / charToWordRatio).round()
        : c.quantity;

    // ⚡ Ajustes de idioma para caracteres
    if (c.measureType == 'caracteres' && targetQuantity > 6000) {
      final cyrillicLanguages = ['Russo', 'Búlgaro', 'Sérvio'];
      final otherNonLatinLanguages = ['Hebraico', 'Grego', 'Tailandês'];
      final heavyDiacriticLanguages = [
        'Turco',
        'Polonês',
        'Tcheco',
        'Vietnamita',
        'Húngaro',
      ];

      if (cyrillicLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.88).round();
      } else if (otherNonLatinLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.85).round();
      } else if (heavyDiacriticLanguages.contains(c.language)) {
        targetQuantity = (targetQuantity * 0.92).round();
      }
    }

    // 📊 Multiplicador por idioma
    double multiplier;
    if (isKoreanTarget) {
      multiplier = 1.18; // Compensar sub-geração de ~15%
    } else if (c.language.toLowerCase().contains('portugu')) {
      multiplier = 1.05;
    } else {
      multiplier = 1.05;
    }

    // Calcular target acumulado até este bloco
    final cumulativeTarget = (targetQuantity * (current / total) * multiplier)
        .round();

    // Calcular target acumulado do bloco anterior
    final previousCumulativeTarget = current > 1
        ? (targetQuantity * ((current - 1) / total) * multiplier).round()
        : 0;

    // DELTA = palavras necessárias NESTE bloco específico
    final baseTarget = cumulativeTarget - previousCumulativeTarget;

    // LIMITES por bloco individual
    final maxBlockSize = c.measureType == 'caracteres' ? 15000 : 5000;

    // Para o último bloco, usar o multiplicador ajustado
    if (current == total) {
      final wordsPerBlock = (targetQuantity / total).ceil();
      return min((wordsPerBlock * multiplier).round(), maxBlockSize);
    }

    return baseTarget > maxBlockSize ? maxBlockSize : baseTarget;
  }
}
