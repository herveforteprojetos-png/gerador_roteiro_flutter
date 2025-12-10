import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'llm_client.dart';

/// 🎭 WorldCharacter - Representa um personagem no mundo da história
///
/// Rastreia informações essenciais sobre cada personagem:
/// - Nome e papel na história
/// - Status (vivo, morto, desaparecido, etc.)
/// - Localização atual
/// - Relacionamentos com outros personagens
class WorldCharacter {
  String nome;
  String papel;
  String? idade;
  String status; // 'vivo', 'morto', 'desaparecido', etc.
  String? localAtual;
  List<String> relacionamentos;

  WorldCharacter({
    required this.nome,
    required this.papel,
    this.idade,
    this.status = 'vivo',
    this.localAtual,
    List<String>? relacionamentos,
  }) : relacionamentos = relacionamentos ?? [];

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'nome': nome,
    'papel': papel,
    if (idade != null) 'idade': idade,
    'status': status,
    if (localAtual != null) 'local_atual': localAtual,
    if (relacionamentos.isNotEmpty) 'relacionamentos': relacionamentos,
  };

  /// Cria a partir de JSON
  factory WorldCharacter.fromJson(Map<String, dynamic> json) => WorldCharacter(
    nome: json['nome'] as String? ?? '',
    papel: json['papel'] as String? ?? 'personagem',
    idade: json['idade'] as String?,
    status: json['status'] as String? ?? 'vivo',
    localAtual: json['local_atual'] as String?,
    relacionamentos:
        (json['relacionamentos'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
  );

  @override
  String toString() => '$nome ($papel) - $status';
}

/// 🌍 WorldState - Estado completo do mundo da história
///
/// Estrutura JSON de memória infinita que rastreia:
/// - Personagens (nome, papel, status, localização)
/// - Inventário (objetos importantes por personagem)
/// - Fatos (eventos importantes que aconteceram)
/// - Linha do tempo (blocos onde eventos ocorreram)
/// - Sinopse Comprimida (Camada 1 - Contexto Estático)
///
/// Parte da refatoração SOLID do GeminiService v7.6.64
class WorldState {
  /// Personagens indexados por papel normalizado
  final Map<String, WorldCharacter> personagens;

  /// Inventário: papel → lista de itens
  final Map<String, List<String>> inventario;

  /// Fatos importantes da história (com bloco onde ocorreram)
  final List<Map<String, dynamic>> fatos;

  /// Último bloco processado
  int ultimoBloco;

  /// Resumo cumulativo da história
  String resumoAcumulado;

  /// Sinopse Comprimida (Camada 1 - Contexto Estático ≤500 tokens)
  /// Gerada UMA VEZ no início e incluída em TODOS os blocos
  String sinopseComprimida;

  WorldState()
    : personagens = {},
      inventario = {},
      fatos = [],
      ultimoBloco = 0,
      resumoAcumulado = '',
      sinopseComprimida = '';

  /// Converte para JSON string para incluir no prompt
  String toJsonString() {
    final buffer = StringBuffer();
    buffer.writeln('{');

    // Personagens
    buffer.writeln('  "personagens": {');
    final chars = personagens.entries.toList();
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      buffer.write(
        '    "${c.key}": {"nome":"${c.value.nome}","papel":"${c.value.papel}","status":"${c.value.status}"',
      );
      if (c.value.localAtual != null) {
        buffer.write(',"local":"${c.value.localAtual}"');
      }
      buffer.write('}');
      if (i < chars.length - 1) buffer.writeln(',');
    }
    buffer.writeln('\n  },');

    // Inventário (só se não vazio)
    if (inventario.isNotEmpty) {
      buffer.writeln('  "inventario": {');
      final invs = inventario.entries.toList();
      for (var i = 0; i < invs.length; i++) {
        final inv = invs[i];
        buffer.write('    "${inv.key}": ${inv.value}');
        if (i < invs.length - 1) buffer.writeln(',');
      }
      buffer.writeln('\n  },');
    }

    // Fatos (últimos 10 para economizar tokens)
    final recentFatos = fatos.length > 10
        ? fatos.sublist(fatos.length - 10)
        : fatos;
    if (recentFatos.isNotEmpty) {
      buffer.writeln('  "fatos_recentes": [');
      for (var i = 0; i < recentFatos.length; i++) {
        final f = recentFatos[i];
        buffer.write('    {"bloco":${f['bloco']},"evento":"${f['evento']}"}');
        if (i < recentFatos.length - 1) buffer.writeln(',');
      }
      buffer.writeln('\n  ],');
    }

    buffer.writeln('  "ultimo_bloco": $ultimoBloco');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Retorna contexto formatado para incluir no prompt de geração
  /// Estrutura "Sanduíche" de 3 Camadas
  String getContextForPrompt() {
    if (personagens.isEmpty && fatos.isEmpty && sinopseComprimida.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln(
      '═══════════════════════════════════════════════════════════',
    );
    buffer.writeln(
      '📊 CONTEXTO ESTRUTURADO - Pipeline de Modelo Único v7.6.53',
    );
    buffer.writeln(
      '═══════════════════════════════════════════════════════════',
    );

    // CAMADA 1 - CONTEXTO ESTÁTICO (Sinopse Comprimida ≤500 tokens)
    if (sinopseComprimida.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('🔵 CAMADA 1 - SINOPSE DA HISTÓRIA:');
      buffer.writeln('   $sinopseComprimida');
    }

    // CAMADA 3 - WORLD STATE JSON (Estado do Mundo)
    buffer.writeln('');
    buffer.writeln('🟡 CAMADA 3 - ESTADO DO MUNDO (Bloco $ultimoBloco):');

    // Personagens
    if (personagens.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('   🎭 PERSONAGENS ATIVOS:');
      for (final entry in personagens.entries) {
        final c = entry.value;
        buffer.write('      • ${c.nome} (${c.papel})');
        if (c.status != 'vivo') {
          buffer.write(' - STATUS: ${c.status.toUpperCase()}');
        }
        if (c.localAtual != null) {
          buffer.write(' - Local: ${c.localAtual}');
        }
        buffer.writeln();
      }
    }

    // Inventário
    if (inventario.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('   🎒 INVENTÁRIO/OBJETOS IMPORTANTES:');
      for (final entry in inventario.entries) {
        if (entry.value.isNotEmpty) {
          buffer.writeln('      • ${entry.key}: ${entry.value.join(", ")}');
        }
      }
    }

    // Fatos recentes
    final recentFatos = fatos.length > 5
        ? fatos.sublist(fatos.length - 5)
        : fatos;
    if (recentFatos.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('   📝 FATOS RECENTES:');
      for (final f in recentFatos) {
        buffer.writeln('      • [Bloco ${f['bloco']}] ${f['evento']}');
      }
    }

    // Resumo
    if (resumoAcumulado.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('   📖 RESUMO ATÉ AGORA:');
      buffer.writeln('      $resumoAcumulado');
    }

    buffer.writeln(
      '═══════════════════════════════════════════════════════════',
    );
    return buffer.toString();
  }

  /// Adiciona ou atualiza um personagem
  /// 🆕 v7.6.117: Não sobrescreve personagens já existentes com nomes diferentes
  void upsertCharacter(String papel, WorldCharacter character) {
    final normalizedRole = _normalizeRole(papel);
    
    // Se já existe um personagem com este papel E tem nome diferente, não sobrescrever
    final existing = personagens[normalizedRole];
    if (existing != null && existing.nome.isNotEmpty) {
      final existingNameNorm = existing.nome.toLowerCase().trim();
      final newNameNorm = character.nome.toLowerCase().trim();
      
      // Se os nomes são diferentes, manter o original (evita inconsistência)
      if (existingNameNorm != newNameNorm && existingNameNorm.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '🌍 WorldState: IGNORANDO novo nome "${character.nome}" para $papel - já existe "${existing.nome}"',
          );
        }
        return; // Não sobrescrever!
      }
    }
    
    personagens[normalizedRole] = character;
    if (kDebugMode) {
      debugPrint(
        '🌍 WorldState: Personagem atualizado - ${character.nome} ($papel)',
      );
    }
  }

  /// Adiciona item ao inventário de um personagem
  void addToInventory(String papel, String item) {
    final normalizedRole = _normalizeRole(papel);
    inventario.putIfAbsent(normalizedRole, () => []);
    if (!inventario[normalizedRole]!.contains(item)) {
      inventario[normalizedRole]!.add(item);
      if (kDebugMode) {
        debugPrint('🌍 WorldState: Item adicionado - $item para $papel');
      }
    }
  }

  /// Remove item do inventário
  void removeFromInventory(String papel, String item) {
    final normalizedRole = _normalizeRole(papel);
    inventario[normalizedRole]?.remove(item);
  }

  /// Adiciona um fato importante
  void addFact(int bloco, String evento) {
    fatos.add({'bloco': bloco, 'evento': evento});
    if (kDebugMode) {
      debugPrint('🌍 WorldState: Fato adicionado - [B$bloco] $evento');
    }
  }

  /// Atualiza status de um personagem
  void updateCharacterStatus(String papel, String novoStatus) {
    final normalizedRole = _normalizeRole(papel);
    if (personagens.containsKey(normalizedRole)) {
      personagens[normalizedRole]!.status = novoStatus;
      if (kDebugMode) {
        debugPrint('🌍 WorldState: Status atualizado - $papel → $novoStatus');
      }
    }
  }

  /// Atualiza localização de um personagem
  void updateCharacterLocation(String papel, String novoLocal) {
    final normalizedRole = _normalizeRole(papel);
    if (personagens.containsKey(normalizedRole)) {
      personagens[normalizedRole]!.localAtual = novoLocal;
    }
  }

  /// Normaliza papel para chave consistente
  static String _normalizeRole(String role) {
    return role
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Limpa estado para nova geração
  void clear() {
    personagens.clear();
    inventario.clear();
    fatos.clear();
    ultimoBloco = 0;
    resumoAcumulado = '';
    sinopseComprimida = '';
  }

  /// Cria snapshot para backup
  Map<String, dynamic> createSnapshot() {
    return {
      'personagens': personagens.map((k, v) => MapEntry(k, v.toJson())),
      'inventario': Map<String, List<String>>.from(inventario),
      'fatos': List<Map<String, dynamic>>.from(fatos),
      'ultimoBloco': ultimoBloco,
      'resumoAcumulado': resumoAcumulado,
      'sinopseComprimida': sinopseComprimida,
    };
  }

  /// Restaura de snapshot
  void restoreFromSnapshot(Map<String, dynamic> snapshot) {
    clear();

    final persMap = snapshot['personagens'] as Map<String, dynamic>?;
    if (persMap != null) {
      persMap.forEach((key, value) {
        personagens[key] = WorldCharacter.fromJson(
          value as Map<String, dynamic>,
        );
      });
    }

    final invMap = snapshot['inventario'] as Map<String, dynamic>?;
    if (invMap != null) {
      invMap.forEach((key, value) {
        inventario[key] = List<String>.from(value as List);
      });
    }

    final fatosL = snapshot['fatos'] as List<dynamic>?;
    if (fatosL != null) {
      fatos.addAll(fatosL.map((e) => Map<String, dynamic>.from(e as Map)));
    }

    ultimoBloco = snapshot['ultimoBloco'] as int? ?? 0;
    resumoAcumulado = snapshot['resumoAcumulado'] as String? ?? '';
    sinopseComprimida = snapshot['sinopseComprimida'] as String? ?? '';
  }
}

/// 🌍 WorldStateManager - Gerenciador do Estado do Mundo
///
/// Responsável por:
/// - Gerenciar instância do WorldState
/// - Atualizar estado após cada bloco gerado
/// - Gerar sinopse comprimida inicial
/// - Criar e restaurar snapshots/backups
///
/// Parte da refatoração SOLID do GeminiService v7.6.64
class WorldStateManager {
  final LlmClient _llmClient;
  final WorldState _worldState;

  /// Lista de snapshots para histórico/backup
  final List<Map<String, dynamic>> _snapshots = [];

  WorldStateManager({LlmClient? llmClient})
    : _llmClient = llmClient ?? LlmClient(),
      _worldState = WorldState();

  /// Acesso ao estado atual
  WorldState get state => _worldState;

  /// 🔵 Gera sinopse comprimida da história (Camada 1 - Contexto Estático)
  ///
  /// Esta sinopse é gerada UMA VEZ no início da geração e incluída em TODOS os blocos.
  /// Serve como "bíblia" da história para manter consistência.
  Future<String> generateCompressedSynopsis({
    required String tema,
    required String title,
    required String protagonistName,
    required String language,
    required String apiKey,
    required String qualityMode,
  }) async {
    if (kDebugMode) {
      debugPrint('🔵 Gerando Sinopse Comprimida (Camada 1)...');
    }

    try {
      final model = LlmClient.getModelForQuality(qualityMode);

      final prompt =
          '''
Você é um assistente de escrita criativa. Gere uma SINOPSE COMPRIMIDA da história a seguir.

TÍTULO: $title
PROTAGONISTA: $protagonistName
TEMA/PROMPT: $tema

INSTRUÇÕES:
1. Crie uma sinopse CONCISA de no máximo 150 palavras
2. Inclua: premissa, protagonista, conflito central, tom narrativo
3. NÃO inclua spoilers ou resolução da história
4. Use linguagem clara e objetiva
5. Esta sinopse será usada como referência durante toda a geração

FORMATO DE RESPOSTA:
Responda APENAS com a sinopse, sem formatação adicional ou explicações.
Idioma da resposta: $language
''';

      final synopsis = await _llmClient.generateText(
        prompt: prompt,
        apiKey: apiKey,
        model: model,
        maxTokens: 500,
        temperature: 0.4, // Baixa temperatura para consistência
      );

      if (synopsis.isNotEmpty) {
        // Limitar a ~150 palavras (~750 caracteres)
        final trimmed = synopsis.trim();
        final limited = trimmed.length > 750
            ? '${trimmed.substring(0, 750)}...'
            : trimmed;

        _worldState.sinopseComprimida = limited;

        if (kDebugMode) {
          debugPrint('✅ Sinopse Comprimida gerada: ${limited.length} chars');
        }
        return limited;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Exceção ao gerar sinopse: $e');
      }
    }

    // Fallback: usar tema original truncado
    final fallback = tema.length > 500 ? '${tema.substring(0, 500)}...' : tema;
    _worldState.sinopseComprimida = fallback;
    return fallback;
  }

  /// 🔄 Atualiza o estado do mundo após geração de um bloco
  ///
  /// Extrai informações do bloco gerado e atualiza:
  /// - Novos personagens
  /// - Itens de inventário
  /// - Fatos importantes
  /// - Resumo cumulativo
  Future<void> updateFromGeneratedBlock({
    required String generatedBlock,
    required int blockNumber,
    required String apiKey,
    required String qualityMode,
    required String language,
  }) async {
    if (generatedBlock.trim().isEmpty) return;

    try {
      final model = LlmClient.getModelForQuality(qualityMode);

      if (kDebugMode) {
        debugPrint(
          '🌍 [Bloco $blockNumber] Atualizando World State com modelo: $model',
        );
      }

      // Prompt para extrair informações do bloco
      final extractionPrompt =
          '''
Analise o seguinte trecho de história e extraia as informações estruturadas.

TRECHO (Bloco $blockNumber):
"""
$generatedBlock
"""

ESTADO ATUAL DO MUNDO:
${_worldState.toJsonString()}

INSTRUÇÕES:
1. Identifique NOVOS personagens que apareceram (nome, papel, status)
2. Identifique objetos importantes que foram mencionados/adquiridos
3. Identifique fatos importantes que aconteceram neste bloco
4. Resuma em 1-2 frases o que aconteceu neste bloco

RESPONDA EXATAMENTE NESTE FORMATO JSON (sem texto adicional):
{
  "novos_personagens": [
    {"nome": "Nome", "papel": "papel do personagem", "status": "vivo"}
  ],
  "novos_itens": [
    {"personagem": "papel", "item": "nome do item"}
  ],
  "novos_fatos": [
    "Descrição curta do fato importante"
  ],
  "resumo_bloco": "Resumo de 1-2 frases do que aconteceu"
}

Se não houver novos elementos em alguma categoria, use array vazio [].
IMPORTANTE: Responda APENAS com o JSON, sem explicações.
''';

      final response = await _llmClient.generateJson(
        prompt: extractionPrompt,
        apiKey: apiKey,
        model: model,
        maxTokens: 1024,
      );

      // Parse da resposta JSON
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ WorldState: Não foi possível extrair JSON da resposta',
          );
        }
        return;
      }

      try {
        final extracted = _parseJsonSafely(jsonMatch.group(0)!);
        if (extracted == null) return;

        // Atualizar personagens
        final novosPersonagens =
            extracted['novos_personagens'] as List<dynamic>? ?? [];
        for (final p in novosPersonagens) {
          if (p is Map<String, dynamic>) {
            final nome = p['nome'] as String? ?? '';
            final papel = p['papel'] as String? ?? 'personagem';
            if (nome.isNotEmpty) {
              _worldState.upsertCharacter(
                papel,
                WorldCharacter(
                  nome: nome,
                  papel: papel,
                  status: p['status'] as String? ?? 'vivo',
                ),
              );
            }
          }
        }

        // Atualizar inventário
        final novosItens = extracted['novos_itens'] as List<dynamic>? ?? [];
        for (final item in novosItens) {
          if (item is Map<String, dynamic>) {
            final personagem = item['personagem'] as String? ?? 'protagonista';
            final nomeItem = item['item'] as String? ?? '';
            if (nomeItem.isNotEmpty) {
              _worldState.addToInventory(personagem, nomeItem);
            }
          }
        }

        // Adicionar fatos
        final novosFatos = extracted['novos_fatos'] as List<dynamic>? ?? [];
        for (final fato in novosFatos) {
          if (fato is String && fato.isNotEmpty) {
            _worldState.addFact(blockNumber, fato);
          }
        }

        // Atualizar resumo acumulado
        final resumoBloco = extracted['resumo_bloco'] as String? ?? '';
        if (resumoBloco.isNotEmpty) {
          if (_worldState.resumoAcumulado.isEmpty) {
            _worldState.resumoAcumulado = resumoBloco;
          } else {
            // Manter resumo conciso (últimos 500 chars)
            final novoResumo = '${_worldState.resumoAcumulado} $resumoBloco';
            _worldState.resumoAcumulado = novoResumo.length > 500
                ? novoResumo.substring(novoResumo.length - 500)
                : novoResumo;
          }
        }

        _worldState.ultimoBloco = blockNumber;

        if (kDebugMode) {
          debugPrint('✅ WorldState atualizado:');
          debugPrint('   Personagens: ${_worldState.personagens.length}');
          debugPrint('   Fatos: ${_worldState.fatos.length}');
          debugPrint(
            '   Itens: ${_worldState.inventario.values.expand((x) => x).length}',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ WorldState: Erro ao processar JSON: $e');
        }
      }
    } catch (e) {
      // Erro não-crítico - não interrompe a geração
      if (kDebugMode) {
        debugPrint('⚠️ WorldState: Erro na atualização (não-crítico): $e');
      }
    }
  }

  /// Helper para parse seguro de JSON
  Map<String, dynamic>? _parseJsonSafely(String jsonStr) {
    try {
      final cleaned = jsonStr
          .replaceAll('\n', ' ')
          .replaceAll('\r', '')
          .replaceAll(RegExp(r'\\(?!["\\/bfnrt])'), '\\\\');

      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ JSON parse error: $e');
      }
      return null;
    }
  }

  // ================== SNAPSHOT/BACKUP ==================

  /// 📸 Cria snapshot do estado atual
  void createSnapshot() {
    _snapshots.add(_worldState.createSnapshot());
    if (kDebugMode) {
      debugPrint('📸 WorldState: Snapshot criado (#${_snapshots.length})');
    }
  }

  /// ⏪ Restaura último snapshot
  bool restoreLastSnapshot() {
    if (_snapshots.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ WorldState: Nenhum snapshot disponível');
      }
      return false;
    }

    final snapshot = _snapshots.removeLast();
    _worldState.restoreFromSnapshot(snapshot);

    if (kDebugMode) {
      debugPrint('⏪ WorldState: Restaurado para snapshot anterior');
    }
    return true;
  }

  /// 🗑️ Limpa todos os snapshots
  void clearSnapshots() {
    _snapshots.clear();
  }

  /// Limpa estado para nova geração
  void reset() {
    _worldState.clear();
    _snapshots.clear();
  }

  /// Inicializa protagonista no estado
  void initializeProtagonist(String name) {
    if (name.trim().isNotEmpty) {
      _worldState.upsertCharacter(
        'protagonista',
        WorldCharacter(
          nome: name.trim(),
          papel: 'protagonista/narradora',
          status: 'vivo',
        ),
      );
    }
  }

  /// 🔄 v7.6.64: Obtém contexto estruturado para prompts
  /// Retorna representação formatada do estado do mundo
  String getStructuredContext() => _worldState.getContextForPrompt();

  /// 📝 v7.6.64: Obtém JSON string do estado (para debug/logging)
  String toJsonString() => _worldState.toJsonString();

  /// 🔄 v7.6.64: Atualiza sinopse comprimida diretamente
  void setSynopsis(String synopsis) {
    _worldState.sinopseComprimida = synopsis;
  }

  /// 📊 v7.6.64: Obtém sinopse comprimida atual
  String get synopsis => _worldState.sinopseComprimida;
}
