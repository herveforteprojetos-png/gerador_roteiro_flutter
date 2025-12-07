/// 🔍 Validador de nomes de personagens
class NameValidator {
  /// Stopwords - palavras que NÃO são nomes de pessoas
  static final Set<String> nameStopwords = {
    // Plataformas/sites
    'youtube',
    'internet',
    'instagram',
    'facebook',
    'whatsapp',
    'tiktok',
    'google',
    'cta',

    // Países/lugares
    'brasil',
    'portugal',
    'portugues',

    // Pronomes e palavras comuns
    'ele',
    'ela',
    'eles',
    'elas',
    'nao',
    'sim',
    'mas',
    'mais',
    'cada',
    'todo',
    'toda',
    'todos',
    'meu',
    'minha',
    'meus',
    'minhas',
    'seu',
    'sua',
    'seus',
    'suas',
    'nosso',
    'nossa',
    'esse',
    'essa',
    'esses',
    'essas',
    'aquele',
    'aquela',
    'aquilo',
    'isto',
    'isso',
    'tudo',
    'nada',
    'algo',
    'alguem',
    'ninguem',
    'qualquer',
    'outro',
    'outra',
    'mesmo',
    'mesma',
    'esta',
    'este',
    'estes',
    'estas',

    // Substantivos comuns
    'filho',
    'filha',
    'filhos',
    'pai',
    'mae',
    'pais',
    'irmao',
    'irma',
    'tio',
    'tia',
    'avo',
    'neto',
    'neta',
    'marido',
    'esposa',
    'noivo',
    'noiva',
    'amigo',
    'amiga',
    'primo',
    'prima',
    'sobrinho',
    'sobrinha',
    'senhor',
    'senhora',
    'doutor',
    'doutora',
    'cliente',
    'pessoa',
    'pessoas',
    'gente',
    'familia',
    'casa',
    'mundo',
    'vida',
    'tempo',
    'dia',
    'noite',
    'momento',

    // Advérbios/conjunções/preposições
    'entao',
    'depois',
    'antes',
    'agora',
    'hoje',
    'ontem',
    'amanha',
    'sempre',
    'nunca',
    'talvez',
    'porem',
    'contudo',
    'entretanto',
    'portanto',
    'enquanto',
    'quando',
    'onde',
    'havia',
    'houve',
    'tinha',
    'foram',
    'eram',
    'estava',
    'estavam',
    'dentro',
    'fora',
    'acima',
    'abaixo',
    'perto',
    'longe',
    'aqui',
    'ali',
    'alem',
    'apenas',
    'somente',
    'tambem',
    'inclusive',
    'ate',
    'ainda',
    'logo',
    'ja',
    'nem',

    // Preposições e artigos
    'com',
    'sem',
    'sobre',
    'para',
    'pela',
    'pelo',
    'uma',
    'umas',
    'uns',
    'por',

    // Palavras fantasma (a AI usou como nomes por engano)
    'lagrimas',
    'lágrimas',
    'justica',
    'justiça',
    'ponto',
    'semanas',
    'aconteceu',
    'todas',
    'ajuda',
    'consolo',
    'vamos',
    'conheço',
    'conheco',
    'lembra',

    // Verbos comuns
    'era',
    'foi',
    'seria',
    'pode',
    'podia',
    'deve',
    'devia',
    'senti',
    'sentiu',
    'pensei',
    'pensou',
    'vi',
    'viu',
    'ouvi',
    'ouviu',
    'fiz',
    'fez',
    'disse',
    'falou',
    'quis',
    'pude',
    'pôde',
    'tive',
    'teve',
    'sabia',
    'soube',
    'imaginei',
    'imaginou',
    'acreditei',
    'acreditou',
    'percebi',
    'percebeu',
    'notei',
    'notou',
    'lembrei',
    'lembrou',
    'passei',
    'abri',
    'olhei',
    'escrevo',
    'escreveu',
    'podes',
    'queria',
    'quer',
    'tenho',
    'tem',
    'levei',
    'levou',
    'trouxe',
    'deixei',
    'deixou',
    'encontrei',
    'encontrou',
    'cheguei',
    'chegou',
    'sai',
    'saiu',
    'entrei',
    'entrou',
    'peguei',
    'pegou',
    'coloquei',
    'colocou',
    'tirei',
    'tirou',
    'guardei',
    'guardou',
    'voltei',
    'voltou',
    'segui',
    'seguiu',
    'comecei',
    'começou',
    'terminei',
    'terminou',
  };

