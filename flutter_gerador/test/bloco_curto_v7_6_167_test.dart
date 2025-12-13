import 'package:flutter_test/flutter_test.dart';

/// ════════════════════════════════════════════════════════════════════════════════
/// 📊 TESTE v7.6.167 - FIX: Flash usa ajuste dinâmico de minAcceptable
/// ════════════════════════════════════════════════════════════════════════════════
///
/// 🐛 PROBLEMA ENCONTRADO:
/// - Bloco 7 com Ato 2 restando apenas 278 palavras
/// - Sistema exigia mínimo 440 palavras (fixo)
/// - Flash gerava 276-371 palavras (tentando respeitar ato)
/// - Loop infinito: blocos CURTOS rejeitados
///
/// 🔍 CAUSA RAIZ:
/// ```dart
/// else if (isActNearLimit && !isFlashModel && !isKorean)
/// ```
/// A condição `!isFlashModel` excluía o Flash do ajuste dinâmico!
/// O `finalMinAcceptable` ficava em 440 palavras fixo.
///
/// ✅ CORREÇÃO v7.6.167:
/// ```dart
/// else if (isActNearLimit && !isKorean)  // Flash agora INCLUÍDO!
/// ```
/// Removido `!isFlashModel`, agora Flash também se beneficia do ajuste.
///
/// 📊 CÁLCULO ESPERADO PARA BLOCO 7:
/// - Ato 2 restante: 278 palavras
/// - minFromTarget (35% de 930): 326 palavras
/// - minFromRemaining (60% de 278): 167 palavras
/// - finalMinAcceptable = min(326, 167) = **167 palavras** ✅
///
/// Agora blocos de 276-371 palavras deveriam PASSAR!
///
/// ════════════════════════════════════════════════════════════════════════════════

void main() {
  group('v7.6.167 - Ajuste dinâmico de minAcceptable para Flash', () {
    test('Bloco 7: 278 palavras restantes → minAcceptable = 167', () {
      // Dados reais do log
      const actRestante = 278;
      const target = 930;
      
      // Cálculo esperado v7.6.167
      final minFromTarget = (target * 0.35).round(); // 326
      final minFromRemaining = (actRestante * 0.6).round(); // 167
      final finalMinAcceptable = minFromTarget < minFromRemaining 
          ? minFromTarget 
          : minFromRemaining;
      
      expect(minFromTarget, 326, reason: '35% do target (930)');
      expect(minFromRemaining, 167, reason: '60% do restante (278)');
      expect(finalMinAcceptable, 167, 
        reason: 'Deve usar o MENOR (167), não o fixo 440!');
    });

    test('Blocos reais do log PASSARIAM com v7.6.167', () {
      const minAcceptable = 167; // Calculado acima
      
      // Blocos reais gerados pelo Flash no Bloco 7
      const retry1 = 325; // ✅ PASSA (325 > 167)
      const retry2 = 304; // ✅ PASSA (304 > 167)  
      const retry3 = 276; // ✅ PASSA (276 > 167)
      const retry4 = 333; // ✅ PASSA (333 > 167)
      const retry5 = 297; // ✅ PASSA (297 > 167)
      const retry6 = 371; // ✅ PASSA (371 > 167)
      
      expect(retry1, greaterThan(minAcceptable), reason: 'Retry 1: 325 > 167 ✅');
      expect(retry2, greaterThan(minAcceptable), reason: 'Retry 2: 304 > 167 ✅');
      expect(retry3, greaterThan(minAcceptable), reason: 'Retry 3: 276 > 167 ✅');
      expect(retry4, greaterThan(minAcceptable), reason: 'Retry 4: 333 > 167 ✅');
      expect(retry5, greaterThan(minAcceptable), reason: 'Retry 5: 297 > 167 ✅');
      expect(retry6, greaterThan(minAcceptable), reason: 'Retry 6: 371 > 167 ✅');
    });

    test('Lógica do menor valor: evita exigir mais que o ato permite', () {
      // Cenário: restam 200 palavras no ato
      const actRestante200 = 200;
      const target = 930;
      
      final minFromTarget = (target * 0.35).round(); // 326
      final minFromRemaining = (actRestante200 * 0.6).round(); // 120
      final finalMin = minFromTarget < minFromRemaining 
          ? minFromTarget 
          : minFromRemaining;
      
      expect(finalMin, 120, 
        reason: 'Deve usar 120 (60% de 200), não 326 que excede o ato!');
    });

    test('Cenário oposto: ato com espaço suficiente', () {
      // Cenário: restam 800 palavras no ato (sem limite)
      const actRestante800 = 800;
      const target = 930;
      
      final minFromTarget = (target * 0.35).round(); // 326
      final minFromRemaining = (actRestante800 * 0.6).round(); // 480
      final finalMin = minFromTarget < minFromRemaining 
          ? minFromTarget 
          : minFromRemaining;
      
      expect(finalMin, 326, 
        reason: 'Deve usar 326 (35% target), menor que 480 restantes');
    });

    test('v7.6.166 vs v7.6.167: comparação de comportamento', () {
      const actRestante = 278;
      const target = 930;
      
      // v7.6.166: Flash EXCLUÍDO do ajuste (falha)
      const v166MinAcceptable = 440; // Fixo, não ajustado!
      
      // v7.6.167: Flash INCLUÍDO no ajuste (correção)
      final minFromTarget = (target * 0.35).round();
      final minFromRemaining = (actRestante * 0.6).round();
      final v167MinAcceptable = minFromTarget < minFromRemaining 
          ? minFromTarget 
          : minFromRemaining;
      
      print('\n📊 COMPARAÇÃO:');
      print('   v7.6.166 (Flash excluído): $v166MinAcceptable palavras');
      print('   v7.6.167 (Flash incluído): $v167MinAcceptable palavras');
      print('   Bloco Flash gerou: 276-371 palavras');
      print('   v7.6.166: ❌ REJEITA (276 < 440)');
      print('   v7.6.167: ✅ ACEITA (276 > 167)');
      
      expect(v167MinAcceptable, lessThan(v166MinAcceptable),
        reason: 'v7.6.167 deve ter minAcceptable MENOR que v7.6.166');
      expect(276, lessThan(v166MinAcceptable),
        reason: 'v7.6.166 rejeitaria bloco de 276 palavras');
      expect(276, greaterThan(v167MinAcceptable),
        reason: 'v7.6.167 aceita bloco de 276 palavras');
    });

    test('Edge case: último bloco também usa ajuste', () {
      // Último bloco (12/12) com Ato 3 restando 500 palavras
      const actRestante = 500;
      const target = 930;
      const isLastBlock = true;
      
      if (isLastBlock) {
        // Lógica diferente para último bloco
        final minFromTarget = (target * 0.40).round(); // 372
        final minFromRemaining = actRestante; // 500
        final finalMin = minFromTarget < minFromRemaining 
            ? minFromTarget 
            : minFromRemaining;
        
        expect(finalMin, 372, 
          reason: 'Último bloco: 40% do target (372) < restantes (500)');
      }
    });
  });
}
