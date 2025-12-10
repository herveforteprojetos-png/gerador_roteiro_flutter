// 🧪 Testes para BlockCalculator
// 🆕 v7.6.126: Testes para validar suporte ao Gemini 3.0 Ultra

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/localization_level.dart';
import 'package:flutter_gerador/data/services/gemini/generation/block_calculator.dart';

/// Helper para criar ScriptConfig com valores padrão
ScriptConfig createTestConfig({
  required int quantity,
  required String language,
  required String qualityMode,
  String measureType = 'palavras',
}) {
  return ScriptConfig(
    apiKey: 'test-key',
    model: qualityMode,
    title: 'Teste',
    tema: 'Livre (Sem Tema)',
    subtema: '',
    localizacao: 'Brasil',
    measureType: measureType,
    quantity: quantity,
    language: language,
    perspective: 'terceira_pessoa',
    localizationLevel: LocalizationLevel.global,
    qualityMode: qualityMode,
  );
}

void main() {
  group('BlockCalculator - Gemini 3.0 Ultra', () {
    
    test('Português Ultra 15000 palavras deve gerar ~10 blocos', () {
      // Target Ultra: 1350 * 1.20 = 1620 palavras/bloco
      // 15000 ÷ 1620 = 9.26 → ceil = 10 blocos
      final config = createTestConfig(
        quantity: 15000,
        language: 'Português',
        qualityMode: 'gemini-3.0-ultra',
      );
      
      final blocos = BlockCalculator.calculateTotalBlocks(config);
      
      expect(blocos, equals(10));
    });
    
    test('Português Ultra 5000 palavras deve gerar ~4 blocos', () {
      final config = createTestConfig(
        quantity: 5000,
        language: 'Português',
        qualityMode: 'gemini-3.0-ultra',
      );
      
      final blocos = BlockCalculator.calculateTotalBlocks(config);
      
      expect(blocos, equals(4));
    });
    
    test('Inglês Ultra 10000 palavras deve gerar ~7 blocos', () {
      final config = createTestConfig(
        quantity: 10000,
        language: 'Inglês',
        qualityMode: 'gemini-3.0-ultra',
      );
      
      final blocos = BlockCalculator.calculateTotalBlocks(config);
      
      expect(blocos, equals(7));
    });
    
    test('Russo Ultra 8000 palavras deve gerar ~7 blocos', () {
      final config = createTestConfig(
        quantity: 8000,
        language: 'Russo',
        qualityMode: 'gemini-3.0-ultra',
      );
      
      final blocos = BlockCalculator.calculateTotalBlocks(config);
      
      expect(blocos, equals(7));
    });
    
    test('Coreano Ultra 5000 palavras deve aplicar redução de 0.72x (v7.6.136)', () {
      final config = createTestConfig(
        quantity: 5000,
        language: 'Coreano (한국어)',
        qualityMode: 'gemini-3.0-ultra',
      );
      
      final blocos = BlockCalculator.calculateTotalBlocks(config);
      
      // v7.6.136: Multiplicador reduzido de 1.18 para 0.72 para evitar word count excessivo
      // 5000 palavras / 840 target = 6 blocos * 0.72 = 4.32 → 5 blocos (mínimo)
      expect(blocos, equals(5));
    });
    
    test('Alemão Ultra 6000 palavras deve gerar ~5 blocos', () {
      final config = createTestConfig(
        quantity: 6000,
        language: 'Alemão',
        qualityMode: 'gemini-3.0-ultra',
      );
      
      final blocos = BlockCalculator.calculateTotalBlocks(config);
      
      expect(blocos, equals(5));
    });
  });
  
  group('BlockCalculator - Comparação PRO vs FLASH vs ULTRA', () {
    
    test('Português 6000 palavras: Ultra < Pro < Flash (menos blocos)', () {
      final configPro = createTestConfig(
        quantity: 6000,
        language: 'Português',
        qualityMode: 'gemini-2.5-pro',
      );
      
      final configFlash = createTestConfig(
        quantity: 6000,
        language: 'Português',
        qualityMode: 'gemini-2.5-flash',
      );
      
      final configUltra = createTestConfig(
        quantity: 6000,
        language: 'Português',
        qualityMode: 'gemini-3.0-ultra',
      );
      
      final blocosPro = BlockCalculator.calculateTotalBlocks(configPro);
      final blocosFlash = BlockCalculator.calculateTotalBlocks(configFlash);
      final blocosUltra = BlockCalculator.calculateTotalBlocks(configUltra);
      
      // Ultra: 6000 ÷ 1620 = 3.7 → 4 blocos
      // Pro: 6000 ÷ 1350 = 4.4 → 5 blocos
      // Flash: 6000 ÷ 900 = 6.7 → 7 blocos
      expect(blocosUltra, lessThan(blocosPro));
      expect(blocosPro, lessThan(blocosFlash));
      expect(blocosUltra, equals(4));
      expect(blocosPro, equals(5));
      expect(blocosFlash, equals(7));
    });
  });
  
  group('BlockCalculator - LanguageCategory', () {
    
    test('getCategory identifica idiomas latinos corretamente', () {
      expect(BlockCalculator.getCategory('Português'), equals(LanguageCategory.latino));
      expect(BlockCalculator.getCategory('Inglês'), equals(LanguageCategory.latino));
      expect(BlockCalculator.getCategory('Espanhol(mexicano)'), equals(LanguageCategory.latino));
      expect(BlockCalculator.getCategory('Francês'), equals(LanguageCategory.latino));
      expect(BlockCalculator.getCategory('Italiano'), equals(LanguageCategory.latino));
      expect(BlockCalculator.getCategory('Romeno'), equals(LanguageCategory.latino));
    });
    
    test('getCategory identifica idiomas cirílicos corretamente', () {
      expect(BlockCalculator.getCategory('Russo'), equals(LanguageCategory.cirilico));
      expect(BlockCalculator.getCategory('Búlgaro'), equals(LanguageCategory.cirilico));
    });
    
    test('getCategory identifica coreano corretamente', () {
      expect(BlockCalculator.getCategory('Coreano (한국어)'), equals(LanguageCategory.hangul));
    });
    
    test('getCategory identifica idiomas com diacríticos corretamente', () {
      expect(BlockCalculator.getCategory('Alemão'), equals(LanguageCategory.diacriticos));
      expect(BlockCalculator.getCategory('Polonês'), equals(LanguageCategory.diacriticos));
      expect(BlockCalculator.getCategory('Turco'), equals(LanguageCategory.diacriticos));
    });
  });
  
  group('BlockCalculator - getTargetPalBloco', () {
    
    test('Target PRO para latino é 1350', () {
      final config = createTestConfig(quantity: 2000, language: 'Português', qualityMode: 'gemini-2.5-pro');
      expect(BlockCalculator.getTargetPalBloco(config), equals(1350.0));
    });
    
    test('Target FLASH para latino é 67% do PRO (904.5)', () {
      final config = createTestConfig(quantity: 2000, language: 'Português', qualityMode: 'gemini-2.5-flash');
      expect(BlockCalculator.getTargetPalBloco(config), closeTo(904.5, 0.1));
    });
    
    test('Target ULTRA para latino é 120% do PRO (1620)', () {
      final config = createTestConfig(quantity: 2000, language: 'Português', qualityMode: 'gemini-3.0-ultra');
      expect(BlockCalculator.getTargetPalBloco(config), equals(1620.0));
    });
    
    test('Target ULTRA para cirílico é 1200 (1000 * 1.20)', () {
      final config = createTestConfig(quantity: 2000, language: 'Russo', qualityMode: 'gemini-3.0-ultra');
      expect(BlockCalculator.getTargetPalBloco(config), equals(1200.0));
    });
    
    test('Target ULTRA para hangul é 840 (700 * 1.20)', () {
      final config = createTestConfig(quantity: 2000, language: 'Coreano (한국어)', qualityMode: 'gemini-3.0-ultra');
      expect(BlockCalculator.getTargetPalBloco(config), equals(840.0));
    });
    
    test('Target ULTRA para diacríticos é 1320 (1100 * 1.20)', () {
      final config = createTestConfig(quantity: 2000, language: 'Alemão', qualityMode: 'gemini-3.0-ultra');
      expect(BlockCalculator.getTargetPalBloco(config), equals(1320.0));
    });
  });
  
  group('BlockCalculator - Limites de segurança', () {
    
    test('Mínimo de 2 blocos sempre aplicado', () {
      final config = createTestConfig(quantity: 500, language: 'Português', qualityMode: 'gemini-2.5-pro');
      expect(BlockCalculator.calculateTotalBlocks(config), greaterThanOrEqualTo(2));
    });
    
    test('Máximo para coreano é 50 blocos', () {
      final config = createTestConfig(quantity: 50000, language: 'Coreano (한국어)', qualityMode: 'gemini-2.5-flash');
      expect(BlockCalculator.calculateTotalBlocks(config), lessThanOrEqualTo(50));
    });
    
    test('Máximo para cirílico é 30 blocos', () {
      final config = createTestConfig(quantity: 50000, language: 'Russo', qualityMode: 'gemini-2.5-flash');
      expect(BlockCalculator.calculateTotalBlocks(config), lessThanOrEqualTo(30));
    });
    
    test('Máximo para latinos/diacríticos é 25 blocos', () {
      final config = createTestConfig(quantity: 50000, language: 'Português', qualityMode: 'gemini-2.5-flash');
      expect(BlockCalculator.calculateTotalBlocks(config), lessThanOrEqualTo(25));
    });
  });
}
