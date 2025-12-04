import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/services/prompts/base_rules.dart';
import 'package:flutter_gerador/data/services/prompts/main_prompt_template.dart';

/// 🏗️ PromptBuilder - Construtor de Prompts para Geração de Roteiros
///
/// Responsável por:
/// - Constantes de formatação TTS
/// - Lógica de Pacing (_getPacingInstruction, _getArchetype)
/// - Lógica de Hook (_generateViralHook)
/// - Montagem do prompt principal
/// - Instruções de perspectiva (primeira/terceira pessoa)
///
/// Parte da refatoração SOLID do GeminiService v7.6.64
class PromptBuilder {
  /// 📏 Regras de formatação para TTS (Text-to-Speech)
  static const String ttsFormattingRules = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 REGRAS DE FORMATAÇÃO PARA TTS (Text-to-Speech)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ESTRUTURA DE PARÁGRAFOS:
• Máximo 180 palavras por parágrafo
• Parágrafos curtos = melhor ritmo de narração
• Quebrar diálogos longos em múltiplos parágrafos

PONTUAÇÃO PARA PAUSAS:
• Vírgula (,) = pausa curta (0.3s)
• Ponto final (.) = pausa média (0.5s)
• Reticências (...) = pausa longa dramática (1s)
• Exclamação (!) = ênfase emocional
• Interrogação (?) = inflexão de pergunta

DIÁLOGOS:
• Usar aspas duplas ("") para falas
• Uma fala por linha quando possível
• Indicar emoção entre parênteses quando relevante

EVITAR:
• Parágrafos gigantes (mais de 200 palavras)
• Muitos diálogos consecutivos sem narração
• Repetição de palavras na mesma frase
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';

  // ================== WRAPPERS PARA MÓDULOS EXISTENTES ==================

  /// 🔄 Obtém instrução de idioma
  static String getLanguageInstruction(String language) {
    return BaseRules.getLanguageInstruction(language);
  }

  /// 🔄 Obtém instrução de início
  static String getStartInstruction(
    String language, {
    required bool withTitle,
    String? title,
  }) {
    return BaseRules.getStartInstruction(
      language,
      withTitle: withTitle,
      title: title,
    );
  }

  /// 🔄 Obtém instrução de continuação
  static String getContinueInstruction(String language) {
    return BaseRules.getContinueInstruction(language);
  }

  /// 🔄 Obtém labels traduzidos para metadados
  static Map<String, String> getMetadataLabels(String language) {
    return BaseRules.getMetadataLabels(language);
  }

  /// 🔄 Constrói guidance de localização
  static String buildLocalizationGuidance(ScriptConfig config) {
    return BaseRules.buildLocalizationGuidance(config);
  }

  /// 🔄 Traduz termos de família
  static String translateFamilyTerms(String language, String text) {
    return BaseRules.translateFamilyTerms(language, text);
  }

  // ================== LÓGICA DE PERSPECTIVA ==================

  /// 🎭 Gera instrução de perspectiva narrativa (primeira/terceira pessoa)
  ///
  /// [perspective]: Tipo de perspectiva (primeira_pessoa_*, terceira_pessoa)
  /// [config]: Configuração do script para obter nome do protagonista
  ///
  /// Retorna: String com instruções detalhadas de perspectiva
  static String getPerspectiveInstruction(
    String perspective,
    ScriptConfig config,
  ) {
    final protagonistInfo = config.protagonistName.trim().isNotEmpty
        ? ' O protagonista é "${config.protagonistName}".'
        : '';

    final perspectiveLower = perspective.toLowerCase();

    // Detectar primeira pessoa (qualquer variação)
    if (perspectiveLower.contains('primeira_pessoa') ||
        perspectiveLower == 'first') {
      String pronomes = 'EU, MEU, MINHA, COMIGO';
      String exemplos =
          '"EU vendi a casa...", "MEU coração batia forte...", "COMIGO ela nunca foi honesta..."';
      String nomeInstrucao = '';

      if (perspectiveLower.contains('mulher')) {
        exemplos =
            '"EU vendi a casa...", "MINHA nora me traiu...", "COMIGO ela nunca foi honesta..."';
        String idadeInstrucao = _getAgeInstruction(perspectiveLower, 'mulher');
        nomeInstrucao = _buildFeminineNameInstruction(idadeInstrucao);
      } else if (perspectiveLower.contains('homem')) {
        exemplos =
            '"EU construí esse negócio...", "MEU filho me abandonou...", "COMIGO ele sempre foi desleal..."';
        String idadeInstrucao = _getAgeInstruction(perspectiveLower, 'homem');
        nomeInstrucao = _buildMasculineNameInstruction(idadeInstrucao);
      }

      return '''PERSPECTIVA NARRATIVA: PRIMEIRA PESSOA$protagonistInfo
$nomeInstrucao
⚠️ CRÍTICO: O PROTAGONISTA conta SUA PRÓPRIA HISTÓRIA usando "$pronomes".
🚫 PROIBIDO usar "ELE", "ELA", "DELE", "DELA" para o protagonista!
✅ CORRETO: $exemplos
O protagonista É o narrador. Ele/Ela está contando os eventos da SUA perspectiva em primeira pessoa.''';
    }

    // Terceira pessoa (padrão)
    return '''PERSPECTIVA NARRATIVA: TERCEIRA PESSOA$protagonistInfo
⚠️ IMPORTANTE: Um NARRADOR EXTERNO conta a história do protagonista usando "ELE", "ELA", "DELE", "DELA".
Exemplo: "ELA vendeu a casa...", "O coração DELE batia forte...", "COM ELA, ninguém foi honesto...".
O narrador observa e conta, mas NÃO é o protagonista.''';
  }

