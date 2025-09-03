import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/generation_config.dart';

class GenerationConfigNotifier extends StateNotifier<GenerationConfig> {
  GenerationConfigNotifier() : super(const GenerationConfig(
    apiKey: '',
    model: 'gemini-1.5-pro',
    title: '',
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

  void clearAll() {
    state = const GenerationConfig(
      apiKey: '',
      model: 'gemini-1.5-pro',
      title: '',
    );
  }

  bool get isValid {
    return state.apiKey.isNotEmpty && 
           state.title.isNotEmpty &&
           state.quantity > 0;
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
