import 'localization_level.dart';
import 'generation_config.dart';

// Formatos de vÃ­deo disponÃ­veis
enum VideoFormat {
  standard,        // Sem otimizaÃ§Ã£o especÃ­fica (padrÃ£o original)
  youtubeShort,    // 1-3 min (200-600 palavras) - Ultra dinÃ¢mico
  youtubeMedium,   // 8-15 min (1.500-3.000 palavras) - DinÃ¢mico
  youtubeLong,     // 20-30 min (4.000-6.000 palavras) - Equilibrado
}

extension VideoFormatExtension on VideoFormat {
  String get displayName {
    switch (this) {
      case VideoFormat.standard:
        return 'PadrÃ£o';
      case VideoFormat.youtubeShort:
        return 'YouTube Short (1-3 min)';
      case VideoFormat.youtubeMedium:
        return 'YouTube MÃ©dio (8-15 min)';
      case VideoFormat.youtubeLong:
        return 'YouTube Longo (20-30 min)';
    }
  }
  
  // Target de palavras recomendado para cada formato
  int get recommendedWordCount {
    switch (this) {
      case VideoFormat.standard:
        return 0; // Usa quantity do usuÃ¡rio
      case VideoFormat.youtubeShort:
        return 400; // ~2 min
      case VideoFormat.youtubeMedium:
        return 2200; // ~12 min
      case VideoFormat.youtubeLong:
        return 5000; // ~25 min
    }
  }
  
  // DuraÃ§Ã£o aproximada em minutos
  String get approximateDuration {
    switch (this) {
      case VideoFormat.standard:
        return 'VariÃ¡vel';
      case VideoFormat.youtubeShort:
        return '1-3 min';
      case VideoFormat.youtubeMedium:
        return '8-15 min';
      case VideoFormat.youtubeLong:
        return '20-30 min';
    }
  }
}

// Modelo principal do projeto
class ScriptConfig {
  final String apiKey;
  final String model;
  final String title;
  final String tema;
  final String subtema;
  final String localizacao;
  final String context;
  final String measureType;
  final int quantity;
  final String language;
  final String perspective;
  final LocalizationLevel localizationLevel;
  final bool startWithTitlePhrase; // NOVO: ComeÃ§ar com frase do tÃ­tulo
  final String qualityMode; // NOVO: Modo de qualidade (balanced, quality, speed)
  final String protagonistName;
  final String secondaryCharacterName;
  final String? genre; // NOVO: Tipo temÃ¡tico da histÃ³ria ('western', 'business', 'family')
  final VideoFormat videoFormat; // ðŸŽ¬ NOVO: Formato de vÃ­deo YouTube

  ScriptConfig({
    required this.apiKey,
    required this.model,
    required this.title,
    required this.tema,
    required this.subtema,
    required this.localizacao,
    required this.context,
    required this.measureType,
    required this.quantity,
    required this.language,
    required this.perspective,
    required this.localizationLevel,
    this.startWithTitlePhrase = false, // NOVO: Default false
    this.qualityMode = 'balanced', // NOVO: PadrÃ£o balanceado
    this.protagonistName = '',
    this.secondaryCharacterName = '',
    this.genre, // NOVO: Opcional (null = nomes do idioma, 'western' = nomes western)
    this.videoFormat = VideoFormat.standard, // ðŸŽ¬ NOVO: PadrÃ£o Ã© standard (sem otimizaÃ§Ã£o)
  });

  // Factory para conversÃ£o de GenerationConfig
  factory ScriptConfig.fromGenerationConfig(GenerationConfig config) {
    // ðŸŽ¯ Se usar tema personalizado, usar personalizedTheme (pode ser vazio = sem tema)
    // Se personalizedTheme estiver vazio, usar 'Livre (Sem Tema)' como indicador
    final temaFinal = config.usePersonalizedTheme
        ? (config.personalizedTheme.trim().isEmpty ? 'Livre (Sem Tema)' : config.personalizedTheme)
        : config.tema;
    
    final subtemFinal = config.usePersonalizedTheme
        ? '' // Subtema nÃ£o se aplica a temas personalizados
        : config.subtema;
    
    return ScriptConfig(
      apiKey: config.apiKey,
      model: config.model,
      title: config.title,
      tema: temaFinal,
      subtema: subtemFinal,
      localizacao: config.localizacao,
      context: config.context,
      measureType: config.measureType,
      quantity: config.quantity,
      language: config.language,
      perspective: config.perspective,
      localizationLevel: config.localizationLevel,
      startWithTitlePhrase: config.startWithTitlePhrase,
      qualityMode: config.qualityMode ?? 'balanced', // NOVO: Suporte ao modo de qualidade
      protagonistName: config.protagonistName,
      secondaryCharacterName: config.secondaryCharacterName,
      genre: config.genre, // NOVO: Tipo temÃ¡tico
      videoFormat: VideoFormat.standard, // ðŸŽ¬ NOVO: Por padrÃ£o usa standard (serÃ¡ adicionado ao GenerationConfig depois)
    );
  }

  ScriptConfig copyWith({
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
    LocalizationLevel? localizationLevel,
    bool? startWithTitlePhrase,
    String? qualityMode,
    String? protagonistName,
    String? secondaryCharacterName,
    String? genre,
    VideoFormat? videoFormat, // ðŸŽ¬ NOVO
  }) {
    return ScriptConfig(
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
      localizationLevel: localizationLevel ?? this.localizationLevel,
      startWithTitlePhrase: startWithTitlePhrase ?? this.startWithTitlePhrase,
      qualityMode: qualityMode ?? this.qualityMode,
      protagonistName: protagonistName ?? this.protagonistName,
      secondaryCharacterName: secondaryCharacterName ?? this.secondaryCharacterName,
      genre: genre ?? this.genre,
      videoFormat: videoFormat ?? this.videoFormat, // ðŸŽ¬ NOVO
    );
  }
}

