// ignore_for_file: avoid_print
/// 🧪 Testes para NameValidator e PostGenerationFixer
/// v7.6.136: Testes para validação de conflitos de nomes e expansão de títulos

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/gemini/validation/name_validator.dart';
import 'package:flutter_gerador/data/services/gemini/validation/post_generation_fixer.dart';

void main() {
  group('📝 NameValidator.hasNameConflict', () {
    test('✅ Retorna false para compoundWhitelist', () {
      // Nomes compostos na whitelist nunca devem gerar conflito
      expect(
        NameValidator.hasNameConflict('Minas Gerais', {'minas'}),
        false,
        reason: 'Minas Gerais está na whitelist',
      );
      expect(
        NameValidator.hasNameConflict('São Paulo', {'são', 'paulo'}),
        false,
        reason: 'São Paulo está na whitelist',
      );
      expect(
        NameValidator.hasNameConflict('Torre Corporativa', {'torre'}),
        false,
        reason: 'Torre Corporativa está na whitelist',
      );
    });

    test('✅ Retorna false para nomes com títulos (Doutor, Senhor)', () {
      // Nomes com prefixos de títulos não devem gerar conflito
      expect(
        NameValidator.hasNameConflict('Doutor Álvaro', {'álvaro'}),
        false,
        reason: 'Prefixo "Doutor" indica tratamento, não conflito',
      );
      expect(
        NameValidator.hasNameConflict('Senhor Carlos', {'carlos'}),
        false,
        reason: 'Prefixo "Senhor" indica tratamento, não conflito',
      );
      expect(
        NameValidator.hasNameConflict('Dona Lúcia', {'lúcia'}),
        false,
        reason: 'Prefixo "Dona" indica tratamento, não conflito',
      );
    });

    test('✅ Retorna false para frases com conjunções', () {
      // Frases com "mas", "ou", "era" no início não são conflitos
      expect(
        NameValidator.hasNameConflict('Mas Otávio', {'otávio'}),
        false,
        reason: '"Mas Otávio" é uma frase, não um nome',
      );
      expect(
        NameValidator.hasNameConflict('Ou Helena', {'helena'}),
        false,
        reason: '"Ou Helena" é uma frase, não um nome',
      );
      expect(
        NameValidator.hasNameConflict('Era Maria', {'maria'}),
        false,
        reason: '"Era Maria" é uma frase, não um nome',
      );
    });

    test('✅ Retorna false para nomes compostos na whitelist (v7.6.136)', () {
      // Novos itens adicionados na v7.6.136
      expect(
        NameValidator.hasNameConflict('Otávio Albuquerque', {'otávio'}),
        false,
        reason: 'Otávio Albuquerque está na whitelist (v7.6.136)',
      );
      expect(
        NameValidator.hasNameConflict('Horizonte Sustentável', {'horizonte'}),
        false,
        reason: 'Horizonte Sustentável está na whitelist (v7.6.136)',
      );
      expect(
        NameValidator.hasNameConflict('Futuro Verde', {'futuro'}),
        false,
        reason: 'Futuro Verde está na whitelist (v7.6.136)',
      );
    });

    test('✅ Retorna false para nomes com prefixo Dr/Prof', () {
      // Abreviações de títulos
      expect(
        NameValidator.hasNameConflict('Dr Álvaro', {'álvaro'}),
        false,
        reason: 'Prefixo "Dr" indica título',
      );
      expect(
        NameValidator.hasNameConflict('Prof Carlos', {'carlos'}),
        false,
        reason: 'Prefixo "Prof" indica título',
      );
    });

    test('🔴 Retorna true para conflito real (match exato)', () {
      expect(
        NameValidator.hasNameConflict('Otávio', {'Otávio'}),
        true,
        reason: 'Match exato deve gerar conflito',
      );
    });

    test('✅ Retorna false para nomes compostos (relaxamento v7.6.127)', () {
      // Relaxamento: nomes compostos longos (>2 palavras) ou existentes compostos
      // não geram conflito para permitir variações
      expect(
        NameValidator.hasNameConflict('Montenegro', {'Otávio Montenegro'}),
        false,
        reason: 'Nomes curtos não bloqueiam por substring em compostos (relaxamento)',
      );
    });
    
    test('🔴 Retorna true quando nome novo contém nome existente longo', () {
      // "Carlos Ferreira" contém "carlos" (existente) que tem >3 chars
      // E NÃO está na whitelist
      expect(
        NameValidator.hasNameConflict('Carlos Ferreira', {'carlos'}),
        true,
        reason: 'Nome novo contém nome existente de >3 chars (conflito)',
      );
    });
  });

  group('📝 NameValidator.isPhrase', () {
    test('✅ Detecta frases com conjunções', () {
      expect(NameValidator.isPhrase('Mas Otávio'), true);
      expect(NameValidator.isPhrase('Ou Helena'), true);
      expect(NameValidator.isPhrase('Enquanto Maria'), true);
    });

    test('✅ Detecta frases com preposições', () {
      expect(NameValidator.isPhrase('Era Maria'), true);
      expect(NameValidator.isPhrase('Foi João'), true);
    });

    test('✅ NÃO detecta nomes simples como frases', () {
      expect(NameValidator.isPhrase('Otávio'), false);
      expect(NameValidator.isPhrase('Helena Montenegro'), false);
      expect(NameValidator.isPhrase('João Carlos'), false);
    });
  });

  group('📝 PostGenerationFixer.expandTitleAbbreviation', () {
    test('✅ Expande Dr para Doutor', () {
      expect(
        PostGenerationFixer.expandTitleAbbreviation('Dr Álvaro chegou.'),
        'Doutor Álvaro chegou.',
        reason: 'Dr deve expandir para Doutor',
      );
    });

    test('✅ Expande Dr. (com ponto) para Doutor', () {
      expect(
        PostGenerationFixer.expandTitleAbbreviation('Dr. Carlos disse.'),
        'Doutor Carlos disse.',
        reason: 'Dr. deve expandir para Doutor',
      );
    });

    test('✅ Expande Sr para Senhor', () {
      expect(
        PostGenerationFixer.expandTitleAbbreviation('Sr Pedro entrou.'),
        'Senhor Pedro entrou.',
        reason: 'Sr deve expandir para Senhor',
      );
    });

    test('✅ Expande Sra para Senhora', () {
      expect(
        PostGenerationFixer.expandTitleAbbreviation('Sra Maria saiu.'),
        'Senhora Maria saiu.',
        reason: 'Sra deve expandir para Senhora',
      );
    });

    test('✅ Expande D. para Dona', () {
      expect(
        PostGenerationFixer.expandTitleAbbreviation('D. Lúcia sorriu.'),
        'Dona Lúcia sorriu.',
        reason: 'D. deve expandir para Dona',
      );
    });

    test('✅ Não modifica texto sem abreviações', () {
      const original = 'Doutor Carlos e Senhora Maria conversaram.';
      expect(
        PostGenerationFixer.expandTitleAbbreviation(original),
        original,
        reason: 'Texto sem abreviações deve permanecer igual',
      );
    });

    test('✅ Expande múltiplas abreviações', () {
      expect(
        PostGenerationFixer.expandTitleAbbreviation('Dr Álvaro e Sra Maria.'),
        'Doutor Álvaro e Senhora Maria.',
        reason: 'Múltiplas abreviações devem ser expandidas',
      );
    });
  });

  group('📝 PostGenerationFixer.isFamilyRelation', () {
    test('✅ Detecta relações familiares em português', () {
      expect(PostGenerationFixer.isFamilyRelation('filho'), true);
      expect(PostGenerationFixer.isFamilyRelation('filha'), true);
      expect(PostGenerationFixer.isFamilyRelation('pai'), true);
      expect(PostGenerationFixer.isFamilyRelation('mãe'), true);
      expect(PostGenerationFixer.isFamilyRelation('irmão'), true);
      expect(PostGenerationFixer.isFamilyRelation('irmã'), true);
    });

    test('✅ Detecta relações familiares em inglês', () {
      expect(PostGenerationFixer.isFamilyRelation('son'), true);
      expect(PostGenerationFixer.isFamilyRelation('daughter'), true);
      expect(PostGenerationFixer.isFamilyRelation('father'), true);
      expect(PostGenerationFixer.isFamilyRelation('mother'), true);
    });

    test('✅ Ignora case (case-insensitive)', () {
      expect(PostGenerationFixer.isFamilyRelation('FILHO'), true);
      expect(PostGenerationFixer.isFamilyRelation('Mãe'), true);
      expect(PostGenerationFixer.isFamilyRelation('MOTHER'), true);
    });

    test('✅ NÃO detecta nomes como relações', () {
      expect(PostGenerationFixer.isFamilyRelation('João'), false);
      expect(PostGenerationFixer.isFamilyRelation('Maria'), false);
      expect(PostGenerationFixer.isFamilyRelation('Otávio'), false);
    });
  });

  group('📝 NameValidator.compoundWhitelist (v7.6.136)', () {
    test('✅ Contém localizações geográficas', () {
      expect(NameValidator.compoundWhitelist.contains('minas gerais'), true);
      expect(NameValidator.compoundWhitelist.contains('são paulo'), true);
      expect(NameValidator.compoundWhitelist.contains('porto alegre'), true);
      expect(NameValidator.compoundWhitelist.contains('belo horizonte'), true);
    });

    test('✅ Contém organizações/empresas', () {
      expect(NameValidator.compoundWhitelist.contains('torre corporativa'), true);
      expect(NameValidator.compoundWhitelist.contains('grupo otávio'), true);
      expect(NameValidator.compoundWhitelist.contains('horizonte sustentável'), true);
      expect(NameValidator.compoundWhitelist.contains('futuro verde'), true);
      expect(NameValidator.compoundWhitelist.contains('polícia federal'), true);
    });

    test('✅ Contém nomes com títulos', () {
      expect(NameValidator.compoundWhitelist.contains('doutor álvaro'), true);
      expect(NameValidator.compoundWhitelist.contains('dona lúcia'), true);
      expect(NameValidator.compoundWhitelist.contains('padre antônio'), true);
    });

    test('✅ Contém nomes compostos de personagens', () {
      expect(NameValidator.compoundWhitelist.contains('otávio albuquerque'), true);
      expect(NameValidator.compoundWhitelist.contains('otávio montenegro'), true);
      expect(NameValidator.compoundWhitelist.contains('helena montenegro'), true);
      expect(NameValidator.compoundWhitelist.contains('maria helena'), true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 🆕 v7.6.136: Testes para formato Gemini (minúsculo + NOMES MAIÚSCULOS)
  // ═══════════════════════════════════════════════════════════════════════════

  group('📝 NameValidator Formato Gemini (v7.6.136)', () {
    test('✅ isUppercaseNameFormat detecta formato Gemini', () {
      const geminiText = 'MATEUS olhava o relógio. ele sorriu para HELENA.';
      expect(NameValidator.isUppercaseNameFormat(geminiText), true);
    });

    test('✅ isUppercaseNameFormat rejeita formato tradicional', () {
      const traditionalText = 'Mateus olhava o relógio. Ele sorriu para Helena.';
      expect(NameValidator.isUppercaseNameFormat(traditionalText), false);
    });

    test('✅ extractNamesFromUppercaseFormat extrai nomes maiúsculos', () {
      const text = 'MATEUS olhava o relógio. ele sorriu para HELENA.';
      final names = NameValidator.extractNamesFromUppercaseFormat(text);
      expect(names, containsAll(['MATEUS', 'HELENA']));
    });

    test('✅ extractNamesFromUppercaseFormat ignora palavras comuns', () {
      const text = 'EU falei MAS ele não ouviu COM ela.';
      final names = NameValidator.extractNamesFromUppercaseFormat(text);
      expect(names, isEmpty);
    });

    test('✅ extractNamesFromUppercaseFormat detecta nomes acentuados', () {
      const text = 'CÉSAR falou com ÁLVARO sobre INÊS.';
      final names = NameValidator.extractNamesFromUppercaseFormat(text);
      expect(names, containsAll(['CÉSAR', 'ÁLVARO', 'INÊS']));
    });

    test('✅ extractNamesFromText auto-detecta formato Gemini', () {
      const geminiText = 'MATEUS olhava HELENA. ele sorriu.';
      final names = NameValidator.extractNamesFromText(geminiText);
      
      // Deve retornar em Title Case (Mateus, Helena)
      expect(names, containsAll(['Mateus', 'Helena']));
      expect(names, isNot(contains('MATEUS')));
      expect(names, isNot(contains('HELENA')));
    });

    test('✅ extractNamesFromText usa lógica tradicional para formato Title Case', () {
      // Texto tradicional com nomes no meio de frases
      const traditionalText = 'E então Arthur disse que Maria estava lá.';
      final names = NameValidator.extractNamesFromText(traditionalText);
      
      expect(names, containsAll(['Arthur', 'Maria']));
    });
  });
}
