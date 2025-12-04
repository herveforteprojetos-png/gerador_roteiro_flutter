import 'localization_level.dart';

class GenerationConfig {
  final String apiKey;
  final String? openAIKey; // 🤖 NOVO: API Key OpenAI (fallback)
  final String
  selectedProvider; // 🤖 NOVO: 'gemini' ou 'openai' - qual API usar
  final String model;
  final String title;
  final String tema;
  final String subtema;
  final String localizacao;
  final String measureType; // 'palavras' ou 'caracteres'
  final int quantity;
  final String language;
  final String perspective;
  final String personalizedTheme; // Tema personalizado do usuário
  final bool usePersonalizedTheme; // Se deve usar tema personalizado
  final String personalizedSubtheme; // Subtema principal personalizado
  final String
  personalizedSecondarySubtheme; // Subtema secundário personalizado
  final LocalizationLevel localizationLevel; // Nível de regionalismo
  final bool startWithTitlePhrase; // Se deve começar com a frase do título
  final String protagonistName; // Nome do protagonista
  final String secondaryCharacterName; // Nome do personagem secundário
  final String
  qualityMode; // Modelo IA: 'pro' (2.5-pro), 'flash' (2.5-flash, 4x rápido), 'ultra' (3.0-preview, +avançado)
  final String?
  genre; // Tipo temático da História: null (normal), 'western', 'business', 'family'
  final String
  narrativeStyle; // Estilo de narração: 'ficcional_livre', 'reflexivo_memorias', 'epico_periodo', etc.
  final String
  customPrompt; // Prompt customizado opcional para instruções específicas avançadas
  final bool useCustomPrompt; // Se deve usar o prompt customizado

  const GenerationConfig({
    required this.apiKey,
    this.openAIKey, // 🤖 NOVO: Opcional
    this.selectedProvider = 'gemini', // 🤖 NOVO: Padrão Gemini
    required this.model,
    required this.title,
    this.tema = 'Vingança',
    this.subtema = 'Vingança Destrutiva',
    this.localizacao = '',
    this.measureType = 'palavras',
    this.quantity = 1000,
    this.language = 'Português',
    this.perspective = 'terceira_pessoa',
    this.personalizedTheme = '',
    this.usePersonalizedTheme = false,
    this.personalizedSubtheme = '',
    this.personalizedSecondarySubtheme = '',
    this.localizationLevel = LocalizationLevel.national,
    this.startWithTitlePhrase = false,
    this.protagonistName = '',
    this.secondaryCharacterName = '',
    this.qualityMode = 'pro', // Padrão: Qualidade Máxima (2.5-pro)
    this.genre, // Opcional: null = nomes do idioma
    this.narrativeStyle =
        'ficcional_livre', // Padrão: Narração livre (sem restrições)
    this.customPrompt = '', // Padrão: vazio (não usa)
    this.useCustomPrompt = false, // Padrão: desativado
  });

