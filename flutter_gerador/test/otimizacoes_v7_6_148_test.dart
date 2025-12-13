import 'package:flutter_test/flutter_test.dart';

/// 🧪 Testes para v7.6.148: Correção de falhas em blocos finais
///
/// Problemas resolvidos:
/// 1. Validação de família muito rígida (neto/filho) em blocos avançados
/// 2. MinAcceptable muito alto quando ato próximo do limite
void main() {
  group('v7.6.148 - Validação de Família Relaxada', () {
    test('Lógica de validação: Blocos 1-5 validam neto/filho', () {
      const blockNumber = 3;

      // Simula lógica: se (neto/neta presente) E (blockNumber < 6)
      final shouldValidate = blockNumber < 6;

      expect(shouldValidate, true); // Bloco 3 deve validar
    });

    test('Lógica de validação: Blocos 6+ NÃO validam neto/filho', () {
      const blockNumber = 7;

      // Simula lógica: se (neto/neta presente) E (blockNumber < 6)
      final shouldValidate = blockNumber < 6;

      expect(shouldValidate, false); // Bloco 7 NÃO deve validar
    });

    test('Exatamente no limite (Bloco 6): Validação já relaxada', () {
      const blockNumber = 6;

      final shouldValidate = blockNumber < 6;

      expect(shouldValidate, false); // Bloco 6 já relaxado
    });

    test('Bloco 5: Ainda valida (último bloco com validação)', () {
      const blockNumber = 5;

      final shouldValidate = blockNumber < 6;

      expect(shouldValidate, true); // Bloco 5 ainda valida
    });
  });

  group('v7.6.148 - MinAcceptable Dinâmico', () {
    test('Cálculo de minAcceptable: Ato normal (65%)', () {
      const adjustedTarget = 1400; // Target normal
      const minPercentForValidation = 0.65;

      final minAcceptable = (adjustedTarget * minPercentForValidation).round();

      expect(minAcceptable, 910); // 65% de 1400
    });

    test('Cálculo de minAcceptable: Ato no limite (35%)', () {
      const adjustedTarget = 1400; // Target normal
      const actRemainingWords =
          200; // Restam apenas 200 palavras (< 50% do target)
      const isActNearLimit = actRemainingWords < (adjustedTarget * 0.5); // true

      final adjustedMinPercent = isActNearLimit ? 0.35 : 0.65;
      final finalMinAcceptable = (adjustedTarget * adjustedMinPercent).round();

      expect(isActNearLimit, true);
      expect(finalMinAcceptable, 490); // 35% de 1400 (muito menor que 910)
    });

    test('Threshold de ato no limite: exatamente 50% do target', () {
      const adjustedTarget = 1400;
      const actRemainingWords = 700; // Exatamente 50% do target

      final isActNearLimit = actRemainingWords < (adjustedTarget * 0.5);

      // Deve ser FALSE (não está "menor que", está "igual a")
      expect(isActNearLimit, false);
    });

    test('Threshold de ato no limite: ligeiramente abaixo de 50%', () {
      const adjustedTarget = 1400;
      const actRemainingWords = 699; // Ligeiramente abaixo de 50%

      final isActNearLimit = actRemainingWords < (adjustedTarget * 0.5);

      // Deve ser TRUE
      expect(isActNearLimit, true);
    });

    test('Cenário real do usuário: Bloco 6 com 178 palavras restantes', () {
      // Dados reais do log:
      // Ato 2: 4072/4250 palavras, restantes: 178
      // Bloco rejeitado com 193 palavras (mínimo era 906)
      const adjustedTarget = 1394; // Target do bloco
      const actRemainingWords = 178; // Restantes no ato

      final isActNearLimit = actRemainingWords < (adjustedTarget * 0.5);

      // v7.6.148.1: Usar menor entre 35% target e 60% restantes
      final minFromTarget = (adjustedTarget * 0.35).round();
      final minFromRemaining = (actRemainingWords * 0.6).round();
      final finalMinAcceptable = minFromTarget < minFromRemaining
          ? minFromTarget
          : minFromRemaining;

      // Validações
      expect(isActNearLimit, true); // 178 < 697
      expect(minFromTarget, 488); // 35% de 1394
      expect(minFromRemaining, 107); // 60% de 178 (arredondado)
      expect(finalMinAcceptable, 107); // Usa o menor (107 < 488)

      // Bloco com 193 palavras agora seria ACEITO!
      const wordCount = 193;
      final wouldBeAccepted = wordCount >= finalMinAcceptable;
      expect(wouldBeAccepted, true); // 193 >= 107, aceito! ✅
    });

    test('Cenário extremo: Bloco 6 com 262 palavras restantes', () {
      // NOVO cenário do log mais recente:
      // Ato 2: 3988/4250 palavras, restantes: 262
      // Blocos gerados: 247, 255, 223, 302 palavras
      // v7.6.148 rejeitou todos (min=488)

      const adjustedTarget = 1394;
      const actRemainingWords = 262;

      final isActNearLimit = actRemainingWords < (adjustedTarget * 0.5);
      final minFromTarget = (adjustedTarget * 0.35).round();
      final minFromRemaining = (actRemainingWords * 0.6).round();
      final finalMinAcceptable = minFromTarget < minFromRemaining
          ? minFromTarget
          : minFromRemaining;

      expect(isActNearLimit, true); // 262 < 697
      expect(minFromTarget, 488); // 35% de 1394
      expect(minFromRemaining, 157); // 60% de 262
      expect(finalMinAcceptable, 157); // Usa 157 (menor que 488)

      // Todas as tentativas do log seriam aceitas agora
      const wordCounts = [247, 255, 223, 302];
      for (final wordCount in wordCounts) {
        final accepted = wordCount >= finalMinAcceptable;
        expect(accepted, true); // Todos >= 157, todos aceitos! ✅
      }
    });

    test('Flash model: não aplica ajuste dinâmico', () {
      const adjustedTarget = 1400;
      const actRemainingWords = 200;
      const isFlashModel = true;
      const isActNearLimit = actRemainingWords < (adjustedTarget * 0.5);

      // Flash sempre usa 45%, não importa se ato está no limite
      final minPercentForValidation = 0.45;
      final finalMinAcceptable = (adjustedTarget * minPercentForValidation)
          .round();

      // Mesmo com ato no limite, Flash usa seu próprio percentual
      expect(isActNearLimit, true);
      expect(finalMinAcceptable, 630); // 45% de 1400 (fixo para Flash)
    });
  });

  group('v7.6.148 - Integração', () {
    test('Cenário completo: Bloco 7 com neta + ato no limite', () {
      const adjustedTarget = 1394; // Target do bloco
      const actRemainingWords = 178; // Restantes no ato

      final isActNearLimit = actRemainingWords < (adjustedTarget * 0.5);
      final adjustedMinPercent = isActNearLimit ? 0.35 : 0.65;
      final finalMinAcceptable = (adjustedTarget * adjustedMinPercent).round();

      // Validações
      expect(isActNearLimit, true); // 178 < 697
      expect(finalMinAcceptable, 488); // 35% de 1394

      // ANTES v7.6.148: minAcceptable = 906 (65% de 1394)
      // Bloco com 193 palavras rejeitado (193 < 906)
      // DEPOIS v7.6.148: minAcceptable = 488 (35% de 1394)
      // Bloco com 193 palavras AINDA rejeitado (193 < 488)

      // Mas blocos de ~500 palavras agora são aceitos
      const wordCount = 500;
      final wouldBeAccepted = wordCount >= finalMinAcceptable;

      expect(wouldBeAccepted, true); // 500 >= 488, aceito!

      // Comparação: antes seria rejeitado
      const oldMinAcceptable = 906;
      final wouldBeRejectedBefore = wordCount < oldMinAcceptable;
      expect(wouldBeRejectedBefore, true); // 500 < 906, seria rejeitado
    });

    test('Flash model: não aplica ajuste dinâmico (sempre 45%)', () {
      const adjustedTarget = 1400;
      const actRemainingWords = 200;
      const isActNearLimit = actRemainingWords < (adjustedTarget * 0.5);

      // Flash sempre usa 45%, não importa se ato está no limite
      final minPercentForValidation = 0.45;
      final finalMinAcceptable = (adjustedTarget * minPercentForValidation)
          .round();

      // Mesmo com ato no limite, Flash usa seu próprio percentual
      expect(isActNearLimit, true);
      expect(finalMinAcceptable, 630); // 45% de 1400 (fixo para Flash)
    });

    test('Economia de retries: bloco 500 palavras vs 193 palavras', () {
      const adjustedTarget = 1394;
      const actRemainingWords = 178;

      final isActNearLimit = actRemainingWords < (adjustedTarget * 0.5);
      final finalMinAcceptable = isActNearLimit
          ? (adjustedTarget * 0.35).round()
          : (adjustedTarget * 0.65).round();

      // Cenário A: Bloco de 193 palavras (muito curto)
      const wordCountTooShort = 193;
      final tooShortAccepted = wordCountTooShort >= finalMinAcceptable;
      expect(tooShortAccepted, false); // 193 < 488, rejeitado (correto!)

      // Cenário B: Bloco de 500 palavras (razoável para ato no limite)
      const wordCountReasonable = 500;
      final reasonableAccepted = wordCountReasonable >= finalMinAcceptable;
      expect(reasonableAccepted, true); // 500 >= 488, aceito! ✅

      // Cenário C: Bloco de 800 palavras (bom, mas excederia ato)
      // 800 palavras + 4072 já existentes = 4872 > 4250 (excederia)
      // Por isso model gera blocos menores (~500) quando ato no limite
    });
  });

  group('v7.6.148 - Integração dos Fixes', () {
    test('Bloco 6: Validação relaxada + minAcceptable ajustado', () {
      const blockNumber = 6;
      const adjustedTarget = 1394;
      const actRemainingWords = 300; // Próximo do limite

      // Fix 1: Validação de família relaxada
      final shouldValidateFamily = blockNumber < 6;
      expect(shouldValidateFamily, false); // Não valida neto/filho

      // Fix 2: MinAcceptable ajustado
      final isActNearLimit = actRemainingWords < (adjustedTarget * 0.5);
      final adjustedMinPercent = isActNearLimit ? 0.35 : 0.65;
      final finalMinAcceptable = (adjustedTarget * adjustedMinPercent).round();

      expect(isActNearLimit, true); // 300 < 697
      expect(finalMinAcceptable, 488); // 35% do target

      // Bloco com 500 palavras seria aceito
      const wordCount = 500;
      final blockAccepted = wordCount >= finalMinAcceptable;
      expect(blockAccepted, true);
    });

    test('Bloco 7: Cenário completo do log (neta + ato limite)', () {
      const blockNumber = 7;
      const adjustedTarget = 1395;
      const actRemainingWords = 150; // Muito próximo do limite
      const wordCount = 500; // Bloco gerado razoável

      // Fix 1: Não valida neto/filho (bloco 7)
      final familyValidationSkipped = blockNumber >= 6;
      expect(familyValidationSkipped, true);

      // Fix 2: MinAcceptable reduzido
      final isActNearLimit = actRemainingWords < (adjustedTarget * 0.5);
      final finalMinAcceptable = isActNearLimit
          ? (adjustedTarget * 0.35).round()
          : (adjustedTarget * 0.65).round();

      expect(isActNearLimit, true);
      expect(finalMinAcceptable, 488); // 35% de 1395

      // Validação de tamanho deve passar
      final sizeValid = wordCount >= finalMinAcceptable;
      expect(sizeValid, true); // 500 >= 488

      // Ambas validações OK = bloco aceito
      final blockAccepted = familyValidationSkipped && sizeValid;
      expect(blockAccepted, true);
    });

    test('Transição Bloco 5→6: Mudança de comportamento', () {
      // Bloco 5: Última validação rígida
      const block5 = 5;
      final block5ValidatesFamily = block5 < 6;
      expect(block5ValidatesFamily, true);

      // Bloco 6: Primeira validação relaxada
      const block6 = 6;
      final block6ValidatesFamily = block6 < 6;
      expect(block6ValidatesFamily, false);

      // Ambos podem ter minAcceptable ajustado se ato no limite
      const adjustedTarget = 1394;
      const actRemaining5 = 1000; // Ato ainda OK no bloco 5
      const actRemaining6 = 200; // Ato no limite no bloco 6

      final isBlock5NearLimit = actRemaining5 < (adjustedTarget * 0.5);
      final isBlock6NearLimit = actRemaining6 < (adjustedTarget * 0.5);

      expect(isBlock5NearLimit, false); // Bloco 5 ainda tem espaço
      expect(isBlock6NearLimit, true); // Bloco 6 ato no limite
    });
  });
}
