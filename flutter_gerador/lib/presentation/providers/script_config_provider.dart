import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/localization_level.dart';

class ScriptConfigNotifier extends StateNotifier<ScriptConfig> {
  ScriptConfigNotifier()
    : super(
        ScriptConfig(
          apiKey: '',
          model: 'gemini-2.5-pro',
          title: '',
          tema: 'Hist�ria',
          subtema: 'Narrativa B�sica',
          localizacao: '',
          measureType: 'palavras',
          quantity: 2000,
          language: 'Portugu�s',
          perspective: 'terceira_pessoa',
          localizationLevel: LocalizationLevel.national,
          startWithTitlePhrase: false, // NOVO: Default false
          protagonistName: '',
          secondaryCharacterName: '',
        ),
      );

  // ?? FUN��O PARA DETECTAR IDIOMAS PROBLEM�TICOS
  String _getOptimalModelForLanguage(String language, String currentModel) {
    // Idiomas do leste europeu que t�m problemas com filtros de conte�do do Pro
    const problematicLanguages = [
      'B�lgaro',
      'Polon�s',
      'Croata',
      'Romeno',
      'Turco',
      'Russo',
    ];

    if (problematicLanguages.contains(language)) {
      // CORRE��O: Sempre usar 2.5 Pro para qualidade m�xima
      return 'gemini-2.5-pro'; // �NICO MODELO DISPON�VEL: Pro 2.5
    }

    // Para outros idiomas, manter o modelo escolhido pelo usu�rio
    return currentModel;
  }

  // Lista de temas dispon�veis
  static const List<String> temas = [
    'Hist�ria',
    'Ci�ncia',
    'Sa�de',
    'Tecnologia',
    'Natureza',
    'Mist�rio/Suspense',
    'Terror/Sobrenatural',
    'Fic��o Cient�fica',
    'Drama/Romance',
    'Com�dia/Humor',
    'Curiosidades',
    'Biografias',
    'Viagens/Lugares',
  ];

  void updateApiKey(String value) {
    state = state.copyWith(apiKey: value);
  }

  void updateModel(String value) {
    // ?? VERIFICA��O: Sempre usar Pro 2.5 para qualidade m�xima
    final finalModel = _getOptimalModelForLanguage(state.language, value);
    state = state.copyWith(model: finalModel);

    // ?? AVISO se modelo foi sobrescrito
    if (finalModel != value) {
      debugPrint(
        '?? ScriptConfig: Modelo $value n�o compat�vel com idioma ${state.language} - usando $finalModel',
      );
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

  // Context removido - m�todo n�o � mais necess�rio

  void updateMeasureType(String value) {
    state = state.copyWith(measureType: value);
  }

  void updateQuantity(int value) {
    state = state.copyWith(quantity: value);
  }

  void updateLanguage(String value) {
    // ?? AJUSTE AUTOM�TICO: Sempre usar Pro 2.5 para qualidade m�xima
    final optimalModel = _getOptimalModelForLanguage(value, state.model);
    final previousModel = state.model;

    state = state.copyWith(language: value, model: optimalModel);

    if (optimalModel != previousModel) {
      debugPrint(
        '?? ScriptConfig: Idioma $value detectado - modelo mudado automaticamente para $optimalModel',
      );
    }
  }

  void updateQualityMode(String mode) {
    // Atualizar qualityMode que ser� usado pelo gemini_service
    state = state.copyWith(qualityMode: mode);
    debugPrint(
      '?? ScriptConfig: Modelo alterado para ${mode == "pro" ? "2.5-PRO (Qualidade M�xima)" : "2.5-FLASH (4x Mais R�pido)"}',
    );
  }

  void updatePerspective(String value) {
    state = state.copyWith(perspective: value);
  }
}

final scriptConfigProvider =
    StateNotifierProvider<ScriptConfigNotifier, ScriptConfig>((ref) {
      return ScriptConfigNotifier();
    });
