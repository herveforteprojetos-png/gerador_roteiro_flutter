import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/utils/name_generator.dart';

void main() {
  group('NameGenerator v7.6.133 - Validação', () {
    test('Seed aleatório gera letras válidas', () {
      for (var i = 0; i < 20; i++) {
        final seed = NameGenerator.generateInitialSeed();

        // Deve ser uma letra de A-Z (exceto K, W, Y, Z)
        expect(seed.length, 1);
        expect(RegExp(r'^[A-Z]$').hasMatch(seed), true);
        expect(['K', 'W', 'Y', 'Z'].contains(seed), false);
      }
    });

    test('Português gera lista de nomes válida', () {
      final nameList = NameGenerator.generateNameList(
        'Português',
        seedLetter: 'L',
      );

      expect(nameList, contains('Lucas'));
      expect(nameList, contains('Laura'));
      expect(nameList, contains('Leonardo'));
      expect(nameList, contains('Letícia'));
      expect(nameList, contains('Seed: L'));
      expect(nameList, contains('NOMES PROIBIDOS'));
      expect(nameList, contains('Mateus - PROIBIDO'));
    });

    test('English gera lista de nomes válida', () {
      final nameList = NameGenerator.generateNameList(
        'English',
        seedLetter: 'M',
      );

      expect(nameList, contains('Michael'));
      expect(nameList, contains('Matthew'));
      expect(nameList, contains('Mia'));
      expect(nameList, contains('Madison'));
      expect(nameList, contains('Seed: M'));
    });

    test('Español gera lista de nomes válida', () {
      final nameList = NameGenerator.generateNameList(
        'Español',
        seedLetter: 'R',
      );

      expect(nameList, contains('Rafael'));
      expect(nameList, contains('Rosa'));
      expect(nameList, contains('Ricardo'));
      expect(nameList, contains('Seed: R'));
    });

    test('Français gera lista de nomes válida', () {
      final nameList = NameGenerator.generateNameList(
        'Français',
        seedLetter: 'P',
      );

      expect(nameList, contains('Pierre'));
      expect(nameList, contains('Paul'));
      expect(nameList, contains('Pauline'));
      expect(nameList, contains('Seed: P'));
    });

    test('Seeds diferentes geram nomes diferentes', () {
      final listA = NameGenerator.generateNameList(
        'Português',
        seedLetter: 'A',
      );
      final listL = NameGenerator.generateNameList(
        'Português',
        seedLetter: 'L',
      );
      final listR = NameGenerator.generateNameList(
        'Português',
        seedLetter: 'R',
      );

      // Listas devem ser diferentes
      expect(listA, isNot(equals(listL)));
      expect(listL, isNot(equals(listR)));

      // Cada lista deve conter nomes da letra correspondente
      expect(listA, contains('André'));
      expect(listL, contains('Lucas'));
      expect(listR, contains('Rafael'));
    });

    test('Gera 12+ nomes por seed', () {
      final nameList = NameGenerator.generateNameList(
        'Português',
        seedLetter: 'G',
      );

      // Contar quantos nomes aparecem (cada nome em uma linha)
      final lines = nameList
          .split('\n')
          .where(
            (line) =>
                line.trim().isNotEmpty &&
                !line.contains('━') &&
                !line.contains('📝') &&
                !line.contains('⚠️') &&
                !line.contains('🚨'),
          )
          .toList();

      // Deve ter pelo menos 12 nomes
      expect(lines.length, greaterThanOrEqualTo(12));
    });
  });
}
