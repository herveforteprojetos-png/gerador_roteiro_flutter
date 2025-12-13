/// 🧪 Teste da função lowercaseExceptNames (v7.6.141)
///
/// Valida normalização de casing para evitar conflitos no validador
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/gemini/validation/post_generation_fixer.dart';

void main() {
  group('lowercaseExceptNames', () {
    test('deve converter tudo para minúsculas sem nomes conhecidos', () {
      const input = 'Para Mariana. O Presidente Costa.';
      const expected = 'para mariana. o presidente costa.';

      final result = PostGenerationFixer.lowercaseExceptNames(input);

      expect(result, expected);
    });

    test('deve preservar nomes conhecidos', () {
      const input = 'Para Mariana. O Presidente Costa falou.';
      const expected = 'para Mariana. o presidente Costa falou.';

      final knownNames = {'Mariana', 'Costa'};
      final result = PostGenerationFixer.lowercaseExceptNames(
        input,
        knownNames: knownNames,
      );

      expect(result, expected);
    });

    test(
      'deve preservar apenas nomes conhecidos (não detectar automaticamente)',
      () {
        // A função NÃO detecta nomes automaticamente, apenas preserva os conhecidos
        const input = 'para Carlos. Helena sorriu para Roberto.';

        // Sem nomes conhecidos, tudo fica lowercase
        final resultWithoutNames = PostGenerationFixer.lowercaseExceptNames(
          input,
        );
        expect(resultWithoutNames, 'para carlos. helena sorriu para roberto.');

        // Com nomes conhecidos, eles são preservados
        final knownNames = {'Carlos', 'Helena', 'Roberto'};
        final resultWithNames = PostGenerationFixer.lowercaseExceptNames(
          input,
          knownNames: knownNames,
        );

        expect(resultWithNames, contains('Carlos'));
        expect(resultWithNames, contains('Helena'));
        expect(resultWithNames, contains('Roberto'));
        expect(resultWithNames, contains('para'));
        expect(resultWithNames, contains('sorriu'));
      },
    );

    test('deve ignorar palavras comuns no início de frases', () {
      const input = 'Para casa. Com amigos. Até logo.';
      const expected = 'para casa. com amigos. até logo.';

      final result = PostGenerationFixer.lowercaseExceptNames(input);

      expect(result, expected);
    });

    test('deve lidar com nomes compostos', () {
      const input = 'Maria Helena conversou com João Pedro.';

      final knownNames = {'Maria Helena', 'João Pedro'};
      final result = PostGenerationFixer.lowercaseExceptNames(
        input,
        knownNames: knownNames,
      );

      expect(result, contains('Maria Helena'));
      expect(result, contains('João Pedro'));
      expect(result, contains('conversou'));
    });

    test('deve ser case-insensitive com nomes conhecidos', () {
      const input = 'MARIANA olhou para mariana e Mariana sorriu.';

      final knownNames = {'Mariana'};
      final result = PostGenerationFixer.lowercaseExceptNames(
        input,
        knownNames: knownNames,
      );

      // Todas as ocorrências de "mariana" (em qualquer case) → "Mariana"
      expect(result, 'Mariana olhou para Mariana e Mariana sorriu.');
    });

    test('deve lidar com texto vazio', () {
      const input = '';

      final result = PostGenerationFixer.lowercaseExceptNames(input);

      expect(result, '');
    });

    test('deve preservar pontuação e espaçamento', () {
      const input = 'Pedro,  Maria.   João!   Ana?';

      final knownNames = {'Pedro', 'Maria', 'João', 'Ana'};
      final result = PostGenerationFixer.lowercaseExceptNames(
        input,
        knownNames: knownNames,
      );

      expect(result, 'Pedro,  Maria.   João!   Ana?');
    });

    test('exemplo do requisito: "para Mariana. o presidente costa."', () {
      const input = 'Para Mariana. O Presidente Costa.';
      const expected = 'para mariana. o presidente costa.';

      final result = PostGenerationFixer.lowercaseExceptNames(input);

      expect(result, expected);
    });

    test('exemplo com nomes válidos capitalizados', () {
      const input = 'Para Mariana. O Presidente Costa.';

      // Se Mariana e Costa forem nomes registrados
      final knownNames = {'Mariana', 'Costa'};
      final result = PostGenerationFixer.lowercaseExceptNames(
        input,
        knownNames: knownNames,
      );

      // Mariana e Costa preservados, resto em lowercase
      expect(result, 'para Mariana. o presidente Costa.');
    });

    test('deve filtrar palavras stopword mesmo capitalizadas', () {
      const input = 'Grande sonho. Central ideia. Municipal escola.';

      final result = PostGenerationFixer.lowercaseExceptNames(input);

      // Todas são stopwords ou palavras comuns, devem ficar minúsculas
      expect(result, 'grande sonho. central ideia. municipal escola.');
    });

    test('deve preservar acentuação em nomes conhecidos', () {
      const input = 'CÉSAR, ÁLVARO e JOÃO conversaram.';

      final knownNames = {'César', 'Álvaro', 'João'};
      final result = PostGenerationFixer.lowercaseExceptNames(
        input,
        knownNames: knownNames,
      );

      // Verificar que os nomes estão capitalizados corretamente
      expect(result, 'César, Álvaro e João conversaram.');
    });
  });
}
