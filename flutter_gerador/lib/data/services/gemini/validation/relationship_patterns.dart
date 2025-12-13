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
    'marido': RegExp(r'meu marido(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
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
    'brother': RegExp(
      r'my brother(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
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
    'hermano': RegExp(
      r'mi hermano(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
    'hermana': RegExp(
      r'mi hermana(?:,)?\s+([A-Z][a-z]+)',
      caseSensitive: false,
    ),
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
  // PADRÕES DE RELACIONAMENTO - ALEMÃO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Alemão
  static final Map<String, RegExp> germanRelations = {
    'ehemann': RegExp(r'mein Ehemann(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'ehefrau': RegExp(r'meine Ehefrau(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'vater': RegExp(r'mein Vater(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'mutter': RegExp(r'meine Mutter(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'bruder': RegExp(r'mein Bruder(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'schwester': RegExp(r'meine Schwester(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'sohn': RegExp(r'mein Sohn(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'tochter': RegExp(r'meine Tochter(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - ITALIANO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Italiano
  static final Map<String, RegExp> italianRelations = {
    'marito': RegExp(r'mio marito(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'moglie': RegExp(r'mia moglie(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'padre': RegExp(r'mio padre(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'madre': RegExp(r'mia madre(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'fratello': RegExp(r'mio fratello(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'sorella': RegExp(r'mia sorella(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'figlio': RegExp(r'mio figlio(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'figlia': RegExp(r'mia figlia(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - POLONÊS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Polonês
  static final Map<String, RegExp> polishRelations = {
    'mąż': RegExp(r'mój mąż(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'żona': RegExp(r'moja żona(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'ojciec': RegExp(r'mój ojciec(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'matka': RegExp(r'moja matka(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'brat': RegExp(r'mój brat(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'siostra': RegExp(r'moja siostra(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'syn': RegExp(r'mój syn(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'córka': RegExp(r'moja córka(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - BÚLGARO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Búlgaro
  static final Map<String, RegExp> bulgarianRelations = {
    'съпруг': RegExp(r'моят съпруг(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'съпруга': RegExp(r'моята съпруга(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'баща': RegExp(r'моят баща(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'майка': RegExp(r'моята майка(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'брат': RegExp(r'моят брат(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'сестра': RegExp(r'моята сестра(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'син': RegExp(r'моят син(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'дъщеря': RegExp(r'моята дъщеря(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - RUSSO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Russo
  static final Map<String, RegExp> russianRelations = {
    'муж': RegExp(r'мой муж(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'жена': RegExp(r'моя жена(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'отец': RegExp(r'мой отец(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'мать': RegExp(r'моя мать(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'брат': RegExp(r'мой брат(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'сестра': RegExp(r'моя сестра(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'сын': RegExp(r'мой сын(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
    'дочь': RegExp(r'моя дочь(?:,)?\s+([А-Я][а-я]+)', caseSensitive: false),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - COREANO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Coreano
  static final Map<String, RegExp> koreanRelations = {
    '남편': RegExp(r'제 남편(?:,)?\s+([가-힣]+)', caseSensitive: false),
    '아내': RegExp(r'제 아내(?:,)?\s+([가-힣]+)', caseSensitive: false),
    '아버지': RegExp(r'제 아버지(?:,)?\s+([가-힣]+)', caseSensitive: false),
    '어머니': RegExp(r'제 어머니(?:,)?\s+([가-힣]+)', caseSensitive: false),
    '형': RegExp(r'제 형(?:,)?\s+([가-힣]+)', caseSensitive: false),
    '누나': RegExp(r'제 누나(?:,)?\s+([가-힣]+)', caseSensitive: false),
    '아들': RegExp(r'제 아들(?:,)?\s+([가-힣]+)', caseSensitive: false),
    '딸': RegExp(r'제 딸(?:,)?\s+([가-힣]+)', caseSensitive: false),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - TURCO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Turco
  static final Map<String, RegExp> turkishRelations = {
    'kocam': RegExp(r'benim kocam(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'eşim': RegExp(r'benim eşim(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'babam': RegExp(r'benim babam(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'annem': RegExp(r'benim annem(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'kardeşim': RegExp(r'benim kardeşim(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'oğlum': RegExp(r'benim oğlum(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'kızım': RegExp(r'benim kızım(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - ROMENO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Romeno
  static final Map<String, RegExp> romanianRelations = {
    'soț': RegExp(r'soțul meu(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'soție': RegExp(r'soția mea(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'tată': RegExp(r'tatăl meu(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'mamă': RegExp(r'mama mea(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'frate': RegExp(r'fratele meu(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'soră': RegExp(r'sora mea(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'fiu': RegExp(r'fiul meu(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'fiică': RegExp(r'fiica mea(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PADRÕES DE RELACIONAMENTO - CROATA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padrões de relacionamentos familiares em Croata
  static final Map<String, RegExp> croatianRelations = {
    'muž': RegExp(r'moj muž(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'žena': RegExp(r'moja žena(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'otac': RegExp(r'moj otac(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'majka': RegExp(r'moja majka(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'brat': RegExp(r'moj brat(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'sestra': RegExp(r'moja sestra(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'sin': RegExp(r'moj sin(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
    'kći': RegExp(r'moja kći(?:,)?\s+([A-Z][a-z]+)', caseSensitive: false),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS UTILITÁRIOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtém todos os padrões de relacionamento para um idioma
  static Map<String, RegExp> getRelationsForLanguage(String language) {
    final normalized = language.toLowerCase().trim();

    if (normalized.contains('ingl') ||
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

    if (normalized.contains('alem') ||
        normalized.contains('german') ||
        normalized == 'de') {
      return germanRelations;
    }

    if (normalized.contains('italia') ||
        normalized.contains('italian') ||
        normalized == 'it') {
      return italianRelations;
    }

    if (normalized.contains('polon') ||
        normalized.contains('polish') ||
        normalized == 'pl') {
      return polishRelations;
    }

    if (normalized.contains('búlg') ||
        normalized.contains('bulg') ||
        normalized == 'bg') {
      return bulgarianRelations;
    }

    if (normalized.contains('russo') ||
        normalized.contains('russian') ||
        normalized == 'ru') {
      return russianRelations;
    }

    if (normalized.contains('core') ||
        normalized.contains('korean') ||
        normalized == 'ko') {
      return koreanRelations;
    }

    if (normalized.contains('turc') ||
        normalized.contains('turk') ||
        normalized == 'tr') {
      return turkishRelations;
    }

    if (normalized.contains('romen') ||
        normalized.contains('roman') ||
        normalized == 'ro') {
      return romanianRelations;
    }

    if (normalized.contains('croat') ||
        normalized.contains('hrvat') ||
        normalized == 'hr') {
      return croatianRelations;
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

  /// Obtém todos os padrões combinados (PT, EN, FR, ES)
  /// Usado para validação multi-idioma
  static Map<String, RegExp> get allRelationPatterns {
    return {
      ...portugueseRelations,
      // Inglês com sufixo _en para evitar colisão
      ...englishRelations.map((k, v) => MapEntry('${k}_en', v)),
      // Francês com sufixo _fr
      ...frenchRelations.map((k, v) => MapEntry('${k}_fr', v)),
      // Espanhol com sufixo _es
      ...spanishRelations.map((k, v) => MapEntry('${k}_es', v)),
      // Padrão de casamento (multi-idioma)
      'married_to': RegExp(
        r'([A-Z][a-z]+)\s+(?:casou com|married|se casou com)\s+([A-Z][a-z]+)',
        caseSensitive: false,
      ),
    };
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