  /// 🎂 Gera instrução de faixa etária
  static String _getAgeInstruction(String perspectiveLower, String genero) {
    final generoLabel = genero == 'mulher' ? 'MULHER' : 'HOMEM';
    final generoIdoso = genero == 'mulher' ? 'IDOSA' : 'IDOSO';
    final generoMaduro = genero == 'mulher' ? 'MADURA' : 'MADURO';
    final generoJovem = 'JOVEM';

    if (perspectiveLower.contains('jovem')) {
      return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 FAIXA ETÁRIA OBRIGATÓRIA: $generoLabel $generoJovem (20-35 ANOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ IDADE CORRETA: Entre 20 e 35 anos
✅ PERFIL: Adulto jovem, início/meio da carreira, energético
✅ VOCABULÁRIO: Moderno, atual, referências contemporâneas

❌ PROIBIDO: Mencionar aposentadoria, netos, memórias de décadas atrás
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    } else if (perspectiveLower.contains('madur')) {
      return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 FAIXA ETÁRIA OBRIGATÓRIA: $generoLabel $generoMaduro (35-50 ANOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ IDADE CORRETA: Entre 35 e 50 anos
✅ PERFIL: Experiente, consolidado profissionalmente
✅ VOCABULÁRIO: Equilibrado, maduro mas contemporâneo

❌ PROIBIDO: Mencionar aposentadoria, netos adultos, velhice
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    } else if (perspectiveLower.contains('idos')) {
      return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 FAIXA ETÁRIA OBRIGATÓRIA: $generoLabel $generoIdoso (50+ ANOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ IDADE CORRETA: Acima de 50 anos
✅ PERFIL: Muita experiência de vida, possivelmente aposentado
✅ VOCABULÁRIO: Sábio, reflexivo, com histórias de décadas atrás

❌ PROIBIDO: Agir como jovem, usar gírias recentes inadequadas
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    }
    return '';
  }

  /// 👩 Instrução para nomes femininos
  static String _buildFeminineNameInstruction(String idadeInstrucao) {
    return '''
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🚨🚨🚨 GÊNERO OBRIGATÓRIO: FEMININO (MULHER) - CONFIGURAÇÃO DO USUÁRIO 🚨🚨🚨 ║
╚══════════════════════════════════════════════════════════════════════════════╝

⚠️⚠️⚠️ REGRA ABSOLUTA - NÃO NEGOCIÁVEL ⚠️⚠️⚠️

O USUÁRIO CONFIGUROU EXPLICITAMENTE: "Primeira Pessoa MULHER"
VOCÊ DEVE, OBRIGATORIAMENTE, GERAR UM PROTAGONISTA FEMININO!

📝 REGRAS DE NOMES:

1️⃣ SE O TÍTULO MENCIONAR UM NOME ESPECÍFICO (ex: "Você é Maria?"):
   ✅ USE ESTE NOME para a protagonista

2️⃣ SE O TÍTULO NÃO MENCIONAR NENHUM NOME:
   ✅ VOCÊ DEVE CRIAR um nome FEMININO apropriado para o idioma
   
   📋 Nomes femininos por idioma:
   • Français: Sophie, Marie, Amélie, Claire, Camille, Emma, Louise, Chloé
   • Português: Maria, Ana, Sofia, Helena, Clara, Beatriz, Julia, Laura
   • English: Emma, Sarah, Jennifer, Emily, Jessica, Ashley, Michelle, Amanda
   • Español: María, Carmen, Laura, Ana, Isabel, Rosa, Elena, Sofia
   • 한국어: Kim Ji-young, Park Soo-yeon, Lee Min-ji (SEMPRE SOBRENOME + NOME)

$idadeInstrucao

🔴 SE VOCÊ CRIAR UM PROTAGONISTA MASCULINO, O ROTEIRO SERÁ REJEITADO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// 👨 Instrução para nomes masculinos
  static String _buildMasculineNameInstruction(String idadeInstrucao) {
    return '''
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🚨🚨🚨 GÊNERO OBRIGATÓRIO: MASCULINO (HOMEM) - CONFIGURAÇÃO DO USUÁRIO 🚨🚨🚨 ║
╚══════════════════════════════════════════════════════════════════════════════╝

⚠️⚠️⚠️ REGRA ABSOLUTA - NÃO NEGOCIÁVEL ⚠️⚠️⚠️

O USUÁRIO CONFIGUROU EXPLICITAMENTE: "Primeira Pessoa HOMEM"
VOCÊ DEVE, OBRIGATORIAMENTE, GERAR UM PROTAGONISTA MASCULINO!

📝 REGRAS DE NOMES:

1️⃣ SE O TÍTULO MENCIONAR UM NOME ESPECÍFICO (ex: "Você é Michael?"):
   ✅ USE ESTE NOME para o protagonista

2️⃣ SE O TÍTULO NÃO MENCIONAR NENHUM NOME:
   ✅ VOCÊ DEVE CRIAR um nome MASCULINO apropriado para o idioma
   
   📋 Nomes masculinos por idioma:
   • Français: Pierre, Jean, Marc, Luc, Antoine, Thomas, Nicolas, Julien
   • Português: João, Pedro, Carlos, Roberto, Alberto, Paulo, Fernando, Ricardo
   • English: John, Michael, David, James, Robert, William, Richard, Thomas
   • Español: Juan, Pedro, Carlos, José, Luis, Miguel, Antonio, Francisco
   • 한국어: Kim Seon-woo, Park Jae-hyun, Lee Min-ho (SEMPRE SOBRENOME + NOME)

$idadeInstrucao

🔴 SE VOCÊ CRIAR UM PROTAGONISTA FEMININO, O ROTEIRO SERÁ REJEITADO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  // ================== MONTAGEM DE PROMPT PRINCIPAL ==================

  /// 🏗️ Constrói o prompt completo para geração de bloco
  ///
  /// Integra todas as partes:
  /// - Instrução de perspectiva
  /// - Contexto do World State
  /// - Seção do título
  /// - Template principal (via MainPromptTemplate)
  /// - Informações de bloco
  static String buildBlockPrompt({
    required ScriptConfig config,
    required int blockNumber,
    required int totalBlocks,
    required String contextoPrevio,
    required String trackerInfo,
    required String worldStateContext,
    required int adjustedTarget,
    required int minAcceptable,
    required int maxAcceptable,
    required int limitedNeeded,
    required bool avoidRepetition,
    required String characterGuidance,
    required String forbiddenNamesWarning,
  }) {
    // Instrução de perspectiva
    final perspectiveInstruction = getPerspectiveInstruction(
      config.perspective,
      config,
    );

    // Seção do título
    final titleSection = _buildTitleSection(config);

    // Instrução de início ou continuação
    String instruction;
    if (contextoPrevio.isEmpty) {
      if (config.startWithTitlePhrase && config.title.trim().isNotEmpty) {
        instruction = getStartInstruction(
          config.language,
          withTitle: true,
          title: config.title,
        );
      } else {
        instruction = getStartInstruction(config.language, withTitle: false);
      }
    } else {
      instruction = getContinueInstruction(config.language);
    }

    // Definir tema/subtema ou modo livre
    final labels = getMetadataLabels(config.language);
    final temaSection = config.tema == 'Livre (Sem Tema)'
        ? '// Modo Livre: Desenvolva o roteiro baseado APENAS no título e contexto fornecidos\n'
        : '${labels['theme']}: ${config.tema}\n${labels['subtheme']}: ${config.subtema}\n';

    // Guidance de localização
    final localizationGuidance = buildLocalizationGuidance(config);

    // Narrative style (poderia ser extraído para função separada)
    final narrativeStyleGuidance = _getNarrativeStyleGuidance(config);

    // Detectar se é espanhol
    final isSpanish =
        config.language.toLowerCase().contains('espanhol') ||
        config.language.toLowerCase().contains('spanish') ||
        config.language.toLowerCase().contains('español');

    // Measure instruction
    final measure = isSpanish
        ? 'GERE EXATAMENTE $adjustedTarget palabras (MÍNIMO $minAcceptable, MÁXIMO $maxAcceptable).'
        : 'GERE EXATAMENTE $adjustedTarget palavras (MÍNIMO $minAcceptable, MÁXIMO $maxAcceptable).';

    // Informações de bloco
    final blockInfo = _buildBlockInfo(blockNumber, totalBlocks, trackerInfo);

    // Montar prompt final
    return perspectiveInstruction +
        '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n' +
        worldStateContext +
        titleSection +
        MainPromptTemplate.buildCompactPrompt(
          language: getLanguageInstruction(config.language),
          instruction: instruction,
          temaSection: temaSection,
          localizacao: config.localizacao,
          localizationGuidance: localizationGuidance,
          narrativeStyleGuidance: narrativeStyleGuidance,
          customPrompt: config.customPrompt,
          useCustomPrompt: config.useCustomPrompt,
          nameList: '', // LLM gera nomes contextualmente
          trackerInfo: trackerInfo,
          measure: measure,
          isSpanish: isSpanish,
          adjustedTarget: adjustedTarget,
          minAcceptable: minAcceptable,
          maxAcceptable: maxAcceptable,
          limitedNeeded: limitedNeeded,
          contextoPrevio: contextoPrevio,
          avoidRepetition: avoidRepetition,
          characterGuidance: characterGuidance,
          forbiddenNamesWarning: forbiddenNamesWarning,
          labels: labels,
        ) +
        blockInfo;
  }

  /// 🎬 Constrói seção do título
  static String _buildTitleSection(ScriptConfig config) {
    if (config.title.trim().isEmpty) return '';

    return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 TÍTULO/PREMISSA OBRIGATÓRIA DA HISTÓRIA:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"${config.title}"

⚠️ REGRA ABSOLUTA:
   • A história DEVE desenvolver os elementos deste título
   • Personagens, ações e contexto do título são OBRIGATÓRIOS
   • NÃO invente uma história diferente da proposta no título
   • O título é a PROMESSA feita ao espectador - CUMPRA-A!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

''';
  }

  /// 📊 Constrói informações de bloco
  static String _buildBlockInfo(
    int blockNumber,
    int totalBlocks,
    String trackerInfo,
  ) {
    final isFinalBlock = blockNumber == totalBlocks;

    return '''

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 INFORMAÇÃO DE BLOCOS (CRÍTICO PARA PLANEJAMENTO):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   • Total de blocos planejados: $totalBlocks
   • Bloco atual: $blockNumber de $totalBlocks
   • Status: ${isFinalBlock ? 'BLOCO FINAL - Conclua a história agora!' : 'CONTINUAÇÃO - Este NÃO é o último bloco!'}

${isFinalBlock ? _getFinalBlockInstructions() : _getContinuationInstructions()}

🎯 REGRA ABSOLUTA:
   UMA HISTÓRIA = UM CONFLITO CENTRAL = UM ARCO COMPLETO = UMA RESOLUÇÃO
   PARÁGRAFOS CURTOS = PAUSAS = DRAMATICIDADE = RETENÇÃO ALTA
   UM NOME = UM PERSONAGEM = NUNCA REUTILIZAR = VERIFICAR SEMPRE

🚫 NUNCA crie duas histórias separadas dentro do mesmo roteiro!
🚫 NUNCA escreva parágrafos com mais de 180 palavras!
🚫 NUNCA reutilize nomes de personagens já mencionados!
${!isFinalBlock ? '🚫 NUNCA finalize a história antes do bloco final ($totalBlocks)!\n' : ''}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// ✅ Instruções para bloco final
  static String _getFinalBlockInstructions() {
    return '''
✅ OBRIGATÓRIO NESTE BLOCO FINAL:
   • AGORA SIM finalize completamente a história
   • Resolva TODOS os conflitos pendentes
   • Dê fechamento a TODOS os personagens
   • Este é o ÚLTIMO bloco - conclusão definitiva!
''';
  }

  /// ⏳ Instruções para blocos de continuação
  static String _getContinuationInstructions() {
    return '''
❌ PROIBIDO NESTE BLOCO:
   • NÃO finalize a história ainda!
   • NÃO escreva "THE END" ou equivalente
   • NÃO crie uma resolução completa e definitiva

✅ OBRIGATÓRIO NESTE BLOCO:
   • CONTINUE desenvolvendo a trama
   • Mantenha tensão e progressão narrativa
   • Deixe ganchos para os próximos blocos
''';
  }

  /// 🎨 Obtém guidance de estilo narrativo
  static String _getNarrativeStyleGuidance(ScriptConfig config) {
    // Pode ser expandido para diferentes estilos
    return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎨 ESTILO NARRATIVO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Narrativa fluida otimizada para TTS
• Parágrafos curtos (máximo 180 palavras)
• Diálogos naturais e realistas
• Descrições vívidas mas concisas
• Ritmo dinâmico com variação de tensão
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  // ================== HOOKS E PACING ==================

  /// 🎣 Gera hook viral para início de história
  ///
  /// [title]: Título da história
  /// [tema]: Tema principal
  /// [language]: Idioma do roteiro
  ///
  /// Retorna: String com hook otimizado para engajamento
  static String generateViralHook({
    required String title,
    required String tema,
    required String language,
  }) {
    // Hook baseado em elementos do título
    if (title.contains('bilionário') || title.contains('billionaire')) {
      return 'O que acontece quando você ajuda um estranho... e descobre que ele pode mudar sua vida para sempre?';
    }
    if (title.contains('traição') || title.contains('betrayal')) {
      return 'Algumas verdades deveriam permanecer enterradas. Esta é a história de quando descobri a minha.';
    }
    if (title.contains('segredo') || title.contains('secret')) {
      return 'Todo mundo tem segredos. O problema é quando eles começam a te caçar.';
    }

    // Hook genérico mas eficaz
    return 'Esta história mudou tudo o que eu pensava saber sobre confiança.';
  }

  /// ⏱️ Obtém instrução de pacing baseado no progresso
  ///
  /// [progress]: Porcentagem de progresso (0.0 a 1.0)
  ///
  /// Retorna: String com instrução de ritmo narrativo
  static String getPacingInstruction(double progress) {
    if (progress < 0.20) {
      // Introdução (0-20%)
      return '''
📈 FASE: INTRODUÇÃO (Setup)
• Apresente protagonista e cenário
• Estabeleça situação inicial
• Introduza elementos do conflito
• Ritmo: Moderado, construindo curiosidade
''';
    } else if (progress < 0.40) {
      // Desenvolvimento inicial (20-40%)
      return '''
📈 FASE: DESENVOLVIMENTO INICIAL
• Aprofunde personagens
• Intensifique conflito
• Introduza complicações
• Ritmo: Crescente, aumentando tensão
''';
    } else if (progress < 0.60) {
      // Ponto médio (40-60%)
      return '''
📈 FASE: PONTO MÉDIO (Midpoint)
• Revelação importante ou reviravolta
• Protagonista toma decisão crucial
• Stakes aumentam significativamente
• Ritmo: Alto, momentos de impacto
''';
    } else if (progress < 0.80) {
      // Clímax se aproximando (60-80%)
      return '''
📈 FASE: PRÉ-CLÍMAX
• Todos os elementos convergem
• Tensão máxima
• Preparação para confronto final
• Ritmo: Muito alto, urgência
''';
    } else {
      // Clímax e resolução (80-100%)
      return '''
📈 FASE: CLÍMAX E RESOLUÇÃO
• Confronto principal
• Resolução de todos os conflitos
• Fechamento de arcos de personagens
• Ritmo: Intenso → Catártico → Conclusivo
''';
    }
  }

  /// 🎭 Obtém arquétipo de história baseado no tema
  ///
  /// [tema]: Tema da história
  ///
  /// Retorna: Nome do arquétipo narrativo
  static String getArchetype(String tema) {
    final temaLower = tema.toLowerCase();

    if (temaLower.contains('vingança') || temaLower.contains('revenge')) {
      return 'VINGANÇA E JUSTIÇA';
    }
    if (temaLower.contains('traição') || temaLower.contains('betrayal')) {
      return 'TRAIÇÃO E REDENÇÃO';
    }
    if (temaLower.contains('amor') || temaLower.contains('love')) {
      return 'AMOR E SACRIFÍCIO';
    }
    if (temaLower.contains('família') || temaLower.contains('family')) {
      return 'LAÇOS FAMILIARES';
    }
    if (temaLower.contains('sucesso') || temaLower.contains('success')) {
      return 'ASCENSÃO E QUEDA';
    }
    if (temaLower.contains('mistério') || temaLower.contains('mystery')) {
      return 'MISTÉRIO E REVELAÇÃO';
    }

    return 'JORNADA DO HERÓI';
  }
}
