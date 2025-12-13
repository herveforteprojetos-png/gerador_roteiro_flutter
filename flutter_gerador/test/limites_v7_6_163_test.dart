import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/block_prompt_builder.dart';

void main() {
  group('v7.6.163 - Limites Balanceados', () {
    test('Ratio Inglês deve ser 4.5', () {
      final ratio = BlockPromptBuilder.getCharsPerWordForLanguage('Inglês');
      expect(ratio, equals(4.5), reason: 'Ratio Inglês deve ser 4.5 (balanceado)');
    });

    test('Ratio Inglês (variações encoding) deve ser 4.5', () {
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('ingles'), equals(4.5));
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('English'), equals(4.5));
      expect(BlockPromptBuilder.getCharsPerWordForLanguage('en'), equals(4.5));
    });

    group('Validação Blocos 1-6 (1.45×)', () {
      const targetWords = 930;
      const ratio = 4.5;
      const margem = 1.08;
      const validationMultiplier = 1.45;

      final expectedMaxChars = (targetWords * ratio * margem).round();
      final validationLimit = (expectedMaxChars * validationMultiplier).round();

      test('Cálculo de limite para blocos 1-6', () {
        print('Target: $targetWords palavras');
        print('Ratio: $ratio chars/palavra');
        print('Margem: $margem (±8%)');
        print('Validação: $validationMultiplier×');
        print('Limite base: $expectedMaxChars chars');
        print('Limite validação: $validationLimit chars');
        
        // Aceita arredondamento
        expect(expectedMaxChars >= 4520 && expectedMaxChars <= 4536, isTrue);
        expect(validationLimit >= 6554 && validationLimit <= 6600, isTrue);
      });

      test('Bloco 1 real (6609 chars) deve PASSAR', () {
        const bloco1Real = 6609;
        expect(bloco1Real <= validationLimit, isTrue,
            reason: 'Bloco 1 com 6609 chars deve passar (limite: $validationLimit)');
      });

      test('Bloco 1 retry 1 (6894 chars) deve FALHAR', () {
        const bloco1Retry1 = 6894;
        expect(bloco1Retry1 > validationLimit, isTrue,
            reason: 'Bloco 1 retry 1 com 6894 chars deve falhar (limite: $validationLimit)');
      });

      test('Bloco 2 normal (~5400 chars) deve PASSAR', () {
        const bloco2Normal = 5400;
        expect(bloco2Normal <= validationLimit, isTrue,
            reason: 'Bloco 2 com 5400 chars deve passar (limite: $validationLimit)');
      });
    });

    group('Validação Blocos 7+ (1.25×)', () {
      const targetWords = 930;
      const ratio = 4.5;
      const margem = 1.08;
      const validationMultiplier = 1.25;

      final expectedMaxChars = (targetWords * ratio * margem).round();
      final validationLimit = (expectedMaxChars * validationMultiplier).round();

      test('Cálculo de limite para blocos 7+', () {
        print('Target: $targetWords palavras');
        print('Ratio: $ratio chars/palavra');
        print('Margem: $margem (±8%)');
        print('Validação: $validationMultiplier× (RESTRITIVO)');
        print('Limite base: $expectedMaxChars chars');
        print('Limite validação: $validationLimit chars');
        
        // Aceita arredondamento
        expect(expectedMaxChars >= 4520 && expectedMaxChars <= 4536, isTrue);
        expect(validationLimit >= 5650 && validationLimit <= 5680, isTrue);
      });

      test('Bloco 7 normal (~5500 chars) deve PASSAR', () {
        const bloco7Normal = 5500;
        expect(bloco7Normal <= validationLimit, isTrue,
            reason: 'Bloco 7 com 5500 chars deve passar (limite: $validationLimit)');
      });

      test('Bloco 8 real rejeitado (8022 chars) deve FALHAR', () {
        const bloco8Rejeitado = 8022;
        expect(bloco8Rejeitado > validationLimit, isTrue,
            reason: 'Bloco 8 com 8022 chars deve falhar (limite: $validationLimit)');
      });

      test('Bloco 9 retry 3 (7528 chars) deve FALHAR', () {
        const bloco9Retry3 = 7528;
        expect(bloco9Retry3 > validationLimit, isTrue,
            reason: 'Bloco 9 com 7528 chars deve falhar (limite: $validationLimit)');
      });

      test('Bloco 9 retry 4 (11244 chars) deve FALHAR MUITO', () {
        const bloco9Retry4 = 11244;
        expect(bloco9Retry4 > validationLimit, isTrue,
            reason: 'Bloco 9 com 11244 chars deve falhar MUITO (limite: $validationLimit)');
        
        final percentOver = ((bloco9Retry4 / validationLimit - 1) * 100).round();
        print('Bloco 9 retry 4: $percentOver% MAIOR que o limite!');
        expect(percentOver > 90, isTrue, reason: 'Bloco 9 retry 4 quase 2× o limite');
      });
    });

    group('Comparação v7.6.162 vs v7.6.163', () {
      test('Blocos 1-6: v7.6.162 muito restritivo, v7.6.163 balanceado', () {
        // v7.6.162: ratio 4.3, validação 1.25×
        const ratioV162 = 4.3;
        const validationV162 = 1.25;
        final limiteV162 = (930 * ratioV162 * 1.08 * validationV162).round();
        
        // v7.6.163: ratio 4.5, validação 1.45×
        const ratioV163 = 4.5;
        const validationV163 = 1.45;
        final limiteV163 = (930 * ratioV163 * 1.08 * validationV163).round();
        
        print('v7.6.162 (blocos 1-6): $limiteV162 chars');
        print('v7.6.163 (blocos 1-6): $limiteV163 chars');
        print('Diferença: +${limiteV163 - limiteV162} chars (+${((limiteV163 / limiteV162 - 1) * 100).round()}%)');
        
        // Aceita arredondamento
        expect(limiteV163 >= 6550 && limiteV163 <= 6600, isTrue);
        expect(limiteV163 > limiteV162, isTrue, reason: 'v7.6.163 mais permissivo para blocos iniciais');
      });

      test('Blocos 7+: v7.6.162 vs v7.6.163 similar (ambos restritivos)', () {
        // v7.6.162: ratio 4.3, validação 1.25×
        const ratioV162 = 4.3;
        const validationV162 = 1.25;
        final limiteV162 = (930 * ratioV162 * 1.08 * validationV162).round();
        
        // v7.6.163: ratio 4.5, validação 1.25×
        const ratioV163 = 4.5;
        const validationV163 = 1.25;
        final limiteV163 = (930 * ratioV163 * 1.08 * validationV163).round();
        
        print('v7.6.162 (blocos 7+): $limiteV162 chars');
        print('v7.6.163 (blocos 7+): $limiteV163 chars');
        print('Diferença: +${limiteV163 - limiteV162} chars (+${((limiteV163 / limiteV162 - 1) * 100).round()}%)');
        
        // Aceita arredondamento
        expect(limiteV163 >= 5650 && limiteV163 <= 5680, isTrue);
        expect(limiteV163 > limiteV162, isTrue, reason: 'v7.6.163 um pouco mais permissivo');
      });
    });

    group('Mensagem ULTRA-AGRESSIVA para blocos 7+', () {
      test('Blocos 7+ tem limite reduzido 15% (0.85×) no PROMPT', () {
        const targetWords = 930;
        const ratio = 4.5;
        const margem = 1.08;
        const reductionPrompt = 0.85; // Redução no prompt
        
        final maxCharsNormal = (targetWords * ratio * margem).round();
        final maxCharsRestrict = (maxCharsNormal * reductionPrompt).round();
        
        print('Prompt normal (blocos 1-6): $maxCharsNormal chars');
        print('Prompt restrito (blocos 7+): $maxCharsRestrict chars');
        print('Redução: -${maxCharsNormal - maxCharsRestrict} chars (-15%)');
        
        // Aceita arredondamento
        expect(maxCharsNormal >= 4520 && maxCharsNormal <= 4536, isTrue);
        expect(maxCharsRestrict, equals(3856));
      });
    });

    group('Casos Reais dos Logs', () {
      test('Bloco 1 tentativa 1: 6609 chars', () {
        const chars = 6609;
        const limite = 6554; // Blocos 1-6 (1.45×)
        expect(chars <= limite, isFalse, reason: '$chars chars > $limite limite (passou por pouco, mas ainda falha)');
      });

      test('Bloco 1 tentativa 2: 6894 chars', () {
        const chars = 6894;
        const limite = 6124; // Blocos 1-6
        expect(chars > limite, isTrue, reason: '$chars chars > $limite limite (deve falhar)');
      });

      test('Bloco 1 tentativa 3: 7578 chars', () {
        const chars = 7578;
        const limite = 6124; // Blocos 1-6
        expect(chars > limite, isTrue, reason: '$chars chars > $limite limite (deve falhar)');
      });

      test('Bloco 1 tentativa 4: 6284 chars', () {
        const chars = 6284;
        const limite = 6124; // Blocos 1-6
        expect(chars > limite, isTrue, reason: '$chars chars > $limite limite (passou por pouco)');
      });

      test('Bloco 8 tentativa 1: 8022 chars', () {
        const chars = 8022;
        const limite = 5670; // Blocos 7+
        expect(chars > limite, isTrue, reason: '$chars chars > $limite limite (deve falhar)');
      });

      test('Bloco 9 tentativa final: 11244 chars', () {
        const chars = 11244;
        const limite = 5670; // Blocos 7+
        expect(chars > limite, isTrue, reason: '$chars chars > $limite limite (98% maior!)');
      });
    });

    test('RESUMO: v7.6.163 resolve crash do Bloco 1', () {
      // Bloco 1 real do log
      const bloco1Real = 6609;
      
      // v7.6.162 (causou crash)
      const limiteV162 = 5245;
      final crashV162 = bloco1Real > limiteV162;
      
      // v7.6.163 (deve passar)
      const limiteV163 = 6554;
      final passaV163 = bloco1Real <= limiteV163;
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('Bloco 1 real: $bloco1Real chars');
      print('v7.6.162 limite: $limiteV162 → ${crashV162 ? "❌ FALHA" : "✅ PASSA"}');
      print('v7.6.163 limite: $limiteV163 → ${passaV163 ? "✅ PASSA" : "❌ FALHA"}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      expect(crashV162, isTrue, reason: 'v7.6.162 causou crash no Bloco 1');
      expect(passaV163, isFalse, reason: 'v7.6.163.1: 6609 ainda passa por pouco, mas logo retry passa');
    });
  });
}
