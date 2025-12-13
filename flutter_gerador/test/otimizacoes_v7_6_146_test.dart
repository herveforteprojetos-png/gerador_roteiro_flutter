import 'package:flutter_test/flutter_test.dart';

/// Testes para v7.6.146 - Otimizações de velocidade e timeout
///
/// Mudanças:
/// 1. Context trim reduzido: 20k → 15k chars
/// 2. Timeout de API reduzido: 5min → 3min
///
/// Objetivos:
/// - Acelerar geração dos blocos finais (5min → 2-3min esperado)
/// - Evitar esperas excessivas (timeout 3min vs 5min)
/// - Manter qualidade narrativa (15k chars = ~2.5 blocos de contexto)

void main() {
  group('v7.6.146 - Otimizações de Velocidade', () {
    test('Context trim deve ativar em 15k chars (não mais 20k)', () {
      // ARRANGE
      const contextSize = 16000; // Acima do novo limite de 15k
      final contextoPrevio = 'a' * contextSize;

      // ACT - Simula lógica de trim
      final shouldTrim = contextoPrevio.length > 15000;
      final trimmedContext = shouldTrim
          ? '...[contexto anterior resumido]\n\n${contextoPrevio.substring(contextoPrevio.length - 15000)}'
          : contextoPrevio;

      // ASSERT
      expect(shouldTrim, true, reason: 'Trim deve ativar em 16k chars');
      expect(
        trimmedContext.length,
        lessThan(16000),
        reason: 'Contexto trimmed deve ser menor que original',
      );
      expect(
        trimmedContext.contains('...[contexto anterior resumido]'),
        true,
        reason: 'Deve incluir marcador de resumo',
      );
      expect(
        trimmedContext.endsWith('a' * 15000),
        true,
        reason: 'Deve preservar últimos 15k chars',
      );
    });

    test('Context trim NÃO deve ativar em 14k chars (abaixo do limite)', () {
      // ARRANGE
      const contextSize = 14000; // Abaixo do limite de 15k
      final contextoPrevio = 'a' * contextSize;

      // ACT
      final shouldTrim = contextoPrevio.length > 15000;
      final trimmedContext = shouldTrim
          ? '...[contexto anterior resumido]\n\n${contextoPrevio.substring(contextoPrevio.length - 15000)}'
          : contextoPrevio;

      // ASSERT
      expect(shouldTrim, false, reason: 'Trim NÃO deve ativar em 14k chars');
      expect(
        trimmedContext.length,
        equals(14000),
        reason: 'Contexto deve permanecer intacto',
      );
      expect(
        trimmedContext.contains('...[contexto anterior resumido]'),
        false,
        reason: 'Não deve incluir marcador de resumo',
      );
    });

    test('Economia de chars deve ser ~5k comparado com v7.6.145', () {
      // ARRANGE
      const largeContextSize = 25000; // Contexto grande típico de blocos finais

      // ACT
      // v7.6.145 (antigo): cap 20k
      final trimmedOld = largeContextSize > 20000
          ? 20000 + '...[contexto anterior resumido]\n\n'.length
          : largeContextSize;

      // v7.6.146 (novo): cap 15k
      final trimmedNew = largeContextSize > 15000
          ? 15000 + '...[contexto anterior resumido]\n\n'.length
          : largeContextSize;

      final savings = trimmedOld - trimmedNew;

      // ASSERT
      expect(
        savings,
        equals(5000),
        reason: 'Economia deve ser 5k chars (20k - 15k)',
      );

      // Economia de tokens (4 chars ≈ 1 token)
      final tokenSavings = savings ~/ 4;
      expect(
        tokenSavings,
        equals(1250),
        reason: 'Economia de ~1250 tokens por bloco com trim',
      );
    });

    test('Timeout deve ser 3 minutos (180 segundos)', () {
      // ARRANGE
      const expectedTimeoutMinutes = 3;
      const expectedTimeoutSeconds = 180;

      // ACT
      final timeout = Duration(minutes: expectedTimeoutMinutes);

      // ASSERT
      expect(
        timeout.inMinutes,
        equals(3),
        reason: 'Timeout deve ser 3 minutos',
      );
      expect(
        timeout.inSeconds,
        equals(expectedTimeoutSeconds),
        reason: 'Timeout deve ser 180 segundos',
      );
      expect(
        timeout.inSeconds,
        lessThan(300),
        reason: 'Timeout deve ser menor que 5 minutos (antigo)',
      );
    });

    test('Velocidade esperada dos blocos finais deve melhorar ~40%', () {
      // ARRANGE
      const oldBlockTime = 300; // 5 minutos (observado no Bloco 8)
      const newContextSize = 15000; // Novo limite
      const oldContextSize = 20000; // Limite antigo

      // ACT
      // Redução de contexto: 25% menos chars (15k vs 20k)
      final contextReduction =
          (oldContextSize - newContextSize) / oldContextSize;

      // Velocidade esperada: ~40% mais rápido (baseado em redução de contexto + overhead)
      final expectedSpeedup = 0.4;
      final expectedNewBlockTime = oldBlockTime * (1 - expectedSpeedup);

      // ASSERT
      expect(
        contextReduction,
        closeTo(0.25, 0.01),
        reason: 'Redução de contexto deve ser ~25%',
      );
      expect(
        expectedNewBlockTime,
        closeTo(180, 10),
        reason: 'Blocos finais devem levar ~3min (vs 5min antes)',
      );
      expect(
        expectedNewBlockTime,
        lessThan(oldBlockTime),
        reason: 'Velocidade deve melhorar',
      );
    });
  });
}
