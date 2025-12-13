import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/main_prompt_template.dart';

void main() {
  group('v7.6.144.1 - Validação Familiar', () {
    test('Prompt inclui regra sobre netos precisarem de filhos', () {
      final prompt = MainPromptTemplate.buildCompactPrompt(
        language: 'Escreva em PORTUGUÊS (Brasil)',
        instruction: 'Continue a narrativa',
        temaSection: 'Tema: Drama',
        localizacao: 'Brasil',
        localizationGuidance: '',
        narrativeStyleGuidance: '',
        customPrompt: '',
        useCustomPrompt: false,
        nameList: '',
        trackerInfo: '',
        measure: 'GERE EXATAMENTE 1000 palavras',
        isSpanish: false,
        adjustedTarget: 1000,
        minAcceptable: 450,
        maxAcceptable: 1500,
        limitedNeeded: 3500,
        contextoPrevio: '',
        avoidRepetition: false,
        characterGuidance: '',
        forbiddenNamesWarning: '',
        labels: {'theme': 'TEMA', 'subtheme': 'SUBTEMA'},
        totalWords: 6000,
      );

      // Verifica presença da regra
      expect(prompt, contains('EVITE'));
      expect(prompt, contains('netos/netas'));
      expect(prompt, contains('estabelecer filhos/pais primeiro'));

      // Verifica que está na seção de vocabulário
      expect(prompt, contains('VOCABULÁRIO SIMPLES'));
      expect(prompt, contains('v7.6.144'));

      // Confirma que menciona "erro de validação"
      expect(prompt, contains('erro de validação'));
    });

    test('Regra está posicionada junto com outras restrições', () {
      final prompt = MainPromptTemplate.buildCompactPrompt(
        language: 'Escreva em PORTUGUÊS (Brasil)',
        instruction: 'Continue a narrativa',
        temaSection: 'Tema: Drama',
        localizacao: 'Brasil',
        localizationGuidance: '',
        narrativeStyleGuidance: '',
        customPrompt: '',
        useCustomPrompt: false,
        nameList: '',
        trackerInfo: '',
        measure: 'GERE EXATAMENTE 1000 palavras',
        isSpanish: false,
        adjustedTarget: 1000,
        minAcceptable: 450,
        maxAcceptable: 1500,
        limitedNeeded: 3500,
        contextoPrevio: '',
        avoidRepetition: false,
        characterGuidance: '',
        forbiddenNamesWarning: '',
        labels: {'theme': 'TEMA', 'subtheme': 'SUBTEMA'},
        totalWords: 6000,
      );

      // Busca a seção EVITE
      final eviteIndex = prompt.indexOf('❌ EVITE:');
      expect(eviteIndex, greaterThan(0), reason: 'Seção EVITE deve existir');

      // Verifica que regra de netos está após EVITE
      final netosIndex = prompt.indexOf('netos/netas');
      expect(
        netosIndex,
        greaterThan(eviteIndex),
        reason: 'Regra de netos deve estar na lista EVITE',
      );

      // Verifica que está antes de PREFIRA
      final prefiraIndex = prompt.indexOf('✅ PREFIRA:');
      expect(
        netosIndex,
        lessThan(prefiraIndex),
        reason: 'Regra de netos deve estar antes de PREFIRA',
      );
    });

    test('Funciona com idioma espanhol', () {
      final prompt = MainPromptTemplate.buildCompactPrompt(
        language: 'Escreva en ESPAÑOL',
        instruction: 'Continúa la narrativa',
        temaSection: 'Tema: Drama',
        localizacao: 'España',
        localizationGuidance: '',
        narrativeStyleGuidance: '',
        customPrompt: '',
        useCustomPrompt: false,
        nameList: '',
        trackerInfo: '',
        measure: 'GENERE EXACTAMENTE 1000 palabras',
        isSpanish: true,
        adjustedTarget: 1000,
        minAcceptable: 450,
        maxAcceptable: 1500,
        limitedNeeded: 3500,
        contextoPrevio: '',
        avoidRepetition: false,
        characterGuidance: '',
        forbiddenNamesWarning: '',
        labels: {'theme': 'TEMA', 'subtheme': 'SUBTEMA'},
        totalWords: 6000,
      );

      // Regra deve aparecer mesmo em espanhol (é universal)
      expect(prompt, contains('netos/netas'));
      expect(prompt, contains('filhos/pais'));
    });
  });
}
