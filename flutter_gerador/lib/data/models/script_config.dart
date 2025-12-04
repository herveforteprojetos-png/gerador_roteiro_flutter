import 'package:flutter/foundation.dart';
import 'localization_level.dart';
import 'generation_config.dart';

// Formatos de vídeo disponíveis
enum VideoFormat {
  standard, // Sem otimização específica (padrão original)
  youtubeShort, // 1-3 min (200-600 palavras) - Ultra dinâmico
  youtubeMedium, // 8-15 min (1.500-3.000 palavras) - Dinâmico
  youtubeLong, // 20-30 min (4.000-6.000 palavras) - Equilibrado
}

extension VideoFormatExtension on VideoFormat {
  String get displayName {
    switch (this) {
      case VideoFormat.standard:
        return 'Padrão';
      case VideoFormat.youtubeShort:
        return 'YouTube Short (1-3 min)';
      case VideoFormat.youtubeMedium:
        return 'YouTube Médio (8-15 min)';
      case VideoFormat.youtubeLong:
        return 'YouTube Longo (20-30 min)';
    }
  }

  // Target de palavras recomendado para cada formato
  int get recommendedWordCount {
    switch (this) {
      case VideoFormat.standard:
        return 1500; // 🔥 CORRIGIDO: Default razoável (~8 min)
      case VideoFormat.youtubeShort:
        return 400; // ~2 min
      case VideoFormat.youtubeMedium:
        return 2200; // ~12 min
      case VideoFormat.youtubeLong:
        return 5000; // ~25 min
    }
  }

