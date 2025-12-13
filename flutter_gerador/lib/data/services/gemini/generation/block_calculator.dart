// 🔧 v7.6.121: Módulo de Cálculo de Blocos (SOLID - SRP)
// 🆕 v7.6.121: Lógica híbrida Flash/Pro - Flash usa blocos menores (~900 pal)
// 🆕 v7.6.126: Suporte ao Gemini 3.0 Ultra com blocos maiores (+20%)
// Extraído de gemini_service.dart para Single Responsibility

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/services/prompts/block_prompt_builder.dart';

/// 🏷️ Categorias linguísticas para cálculo de blocos
enum LanguageCategory {
  /// Idiomas latinos: Português, Inglês, Espanhol, Francês, Italiano, Romeno
  latino,

  /// Idiomas cirílicos: Russo, Búlgaro
  cirilico,

  /// Idioma coreano (한국어) - Alfabeto Hangul
  hangul,

  /// Idiomas com diacríticos pesados: Alemão, Polonês, Turco
  diacriticos,
}

/// 🎯 Módulo de Cálculo de Blocos
/// Responsável por calcular quantidade e tamanho de blocos para geração
class BlockCalculator {
  /// Lista de fases narrativas
  static const List<String> phases = [
    'Preparação',
    'Introdução',
    'Desenvolvimento',
    'Clímax',
    'Resolução',
    'Finalização',
  ];

  /// 📖 Determina a fase narrativa baseada no progresso (0.0 a 1.0)
  static String getPhase(double progress) {
    final phaseIdx = progress <= 0.15
        ? 0
        : progress <= 0.35
        ? 1
        : progress <= 0.65
        ? 2
        : progress <= 0.80
        ? 3
        : progress <= 0.95
        ? 4
        : 5;
    return phases[phaseIdx];
  }

  /// 🔍 Verifica se a meta foi atingida com tolerância
  /// 🆕 v7.6.121: Tolerância maior para Flash (mais blocos menores)
  static bool checkTargetMet(String text, ScriptConfig c) {
    // 🔍 Flash usa tolerância maior pois trabalha com mais blocos
    final isFlash = c.qualityMode.toLowerCase().contains('flash');

    if (c.measureType == 'caracteres') {
      // Flash: 3% tolerância | Pro: 0.5% tolerância
      final tolerancePercent = isFlash ? 0.03 : 0.005;
      final minTol = isFlash ? 100 : 50;
      final tol = max(minTol, (c.quantity * tolerancePercent).round());
      return text.length >= (c.quantity - tol);
    }

    final wc = countWords(text);
    // Flash: 5% tolerância | Pro: 1% tolerância
    final tolerancePercent = isFlash ? 0.05 : 0.01;
    final minTol = isFlash ? 30 : 10;
    final tol = max(minTol, (c.quantity * tolerancePercent).round());
    return wc >= (c.quantity - tol);
  }

  /// 📊 Conta palavras em um texto
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// 🏷️ Determina a categoria linguística de um idioma
  ///
  /// Mapeia idiomas para categorias que afetam o cálculo de blocos:
  /// - latino: Idiomas com alfabeto latino simples
  /// - cirilico: Alfabeto cirílico (caracteres mais pesados)
  /// - hangul: Alfabeto coreano (alta densidade silábica)
  /// - diacriticos: Idiomas com acentuação pesada
  static LanguageCategory getCategory(String language) {
    final lang = language.toLowerCase();

    // 🇧🇷 LATINO: Português, Inglês, Espanhol, Francês, Italiano, Romeno
    if (lang.contains('português') ||
        lang.contains('portugues') ||
        lang.contains('inglês') ||
        lang.contains('ingles') ||
        lang.contains('english') ||
        lang.contains('español') ||
        lang.contains('espanhol') ||
        lang.contains('francês') ||
        lang.contains('frances') ||
        lang.contains('français') ||
        lang.contains('italiano') ||
        lang.contains('italian') ||
        lang.contains('romeno') ||
        lang.contains('român')) {
      return LanguageCategory.latino;
    }

    // 🇷🇺 CIRÍLICO: Russo, Búlgaro
    if (lang.contains('russo') ||
        lang.contains('russian') ||
        lang.contains('búlgar') ||
        lang.contains('bulgar') ||
        lang.contains('bulgarian')) {
      return LanguageCategory.cirilico;
    }

    // 🇰🇷 HANGUL: Coreano
    if (language.contains('한국어') ||
        lang.contains('coreano') ||
        lang.contains('korean')) {
      return LanguageCategory.hangul;
    }

    // 🌍 DIACRÍTICOS: Alemão, Polonês, Turco
    if (lang.contains('alemão') ||
        lang.contains('alemao') ||
        lang.contains('german') ||
        lang.contains('polonês') ||
        lang.contains('polones') ||
        lang.contains('polish') ||
        lang.contains('turco') ||
        lang.contains('turkish')) {
      return LanguageCategory.diacriticos;
    }

    // Default: latino
    return LanguageCategory.latino;
  }

