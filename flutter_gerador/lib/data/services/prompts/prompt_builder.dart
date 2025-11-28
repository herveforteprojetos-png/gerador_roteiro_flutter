/// Sistema de Construção Dinâmica de Prompts
/// Orquestra todos os módulos de regras para construir prompts otimizados
library;

import 'base_rules.dart';
import 'character_rules.dart';
import 'structure_rules.dart';
import 'youtube_rules.dart';

/// Construtor dinâmico de prompts que combina todas as regras
class PromptBuilder {
  final String language;
  final String perspective;
  final String narrativeStyle;
  final String measureType;
  final int needed;
  final int blockNumber;
  final int totalBlocks;
  final int totalWords;
  final int currentWords;
  final CharacterTracker characterTracker;
  final String? theme;
  final String? location;
  final String? ambiance;
  final String? villainType;
  final String? endingType;
  final String? protagonistGender;

  PromptBuilder({
    required this.language,
    required this.perspective,
    required this.narrativeStyle,
    required this.measureType,
    required this.needed,
    required this.blockNumber,
    required this.totalBlocks,
    required this.totalWords,
    required this.currentWords,
    required this.characterTracker,
    this.theme,
    this.location,
    this.ambiance,
    this.villainType,
    this.endingType,
    this.protagonistGender,
  });

