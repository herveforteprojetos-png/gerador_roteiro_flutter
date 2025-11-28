/// Sistema de Regras de Personagens
/// Gerencia rastreamento de nomes, validações de personagens e controle de tracker
library;

import 'package:flutter/foundation.dart';

/// Classe principal para regras de personagens
class CharacterRules {
  // 🎭 SISTEMA DE RASTREAMENTO DE NOMES - v4 (SOLUÇÃO TÉCNICA)

  /// Extrai nomes próprios capitalizados do texto gerado
  /// Retorna Set de nomes encontrados (não duplicados)
  static Set<String> extractNamesFromText(String text) {
    final names = <String>{};

    // 🎯 REGEX para detectar nomes próprios:
    // - Palavra capitalizada (primeira letra maiúscula)
    // - 2-15 letras
    // - Não é início de frase (tem palavra antes)
    // - Não são palavras comuns (artigos, preposições)
    final namePattern = RegExp(
      r'(?<![.!?]\s)(?<!\n)(?<!^)\b([A-ZÀ-Ü][a-zà-ÿ]{1,14})\b',
      multiLine: true,
    );

    final matches = namePattern.allMatches(text);

    for (final match in matches) {
      final potentialName = match.group(1);
      if (potentialName != null) {
        // 🔥 FILTRO: Remover palavras comuns que não são nomes
        final commonWords = {
          'Então',
          'Quando',
          'Depois',
          'Antes',
          'Agora',
          'Hoje',
          'Naquela',
          'Aquela',
          'Aquele',
          'Naquele',
          'Enquanto',
          'Durante',
          'Embora',
          'Porém',
          'Portanto',
          'Assim',
          'Nunca',
          'Sempre',
          'Talvez',
          'Quase',
          'Apenas',
          'Mesmo',
          'Também',
          'Muito',
          'Pouco',
          'Tanto',
        };

        if (!commonWords.contains(potentialName)) {
          names.add(potentialName);
        }
      }
    }

    return names;
  }

  /// Valida se há nomes duplicados em papéis diferentes
  /// Retorna lista de nomes duplicados encontrados
  static List<String> validateNamesInText(
    String newBlock,
    Set<String> previousNames,
  ) {
    final duplicates = <String>[];
    final newNames = extractNamesFromText(newBlock);

    for (final name in newNames) {
      if (previousNames.contains(name)) {
        // 🚨 Nome já usado anteriormente!
        if (!duplicates.contains(name)) {
          duplicates.add(name);
        }
      }
    }

    return duplicates;
  }

  /// Gera instruções de controle de nomes para o prompt
  static String getNameControlInstructions(CharacterTracker tracker) {
    final buffer = StringBuffer();

    buffer.writeln('🚨 PRESERVAÇÃO DE NOMES - REGRA ABSOLUTA E INEGOCIÁVEL:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
      '⚠️ OS NOMES DE PERSONAGENS JÁ ESTABELECIDOS NO CONTEXTO ACIMA SÃO PERMANENTES!',
    );
    buffer.writeln(
      '⚠️ VOCÊ NÃO PODE MUDAR, ALTERAR, OU SUBSTITUIR ESSES NOMES EM HIPÓTESE ALGUMA!',
    );
    buffer.writeln(
      '⚠️ SE VOCÊ CRIAR NOVOS NOMES PARA PERSONAGENS JÁ EXISTENTES, O TEXTO SERÁ REJEITADO!',
    );
    buffer.writeln();
    buffer.writeln(
      '✅ CORRETO: "Daniela pegou o telefone" (se Daniela já existe no contexto)',
    );
    buffer.writeln(
      '❌ ERRADO: "Sofia pegou o telefone" (mudou o nome de Daniela para Sofia - PROIBIDO!)',
    );
    buffer.writeln(
      '❌ ERRADO: "A nora pegou o telefone" (usou descrição genérica em vez do nome - PROIBIDO!)',
    );
    buffer.writeln();

    // Adicionar mapeamento de personagens se houver
    final mapping = tracker.getCharacterMapping();
    if (mapping.isNotEmpty) {
      buffer.writeln(mapping);
    }

    buffer.writeln('⚠️ ATENÇÃO CRÍTICA - MEMBROS DA MESMA FAMÍLIA:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
      '⚠️ NUNCA, EM HIPÓTESE ALGUMA, use o MESMO NOME para dois membros da família!',
    );
    buffer.writeln();
    buffer.writeln(
      '❌ PROIBIDO: "Mônica" (protagonista) + "minha irmã, Mônica" = IMPOSSÍVEL!',
    );
    buffer.writeln(
      '❌ PROIBIDO: "Carlos" (pai) + "meu filho Carlos" = CONFUSO E ABSURDO!',
    );
    buffer.writeln(
      '❌ PROIBIDO: "Helena" (mãe) + "minha sogra Helena" = NÃO PODE!',
    );
    buffer.writeln();
    buffer.writeln(
      '✅ REGRA: CADA personagem da família precisa de um nome ÚNICO e DIFERENTE!',
    );
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return buffer.toString();
  }