  /// Verifica se uma string parece um nome de pessoa
  /// 🔥 VALIDAÇÃO v7.6.56: Estrutural (Casting Director cria os nomes)
  static bool looksLikePersonName(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return false;

    // v7.6.56: Validação estrutural - Gemini é o Casting Director
    // Verificar estrutura básica de nome próprio
    if (cleaned.length < 2 || cleaned.length > 30) return false;

    // Primeira letra maiúscula
    if (!RegExp(r'^[A-ZÁÀÂÃÉÊÍÓÔÕÚÇÑ]').hasMatch(cleaned)) return false;

    // Não é stopword conhecida
    if (nameStopwords.contains(cleaned.toLowerCase())) return false;

    return true;
  }

  /// Extrai nomes de um texto usando regex
  /// 🔧 v7.6.76: Versão completa com detecção de nomes compostos
  static Set<String> extractNamesFromText(String text) {
    final names = <String>{};
    if (text.isEmpty) return names;

    // 🎯 v7.6.30: DETECTAR NOMES COMPOSTOS PRIMEIRO (Arthur Evans, Mary Jane, etc)
    final compoundNamePattern = RegExp(
      r'\b([A-ZÀ-Ú][a-zà-ú]{1,14}(?:\s+[A-ZÀ-Ú][a-zà-ú]{1,14}){1,2})\b',
      multiLine: true,
    );

    final compoundMatches = compoundNamePattern.allMatches(text);
    final processedWords = <String>{}; // Rastrear palavras já processadas

    for (final match in compoundMatches) {
      final fullName = match.group(1);
      if (fullName != null && !isCommonPhrase(fullName)) {
        names.add(fullName);
        for (final word in fullName.split(' ')) {
          processedWords.add(word);
        }
      }
    }

    // Regex para nomes simples
    final nameRegex = RegExp(
      r'\b([A-ZÀ-Ú][a-zà-ú]{1,14})\b',
      multiLine: true,
    );

    for (final match in nameRegex.allMatches(text)) {
      final potentialName = match.group(1)?.trim() ?? '';

      // Pular se já processado como parte de nome composto
      if (processedWords.contains(potentialName)) continue;

      // Filtros básicos
      if (potentialName.length < 3) continue;
      if (potentialName.length > 30) continue;

      // Verificar se é stopword
      if (nameStopwords.contains(potentialName.toLowerCase())) continue;

      // 🎯 Filtro de palavras comuns
      if (_commonWordsFilter.contains(potentialName)) continue;

      // Verificar se parece nome de pessoa
      if (!looksLikePersonName(potentialName)) continue;

      names.add(potentialName);
    }

    return names;
  }

  /// 🔧 v7.6.76: Filtro de palavras comuns que não são nomes
  static final Set<String> _commonWordsFilter = {
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
    // Verbos auxiliares
    'Was', 'Were', 'Is', 'Are', 'Am', 'Has', 'Have', 'Had',
    'Do', 'Does', 'Did', 'Will', 'Would', 'Could', 'Should',
    'Can', 'May', 'Might', 'Must',
    // Dias da semana
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    // Meses
    'January', 'February', 'March', 'April', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
    // Português
    'Então', 'Quando', 'Depois', 'Antes', 'Agora', 'Hoje', 'Amanhã', 'Ontem',
    'Naquela', 'Aquela', 'Aquele', 'Naquele', 'Enquanto', 'Durante', 'Embora',
    'Porém', 'Portanto', 'Assim', 'Nunca', 'Sempre', 'Talvez', 'Quase',
    'Apenas', 'Mesmo', 'Também', 'Muito', 'Pouco', 'Tanto', 'Onde',
    'Como', 'Porque', 'Mas', 'Ou', 'Para', 'Com', 'Sem', 'Por',
    // Termos técnicos
    'Tax', 'Certificate', 'Bearer', 'Shares', 'Switzerland',
    'Consider', 'Tucked',
  };

