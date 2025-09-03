import 'dart:math';

class GenreDetectionService {
  // Palavras-chave por gênero
  static const Map<String, List<String>> _genreKeywords = {
    'business': [
      'negócio', 'empresa', 'herança', 'ceo', 'sócio', 'corporação',
      'investimento', 'fusão', 'startup', 'lucro', 'mercado', 'cliente',
      'vendas', 'contrato', 'patrimônio', 'capital', 'ações', 'dividendos'
    ],
    'family': [
      'família', 'segredo', 'pai', 'mãe', 'coração', 'amor', 'filho',
      'filha', 'irmão', 'irmã', 'avô', 'avó', 'casamento', 'divórcio',
      'tradição', 'herança familiar', 'reconciliação', 'perdão'
    ],
    'western': [
      'pistoleiro', 'xerife', 'rancho', 'vingança', 'dólar', 'cidade',
      'cavalo', 'revólver', 'duelo', 'saloon', 'forasteiro', 'bandido',
      'ouro', 'mina', 'fronteira', 'diligência', 'cowboy'
    ]
  };

  // Templates por gênero
  static const Map<String, List<String>> _genreTemplates = {
    'business': [
      'Traição Corporativa: Descoberta de esquema dentro da empresa',
      'Revelação de Herança: Testamento muda tudo',
      'Startup do Caos: Jovem empreendedor enfrenta adversidades',
      'O Sócio Fantasma: Parceiro misterioso surge',
      'Fusão Impossível: Duas empresas rivais se unem',
      'O CEO Desaparecido: Líder some em momento crítico',
      'Império Familiar: Disputa por controle da empresa'
    ],
    'family': [
      'Revelação de Segredo Familiar: Verdade escondida por décadas',
      'Jornada de Reconciliação: Família separada se reencontra',
      'O Testamento Perdido: Documento revela surpresas',
      'Casamento Arranjado: Tradição versus amor verdadeiro',
      'O Filho Perdido: Retorno após anos de ausência',
      'Segredos da Matriarca: Avó revela passado oculto',
      'A Casa da Família: Propriedade que une gerações'
    ],
    'western': [
      'Compra e Venda Humana: Tráfico no Velho Oeste',
      'Objetos Misteriosos: Artefato valioso causa conflito',
      'O Último Duelo: Confronto final entre rivais'
    ]
  };

  static String detectGenre(String title, String context) {
    final combinedText = '${title.toLowerCase()} ${context.toLowerCase()}';
    
    final scores = <String, int>{};
    
    // Calcular pontuação para cada gênero
    for (final genre in _genreKeywords.keys) {
      final keywords = _genreKeywords[genre]!;
      int score = 0;
      
      for (final keyword in keywords) {
        // Pontuação maior se a palavra estiver no título
        if (title.toLowerCase().contains(keyword)) {
          score += 3;
        }
        // Pontuação menor se estiver apenas no contexto
        else if (context.toLowerCase().contains(keyword)) {
          score += 1;
        }
      }
      
      scores[genre] = score;
    }
    
    // Encontrar gênero com maior pontuação
    String detectedGenre = 'family'; // Padrão
    int maxScore = 0;
    
    for (final entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        detectedGenre = entry.key;
      }
    }
    
    // Se pontuação muito baixa, usar família como padrão
    if (maxScore < 2) {
      detectedGenre = 'family';
    }
    
    return detectedGenre;
  }

  static List<String> getTemplatesForGenre(String genre) {
    return _genreTemplates[genre] ?? _genreTemplates['family']!;
  }

  static String getRandomTemplate(String genre) {
    final templates = getTemplatesForGenre(genre);
    final random = Random();
    return templates[random.nextInt(templates.length)];
  }

  static String getGenreDisplayName(String genre) {
    switch (genre) {
      case 'business':
        return 'Negócios';
      case 'family':
        return 'Familiar';
      case 'western':
        return 'Faroeste';
      default:
        return 'Familiar';
    }
  }

  static String getGenreIcon(String genre) {
    switch (genre) {
      case 'business':
        return '💼';
      case 'family':
        return '👨‍👩‍👧‍👦';
      case 'western':
        return '🤠';
      default:
        return '👨‍👩‍👧‍👦';
    }
  }

  static Map<String, dynamic> analyzeContent(String title, String context) {
    final genre = detectGenre(title, context);
    final templates = getTemplatesForGenre(genre);
    final randomTemplate = getRandomTemplate(genre);
    
    return {
      'genre': genre,
      'genreDisplayName': getGenreDisplayName(genre),
      'genreIcon': getGenreIcon(genre),
      'templates': templates,
      'suggestedTemplate': randomTemplate,
      'confidence': _calculateConfidence(title, context, genre),
    };
  }

  static double _calculateConfidence(String title, String context, String genre) {
    final combinedText = '${title.toLowerCase()} ${context.toLowerCase()}';
    final keywords = _genreKeywords[genre] ?? [];
    
    int matches = 0;
    for (final keyword in keywords) {
      if (combinedText.contains(keyword)) {
        matches++;
      }
    }
    
    // Confiança baseada na porcentagem de palavras-chave encontradas
    return (matches / keywords.length).clamp(0.0, 1.0);
  }
}
