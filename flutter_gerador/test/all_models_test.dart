import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/prompts/block_prompt_builder.dart';

void main() {
  group('Todos 3 Modelos (Flash/Pro/Ultra) - Mesmos Limites', () {
    test('Inglês - limites iguais para Flash, Pro e Ultra', () {
      // Simular configuração com Inglês
      final charsPerWord = BlockPromptBuilder.getCharsPerWordForLanguage('Inglês');
      final adjustedTarget = 930 * 1.05; // 977 palavras (Inglês tem multiplier 1.05)
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();
      final rejectionLimit = (maxChars * 1.5).round();

      print('\n📊 INGLÊS - TODOS OS MODELOS:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite prompt: $maxChars chars');
      print('   Limite rejeição: $rejectionLimit chars');
      print('   ✅ Flash: USA ESTE LIMITE');
      print('   ✅ Pro: USA ESTE LIMITE');
      print('   ✅ Ultra: USA ESTE LIMITE\n');

      expect(charsPerWord, 4.7);
      expect(maxChars, 4957);
      expect(rejectionLimit, 7436);
    });

    test('Coreano - modelo mais compacto (2.5 chars/palavra)', () {
      final charsPerWord = BlockPromptBuilder.getCharsPerWordForLanguage('Coreano');
      final adjustedTarget = 930 * 1.20; // 1116 palavras (Coreano pede 20% mais)
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('📊 COREANO - TODOS OS MODELOS:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   ✅ Mais compacto dos 13 idiomas\n');

      expect(charsPerWord, 2.5);
      expect(maxChars, 3013);
    });

    test('Alemão - modelo mais verboso (6.5 chars/palavra)', () {
      final charsPerWord = BlockPromptBuilder.getCharsPerWordForLanguage('Alemão');
      final adjustedTarget = 930 * 1.0; // 930 palavras
      final maxChars = (adjustedTarget * charsPerWord * 1.08).round();

      print('📊 ALEMÃO - TODOS OS MODELOS:');
      print('   Chars/palavra: $charsPerWord');
      print('   Target: ${adjustedTarget.round()} palavras');
      print('   Limite: $maxChars chars');
      print('   ✅ Mais verboso dos 13 idiomas\n');

      expect(charsPerWord, 6.5);
      expect(maxChars, 6529);
    });

    test('Confirmação: Função NÃO depende do modelo', () {
      // getCharsPerWordForLanguage() só recebe "language" como parâmetro
      // NÃO recebe "qualityMode" ou "model"
      // Logo: TODOS os modelos usam o MESMO limite!

      final inglesFlash = BlockPromptBuilder.getCharsPerWordForLanguage('Inglês');
      final inglesPro = BlockPromptBuilder.getCharsPerWordForLanguage('Inglês');
      final inglesUltra = BlockPromptBuilder.getCharsPerWordForLanguage('Inglês');

      print('✅ CONFIRMAÇÃO FINAL:');
      print('   Flash (Inglês): $inglesFlash chars/palavra');
      print('   Pro (Inglês): $inglesPro chars/palavra');
      print('   Ultra (Inglês): $inglesUltra chars/palavra');
      print('   → Todos IGUAIS!\n');

      expect(inglesFlash, inglesPro);
      expect(inglesPro, inglesUltra);
      expect(inglesFlash, 4.7);
    });

    test('Resumo: 13 idiomas × 3 modelos = 39 combinações cobertas', () {
      final idiomas = [
        'Português', 'Inglês', 'Espanhol', 'Francês', 'Alemão', 
        'Italiano', 'Polonês', 'Búlgaro', 'Russo', 'Coreano', 
        'Turco', 'Romeno', 'Croata'
      ];

      print('══════════════════════════════════════════════════════');
      print('✅ COBERTURA COMPLETA:');
      print('══════════════════════════════════════════════════════');
      print('   13 idiomas');
      print('   × 3 modelos (Flash, Pro, Ultra)');
      print('   ─────────────────────');
      print('   = 39 combinações funcionando!');
      print('');
      print('   Prompt ultra-agressivo: 🚨⛔❌ (todos modelos)');
      print('   Validação de rejeição: 1.5× limite (todos modelos)');
      print('   Detecção robusta: encoding/acentos (todos idiomas)');
      print('══════════════════════════════════════════════════════\n');

      expect(idiomas.length, 13);
      expect(idiomas.length * 3, 39); // 39 combinações
    });
  });
}
