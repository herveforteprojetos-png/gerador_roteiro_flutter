import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/localization_level.dart';

class ScriptConfigNotifier extends StateNotifier<ScriptConfig> {
  ScriptConfigNotifier()
      : super(ScriptConfig(
          apiKey: '',
          model: 'gemini-2.5-pro',
          title: '',
          tema: 'História',
          subtema: 'Narrativa Básica',
          localizacao: '',
          measureType: 'palavras',
          quantity: 2000,
          language: 'Português',
          perspective: 'terceira_pessoa',
          localizationLevel: LocalizationLevel.national,
          startWithTitlePhrase: false, // NOVO: Default false
          protagonistName: '',
          secondaryCharacterName: '',
        ));

  // 🚨 FUNÇÃO PARA DETECTAR IDIOMAS PROBLEMÁTICOS
  String _getOptimalModelForLanguage(String language, String currentModel) {
    // Idiomas do leste europeu que têm problemas com filtros de conteúdo do Pro
    const problematicLanguages = ['Búlgaro', 'Polonês', 'Croata', 'Romeno', 'Turco', 'Russo'];
    
    if (problematicLanguages.contains(language)) {
      // CORREÇÃO: Sempre usar 2.5 Pro para qualidade máxima
      return 'gemini-2.5-pro'; // ÚNICO MODELO DISPONÍVEL: Pro 2.5
    }
    
    // Para outros idiomas, manter o modelo escolhido pelo usuário
    return currentModel;
  }

  // Lista de temas disponíveis
  static const List<String> temas = [
    'História',
    'Ciência',
    'Saúde',
    'Tecnologia',
    'Natureza',
    'Mistério/Suspense',
    'Terror/Sobrenatural',
    'Ficção Científica',
    'Drama/Romance',
    'Comédia/Humor',
    'Curiosidades',
    'Biografias',
    'Viagens/Lugares',
  ];

  void updateApiKey(String value) {
    state = state.copyWith(apiKey: value);
  }

  void updateModel(String value) {
    // 🚨 VERIFICAÇÃO: Sempre usar Pro 2.5 para qualidade máxima
    final finalModel = _getOptimalModelForLanguage(state.language, value);
    state = state.copyWith(model: finalModel);
    
    // 🚨 AVISO se modelo foi sobrescrito
    if (finalModel != value) {
      print('🚨 ScriptConfig: Modelo $value não compatível com idioma ${state.language} - usando $finalModel');
    }
  }

  void updateTitle(String value) {
    state = state.copyWith(title: value);
  }

  void updateTema(String value) {
    state = state.copyWith(tema: value);
  }

  void updateLocalizacao(String value) {
    state = state.copyWith(localizacao: value);
  }

  // Context removido - método não é mais necessário

  void updateMeasureType(String value) {
    state = state.copyWith(measureType: value);
  }

  void updateQuantity(int value) {
    state = state.copyWith(quantity: value);
  }

  void updateLanguage(String value) {
    // 🚨 AJUSTE AUTOMÁTICO: Sempre usar Pro 2.5 para qualidade máxima
    final optimalModel = _getOptimalModelForLanguage(value, state.model);
    final previousModel = state.model;

    state = state.copyWith(language: value, model: optimalModel);

    if (optimalModel != previousModel) {
      print('🚨 ScriptConfig: Idioma $value detectado - modelo mudado automaticamente para $optimalModel');
    }
  }

  void updateQualityMode(String mode) {
    // Atualizar qualityMode que será usado pelo gemini_service
    state = state.copyWith(qualityMode: mode);
    print('🤖 ScriptConfig: Modelo alterado para ${mode == "pro" ? "2.5-PRO (Qualidade Máxima)" : "2.5-FLASH (4x Mais Rápido)"}');
  }

  void updatePerspective(String value) {
    state = state.copyWith(perspective: value);
  }
}

final scriptConfigProvider = StateNotifierProvider<ScriptConfigNotifier, ScriptConfig>((ref) {
  return ScriptConfigNotifier();
});



