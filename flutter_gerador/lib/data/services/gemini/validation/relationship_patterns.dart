// 🏗️ v7.6.67: Módulo extraído de gemini_service.dart
// Padrões de relacionamento e validação de nomes
// Parte da arquitetura SOLID - Single Responsibility Principle

import 'package:flutter/foundation.dart';

/// 🎭 Padrões de relacionamento para validação de personagens
class RelationshipPatterns {
  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - PORTUGUÊS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Português
  static final Map<String, RegExp> portugueseRelations = {
    'marido': RegExp(
      r'meu marido(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'esposa': RegExp(
      r'minha esposa(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'pai': RegExp(r'meu pai(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'mãe': RegExp(r'minha mãe(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'irmão': RegExp(r'meu irmão(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'irmã': RegExp(r'minha irmã(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'sogro': RegExp(r'meu sogro(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'sogra': RegExp(r'minha sogra(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'cunhado': RegExp(
      r'meu cunhado(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'cunhada': RegExp(
      r'minha cunhada(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'genro': RegExp(r'meu genro(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'nora': RegExp(r'minha nora(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'neto': RegExp(r'meu neto(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'neta': RegExp(r'minha neta(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'avô': RegExp(r'meu avô(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'avó': RegExp(r'minha avó(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'filho': RegExp(r'meu filho(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'filha': RegExp(r'minha filha(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'tio': RegExp(r'meu tio(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'tia': RegExp(r'minha tia(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'primo': RegExp(r'meu primo(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'prima': RegExp(r'minha prima(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'sobrinho': RegExp(
      r'meu sobrinho(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'sobrinha': RegExp(
      r'minha sobrinha(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - INGLÊS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Inglês
  static final Map<String, RegExp> englishRelations = {
    'husband': RegExp(
      r'my husband(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'wife': RegExp(r'my wife(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'father': RegExp(r'my father(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'mother': RegExp(r'my mother(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'brother': RegExp(r'my brother(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'sister': RegExp(r'my sister(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'father_in_law': RegExp(
      r'my father-in-law(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'mother_in_law': RegExp(
      r'my mother-in-law(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'brother_in_law': RegExp(
      r'my brother-in-law(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'sister_in_law': RegExp(
      r'my sister-in-law(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'son_in_law': RegExp(
      r'my son-in-law(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'daughter_in_law': RegExp(
      r'my daughter-in-law(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'grandson': RegExp(
      r'my grandson(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'granddaughter': RegExp(
      r'my granddaughter(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'grandfather': RegExp(
      r'my grandfather(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'grandmother': RegExp(
      r'my grandmother(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'son': RegExp(r'my son(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'daughter': RegExp(
      r'my daughter(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'uncle': RegExp(r'my uncle(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'aunt': RegExp(r'my aunt(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'cousin': RegExp(r'my cousin(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'nephew': RegExp(r'my nephew(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'niece': RegExp(r'my niece(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - FRANCÊS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Francês
  static final Map<String, RegExp> frenchRelations = {
    'mari': RegExp(r'mon mari(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'femme': RegExp(r'ma femme(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'père': RegExp(r'mon père(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'mère': RegExp(r'ma mère(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'frère': RegExp(r'mon frère(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'sœur': RegExp(r'ma sœur(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'beau_père': RegExp(
      r'mon beau-père(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'belle_mère': RegExp(
      r'ma belle-mère(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'beau_frère': RegExp(
      r'mon beau-frère(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'belle_sœur': RegExp(
      r'ma belle-sœur(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'fils': RegExp(r'mon fils(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'fille': RegExp(r'ma fille(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'petit_fils': RegExp(
      r'mon petit-fils(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'petite_fille': RegExp(
      r'ma petite-fille(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'grand_père': RegExp(
      r'mon grand-père(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'grand_mère': RegExp(
      r'ma grand-mère(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - ESPANHOL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Espanhol
  static final Map<String, RegExp> spanishRelations = {
    'marido': RegExp(r'mi marido(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'esposa': RegExp(r'mi esposa(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'padre': RegExp(r'mi padre(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'madre': RegExp(r'mi madre(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'hermano': RegExp(r'mi hermano(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'hermana': RegExp(r'mi hermana(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'suegro': RegExp(r'mi suegro(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'suegra': RegExp(r'mi suegra(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'cuñado': RegExp(r'mi cuñado(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'cuñada': RegExp(r'mi cuñada(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'hijo': RegExp(r'mi hijo(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'hija': RegExp(r'mi hija(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'nieto': RegExp(r'mi nieto(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'nieta': RegExp(r'mi nieta(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'abuelo': RegExp(r'mi abuelo(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'abuela': RegExp(r'mi abuela(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS UTILITÁRIOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtém todos os padrões de relacionamento para um idioma
  static Map<String, RegExp> getRelationsForLanguage(String language) {
    final normalized = language.toLowerCase().trim();

    if (normalized.contains('inglês') ||
        normalized.contains('ingles') ||
        normalized.contains('english') ||
        normalized == 'en') {
      return englishRelations;
    }

    if (normalized.contains('franc') ||
        normalized.contains('french') ||
        normalized == 'fr') {
      return frenchRelations;
    }

    if (normalized.contains('espanhol') ||
        normalized.contains('spanish') ||
        normalized.contains('español') ||
        normalized == 'es') {
      return spanishRelations;
    }

    // Português como padrão
    return portugueseRelations;
  }

  /// Extrai relacionamentos de um texto
  static Map<String, Set<String>> extractRelationships(
    String text,
    String language,
  ) {
    final relations = getRelationsForLanguage(language);
    final extracted = <String, Set<String>>{};

    for (final entry in relations.entries) {
      final relationType = entry.key;
      final pattern = entry.value;

      for (final match in pattern.allMatches(text)) {
        final name = match.group(1);
        if (name != null) {
          extracted.putIfAbsent(relationType, () => <String>{});
          extracted[relationType]!.add(name);
        }
      }
    }

    return extracted;
  }

  /// Padrões para detectar auto-apresentação com nome
  static final List<RegExp> nameIntroPatterns = [
    RegExp(r'my name is ([A-Z][a-z]+)', caseSensitive: false),
    RegExp(r"i'm ([A-Z][a-z]+)", caseSensitive: false),
    RegExp(r'call me ([A-Z][a-z]+)', caseSensitive: false),
    RegExp(r"i am ([A-Z][a-z]+)", caseSensitive: false),
    RegExp(r'me chamo ([A-Z][a-z]+)', caseSensitive: false),
    RegExp(r'meu nome é ([A-Z][a-z]+)', caseSensitive: false),
    RegExp(r"je m'appelle ([A-Z][a-z]+)", caseSensitive: false),
    RegExp(r'me llamo ([A-Z][a-z]+)', caseSensitive: false),
  ];

  /// Detecta nome em auto-apresentação
  static String? detectSelfIntroducedName(String text) {
    for (final pattern in nameIntroPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Lista de nomes suspeitos comuns que indicam troca de protagonista
  static final List<String> suspiciousNames = [
    // Português
    'Wanessa', 'Carla', 'Beatriz', 'Fernanda', 'Juliana', 'Mariana',
    'Patrícia', 'Roberta', 'Silvia', 'Tatiana',
    'Carlos', 'Eduardo', 'Fernando', 'Gustavo', 'Henrique',
    'Leonardo', 'Marcelo', 'Rafael', 'Rodrigo', 'Thiago',
    // Inglês
    'Hannah', 'Laura', 'Jessica', 'Sarah', 'Emily', 'Emma',
    'Olivia', 'Sophia', 'Michael', 'David', 'James', 'John', 'Robert',
    // Francês
    'Marie', 'Sophie', 'Camille', 'Léa', 'Pierre', 'Jean', 'Marc',
    // Espanhol
    'María', 'Carmen', 'Juan', 'José', 'Luis',
  ];

  /// Verifica se um nome parece ser nome de pessoa
  static bool looksLikePersonName(String candidate) {
    if (candidate.isEmpty || candidate.length < 2) return false;

    // Palavras comuns que NÃO são nomes
    const nonNames = {
      // Inglês
      'The', 'This', 'That', 'What', 'When', 'Where', 'Why', 'How',
      'But', 'And', 'For', 'Not', 'You', 'All', 'Can', 'Had', 'Her',
      'Was', 'One', 'Our', 'Out', 'Day', 'Get', 'Has', 'Him', 'His',
      'Its', 'Let', 'May', 'New', 'Now', 'Old', 'See', 'Way',
      'Who', 'Did', 'Got', 'Man', 'She', 'Too', 'Two', 'After', 'Before',
      'Chapter', 'Part', 'Section', 'Title', 'Story', 'Book', 'Page',
      'With', 'From', 'Into', 'Just', 'Over', 'Such', 'Take', 'Come',
      'Could', 'Good', 'Know', 'Made', 'Many', 'More', 'Most', 'Much',
      'Must', 'Name', 'Only', 'Other', 'Should', 'Some', 'Than',
      'Their', 'Then', 'There', 'These', 'They', 'Through', 'Time',
      'Very', 'Want', 'Well', 'Were', 'Will', 'Would', 'Your', 'First',
      'Last', 'Long', 'Great', 'Little', 'Never', 'Always', 'Every',
      'Here', 'Between', 'Because', 'Under', 'While', 'About',
      // Português
      'Quando', 'Onde', 'Como', 'Para', 'Depois', 'Antes', 'Durante',
      'Sobre', 'Ainda', 'Aquele', 'Aquela', 'Aquilo', 'Este', 'Esta',
      'Isso', 'Isto', 'Esse', 'Essa', 'Muito', 'Pouco', 'Mais', 'Menos',
      'Cada', 'Todo', 'Toda', 'Algum', 'Alguma', 'Nenhum', 'Nenhuma',
      'Outro', 'Outra', 'Mesmo', 'Mesma', 'Tanto', 'Tanta', 'Certo',
      'Certa', 'Qual', 'Quais', 'Quem', 'Cujo', 'Cuja', 'Capítulo',
      'Parte', 'Seção', 'Título', 'História', 'Livro', 'Página',
      // Francês
      'Chapitre', 'Partie', 'Titre', 'Quand', 'Comment', 'Pourquoi',
      'Après', 'Pendant', 'Chez', 'Dans', 'Pour', 'Avec', 'Sans', 'Sous',
      // Espanhol (apenas únicos)
      'Sección', 'Cuando', 'Cómo', 'Después', 'Hacia', 'Desde', 'Hasta',
    };

    // Começa com maiúscula?
    if (!RegExp(r'^[A-ZÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇ]').hasMatch(candidate)) {
      return false;
    }

    // É muito curto ou muito longo?
    if (candidate.length < 2 || candidate.length > 25) return false;

    // Está na lista de não-nomes?
    if (nonNames.contains(candidate)) return false;

    // Contém caracteres inválidos para nomes?
    if (RegExp(r'[0-9@#$%^&*()+=\[\]{}|\\<>/?~`]').hasMatch(candidate)) {
      return false;
    }

    return true;
  }

  /// Valida se um nome encontrado contradiz protagonista configurado
  static bool validateProtagonistName({
    required String foundName,
    required String configuredProtagonist,
    required int blockNumber,
  }) {
    if (configuredProtagonist.isEmpty) return true;

    // Nome suspeito diferente do protagonista?
    if (suspiciousNames.contains(foundName) &&
        foundName.toLowerCase() != configuredProtagonist.toLowerCase()) {
      if (kDebugMode) {
        debugPrint('⚠️ ALERTA: Nome suspeito "$foundName" encontrado');
        debugPrint('   Protagonista configurado: "$configuredProtagonist"');
        debugPrint('   Bloco: $blockNumber');
      }
      return false;
    }

    return true;
  }
}