  /// Constrói o prompt completo combinando todos os módulos
  String buildFullPrompt({
    required String context,
    bool includeYouTubeRules = true,
    bool includeStructureRules = true,
    bool includeCharacterRules = true,
  }) {
    final buffer = StringBuffer();

    // ═══════════════════════════════════════════════════════════════
    // SEÇÃO 1: CONTEXTO E INSTRUÇÃO BASE
    // ═══════════════════════════════════════════════════════════════
    buffer.writeln('CONTEXTO:');
    buffer.writeln(context);
    buffer.writeln();

    // ═══════════════════════════════════════════════════════════════
    // SEÇÃO 2: INSTRUÇÃO DE IDIOMA E LOCALIZAÇÃO
    // ═══════════════════════════════════════════════════════════════
    buffer.writeln(BaseRules.getLanguageInstruction(language));
    buffer.writeln();

    // ═══════════════════════════════════════════════════════════════
    // SEÇÃO 3: ORIENTAÇÃO DE LOCALIZAÇÃO
    // ═══════════════════════════════════════════════════════════════
    // Nota: buildLocalizationGuidance requer ScriptConfig completo
    // Esta seção será adicionada pelo gemini_service ao chamar buildFullPrompt
    buffer.writeln();

    // ═══════════════════════════════════════════════════════════════
    // SEÇÃO 4: INSTRUÇÃO DE PERSPECTIVA NARRATIVA
    // ═══════════════════════════════════════════════════════════════
    buffer.writeln(_getPerspectiveInstruction());
    buffer.writeln();

    // ═══════════════════════════════════════════════════════════════
    // SEÇÃO 5: ESTRUTURA DE 3 ATOS
    // ═══════════════════════════════════════════════════════════════
    if (includeStructureRules) {
      buffer.writeln(
        StructureRules.getThreeActStructure(
          totalWords: totalWords,
          blockNumber: blockNumber,
          totalBlocks: totalBlocks,
        ),
      );
      buffer.writeln();

      buffer.writeln(StructureRules.getAct3Details());
      buffer.writeln();

      buffer.writeln(StructureRules.getDetailedFallRules());
      buffer.writeln();

      buffer.writeln(
        StructureRules.getProgressCheckpoints(
          totalWords: totalWords,
          currentWords: currentWords,
        ),
      );
      buffer.writeln();

      buffer.writeln(StructureRules.getRetentionHooks());
      buffer.writeln();

      buffer.writeln(StructureRules.getCompletionChecklist());
      buffer.writeln();

      buffer.writeln(StructureRules.getCharacterLimits());
      buffer.writeln();

      buffer.writeln(
        StructureRules.getBlockProgressInstructions(
          blockNumber: blockNumber,
          totalBlocks: totalBlocks,
        ),
      );
      buffer.writeln();

      buffer.writeln(StructureRules.getLimitsTable());
      buffer.writeln();
    }

    // ═══════════════════════════════════════════════════════════════
    // SEÇÃO 6: REGRAS ESPECÍFICAS DO YOUTUBE
    // ═══════════════════════════════════════════════════════════════
    if (includeYouTubeRules) {
      buffer.writeln(YouTubeRules.getAllYouTubeRules());
      buffer.writeln();
    }

    // ═══════════════════════════════════════════════════════════════
    // SEÇÃO 7: REGRAS DE PERSONAGENS E NOMES
    // ═══════════════════════════════════════════════════════════════
    if (includeCharacterRules) {
      buffer.writeln(
        CharacterRules.getNameControlInstructions(characterTracker),
      );
      buffer.writeln();

      buffer.writeln(CharacterRules.getNameVerificationProtocol());
      buffer.writeln();

      buffer.writeln(CharacterRules.getNameValidationRules());
      buffer.writeln();
    }

    // ═══════════════════════════════════════════════════════════════
    // SEÇÃO 8: METADATA E LABELS
    // ═══════════════════════════════════════════════════════════════
    final labels = BaseRules.getMetadataLabels(language);
    if (theme != null || location != null) {
      buffer.writeln('\n${labels['metadata']}:');
      if (theme != null) {
        buffer.writeln('${labels['theme']}: $theme');
      }
      if (location != null) {
        buffer.writeln('${labels['location']}: $location');
      }
      if (ambiance != null) {
        buffer.writeln('${labels['ambiance']}: $ambiance');
      }
      if (villainType != null) {
        buffer.writeln('${labels['villain']}: $villainType');
      }
      if (endingType != null) {
        buffer.writeln('${labels['ending']}: $endingType');
      }
      buffer.writeln();
    }

    // ═══════════════════════════════════════════════════════════════
    // SEÇÃO 9: INSTRUÇÃO DE CONTINUAÇÃO OU INÍCIO
    // ═══════════════════════════════════════════════════════════════
    if (context.isEmpty || blockNumber == 1) {
      buffer.writeln(
        BaseRules.getStartInstruction(
          language,
          withTitle:
              false, // Título será adicionado pelo gemini_service se necessário
        ),
      );
    } else {
      buffer.writeln(BaseRules.getContinueInstruction(language));
    }
    buffer.writeln();

    // ═══════════════════════════════════════════════════════════════
    // SEÇÃO 10: LEMBRETES FINAIS CRÍTICOS
    // ═══════════════════════════════════════════════════════════════
    buffer.writeln(_getFinalReminders());

    return buffer.toString();
  }

  /// Gera instrução de perspectiva narrativa
  String _getPerspectiveInstruction() {
    if (perspective.contains('primeira_pessoa')) {
      return '''
🎯 PERSPECTIVA OBRIGATÓRIA: PRIMEIRA PESSOA (EU)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ NARRADOR = PROTAGONISTA contando SUA própria história

✅ OBRIGATÓRIO:
   • Use "eu", "meu/minha", "comigo", "me"
   • O narrador conta o que ELE/ELA viveu
   • Perspectiva interna: pensamentos, sentimentos do protagonista

❌ PROIBIDO:
   • "Ele/ela" para o protagonista
   • Narração em terceira pessoa
   • Visão externa dos eventos

Exemplo: "Eu olhei para a carta. Minhas mãos tremiam."
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    } else {
      return '''
🎯 PERSPECTIVA OBRIGATÓRIA: TERCEIRA PESSOA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ NARRADOR EXTERNO contando história de outras pessoas

✅ OBRIGATÓRIO:
   • Use nomes próprios e "ele/ela"
   • Narração externa dos eventos
   • Visão onisciente ou limitada

❌ PROIBIDO:
   • "Eu", "meu/minha" (isso é primeira pessoa!)
   • Narrador se colocar como personagem

Exemplo: "João olhou para a carta. Suas mãos tremiam."
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    }
  }

