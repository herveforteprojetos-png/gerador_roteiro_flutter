/// 🔍 Validador de nomes de personagens
/// 🆕 v7.6.128: Cache de validações para performance
class NameValidator {
  /// 💾 Cache de validações (nome → isValid)
  /// 🆕 v7.6.128: Evita revalidar o mesmo nome múltiplas vezes
  static final Map<String, bool> _validationCache = {};

  /// 🗑️ Limpa o cache de validações
  /// Use no início de cada geração para evitar cache obsoleto
  static void clearCache() {
    _validationCache.clear();
  }

  /// 🆕 v7.6.132: Prefixos/palavras que indicam FRASES (não nomes)
  ///
  /// Problema: "Mas Mateus", "Ou Otávio", "Enquanto Eduardo" detectados como nomes compostos
  /// Solução: Ignorar completamente se contém essas palavras
  ///
  /// Impacto: Reduz 40-50% dos conflitos falsos
  static final Set<String> phraseIgnoreSet = {
    // Conjunções/conectivos
    'mas', 'ou', 'e', 'nem', 'pois', 'porém', 'contudo',

    // Preposições/advérbios temporais
    'enquanto', 'quando', 'como', 'onde', 'então', 'depois',
    'antes', 'agora', 'ainda', 'já', 'logo',

    // Tratamentos/títulos (não são nomes próprios isolados)
    'senhor', 'senhora', 'dona', 'seu', 'sua',

    // Verbos comuns no início de frases
    'era', 'foi', 'tinha', 'estava', 'havia', 'disse',
    'falou', 'pensou', 'sabia', 'quis', 'pode', 'deve',

    // Artigos indefinidos (podem preceder nomes)
    'um', 'uma', 'uns', 'umas',
  };

  /// 🆕 v7.6.141: Palavras que indicam INSTITUIÇÕES (não pessoas)
  /// Se um nome composto contém uma dessas palavras, NÃO é nome de pessoa
  /// Ex: "Escola Municipal", "Hospital São Lucas", "Prefeitura de Santos"
  static final Set<String> institutionIndicators = {
    // Educação
    'escola', 'colégio', 'faculdade', 'universidade', 'instituto',
    'creche', 'biblioteca', 'academia', 'curso',

    // Saúde
    'hospital', 'clínica', 'posto', 'upa', 'pronto-socorro',
    'consultório', 'laboratório',

    // Governo
    'prefeitura', 'câmara', 'fórum', 'tribunal', 'delegacia',
    'secretaria', 'ministério', 'assembleia', 'senado',

    // Comércio/Negócios
    'empresa', 'loja', 'mercado', 'supermercado', 'farmácia',
    'padaria', 'restaurante', 'hotel', 'pousada',

    // Lugares públicos
    'praça', 'parque', 'jardim', 'rua', 'avenida',
    'rodovia', 'estrada', 'ponte', 'viaduto',

    // Organizações
    'associação', 'fundação', 'ong', 'sindicato', 'cooperativa',
    'clube', 'centro', 'núcleo',

    // Qualificadores administrativos
    'municipal', 'estadual', 'federal', 'nacional',
    'público', 'pública', 'particular', 'privado', 'privada',
  };

