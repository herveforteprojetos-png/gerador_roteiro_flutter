import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/block_prompt_builder.dart';

void main() {
  group('TODOS 13 Idiomas - Detecção Robusta', () {
    test('1. Português - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Português'), 5.2);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Portugues'), 5.2);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('português'), 5.2);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('pt'), 5.2);
      print('✅ 1. PORTUGUÊS: 5.2 chars/palavra');
    });

    test('2. Inglês - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Inglês'), 4.7);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Ingles'), 4.7);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('inglês'), 4.7);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('en'), 4.7);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('English'), 4.7);
      print('✅ 2. INGLÊS: 4.7 chars/palavra');
    });

    test('3. Espanhol - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Espanhol'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('espanhol'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Español'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('es'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Spanish'), 5.3);
      print('✅ 3. ESPANHOL: 5.3 chars/palavra');
    });

    test('4. Francês - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Francês'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Frances'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('francês'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('fr'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('French'), 5.3);
      print('✅ 4. FRANCÊS: 5.3 chars/palavra');
    });

    test('5. Alemão - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Alemão'), 6.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Alemao'), 6.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('alemão'), 6.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('de'), 6.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('German'), 6.5);
      print('✅ 5. ALEMÃO: 6.5 chars/palavra');
    });

    test('6. Italiano - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Italiano'), 5.2);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('italiano'), 5.2);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('it'), 5.2);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Italian'), 5.2);
      print('✅ 6. ITALIANO: 5.2 chars/palavra');
    });

    test('7. Polonês - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Polonês'), 5.8);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Polones'), 5.8);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('polonês'), 5.8);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('pl'), 5.8);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Polish'), 5.8);
      print('✅ 7. POLONÊS: 5.8 chars/palavra');
    });

    test('8. Búlgaro - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Búlgaro'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Bulgaro'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('búlgaro'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('bg'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Bulgarian'), 5.5);
      print('✅ 8. BÚLGARO: 5.5 chars/palavra');
    });

    test('9. Russo - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Russo'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('russo'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('ru'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Russian'), 5.5);
      print('✅ 9. RUSSO: 5.5 chars/palavra');
    });

    test('10. Coreano - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Coreano'), 2.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('coreano'), 2.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('ko'), 2.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Korean'), 2.5);
      print('✅ 10. COREANO: 2.5 chars/palavra');
    });

    test('11. Turco - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Turco'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('turco'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('tr'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Turkish'), 5.3);
      print('✅ 11. TURCO: 5.3 chars/palavra');
    });

    test('12. Romeno - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Romeno'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('romeno'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('ro'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Romanian'), 5.3);
      print('✅ 12. ROMENO: 5.3 chars/palavra');
    });

    test('13. Croata - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Croata'), 5.7);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('croata'), 5.7);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('hr'), 5.7);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Hrvatski'), 5.7);
      print('✅ 13. CROATA: 5.7 chars/palavra');
    });

    test('Resumo: Todos 13 idiomas configurados', () {
      final idiomas = [
        {'nome': 'Português', 'chars': 5.2},
        {'nome': 'Inglês', 'chars': 4.7},
        {'nome': 'Espanhol', 'chars': 5.3},
        {'nome': 'Francês', 'chars': 5.3},
        {'nome': 'Alemão', 'chars': 6.5},
        {'nome': 'Italiano', 'chars': 5.2},
        {'nome': 'Polonês', 'chars': 5.8},
        {'nome': 'Búlgaro', 'chars': 5.5},
        {'nome': 'Russo', 'chars': 5.5},
        {'nome': 'Coreano', 'chars': 2.5},
        {'nome': 'Turco', 'chars': 5.3},
        {'nome': 'Romeno', 'chars': 5.3},
        {'nome': 'Croata', 'chars': 5.7},
      ];

      print('\n══════════════════════════════════════════════════════');
      print('✅ TODOS 13 IDIOMAS CONFIGURADOS E TESTADOS');
      print('══════════════════════════════════════════════════════');
      for (final idioma in idiomas) {
        final result = BlockPromptBuilder.getCharsPerWordForLanguage(idioma['nome'] as String);
        expect(result, idioma['chars']);
        print('   ${idioma['nome']}: ${idioma['chars']} chars/palavra');
      }
      print('══════════════════════════════════════════════════════\n');

      expect(idiomas.length, 13);
    });
  });
}