  /// Gera protocolo de verificação de nomes para o prompt
  static String getNameVerificationProtocol() {
    return '''
🚨 PROTOCOLO OBRIGATÓRIO ANTES DE CRIAR NOVO PERSONAGEM:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ATENÇÃO CRÍTICA: Antes de introduzir qualquer personagem novo:

1️⃣ PAUSE e RELEIA o CONTEXTO ACIMA completamente
2️⃣ FAÇA UMA LISTA MENTAL de TODOS os nomes já mencionados
3️⃣ VERIFIQUE: O nome que você quer usar JÁ APARECEU?
4️⃣ SE SIM → Escolha OUTRO nome da lista "NOMES DISPONÍVEIS"
5️⃣ SE NÃO → Pode usar, mas MEMORIZE este novo nome!

🚨 CHECKLIST OBRIGATÓRIO ANTES DE NOMEAR PERSONAGEM 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔥 ANTES DE DAR NOME A **QUALQUER** PERSONAGEM (principal ou secundário):

✋ PARE! NÃO ESCREVA O NOME AINDA!

📝 SIGA ESTE PROTOCOLO OBRIGATÓRIO:

1️⃣ PAUSE e RELEIA os últimos 5-10 parágrafos que você escreveu
2️⃣ LISTE mentalmente TODOS os nomes já usados (principais + secundários)
3️⃣ PERGUNTE: "O nome que quero usar (ex: Alberto) JÁ apareceu?"
4️⃣ SE SIM → ESCOLHA OUTRO NOME IMEDIATAMENTE!
5️⃣ SE NÃO → Pode usar, mas ADICIONE à sua lista mental

⚠️ LEMBRE-SE:
   • Há 510+ nomes portugueses disponíveis no banco de dados
   • NÃO há desculpa para reutilizar nomes
   • Cada personagem merece identidade ÚNICA
   • Confusão de nomes = História rejeitada!

🎯 DICA PRÁTICA:
   Quando for criar personagem secundário:
   - Pense: "Vou usar Alberto"
   - PARE: "Alberto já apareceu? DEIXE-ME VERIFICAR..."
   - Releia contexto anterior
   - Se encontrou "Alberto": "OK, preciso de outro. Que tal Fernando? Marcelo? Gustavo?"
   - Se não encontrou: "Ótimo! Alberto está livre!"

🚨 ESTA VERIFICAÇÃO É OBRIGATÓRIA PARA **CADA NOVO PERSONAGEM**!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// Gera regras de validação de nomes para o prompt
  static String getNameValidationRules() {
    return '''
🚨 NOMES DE PERSONAGENS - REGRA CRÍTICA E OBRIGATÓRIA:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VOCÊ DEVE COPIAR E COLAR os nomes EXATAMENTE da lista "NOMES DISPONÍVEIS" acima.
⚠️ ESTA É UMA REGRA ABSOLUTA - NÃO HÁ EXCEÇÕES!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ CORRETO - Exemplos de como usar:
  • "Helena pegou o casaco" (Helena está na lista)
  • "Lucas entrou na sala" (Lucas está na lista)
  • "Sofia olhou para mim" (Sofia está na lista)

❌ PROIBIDO - NUNCA faça isso:
  • "Observei o casaco" → "Observei" NÃO é nome! Use "Marta observou"
  • "Quero saber a verdade" → "Quero" NÃO é nome! Use "Carlos quer saber"
  • "Pergunte a ele" → "Pergunte" NÃO é verbo! Use "Roberto perguntou"
  • "Apenas sorriu" → "Apenas" NÃO é nome! Use "Ana apenas sorriu"
  • "Imaginei que era tarde" → "Imaginei" é verbo! Use "Eu imaginei"

🚨 ERROS REAIS QUE VOCÊ COMETEU ANTES (NUNCA REPITA):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ "Lágrimas" como nome de pessoa → É uma PALAVRA COMUM! Use "Marina" ou "Júlia"
❌ "Justiça" como nome de pessoa → É um SUBSTANTIVO! Use "Beatriz" ou "Fernanda"
❌ "Vamos" como nome de pessoa → É um VERBO! Use "Rafael" ou "André"
❌ "Aconteceu" como nome de pessoa → É um VERBO! Use "Carlos" ou "Miguel"
❌ "Ponto" como nome de pessoa → É uma PALAVRA! Use "Paulo" ou "Antônio"
❌ "Semanas" como nome de pessoa → É uma PALAVRA! Use "Pedro" ou "José"
❌ "Todas" como nome de pessoa → É um PRONOME! Use "Manuel" ou "Luís"
❌ "Ajuda" e "Consolo" como nomes de irmãs → São SUBSTANTIVOS! Use "Rita e Clara"

⚠️ REGRA: Se uma palavra NÃO está na lista "NOMES DISPONÍVEIS", NÃO É NOME!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 PROCESSO OBRIGATÓRIO para nomear personagens:
1. PAUSE e OLHE para a lista "NOMES DISPONÍVEIS" acima
2. IDENTIFIQUE: personagem é masculino ou feminino? Jovem, maduro ou idoso?
3. ESCOLHA um nome da categoria apropriada
4. COPIE o nome EXATAMENTE como está escrito na lista
5. VERIFIQUE: este nome já foi usado para OUTRO personagem? Se SIM, escolha outro!

⚠️ REGRA CRÍTICA: NUNCA use o mesmo nome para dois personagens diferentes!
   ❌ ERRADO: "Ricardo, o advogado" (bloco 3) e depois "Ricardo, o namorado" (bloco 17)
   ✅ CORRETO: "Ricardo, o advogado" (bloco 3) e depois "Fernando, o namorado" (bloco 17)

⚠️ TESTE ANTES DE ESCREVER:
Antes de usar qualquer palavra como nome, pergunte:
"Esta palavra está na lista NOMES DISPONÍVEIS acima?"
Se a resposta é NÃO → NÃO USE como nome!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }
}

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