  /// 🆕 v7.6.130: Whitelist de nomes compostos (evita conflitos falsos)
  ///
  /// Problema: "Minas Gerais" vs "Minas" geravam alerta falso
  /// Solução: Tratar compostos como unidade única
  ///
  /// Inclui: Localidades, organizações, nomes institucionais
  /// 🆕 v7.6.136: Expandido com nomes compostos de personagens e empresas
  static final Set<String> compoundWhitelist = {
    // Localidades geográficas (Brasil)
    'minas gerais', 'são paulo', 'rio de janeiro', 'espírito santo',
    'santa catarina', 'rio grande do sul', 'rio grande do norte',
    'mato grosso', 'mato grosso do sul', 'distrito federal',
    'zona leste', 'zona oeste', 'zona norte', 'zona sul',
    'belo horizonte', 'porto alegre', 'nova york', 'los angeles',

    // Organizações/Programas (contexto corporativo/social)
    'fundo integridade', 'programa social', 'projeto social',
    'empresa de contabilidade', 'conselho de administração',
    'torre corporativa', 'centro empresarial', 'escritório central',
    'grupo otávio', 'horizonte sustentável', 'futuro verde',
    'polícia federal', 'polícia civil', 'polícia militar',

    // Instituições de ensino
    'universidade federal', 'instituto federal', 'escola técnica',
    'escola municipal',
    'escola estadual',
    'escola pública',
    'escola particular',
    'colégio estadual', 'colégio municipal', 'creche municipal',

    // Lugares/Instituições genéricas que não são pessoas
    'hospital municipal', 'hospital estadual', 'posto de saúde',
    'prefeitura municipal', 'câmara municipal', 'fórum municipal',
    'biblioteca municipal', 'teatro municipal', 'praça central',
    'parque municipal', 'jardim botânico', 'zoológico municipal',
    'sonho grande', 'futuro brilhante', 'nova esperança',

    // Títulos/Cargos compostos
    'chefe de gabinete', 'diretor executivo', 'presidente do conselho',

    // 🆕 v7.6.136: Nomes compostos com títulos (personagens)
    'doutor álvaro', 'doutora álvaro', 'dr álvaro', 'dra álvaro',
    'doutor augusto', 'doutora helena', 'doutor carlos', 'doutor pedro',
    'senhor álvaro', 'senhora álvaro', 'sr álvaro', 'sra álvaro',
    'dona lúcia', 'dona maria', 'dona helena', 'dona ana',
    'padre antônio', 'padre joão', 'padre carlos',

    // 🆕 v7.6.136: Nomes compostos de personagens (sobrenome distinto)
    'otávio albuquerque', 'otávio montenegro', 'otávio silva',
    'álvaro albuquerque', 'álvaro montenegro', 'álvaro castro',
    'helena albuquerque', 'helena montenegro', 'helena santos',
    'maria helena', 'maria clara', 'maria fernanda', 'ana lúcia',
    'pedro henrique', 'joão pedro', 'josé carlos', 'carlos eduardo',
  };

