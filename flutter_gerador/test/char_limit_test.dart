import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/block_prompt_builder.dart';

void main() {
  group('Teste de Limites de Caracteres - 13 Idiomas', () {
    test('1. Português - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Português');
      final adjustedTarget = 930 * 1.0;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇧🇷 PORTUGUÊS:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 5.2);
    });

    test('2. Inglês - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Inglês');
      final adjustedTarget = 930 * 1.05;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇺🇸 INGLÊS:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 4.7);
    });

    test('3. Espanhol - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Espanhol');
      final adjustedTarget = 930 * 0.85;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇪🇸 ESPANHOL:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 5.3);
    });

    test('4. Francês - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Francês');
      final adjustedTarget = 930 * 0.90;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇫🇷 FRANCÊS:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 5.3);
    });

    test('5. Alemão - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Alemão');
      final adjustedTarget = 930 * 1.0;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇩🇪 ALEMÃO:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 6.5);
    });

    test('6. Italiano - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Italiano');
      final adjustedTarget = 930 * 0.92;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇮🇹 ITALIANO:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 5.2);
    });

    test('7. Polonês - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Polonês');
      final adjustedTarget = 930 * 1.05;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇵🇱 POLONÊS:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 5.8);
    });

    test('8. Búlgaro - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Búlgaro');
      final adjustedTarget = 930 * 1.15;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇧🇬 BÚLGARO:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 5.5);
    });

    test('9. Russo - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Russo');
      final adjustedTarget = 930 * 1.15;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇷🇺 RUSSO:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 5.5);
    });

    test('10. Coreano - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Coreano');
      final adjustedTarget = 930 * 1.20;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇰🇷 COREANO:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 2.5);
    });

    test('11. Turco - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Turco');
      final adjustedTarget = 930 * 1.10;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇹🇷 TURCO:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 5.3);
    });

    test('12. Romeno - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Romeno');
      final adjustedTarget = 930 * 0.92;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇷🇴 ROMENO:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 5.3);
    });

    test('13. Croata - 930 palavras', () {
      final charsPerWord =
          BlockPromptBuilder.getCharsPerWordForLanguage('Croata');
      final adjustedTarget = 930 * 1.05;
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('🇭🇷 CROATA:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   Validação máx: ${(maxChars * 1.5).round()} chars\n');

      expect(charsPerWord, 5.7);
    });
  });
}