/// 🔥 SOLUÇÃO 3: Tracker GLOBAL para manter personagens entre blocos
class CharacterTracker {
  final Set<String> _confirmedNames = {};
  // 🔥 NOVO: Mapear cada nome ao seu papel para prevenir confusão e reuso
  final Map<String, String> _characterRoles = {};
  // 📊 v1.7 NOVO: MAPEAMENTO REVERSO papel → nome (detecta nomes múltiplos por papel)
  final Map<String, String> _roleToName = {};
  // 📚 SISTEMA DE NOTAS: Histórico completo de cada personagem
  final Map<String, CharacterHistory> _characterHistories = {};

  void addName(String name, {String? role, int? blockNumber}) {
    if (name.isEmpty || name.length <= 2) return;

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
      return; // Bloqueia adição
    }

    // 🚨 v1.7: VALIDAÇÃO REVERSA - Um papel pode ter apenas UM nome
    if (role != null && role.isNotEmpty && role != 'indefinido') {
      // Normalizar papel (remover detalhes específicos para comparação)
      final normalizedRole = _normalizeRole(role);

      if (_roleToName.containsKey(normalizedRole)) {
        final existingName = _roleToName[normalizedRole]!;

        if (existingName != name) {
          // 🚨 ERRO CRÍTICO: Mesmo papel com nomes diferentes!
          if (kDebugMode) {
            debugPrint(
              '🚨🚨🚨 ERRO CRÍTICO v1.7: MÚLTIPLOS NOMES PARA MESMO PAPEL 🚨🚨🚨',
            );
            debugPrint('   ❌ Papel: "$normalizedRole"');
            debugPrint('   ❌ Nome original: "$existingName"');
            debugPrint('   ❌ Nome novo (CONFLITANTE): "$name"');
            debugPrint(
              '   💡 EXEMPLO DO BUG: "filho" sendo Marco em um bloco e Martin em outro!',
            );
            debugPrint(
              '   ⚠️ BLOQUEANDO adição de "$name" - usar apenas "$existingName"!',
            );
            debugPrint('🚨🚨🚨 FIM DO ALERTA 🚨🚨🚨');
          }
          return; // BLOQUEIA nome conflitante
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
  }

  /// 🔧 v1.7: Normaliza papel para comparação (remove detalhes específicos)
  /// Exemplo: "irmã de Ana" → "irmã", "filho de Maria" → "filho"
  String _normalizeRole(String role) {
    // Remover " de [nome]" do final
    final normalized = role.replaceAll(
      RegExp(r'\s+de\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+.*$'),
      '',
    );
    return normalized.trim().toLowerCase();
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

  // 🔥 NOVO: Obter mapeamento completo de personagens com histórico
  String getCharacterMapping() {
    if (_characterRoles.isEmpty && _characterHistories.isEmpty) return '';

    final buffer = StringBuffer('\n🎭 PERSONAGENS JÁ DEFINIDOS:\n');

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

  void clear() {
    _confirmedNames.clear();
    _characterRoles.clear();
    _roleToName.clear(); // v1.7: Limpar mapeamento reverso
    _characterHistories.clear();
  }
}