  // Duração aproximada em minutos
  String get approximateDuration {
    switch (this) {
      case VideoFormat.standard:
        return 'Variável';
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
  final String? openAIKey; // 🤖 NOVO: API Key OpenAI (fallback)
  final String selectedProvider; // 🤖 NOVO: 'gemini' ou 'openai'
  final String model;
  final String title;
  final String tema;
  final String subtema;
  final String localizacao;
  final String measureType;
  final int quantity;
  final String language;
  final String perspective;
  final LocalizationLevel localizationLevel;
  final bool startWithTitlePhrase; // NOVO: Começar com frase do título
  final String
  qualityMode; // NOVO: Modo de qualidade (balanced, quality, speed)
  final String protagonistName;
  final String secondaryCharacterName;
  final String?
  genre; // NOVO: Tipo temático da história ('western', 'business', 'family')
  final String
  narrativeStyle; // NOVO: Estilo de narração ('ficcional_livre', 'reflexivo_memorias', etc.)
  final VideoFormat videoFormat; // 🎬 NOVO: Formato de vídeo YouTube
  final String customPrompt; // 📝 NOVO: Prompt personalizado do usuário
  final bool useCustomPrompt; // 📝 NOVO: Habilitar prompt personalizado

  ScriptConfig({
    required this.apiKey,
    this.openAIKey, // 🤖 NOVO: Opcional
    this.selectedProvider = 'gemini', // 🤖 NOVO: Padrão Gemini
    required this.model,
    required this.title,
    required this.tema,
    required this.subtema,
    required this.localizacao,
    required this.measureType,
    required this.quantity,
    required this.language,
    required this.perspective,
    required this.localizationLevel,
    this.startWithTitlePhrase = false, // NOVO: Default false
    this.qualityMode = 'balanced', // NOVO: Padrão balanceado
    this.protagonistName = '',
    this.secondaryCharacterName = '',
    this.genre, // NOVO: Opcional (null = nomes do idioma, 'western' = nomes western)
    this.narrativeStyle = 'ficcional_livre', // NOVO: Padrão é narração livre
    this.videoFormat =
        VideoFormat.standard, // 🎬 NOVO: Padrão é standard (sem otimização)
    this.customPrompt = '', // 📝 NOVO: Padrão vazio
    this.useCustomPrompt = false, // 📝 NOVO: Padrão desabilitado
  }) {
    // 🔥 VALIDAÇÕES
    if (quantity <= 0) {
      throw ArgumentError('quantity deve ser maior que 0');
    }
    if (apiKey.trim().isEmpty) {
      throw ArgumentError('apiKey não pode ser vazia');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('title não pode ser vazio');
    }
  }

  // Factory para conversão de GenerationConfig
  factory ScriptConfig.fromGenerationConfig(GenerationConfig config) {
    debugPrint('🔄 ScriptConfig.fromGenerationConfig()');
    debugPrint('📥 GenerationConfig.qualityMode = "${config.qualityMode}"');

    // 🎯 Se usar tema personalizado, usar personalizedTheme (pode ser vazio = sem tema)
    // Se personalizedTheme estiver vazio, usar 'Livre (Sem Tema)' como indicador
    final temaFinal = config.usePersonalizedTheme
        ? (config.personalizedTheme.trim().isEmpty
              ? 'Livre (Sem Tema)'
              : config.personalizedTheme)
        : config.tema;

    final subtemFinal = config.usePersonalizedTheme
        ? config
              .personalizedSubtheme // 🎯 NOVO: Usar subtema personalizado
        : config.subtema;

    // 🎯 NOVO: Adicionar subtema secundário ao final do subtema se existir
    final subtemaCompleto =
        config.usePersonalizedTheme &&
            config.personalizedSecondarySubtheme.trim().isNotEmpty
        ? (subtemFinal.isEmpty
              ? config.personalizedSecondarySubtheme
              : '$subtemFinal | ${config.personalizedSecondarySubtheme}')
        : subtemFinal;

    return ScriptConfig(
      apiKey: config.apiKey,
      openAIKey: config.openAIKey, // 🤖 NOVO: Fallback OpenAI
      selectedProvider: config.selectedProvider, // 🤖 NOVO: Qual API usar
      model: config.model,
      title: config.title,
      tema: temaFinal,
      subtema:
          subtemaCompleto, // 🎯 USAR subtemaCompleto que contém ambos subtemas
      localizacao: config.localizacao,
      measureType: config.measureType,
      quantity: config.quantity,
      language: config.language,
      perspective: config.perspective,
      localizationLevel: config.localizationLevel,
      startWithTitlePhrase: config.startWithTitlePhrase,
      qualityMode: config.qualityMode,
      protagonistName: config.protagonistName,
      secondaryCharacterName: config.secondaryCharacterName,
      genre: config.genre, // NOVO: Tipo temático
      narrativeStyle: config.narrativeStyle, // NOVO: Estilo de narração
      videoFormat: VideoFormat
          .standard, // 🎬 NOVO: Por padrão usa standard (será adicionado ao GenerationConfig depois)
      customPrompt: config.customPrompt, // 📝 NOVO: Prompt personalizado
      useCustomPrompt: config.useCustomPrompt, // 📝 NOVO: Habilitar prompt
    ).._debugLog();
  }

  void _debugLog() {
    debugPrint('📦 ScriptConfig criado:');
    debugPrint('   qualityMode = "$qualityMode"');
  }

  ScriptConfig copyWith({
    String? apiKey,
    String? model,
    String? title,
    String? tema,
    String? subtema,
    String? localizacao,
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
    String? narrativeStyle,
    VideoFormat? videoFormat, // 🎬 NOVO
    String? customPrompt, // 📝 NOVO
    bool? useCustomPrompt, // 📝 NOVO
  }) {
    return ScriptConfig(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      title: title ?? this.title,
      tema: tema ?? this.tema,
      subtema: subtema ?? this.subtema,
      localizacao: localizacao ?? this.localizacao,
      measureType: measureType ?? this.measureType,
      quantity: quantity ?? this.quantity,
      language: language ?? this.language,
      perspective: perspective ?? this.perspective,
      localizationLevel: localizationLevel ?? this.localizationLevel,
      startWithTitlePhrase: startWithTitlePhrase ?? this.startWithTitlePhrase,
      qualityMode: qualityMode ?? this.qualityMode,
      protagonistName: protagonistName ?? this.protagonistName,
      secondaryCharacterName:
          secondaryCharacterName ?? this.secondaryCharacterName,
      genre: genre ?? this.genre,
      narrativeStyle: narrativeStyle ?? this.narrativeStyle,
      videoFormat: videoFormat ?? this.videoFormat, // 🎬 NOVO
      customPrompt: customPrompt ?? this.customPrompt, // 📝 NOVO
      useCustomPrompt: useCustomPrompt ?? this.useCustomPrompt, // 📝 NOVO
    );
  }
}
