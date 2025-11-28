import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/generation_config.dart';
import '../../data/models/localization_level.dart';

class GenerationConfigNotifier extends StateNotifier<GenerationConfig> {
  GenerationConfigNotifier()
    : super(
        const GenerationConfig(
          apiKey: '',
          model: 'gemini-2.5-pro',
          title: '',
          tema: 'Vingança',
          subtema: 'Vingança Destrutiva',
          localizacao: '',
          personalizedTheme: '',
          usePersonalizedTheme: false,
        ),
      );

  void updateApiKey(String apiKey) {
    print('🔐 updateApiKey chamado: "${apiKey}"');
    state = state.copyWith(apiKey: apiKey);
    print('🔐 state.apiKey agora é: "${state.apiKey}"');
  }

  void updateOpenAIKey(String openAIKey) {
    print('🤖 updateOpenAIKey chamado: "${openAIKey.isEmpty ? "(vazia)" : "***"}"');
    state = state.copyWith(openAIKey: openAIKey.isEmpty ? null : openAIKey);
    print('🤖 state.openAIKey configurada');
  }

  void updateSelectedProvider(String provider) {
    print('🎯 updateSelectedProvider chamado: "$provider"');
    state = state.copyWith(selectedProvider: provider);
    print('🎯 state.selectedProvider agora é: "${state.selectedProvider}"');
  }

  void updateModel(String model) {
    state = state.copyWith(model: model);
  }

  void updateQualityMode(String mode) {
    state = state.copyWith(qualityMode: mode);
    print(
      '🤖 Modelo alterado para: ${mode == "pro" ? "Gemini 2.5-PRO (Melhor Qualidade)" : "Gemini 2.5-FLASH (4x Mais Rápido)"}',
    );
  }

  void updateTitle(String title) {
    print('📰 updateTitle chamado: "${title}"');
    state = state.copyWith(title: title);
    print('📰 state.title agora é: "${state.title}"');
  }

  void updateTema(String tema) {
    final defaultSubtema = GenerationConfig.getDefaultSubtema(tema);
    state = state.copyWith(tema: tema, subtema: defaultSubtema);
  }

  void updateSubtema(String subtema) {
    state = state.copyWith(subtema: subtema);
  }

  void updateLocalizacao(String localizacao) {
    state = state.copyWith(localizacao: localizacao);
  }

  void updateMeasureType(String measureType) {
    final limits = GenerationConfig.measureLimits[measureType]!;
    state = state.copyWith(
      measureType: measureType,
      quantity: limits['default']!,
    );
  }

  void updateQuantity(int quantity) {
    state = state.copyWith(quantity: quantity);
  }

  void updateLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void updatePerspective(String perspective) {
    state = state.copyWith(perspective: perspective);
  }

  void updatePersonalizedTheme(String theme) {
    state = state.copyWith(personalizedTheme: theme);
  }

  void updateUsePersonalizedTheme(bool use) {
    state = state.copyWith(usePersonalizedTheme: use);
    // limpar o campo
    if (!use) {
      state = state.copyWith(personalizedTheme: '');
    }
  }

  void updatePersonalizedSubtheme(String subtheme) {
    state = state.copyWith(personalizedSubtheme: subtheme);
  }

  void updatePersonalizedSecondarySubtheme(String secondarySubtheme) {
    state = state.copyWith(personalizedSecondarySubtheme: secondarySubtheme);
  }

  void updateLocalizationLevel(LocalizationLevel level) {
    state = state.copyWith(localizationLevel: level);
  }

  void updateStartWithTitlePhrase(bool value) {
    state = state.copyWith(startWithTitlePhrase: value);
  }

  void updateProtagonistName(String value) {
    state = state.copyWith(protagonistName: value);
  }

  void updateSecondaryCharacterName(String value) {
    state = state.copyWith(secondaryCharacterName: value);
  }

  void updateGenre(String? value) {
    state = state.copyWith(genre: value);
  }

  void updateNarrativeStyle(String value) {
    state = state.copyWith(narrativeStyle: value);
  }

  void updateCustomPrompt(String value) {
    state = state.copyWith(customPrompt: value);
  }

  void updateUseCustomPrompt(bool use) {
    state = state.copyWith(useCustomPrompt: use);
    // Limpar o campo se desativado
    if (!use) {
      state = state.copyWith(customPrompt: '');
    }
  }

  void clearAll() {
    // Preservar a API key e modelo ao limpar
    final currentApiKey = state.apiKey;
    final currentModel = state.model;

    state = GenerationConfig(
      apiKey: currentApiKey,
      model: currentModel,
      title: '',
      tema: 'Vingança',
      subtema: 'Vingança Destrutiva',
      localizacao: '',
      personalizedTheme: '',
      usePersonalizedTheme: false,
      startWithTitlePhrase: false,
    );
  }

  bool get isValid {
    // ✅ VALIDAÇÃO SIMPLIFICADA: Apenas API Key + Título são obrigatórios
    // Tema, localização e outros campos são OPCIONAIS
    final apiKeyValid = state.apiKey.isNotEmpty;
    final titleValid = state.title.isNotEmpty;
    final quantityValid = state.quantity > 0;
    final result = apiKeyValid && titleValid && quantityValid;

    print('🔍 VALIDAÇÃO isValid:');
    print(
      '  ✅ API Key: "${state.apiKey}" -> ${apiKeyValid ? "VÁLIDO" : "INVÁLIDO (vazio)"}',
    );
    print(
      '  ✅ Título: "${state.title}" -> ${titleValid ? "VÁLIDO" : "INVÁLIDO (vazio)"}',
    );
    print(
      '  ✅ Quantidade: ${state.quantity} -> ${quantityValid ? "VÁLIDO" : "INVÁLIDO"}',
    );
    print('  🎯 RESULTADO FINAL: ${result ? "✅ VÁLIDO" : "❌ INVÁLIDO"}');

    return result;
  }

  int get minQuantity {
    return GenerationConfig.measureLimits[state.measureType]!['min']!;
  }

  int get maxQuantity {
    return GenerationConfig.measureLimits[state.measureType]!['max']!;
  }
}

final generationConfigProvider =
    StateNotifierProvider<GenerationConfigNotifier, GenerationConfig>((ref) {
      return GenerationConfigNotifier();
    });
