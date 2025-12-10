import 'package:flutter/foundation.dart';

/// 🧹 TextCleaner - Limpeza e processamento de texto gerado
///
/// Responsável por:
/// - Limpar texto gerado (remover marcadores, linhas vazias)
/// - Filtrar parágrafos duplicados
/// - Remover duplicatas do roteiro final
/// - Detectar duplicações para logging
///
/// Parte da refatoração SOLID do GeminiService v7.6.66
class TextCleaner {
  /// Limpa texto gerado removendo marcadores e formatação indesejada
  static String cleanGeneratedText(String text) {
    return text
        // Remove "CONTINUAÇÃO:" no início ou meio do texto
        .replaceAll(RegExp(r'CONTINUAÇÃO:\s*', caseSensitive: false), '')
        // Remove "CONTEXTO FINAL:" se aparecer
        .replaceAll(RegExp(r'CONTEXTO FINAL:\s*', caseSensitive: false), '')
        // Remove linhas vazias duplas
        .replaceAll(RegExp(r'\n\n\n+'), '\n\n')
        // Remove espaços desnecessários no início
        .trim();
  }

  /// Filtra parágrafos duplicados de um texto em relação ao existente
  /// Versão síncrona para textos pequenos
  static String filterDuplicateParagraphsSync(
    String existing,
    String addition,
  ) {
    if (addition.trim().isEmpty) return '';

    // 🚀 OTIMIZAÇÃO CRÍTICA: Comparar apenas últimos ~5000 caracteres
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

  /// Remove TODAS as duplicatas de parágrafos (não apenas consecutivas)
  /// Mantém a primeira ocorrência e remove todas as repetições posteriores
  static String removeAllDuplicateParagraphs(String fullScript) {
    final paragraphs = fullScript.split(RegExp(r'\n{2,}'));

    if (paragraphs.length < 2) return fullScript;

    final seen = <String>{};
    final seenNormalized = <String>{};
    final result = <String>[];
    var removedCount = 0;

    for (final rawParagraph in paragraphs) {
      final paragraph = rawParagraph.trim();

      if (paragraph.isEmpty) continue;

      // Normalizar para comparação (ignorar espaços extras)
      final normalized = paragraph
          .replaceAll(RegExp(r'\s+'), ' ')
          .toLowerCase();

      // Verificar duplicata exata
      if (seen.contains(paragraph)) {
        removedCount++;
        if (kDebugMode) {
          final preview = paragraph.length > 50
              ? '${paragraph.substring(0, 50)}...'
              : paragraph;
          debugPrint('🧹 REMOVIDO duplicata exata: "$preview"');
        }
        continue;
      }

      // Verificar duplicata normalizada (ignora case e espaços)
      if (seenNormalized.contains(normalized)) {
        removedCount++;
        if (kDebugMode) {
          debugPrint('🧹 REMOVIDO duplicata similar (case/espaços diferentes)');
        }
        continue;
      }

      seen.add(paragraph);
      seenNormalized.add(normalized);
      result.add(paragraph);
    }

    if (removedCount > 0 && kDebugMode) {
      debugPrint(
        '✅ TextCleaner: Total de $removedCount parágrafo(s) duplicado(s) removido(s)',
      );
    }

    return result.join('\n\n');
  }

  /// 🔍 Detecta parágrafos duplicados no roteiro final (apenas para LOG)
  /// NÃO remove nada, apenas alerta no console para debugging
  static void detectDuplicateParagraphsInFinalScript(String fullScript) {
    if (!kDebugMode) return;

    final paragraphs = fullScript
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final seen = <String, int>{};
    var duplicateCount = 0;

    for (var i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];

      if (seen.containsKey(paragraph)) {
        duplicateCount++;
        final firstIndex = seen[paragraph]!;
        final preview = paragraph.length > 80
            ? '${paragraph.substring(0, 80)}...'
            : paragraph;

        debugPrint('⚠️ DUPLICAÇÃO DETECTADA:');
        debugPrint(
          '   📍 Parágrafo #${firstIndex + 1} repetido no parágrafo #${i + 1}',
        );
        debugPrint('   📝 Prévia: "$preview"');
      } else {
        seen[paragraph] = i;
      }
    }

    if (duplicateCount > 0) {
      debugPrint(
        '🚨 TOTAL: $duplicateCount parágrafo(s) duplicado(s) encontrado(s) no roteiro final!',
      );
      debugPrint(
        '   💡 DICA: Fortaleça as instruções anti-repetição no prompt',
      );
    } else {
      debugPrint(
        '✅ VERIFICAÇÃO: Nenhuma duplicação de parágrafo detectada no roteiro final',
      );
    }
  }

  /// Remove múltiplas quebras de linha consecutivas
  static String normalizeLineBreaks(String text) {
    return text
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .trim();
  }

  /// Remove espaços extras dentro de parágrafos
  static String normalizeSpaces(String text) {
    return text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  }

  /// Conta palavras em um texto (com cache para performance)
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  /// Trunca texto para um número máximo de caracteres
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Remove marcadores de bloco como [BLOCO X] ou (BLOCO X)
  static String removeBlockMarkers(String text) {
    return text
        .replaceAll(RegExp(r'\[BLOCO\s*\d+\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(BLOCO\s*\d+\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'BLOCO\s*\d+:', caseSensitive: false), '')
        .trim();
  }

  /// Remove instruções de prompt que vazaram para o texto
  static String removeLeakedPromptInstructions(String text) {
    return text
        .replaceAll(RegExp(r'INSTRUÇÃO:\s*[^\n]+\n?', caseSensitive: false), '')
        .replaceAll(RegExp(r'NOTA:\s*[^\n]+\n?', caseSensitive: false), '')
        .replaceAll(RegExp(r'ATENÇÃO:\s*[^\n]+\n?', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'IMPORTANTE:\s*[^\n]+\n?', caseSensitive: false),
          '',
        )
        .trim();
  }
}

// ============================================================================
// 🚀 FUNÇÕES TOP-LEVEL PARA ISOLATE
// ============================================================================

/// Função top-level para filtrar parágrafos duplicados em Isolate
String filterDuplicateParagraphsIsolate(Map<String, dynamic> params) {
  final String existing = params['existing'] as String;
  final String addition = params['addition'] as String;
  return TextCleaner.filterDuplicateParagraphsSync(existing, addition);
}
