import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/main_prompt_template.dart';

void main() {
  group('v7.6.144 - Vocabulário Simples', () {
    test('Prompt inclui seção de vocabulário simples', () {
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
      );

      // Verifica presença da seção
      expect(prompt, contains('VOCABULÁRIO SIMPLES'));
      expect(prompt, contains('v7.6.144'));

      // Verifica instruções-chave
      expect(prompt, contains('LINGUAGEM DE 8ª SÉRIE'));
      expect(prompt, contains('O público OUVE'));

      // Verifica exemplos de palavras proibidas
      expect(prompt, contains('PALAVRAS COMPLEXAS PROIBIDAS'));
      expect(prompt, contains('fibrocimento'));
      expect(prompt, contains('paralelepípedos'));
      expect(prompt, contains('impecável'));
      expect(prompt, contains('fervilhava'));
      expect(prompt, contains('burocrático'));

      // Verifica substituições sugeridas
      expect(prompt, contains('telha de amianto'));
      expect(prompt, contains('pedras da rua'));
      expect(prompt, contains('arrumado/perfeito'));
      expect(prompt, contains('estava agitada'));
      expect(prompt, contains('complicado'));

      // Verifica regras práticas
      expect(prompt, contains('Palavras de 1-3 sílabas'));
      expect(prompt, contains('Vocabulário do dia a dia'));
      expect(prompt, contains('REGRA DE OURO'));
      expect(prompt, contains('criança de 13 anos'));
    });

    test('Seção aparece antes das regras de estrutura', () {
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
      );

      final vocabularioIndex = prompt.indexOf('VOCABULÁRIO SIMPLES');
      final estructuraIndex = prompt.indexOf('ESTRUTURA DE 3 ATOS');

      expect(vocabularioIndex, greaterThan(0),
          reason: 'Seção de vocabulário deve existir');
      expect(estructuraIndex, greaterThan(0),
          reason: 'Seção de estrutura deve existir');
      expect(vocabularioIndex, lessThan(estructuraIndex),
          reason:
              'Vocabulário simples deve aparecer ANTES das regras de estrutura');
    });

    test('Inclui exemplos práticos de substituição', () {
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
      );

      // Deve conter pares de substituição
      expect(prompt, contains('→'));

      // Exemplos específicos de substituição
      final hasFibrocimento = prompt.contains('fibrocimento');
      final hasTelha = prompt.contains('telha');
      expect(hasFibrocimento && hasTelha, isTrue,
          reason: 'Deve mostrar fibrocimento → telha');

      final hasParaleleppedos = prompt.contains('paralelepípedos');
      final hasPedras = prompt.contains('pedras da rua');
      expect(hasParaleleppedos && hasPedras, isTrue,
          reason: 'Deve mostrar paralelepípedos → pedras da rua');
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
      );

      // A seção deve aparecer mesmo em espanhol (é universal)
      expect(prompt, contains('VOCABULÁRIO SIMPLES'));
      expect(prompt, contains('v7.6.144'));
    });

    test('Contém regra de teste para simplicidade', () {
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
      );

      // Deve ter a regra de ouro que serve como teste mental
      expect(prompt, contains('REGRA DE OURO'));
      expect(prompt, contains('conversa casual'));
      expect(prompt, contains('COMPLEXA DEMAIS'));
    });
  });
}
