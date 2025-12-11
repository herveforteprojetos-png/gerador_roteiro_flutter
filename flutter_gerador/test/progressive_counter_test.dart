/// 🧪 Testes do Contador Progressivo v7.6.142
/// Valida cálculo de Atos e mensagens de progresso

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/structure_rules.dart';

void main() {
  group('Progressive Counter - ActInfo Calculation', () {
    const targetTotal = 6800; // Total padrão de palavras
    const act1Limit = 1700; // 25%
    const act2MaxWords = 2720; // 40% (do total)
    const act2End = 4420; // 65% (fim do Ato 2)
    const act3Min = 2380; // 35%

    test('Ato 1 - Início (0 palavras)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 0,
        targetTotalWords: targetTotal,
      );

      expect(actInfo.actNumber, 1);
      expect(actInfo.actName, 'ATO 1 - INÍCIO (Setup)');
      expect(actInfo.actCurrentWords, 0);
      expect(actInfo.actMaxWords, act1Limit);
      expect(actInfo.actRemainingWords, act1Limit);
      expect(actInfo.isOverLimit, false);
    });

    test('Ato 1 - Meio (800 palavras)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 800,
        targetTotalWords: targetTotal,
      );

      expect(actInfo.actNumber, 1);
      expect(actInfo.actCurrentWords, 800);
      expect(actInfo.actRemainingWords, act1Limit - 800);
    });

    test('Ato 1 - Fim (1699 palavras - última palavra antes do Ato 2)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 1699,
        targetTotalWords: targetTotal,
      );

      expect(actInfo.actNumber, 1);
      expect(actInfo.actRemainingWords, 1);
    });

    test('Ato 2 - Início (1701 palavras)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 1701,
        targetTotalWords: targetTotal,
      );

      expect(actInfo.actNumber, 2);
      expect(actInfo.actName, 'ATO 2 - MEIO (Desenvolvimento)');
      expect(actInfo.actCurrentWords, 1); // 1701 - 1700 (fim Ato 1)
      expect(actInfo.actMaxWords, act2MaxWords); // 40% do total
      expect(actInfo.isOverLimit, false);
    });

    test('Ato 2 - Meio (2500 palavras)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 2500,
        targetTotalWords: targetTotal,
      );

      expect(actInfo.actNumber, 2);
      expect(actInfo.actCurrentWords, 2500 - act1Limit);
      expect(actInfo.actRemainingWords, greaterThan(0));
    });

    test('Ato 2 - Fim crítico (4300 palavras - restam 120)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 4300,
        targetTotalWords: targetTotal,
      );

      expect(actInfo.actNumber, 2);
      expect(actInfo.actCurrentWords, 4300 - act1Limit);
      expect(actInfo.actRemainingWords, lessThan(300)); // Zona crítica
    });

    test('Ato 3 - Início (4421 palavras)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 4421,
        targetTotalWords: targetTotal,
      );

      expect(actInfo.actNumber, 3);
      expect(actInfo.actName, 'ATO 3 - FIM (Resolução)');
      expect(actInfo.actCurrentWords, 1); // 4421 - 4420
      expect(actInfo.actMaxWords, act3Min);
      expect(actInfo.actRemainingWords, greaterThan(2000)); // Muito espaço
    });

    test('Ato 3 - Meio (5000 palavras)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 5000,
        targetTotalWords: targetTotal,
      );

      expect(actInfo.actNumber, 3);
      expect(actInfo.actCurrentWords, 5000 - act2End);
      expect(actInfo.actRemainingWords, greaterThan(500));
    });

    test('Ato 3 - Fim completo (6800 palavras - 100%)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 6800,
        targetTotalWords: targetTotal,
      );

      expect(actInfo.actNumber, 3);
      expect(actInfo.actCurrentWords, 6800 - act2End);
      expect(
        actInfo.actRemainingWords,
        lessThanOrEqualTo(0),
      ); // Completou mínimo
    });
  });

  group('Progressive Counter - Edge Cases', () {
    test('Roteiro curto (1000 palavras)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 300,
        targetTotalWords: 1000,
      );

      expect(actInfo.actNumber, greaterThanOrEqualTo(1));
      expect(actInfo.actMaxWords, greaterThan(0));
    });

    test('Roteiro longo (20000 palavras)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 10000,
        targetTotalWords: 20000,
      );

      expect(actInfo.actNumber, greaterThanOrEqualTo(1));
      expect(actInfo.actNumber, lessThanOrEqualTo(3));
    });

    test('Início absoluto (0 palavras)', () {
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: 0,
        targetTotalWords: 5000,
      );

      expect(actInfo.actNumber, 1);
      expect(actInfo.actCurrentWords, 0);
      expect(actInfo.actRemainingWords, equals(actInfo.actMaxWords));
    });
  });
}