  /// Gera lembretes finais críticos
  String _getFinalReminders() {
    return '''
🎯 REGRA ABSOLUTA:
   UMA HISTÓRIA = UM CONFLITO CENTRAL = UM ARCO COMPLETO = UMA RESOLUÇÃO
   PARÁGRAFOS CURTOS = PAUSAS = DRAMATICIDADE = RETENÇÃO ALTA
   UM NOME = UM PERSONAGEM = NUNCA REUTILIZAR = VERIFICAR SEMPRE
   DIÁLOGOS + MOTIVAÇÕES + CLOSURE = HISTÓRIA COMPLETA E SATISFATÓRIA

🚫 NUNCA crie duas histórias separadas dentro do mesmo roteiro!
🚫 NUNCA escreva parágrafos com mais de 180 palavras!
🚫 NUNCA reutilize nomes de personagens já mencionados!
🚫 NUNCA deixe personagens importantes sem destino final!
🚫 NUNCA faça traições/conflitos sem motivação clara!
${blockNumber < totalBlocks ? '🚫 NUNCA finalize a história antes do bloco final ($totalBlocks)!\n' : ''}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⭐ IMPORTANTE: Desenvolva a narrativa com riqueza de detalhes, diálogos, descrições e desenvolvimento de personagens para atingir EXATAMENTE o número de $measureType solicitado. SEMPRE use frases curtas (máximo 20-25 palavras), palavras simples que seus avós entendem, e linguagem de conversa natural familiar.

🚨 LEMBRETE FINAL ANTES DE COMEÇAR A ESCREVER:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ PERGUNTE A SI MESMO AGORA:

1️⃣ "Qual é o CONFLITO PRINCIPAL desta história?"
   → Deve ser o MESMO conflito do início ao fim!

2️⃣ "Este bloco está avançando ESSE conflito específico?"
   → Se não, você está criando história NOVA (PROIBIDO!)

3️⃣ "Estou resolvendo o problema inicial ou criando problema DIFERENTE?"
   → Subtramas OK se conectadas; Histórias separadas PROIBIDO!

4️⃣ "Ao final do roteiro, esse conflito terá RESOLUÇÃO CLARA?"
   → História sem final = REJEITADO!

5️⃣ "Cada parágrafo tem MENOS de 180 palavras?"
   → Parágrafos longos = monotonia = abandono = REJEITADO!
   → Conte as palavras DURANTE a escrita!
   → Ao atingir 150-180 palavras → QUEBRE EM NOVO PARÁGRAFO!

6️⃣ "TODOS os nomes que vou usar já foram verificados no contexto?"
   → ANTES de escrever qualquer nome, procure no CONTEXTO ACIMA!
   → Se o nome JÁ APARECEU antes = NÃO POSSO REUTILIZAR!
   → Exemplos: Marco (já usado?) → SIM? Escolha outro = Pedro!
   → Julia (já usada?) → SIM? Escolha outra = Helena!
   → Roberto (já usado?) → SIM? Escolha outro = Daniel!
   → CADA PERSONAGEM NOVO = VERIFICAÇÃO OBRIGATÓRIA!

✅ SE TODAS AS RESPOSTAS ESTÃO CERTAS → PROSSIGA COM A ESCRITA!
❌ SE QUALQUER RESPOSTA ESTÁ ERRADA → REVISE SEU PLANO!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// Constrói um prompt simplificado (sem todas as regras)
  String buildSimplePrompt({
    required String context,
    required String instruction,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('CONTEXTO:');
    buffer.writeln(context);
    buffer.writeln();

    buffer.writeln(BaseRules.getLanguageInstruction(language));
    buffer.writeln();

    buffer.writeln(_getPerspectiveInstruction());
    buffer.writeln();

    buffer.writeln('INSTRUÇÃO:');
    buffer.writeln(instruction);
    buffer.writeln();

    buffer.writeln('FORMATO: Texto narrativo limpo, sem formatação markdown.');
    buffer.writeln('IDIOMA: $language');

    return buffer.toString();
  }

  /// Constrói prompt apenas com regras de personagens
  String buildCharacterPrompt({required String context}) {
    final buffer = StringBuffer();

    buffer.writeln('CONTEXTO:');
    buffer.writeln(context);
    buffer.writeln();

    buffer.writeln(CharacterRules.getNameControlInstructions(characterTracker));
    buffer.writeln();

    buffer.writeln(CharacterRules.getNameVerificationProtocol());
    buffer.writeln();

    buffer.writeln(CharacterRules.getNameValidationRules());

    return buffer.toString();
  }

  /// Constrói prompt apenas com regras de estrutura
  String buildStructurePrompt({required String context}) {
    final buffer = StringBuffer();

    buffer.writeln('CONTEXTO:');
    buffer.writeln(context);
    buffer.writeln();

    buffer.writeln(
      StructureRules.getThreeActStructure(
        totalWords: totalWords,
        blockNumber: blockNumber,
        totalBlocks: totalBlocks,
      ),
    );
    buffer.writeln();

    buffer.writeln(
      StructureRules.getProgressCheckpoints(
        totalWords: totalWords,
        currentWords: currentWords,
      ),
    );
    buffer.writeln();

    buffer.writeln(
      StructureRules.getBlockProgressInstructions(
        blockNumber: blockNumber,
        totalBlocks: totalBlocks,
      ),
    );

    return buffer.toString();
  }

  /// Constrói prompt apenas com regras do YouTube
  String buildYouTubePrompt({required String context}) {
    final buffer = StringBuffer();

    buffer.writeln('CONTEXTO:');
    buffer.writeln(context);
    buffer.writeln();

    buffer.writeln(YouTubeRules.getAllYouTubeRules());

    return buffer.toString();
  }

  /// Constrói prompt customizado com regras selecionadas
  String buildCustomPrompt({
    required String context,
    required String customInstruction,
    bool includeBase = true,
    bool includeCharacter = false,
    bool includeStructure = false,
    bool includeYouTube = false,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('CONTEXTO:');
    buffer.writeln(context);
    buffer.writeln();

    if (includeBase) {
      buffer.writeln(BaseRules.getLanguageInstruction(language));
      buffer.writeln();

      buffer.writeln(_getPerspectiveInstruction());
      buffer.writeln();
    }

    if (includeCharacter) {
      buffer.writeln(
        CharacterRules.getNameControlInstructions(characterTracker),
      );
      buffer.writeln();
    }

    if (includeStructure) {
      buffer.writeln(
        StructureRules.getThreeActStructure(
          totalWords: totalWords,
          blockNumber: blockNumber,
          totalBlocks: totalBlocks,
        ),
      );
      buffer.writeln();
    }

    if (includeYouTube) {
      buffer.writeln(YouTubeRules.getFormatRules());
      buffer.writeln();
      buffer.writeln(YouTubeRules.getParagraphRules());
      buffer.writeln();
    }

    buffer.writeln('INSTRUÇÃO CUSTOMIZADA:');
    buffer.writeln(customInstruction);

    return buffer.toString();
  }

  /// Gera estatísticas do prompt construído
  Map<String, dynamic> getPromptStats(String prompt) {
    final lines = prompt.split('\n').length;
    final words = prompt.split(RegExp(r'\s+')).length;
    final chars = prompt.length;

    return {
      'lines': lines,
      'words': words,
      'characters': chars,
      'estimated_tokens': (words * 1.3).round(), // Aproximação
    };
  }
}
