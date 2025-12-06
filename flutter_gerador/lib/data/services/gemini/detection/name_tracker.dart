import 'package:flutter/foundation.dart';

/// 📝 NameTracker - Rastreamento de nomes próprios no roteiro
///
/// Responsável por:
/// - Extrair nomes próprios do texto
/// - Rastrear nomes usados na história
/// - Detectar nomes duplicados
/// - Validar consistência de nomes
///
/// Parte da refatoração SOLID do GeminiService v7.6.66
class NameTracker {
  /// Set de nomes usados na história atual
  final Set<String> _namesUsedInCurrentStory = {};

  /// Palavras comuns em inglês que não são nomes
  static const Set<String> _commonEnglishWords = {
    // Pronomes
    'He', 'She', 'It', 'They', 'We', 'You', 'I',
    // Possessivos
    'My', 'Your', 'His', 'Her', 'Their', 'Our', 'Its',
    // Conjunções
    'And', 'But', 'Or', 'Because', 'So', 'Yet', 'For',
    // Artigos
    'The', 'A', 'An',
    // Preposições comuns
    'In', 'On', 'At', 'To', 'From', 'With', 'By', 'Of', 'As',
    // Advérbios temporais
    'Then', 'When', 'After', 'Before', 'Now', 'Today', 'Tomorrow',
    'Yesterday', 'While', 'During', 'Since', 'Until', 'Although', 'Though',
    // Advérbios de frequência
    'Always', 'Never', 'Often', 'Sometimes', 'Usually', 'Rarely',
    'Maybe', 'Perhaps', 'Almost', 'Just', 'Only', 'Even', 'Still',
    // Quantificadores
    'Much', 'Many', 'Few', 'Little', 'Some', 'Any', 'All', 'Most',
    'Both', 'Each', 'Every', 'Either', 'Neither', 'One', 'Two', 'Three',
    // Outros comuns
    'This', 'That', 'These', 'Those', 'There', 'Here', 'Where',
    'What', 'Which', 'Who', 'Whose', 'Whom', 'Why', 'How',
    // Verbos comuns
    'Was', 'Were', 'Is', 'Are', 'Am', 'Has', 'Have', 'Had',
    'Do', 'Does', 'Did', 'Will', 'Would', 'Could', 'Should',
    'Can', 'May', 'Might', 'Must',
    // Dias da semana
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    // Meses
    'January', 'February', 'March', 'April', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  };

  /// Palavras comuns em português que não são nomes
  static const Set<String> _commonPortugueseWords = {
    'Então', 'Quando', 'Depois', 'Antes', 'Agora', 'Hoje', 'Amanhã',
    'Ontem', 'Naquela', 'Aquela', 'Aquele', 'Naquele', 'Enquanto',
    'Durante', 'Embora', 'Porém', 'Portanto', 'Assim', 'Nunca', 'Sempre',
    'Talvez', 'Quase', 'Apenas', 'Mesmo', 'Também', 'Muito', 'Pouco',
    'Tanto', 'Onde', 'Como', 'Porque', 'Mas', 'Ou', 'Para', 'Com', 'Sem', 'Por',
  };

  /// Palavras comuns em minúsculas (para comparação case-insensitive)
  static const Set<String> _commonLowerWords = {
    'the', 'and', 'but', 'for', 'with', 'from', 'about', 'into',
    'through', 'during', 'before', 'after', 'above', 'below', 'between',
    'under', 'again', 'further', 'then', 'once', 'here', 'there',
    'when', 'where', 'why', 'how', 'all', 'each', 'other', 'some',
    'such', 'only', 'own', 'same', 'than', 'too', 'very', 'can', 'will',
    'just', 'now', 'like', 'back', 'even', 'still', 'also', 'well', 'way',
    'because', 'while', 'since', 'until', 'both', 'was', 'were', 'been',
    'being', 'have', 'has', 'had', 'having', 'does', 'did', 'doing',
    'would', 'could', 'should', 'might', 'must', 'shall', 'may',
  };

  /// Frases comuns que não são nomes de pessoas
  static const Set<String> _commonPhrases = {
    'new york', 'los angeles', 'san francisco', 'las vegas',
    'united states', 'north carolina', 'south carolina',
    'good morning', 'good night', 'good afternoon',
    'thank you', 'excuse me', 'oh my',
    'dear god', 'holy shit', 'oh well',
    'right now', 'just then', 'back then',
    'even though', 'as if', 'so much',
    'too much', 'very much', 'much more',
    // Português
    'são paulo', 'rio de', 'belo horizonte',
    'bom dia', 'boa tarde', 'boa noite',
    'meu deus', 'nossa senhora', 'por favor',
    'de repente', 'de novo', 'tão pouco',
  };

  /// Getter para acessar nomes usados
  Set<String> get namesUsed => Set.unmodifiable(_namesUsedInCurrentStory);

  /// Total de nomes únicos
  int get totalNames => _namesUsedInCurrentStory.length;

