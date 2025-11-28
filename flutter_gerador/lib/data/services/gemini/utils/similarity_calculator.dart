import 'dart:math';

/// 🔍 Calculadora de similaridade entre textos usando n-gramas
class SimilarityCalculator {
  /// Calcula similaridade entre dois textos (0.0 a 1.0)
  /// Usa n-gramas de palavras para detectar similaridade estrutural
  static double calculate(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    final normalized1 = text1.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final normalized2 = text2.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (normalized1 == normalized2) return 1.0;

    const nGramSize = 8;
    final words1 = normalized1.split(' ');
    final words2 = normalized2.split(' ');

    // Fallback para textos muito curtos
    if (words1.length < nGramSize || words2.length < nGramSize) {
      final commonWords = words1.toSet().intersection(words2.toSet()).length;
      return commonWords / max(words1.length, words2.length);
    }

    // Criar n-gramas
    final ngrams1 = <String>{};
    for (int i = 0; i <= words1.length - nGramSize; i++) {
      ngrams1.add(words1.sublist(i, i + nGramSize).join(' '));
    }

    final ngrams2 = <String>{};
    for (int i = 0; i <= words2.length - nGramSize; i++) {
      ngrams2.add(words2.sublist(i, i + nGramSize).join(' '));
    }

    // Jaccard similarity
    final intersection = ngrams1.intersection(ngrams2).length;
    final union = ngrams1.union(ngrams2).length;

    return union > 0 ? intersection / union : 0.0;
  }
}