  GenerationConfig copyWith({
    String? apiKey,
    String? openAIKey, // 🤖 NOVO
    String? selectedProvider, // 🤖 NOVO
    String? model,
    String? title,
    String? tema,
    String? subtema,
    String? localizacao,
    String? measureType,
    int? quantity,
    String? language,
    String? perspective,
    String? personalizedTheme,
    bool? usePersonalizedTheme,
    String? personalizedSubtheme,
    String? personalizedSecondarySubtheme,
    LocalizationLevel? localizationLevel,
    bool? startWithTitlePhrase,
    String? protagonistName,
    String? secondaryCharacterName,
    String? qualityMode,
    String? genre,
    String? narrativeStyle,
    String? customPrompt,
    bool? useCustomPrompt,
  }) {
    return GenerationConfig(
      apiKey: apiKey ?? this.apiKey,
      openAIKey: openAIKey ?? this.openAIKey, // 🤖 NOVO
      selectedProvider: selectedProvider ?? this.selectedProvider, // 🤖 NOVO
      model: model ?? this.model,
      title: title ?? this.title,
      tema: tema ?? this.tema,
      subtema: subtema ?? this.subtema,
      localizacao: localizacao ?? this.localizacao,
      measureType: measureType ?? this.measureType,
      quantity: quantity ?? this.quantity,
      language: language ?? this.language,
      perspective: perspective ?? this.perspective,
      personalizedTheme: personalizedTheme ?? this.personalizedTheme,
      usePersonalizedTheme: usePersonalizedTheme ?? this.usePersonalizedTheme,
      personalizedSubtheme: personalizedSubtheme ?? this.personalizedSubtheme,
      personalizedSecondarySubtheme:
          personalizedSecondarySubtheme ?? this.personalizedSecondarySubtheme,
      localizationLevel: localizationLevel ?? this.localizationLevel,
      startWithTitlePhrase: startWithTitlePhrase ?? this.startWithTitlePhrase,
      protagonistName: protagonistName ?? this.protagonistName,
      secondaryCharacterName:
          secondaryCharacterName ?? this.secondaryCharacterName,
      qualityMode: qualityMode ?? this.qualityMode,
      genre: genre ?? this.genre,
      narrativeStyle: narrativeStyle ?? this.narrativeStyle,
      customPrompt: customPrompt ?? this.customPrompt,
      useCustomPrompt: useCustomPrompt ?? this.useCustomPrompt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'openAIKey': openAIKey, // 🤖 NOVO
      'selectedProvider': selectedProvider, // 🤖 NOVO
      'model': model,
      'title': title,
      'tema': tema,
      'subtema': subtema,
      'localizacao': localizacao,
      'measureType': measureType,
      'quantity': quantity,
      'language': language,
      'perspective': perspective,
      'personalizedTheme': personalizedTheme,
      'usePersonalizedTheme': usePersonalizedTheme,
      'personalizedSubtheme': personalizedSubtheme,
      'personalizedSecondarySubtheme': personalizedSecondarySubtheme,
      'localizationLevel': localizationLevel.name,
      'startWithTitlePhrase': startWithTitlePhrase,
      'protagonistName': protagonistName,
      'secondaryCharacterName': secondaryCharacterName,
      'qualityMode': qualityMode,
      'genre': genre,
      'narrativeStyle': narrativeStyle,
      'customPrompt': customPrompt,
      'useCustomPrompt': useCustomPrompt,
    };
  }

  factory GenerationConfig.fromJson(Map<String, dynamic> json) {
    return GenerationConfig(
      apiKey: json['apiKey'] ?? '',
      openAIKey: json['openAIKey'], // 🤖 NOVO: Nullable
      selectedProvider:
          json['selectedProvider'] ?? 'gemini', // 🤖 NOVO: Padrão gemini
      model: json['model'] ?? 'gemini-1.5-pro',
      title: json['title'] ?? '',
      tema: json['tema'] ?? 'Vingança',
      subtema: json['subtema'] ?? 'Vingança Destrutiva',
      localizacao: json['localizacao'] ?? '',
      measureType: json['measureType'] ?? 'palavras',
      quantity: json['quantity'] ?? 1000,
      language: json['language'] ?? 'Português',
      perspective: json['perspective'] ?? 'terceira_pessoa',
      personalizedTheme: json['personalizedTheme'] ?? '',
      usePersonalizedTheme: json['usePersonalizedTheme'] ?? false,
      personalizedSubtheme: json['personalizedSubtheme'] ?? '',
      personalizedSecondarySubtheme:
          json['personalizedSecondarySubtheme'] ?? '',
      localizationLevel: LocalizationLevel.values.firstWhere(
        (level) => level.name == json['localizationLevel'],
        orElse: () => LocalizationLevel.national,
      ),
      startWithTitlePhrase: json['startWithTitlePhrase'] ?? false,
      protagonistName: json['protagonistName'] ?? '',
      secondaryCharacterName: json['secondaryCharacterName'] ?? '',
      qualityMode: json['qualityMode'] ?? 'pro', // Padrão: Pro
      genre: json['genre'], // Nullable: null = nomes do idioma
      narrativeStyle:
          json['narrativeStyle'] ?? 'ficcional_livre', // Padrão: Narração livre
      customPrompt: json['customPrompt'] ?? '', // Padrão: vazio
      useCustomPrompt: json['useCustomPrompt'] ?? false, // Padrão: desativado
    );
  }

  // OpÃ§Ãµes disponíveis
  static const List<String> availableLanguages = [
    'Alemão',
    'Búlgaro',
    'Coreano (한국어)',
    'Croata',
    'Espanhol(mexicano)',
    'Francês',
    'Inglês',
    'Italiano',
    'Polonês',
    'Português',
    'Russo',
    'Turco',
    'Romeno',
  ];

  static const List<String> availablePerspectives = [
    'terceira_pessoa',
    'primeira_pessoa_homem_jovem',
    'primeira_pessoa_homem_maduro',
    'primeira_pessoa_homem_idoso',
    'primeira_pessoa_mulher_jovem',
    'primeira_pessoa_mulher_madura',
    'primeira_pessoa_mulher_idosa',
  ];