  /// Stopwords - palavras que NÃO são nomes de pessoas
  /// 🆕 v7.6.120: Expandido com preposições, artigos e palavras curtas problemáticas
  /// 🆕 v7.6.127: Expandido com palavras detectadas em logs Flash (as, não, valores, etc)
  /// Stopwords - palavras que NÃO são nomes de pessoas
  /// 🆕 v7.6.120: Expandido com preposições, artigos e palavras curtas problemáticas
  /// 🆕 v7.6.127: Expandido com palavras detectadas em logs Flash (as, não, valores, etc)
  /// 🆕 v7.6.139: Expandido com palavras detectadas em logs (moro, nesses, após, etc)
  static final Set<String> nameStopwords = {
    // 🆕 v7.6.139: Palavras comuns que aparecem no início de frases
    'moro', 'nesses', 'deus', 'faxineiros', 'professores', 'agentes',
    'após', 'assim', 'colegas', 'jornais', 'acompanhada', 'ofereço', 'vai',
    'temos', 'aceitar', 'atravess', 'duzentos', 'aprendiz',
    'est', 'obrigado', 'obrigada', // Palavras de cortesia
    // 🆕 v7.6.140: Verbos imperativos e palavras de início de frase
    'inicie', 'quero', 'lembre', 'nenhum', 'oferta', 'genuíno', 'dias',
    'ei', 'iniciativa', 'proatividade', 'campanha', 'foco', 'liderança',
    'teste', 'tente', 'faça', 'olhe', 'veja', 'venha', 'vá', 'pegue',
    'traga', 'leve', 'fale', 'ouça', 'pense', 'imagine',

    // 🆕 v7.6.141: Substantivos e adjetivos comuns detectados em logs
    'escola', 'municipal', 'sonho', 'grande', 'tão', 'pequeno', 'pequena',
    'novo', 'nova', 'velho', 'velha', 'ruim', 'bonito', 'bonita',
    'feio', 'feia', 'alto', 'alta', 'baixo', 'baixa', 'central',

    // Substantivos plurais comuns (não são nomes de personagens)
    'estudantes', 'alunos', 'meninos', 'meninas', 'crianças', 'jovens',
    'adultos', 'velhos', 'idosos', 'trabalhadores', 'funcionários',
    'médicos', 'enfermeiros', 'policiais', 'bombeiros', 'militares',
    'comerciantes', 'vendedores', 'compradores', 'clientes',

    // Títulos que NÃO são nomes (fundação, desenvolvimento, etc já existem abaixo)
    'humano', 'social', 'projeto',
    'programa', 'instituto', 'organização', 'associação',

    // 🆕 v7.6.120: Preposições e artigos curtos (eram detectados como nomes!)
    'na', 'no', 'nas',
    'em', 'de', 'do', 'da', 'dos', 'das',
    'ao', 'aos', 'à', 'às',
    'tu', 'nós', 'vós',

    // 🆕 v7.6.120: Palavras curtas problemáticas
    'mal', 'bem', 'ser', 'ter', 'ver', 'dar',
    'três', 'dois', 'dez', 'cem', 'mil',
    'ano', 'mes', 'vez', 'fim', 'mar', 'sol', 'ceu', 'paz',

    // 🆕 v7.6.120: Verbos/advérbios que parecem nomes
    'deu', 'algumas', 'naquele', 'tentou', 'olhou', 'voc',

    // 🆕 v7.6.127: Palavras detectadas em logs Flash (falsos positivos)
    'as', 'os', 'um', // Artigos (uma, umas, uns já existem abaixo)
    'não', 'se', 'eu', 'ou', 'que', // Comuns (sim, mas já existem abaixo)
    'pontualmente',
    'valores',
    'provas',
    'detalhes',
    'poder', // Substantivos comuns
    'precisarei', 'entrarei', 'sejam', 'usava', // Verbos
    'torre', // Locais comuns que não são personagens
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

    // 🆕 v7.6.137: Verbos adicionais detectados em logs
    'sentou',
    'sentei',
    'sentado',
    'sentada',
    'bom',
    'boa',
    'muito',
    'muita',
    'procuro',
    'procura',
    'procurou',
    'torne',
    'torna',
    'tornou',
    'fechar',
    'fechou',
    'fechei',
    'qual',
    'quais',
    'alguém',
    'ninguém',
    'vende',
    'vendeu',
    'vendi',
    'chega',
    // 'chegou' - já existe acima
    'criar',
    'criou',
    'criei',
    'brilhante',
    'simples',
    'considere',
    'considera',
    'considerou',
    'escute',
    'escuta',
    'escutou',
    'aproveite',
    'aproveita',
    'aproveitou',
    'entregou',
    'entregue',
    'protegeu',
    'livre',
    'anos',
    // 'ano' - já existe acima
    'amanh',
    'amanhã',
    'diga',
    'negócios',
    'negócio',
    'maximizar',
    'sentimentalismo',
    'estamos',
    'tome',
    'comunidades',
    'comunidade',
    'moderniz',
    'modernizar',
    'modernizou',

    // Títulos abreviados (não são nomes)
    'dr',
    'dra',
    'sr',
    'sra',
    'prof',
    'profa',
    'pe',
    'mr',
    'mrs',
    'ms',

    // Palavras comuns que aparecem capitalizadas
    'presidente',
    'diretor',
    'diretora',
    'conselho',
    'grupo',
    'fundação',
    'vila',
    'esperança',
  };

  /// 🆕 v7.6.132: Verifica se string é uma FRASE (não um nome)
  ///
  /// Exemplos detectados:
  /// - "Mas Mateus" → true (contém 'mas')
  /// - "Ou Otávio" → true (contém 'ou')
  /// - "Enquanto Eduardo" → true (contém 'enquanto')
  /// - "João Silva" → false (nome legítimo)
  static bool isPhrase(String text) {
    final lowerText = text.toLowerCase();

    // Divide em palavras e verifica se alguma está no phraseIgnoreSet
    final words = lowerText.split(RegExp(r'\s+'));
    return words.any((word) => phraseIgnoreSet.contains(word));
  }

