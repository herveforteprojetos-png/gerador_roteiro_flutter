class GenerationConfig {
  final String apiKey;
  final String model;
  final String title;
  final String measureType; // 'palavras' ou 'caracteres'
  final int quantity;
  final String language;
  final String perspective;
  final bool includeCallToAction;

  const GenerationConfig({
    required this.apiKey,
    required this.model,
    required this.title,
    this.measureType = 'palavras',
    this.quantity = 1000,
    this.language = 'português',
    this.perspective = 'terceira_pessoa',
    this.includeCallToAction = false,
  });

  GenerationConfig copyWith({
    String? apiKey,
    String? model,
    String? title,
    String? measureType,
    int? quantity,
    String? language,
    String? perspective,
    bool? includeCallToAction,
  }) {
    return GenerationConfig(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      title: title ?? this.title,
      measureType: measureType ?? this.measureType,
      quantity: quantity ?? this.quantity,
      language: language ?? this.language,
      perspective: perspective ?? this.perspective,
      includeCallToAction: includeCallToAction ?? this.includeCallToAction,
    );
  }

  // Opções disponíveis
  static const List<String> availableLanguages = [
    'alemão',
    'búlgaro',
    'mexicano',
    'francês',
    'inglês',
    'italiano',
    'polonês',
    'português',
    'turco',
    'romeno',
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
    'alemão': 'Alemão',
    'búlgaro': 'Búlgaro',
    'mexicano': 'Mexicano',
    'francês': 'Francês',
    'inglês': 'Inglês',
    'italiano': 'Italiano',
    'polonês': 'Polonês',
    'português': 'Português',
    'turco': 'Turco',
    'romeno': 'Romeno',
  };

  // Limites para sliders
  static const Map<String, Map<String, int>> measureLimits = {
    'palavras': {'min': 500, 'max': 14000, 'default': 2000},
    'caracteres': {'min': 1000, 'max': 100000, 'default': 5000},
  };
}
