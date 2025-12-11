import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/main_prompt_template.dart';

/// 🆕 v7.6.143: Valida instrução "Show, Don't Tell"
///
/// Garante que o prompt inclui orientação para mostrar emoções
/// através de ações físicas ao invés de "tells" diretos.
void main() {
  group('v7.6.143 - Show, Don\'t Tell Instruction', () {
    test('Prompt inclui seção "Show, Don\'t Tell"', () {
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

      // Verifica presença da seção
      expect(prompt, contains('SHOW, DON\'T TELL'));
      expect(prompt, contains('v7.6.143'));

      // Verifica instruções-chave
      expect(prompt, contains('MOSTRE emoções através de AÇÕES físicas'));
      expect(prompt, contains('NÃO diga diretamente'));

      // Verifica exemplos de "evite"
      expect(prompt, contains('EVITE (tell)'));
      expect(prompt, contains('"Ele sentiu medo"'));
      expect(prompt, contains('"Estava nervoso"'));
      expect(prompt, contains('"Sentiu um arrepio"'));

      // Verifica exemplos de "mostre"
      expect(prompt, contains('MOSTRE (show)'));
      expect(prompt, contains('Suas mãos tremeram'));
      expect(prompt, contains('Engoliu em seco'));
      expect(prompt, contains('dedos tamborilaram'));

      // Verifica regras práticas
      expect(prompt, contains('AÇÕES CONCRETAS'));
      expect(prompt, contains('REAÇÕES FÍSICAS'));
      expect(prompt, contains('Prefira SEMPRE show'));
    });

    test('Instrução aparece antes das regras de estrutura', () {
      final prompt = MainPromptTemplate.buildCompactPrompt(
        language: 'Escreva em PORTUGUÊS (Brasil)',
        instruction: 'Continue',
        temaSection: '',
        localizacao: '',
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

      final showDontTellIndex = prompt.indexOf('SHOW, DON\'T TELL');
      final act3Index = prompt.indexOf('ATO 3');

      // Show Don't Tell deve aparecer ANTES das regras de Ato 3
      expect(showDontTellIndex, greaterThan(0));
      expect(showDontTellIndex, lessThan(act3Index));
    });

    test('Exemplos práticos cobrem cenários comuns', () {
      final prompt = MainPromptTemplate.buildCompactPrompt(
        language: 'Escreva em PORTUGUÊS (Brasil)',
        instruction: 'Continue',
        temaSection: '',
        localizacao: '',
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

      // Exemplos de emoções básicas (tells comuns)
      expect(prompt, contains('"Ele sentiu medo"'));
      expect(prompt, contains('"Estava nervoso"'));
      expect(prompt, contains('"Ficou surpreso"'));

      // Alternativas físicas (shows)
      expect(prompt, contains('"Suas mãos tremeram'));
      expect(prompt, contains('"Engoliu em seco'));
      expect(prompt, contains('"Desviou o olhar'));

      // Cobre diferentes tipos de reação
      expect(prompt, contains('gestos'));
      expect(prompt, contains('movimentos'));
      expect(prompt, contains('expressões faciais'));
      expect(prompt, contains('respiração'));
      expect(prompt, contains('postura'));
    });

    test('Funciona com idioma espanhol', () {
      final prompt = MainPromptTemplate.buildCompactPrompt(
        language: 'Escribe en ESPAÑOL',
        instruction: 'Continúa la narrativa',
        temaSection: 'Tema: Drama',
        localizacao: '',
        localizationGuidance: '',
        narrativeStyleGuidance: '',
        customPrompt: '',
        useCustomPrompt: false,
        nameList: '',
        trackerInfo: '',
        measure: 'GENERA EXACTAMENTE 1000 palabras',
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

      // Instrução deve aparecer mesmo em espanhol (está em português/inglês)
      expect(prompt, contains('SHOW, DON\'T TELL'));
      expect(prompt, contains('MOSTRE emoções'));
    });
  });
}
