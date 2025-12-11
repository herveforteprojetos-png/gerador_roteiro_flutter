import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/structure_rules.dart';
import 'package:flutter_gerador/data/services/gemini/utils/text_utils.dart';

/// 🐛 v7.6.142.1: Testa correção do bug de truncamento em retries
///
/// BUG ORIGINAL:
/// No retry de blocos vazios, o contexto era truncado para 8000 chars,
/// fazendo o contador progressivo calcular Ato baseado em texto parcial.
///
/// EXEMPLO:
/// - Bloco 7 com 5870 palavras acumuladas
/// - Retry trunca para 8000 chars (~1302 palavras)
/// - Contador mostrava "Ato 1 - 1302/1475" ao invés de "Ato 3 - 2035/2065"
///
/// CORREÇÃO:
/// Adicionar parâmetro fullContextForCounter para passar contexto completo
/// apenas para cálculo do contador, mantendo contexto truncado no prompt.
void main() {
  group('v7.6.142.1 - Retry Counter Bug Fix', () {
    test('Simulação do bug: truncamento em 8000 chars', () {
      // Simular Bloco 7 com 5870 palavras (~40k chars)
      final fullContext = List.generate(5870, (i) => 'palavra').join(' ');

      final fullWords = TextUtils.countWords(fullContext);
      expect(fullWords, greaterThanOrEqualTo(5800)); // ~5870 palavras

      // Simular truncamento do retry (últimos 8000 chars)
      final truncatedContext = fullContext.length > 8000
          ? fullContext.substring(fullContext.length - 8000)
          : fullContext;

      final truncatedWords = TextUtils.countWords(truncatedContext);
      expect(truncatedWords, lessThan(2000)); // ~1300 palavras

      // Calcular Ato com contexto COMPLETO (correto)
      final actInfoFull = StructureRules.getActInfo(
        currentTotalWords: fullWords,
        targetTotalWords: 5900,
      );
      expect(actInfoFull.actNumber, 3); // Ato 3 ✅
      expect(actInfoFull.actName, contains('ATO 3'));

      // Calcular Ato com contexto TRUNCADO (bug original)
      final actInfoTruncated = StructureRules.getActInfo(
        currentTotalWords: truncatedWords,
        targetTotalWords: 5900,
      );
      expect(actInfoTruncated.actNumber, 1); // Ato 1 ❌ BUG!
      expect(actInfoTruncated.actName, contains('ATO 1'));
    });

    test('Cenário real: Bloco 7 com 5870 palavras', () {
      // Valores reais dos logs
      const realTotalWords = 5870;
      const targetWords = 5900;

      // Ato correto (contexto completo)
      final actInfo = StructureRules.getActInfo(
        currentTotalWords: realTotalWords,
        targetTotalWords: targetWords,
      );

      expect(actInfo.actNumber, 3); // Ato 3
      expect(actInfo.actName, 'ATO 3 - FIM (Resolução)');
      expect(actInfo.actCurrentWords, 2035); // 5870 - 3835 (65% de 5900)
      expect(actInfo.actMaxWords, 2065); // 35% de 5900
      expect(actInfo.actRemainingWords, 30); // 2065 - 2035
    });

    test('Bloco 7 retry 3: Bug mostrava Ato 1 com 1302 palavras', () {
      // Valores do log bugado
      const buggedWords = 1302;
      const targetWords = 5900;

      final actInfo = StructureRules.getActInfo(
        currentTotalWords: buggedWords,
        targetTotalWords: targetWords,
      );

      // Bug mostrava Ato 1
      expect(actInfo.actNumber, 1); // ❌ Incorreto mas esperado no bug
      expect(actInfo.actName, contains('ATO 1'));
      expect(actInfo.actMaxWords, 1475); // 25% de 5900
      expect(actInfo.actCurrentWords, 1302);
      expect(actInfo.actRemainingWords, 173);
    });

    test('Transições corretas com contexto completo', () {
      const targetWords = 5900;

      // Bloco 1: 753 palavras (Ato 1)
      var actInfo = StructureRules.getActInfo(
        currentTotalWords: 753,
        targetTotalWords: targetWords,
      );
      expect(actInfo.actNumber, 1);
      expect(actInfo.actCurrentWords, 753);

      // Bloco 3: 1773 palavras (Ato 2 - transição)
      actInfo = StructureRules.getActInfo(
        currentTotalWords: 1773,
        targetTotalWords: targetWords,
      );
      expect(actInfo.actNumber, 2);
      expect(actInfo.actName, contains('ATO 2'));

      // Bloco 6: 4726 palavras (Ato 3 - transição)
      actInfo = StructureRules.getActInfo(
        currentTotalWords: 4726,
        targetTotalWords: targetWords,
      );
      expect(actInfo.actNumber, 3);
      expect(actInfo.actName, contains('ATO 3'));

      // Bloco 7: 5870 palavras (Ato 3 - final)
      actInfo = StructureRules.getActInfo(
        currentTotalWords: 5870,
        targetTotalWords: targetWords,
      );
      expect(actInfo.actNumber, 3);
      expect(
        actInfo.actRemainingWords,
        lessThanOrEqualTo(100),
      ); // Quase completo
    });
  });
}
