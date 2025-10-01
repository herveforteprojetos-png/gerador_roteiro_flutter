import 'localization_level.dart';
import 'generation_config.dart';

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
  final bool includeCallToAction;
  final bool includeFinalCta;
  final LocalizationLevel localizationLevel;
  final bool startWithTitlePhrase; // NOVO: Começar com frase do título
  final String qualityMode; // NOVO: Modo de qualidade (balanced, quality, speed)
  final String protagonistName;
  final String secondaryCharacterName;

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
    required this.includeCallToAction,
    required this.includeFinalCta,
    required this.localizationLevel,
    this.startWithTitlePhrase = false, // NOVO: Default false
    this.qualityMode = 'balanced', // NOVO: Padrão balanceado
    this.protagonistName = '',
    this.secondaryCharacterName = '',
  });

  // Factory para conversão de GenerationConfig
  factory ScriptConfig.fromGenerationConfig(GenerationConfig config) {
    return ScriptConfig(
      apiKey: config.apiKey,
      model: config.model,
      title: config.title,
      tema: config.tema,
      subtema: config.subtema,
      localizacao: config.localizacao,
      context: config.context,
      measureType: config.measureType,
      quantity: config.quantity,
      language: config.language,
      perspective: config.perspective,
      includeCallToAction: config.includeCallToAction,
      includeFinalCta: config.includeFinalCta,
      localizationLevel: config.localizationLevel,
      startWithTitlePhrase: config.startWithTitlePhrase,
      qualityMode: config.qualityMode ?? 'balanced', // NOVO: Suporte ao modo de qualidade
      protagonistName: config.protagonistName,
      secondaryCharacterName: config.secondaryCharacterName,
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
    bool? includeCallToAction,
    bool? includeFinalCta,
    LocalizationLevel? localizationLevel,
    bool? startWithTitlePhrase,
    String? qualityMode,
    String? protagonistName,
    String? secondaryCharacterName,
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
      includeCallToAction: includeCallToAction ?? this.includeCallToAction,
      includeFinalCta: includeFinalCta ?? this.includeFinalCta,
      localizationLevel: localizationLevel ?? this.localizationLevel,
      startWithTitlePhrase: startWithTitlePhrase ?? this.startWithTitlePhrase,
      qualityMode: qualityMode ?? this.qualityMode,
      protagonistName: protagonistName ?? this.protagonistName,
      secondaryCharacterName: secondaryCharacterName ?? this.secondaryCharacterName,
    );
  }
}
