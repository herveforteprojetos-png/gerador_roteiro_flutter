/// 📊 Utilitário para contagem de palavras com cache
class WordCounter {
  static final Map<int, int> _wordCountCache = {};
  static const int _maxCacheSize = 50;

  /// Conta palavras em um texto (com cache para performance)
  static int count(String text) {
    final hash = text.hashCode;

    if (_wordCountCache.containsKey(hash)) {
      return _wordCountCache[hash]!;
    }

    final count = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    // Limpar cache se muito grande
    if (_wordCountCache.length > _maxCacheSize) {
      final keysToRemove = _wordCountCache.keys
          .take(_wordCountCache.length - _maxCacheSize ~/ 2)
          .toList();
      for (final key in keysToRemove) {
        _wordCountCache.remove(key);
      }
    }

    _wordCountCache[hash] = count;
    return count;
  }

  /// Limpa o cache de contagem de palavras
  static void clearCache() {
    _wordCountCache.clear();
  }
}
