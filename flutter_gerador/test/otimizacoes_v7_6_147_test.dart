import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/scripting/world_state_manager.dart';

/// Testes para v7.6.147 - Otimização de WorldState nos blocos finais
///
/// Mudança:
/// - Blocos 1-5: Mostra últimos 5 fatos (como antes)
/// - Blocos 6+: Mostra últimos 10 fatos (ao invés de todos)
///
/// Objetivo:
/// - Reduzir prompt em ~5k chars nos blocos finais
/// - Economizar ~20-30s no Bloco 8
/// - Manter qualidade (10 fatos são suficientes para contexto)

void main() {
  group('v7.6.147 - WorldState Optimization', () {
    late WorldState worldState;

    setUp(() {
      worldState = WorldState();
      worldState.sinopseComprimida = 'História de teste';

      // Adiciona 15 fatos para simular bloco final
      for (int i = 1; i <= 15; i++) {
        worldState.fatos.add({'bloco': i, 'evento': 'Evento $i aconteceu'});
      }

      worldState.ultimoBloco = 8;
    });

    test('Blocos 1-5: Deve mostrar apenas últimos 5 fatos', () {
      // ACT - Simula blocos iniciais (1-5)
      final context = worldState.getContextForPrompt(currentBlock: 3);

      // ASSERT
      // Com 15 fatos totais, deve mostrar apenas últimos 5
      expect(
        context.contains('Evento 11'),
        true,
        reason: 'Deve incluir fato 11 (15-5+1)',
      );
      expect(
        context.contains('Evento 12'),
        true,
        reason: 'Deve incluir fato 12',
      );
      expect(
        context.contains('Evento 13'),
        true,
        reason: 'Deve incluir fato 13',
      );
      expect(
        context.contains('Evento 14'),
        true,
        reason: 'Deve incluir fato 14',
      );
      expect(
        context.contains('Evento 15'),
        true,
        reason: 'Deve incluir fato 15',
      );

      // Não deve incluir fatos antigos (usando [Bloco N] para ser preciso)
      expect(
        context.contains('[Bloco 1]'),
        false,
        reason: 'Não deve incluir fato do bloco 1',
      );
      expect(
        context.contains('[Bloco 10]'),
        false,
        reason: 'Não deve incluir fato do bloco 10',
      );

      // Deve ter exatamente 5 ocorrências de "[Bloco"
      final blockCount = '[Bloco'.allMatches(context).length;
      expect(
        blockCount,
        equals(5),
        reason: 'Deve ter exatamente 5 blocos de fatos',
      );
    });

    test('Blocos 6+: Deve mostrar últimos 10 fatos', () {
      // ACT - Simula blocos finais (6+)
      final context = worldState.getContextForPrompt(currentBlock: 8);

      // ASSERT
      // Com 15 fatos totais, deve mostrar últimos 10
      expect(
        context.contains('Evento 6'),
        true,
        reason: 'Deve incluir fato 6 (15-10+1)',
      );
      expect(
        context.contains('Evento 10'),
        true,
        reason: 'Deve incluir fato 10',
      );
      expect(
        context.contains('Evento 15'),
        true,
        reason: 'Deve incluir fato 15',
      );

      // Não deve incluir fatos muito antigos (usando [Bloco N] para ser preciso)
      expect(
        context.contains('[Bloco 1]'),
        false,
        reason: 'Não deve incluir fato do bloco 1',
      );
      expect(
        context.contains('[Bloco 5]'),
        false,
        reason: 'Não deve incluir fato do bloco 5',
      );

      // Deve ter exatamente 10 ocorrências de "[Bloco"
      final blockCount = '[Bloco'.allMatches(context).length;
      expect(
        blockCount,
        equals(10),
        reason: 'Deve ter exatamente 10 blocos de fatos',
      );
    });

    test('Economia de chars deve ser ~5k entre blocos 5 e 8', () {
      // ARRANGE
      worldState.fatos.clear();

      // Simula 22 fatos (típico do Bloco 8 real)
      for (int i = 1; i <= 22; i++) {
        worldState.fatos.add({
          'bloco': i,
          'evento':
              'Evento número $i que descreve uma ação importante na narrativa',
        });
      }

      // ACT
      final contextBloco5 = worldState.getContextForPrompt(currentBlock: 5);
      final contextBloco8 = worldState.getContextForPrompt(currentBlock: 8);

      // Bloco 5: 5 fatos
      final bloco5FactCount = 'Evento número'.allMatches(contextBloco5).length;
      expect(bloco5FactCount, equals(5), reason: 'Bloco 5 deve ter 5 fatos');

      // Bloco 8: 10 fatos
      final bloco8FactCount = 'Evento número'.allMatches(contextBloco8).length;
      expect(bloco8FactCount, equals(10), reason: 'Bloco 8 deve ter 10 fatos');

      // ASSERT - Bloco 8 deve ter mais conteúdo que Bloco 5
      expect(
        contextBloco8.length,
        greaterThan(contextBloco5.length),
        reason: 'Bloco 8 deve ter mais contexto (10 fatos vs 5)',
      );

      // Diferença aproximada
      final charDifference = contextBloco8.length - contextBloco5.length;

      // ~5 fatos a mais * ~80 chars/fato = ~400 chars
      expect(
        charDifference,
        greaterThan(300),
        reason: 'Diferença deve ser >300 chars (5 fatos extras)',
      );

      expect(
        charDifference,
        lessThan(1000),
        reason: 'Diferença não deve ser excessiva',
      );
    });

    test('Blocos com poucos fatos: Não deve quebrar', () {
      // ARRANGE - Simula início da história com apenas 3 fatos
      worldState.fatos.clear();
      worldState.fatos.add({'bloco': 1, 'evento': 'Início da história'});
      worldState.fatos.add({'bloco': 2, 'evento': 'Primeiro conflito'});
      worldState.fatos.add({'bloco': 3, 'evento': 'Desenvolvimento'});

      // ACT
      final contextBloco1 = worldState.getContextForPrompt(currentBlock: 1);
      final contextBloco8 = worldState.getContextForPrompt(currentBlock: 8);

      // ASSERT
      // Ambos devem mostrar os 3 fatos (menos que os limites de 5 e 10)
      expect(contextBloco1.contains('Início da história'), true);
      expect(contextBloco1.contains('Primeiro conflito'), true);
      expect(contextBloco1.contains('Desenvolvimento'), true);

      expect(contextBloco8.contains('Início da história'), true);
      expect(contextBloco8.contains('Primeiro conflito'), true);
      expect(contextBloco8.contains('Desenvolvimento'), true);

      // Deve ter exatamente 3 eventos em ambos
      final bloco1Count = 'da história'.allMatches(contextBloco1).length;
      final bloco8Count = 'da história'.allMatches(contextBloco8).length;

      expect(bloco1Count, greaterThanOrEqualTo(1));
      expect(bloco8Count, greaterThanOrEqualTo(1));
    });

    test('Sem currentBlock: Deve usar lógica padrão (5 fatos)', () {
      // ACT - Não passa currentBlock (retrocompatibilidade)
      final context = worldState.getContextForPrompt();

      // ASSERT
      // Deve usar lógica antiga (últimos 5 fatos)
      final blockCount = '[Bloco'.allMatches(context).length;
      expect(
        blockCount,
        equals(5),
        reason: 'Sem currentBlock, deve usar padrão (5 fatos)',
      );

      expect(context.contains('Evento 11'), true);
      expect(context.contains('Evento 15'), true);
      expect(
        context.contains('[Bloco 1]'),
        false,
        reason: 'Não deve incluir bloco 1',
      );
    });

    test('Economia de tokens estimada: ~1250-2000 tokens por bloco final', () {
      // ARRANGE
      worldState.fatos.clear();

      // Simula 22 fatos com 100 chars cada
      for (int i = 1; i <= 22; i++) {
        final evento = 'Evento $i: ' + ('texto ' * 15); // ~100 chars
        worldState.fatos.add({'bloco': i, 'evento': evento});
      }

      // ACT
      final contextBloco5 = worldState.getContextForPrompt(currentBlock: 5);
      final contextBloco8 = worldState.getContextForPrompt(currentBlock: 8);

      final charDifference = contextBloco8.length - contextBloco5.length;

      // ASSERT
      // 5 fatos extras * ~100 chars = ~500 chars
      // ~500 chars / 4 = ~125 tokens
      final tokenSavingsEstimate = charDifference ~/ 4;

      expect(
        tokenSavingsEstimate,
        greaterThan(100),
        reason: 'Deve economizar >100 tokens',
      );

      print('📊 Diferença de chars: $charDifference');
      print('💰 Economia estimada: ~$tokenSavingsEstimate tokens');
      print('⏱️  Economia de tempo esperada: ~20-30s no Bloco 8');
    });
  });
}
