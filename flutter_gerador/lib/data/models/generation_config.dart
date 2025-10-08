import 'localization_level.dart';

class GenerationConfig {
  final String apiKey;
  final String model;
  final String title;
  final String tema;
  final String subtema;
  final String localizacao;
  final String context;
  final String measureType; // 'palavras' ou 'caracteres'
  final int quantity;
  final String language;
  final String perspective;
  final bool includeCallToAction;
  final bool includeFinalCta;
  final String personalizedTheme; // Tema personalizado do usuário
  final bool usePersonalizedTheme; // Se deve usar tema personalizado
  final LocalizationLevel localizationLevel; // Nível de regionalismo
  final bool startWithTitlePhrase; // Se deve começar com a frase do título
  final String protagonistName; // Nome do protagonista
  final String secondaryCharacterName; // Nome do personagem secundário
  final String qualityMode; // Modo de qualidade: 'balanced', 'quality', 'speed'
  final String? genre; // Tipo temático da história: null (normal), 'western', 'business', 'family'

  const GenerationConfig({
    required this.apiKey,
    required this.model,
    required this.title,
    this.tema = 'Vingança',
    this.subtema = 'Vingança Destrutiva',
    this.localizacao = '',
    this.context = '',
    this.measureType = 'palavras',
    this.quantity = 1000,
    this.language = 'Português',
    this.perspective = 'terceira_pessoa',
    this.includeCallToAction = false,
    this.includeFinalCta = false,
    this.personalizedTheme = '',
    this.usePersonalizedTheme = false,
    this.localizationLevel = LocalizationLevel.national,
    this.startWithTitlePhrase = false,
    this.protagonistName = '',
    this.secondaryCharacterName = '',
    this.qualityMode = 'balanced',
    this.genre, // Opcional: null = nomes do idioma
  });

  GenerationConfig copyWith({
    String? apiKey,
    String? model,
    String? title,
    String? tema,
    String? subtema,
    String? localizacao,
    String? context,
    String? measureType,
    int? quantity,
    String? language,
    String? perspective,
    bool? includeCallToAction,
    bool? includeFinalCta,
    String? personalizedTheme,
    bool? usePersonalizedTheme,
    LocalizationLevel? localizationLevel,
    bool? startWithTitlePhrase,
    String? protagonistName,
    String? secondaryCharacterName,
    String? qualityMode,
    String? genre,
  }) {
    return GenerationConfig(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      title: title ?? this.title,
      tema: tema ?? this.tema,
      subtema: subtema ?? this.subtema,
      localizacao: localizacao ?? this.localizacao,
      context: context ?? this.context,
      measureType: measureType ?? this.measureType,
      quantity: quantity ?? this.quantity,
      language: language ?? this.language,
      perspective: perspective ?? this.perspective,
      includeCallToAction: includeCallToAction ?? this.includeCallToAction,
      includeFinalCta: includeFinalCta ?? this.includeFinalCta,
      personalizedTheme: personalizedTheme ?? this.personalizedTheme,
      usePersonalizedTheme: usePersonalizedTheme ?? this.usePersonalizedTheme,
      localizationLevel: localizationLevel ?? this.localizationLevel,
      startWithTitlePhrase: startWithTitlePhrase ?? this.startWithTitlePhrase,
      protagonistName: protagonistName ?? this.protagonistName,
      secondaryCharacterName: secondaryCharacterName ?? this.secondaryCharacterName,
      qualityMode: qualityMode ?? this.qualityMode,
      genre: genre ?? this.genre,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'model': model,
      'title': title,
      'tema': tema,
      'subtema': subtema,
      'localizacao': localizacao,
      'context': context,
      'measureType': measureType,
      'quantity': quantity,
      'language': language,
      'perspective': perspective,
      'includeCallToAction': includeCallToAction,
      'includeFinalCta': includeFinalCta,
      'personalizedTheme': personalizedTheme,
      'usePersonalizedTheme': usePersonalizedTheme,
      'localizationLevel': localizationLevel.name,
      'startWithTitlePhrase': startWithTitlePhrase,
      'protagonistName': protagonistName,
      'secondaryCharacterName': secondaryCharacterName,
      'qualityMode': qualityMode,
      'genre': genre,
    };
  }