  /// Extrai nomes próprios capitalizados do texto
  Set<String> extractNamesFromText(String text) {
    final names = <String>{};

    // 🎯 DETECTAR NOMES COMPOSTOS PRIMEIRO (Arthur Evans, Mary Jane, etc)
    final compoundNamePattern = RegExp(
      r'\b([A-ZÀ-Ü][a-zà-ÿ]{1,14}(?:\s+[A-ZÀ-Ü][a-zà-ÿ]{1,14}){1,2})\b',
      multiLine: true,
    );

    final compoundMatches = compoundNamePattern.allMatches(text);
    final processedWords = <String>{};

    for (final match in compoundMatches) {
      final fullName = match.group(1);
      if (fullName != null && !_isCommonPhrase(fullName)) {
        names.add(fullName);
        // Marcar cada palavra do nome composto como processada
        for (final word in fullName.split(' ')) {
          processedWords.add(word);
        }
      }
    }

    // 🎯 Detectar nomes simples
    final namePattern = RegExp(
      r'\b([A-ZÀ-Ü][a-zà-ÿ]{1,14})\b',
      multiLine: true,
    );

    final matches = namePattern.allMatches(text);

    for (final match in matches) {
      final potentialName = match.group(1);
      if (potentialName != null) {
        // Pular se já processado como parte de nome composto
        if (processedWords.contains(potentialName)) continue;

        // Filtrar palavras comuns
        if (!_commonEnglishWords.contains(potentialName) &&
            !_commonPortugueseWords.contains(potentialName)) {
          names.add(potentialName);
        }
      }
    }

    return names;
  }

  /// Verifica se frase composta é nome real ou expressão comum
  bool _isCommonPhrase(String phrase) {
    return _commonPhrases.contains(phrase.toLowerCase());
  }

  /// Adiciona nomes ao rastreador
  void addNames(String text) {
    final names = extractNamesFromText(text);
    _namesUsedInCurrentStory.addAll(names);

    if (kDebugMode && names.isNotEmpty) {
      debugPrint('📝 Nomes extraídos do bloco: ${names.join(", ")}');
      debugPrint('📊 Total de nomes únicos na história: $totalNames');
    }
  }

  /// Adiciona um nome específico
  void addName(String name) {
    _namesUsedInCurrentStory.add(name);
  }

  /// Adiciona múltiplos nomes
  void addMultipleNames(Iterable<String> names) {
    _namesUsedInCurrentStory.addAll(names);
  }

  /// Verifica se um nome já foi usado
  bool hasName(String name) {
    return _namesUsedInCurrentStory.contains(name);
  }

  /// Reseta o rastreador para nova história
  void reset() {
    _namesUsedInCurrentStory.clear();
    if (kDebugMode) {
      debugPrint('🔄 Rastreador de nomes resetado para nova história');
    }
  }

  /// Valida se há nomes duplicados em papéis diferentes
  List<String> validateNamesInText(String newBlock) {
    final duplicates = <String>[];
    final newNames = extractNamesFromText(newBlock);

    for (final name in newNames) {
      if (_namesUsedInCurrentStory.contains(name)) {
        if (!duplicates.contains(name)) {
          duplicates.add(name);
        }
      }
    }

    // Validação case-insensitive para nomes em minúsculas
    final previousNamesLower =
        _namesUsedInCurrentStory.map((n) => n.toLowerCase()).toSet();

    final lowercasePattern = RegExp(r'\b([a-z][a-z]{1,14})\b');
    final lowercaseMatches = lowercasePattern.allMatches(newBlock);

    for (final match in lowercaseMatches) {
      final word = match.group(1);
      if (word != null && previousNamesLower.contains(word.toLowerCase())) {
        if (!_commonLowerWords.contains(word.toLowerCase())) {
          final originalName = _namesUsedInCurrentStory.firstWhere(
            (n) => n.toLowerCase() == word.toLowerCase(),
            orElse: () => word,
          );

          if (!duplicates.contains(originalName)) {
            duplicates.add(originalName);
            if (kDebugMode) {
              debugPrint(
                '🚨 DUPLICAÇÃO DETECTADA (case-insensitive): "$word" → já existe como "$originalName"',
              );
            }
          }
        }
      }
    }

    return duplicates;
  }

  /// Verifica se uma palavra parece ser um nome próprio
  static bool looksLikePersonName(String value) {
    if (value.isEmpty) return false;

    // Deve começar com maiúscula
    if (!RegExp(r'^[A-ZÀ-Ü]').hasMatch(value)) return false;

    // Deve ter pelo menos 2 caracteres
    if (value.length < 2) return false;

    // Não deve ser palavra comum
    if (_commonEnglishWords.contains(value)) return false;
    if (_commonPortugueseWords.contains(value)) return false;

    return true;
  }

  /// Verifica se texto é provavelmente um nome
  static bool isLikelyName(String text) {
    if (text.isEmpty) return false;

    // Padrão: 1-3 palavras capitalizadas
    final words = text.split(' ');
    if (words.length > 3) return false;

    for (final word in words) {
      if (!RegExp(r'^[A-ZÀ-Ü][a-zà-ÿ]+$').hasMatch(word)) {
        return false;
      }
    }

    return true;
  }
}
