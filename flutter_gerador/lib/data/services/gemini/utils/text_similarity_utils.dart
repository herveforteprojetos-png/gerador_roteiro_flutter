import 'dart:math';

/// ?? FUNÇÃO TOP-LEVEL para filtrar parágrafos duplicados em Isolate
String filterDuplicateParagraphsStatic(Map<String, dynamic> params) {
  final String existing = params['existing'] as String;
  final String addition = params['addition'] as String;

  if (addition.trim().isEmpty) return '';

  // Comparar apenas últimos ~5000 caracteres
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

/// ?? FUNÇÃO TOP-LEVEL para execução em Isolate separado
/// Evita travar UI thread durante verificação de repetição
Map<String, dynamic> isTooSimilarInIsolate(Map<String, dynamic> params) {
  final String newBlock = params['newBlock'] as String;
  final String previousContent = params['previousContent'] as String;
  final double threshold = params['threshold'] as double;

  if (previousContent.isEmpty) {
    return {'isSimilar': false, 'reason': 'No previous content'};
  }

  // ?? PRIORIDADE 1: Verificar duplicação literal de blocos grandes
  final hasLiteral = hasLiteralDuplicationStatic(newBlock, previousContent);
  if (hasLiteral) {
    return {'isSimilar': true, 'reason': 'Literal duplication detected'};
  }

  // ?? OTIMIZAÇÃO: Limitar contexto anterior para comparação
  final limitedPrevious = previousContent.length > 12000
      ? previousContent.substring(previousContent.length - 12000)
      : previousContent;

  // Dividir conteúdo anterior em parágrafos
  final paragraphs = limitedPrevious
      .split('\n\n')
      .where((p) => p.trim().isNotEmpty)
      .toList();

  // ?? OTIMIZAÇÃO CRÍTICA: Limitar a 10 últimos parágrafos
  final recentParagraphs = paragraphs.length > 10
      ? paragraphs.sublist(paragraphs.length - 10)
      : paragraphs;

  // Dividir novo bloco em parágrafos
  final newParagraphs = newBlock
      .split('\n\n')
      .where((p) => p.trim().isNotEmpty)
      .toList();

  // ?? AJUSTE FINO: Verificar cada parágrafo novo contra os RECENTES
  int highSimilarityCount = 0;

  for (final newPara in newParagraphs) {
    // ?? AJUSTE: Detectar parágrafos de 50+ palavras (era 100)
    final wordCount = newPara.trim().split(RegExp(r'\s+')).length;
    if (wordCount < 50) continue; // Ignorar parágrafos muito curtos

    if (highSimilarityCount >= 2) break;

    for (final oldPara in recentParagraphs) {
      final oldWordCount = oldPara.trim().split(RegExp(r'\s+')).length;
      if (oldWordCount < 50) continue; // Ignorar parágrafos muito curtos

      final similarity = calculateSimilarityStatic(newPara, oldPara);

      // ?? AJUSTE: Threshold reduzido de 85% para 80%
      if (similarity >= threshold) {
        highSimilarityCount++;

        if (highSimilarityCount >= 2) {
          return {
            'isSimilar': true,
            'reason':
                '$highSimilarityCount paragraphs with ${(similarity * 100).toStringAsFixed(1)}% similarity',
          };
        }
        break;
      }
    }
  }

  return {'isSimilar': false, 'reason': 'Content is unique'};
}

/// Versão estática de _hasLiteralDuplication para usar em Isolate
/// ?? FORTALECIDO: Detecta duplicações literais com mais agressividade
bool hasLiteralDuplicationStatic(String newBlock, String previousContent) {
  if (previousContent.length < 500) {
    return false; // ?? REDUZIDO: Era 1000, agora 500
  }

  // ?? NOVO: Verificar parágrafos completos duplicados (para transições de seção)
  final newParagraphs = newBlock
      .split('\n\n')
      .where(
        (p) =>
            p.trim().isNotEmpty && p.trim().split(RegExp(r'\s+')).length > 30,
      )
      .map((p) => p.trim().toLowerCase())
      .toList();

  final prevParagraphs = previousContent
      .split('\n\n')
      .where(
        (p) =>
            p.trim().isNotEmpty && p.trim().split(RegExp(r'\s+')).length > 30,
      )
      .map((p) => p.trim().toLowerCase())
      .toList();

  // ?? CRÍTICO: Detectar parágrafos idênticos (problema do Quitéria)
  for (final newPara in newParagraphs) {
    for (final prevPara in prevParagraphs) {
      // Similaridade exata ou muito próxima (95%+)
      if (newPara == prevPara) {
        return true; // Parágrafo duplicado exato
      }

      // ?? Verificar similaridade estrutural (mesmas primeiras 50 palavras)
      final newWords = newPara.split(RegExp(r'\s+'));
      final prevWords = prevPara.split(RegExp(r'\s+'));

      if (newWords.length > 50 && prevWords.length > 50) {
        final newStart = newWords.take(50).join(' ');
        final prevStart = prevWords.take(50).join(' ');

        if (newStart == prevStart) {
          return true; // Início idêntico em parágrafo longo
        }
      }
    }
  }

  // ?? Verificação de sequências de palavras (original)
  final newWords = newBlock.split(RegExp(r'\s+'));
  if (newWords.length < 150) return false; // ?? REDUZIDO: Era 200, agora 150

  final prevWords = previousContent.split(RegExp(r'\s+'));
  if (prevWords.length < 150) return false; // ?? REDUZIDO: Era 200, agora 150

  // ?? OTIMIZADO: Verificar sequências menores (150 palavras em vez de 200)
  for (int i = 0; i <= newWords.length - 150; i++) {
    final newSequence = newWords.sublist(i, i + 150).join(' ').toLowerCase();

    for (int j = 0; j <= prevWords.length - 150; j++) {
      final prevSequence = prevWords
          .sublist(j, j + 150)
          .join(' ')
          .toLowerCase();

      if (newSequence == prevSequence) {
        return true;
      }
    }
  }

  return false;
}

/// Versão estática de _calculateSimilarity para usar em Isolate
double calculateSimilarityStatic(String text1, String text2) {
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

  if (words1.length < nGramSize || words2.length < nGramSize) {
    final commonWords = words1.toSet().intersection(words2.toSet()).length;
    return commonWords / max(words1.length, words2.length);
  }

  final ngrams1 = <String>{};
  for (int i = 0; i <= words1.length - nGramSize; i++) {
    ngrams1.add(words1.sublist(i, i + nGramSize).join(' '));
  }

  final ngrams2 = <String>{};
  for (int i = 0; i <= words2.length - nGramSize; i++) {
    ngrams2.add(words2.sublist(i, i + nGramSize).join(' '));
  }

  final intersection = ngrams1.intersection(ngrams2).length;
  final union = ngrams1.union(ngrams2).length;

  return union > 0 ? intersection / union : 0.0;
}