  /// 🔧 v7.6.76: Verifica se frase composta é nome real ou expressão comum
  static bool isCommonPhrase(String phrase) {
    final phraseLower = phrase.toLowerCase();

    const commonPhrases = {
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

    return commonPhrases.contains(phraseLower);
  }

  /// Valida se há nomes duplicados em papéis diferentes
  /// Retorna lista de nomes duplicados encontrados
  static List<String> validateNamesInText(
    String newBlock,
    Set<String> previousNames,
  ) {
    final duplicates = <String>[];
    final newNames = extractNamesFromText(newBlock);

    for (final name in newNames) {
      if (previousNames.contains(name)) {
        if (!duplicates.contains(name)) {
          duplicates.add(name);
        }
      }
    }

    return duplicates;
  }

  /// Extrai nomes de um snippet com contagem de ocorrências
  static Map<String, int> extractNamesFromSnippet(String snippet) {
    final counts = <String, int>{};
    final regex = RegExp(
      r'\b([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+(?:\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)*)\b',
    );

    for (final match in regex.allMatches(snippet)) {
      final candidate = match.group(1)?.trim() ?? '';
      if (!looksLikePersonName(candidate)) continue;
      final normalized = candidate.replaceAll(RegExp(r'\s+'), ' ');
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }

    return counts;
  }

  /// Extrai papel/relação de um nome em um texto
  /// Retorna o primeiro papel encontrado ou null
  static String? extractRoleForName(String name, String text) {
    final rolePatterns = {
      'marido': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:marido|esposo)(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'esposa': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:esposa|mulher)(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'pai': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Pp]ai(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'mãe': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Mm]ãe(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'filho': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Ff]ilho(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'filha': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Ff]ilha(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'irmão': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:irmão|irmao)(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'irmã': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:irmã|irma)(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'sogro': RegExp(
        r'(?:meu|seu|nosso|o)\s+sogro(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'sogra': RegExp(
        r'(?:minha|sua|nossa|a)\s+sogra(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'amigo': RegExp(
        r'(?:meu|seu|nosso|o)\s+amigo(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'amiga': RegExp(
        r'(?:minha|sua|nossa|a)\s+amiga(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
    };

    for (final entry in rolePatterns.entries) {
      if (entry.value.hasMatch(text)) {
        return entry.key;
      }
    }

    return null;
  }

  /// 🔧 v7.6.73: Validação simples de nome (aceita criatividade do LLM)
  /// Resolve bug de rejeitar nomes coreanos, compostos, etc.
  static bool isLikelyName(String text) {
    if (text.isEmpty) return false;
    // Aceita qualquer string que comece com letra maiúscula
    // e contenha apenas letras, espaços, hífens ou apóstrofos
    final nameRegex = RegExp(
      r"^[A-Z\u00C0-\u00DC\u0100-\u017F\uAC00-\uD7AF][a-zA-Z\u00C0-\u00FF\u0100-\u017F\uAC00-\uD7AF\s\-\']+$",
    );
    return nameRegex.hasMatch(text.trim());
  }

  /// 🔧 v7.6.73: Verifica estrutura válida de nome próprio
  static bool hasValidNameStructure(String name) {
    // Mínimo 2 caracteres, máximo 15
    if (name.length < 2 || name.length > 15) return false;

    // Primeira letra maiúscula
    if (name[0] != name[0].toUpperCase()) return false;

    // Resto em minúsculas (permite acentos)
    final rest = name.substring(1);
    if (rest != rest.toLowerCase()) return false;

    // Apenas letras (permite acentuação)
    final validPattern = RegExp(r'^[A-ZÀ-Ú][a-zà-ú]+$');
    return validPattern.hasMatch(name);
  }

  /// 🔧 v7.6.73: Verifica se é palavra comum (não-nome)
  static bool isCommonWord(String word) {
    final lower = word.toLowerCase();

    // Palavras comuns em múltiplos idiomas
    const commonWords = {
      // Português
      'então', 'quando', 'depois', 'antes', 'agora', 'hoje',
      'ontem', 'sempre', 'nunca', 'muito', 'pouco', 'nada',
      'tudo', 'algo', 'alguém', 'ninguém', 'mesmo', 'outra',
      'outro', 'cada', 'toda', 'todo', 'todos', 'onde', 'como',
      'porque', 'porém', 'mas', 'para', 'com', 'sem', 'por',
      'sobre', 'entre', 'durante', 'embora', 'enquanto',
      // English
      'then', 'when', 'after', 'before', 'now', 'today',
      'yesterday', 'always', 'never', 'much', 'little', 'nothing',
      'everything', 'something', 'someone', 'nobody', 'same', 'other',
      'each', 'every', 'where', 'because', 'however', 'though',
      'while', 'about', 'between',
      // Español
      'entonces', 'después', 'ahora', 'hoy', 'ayer', 'siempre',
      'mucho', 'alguien', 'nadie', 'mismo', 'pero', 'sin', 'aunque',
      'mientras',
    };

    return commonWords.contains(lower);
  }
}
