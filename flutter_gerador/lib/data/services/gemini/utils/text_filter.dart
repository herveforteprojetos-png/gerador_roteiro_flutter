import 'package:flutter/foundation.dart';

/// 🧹 v7.6.123: Filtro de texto para remover parágrafos duplicados e limitar mantras
/// 🆕 v7.6.123: Limite REDUZIDO para 2x (era 3x) - Flash repete muito
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

  /// 🔧 v7.6.79: Remove TODAS as duplicatas de parágrafos (não apenas consecutivas)
  /// Mantém a primeira ocorrência e remove todas as repetições posteriores
  /// 🆕 v7.6.110: Adiciona detecção de similaridade semântica para variações
  static String removeAllDuplicateParagraphs(String fullScript) {
    final paragraphs = fullScript.split(RegExp(r'\n{2,}'));

    if (paragraphs.length < 2) return fullScript;

    final result = <String>[];
    var removedCount = 0;

    for (var i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i].trim();
      if (paragraph.isEmpty) continue;

      bool isDuplicate = false;

      // Verificar contra todos os parágrafos já aceitos
      for (final acceptedParagraph in result) {
        // 1. DUPLICATA EXATA
        if (paragraph == acceptedParagraph) {
          isDuplicate = true;
          if (kDebugMode) {
            final preview = paragraph.length > 50
                ? '${paragraph.substring(0, 50)}...'
                : paragraph;
            debugPrint('🗑️ REMOVIDO duplicata exata: "$preview"');
          }
          break;
        }

        // 2. DUPLICATA NORMALIZADA (case-insensitive + espaços)
        final normalizedNew = paragraph
            .replaceAll(RegExp(r'\s+'), ' ')
            .toLowerCase();
        final normalizedAccepted = acceptedParagraph
            .replaceAll(RegExp(r'\s+'), ' ')
            .toLowerCase();

        if (normalizedNew == normalizedAccepted) {
          isDuplicate = true;
          if (kDebugMode) {
            debugPrint('🗑️ REMOVIDO duplicata normalizada (case/espaços)');
          }
          break;
        }

        // 3. SIMILARIDADE SEMÂNTICA (>85% similar)
        final similarity = _calculateSimilarity(
          normalizedNew,
          normalizedAccepted,
        );
        if (similarity > 0.85) {
          isDuplicate = true;
          if (kDebugMode) {
            final preview = paragraph.length > 50
                ? '${paragraph.substring(0, 50)}...'
                : paragraph;
            debugPrint(
              '🗑️ REMOVIDO duplicata semântica (${(similarity * 100).toStringAsFixed(1)}% similar): "$preview"',
            );
          }
          break;
        }
      }

      if (!isDuplicate) {
        result.add(paragraph);
      } else {
        removedCount++;
      }
    }

    if (kDebugMode && removedCount > 0) {
      debugPrint(
        '✅ v7.6.110: Total de $removedCount parágrafo(s) duplicado(s) removido(s) (exatos + semânticos)',
      );
    }

    return result.join('\n\n');
  }

  /// 🔍 Calcula similaridade entre dois textos usando algoritmo de Jaccard
  /// Retorna valor entre 0.0 (totalmente diferentes) e 1.0 (idênticos)
  static double _calculateSimilarity(String text1, String text2) {
    // Tokenizar em palavras
    final words1 = text1.split(RegExp(r'\s+'));
    final words2 = text2.split(RegExp(r'\s+'));

    // Criar conjuntos de palavras
    final set1 = words1.toSet();
    final set2 = words2.toSet();

    // Calcular Jaccard similarity: intersecção / união
    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    if (union == 0) return 0.0;

    return intersection / union;
  }

  /// 🚫 Limita repetições excessivas de frases-mantra
  /// Remove ocorrências além do limite especificado
  /// 🆕 v7.6.123: Limite reduzido para 2x (era 3x) - Flash repete muito mais
  static String limitMantraRepetition(
    String fullScript, {
    int maxOccurrences = 2, // 🆕 v7.6.123: Reduzido de 3 para 2
  }) {
    final paragraphs = fullScript.split(RegExp(r'\n{2,}'));
    final result = <String>[];
    var removedCount = 0;

    // 🔍 Detectar frases-mantra comuns (case-insensitive, em qualquer contexto)
    final commonMantras = <String, int>{};

    // 🆕 v7.6.122: Padrões expandidos de frases-mantra frequentes
    final mantraPatterns = [
      // Padrões sobre riqueza (CRÍTICO - muito repetido)
      r'a verdadeira riqueza não se mede',
      r'a verdadeira riqueza está no que você',
      r'a verdadeira riqueza não está no que se',
      r'a verdadeira riqueza se multiplica',
      r'verdadeira riqueza.*compartilh',
      r'verdadeira riqueza.*acumular',
      r'verdadeira riqueza.*impactar',
      r'verdadeira riqueza.*guarda.*divide',
      r'verdadeira riqueza.*semeia',
      r'verdadeira riqueza.*constr[oó]i',
      r'não está no que se acumula.*semeia',
      r'não se mede pelo que.*guarda',
      // Padrões sobre bondade/gentileza
      r'a gentileza é uma semente',
      r'gentileza.*cresce.*solo fértil',
      r'gentileza.*frutos inesperados',
      r'semente.*bondade.*floresce',
      r'a bondade sempre volta',
      r'a semente da bondade[^.]*floresce',
      r'o maior poder[^.]*coração',
      // Padrões sobre avô/pai (CRÍTICO - confusão avô/pai)
      r'meu avô (sempre )?diz(ia)?',
      r'meu pai (sempre )?diz(ia)?',
      r'como (meu )?avô (sempre )?ensinava',
      r'lembr(ou|ava|ei)(-se)? das palavras (de seu|do) (avô|pai)',
      r'palavras.*s[aá]bias.*av[oô]',
      r'palavras de (otávio|seu mentor)',
      // Padrões sobre propósito/jornada
      r'havia encontrado seu (verdadeiro )?propósito',
      r'era o jardineiro.*sementes',
      r'a cada amanhecer.*gratidão',
      r'marmita simb[oó]lica.*partilha',
      // 🆕 v7.6.122: Novos padrões detectados no roteiro
      r'plantava uma nova semente',
      r'a cada (novo )?passo.*semente',
      r'o teste de otávio (continuava|não tinha fim)',
      r'teste.*continuava.*outras formas',
      r'fazer (a )?santa clara florescer',
      r'chaminés.*soltando fumaça',
      r'sentiria o gosto da vitória',
      r'semear.*futuro',
      r'construir com o coração',
      r'constrói.*coração',
      // Outros padrões comuns
      r'o crime paga um preço',
      r'não é sobre o que você tem',
      r'as consequências sempre chegam',
      r'prova viva de que',
    ];

    // Contar ocorrências de cada mantra no roteiro completo
    for (final pattern in mantraPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(fullScript);
      if (matches.isNotEmpty) {
        commonMantras[pattern] = matches.length;
      }
    }

    // Filtrar parágrafos removendo excedentes
    for (final paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      bool shouldRemove = false;

      // Verificar se parágrafo contém mantra que excedeu limite
      for (final entry in commonMantras.entries) {
        final pattern = entry.key;
        final totalCount = entry.value;

        if (totalCount > maxOccurrences) {
          final regex = RegExp(pattern, caseSensitive: false);
          if (regex.hasMatch(paragraph)) {
            // Contar quantas vezes já vimos este mantra
            final currentOccurrence =
                result.where((p) => regex.hasMatch(p)).length + 1;

            if (currentOccurrence > maxOccurrences) {
              shouldRemove = true;
              if (kDebugMode) {
                final preview = paragraph.length > 60
                    ? '${paragraph.substring(0, 60)}...'
                    : paragraph;
                debugPrint(
                  '🚫 REMOVIDO parágrafo #$currentOccurrence com mantra excedente (padrão: "$pattern"): "$preview"',
                );
              }
              break;
            }
          }
        }
      }

      if (!shouldRemove) {
        result.add(paragraph);
      } else {
        removedCount++;
      }
    }

    if (kDebugMode && removedCount > 0) {
      debugPrint(
        '✅ v7.6.111: $removedCount parágrafo(s) com frases-mantra excedentes removido(s)',
      );
      debugPrint('📊 Mantras detectados:');
      for (final entry in commonMantras.entries) {
        if (entry.value > maxOccurrences) {
          debugPrint(
            '   - "${entry.key}": ${entry.value}x (limite: $maxOccurrences) ⚠️',
          );
        }
      }
    }

    return result.join('\n\n');
  }

  /// 🚨 v7.6.114: Detecta se um bloco está recomeçando a história do início
  /// Compara as primeiras frases do bloco com as primeiras frases do contexto completo
  /// Retorna true se detectar reinício (deve rejeitar o bloco)
  static bool isRestartingStory(String newBlock, String fullContext) {
    if (fullContext.isEmpty || newBlock.isEmpty) return false;

    // Extrair primeiras 3 sentenças do contexto completo (o início da história)
    final contextSentences = _extractFirstSentences(fullContext, 5);
    if (contextSentences.isEmpty) return false;

    // Extrair primeiras 3 sentenças do novo bloco
    final blockSentences = _extractFirstSentences(newBlock, 3);
    if (blockSentences.isEmpty) return false;

    // Verificar se alguma sentença do novo bloco é muito similar ao início
    int matchCount = 0;
    for (final blockSentence in blockSentences) {
      for (final contextSentence in contextSentences) {
        final similarity = _calculateSimilarity(
          blockSentence.toLowerCase(),
          contextSentence.toLowerCase(),
        );
        if (similarity > 0.70) {
          matchCount++;
          if (kDebugMode) {
            debugPrint(
              '🚨 REINÍCIO DETECTADO: Bloco reutiliza início da história!',
            );
            debugPrint(
              '   Nova: "${blockSentence.substring(0, blockSentence.length > 50 ? 50 : blockSentence.length)}..."',
            );
            debugPrint(
              '   Original: "${contextSentence.substring(0, contextSentence.length > 50 ? 50 : contextSentence.length)}..."',
            );
            debugPrint(
              '   Similaridade: ${(similarity * 100).toStringAsFixed(1)}%',
            );
          }
          break;
        }
      }
    }

    // Se 2+ sentenças do início do bloco são similares ao início do contexto = reinício
    return matchCount >= 2;
  }

  /// Extrai as primeiras N sentenças de um texto
  static List<String> _extractFirstSentences(String text, int count) {
    // Separar por pontuação final (., !, ?)
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 20) // Ignorar sentenças muito curtas
        .take(count)
        .toList();
    return sentences;
  }
}