  static const Map<String, String> perspectiveLabels = {
    'terceira_pessoa': 'Terceira Pessoa',
    'primeira_pessoa_homem_jovem': 'Primeira Pessoa Homem Jovem (20-35 anos)',
    'primeira_pessoa_homem_maduro': 'Primeira Pessoa Homem Maduro (35-50 anos)',
    'primeira_pessoa_homem_idoso': 'Primeira Pessoa Homem Idoso (50+ anos)',
    'primeira_pessoa_mulher_jovem': 'Primeira Pessoa Mulher Jovem (20-35 anos)',
    'primeira_pessoa_mulher_madura':
        'Primeira Pessoa Mulher Madura (35-50 anos)',
    'primeira_pessoa_mulher_idosa': 'Primeira Pessoa Mulher Idosa (50+ anos)',
  };

  static const Map<String, String> languageLabels = {
    'Alemão': 'Alemão',
    'Búlgaro': 'Búlgaro',
    'Coreano (한국어)': 'Coreano (한국어)',
    'Croata': 'Croata',
    'Espanhol(mexicano)': 'Espanhol (Mexicano)',
    'Francês': 'Francês',
    'Inglês': 'Inglês',
    'Italiano': 'Italiano',
    'Polonês': 'Polonês',
    'Português': 'Português',
    'Russo': 'Russo',
    'Turco': 'Turco',
    'Romeno': 'Romeno',
  };

  // Limites para sliders
  static const Map<String, Map<String, int>> measureLimits = {
    'palavras': {'min': 500, 'max': 14000, 'default': 2000},
    'caracteres': {'min': 1000, 'max': 100000, 'default': 5000},
  };

