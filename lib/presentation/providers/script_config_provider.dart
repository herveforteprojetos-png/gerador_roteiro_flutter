import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/script_config.dart';

class ScriptConfigNotifier extends StateNotifier<ScriptConfig> {
  ScriptConfigNotifier()
      : super(ScriptConfig(
          apiKey: '',
          model: 'gemini-1.5-pro',
          title: '',
          context: '',
          measureType: 'palavras',
          quantity: 1000,
          language: 'pt',
          includeCallToAction: false,
        ));

  // Métodos para atualizar cada campo...
}

final scriptConfigProvider = StateNotifierProvider<ScriptConfigNotifier, ScriptConfig>((ref) {
  return ScriptConfigNotifier();
});
