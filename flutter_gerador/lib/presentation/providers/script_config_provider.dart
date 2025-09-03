import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/data/models/script_config.dart';

class ScriptConfigNotifier extends StateNotifier<ScriptConfig> {
  ScriptConfigNotifier()
      : super(ScriptConfig(
          apiKey: '',
          model: 'gemini-1.5-pro',
          title: '',
          context: '',
          measureType: 'palavras',
          quantity: 2000,
          language: 'pt',
          perspective: 'terceira',
          includeCallToAction: false,
        ));

  // Métodos para atualizar cada campo...
}

final scriptConfigProvider = StateNotifierProvider<ScriptConfigNotifier, ScriptConfig>((ref) {
  return ScriptConfigNotifier();
});