  /// 🎯 Calcula o target de palavras por bloco baseado em idioma e modelo
  ///
  /// Multiplicadores por modelo:
  /// - Ultra (3.0): 1.20x (blocos 20% maiores que Pro)
  /// - Pro (2.5): 1.00x (referência base)
  /// - Flash (2.5): 0.67x (blocos 33% menores que Pro)
  ///
  /// Targets base por categoria:
  /// - Latino: 1350 palavras/bloco (Pro)
  /// - Cirílico: 1000 palavras/bloco (Pro)
  /// - Hangul: 700 palavras/bloco (Pro)
  /// - Diacríticos: 1100 palavras/bloco (Pro)
  static double getTargetPalBloco(ScriptConfig c) {
    final category = getCategory(c.language);

    // 📊 Target base por categoria (valores para Pro)
    final int baseTarget;
    switch (category) {
      case LanguageCategory.latino:
        baseTarget = 1350;
        break;
      case LanguageCategory.cirilico:
        baseTarget = 1000;
        break;
      case LanguageCategory.hangul:
        baseTarget = 700;
        break;
      case LanguageCategory.diacriticos:
        baseTarget = 1100;
        break;
    }

    // 🔍 Detectar modelo e aplicar multiplicador
    final qualityLower = c.qualityMode.toLowerCase();

    if (qualityLower.contains('flash')) {
      // ⚡ FLASH: Blocos menores (67% do Pro)
      return baseTarget * 0.67;
    } else if (qualityLower.contains('ultra')) {
      // 🚀 ULTRA: Blocos maiores (120% do Pro)
      return baseTarget * 1.20;
    } else {
      // 🎯 PRO: Target base (100%)
      return baseTarget.toDouble();
    }
  }

  /// 📦 Calcula número total de blocos necessários
  static int calculateTotalBlocks(ScriptConfig c) {
    // 🔄 NORMALIZAÇÃO: Converter tudo para palavras equivalentes
    final isKoreanMeasure =
        c.language.contains('한국어') ||
        c.language.toLowerCase().contains('coreano') ||
        c.language.toLowerCase().contains('korean');

    // 🚨 v7.6.158: Usar ratio específico por idioma (2.5-6.5 range)
    final charToWordRatio = c.measureType == 'caracteres'
        ? (isKoreanMeasure 
            ? 4.2 // Coreano em modo caracteres (legacy)
            : BlockPromptBuilder.getCharsPerWordForLanguage(c.language))
        : BlockPromptBuilder.getCharsPerWordForLanguage(c.language);

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

    // 📊 USAR NOVA LÓGICA DE TARGET POR IDIOMA E MODELO
    // 🆕 v7.6.126: Refatorado para usar getTargetPalBloco com suporte Ultra
    final double targetPalBloco = getTargetPalBloco(c);
    final category = getCategory(c.language);

    // 🏷️ Label para debug
    String langCategory;
    final qualityLower = c.qualityMode.toLowerCase();

    if (qualityLower.contains('ultra')) {
      langCategory = '🚀 ${category.name.toUpperCase()} (ULTRA)';
    } else if (qualityLower.contains('flash')) {
      langCategory = '⚡ ${category.name.toUpperCase()} (FLASH)';
    } else {
      langCategory = '🎯 ${category.name.toUpperCase()} (PRO)';
    }

    // 📦 CÁLCULO DE BLOCOS
    int calculatedBlocks = (wordsEquivalent / targetPalBloco).ceil();

    // 🛡️ LIMITES DE SEGURANÇA
    int minBlocks = 2;
    int maxBlocks;

    // Definir maxBlocks baseado na categoria
    if (category == LanguageCategory.hangul) {
      maxBlocks =
          35; // Coreano v7.6.135: reduzido (gera mais palavras por bloco)
    } else if (category == LanguageCategory.cirilico) {
      maxBlocks = 30; // Cirílico: limite intermediário
    } else {
      maxBlocks = 25; // Padrão para latinos e diacríticos
    }

    int finalBlocks = calculatedBlocks.clamp(minBlocks, maxBlocks);

    // 🇰🇷 CORREÇÃO COREANO v7.6.135: -16%
    // Coreano gera ~40% MAIS palavras que o esperado (Hangul denso)
    // Reduzir blocos para compensar a sobre-geração
    if (category == LanguageCategory.hangul) {
      finalBlocks = (finalBlocks * 0.72).ceil().clamp(minBlocks, maxBlocks);
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
  /// 🆕 v7.6.121: Limites menores para Flash
  static int calculateTargetForBlock(int current, int total, ScriptConfig c) {
    final isKoreanTarget =
        c.language.contains('한국어') ||
        c.language.toLowerCase().contains('coreano') ||
        c.language.toLowerCase().contains('korean');

    // 🔍 Flash usa limites menores por bloco
    final isFlash = c.qualityMode.toLowerCase().contains('flash');

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
    // 🆕 v7.6.121: Flash usa limites menores para evitar timeout
    final int maxBlockSize;
    if (c.measureType == 'caracteres') {
      maxBlockSize = isFlash ? 8000 : 15000;
    } else {
      maxBlockSize = isFlash ? 1200 : 5000; // Flash: ~1200 palavras max
    }

    // Para o último bloco, usar o multiplicador ajustado
    if (current == total) {
      final wordsPerBlock = (targetQuantity / total).ceil();
      return min((wordsPerBlock * multiplier).round(), maxBlockSize);
    }

    return baseTarget > maxBlockSize ? maxBlockSize : baseTarget;
  }
}