  // Mapeamento TEMA â†’ SUBTEMAS
  static const Map<String, List<String>> temaSubtemas = {
    // ðŸŽ¯ MODO LIVRE (SEM TEMA)
    'Livre (Sem Tema)': [], // Sem subtemas disponíveis
    // TEMAS DRAMÃTICOS E INTENSOS
    'Vingança': [
      'Vingança Destrutiva',
      'Vingança Construtiva',
      'Justiça Poética',
      'Vingança Silenciosa',
      'Vingança Familiar',
    ],
    'Traição': [
      'Traição Amorosa',
      'Traição Política',
      'Traição Familiar',
      'Traição Profissional',
      'AutoTraição',
    ],
    'Redenção': [
      'Redenção Religiosa',
      'Redenção Social',
      'Redenção Familiar',
      'Redenção Profissional',
      'AutorRedenção',
    ],
    'Justiça': [
      'Justiça Legal',
      'Justiça Social',
      'Justiça Vigilante',
      'Justiça Divina',
      'Justiça Restaurativa',
    ],
    'SacrifÃ­cio': [
      'SacrifÃ­cio Heroico',
      'SacrifÃ­cio Familiar',
      'SacrifÃ­cio romântico',
      'SacrifÃ­cio Profissional',
      'SacrifÃ­cio Espiritual',
    ],
    'Poder e Corrupção': [
      'Ascensão Política',
      'Corrupção Gradual',
      'ImpÃ©rio Empresarial',
      'Poder Familiar',
      'Queda do Poder',
    ],
    'Sobrevivência': [
      'Sobrevivência Urbana',
      'Sobrevivência Natural',
      'Sobrevivência EconÃ´mica',
      'Sobrevivência Emocional',
      'Sobrevivência Social',
    ],
    'Família Disfuncional': [
      'Família TÃ³xica',
      'Segredos Familiares',
      'Rivalidade Fraternal',
      'Pais Ausentes',
      'HeranÃ§a Maldita',
    ],
    'Segredos Obscuros': [
      'Segredos do Passado',
      'ConspirAção',
      'Dupla Vida',
      'Segredos Corporativos',
      'Segredos Sobrenaturais',
    ],
    'Ascensão e Queda': [
      'Do Nada ao Tudo',
      'Queda TrÃ¡gica',
      'Ciclos de Poder',
      'Legado Perdido',
      'RessurreiÃ§Ã£o',
    ],

    // GÃŠNEROS CLÃSSICOS
    'Mistério/Suspense': [
      'Crime Investigation',
      'Thriller PsicolÃ³gico',
      'ConspirAção',
      'Mistério Sobrenatural',
      'Cold Case',
    ],
    'Terror/Sobrenatural': [
      'Horror PsicolÃ³gico',
      'Terror Sobrenatural',
      'Horror Corporal',
      'Terror CÃ³smico',
      'Survival Horror',
    ],
    'Ficção CientÃ­fica': [
      'Distopia Futurista',
      'ExplorAção Espacial',
      'InteligÃªncia Artificial',
      'Viagem no Tempo',
      'Biotecnologia',
    ],
    'Drama/Romance': [
      'Amor Proibido',
      'Segunda Chance',
      'TriÃ¢ngulo Amoroso',
      'Amor PlatÃ´nico',
      'Amor Eterno',
    ],
    'ComÃ©dia/Humor': [
      'ComÃ©dia RomÃ¢ntica',
      'SÃ¡tira Social',
      'ComÃ©dia de Erros',
      'Humor Negro',
      'ParÃ³dia',
    ],
    'Ação/Aventura': [
      'MissÃ£o ImpossÃ­vel',
      'Jornada Ã‰pica',
      'PerseguiÃ§Ã£o',
      'Heist',
      'Aventura HistÃ³rica',
    ],

    // TEMAS EDUCATIVOS
    'História': [
      'Grandes CivilizaÃ§Ãµes',
      'Guerras Mundiais',
      'RevoluÃ§Ãµes',
      'Biografias HistÃ³ricas',
      'História Local',
    ],
    'Ciência': [
      'Descobertas CientÃ­ficas',
      'Experimentos Famosos',
      'Cientistas Pioneiros',
      'Ciência Aplicada',
      'Fronteiras da Ciência',
    ],
    'Saúde': [
      'PrevenÃ§Ã£o',
      'DoenÃ§as e Tratamentos',
      'Saúde Mental',
      'NutriÃ§Ã£o',
      'ExercÃ­cio e Fitness',
    ],
    'Tecnologia': [
      'InovaÃ§Ãµes TecnolÃ³gicas',
      'Impacto Social da Tech',
      'ProgramAção e Desenvolvimento',
      'Startups e Empreendedorismo',
      'Futuro Digital',
    ],
    'Natureza': [
      'Ecossistemas',
      'ConservAção Ambiental',
      'Vida Selvagem',
      'MudanÃ§as ClimÃ¡ticas',
      'Sustentabilidade',
    ],
    'Biografias': [
      'LÃ­deres HistÃ³ricos',
      'Artistas e Criativos',
      'Cientistas e Inventores',
      'Esportistas',
      'Empreendedores',
    ],
    'Curiosidades': [
      'Fatos HistÃ³ricos Inusitados',
      'Mistérios NÃ£o Resolvidos',
      'CoincidÃªncias IncrÃ­veis',
      'Recordes Mundiais',
      'TradiÃ§Ãµes Culturais',
    ],
    'Viagens/Lugares': [
      'Destinos ExÃ³ticos',
      'Culturas Locais',
      'Monumentos HistÃ³ricos',
      'Gastronomia Regional',
      'Aventuras de Viagem',
    ],
  };

  /// Retorna o tema efetivo que deve ser usado na gerAção
  String get effectiveTheme {
    return usePersonalizedTheme && personalizedTheme.isNotEmpty
        ? personalizedTheme
        : tema;
  }

  /// Retorna o subtema efetivo que deve ser usado na gerAção
  String get effectiveSubtema {
    return usePersonalizedTheme && personalizedTheme.isNotEmpty
        ? '' // Quando usa tema personalizado, nÃ£o usa subtema predefinido
        : subtema;
  }

  // MÃ©todo para obter subtemas de um tema
  static List<String> getSubtemasForTema(String tema) {
    return temaSubtemas[tema] ?? [];
  }

  // Método para obter o primeiro subtema de um tema (padrão)
  static String getDefaultSubtema(String tema) {
    final subtemas = getSubtemasForTema(tema);
    return subtemas.isNotEmpty ? subtemas.first : '';
  }

  // Estilos de narração disponíveis
  static const List<String> availableNarrativeStyles = [
    'ficcional_livre',
    'reflexivo_memorias',
    'epico_periodo',
    'educativo_curioso',
    'acao_rapida',
    'lirico_poetico',
  ];

  // Labels dos estilos de narração
  static const Map<String, String> narrativeStyleLabels = {
    'ficcional_livre': '📖 Ficção Livre',
    'reflexivo_memorias': '👵 Reflexivo (Memórias)',
    'epico_periodo': '⚔️ Épico de Período',
    'educativo_curioso': '🔍 Educativo (Curiosidades)',
    'acao_rapida': '⚡ Ação Rápida',
    'lirico_poetico': '🌸 Lírico Poético',
  };
}
