import 'package:flutter/foundation.dart';

import '../../../models/script_config.dart';
import '../utils/character_guidance.dart';
import '../validation/name_validator.dart';

/// 📝 Classe para armazenar uma nota sobre um personagem em um bloco específico
class CharacterNote {
  final int blockNumber;
  final String observation;
  final DateTime timestamp;

  CharacterNote(this.blockNumber, this.observation)
    : timestamp = DateTime.now();

  @override
  String toString() => '[Bloco $blockNumber] $observation';
}

/// 📚 Classe para armazenar o histórico completo de um personagem
class CharacterHistory {
  final String name;
  final List<CharacterNote> timeline = [];

  CharacterHistory(this.name);

  /// Adiciona uma nova observação sobre o personagem
  void addNote(int blockNumber, String observation) {
    if (observation.isEmpty) return;
    timeline.add(CharacterNote(blockNumber, observation));
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

    // Extrair palavras-chave da nova observação
    final newKeywords = _extractRelationshipKeywords(newObservation);

    // Verificar se contradiz alguma nota anterior
    for (final note in timeline) {
      final existingKeywords = _extractRelationshipKeywords(note.observation);

      // Se ambos têm palavras de relacionamento, verificar contradição
      if (newKeywords.isNotEmpty && existingKeywords.isNotEmpty) {
        // Relacionamentos diferentes para o mesmo tipo = contradição
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

    // Padrões de relacionamento
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

        // Mesmo tipo de relacionamento mas com pessoas diferentes = contradição
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
  String? get initialRole {
    return timeline.isEmpty ? null : timeline.first.observation;
  }

  /// Retorna número de aparições do personagem
  int get appearanceCount => timeline.length;
}

/// 🔥 CharacterTracker - Rastreia personagens entre blocos de geração
///
/// Responsabilidades:
/// - Manter nomes confirmados de personagens
/// - Mapear nomes aos seus papéis
/// - Mapear papéis aos nomes (reverso)
/// - Detectar conflitos de nomes/papéis
/// - Rastrear histórico de personagens
/// - Detectar fechamento/resolução de arcos
///
/// Parte da refatoração SOLID do GeminiService v7.6.65
class CharacterTracker {
  final Set<String> _confirmedNames = {};
  // 🔥 Mapear cada nome ao seu papel para prevenir confusão e reuso
  final Map<String, String> _characterRoles = {};
  // 🔗 MAPEAMENTO REVERSO papel → nome (detecta nomes múltiplos por papel)
  final Map<String, String> _roleToName = {};
  // 📚 SISTEMA DE NOTAS: Histórico completo de cada personagem
  final Map<String, CharacterHistory> _characterHistories = {};
  // 🆕 Nome da protagonista detectado automaticamente no Bloco 1
  String? _detectedProtagonistName;
  // 🔄 RASTREAMENTO DE FECHAMENTO DE PERSONAGENS
  final Map<String, bool> _characterResolution = {};

  // 🚫 v7.6.172: BLACKLIST de pronomes comuns (nunca são nomes)
  // Problema: "Her", "He", "She" sendo detectados como nomes → retries
  static const _pronounBlacklist = {
    // Inglês
    'he', 'she', 'her', 'his', 'him', 'they', 'them', 'their',
    'it', 'its', 'i', 'you', 'we', 'us', 'our', 'my', 'your',
    // Português
    'ele', 'ela', 'seu', 'sua', 'dele', 'dela', 'eles', 'elas',
    'seus', 'suas', 'deles', 'delas', 'meu', 'minha', 'você',
    // Espanhol
    'él', 'ella', 'su', 'sus', 'lo', 'la', 'ellos', 'ellas',
    // Francês
    'il', 'elle', 'son', 'sa', 'ses', 'leur', 'leurs', 'ils', 'elles',
  };

  /// 🆕 v7.6.25: Retorna false se nome foi rejeitado (papel duplicado)
  /// 🆕 v7.6.136: Usa NameValidator para evitar falsos positivos
  /// 🆕 v7.6.172: Filtra pronomes comuns (Her, He, She, etc)
  bool addName(String name, {String? role, int? blockNumber}) {
    if (name.isEmpty || name.length <= 2) return true; // Nome vazio não é erro

    // 🚫 v7.6.172: FILTRO DE PRONOMES - ignorar completamente
    if (_pronounBlacklist.contains(name.toLowerCase())) {
      if (kDebugMode) {
        debugPrint('⏭️ v7.6.172: "$name" ignorado (pronome comum, não nome)');
      }
      return true; // Não é erro, apenas ignorar
    }

    // 🆕 v7.6.136: Ignorar FRASES (não são nomes de personagens)
    // Ex: "Mas Mateus", "Com Helena", "Até César" → ignorar
    if (NameValidator.isPhrase(name)) {
      if (kDebugMode) {
        debugPrint('⏭️ v7.6.136: "$name" ignorado (é frase, não nome)');
      }
      return true; // Não é erro, apenas ignorar
    }

    // 🆕 v7.6.136: Ignorar nomes na WHITELIST de compostos
    // Ex: "Futuro Brilhante", "Doutor Álvaro" → não são conflitos
    final nameLower = name.toLowerCase();
    if (NameValidator.compoundWhitelist.contains(nameLower)) {
      if (kDebugMode) {
        debugPrint('⏭️ v7.6.136: "$name" na whitelist de compostos');
      }
      // Continuar adição normal, sem gerar conflito
    }

    // 🆕 v7.6.136: Usar NameValidator.hasNameConflict() em vez de lógica duplicada
    // Esta função já trata prefixos (Doutor, Senhor) e whitelist
    if (NameValidator.hasNameConflict(name, _confirmedNames)) {
      if (kDebugMode) {
        debugPrint('🚨🚨🚨 v7.6.30: CONFLITO DE NOMES DETECTADO! 🚨🚨🚨');
        debugPrint('   ❌ Nome novo: "$name"');
        debugPrint('   ❌ Conflita com nomes existentes');
        debugPrint('   💡 SOLUÇÃO: Use nomes COMPLETAMENTE diferentes');
        debugPrint('   ❌ BLOQUEANDO adição de "$name"!');
        debugPrint('🚨🚨🚨 FIM DO ALERTA 🚨🚨🚨');
      }
      return true; // Bloquear conflito
    }

    // 🔒 VALIDAÇÃO CRÍTICA: Bloquear reuso de nomes
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
      return true; // Nome duplicado, mas não é erro de papel
    }

    // 🚨 v7.6.25: VALIDAÇÃO REVERSA - Um papel pode ter apenas UM nome
    if (role != null && role.isNotEmpty && role != 'indefinido') {
      // Normalizar papel (remover detalhes específicos para comparação)
      final normalizedRole = _normalizeRole(role);

      if (_roleToName.containsKey(normalizedRole)) {
        final existingName = _roleToName[normalizedRole]!;

        if (existingName != name) {
          // 🚨 ERRO CRÍTICO: Mesmo papel com nomes diferentes!
          if (kDebugMode) {
            debugPrint(
              '🚨🚨🚨 ERRO CRÍTICO v7.6.25: MÚLTIPLOS NOMES PARA MESMO PAPEL 🚨🚨🚨',
            );
            debugPrint('   ❌ Papel: "$normalizedRole"');
            debugPrint('   ❌ Nome original: "$existingName"');
            debugPrint('   ❌ Nome novo (CONFLITANTE): "$name"');
            debugPrint(
              '   💡 EXEMPLO DO BUG: "advogado" sendo Martin no bloco 2 e Richard no bloco 7!',
            );
            debugPrint(
              '   ⚠️ BLOQUEANDO adição de "$name" - usar apenas "$existingName"!',
            );
            debugPrint('🚨🚨🚨 FIM DO ALERTA 🚨🚨🚨');
          }
          return false; // ❌ RETORNA FALSE = ERRO DETECTADO
        }
      } else {
        // Primeiro nome para este papel - registrar no mapeamento reverso
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

      // 📚 SISTEMA DE NOTAS: Adicionar ao histórico
      if (blockNumber != null) {
        addNoteToCharacter(name, blockNumber, role);
      }
    }

    return true; // ✅ SUCESSO
  }

  /// 🔧 v7.6.26: Normaliza papel SELETIVAMENTE (evita falsos positivos)
  ///
  /// PAPÉIS FAMILIARES: Mantém completo "mãe de Emily" ≠ "mãe de Michael"
  /// PAPÉIS GENÉRICOS: Normaliza "advogado de Sarah" → "advogado"
  String _normalizeRole(String role) {
    final roleLower = role.toLowerCase().trim();

    // 🔥 v7.6.26: PAPÉIS FAMILIARES - NÃO normalizar (manter contexto familiar)
    final familyRoles = [
      'mãe',
      'pai',
      'filho',
      'filha',
      'irmão',
      'irmã',
      'avô',
      'avó',
      'tio',
      'tia',
      'primo',
      'prima',
      'sogro',
      'sogra',
      'cunhado',
      'cunhada',
      'mother',
      'father',
      'son',
      'daughter',
      'brother',
      'sister',
      'grandfather',
      'grandmother',
      'uncle',
      'aunt',
      'cousin',
      'father-in-law',
      'mother-in-law',
      'brother-in-law',
      'sister-in-law',
      'mère',
      'père',
      'fils',
      'fille',
      'frère',
      'sœur',
      'grand-père',
      'grand-mère',
      'oncle',
      'tante',
      'cousin',
      'cousine',
    ];

    // Verificar se é papel familiar
    for (final familyRole in familyRoles) {
      if (roleLower.contains(familyRole)) {
        return roleLower; // Manter completo
      }
    }

    // 🔧 PAPÉIS GENÉRICOS: Normalizar
    final normalized = roleLower
        .replaceAll(RegExp(r'\s+de\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇa-záàâãéêíóôõúç]+.*$'), '')
        .trim();

    return normalized;
  }

  /// 📝 Adiciona uma nota sobre um personagem
  void addNoteToCharacter(String name, int blockNumber, String observation) {
    if (!_characterHistories.containsKey(name)) {
      _characterHistories[name] = CharacterHistory(name);
    }

    // Verificar se a nova observação contradiz o histórico
    final history = _characterHistories[name]!;
    if (history.contradicts(observation)) {
      if (kDebugMode) {
        debugPrint('🚨🚨🚨 CONTRADIÇÃO NO HISTÓRICO DE "$name" 🚨🚨🚨');
        debugPrint('   📚 Histórico existente:');
        debugPrint('   ${history.getFullHistory()}');
        debugPrint('   ⚠️ Nova observação contraditória: $observation');
        debugPrint('   💡 Esta observação NÃO será adicionada!');
        debugPrint('🚨🚨🚨 FIM DO ALERTA 🚨🚨🚨');
      }
      return; // Bloqueia adição de observação contraditória
    }

    history.addNote(blockNumber, observation);
  }

  /// 📖 Obtém o histórico completo de um personagem
  String? getCharacterHistory(String name) {
    final history = _characterHistories[name];
    return history?.getFullHistory();
  }

  /// 📊 Obtém estatísticas de um personagem
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

  void addNames(List<String> names) {
    for (final name in names) {
      addName(name);
    }
  }

  Set<String> get confirmedNames => Set.unmodifiable(_confirmedNames);

  bool hasName(String name) => _confirmedNames.contains(name);

  String? getRole(String name) => _characterRoles[name];

  /// 🆕 v7.6.35: Expõe o mapa roleToName para o PostGenerationFixer
  Map<String, String> get roleToNameMap => Map.unmodifiable(_roleToName);

  /// 🔍 v1.7: Obtém o nome associado a um papel (mapeamento reverso)
  String? getNameForRole(String role) {
    final normalizedRole = _normalizeRole(role);
    return _roleToName[normalizedRole];
  }

  /// 🔍 v1.7: Verifica se um papel já tem nome definido
  bool roleHasName(String role) {
    final normalizedRole = _normalizeRole(role);
    return _roleToName.containsKey(normalizedRole);
  }

  // 🔥 v7.6.28: Obter mapeamento completo de personagens + LISTA DE NOMES PROIBIDOS
  String getCharacterMapping() {
    if (_characterRoles.isEmpty && _characterHistories.isEmpty) return '';

    final buffer = StringBuffer('\n🎭 PERSONAGENS JÁ DEFINIDOS:\n');

    // 🚨 v7.6.28: LISTA CRÍTICA DE NOMES JÁ USADOS (NUNCA REUTILIZAR!)
    if (_confirmedNames.isNotEmpty) {
      buffer.writeln('\n🚫 NOMES JÁ USADOS - NUNCA REUTILIZE ESTES NOMES:');
      final namesList = _confirmedNames.toList()..sort();
      for (final name in namesList) {
        final role = _characterRoles[name] ?? 'indefinido';
        buffer.writeln('   ❌ "$name" (já é: $role)');
      }
      buffer.writeln('\n⚠️ REGRA ABSOLUTA: Cada nome deve ser ÚNICO!');
      buffer.writeln('⚠️ Se precisa de novo personagem, use NOME DIFERENTE!');
      buffer.writeln(
        '⚠️ NUNCA use "Mark", "Charles", etc se já estão acima!\n',
      );
    }

    // v1.7: Mostrar mapeamento reverso (papel → nome) para reforçar consistência
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

    // Para cada personagem, mostrar histórico completo se disponível
    for (final name in _confirmedNames) {
      final history = _characterHistories[name];

      if (history != null && history.timeline.isNotEmpty) {
        // Mostrar histórico completo
        buffer.writeln('\n👤 $name:');
        buffer.writeln('   ${history.getFullHistory()}');
        buffer.writeln(
          '   ⚠️ NUNCA mude este personagem! Use outro nome para novos personagens.',
        );
      } else {
        // Mostrar apenas papel básico
        final role = _characterRoles[name] ?? 'personagem';
        buffer.writeln('   "$name" = $role');
      }
    }

    return buffer.toString();
  }

  /// 🆕 v7.6.17: Registra o nome da protagonista detectado no Bloco 1
  void setProtagonistName(String name) {
    if (_detectedProtagonistName == null) {
      _detectedProtagonistName = name.trim();
      if (kDebugMode) {
        debugPrint('✅ Protagonista detectada: "$_detectedProtagonistName"');
      }
    }
  }

  /// 🆕 v7.6.17: Retorna o nome da protagonista registrado
  String? getProtagonistName() => _detectedProtagonistName;

  /// Marca um personagem como tendo recebido fechamento/resolução
  void markCharacterAsResolved(String name) {
    if (_confirmedNames.contains(name)) {
      _characterResolution[name] = true;
      if (kDebugMode) {
        debugPrint('✅ PERSONAGEM RESOLVIDO: $name');
      }
    }
  }

  /// Detecta automaticamente personagens que receberam fechamento no texto
  void detectResolutionInText(String text, int blockNumber) {
    // Padrões que indicam fechamento de personagem
    final resolutionPatterns = [
      // Conclusão física/localização
      RegExp(
        r'([A-Z][a-z]+)\s+(?:foi embora|left|partiu|morreu|died|desapareceu|vanished)',
        caseSensitive: false,
      ),
      RegExp(
        r'([A-Z][a-z]+)\s+(?:nunca mais|never again|jamais)',
        caseSensitive: false,
      ),

      // Justiça/vingança
      RegExp(
        r'([A-Z][a-z]+)\s+(?:foi preso|was arrested|foi condenado|was convicted)',
        caseSensitive: false,
      ),
      RegExp(
        r'([A-Z][a-z]+)\s+(?:confessou|confessed|admitiu|admitted)',
        caseSensitive: false,
      ),

      // Reconciliação/paz
      RegExp(
        r'([A-Z][a-z]+)\s+(?:me perdoou|forgave me|fez as pazes|made peace)',
        caseSensitive: false,
      ),
      RegExp(
        r'([A-Z][a-z]+)\s+(?:finalmente|finally|por fim|at last)\s+(?:tinha|had|conseguiu|achieved)',
        caseSensitive: false,
      ),

      // Estado emocional final
      RegExp(
        r'([A-Z][a-z]+)\s+(?:estava feliz|was happy|encontrou paz|found peace)',
        caseSensitive: false,
      ),
      RegExp(
        r'([A-Z][a-z]+)\s+(?:seguiu em frente|moved on|superou|overcame)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in resolutionPatterns) {
      for (final match in pattern.allMatches(text)) {
        final name = match.group(1);
        if (name != null && _confirmedNames.contains(name)) {
          markCharacterAsResolved(name);
          addNoteToCharacter(name, blockNumber, 'RESOLUÇÃO: ${match.group(0)}');
        }
      }
    }
  }

  /// Retorna lista de personagens sem fechamento
  List<String> getUnresolvedCharacters() {
    final unresolved = <String>[];

    for (final name in _confirmedNames) {
      // Ignorar protagonista (sempre tem fechamento implícito)
      if (name == _detectedProtagonistName) continue;

      final role = _characterRoles[name]?.toLowerCase() ?? '';

      // 🐛 FIX v7.6.24: Ignorar personagens SEM histórico OU muito secundários (≤1 aparição)
      final history = _characterHistories[name];
      if (history == null || history.appearanceCount <= 1) continue;

      // Personagens importantes que precisam de fechamento:
      // - Família próxima (pai, mãe, irmão, filho, cônjuge)
      // - Antagonistas/vilões
      // - Ajudantes/aliados que apareceram múltiplas vezes (3+)
      final needsClosure =
          role.contains('marido') ||
          role.contains('esposa') ||
          role.contains('pai') ||
          role.contains('mãe') ||
          role.contains('filho') ||
          role.contains('filha') ||
          role.contains('irmão') ||
          role.contains('irmã') ||
          role.contains('husband') ||
          role.contains('wife') ||
          role.contains('father') ||
          role.contains('mother') ||
          role.contains('son') ||
          role.contains('daughter') ||
          role.contains('brother') ||
          role.contains('sister') ||
          role.contains('amigo') ||
          role.contains('friend') ||
          role.contains('advogad') ||
          role.contains('lawyer') ||
          role.contains('sócio') ||
          role.contains('partner') ||
          history.appearanceCount >= 3; // history guaranteed non-null here

      if (needsClosure && !(_characterResolution[name] ?? false)) {
        unresolved.add(name);
      }
    }

    return unresolved;
  }

  /// Calcula taxa de fechamento de personagens (0.0 a 1.0)
  double getClosureRate() {
    final important = _confirmedNames.where((name) {
      if (name == _detectedProtagonistName) return false;
      final history = _characterHistories[name];
      // 🐛 FIX v7.6.24: Excluir personagens SEM histórico OU com 1 aparição
      if (history == null || history.appearanceCount <= 1) return false;
      return true;
    }).toList();

    if (important.isEmpty) return 1.0;

    final resolved = important
        .where((name) => _characterResolution[name] ?? false)
        .length;
    return resolved / important.length;
  }

  void clear() {
    _confirmedNames.clear();
    _detectedProtagonistName = null;
    _characterRoles.clear();
    _roleToName.clear();
    _characterHistories.clear();
    _characterResolution.clear();
  }

  /// 🔧 SOLID v7.6.81: Inicializa tracker com nomes do config
  ///
  /// Carrega nomes do protagonista, secundário e extrai do título.
  /// Atribui papéis apropriados a cada nome.
  static void bootstrap(CharacterTracker tracker, ScriptConfig config) {
    final names = <String>{};
    final fromProtagonist = <String>{};
    final fromSecondary = <String>{};
    final fromContext = <String>{};
    final fromTitle = <String>{};

    if (config.protagonistName.trim().isNotEmpty) {
      final name = config.protagonistName.trim();
      names.add(name);
      fromProtagonist.add(name);
    }
    if (config.secondaryCharacterName.trim().isNotEmpty) {
      final name = config.secondaryCharacterName.trim();
      names.add(name);
      fromSecondary.add(name);
    }

    // Context removido - não há mais nomes para extrair do contexto manual

    // 🆕 NOVO: Extrair gênero e relações de personagens do título
    final titleNames = CharacterGuidanceBuilder.extractHintsFromTitle(
      config.title,
      '',
    );
    names.addAll(titleNames);
    fromTitle.addAll(titleNames);

    // ✅ CORREÇÃO BUG ALBERTO: Adicionar nomes COM papéis ao tracker
    for (final name in names) {
      // Context removido - papel não pode mais ser extraído do contexto manual

      // Para protagonista e secundário, usar papéis explícitos
      if (fromProtagonist.contains(name)) {
        tracker.addName(name, role: 'protagonista');
      } else if (fromSecondary.contains(name)) {
        tracker.addName(name, role: 'secundário');
      } else {
        tracker.addName(name, role: 'indefinido');
      }
    }

    // 📝 LOG DETALHADO: Mostrar origem de cada nome carregado
    if (kDebugMode && tracker.confirmedNames.isNotEmpty) {
      debugPrint(
        '🔰 TRACKER BOOTSTRAP - ${tracker.confirmedNames.length} nome(s) carregado(s):',
      );
      if (fromProtagonist.isNotEmpty) {
        debugPrint('   🎭 Protagonista: ${fromProtagonist.join(", ")}');
      }
      if (fromSecondary.isNotEmpty) {
        debugPrint('   🎬 Secundário: ${fromSecondary.join(", ")}');
      }
      if (fromContext.isNotEmpty) {
        debugPrint('   📖 Do contexto: ${fromContext.join(", ")}');
      }
      if (fromTitle.isNotEmpty) {
        debugPrint('   📌 Do título: ${fromTitle.join(", ")}');
      }
      debugPrint('   ✅ Total: ${tracker.confirmedNames.join(", ")}');
    } else if (kDebugMode) {
      debugPrint(
        '🔰 TRACKER BOOTSTRAP: Nenhum nome inicial fornecido (será detectado no bloco 1)',
      );
    }
  }
}
