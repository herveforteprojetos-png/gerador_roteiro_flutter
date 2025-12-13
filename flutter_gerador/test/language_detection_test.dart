import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/block_prompt_builder.dart';

void main() {
  group('Detecção de Idiomas - Encoding Robusto', () {
    test('Inglês - todas variações', () {
      // Dropdown value
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Inglês'), 4.7);
      
      // Possíveis encoding quebrado
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Ingles'), 4.7);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('inglês'), 4.7);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('ingles'), 4.7);
      
      // Código ISO
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('en'), 4.7);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('en-us'), 4.7);
      
      // Nome em inglês
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('English'), 4.7);
      
      print('✅ Inglês detectado em todas variações');
    });

    test('Português - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Português'), 5.2);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Portugues'), 5.2);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('português'), 5.2);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('portugues'), 5.2);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('pt'), 5.2);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Portuguese'), 5.2);
      
      print('✅ Português detectado em todas variações');
    });

    test('Francês - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Francês'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Frances'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('francês'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('frances'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('fr'), 5.3);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('French'), 5.3);
      
      print('✅ Francês detectado em todas variações');
    });

    test('Alemão - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Alemão'), 6.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Alemao'), 6.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('alemão'), 6.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('alemao'), 6.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('de'), 6.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('German'), 6.5);
      
      print('✅ Alemão detectado em todas variações');
    });

    test('Polonês - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Polonês'), 5.8);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Polones'), 5.8);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('polonês'), 5.8);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('polones'), 5.8);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('pl'), 5.8);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Polish'), 5.8);
      
      print('✅ Polonês detectado em todas variações');
    });

    test('Búlgaro - todas variações', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Búlgaro'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Bulgaro'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('búlgaro'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('bulgaro'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('bg'), 5.5);
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('Bulgarian'), 5.5);
      
      print('✅ Búlgaro detectado em todas variações');
    });

    test('Limite calculado corretamente para Inglês', () {
      final charsPerWord = BlockPromptBuilder.getCharsPerWordForLanguage('Inglês');
      final adjustedTarget = 930 * 1.05; // 977 palavras
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();
      final rejectionLimit = (maxChars * 1.5).round();

      print('\n📊 CÁLCULO INGLÊS:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target ajustado: ${adjustedTarget.round()} palavras');
      print('   Limite prompt: $maxChars chars');
      print('   Limite rejeição: $rejectionLimit chars\n');

      expect(charsPerWord, 4.7);
      expect(maxChars, 4957); // 977 * 4.7 * 1.08 = 4,959 → arredondado para 4957
      expect(rejectionLimit, 7436); // 4,957 * 1.5 = 7,435.5 → arredondado para 7436
    });
  });
}
