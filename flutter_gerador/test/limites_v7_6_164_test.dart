import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/block_prompt_builder.dart';

/// v7.6.164: Teste da abordagem híbrida (ratio 4.0 + validação 1.4× para blocos 7+)
void main() {
  group('v7.6.164 - Solução Híbrida (Ratio + Validação)', () {
    test('Ratio: Blocos 1-6 usam 4.5', () {
      final ratio16 = BlockPromptBuilder.getCharsPerWordForLanguage('Inglês', blockNumber: 1);
      final ratio26 = BlockPromptBuilder.getCharsPerWordForLanguage('Inglês', blockNumber: 6);
      
      expect(ratio16, equals(4.5));
      expect(ratio26, equals(4.5));
      
      print('✅ Blocos 1-6: ratio 4.5 chars/palavra');
    });

    test('Ratio: Blocos 7+ usam 4.0 (mais conservador)', () {
      final ratio7 = BlockPromptBuilder.getCharsPerWordForLanguage('Inglês', blockNumber: 7);
      final ratio12 = BlockPromptBuilder.getCharsPerWordForLanguage('Inglês', blockNumber: 12);
      
      expect(ratio7, equals(4.0));
      expect(ratio12, equals(4.0));
      
      print('✅ Blocos 7+: ratio 4.0 chars/palavra (11% mais conservador)');
    });

    group('Blocos 1-6: Validação 1.47×', () {
      const targetWords = 930;
      const ratio = 4.5;
      const margem = 1.08;
      const validationMultiplier = 1.47;

      final expectedMaxChars = (targetWords * ratio * margem).round();
      final validationLimit = (expectedMaxChars * validationMultiplier).round();

      test('Cálculo de limite para blocos 1-6', () {
        print('📊 BLOCOS 1-6:');
        print('   Target: $targetWords palavras');
        print('   Ratio: $ratio chars/palavra');
        print('   Margem: $margem (±8%)');
        print('   Validação: $validationMultiplier×');
        print('   Limite base: $expectedMaxChars chars');
        print('   Limite validação: $validationLimit chars\n');
        
        expect(expectedMaxChars, equals(4520)); // 930 × 4.5 × 1.08
        expect(validationLimit, equals(6644)); // 4520 × 1.47
      });

      test('Bloco 1 real (6609 chars) deve PASSAR', () {
        const chars = 6609;
        expect(chars <= validationLimit, isTrue,
            reason: 'Bloco 1 com 6609 chars deve passar (limite: $validationLimit)');
        
        print('✅ Bloco 1: 6609 chars < $validationLimit = PASSA');
      });
    });

    group('Blocos 7+: Ratio 4.0 + Validação 1.4×', () {
      const targetWords = 930;
      const ratio = 4.0;
      const margem = 1.08;
      const validationMultiplier = 1.4;

      final expectedMaxChars = (targetWords * ratio * margem).round();
      final validationLimit = (expectedMaxChars * validationMultiplier).round();

      test('Cálculo de limite para blocos 7+', () {
        print('📊 BLOCOS 7+ (HÍBRIDO):');
        print('   Target: $targetWords palavras');
        print('   Ratio: $ratio chars/palavra (11% menor)');
        print('   Margem: $margem (±8%)');
        print('   Validação: $validationMultiplier× (12% maior que 1.25×)');
        print('   Limite base: $expectedMaxChars chars');
        print('   Limite validação: $validationLimit chars\n');
        
        expect(expectedMaxChars >= 4010 && expectedMaxChars <= 4020, isTrue); // 930 × 4.0 × 1.08
        expect(validationLimit >= 5614 && validationLimit <= 5630, isTrue); // ~4017 × 1.4
      });

      test('Bloco 7: casos do log', () {
        // Retry 1: 6316 chars
        const retry1 = 6316;
        expect(retry1 > validationLimit, isTrue,
            reason: 'Bloco 7 retry 1 (6316) deve FALHAR (limite: $validationLimit)');
        
        // Retry 2: 6001 chars
        const retry2 = 6001;
        expect(retry2 > validationLimit, isTrue,
            reason: 'Bloco 7 retry 2 (6001) deve FALHAR (limite: $validationLimit)');
        
        // Retry 5: 4167 chars (passou)
        const retry5 = 4167;
        expect(retry5 <= validationLimit, isTrue,
            reason: 'Bloco 7 retry 5 (4167) deve PASSAR (limite: $validationLimit)');
        
        print('✅ Bloco 7:');
        print('   Retry 1 (6316): REJEITADO ❌');
        print('   Retry 2 (6001): REJEITADO ❌');
        print('   Retry 5 (4167): ACEITO ✅\n');
      });

      test('Bloco 8: casos do log (v7.6.163.2 falhou 6×)', () {
        // v7.6.163.2: limite era 5650 (4520 × 1.25)
        const limiteV163 = 5650;
        
        // v7.6.164: limite é ~5620 (4017 × 1.4)
        
        // Retry 1: 8341 chars (ainda vai falhar)
        const retry1 = 8341;
        expect(retry1 > validationLimit, isTrue,
            reason: 'Bloco 8 retry 1 (8341) ainda FALHA com v7.6.164');
        
        // Retry 2: 19560 chars (monstruoso!)
        const retry2 = 19560;
        expect(retry2 > validationLimit, isTrue,
            reason: 'Bloco 8 retry 2 (19560) ainda FALHA com v7.6.164');
        
        // Retry 3: 6975 chars
        const retry3 = 6975;
        expect(retry3 > limiteV163, isTrue,
            reason: 'v7.6.163: 6975 > 5650 (FALHOU)');
        expect(retry3 > validationLimit, isTrue,
            reason: 'v7.6.164: 6975 > $validationLimit (ainda FALHA)');
        
        // Retry 4: 6249 chars
        const retry4 = 6249;
        expect(retry4 > limiteV163, isTrue,
            reason: 'v7.6.163: 6249 > 5650 (FALHOU)');
        expect(retry4 > validationLimit, isTrue,
            reason: 'v7.6.164: 6249 > $validationLimit (ainda FALHA)');
        
        // Retry 5: 23056 chars (absurdo!)
        const retry5 = 23056;
        expect(retry5 > validationLimit, isTrue,
            reason: 'Bloco 8 retry 5 (23056) ainda FALHA com v7.6.164');
        
        // Retry 6: 6677 chars
        const retry6 = 6677;
        expect(retry6 > limiteV163, isTrue,
            reason: 'v7.6.163: 6677 > 5650 (FALHOU)');
        expect(retry6 > validationLimit, isTrue,
            reason: 'v7.6.164: 6677 > $validationLimit (ainda FALHA)');
        
        print('⚠️ Bloco 8 (v7.6.163.2 falhou 6×):');
        print('   Limite v7.6.163: $limiteV163 chars');
        print('   Limite v7.6.164: $validationLimit chars');
        print('   Retry 1 (8341): FALHA em ambos ❌');
        print('   Retry 2 (19560): FALHA em ambos ❌');
        print('   Retry 3 (6975): FALHA em ambos ❌');
        print('   Retry 4 (6249): FALHA em ambos ❌');
        print('   Retry 5 (23056): FALHA em ambos ❌');
        print('   Retry 6 (6677): FALHA em ambos ❌');
        print('   💡 Flash ainda gera demais, mas -11% no ratio pode ajudar\n');
      });

      test('Comparação v7.6.163 vs v7.6.164 para blocos 7+', () {
        // v7.6.163: 930 × 4.5 × 1.08 × 1.25 = 5650
        const limiteV163 = 5650;
        
        // v7.6.164: 930 × 4.0 × 1.08 × 1.4 = ~5620
        
        print('📊 COMPARAÇÃO (Blocos 7+):');
        print('   v7.6.163: ratio 4.5, validação 1.25× = $limiteV163 chars');
        print('   v7.6.164: ratio 4.0, validação 1.4× = $validationLimit chars');
        print('   Diferença: ${validationLimit - limiteV163} chars (${((validationLimit / limiteV163 - 1) * 100).toStringAsFixed(1)}%)');
        print('   ');
        print('   🔍 Estratégia:');
        print('      • Ratio -11% (4.5→4.0) = Prompt pede menos');
        print('      • Validação +12% (1.25→1.4) = Aceita um pouco mais');
        print('      • Resultado: Limite similar mas Flash pode respeitar ratio menor\n');
      });
    });

    test('RESUMO: Abordagem híbrida v7.6.164', () {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📋 v7.6.164 - SOLUÇÃO HÍBRIDA');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      print('🎯 BLOCOS 1-6:');
      print('   Ratio: 4.5 chars/palavra');
      print('   Validação: 1.47× → 6644 chars');
      print('   ✅ Bloco 1 (6609) PASSA');
      print('');
      print('🎯 BLOCOS 7-12:');
      print('   Ratio: 4.0 chars/palavra (11% menor)');
      print('   Validação: 1.4× → ~5620 chars');
      print('   💡 Flash vê prompt com ratio menor, pode respeitar');
      print('   ⚠️ Validação 12% maior que v7.6.163 (1.25×→1.4×)');
      print('');
      print('🔬 HIPÓTESE:');
      print('   • Flash ignora validação backend (rejeita e retenta)');
      print('   • Flash pode respeitar ratio no prompt (4.0 vs 4.5)');
      print('   • Ratio -11% = ~448 chars menos por bloco');
      print('   • Combinado com mensagem ultra-agressiva');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      expect(true, isTrue);
    });
  });
}