  /// Verifica se uma string parece um nome de pessoa
  /// 🔥 VALIDAÇÃO v7.6.56: Estrutural (Casting Director cria os nomes)
  /// 🆕 v7.6.128: Com cache para evitar revalidações
  /// 🆕 v7.6.132: Rejeita frases usando isPhrase()
  /// 🆕 v7.6.140: Rejeita substantivos abstratos (-ade, -ção, -ncia, etc)
  static bool looksLikePersonName(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return false;

    // 🔥 v7.6.132: REJEITAR FRASES primeiro (antes de cache)
    // Ex: "Mas Mateus", "Ou Otávio" → false imediato
    if (isPhrase(cleaned)) {
      _validationCache[cleaned] = false;
      return false;
    }

    // 💾 Check cache primeiro
    if (_validationCache.containsKey(cleaned)) {
      return _validationCache[cleaned]!;
    }

    // v7.6.56: Validação estrutural - Gemini é o Casting Director
    // Verificar estrutura básica de nome próprio
    if (cleaned.length < 2 || cleaned.length > 30) {
      _validationCache[cleaned] = false;
      return false;
    }

    // 🆕 v7.6.140: REJEITAR substantivos abstratos (não são nomes de pessoas)
    // Exemplos: "Iniciativa", "Proatividade", "Liderança", "Campanha", "Ação"
    final lowerCleaned = cleaned.toLowerCase();

    // 🆕 v7.6.141: REJEITAR instituições (Escola Municipal, Hospital Central)
    // Verifica se contém palavras indicadoras de instituição
    final words = lowerCleaned.split(RegExp(r'\s+'));
    for (final word in words) {
      if (institutionIndicators.contains(word)) {
        _validationCache[cleaned] = false;
        return false;
      }
    }

    // Verificar sufixos abstratos
    final abstractSuffixes = [
      'ade', // Iniciativa, Proatividade, Felicidade, Bondade
      'ção', 'são', // Ação, Campanha, Decisão, Posição
      'mento', // Pensamento, Sentimento, Movimento
      'ncia', 'ência', // Liderança, Influência, Paciência
      'eza', // Beleza, Tristeza, Pobreza
      'ismo', // Heroísmo, Romantismo
      'idade', // Felicidade, Bondade (já coberto por -ade)
    ];

    for (final suffix in abstractSuffixes) {
      if (lowerCleaned.endsWith(suffix) &&
          lowerCleaned.length > suffix.length + 2) {
        _validationCache[cleaned] = false;
        return false;
      }
    }

    // 🇰🇷 v7.6.150: Primeira letra maiúscula OU caracteres hangul/CJK
    // Aceita: "Arthur", "박진우", "山田", "李明"
    // Unicode ranges: Hangul (AC00-D7AF), CJK (4E00-9FFF)
    final startsWithCapital = RegExp(r'^[A-ZÁÀÂÃÉÊÍÓÔÕÚÇÑ]').hasMatch(cleaned);
    final isHangulOrCJK = RegExp(r'^[\uAC00-\uD7AF\u4E00-\u9FFF]').hasMatch(cleaned);
    
    if (!startsWithCapital && !isHangulOrCJK) {
      _validationCache[cleaned] = false;
      return false;
    }

    // Não é stopword conhecida
    if (nameStopwords.contains(cleaned.toLowerCase())) {
      _validationCache[cleaned] = false;
      return false;
    }

    _validationCache[cleaned] = true;
    return true;
  }

