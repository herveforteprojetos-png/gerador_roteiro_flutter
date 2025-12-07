// 🏗️ v7.6.67: Módulo extraído de gemini_service.dart
// Padrões de papéis/relacionamentos para identificação de personagens
// Parte da arquitetura SOLID - Single Responsibility Principle

/// 🎭 Padrões de papéis para identificação de personagens em texto
/// Detecta relacionamentos familiares e sociais mencionados na narrativa
class RolePatterns {
  // ═══════════════════════════════════════════════════════════════════════════
  // PAPÉIS EM PORTUGUÊS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gera padrões de papéis em Português para um nome específico
  static Map<String, RegExp> getPortugueseRolePatterns(String name) {
    return {
      'marido': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:marido|esposo)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'esposa': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:esposa|mulher)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'pai': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Pp]ai(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'mãe': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Mm]ãe(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'filho': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Ff]ilho(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'filha': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Ff]ilha(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'irmão': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:irmão|irmao)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'irmã': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:irmã|irma)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'sogro': RegExp(
        r'(?:meu|seu|nosso|o)\s+sogro(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'sogra': RegExp(
        r'(?:minha|sua|nossa|a)\s+sogra(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'cunhado': RegExp(
        r'(?:meu|seu|nosso|o)\s+cunhado(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'cunhada': RegExp(
        r'(?:minha|sua|nossa|a)\s+cunhada(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'nora': RegExp(
        r'(?:minha|sua|nossa|a)\s+nora(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'genro': RegExp(
        r'(?:meu|seu|nosso|o)\s+genro(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'amigo': RegExp(
        r'(?:meu|seu|nosso|o)\s+amigo(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'amiga': RegExp(
        r'(?:minha|sua|nossa|a)\s+amiga(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'vizinho': RegExp(
        r'(?:o|um)\s+vizinho(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'vizinha': RegExp(
        r'(?:a|uma)\s+vizinha(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'tio': RegExp(
        r'(?:meu|seu|o)\s+[Tt]io(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'tia': RegExp(
        r'(?:minha|sua|a)\s+[Tt]ia(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'avô': RegExp(
        r'(?:meu|seu|o)\s+avô(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'avó': RegExp(
        r'(?:minha|sua|a)\s+avó(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'neto': RegExp(
        r'(?:meu|seu|o)\s+neto(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'neta': RegExp(
        r'(?:minha|sua|a)\s+neta(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'primo': RegExp(
        r'(?:meu|seu|o)\s+primo(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'prima': RegExp(
        r'(?:minha|sua|a)\s+prima(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'namorado': RegExp(
        r'(?:meu|seu|o)\s+namorado(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'namorada': RegExp(
        r'(?:minha|sua|a)\s+namorada(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'noivo': RegExp(
        r'(?:meu|seu|o)\s+noivo(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'noiva': RegExp(
        r'(?:minha|sua|a)\s+noiva(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAPÉIS EM INGLÊS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gera padrões de papéis em Inglês para um nome específico
  static Map<String, RegExp> getEnglishRolePatterns(String name) {
    return {
      'father': RegExp(
        r'(?:my|his|her|our|the)\s+(?:father|dad)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'mother': RegExp(
        r'(?:my|his|her|our|the)\s+(?:mother|mom|mum)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'sister': RegExp(
        r'(?:my|his|her|our|the)\s+sister(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'brother': RegExp(
        r'(?:my|his|her|our|the)\s+brother(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'husband': RegExp(
        r'(?:my|her|our|the)\s+husband(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'wife': RegExp(
        r'(?:my|his|our|the)\s+wife(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'boyfriend': RegExp(
        r'(?:my|her|the)\s+(?:boyfriend|fiancé)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'girlfriend': RegExp(
        r'(?:my|his|the)\s+(?:girlfriend|fiancée)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'uncle': RegExp(
        r'(?:my|his|her|our|the)\s+uncle(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'aunt': RegExp(
        r'(?:my|his|her|our|the)\s+aunt(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'grandfather': RegExp(
        r'(?:my|his|her|our|the)\s+(?:grandfather|grandpa)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'grandmother': RegExp(
        r'(?:my|his|her|our|the)\s+(?:grandmother|grandma)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'lawyer': RegExp(
        r'(?:my|his|her|our|the|a)\s+(?:lawyer|attorney)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'father-in-law': RegExp(
        r'(?:my|his|her|our|the)\s+father-in-law(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'mother-in-law': RegExp(
        r'(?:my|his|her|our|the)\s+mother-in-law(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'son': RegExp(
        r'(?:my|his|her|our|the)\s+son(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'daughter': RegExp(
        r'(?:my|his|her|our|the)\s+daughter(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'friend': RegExp(
        r'(?:my|his|her|our|a)\s+(?:friend|best friend)(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'cousin': RegExp(
        r'(?:my|his|her|our|the)\s+cousin(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'nephew': RegExp(
        r'(?:my|his|her|our|the)\s+nephew(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'niece': RegExp(
        r'(?:my|his|her|our|the)\s+niece(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'boss': RegExp(
        r'(?:my|his|her|our|the)\s+boss(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'colleague': RegExp(
        r'(?:my|his|her|our|a)\s+colleague(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
      'neighbor': RegExp(
        r'(?:my|his|her|our|the|a)\s+neighbor(?:[^.]{0,30}\b' +
            name +
            r'\b|(?:,)?\s+' +
            name +
            r')',
        caseSensitive: false,
      ),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODO PRINCIPAL - EXTRAÇÃO DE PAPEL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extrai o papel/relacionamento de um nome em um texto
  /// Retorna o primeiro papel encontrado ou null se não detectar
  static String? extractRoleForName(String name, String text) {
    // Tentar padrões em Português primeiro
    final ptPatterns = getPortugueseRolePatterns(name);
    for (final entry in ptPatterns.entries) {
      if (entry.value.hasMatch(text)) {
        return entry.key;
      }
    }

    // Tentar padrões em Inglês
    final enPatterns = getEnglishRolePatterns(name);
    for (final entry in enPatterns.entries) {
      if (entry.value.hasMatch(text)) {
        return entry.key;
      }
    }

    return null; // Nenhum papel detectado
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAPEAMENTO DE PAPÉIS EQUIVALENTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mapeia papéis em inglês para português para comparação
  static const Map<String, String> englishToPortuguese = {
    'father': 'pai',
    'mother': 'mãe',
    'son': 'filho',
    'daughter': 'filha',
    'brother': 'irmão',
    'sister': 'irmã',
    'husband': 'marido',
    'wife': 'esposa',
    'boyfriend': 'namorado',
    'girlfriend': 'namorada',
    'uncle': 'tio',
    'aunt': 'tia',
    'grandfather': 'avô',
    'grandmother': 'avó',
    'grandson': 'neto',
    'granddaughter': 'neta',
    'cousin': 'primo',
    'nephew': 'sobrinho',
    'niece': 'sobrinha',
    'father-in-law': 'sogro',
    'mother-in-law': 'sogra',
    'brother-in-law': 'cunhado',
    'sister-in-law': 'cunhada',
    'son-in-law': 'genro',
    'daughter-in-law': 'nora',
    'friend': 'amigo',
    'neighbor': 'vizinho',
    'boss': 'chefe',
    'colleague': 'colega',
    'lawyer': 'advogado',
  };

  /// Normaliza um papel para comparação (converte EN → PT)
  static String normalizeRole(String role) {
    return englishToPortuguese[role.toLowerCase()] ?? role.toLowerCase();
  }

  /// Verifica se dois papéis são equivalentes
  static bool areRolesEquivalent(String role1, String role2) {
    return normalizeRole(role1) == normalizeRole(role2);
  }
}
