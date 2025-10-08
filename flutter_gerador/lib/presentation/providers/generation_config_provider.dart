import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/generation_config.dart';
import '../../data/models/localization_level.dart';

class GenerationConfigNotifier extends StateNotifier<GenerationConfig> {
  GenerationConfigNotifier() : super(const GenerationConfig(
    apiKey: '',
    model: 'gemini-2.5-pro',
    title: '',
    tema: 'Vingança',
    subtema: 'Vingança Destrutiva',
    localizacao: '',
    personalizedTheme: '',
    usePersonalizedTheme: false,
  ));

  void updateApiKey(String apiKey) {
    state = state.copyWith(apiKey: apiKey);
  }

  void updateModel(String model) {
    state = state.copyWith(model: model);
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateTema(String tema) {
    final defaultSubtema = GenerationConfig.getDefaultSubtema(tema);
    state = state.copyWith(
      tema: tema,
      subtema: defaultSubtema,
    );
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

  void updateIncludeCallToAction(bool include) {
    state = state.copyWith(includeCallToAction: include);
  }

  void updateIncludeFinalCta(bool include) {
    state = state.copyWith(includeFinalCta: include);
  }

  void updatePersonalizedTheme(String theme) {
    state = state.copyWith(personalizedTheme: theme);
  }

  void updateUsePersonalizedTheme(bool use) {
    state = state.copyWith(usePersonalizedTheme: use);
    // Se desabilitou o tema personalizado, limpar o campo
    if (!use) {
      state = state.copyWith(personalizedTheme: '');
    }
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
    return state.apiKey.isNotEmpty && 
           state.title.isNotEmpty &&
           state.quantity > 0 &&
           // Validar tema: predefinido deve ter tema, personalizado PODE estar vazio (= sem tema)
           ((!state.usePersonalizedTheme && state.tema.isNotEmpty) ||
            state.usePersonalizedTheme); // ✅ Permite tema personalizado vazio
  }

  int get minQuantity {
    return GenerationConfig.measureLimits[state.measureType]!['min']!;
  }

  int get maxQuantity {
    return GenerationConfig.measureLimits[state.measureType]!['max']!;
  }
}

final generationConfigProvider = StateNotifierProvider<GenerationConfigNotifier, GenerationConfig>((ref) {
  return GenerationConfigNotifier();
});