  factory GenerationConfig.fromJson(Map<String, dynamic> json) {
    return GenerationConfig(
      apiKey: json['apiKey'] ?? '',
      model: json['model'] ?? 'gemini-1.5-pro',
      title: json['title'] ?? '',
      tema: json['tema'] ?? 'Vingança',
      subtema: json['subtema'] ?? 'Vingança Destrutiva',
      localizacao: json['localizacao'] ?? '',
      context: json['context'] ?? '',
      measureType: json['measureType'] ?? 'palavras',
      quantity: json['quantity'] ?? 1000,
      language: json['language'] ?? 'Português',
      perspective: json['perspective'] ?? 'terceira_pessoa',
      includeCallToAction: json['includeCallToAction'] ?? false,
      includeFinalCta: json['includeFinalCta'] ?? false,
      personalizedTheme: json['personalizedTheme'] ?? '',
      usePersonalizedTheme: json['usePersonalizedTheme'] ?? false,
      localizationLevel: LocalizationLevel.values.firstWhere(
        (level) => level.name == json['localizationLevel'],
        orElse: () => LocalizationLevel.national,
      ),
      startWithTitlePhrase: json['startWithTitlePhrase'] ?? false,
      protagonistName: json['protagonistName'] ?? '',
      secondaryCharacterName: json['secondaryCharacterName'] ?? '',
      qualityMode: json['qualityMode'] ?? 'balanced',
      genre: json['genre'], // Nullable: null = nomes do idioma
    );
  }

  // Opções disponíveis
  static const List<String> availableLanguages = [
    'Alemão',
    'Búlgaro',
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
    'primeira_pessoa_homem_idoso',
    'primeira_pessoa_homem_jovem',
    'primeira_pessoa_mulher_idosa',
    'primeira_pessoa_mulher_jovem',
  ];

  static const Map<String, String> perspectiveLabels = {
    'terceira_pessoa': 'Terceira Pessoa',
    'primeira_pessoa_homem_idoso': 'Primeira Pessoa Homem Idoso',
    'primeira_pessoa_homem_jovem': 'Primeira Pessoa Homem Jovem de 25 a 40',
    'primeira_pessoa_mulher_idosa': 'Primeira Pessoa Mulher Idosa',
    'primeira_pessoa_mulher_jovem': 'Primeira Pessoa Mulher Jovem de 25 a 40',
  };