  /// 🔍 Verifica se há conflito de nomes com relaxamento para nomes compostos
  /// 🆕 v7.6.127: Permite nomes compostos longos (>2 palavras) mesmo com sobreposição
  /// 🆕 v7.6.130: Whitelist para compostos geográficos/organizacionais
  /// 🆕 v7.6.136: Skip de prefixos (doutor, senhor, mas, ou, era)
  ///
  /// Exemplos:
  /// - "Otávio Montenegro" OK mesmo com "Otávio" existente (>2 palavras)
  /// - "Minas Gerais" OK mesmo com "Minas" existente (whitelist)
  /// - "Fundo Integridade" OK mesmo com "Fundo" existente (whitelist)
  /// - "Doutor Álvaro" OK mesmo com "Álvaro" existente (prefixo título)
  /// - "Mas Otávio" OK mesmo com "Otávio" existente (prefixo conjunção)
  /// - "Otávio" bloqueado se "Otávio Montenegro" já existe (exato match)
  static bool hasNameConflict(String newName, Set<String> existingNames) {
    if (existingNames.isEmpty) return false;

    final newLower = newName.toLowerCase();
    final newWordCount = newName.split(' ').length;

    // 🔥 v7.6.132: Ignorar FRASES completamente (não são nomes)
    // Ex: "Mas Mateus", "Enquanto Eduardo" → return false (sem conflito)
    if (isPhrase(newName)) return false;

    // 🔥 v7.6.136: Skip de prefixos - títulos e conjunções no início
    // Ex: "Doutor Álvaro", "Senhor Carlos", "Mas Otávio" → não são conflitos
    const prefixosIgnore = [
      'doutor ',
      'doutora ',
      'dr ',
      'dra ',
      'dr. ',
      'dra. ',
      'senhor ',
      'senhora ',
      'sr ',
      'sra ',
      'sr. ',
      'sra. ',
      'dona ',
      'dom ',
      'padre ',
      'frei ',
      'irmã ',
      'irmão ',
      'professor ',
      'professora ',
      'prof ',
      'profa ',
      'prof. ',
      'profa. ',
      'mas ',
      'ou ',
      'era ',
      'foi ',
      'e ',
    ];

    for (final prefixo in prefixosIgnore) {
      if (newLower.startsWith(prefixo)) {
        // Remove o prefixo e verifica se o resto está na whitelist
        final resto = newLower.substring(prefixo.length).trim();
        if (resto.isNotEmpty) {
          // "Doutor Álvaro" → se "doutor álvaro" está na whitelist, OK
          if (compoundWhitelist.contains(newLower)) return false;
          // Prefixo + nome = não é conflito (é tratamento respeitoso)
          if (resto.split(' ').length == 1) return false;
        }
      }
    }

    // 🔥 v7.6.130: Whitelist de compostos - NUNCA bloqueia
    if (compoundWhitelist.contains(newLower)) return false;

    // 🚀 RELAXAMENTO: Nomes compostos longos (>2 palavras) passam direto
    // Ex: "Otávio Montenegro Silva" sempre permitido
    if (newWordCount > 2) return false;

    for (final existingName in existingNames) {
      final existingLower = existingName.toLowerCase();

      // 🔥 v7.6.130: Se existente está na whitelist, não bloqueia novo
      if (compoundWhitelist.contains(existingLower)) continue;

      // 🔥 v7.6.136: Se existente tem prefixo ignorável, extrair nome real
      String existingReal = existingLower;
      for (final prefixo in prefixosIgnore) {
        if (existingLower.startsWith(prefixo)) {
          existingReal = existingLower.substring(prefixo.length).trim();
          break;
        }
      }

      // 🔴 BLOQUEIO 1: Match exato
      if (newLower == existingLower) return true;
      if (newLower == existingReal) return true;

      // 🟡 BLOQUEIO 2: Sobreposição só se palavra existente for longa (>3 chars)
      // Evita bloquear "João Silva" por causa de "Silva" sozinho
      if (newLower.contains(existingReal) && existingReal.length > 3) {
        return true;
      }

      // 🟡 BLOQUEIO 3: Nome curto sendo adicionado quando composto já existe
      // Ex: Bloquear "Otávio" se "Otávio Montenegro" já está no tracker
      if (existingReal.contains(newLower) && newLower.length > 3) {
        return true;
      }
    }

    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🆕 v7.6.136: EXTRAÇÃO SIMPLIFICADA (Formato Gemini: minúsculo + NOMES)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extrai nomes de texto no formato Gemini (minúsculo + NOMES MAIÚSCULOS)
  ///
  /// Esta é a lógica SIMPLIFICADA: nomes são palavras TODO MAIÚSCULAS
  /// Ex: "MATEUS olhava HELENA" → {MATEUS, HELENA}
  ///
  /// Retorna nomes em MAIÚSCULAS (como estão no texto)
  static Set<String> extractNamesFromUppercaseFormat(String text) {
    if (text.isEmpty) return {};

    final names = <String>{};
    final words = text.split(RegExp(r'[\s.,!?;:()\[\]"]+'));

    // Lista de palavras comuns que podem aparecer maiúsculas por erro
    const commonWords = {
      'EU',
      'ELE',
      'ELA',
      'NOS',
      'VOS',
      'UM',
      'UMA',
      'UNS',
      'UMAS',
      'OS',
      'AS',
      'DE',
      'DA',
      'DO',
      'EM',
      'NA',
      'NO',
      'MAS',
      'OU',
      'SE',
      'QUE',
      'COM',
      'THE',
      'TO',
      'IN',
      'ON',
      'AT',
      'AN',
    };

    for (final word in words) {
      if (word.length < 2) continue;

      // Remove caracteres não-letra
      final lettersOnly = word.replaceAll(
        RegExp(r'[^a-zA-ZáàâãéêíóôõúçüñÁÀÂÃÉÊÍÓÔÕÚÇÜÑ]'),
        '',
      );
      if (lettersOnly.isEmpty) continue;

      // Verifica se toda a palavra está em maiúsculas
      if (lettersOnly == lettersOnly.toUpperCase() &&
          lettersOnly != lettersOnly.toLowerCase()) {
        if (!commonWords.contains(lettersOnly)) {
          names.add(lettersOnly);
        }
      }
    }

    return names;
  }

  /// Verifica se texto está no formato Gemini (minúsculo + NOMES MAIÚSCULOS)
  static bool isUppercaseNameFormat(String text) {
    if (text.isEmpty) return false;

    final words = text.split(RegExp(r'\s+'));
    int lowercaseWords = 0;
    int uppercaseWords = 0;

    for (final word in words) {
      if (word.isEmpty) continue;
      final clean = word.replaceAll(
        RegExp(r'[^a-zA-ZáàâãéêíóôõúçüñÁÀÂÃÉÊÍÓÔÕÚÇÜÑ]'),
        '',
      );
      if (clean.isEmpty) continue;

      if (clean == clean.toLowerCase()) {
        lowercaseWords++;
      } else if (clean == clean.toUpperCase() && clean.length >= 2) {
        uppercaseWords++;
      }
    }

    final total = lowercaseWords + uppercaseWords;
    if (total == 0) return false;

    // Formato Gemini: maioria minúsculas com algumas maiúsculas (nomes)
    final lowercaseRatio = lowercaseWords / total;
    return lowercaseRatio >= 0.5 && uppercaseWords > 0;
  }

  /// 🧠 Extrai nomes baseados na POSIÇÃO na frase (lógica inteligente)
  /// 🆕 v7.6.124: REFATORAÇÃO COMPLETA - Elimina necessidade de stopwords
  /// 🆕 v7.6.127: Usa hasNameConflict para relaxar detecção
  /// 🆕 v7.6.136: Detecta automaticamente formato Gemini (maiúsculas)
  ///
  /// Se o texto estiver no formato Gemini (minúsculo + NOMES MAIÚSCULOS),
  /// usa lógica simplificada: nomes são palavras TODO MAIÚSCULAS.
  ///
  /// Caso contrário, usa LÓGICA POSICIONAL:
  /// - Início de frase: Ignora (ex: "Então...") A MENOS que já seja conhecido
  /// - Meio de frase: Captura (ex: "...disse Arthur ontem")
  ///
  /// Parâmetros:
  /// - [text]: Texto a ser analisado
  /// - [knownNames]: Nomes já confirmados (do CharacterTracker)
  static Set<String> extractNamesFromText(
    String text, [
    Set<String>? knownNames,
  ]) {
    final namesFound = <String>{};
    final known = knownNames ?? <String>{};

    if (text.isEmpty) return namesFound;

    // 🆕 v7.6.136: Detecta formato Gemini (minúsculo + NOMES MAIÚSCULOS)
    if (isUppercaseNameFormat(text)) {
      // Extrai nomes do formato simplificado
      final uppercaseNames = extractNamesFromUppercaseFormat(text);

      // Converte para Title Case (MATEUS → Mateus) para compatibilidade
      for (final name in uppercaseNames) {
        final titleCase =
            name[0].toUpperCase() + name.substring(1).toLowerCase();
        namesFound.add(titleCase);
      }

      return namesFound;
    }

    // Lógica tradicional (formato Title Case)
    // 1. Normalizar quebras de linha para facilitar a divisão por frases
    final cleanText = text.replaceAll('\r\n', '\n');

    // 2. Quebrar em frases (Ponto, Exclamação, Interrogação, Quebra de linha, Dois-pontos)
    // O regex olha para pontuação seguida de espaço ou fim de linha
    final sentences = cleanText.split(RegExp(r'[.?!:\n]+'));

    for (var sentence in sentences) {
      sentence = sentence.trim();
      if (sentence.isEmpty) continue;

      // 3. Quebrar em palavras
      final words = sentence.split(RegExp(r'\s+'));

      for (var i = 0; i < words.length; i++) {
        // Limpar pontuação da palavra (ex: "Arthur," -> "Arthur")
        // Mantém letras, acentos unicode e hífens
        String word = words[i].replaceAll(RegExp(r'[^\w\u00C0-\u017F\-]'), '');

        if (word.length < 2) continue; // Ignora letras soltas

        // Verifica se começa com Maiúscula
        bool isCapitalized =
            word[0] == word[0].toUpperCase() &&
            word[0] != word[0].toLowerCase();

        if (!isCapitalized) continue;

        // --- LÓGICA POSICIONAL INTELIGENTE ---

        if (i == 0) {
          // CASO 1: Início da frase (ex: "Então", "Mas", "Arthur", "Carlos")
          // 🔥 v7.6.140: Aplicar mesmo filtro do meio da frase
          // Se já conhecido OU se parecer nome real → aceitar
          if (known.contains(word)) {
            namesFound.add(word);
          } else if (word.length >= 3 &&
              word.length <= 30 &&
              looksLikePersonName(word)) {
            // Nome desconhecido mas que PARECE nome de pessoa
            namesFound.add(word);
          }
        } else {
          // CASO 2: Meio da frase (ex: "...disse Arthur para...")
          // Se tem maiúscula no meio, 99% de chance de ser nome próprio.

          // 🔥 v7.6.132: Filtro adicional - rejeitar palavras indefinidas/verbos
          // Ex: "Fui", "Como", "Quais" → ignorar
          if (word.length < 3) continue; // Muito curto (ex: "Ah", "Ou")
          if (word.length > 30) continue;
          if (!looksLikePersonName(word)) continue;

          namesFound.add(word);
        }
      }
    }

    // 🎯 v7.6.124: Detectar nomes compostos (Arthur Evans, Mary Jane)
    // Usar regex mais preciso para capturar apenas no meio de frases
    final compoundPattern = RegExp(
      r'(?<!^|[.?!:\n])\s+([A-ZÀ-Ú][a-zà-ú]{1,14}\s+[A-ZÀ-Ú][a-zà-ú]{1,14})(?=\s|[,.;]|$)',
      multiLine: true,
    );

    for (final match in compoundPattern.allMatches(cleanText)) {
      final fullName = match.group(1)?.trim();
      if (fullName != null) {
        // 🔥 v7.6.132: Filtrar FRASES antes de adicionar
        // Ex: "Mas Mateus", "Ou Otávio" → ignorar
        if (isPhrase(fullName)) continue;
        if (isCommonPhrase(fullName)) continue;

        // 🔥 v7.6.141: Filtrar INSTITUIÇÕES antes de adicionar
        // Ex: "Escola Municipal", "Hospital Central", "Prefeitura Municipal" → ignorar
        final lowerFullName = fullName.toLowerCase();
        final nameWords = lowerFullName.split(RegExp(r'\s+'));
        bool isInstitution = nameWords.any(
          (word) => institutionIndicators.contains(word),
        );
        if (isInstitution) continue;

        // 🔥 v7.6.141: Verificar se cada palavra do composto parece nome
        // Evita "Sonho Grande" (ambos stopwords)
        final parts = fullName.split(RegExp(r'\s+'));
        bool allPartsLookLikeNames = parts.every(
          (part) =>
              part.length >= 3 &&
              part.length <= 30 &&
              looksLikePersonName(part),
        );
        if (!allPartsLookLikeNames) continue;

        namesFound.add(fullName);
      }
    }

    // 🇰🇷 v7.6.149: Pós-processamento para nomes coreanos
    // Problema: "Park Ji-seong" é detectado como ["Park", "Ji", "seong"]
    // Solução: Mesclar nomes coreanos no formato "Sobrenome Nome-composto"
    final koreanNames = _mergeKoreanNames(text, namesFound);
    namesFound.addAll(koreanNames);

    // 🇰🇷 Remover partes individuais de nomes coreanos
    // Ex: Se "Park Ji-seong" existe, remover "Ji", "seong"
    namesFound.removeWhere((name) {
      // Se for nome muito curto (2-3 letras) E existir nome composto contendo ele
      if (name.length <= 3) {
        return koreanNames.any((korean) => korean.contains(name));
      }
      return false;
    });

    // 🇰🇷 v7.6.150: REMOVIDO detecção automática de hangul
    // Problema: Capturava TODAS palavras coreanas (사무실로, 돌아오는, etc) como nomes
    // Solução: Gemini já gera nomes romanizados (park min-jun, jung tae-soo)
    // Resultado: 534+ falsos positivos → 2-5 nomes reais ✅

    return namesFound;
  }

  /// 🇰🇷 v7.6.149: Detecta e mescla nomes coreanos com hífen
  /// Formato: Sobrenome Nome-composto (ex: Park Ji-seong, Kim Min-jun)
  /// 🇰🇷 v7.6.150: Apenas nomes romanizados (Gemini não gera hangul)
  static Set<String> _mergeKoreanNames(String text, Set<String> detectedNames) {
    final koreanNames = <String>{};
    
    // Lista de sobrenomes coreanos comuns (romanizado)
    const koreanSurnames = {
      'Kim', 'Lee', 'Park', 'Choi', 'Jung', 'Kang', 'Cho', 'Yoon',
      'Jang', 'Lim', 'Han', 'Oh', 'Seo', 'Shin', 'Kwon', 'Hwang',
      'Ahn', 'Song', 'Hong', 'Jeon', 'Baek', 'Moon', 'Yang', 'Koh',
    };

    // Regex para nomes ROMANIZADOS: Sobrenome Nome-composto
    // Ex: "Park Ji-seong", "Kim Min-ho"
    final romanPattern = RegExp(
      r'\b([A-Z][a-z]+)\s+([A-Z][a-z]+(?:-[A-Z][a-z]+)?)\b'
    );

    for (final match in romanPattern.allMatches(text)) {
      final surname = match.group(1);
      final givenName = match.group(2);
      
      if (surname != null && givenName != null) {
        // Verificar se o sobrenome é coreano
        if (koreanSurnames.contains(surname)) {
          final fullName = '$surname $givenName';
          koreanNames.add(fullName);
        }
      }
    }

    // 🇰🇷 v7.6.150: REMOVIDO detecção de hangul
    // Gemini gera nomes romanizados, não em 한글

    return koreanNames;
  }

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
  /// 🔧 v7.6.124: Versão com lógica posicional
  static List<String> validateNamesInText(
    String newBlock,
    Set<String> previousNames,
  ) {
    final duplicates = <String>[];
    // 🆕 v7.6.124: Passar previousNames como knownNames para extração posicional
    final newNames = extractNamesFromText(newBlock, previousNames);

    // Validação case-sensitive
    for (final name in newNames) {
      if (previousNames.contains(name)) {
        if (!duplicates.contains(name)) {
          duplicates.add(name);
        }
      }
    }

    // 🎯 Validação case-insensitive para nomes em minúsculas
    // Detecta casos como "my lawyer, mark" onde "mark" deveria ser "Mark"
    final previousNamesLower = previousNames
        .map((n) => n.toLowerCase())
        .toSet();

    final lowercasePattern = RegExp(r'\b([a-z][a-z]{1,14})\b');
    final lowercaseMatches = lowercasePattern.allMatches(newBlock);

    for (final match in lowercaseMatches) {
      final word = match.group(1);
      if (word != null && previousNamesLower.contains(word.toLowerCase())) {
        // Verificar se não é palavra comum
        if (!_commonLowerWords.contains(word.toLowerCase())) {
          final originalName = previousNames.firstWhere(
            (n) => n.toLowerCase() == word.toLowerCase(),
            orElse: () => word,
          );

          if (!duplicates.contains(originalName)) {
            duplicates.add(originalName);
          }
        }
      }
    }

    return duplicates;
  }

  /// 🔧 v7.6.77: Palavras comuns em minúsculas (não são nomes)
  static const Set<String> _commonLowerWords = {
    'the',
    'and',
    'but',
    'for',
    'with',
    'from',
    'about',
    'into',
    'through',
    'during',
    'before',
    'after',
    'above',
    'below',
    'between',
    'under',
    'again',
    'further',
    'then',
    'once',
    'here',
    'there',
    'when',
    'where',
    'why',
    'how',
    'all',
    'each',
    'other',
    'some',
    'such',
    'only',
    'own',
    'same',
    'than',
    'too',
    'very',
    'can',
    'will',
    'just',
    'now',
    'like',
    'back',
    'even',
    'still',
    'also',
    'well',
    'way',
    'because',
    'while',
    'since',
    'until',
    'both',
    'was',
    'were',
    'been',
    'being',
    'have',
    'has',
    'had',
    'having',
    'does',
    'did',
    'doing',
    'would',
    'could',
    'should',
    'might',
    'must',
    'shall',
    'may',
  };

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
