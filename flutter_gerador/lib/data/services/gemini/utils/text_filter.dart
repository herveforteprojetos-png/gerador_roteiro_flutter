import 'package:flutter/foundation.dart';

/// 🧹 Filtro de texto para remover parágrafos duplicados
class TextFilter {
  /// Filtra parágrafos duplicados de um texto adicional
  /// Compara com os últimos ~5000 caracteres do texto existente
  static String filterDuplicateParagraphs(String existing, String addition) {
    if (addition.trim().isEmpty) return '';

    // Para textos pequenos, executar direto
    if (existing.length < 3000 && addition.length < 1000) {
      return _filterSync(existing, addition);
    }

    // Textos grandes: seria processado em isolate, mas por simplicidade
    // mantemos síncrono com otimização
    return _filterSync(existing, addition);
  }

  /// Versão síncrona da filtragem (otimizada)
  static String _filterSync(String existing, String addition) {
    if (addition.trim().isEmpty) return '';

    // 🚀 OTIMIZAÇÃO: Comparar apenas últimos ~5000 caracteres
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

  /// 🔍 Detecta parágrafos duplicados no roteiro final (apenas para LOG)
  /// NÃO remove nada, apenas alerta no console para debugging
  static void detectDuplicates(String fullScript) {
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

        if (kDebugMode) {
          debugPrint('⚠️ DUPLICAÇÃO DETECTADA:');
          debugPrint(
            '   📍 Parágrafo #${firstIndex + 1} repetido no parágrafo #${i + 1}',
          );
          debugPrint('   📝 Prévia: "$preview"');
        }
      } else {
        seen[paragraph] = i;
      }
    }

    if (kDebugMode) {
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
  }
}