  static const Map<String, String> languageLabels = {
    'Alemão': 'Alemão',
    'Búlgaro': 'Búlgaro',
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

  // Mapeamento TEMA → SUBTEMAS
  static const Map<String, List<String>> temaSubtemas = {
    // 🎯 MODO LIVRE (SEM TEMA)
    'Livre (Sem Tema)': [], // Sem subtemas disponíveis
    
    // TEMAS DRAMÁTICOS E INTENSOS
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
      'Autotraição',
    ],
    'Redenção': [
      'Redenção Religiosa',
      'Redenção Social',
      'Redenção Familiar',
      'Redenção Profissional',
      'Autorredenção',
    ],
    'Justiça': [
      'Justiça Legal',
      'Justiça Social',
      'Justiça Vigilante',
      'Justiça Divina',
      'Justiça Restaurativa',
    ],
    'Sacrifício': [
      'Sacrifício Heroico',
      'Sacrifício Familiar',
      'Sacrifício Romântico',
      'Sacrifício Profissional',
      'Sacrifício Espiritual',
    ],
    'Poder e Corrupção': [
      'Ascensão Política',
      'Corrupção Gradual',
      'Império Empresarial',
      'Poder Familiar',
      'Queda do Poder',
    ],
    'Sobrevivência': [
      'Sobrevivência Urbana',
      'Sobrevivência Natural',
      'Sobrevivência Econômica',
      'Sobrevivência Emocional',
      'Sobrevivência Social',
    ],
    'Família Disfuncional': [
      'Família Tóxica',
      'Segredos Familiares',
      'Rivalidade Fraternal',
      'Pais Ausentes',
      'Herança Maldita',
    ],
    'Segredos Obscuros': [
      'Segredos do Passado',
      'Conspiração',
      'Dupla Vida',
      'Segredos Corporativos',
      'Segredos Sobrenaturais',
    ],
    'Ascensão e Queda': [
      'Do Nada ao Tudo',
      'Queda Trágica',
      'Ciclos de Poder',
      'Legado Perdido',
      'Ressurreição',
    ],

    // GÊNEROS CLÁSSICOS
    'Mistério/Suspense': [
      'Crime Investigation',
      'Thriller Psicológico',
      'Conspiração',
      'Mistério Sobrenatural',
      'Cold Case',
    ],
    'Terror/Sobrenatural': [
      'Horror Psicológico',
      'Terror Sobrenatural',
      'Horror Corporal',
      'Terror Cósmico',
      'Survival Horror',
    ],
    'Ficção Científica': [
      'Distopia Futurista',
      'Exploração Espacial',
      'Inteligência Artificial',
      'Viagem no Tempo',
      'Biotecnologia',
    ],
    'Drama/Romance': [
      'Amor Proibido',
      'Segunda Chance',
      'Triângulo Amoroso',
      'Amor Platônico',
      'Amor Eterno',
    ],
    'Comédia/Humor': [
      'Comédia Romântica',
      'Sátira Social',
      'Comédia de Erros',
      'Humor Negro',
      'Paródia',
    ],
    'Ação/Aventura': [
      'Missão Impossível',
      'Jornada Épica',
      'Perseguição',
      'Heist',
      'Aventura Histórica',
    ],

    // TEMAS EDUCATIVOS
    'História': [
      'Grandes Civilizações',
      'Guerras Mundiais',
      'Revoluções',
      'Biografias Históricas',
      'História Local',
    ],
    'Ciência': [
      'Descobertas Científicas',
      'Experimentos Famosos',
      'Cientistas Pioneiros',
      'Ciência Aplicada',
      'Fronteiras da Ciência',
    ],
    'Saúde': [
      'Prevenção',
      'Doenças e Tratamentos',
      'Saúde Mental',
      'Nutrição',
      'Exercício e Fitness',
    ],
    'Tecnologia': [
      'Inovações Tecnológicas',
      'Impacto Social da Tech',
      'Programação e Desenvolvimento',
      'Startups e Empreendedorismo',
      'Futuro Digital',
    ],
    'Natureza': [
      'Ecossistemas',
      'Conservação Ambiental',
      'Vida Selvagem',
      'Mudanças Climáticas',
      'Sustentabilidade',
    ],
    'Biografias': [
      'Líderes Históricos',
      'Artistas e Criativos',
      'Cientistas e Inventores',
      'Esportistas',
      'Empreendedores',
    ],
    'Curiosidades': [
      'Fatos Históricos Inusitados',
      'Mistérios Não Resolvidos',
      'Coincidências Incríveis',
      'Recordes Mundiais',
      'Tradições Culturais',
    ],
    'Viagens/Lugares': [
      'Destinos Exóticos',
      'Culturas Locais',
      'Monumentos Históricos',
      'Gastronomia Regional',
      'Aventuras de Viagem',
    ],
  };

  /// Retorna o tema efetivo que deve ser usado na geração
  String get effectiveTheme {
    return usePersonalizedTheme && personalizedTheme.isNotEmpty 
        ? personalizedTheme 
        : tema;
  }

  /// Retorna o subtema efetivo que deve ser usado na geração
  String get effectiveSubtema {
    return usePersonalizedTheme && personalizedTheme.isNotEmpty 
        ? '' // Quando usa tema personalizado, não usa subtema predefinido
        : subtema;
  }

  // Método para obter subtemas de um tema
  static List<String> getSubtemasForTema(String tema) {
    return temaSubtemas[tema] ?? [];
  }

  // Método para obter o primeiro subtema de um tema (padrão)
  static String getDefaultSubtema(String tema) {
    final subtemas = getSubtemasForTema(tema);
    return subtemas.isNotEmpty ? subtemas.first : '';
  }
}
