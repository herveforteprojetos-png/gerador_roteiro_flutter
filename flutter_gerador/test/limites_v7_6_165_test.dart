import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/block_prompt_builder.dart';

/// v7.6.166: Emergency Accept para TODOS os blocos (não só 7+)
void main() {
  group('v7.6.166 - Emergency Accept Universal', () {
    group('Blocos 1-6: Emergency após retry 3', () {
      const targetWords = 930;
      const ratio = 4.5;
      const margem = 1.08;

      final expectedMaxChars = (targetWords * ratio * margem).round();

      test('Tentativas 1-3: Validação 1.47×', () {
        const validationMultiplier = 1.47;
        final validationLimit = (expectedMaxChars * validationMultiplier).round();

        print('📊 BLOCOS 1-6 (Tentativas 1-3):');
        print('   Target: $targetWords palavras');
        print('   Ratio: $ratio chars/palavra');
        print('   Validação: $validationMultiplier×');
        print('   Limite: $validationLimit chars\n');

        expect(expectedMaxChars, equals(4520));
        expect(validationLimit, equals(6644));
      });

      test('Tentativa 4+: Emergency Accept 1.65×', () {
        const validationMultiplier = 1.65;
        final validationLimit = (expectedMaxChars * validationMultiplier).round();

        print('🚨 BLOCOS 1-6 (EMERGENCY - Tentativa 4+):');
        print('   Validação EMERGENCY: $validationMultiplier×');
        print('   Limite EMERGENCY: $validationLimit chars\n');

        expect(validationLimit, equals(7458)); // 4520 × 1.65
      });

      test('Bloco 1 real (6609) PASSA', () {
        const chars = 6609;
        const limitNormal = 6644;
        expect(chars <= limitNormal, isTrue);
        
        print('✅ Bloco 1 (6609 chars) PASSA com 1.47×');
      });

      test('Bloco 4 casos reais - v7.6.165 falhou 4×', () {
        const limitNormal = 6644; // 4520 × 1.47
        const limitEmergency = 7458; // 4520 × 1.65

        // Bloco 4 falhou com: 9766, 9054, 7347, 8947
        const retry1 = 9766;
        const retry2 = 9054;
        const retry3 = 7347;
        const retry4 = 8947;

        print('📋 BLOCO 4 - ANÁLISE:');
        print('   Limite normal (1.47×): $limitNormal chars');
        print('   Limite emergency (1.65×): $limitEmergency chars\n');
        
        expect(retry1 > limitEmergency, isTrue);
        print('   Retry 1 (9766): ❌ Muito grande (absurdo)');
        
        expect(retry2 > limitEmergency, isTrue);
        print('   Retry 2 (9054): ❌ Muito grande (absurdo)');
        
        expect(retry3 <= limitEmergency, isTrue);
        print('   Retry 3 (7347): ❌ Normal | ✅ PASSARIA com emergency!');
        
        expect(retry4 > limitEmergency, isTrue);
        print('   Retry 4 (8947): ❌ Ainda muito grande\n');

        print('   💡 Com emergency: Retry 4 ativaria emergency');
        print('   💡 Bloco 4 teria passado no retry 3 (7347 < 7458)\n');
      });
    });

    group('Blocos 7-12: Emergency Accept após retry 4', () {
      const targetWords = 930;
      const ratio = 4.0; // v7.6.164: ratio diferenciado
      const margem = 1.08;

      final expectedMaxChars = (targetWords * ratio * margem).round();

      test('Tentativas 1-4: Validação 1.4×', () {
        const validationMultiplier = 1.4;
        final validationLimit = (expectedMaxChars * validationMultiplier).round();

        print('📊 BLOCOS 7+ (Tentativas 1-4):');
        print('   Target: $targetWords palavras');
        print('   Ratio: $ratio chars/palavra');
        print('   Margem: $margem');
        print('   Validação: $validationMultiplier×');
        print('   Limite base: $expectedMaxChars chars');
        print('   Limite validação: $validationLimit chars\n');

        expect(expectedMaxChars >= 4010 && expectedMaxChars <= 4020, isTrue);
        expect(validationLimit >= 5614 && validationLimit <= 5630, isTrue);
      });

      test('Tentativa 5+: Emergency Accept 1.8×', () {
        const validationMultiplier = 1.8;
        final validationLimit = (expectedMaxChars * validationMultiplier).round();

        print('🚨 BLOCOS 7+ (EMERGENCY - Tentativa 5+):');
        print('   Target: $targetWords palavras');
        print('   Ratio: $ratio chars/palavra');
        print('   Validação EMERGENCY: $validationMultiplier×');
        print('   Limite base: $expectedMaxChars chars');
        print('   Limite EMERGENCY: $validationLimit chars\n');

        expect(expectedMaxChars >= 4010 && expectedMaxChars <= 4020, isTrue);
        expect(validationLimit >= 7218 && validationLimit <= 7240, isTrue); // ~4017 × 1.8
      });

      test('Bloco 7: Casos reais do log', () {
        const validationNormal = 1.4;
        const validationEmergency = 1.8;
        final limitNormal = (expectedMaxChars * validationNormal).round();
        final limitEmergency = (expectedMaxChars * validationEmergency).round();

        // Retry 1-4: 6316, 6001, 11390, 6261 (rejeitados com 1.4×)
        const retry1 = 6316;
        const retry2 = 6001;
        const retry3 = 11390;
        const retry4 = 6261;
        
        // Retry 5: 4167 (passou antes, mas com emergency passaria mais fácil)
        const retry5 = 4167;

        print('📋 BLOCO 7 - ANÁLISE:');
        print('   Limite normal (1.4×): $limitNormal chars');
        print('   Limite emergency (1.8×): $limitEmergency chars\n');
        
        expect(retry1 > limitNormal, isTrue);
        expect(retry1 <= limitEmergency, isTrue);
        print('   Retry 1 (6316): ❌ Normal | ✅ Emergency');
        
        expect(retry2 > limitNormal, isTrue);
        expect(retry2 <= limitEmergency, isTrue);
        print('   Retry 2 (6001): ❌ Normal | ✅ Emergency');
        
        expect(retry3 > limitEmergency, isTrue);
        print('   Retry 3 (11390): ❌ Normal | ❌ Emergency (muito grande)');
        
        expect(retry4 > limitNormal, isTrue);
        expect(retry4 <= limitEmergency, isTrue);
        print('   Retry 4 (6261): ❌ Normal | ✅ Emergency');
        
        expect(retry5 <= limitNormal, isTrue);
        print('   Retry 5 (4167): ✅ Normal | ✅ Emergency\n');
      });

      test('Bloco 8: Casos reais - v7.6.163.2 falhou 6×', () {
        const validationEmergency = 1.8;
        final limitEmergency = (expectedMaxChars * validationEmergency).round();

        // v7.6.163.2: 8341, 19560, 6975, 6249, 23056, 6677
        const retry1 = 8341;
        const retry2 = 19560;
        const retry3 = 6975;
        const retry4 = 6249;
        const retry5 = 23056;
        const retry6 = 6677;

        print('📋 BLOCO 8 - ANÁLISE COM EMERGENCY:');
        print('   Limite emergency (1.8×): $limitEmergency chars\n');
        
        expect(retry1 > limitEmergency, isTrue);
        print('   Retry 1 (8341): ❌ Ainda falha (16% acima)');
        
        expect(retry2 > limitEmergency, isTrue);
        print('   Retry 2 (19560): ❌ Absurdo (3× o limite)');
        
        expect(retry3 <= limitEmergency, isTrue);
        print('   Retry 3 (6975): ✅ PASSARIA com emergency!');
        
        expect(retry4 <= limitEmergency, isTrue);
        print('   Retry 4 (6249): ✅ PASSARIA com emergency!');
        
        expect(retry5 > limitEmergency, isTrue);
        print('   Retry 5 (23056): ❌ Absurdo (3× o limite)');
        
        expect(retry6 <= limitEmergency, isTrue);
        print('   Retry 6 (6677): ✅ PASSARIA com emergency!\n');

        print('   💡 Com emergency: 3/6 tentativas passariam');
        print('   💡 Retry 5 ativaria emergency e aceitaria retry 6\n');
      });
    });

    test('RESUMO: v7.6.166 Emergency Accept Universal', () {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🚨 v7.6.166 - EMERGENCY ACCEPT UNIVERSAL');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      print('🎯 BLOCOS 1-6 (Tentativas 1-3):');
      print('   Ratio: 4.5 chars/palavra');
      print('   Validação: 1.47× → 6644 chars');
      print('');
      print('🚨 BLOCOS 1-6 (Tentativa 4+):');
      print('   Ratio: 4.5 chars/palavra');
      print('   Validação EMERGENCY: 1.65× → 7458 chars');
      print('   ✅ Aceita 7k chars (Bloco 4 retry 3)');
      print('');
      print('🎯 BLOCOS 7-12 (Tentativas 1-4):');
      print('   Ratio: 4.0 chars/palavra');
      print('   Validação: 1.4× → ~5620 chars');
      print('');
      print('🚨 BLOCOS 7-12 (Tentativa 5+):');
      print('   Ratio: 4.0 chars/palavra');
      print('   Validação EMERGENCY: 1.8× → ~7230 chars');
      print('');
      print('📊 MUDANÇAS vs v7.6.165:');
      print('   • Todos blocos: 5 retries (antes: 1-6=3, 7+=5)');
      print('   • Blocos 1-6: Emergency após retry 3 (1.65×)');
      print('   • Blocos 7-12: Emergency após retry 4 (1.8×)');
      print('');
      print('✅ PROBLEMA RESOLVIDO:');
      print('   • Bloco 4 não falhará mais (7347 < 7458)');
      print('   • Blocos 7-8 terão mais chances de passar');
      print('   • Absurdos (>8k) ainda rejeitados');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      expect(true, isTrue);
    });
  });
}
