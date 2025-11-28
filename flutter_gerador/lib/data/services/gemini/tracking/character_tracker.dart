import 'package:flutter/foundation.dart';

/// 📝 Classe para armazenar uma nota sobre um personagem em um bloco específico
class CharacterTrackingNote {
  final int blockNumber;
  final String observation;
  final DateTime timestamp;

  CharacterTrackingNote(this.blockNumber, this.observation)
    : timestamp = DateTime.now();

  @override
  String toString() => '[Bloco $blockNumber] $observation';
}

/// 📚 Classe para armazenar o histórico completo de um personagem
class CharacterHistory {
  final String name;
  final List<CharacterTrackingNote> timeline = [];

  CharacterHistory(this.name);

  /// Adiciona uma nova observação sobre o personagem
  void addNote(int blockNumber, String observation) {
    if (observation.isEmpty) return;
    timeline.add(CharacterTrackingNote(blockNumber, observation));
    if (kDebugMode) {
      debugPrint('📝 Nota adicionada: "$name" → [B$blockNumber] $observation');
    }
  }

  /// Retorna o histórico completo formatado
  String getFullHistory() {
    if (timeline.isEmpty) return '';
    return timeline.map((e) => e.toString()).join('\n   ');
  }

  /// Verifica se uma nova observação contradiz o histórico
  bool contradicts(String newObservation) {
    if (timeline.isEmpty) return false;

    final newKeywords = _extractRelationshipKeywords(newObservation);

    for (final note in timeline) {
      final existingKeywords = _extractRelationshipKeywords(note.observation);

      if (newKeywords.isNotEmpty && existingKeywords.isNotEmpty) {
        if (_areContradictoryRelationships(existingKeywords, newKeywords)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Extrai palavras-chave de relacionamento de uma observação
  Set<String> _extractRelationshipKeywords(String text) {
    final keywords = <String>{};
    final lowerText = text.toLowerCase();

    final patterns = {
      'irmã': r'irmã\s+de\s+(\w+)',
      'irmão': r'irmão\s+de\s+(\w+)',
      'filho': r'filh[oa]\s+de\s+(\w+)',
      'pai': r'pai\s+de\s+(\w+)',
      'mãe': r'mãe\s+de\s+(\w+)',
      'esposa': r'esposa\s+de\s+(\w+)',
      'marido': r'marido\s+de\s+(\w+)',
      'neto': r'net[oa]\s+de\s+(\w+)',
      'tio': r'ti[oa]\s+de\s+(\w+)',
      'primo': r'prim[oa]\s+de\s+(\w+)',
      'avô': r'av[ôó]\s+de\s+(\w+)',
    };

    for (final entry in patterns.entries) {
      final regex = RegExp(entry.value, caseSensitive: false);
      final match = regex.firstMatch(lowerText);
      if (match != null) {
        keywords.add('${entry.key}_${match.group(1)}');
      }
    }

    return keywords;
  }

  /// Verifica se dois conjuntos de relacionamentos são contraditórios
  bool _areContradictoryRelationships(Set<String> existing, Set<String> new_) {
    for (final existingRel in existing) {
      final existingType = existingRel.split('_')[0];

      for (final newRel in new_) {
        final newType = newRel.split('_')[0];

        if (existingType == newType && existingRel != newRel) {
          if (kDebugMode) {
            debugPrint('🚨 CONTRADIÇÃO DETECTADA:');
            debugPrint('   Existente: $existingRel');
            debugPrint('   Nova: $newRel');
          }
          return true;
        }
      }
    }

    return false;
  }

  /// Retorna a primeira nota (papel inicial do personagem)
  String? get initialRole =>
      timeline.isEmpty ? null : timeline.first.observation;

  /// Retorna número de aparições do personagem
  int get appearanceCount => timeline.length;
}

/// 📚 Rastreador de personagens - mantém consistência de nomes entre blocos
class CharacterTracker {
  final Set<String> _confirmedNames = {};
  final Map<String, String> _characterRoles = {};
  final Map<String, String> _roleToName = {};
  final Map<String, CharacterHistory> _characterHistories = {};

  void addName(String name, {String? role, int? blockNumber}) {
    if (name.isEmpty || name.length <= 2) return;

    // 🔒 VALIDAÇÃO: Bloquear reuso de nomes
    if (_confirmedNames.contains(name)) {
      if (kDebugMode) {
        final existingRole = _characterRoles[name] ?? 'desconhecido';
        debugPrint(
          '❌ BLOQUEIO DE REUSO: "$name" já usado como "$existingRole"!',
        );
        if (role != null && role != existingRole) {
          debugPrint(
            '   ⚠️ Tentativa de reusar "$name" como "$role" → REJEITADO!',
          );
        }
      }
      return;
    }

    // 🚨 VALIDAÇÃO REVERSA: Um papel pode ter apenas UM nome
    if (role != null && role.isNotEmpty && role != 'indefinido') {
      final normalizedRole = _normalizeRole(role);

      if (_roleToName.containsKey(normalizedRole)) {
        final existingName = _roleToName[normalizedRole]!;

        if (existingName != name) {
          if (kDebugMode) {
            debugPrint('🚨🚨🚨 ERRO: MÚLTIPLOS NOMES PARA MESMO PAPEL 🚨🚨🚨');
            debugPrint('   ❌ Papel: "$normalizedRole"');
            debugPrint('   ❌ Nome original: "$existingName"');
            debugPrint('   ❌ Nome novo (CONFLITANTE): "$name"');
            debugPrint('   ⚠️ BLOQUEANDO adição de "$name"!');
          }
          return;
        }
      } else {
        _roleToName[normalizedRole] = name;
        if (kDebugMode) {
          debugPrint('🔗 MAPEAMENTO REVERSO: "$normalizedRole" → "$name"');
        }
      }
    }

    _confirmedNames.add(name);
    if (role != null && role.isNotEmpty) {
      _characterRoles[name] = role;
      if (kDebugMode) {
        debugPrint('✅ MAPEAMENTO: "$name" = "$role"');
      }

      if (blockNumber != null) {
        addNoteToCharacter(name, blockNumber, role);
      }
    }
  }

  /// Normaliza papel para comparação (remove detalhes específicos)
  String _normalizeRole(String role) {
    final normalized = role.replaceAll(
      RegExp(r'\s+de\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+.*$'),
      '',
    );
    return normalized.trim().toLowerCase();
  }

  /// Adiciona uma nota sobre um personagem
  void addNoteToCharacter(String name, int blockNumber, String observation) {
    if (!_characterHistories.containsKey(name)) {
      _characterHistories[name] = CharacterHistory(name);
    }

    final history = _characterHistories[name]!;
    if (history.contradicts(observation)) {
      if (kDebugMode) {
        debugPrint('🚨🚨🚨 CONTRADIÇÃO NO HISTÓRICO DE "$name" 🚨🚨🚨');
        debugPrint(
          '   📚 Histórico existente:\n   ${history.getFullHistory()}',
        );
        debugPrint('   ⚠️ Nova observação contraditória: $observation');
        debugPrint('   💡 Esta observação NÃO será adicionada!');
      }
      return;
    }

    history.addNote(blockNumber, observation);
  }

  void addNames(List<String> names) {
    for (final name in names) {
      addName(name);
    }
  }

  Set<String> get confirmedNames => Set.unmodifiable(_confirmedNames);
  bool hasName(String name) => _confirmedNames.contains(name);
  String? getRole(String name) => _characterRoles[name];
  String? getNameForRole(String role) => _roleToName[_normalizeRole(role)];
  bool roleHasName(String role) =>
      _roleToName.containsKey(_normalizeRole(role));

  /// Obtém o histórico completo de um personagem
  String? getCharacterHistory(String name) =>
      _characterHistories[name]?.getFullHistory();

  /// Obtém estatísticas de um personagem
  Map<String, dynamic> getCharacterStats(String name) {
    final history = _characterHistories[name];
    if (history == null) return {};

    return {
      'name': name,
      'initial_role': history.initialRole,
      'appearances': history.appearanceCount,
      'full_history': history.getFullHistory(),
    };
  }

  /// Obter mapeamento completo de personagens
  String getCharacterMapping() {
    if (_characterRoles.isEmpty && _characterHistories.isEmpty) return '';

    final buffer = StringBuffer('\n🎭 PERSONAGENS JÁ DEFINIDOS:\n');

    if (_roleToName.isNotEmpty) {
      buffer.writeln(
        '\n📋 MAPEAMENTO PAPEL → NOME (use SEMPRE os mesmos nomes):',
      );
      for (final entry in _roleToName.entries) {
        buffer.writeln(
          '   "${entry.key}" = "${entry.value}" ⚠️ NUNCA mude este nome!',
        );
      }
      buffer.writeln();
    }

    for (final name in _confirmedNames) {
      final history = _characterHistories[name];

      if (history != null && history.timeline.isNotEmpty) {
        buffer.writeln('\n👤 $name:');
        buffer.writeln('   ${history.getFullHistory()}');
        buffer.writeln(
          '   ⚠️ NUNCA mude este personagem! Use outro nome para novos.',
        );
      } else {
        final role = _characterRoles[name] ?? 'personagem';
        buffer.writeln('   "$name" = $role');
      }
    }

    return buffer.toString();
  }

  void clear() {
    _confirmedNames.clear();
    _characterRoles.clear();
    _roleToName.clear();
    _characterHistories.clear();
  }
}
