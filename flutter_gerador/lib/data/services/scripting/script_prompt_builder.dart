import 'package:flutter/foundation.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/services/prompts/base_rules.dart';
import 'package:flutter_gerador/data/services/prompts/main_prompt_template.dart';

/// 🏗️ ScriptPromptBuilder - Construtor de Prompts para Geração de Roteiros
///
/// Responsável por:
/// - Constantes de formatação TTS
/// - Lógica de Pacing (_getPacingInstruction, _getArchetype)
/// - Lógica de Hook (_generateViralHook)
/// - Montagem do prompt principal
/// - Instruções de perspectiva (primeira/terceira pessoa)
/// - Prompts de recuperação de elementos faltantes
///
/// Parte da refatoração SOLID do GeminiService v7.6.64
/// Renomeado de PromptBuilder para evitar conflito com prompts/prompt_builder.dart
class ScriptPromptBuilder {
  /// 🚫 Regras ANTI-REPETIÇÃO e ANTI-LOOP (CRÍTICO)
  static const String antiRepetitionRules = """
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚫 REGRAS DE CONTINUIDADE (CRÍTICO - ÚLTIMA INSTRUÇÃO):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. **AVANCE O TEMPO:** Você está escrevendo a CONTINUAÇÃO. O bloco anterior 
   já terminou a cena. NÃO reescreva o que acabou de acontecer. Comece 
   IMEDIATAMENTE na próxima ação.

2. **PROIBIDO RECAPITULAR:** Se o bloco anterior terminou com "Ele saiu da sala", 
   o novo bloco DEVE começar com "No corredor..." ou "No dia seguinte...". 
   NUNCA repita "Ele saiu da sala".

3. **AÇÃO > PENSAMENTO:** Limite monólogos internos a no máximo 2 frases 
   consecutivas. Foque no que os personagens FAZEM e FALAM.

4. **SHOW, DON'T TELL:** Em vez de escrever "Ele estava nervoso", escreva 
   "Suas mãos tremiam enquanto segurava o copo".

5. **BLOCOS ANTERIORES JÁ EXISTEM:** Não reescreva parágrafos que já foram 
   escritos. Se você lê "Kim Tae-jun saiu da sala" no contexto anterior, 
   isso JÁ ACONTECEU. Pule para a PRÓXIMA cena.

6. **RITMO CINEMATOGRÁFICO:** Alterne entre ação externa e reflexão interna. 
   Máximo 2 parágrafos de pensamentos antes de voltar à ação concreta.

🎬 REGRA DE OURO: CADA NOVO BLOCO = NOVA CENA OU AVANÇO DE TEMPO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""";

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
    final compactPrompt = MainPromptTemplate.buildCompactPrompt(
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
    );

    return '$perspectiveInstruction\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n$worldStateContext$titleSection$compactPrompt$blockInfo\n$antiRepetitionRules\n$ttsFormattingRules';
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
  /// 🎣 Gera gancho viral para abertura do roteiro
  ///
  /// Analisa título, tema e idioma para criar um hook impactante
  /// que prende a atenção nos primeiros 5 segundos.
  ///
  /// [title]: Título do roteiro
  /// [tema]: Tema/categoria do conteúdo
  /// [language]: Idioma do roteiro (pt, en, es)
  ///
  /// Retorna: String com gancho viral contextualizado
  static String generateViralHook({
    required String title,
    required String tema,
    required String language,
  }) {
    final titleLower = title.toLowerCase();
    final temaLower = tema.toLowerCase();

    // 🌍 Hooks por idioma
    final hooks = _getHooksByLanguage(language);

    // 🎯 Hook específico por elementos do título (prioridade)

    // 💰 Histórias de riqueza/bilionários
    if (_containsAny(titleLower, [
      'bilionário',
      'billionaire',
      'rico',
      'millonario',
      'fortuna',
      'herdeiro',
      'heir',
    ])) {
      return hooks['billionaire']!;
    }

    // 💔 Histórias de traição/vingança
    if (_containsAny(titleLower, [
      'traição',
      'betrayal',
      'traicion',
      'vingança',
      'revenge',
      'venganza',
    ])) {
      return hooks['betrayal']!;
    }

    // 🔒 Histórias de segredos/mistérios
    if (_containsAny(titleLower, [
      'segredo',
      'secret',
      'secreto',
      'mistério',
      'mystery',
      'misterio',
      'oculto',
      'hidden',
    ])) {
      return hooks['secret']!;
    }

    // 👨‍👩‍👧 Histórias de família/relacionamentos
    if (_containsAny(titleLower, [
      'mãe',
      'pai',
      'filho',
      'filha',
      'família',
      'mother',
      'father',
      'son',
      'daughter',
      'family',
      'esposa',
      'marido',
      'wife',
      'husband',
    ])) {
      return hooks['family']!;
    }

    // 😢 Histórias de superação/emoção
    if (_containsAny(titleLower, [
      'chorei',
      'cried',
      'lloré',
      'emocionante',
      'touching',
      'lágrimas',
      'tears',
    ])) {
      return hooks['emotional']!;
    }

    // 🏥 Histórias de doença/hospital
    if (_containsAny(titleLower, [
      'hospital',
      'médico',
      'doctor',
      'doença',
      'cancer',
      'câncer',
      'sick',
      'enfermo',
    ])) {
      return hooks['medical']!;
    }

    // 💼 Histórias de trabalho/chefe
    if (_containsAny(titleLower, [
      'chefe',
      'boss',
      'jefe',
      'emprego',
      'job',
      'trabajo',
      'demitido',
      'fired',
      'despedido',
    ])) {
      return hooks['work']!;
    }

    // 👻 Histórias de terror/medo
    if (_containsAny(temaLower, [
      'terror',
      'horror',
      'medo',
      'fear',
      'miedo',
      'sobrenatural',
      'supernatural',
    ])) {
      return hooks['horror']!;
    }

    // 💕 Histórias de romance
    if (_containsAny(temaLower, [
      'romance',
      'amor',
      'love',
      'relacionamento',
      'relationship',
    ])) {
      return hooks['romance']!;
    }

    // 🎬 Hook genérico mas eficaz (fallback)
    return hooks['generic']!;
  }

  /// Helper para verificar se string contém qualquer termo da lista
  static bool _containsAny(String text, List<String> terms) {
    return terms.any((term) => text.contains(term));
  }

  /// Retorna mapa de hooks por idioma
  static Map<String, String> _getHooksByLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'en':
      case 'english':
        return {
          'billionaire':
              'What happens when you help a stranger... and discover they could change your life forever?',
          'betrayal':
              'Some truths should remain buried. This is the story of when I discovered mine.',
          'secret':
              'Everyone has secrets. The problem is when they start hunting you.',
          'family':
              'The last words she said to me changed everything. I just wish I had listened sooner.',
          'emotional': 'I never cry. But this story... this story broke me.',
          'medical':
              'The doctor called it a miracle. I call it the day everything changed.',
          'work':
              'My boss laughed when he fired me. He stopped laughing three months later.',
          'horror':
              'I used to think monsters were just stories. That was before I met one.',
          'romance':
              'They say you only truly love once. I thought that was true... until that day.',
          'generic':
              'This story changed everything I thought I knew about trust.',
        };

      case 'es':
      case 'spanish':
        return {
          'billionaire':
              '¿Qué pasa cuando ayudas a un extraño... y descubres que podría cambiar tu vida para siempre?',
          'betrayal':
              'Algunas verdades deberían permanecer enterradas. Esta es la historia de cuando descubrí la mía.',
          'secret':
              'Todos tienen secretos. El problema es cuando empiezan a cazarte.',
          'family':
              'Las últimas palabras que me dijo lo cambiaron todo. Ojalá hubiera escuchado antes.',
          'emotional':
              'Nunca lloro. Pero esta historia... esta historia me quebró.',
          'medical':
              'El doctor lo llamó un milagro. Yo lo llamo el día que todo cambió.',
          'work':
              'Mi jefe se rió cuando me despidió. Dejó de reír tres meses después.',
          'horror':
              'Solía pensar que los monstruos eran solo cuentos. Eso fue antes de conocer uno.',
          'romance':
              'Dicen que solo amas de verdad una vez. Yo creía eso... hasta ese día.',
          'generic':
              'Esta historia cambió todo lo que pensaba saber sobre la confianza.',
        };

      default: // Portuguese
        return {
          'billionaire':
              'O que acontece quando você ajuda um estranho... e descobre que ele pode mudar sua vida para sempre?',
          'betrayal':
              'Algumas verdades deveriam permanecer enterradas. Esta é a história de quando descobri a minha.',
          'secret':
              'Todo mundo tem segredos. O problema é quando eles começam a te caçar.',
          'family':
              'As últimas palavras que ela me disse mudaram tudo. Eu só queria ter ouvido antes.',
          'emotional':
              'Eu nunca choro. Mas essa história... essa história me quebrou.',
          'medical':
              'O médico chamou de milagre. Eu chamo de o dia em que tudo mudou.',
          'work':
              'Meu chefe riu quando me demitiu. Ele parou de rir três meses depois.',
          'horror':
              'Eu costumava pensar que monstros eram só histórias. Isso foi antes de conhecer um.',
          'romance':
              'Dizem que você só ama de verdade uma vez. Eu acreditava nisso... até aquele dia.',
          'generic':
              'Esta história mudou tudo o que eu pensava saber sobre confiança.',
        };
    }
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

  // ================== PROMPTS DE RECUPERAÇÃO ==================

  /// 🔄 Cria prompt de recuperação para incorporar elementos faltantes
  ///
  /// Usado quando a validação detecta que elementos-chave do título
  /// não apareceram na história gerada.
  ///
  /// [title]: Título original da história
  /// [missingElements]: Lista de elementos que faltam
  /// [context]: Contexto dos últimos blocos da história
  /// [language]: Idioma do roteiro
  ///
  /// Retorna: Prompt formatado para gerar bloco de recuperação
  static String buildRecoveryPrompt(
    String title,
    List<String> missingElements,
    String context,
    String language,
  ) {
    // Mapear idioma para instruções
    final languageInstructions = {
      'pt': 'em português brasileiro',
      'en': 'in English',
      'es': 'en español',
      'ko': '한국어로',
    };

    final langCode = language.toLowerCase().length >= 2
        ? language.toLowerCase().substring(0, 2)
        : language.toLowerCase();
    final langInstruction =
        languageInstructions[langCode] ?? 'in the same language as the title';

    final contextPreview = context.length > 800
        ? context.substring(context.length - 800)
        : context;

    return '''
🎯 MISSÃO DE RECUPERAÇÃO: Adicionar elementos faltantes à história

TÍTULO ORIGINAL: "$title"

ELEMENTOS QUE AINDA NÃO APARECERAM:
${missingElements.map((e) => '❌ $e').join('\n')}

CONTEXTO FINAL DA HISTÓRIA ATÉ AGORA:
---
$contextPreview
---

TAREFA:
Escreva UM PARÁGRAFO FINAL (100-150 palavras) $langInstruction que:
✅ Incorpore TODOS os elementos faltantes de forma NATURAL
✅ Seja uma continuação FLUIDA do contexto acima
✅ Mantenha coerência com a história existente
✅ NÃO repita eventos já narrados

❌ PROIBIDO:
- Começar nova história do zero
- Ignorar o contexto fornecido
- Usar "CONTINUAÇÃO:", "CONTEXTO:", etc.
- Adicionar mais de 200 palavras

APENAS o parágrafo final. Comece direto:
''';
  }

  // ================== CTA PROMPTS ==================

  static String buildAdvancedCtaPrompt(
    String scriptContent,
    List<String> ctaTypes,
    String? customTheme,
    String language,
    String scriptContext,
    String perspective, // PERSPECTIVA CONFIGURADA PELO USUÁRIO
  ) {
    final ctaDescriptions = getCtaTypeDescriptions(language);
    final requestedTypes = ctaTypes
        .map(
          (type) =>
              '"$type": ${ctaDescriptions[type] ?? "Call-to-action personalizado"}',
        )
        .join('\n');

    // 🔍 USAR PERSPECTIVA CONFIGURADA PELO USUÁRIO (não detectar)
    final isPrimeiraPessoa = perspective.contains('primeira_pessoa');

    if (kDebugMode) {
      debugPrint('🔍 Perspectiva Configurada pelo Usuário: $perspective');
      debugPrint(
        '   👉 ${isPrimeiraPessoa ? "PRIMEIRA PESSOA" : "TERCEIRA PESSOA"}',
      );
    }

    final perspectiveInstruction = isPrimeiraPessoa
        ? '''
+----------------------------------------------------------------+
│ 👤 OBRIGATÓRIO: PRIMEIRA PESSOA - NARRADOR = PROTAGONISTA     │
+----------------------------------------------------------------+

O NARRADOR É O PROTAGONISTA CONTANDO SUA PRÓPRIA HISTÓRIA.

⚠️ REGRA ABSOLUTA: CTAs devem falar como se o PERSONAGEM estivesse pedindo apoio.

✅ CAPITALIZAÇÃO CORRETA:
- "eu", "meu/minha" (MINÚSCULAS no meio da frase!)
- "Eu" (Maiúscula APENAS no início da frase)
- ❌ ERRADO: "EU pensei", "MEU filho", "MINHA casa"
- ✅ CERTO: "Eu pensei", "meu filho", "minha casa"

✅ PALAVRAS OBRIGATÓRIAS:
- "eu", "meu/minha", "minha história", "meu relato", "comigo", "me"

✅ EXEMPLOS CORRETOS (Primeira Pessoa):
• CTA INÍCIO: "Eu estava sem-teto e herdei 47 milhões. Mas a fortuna veio com um diário de vingança. Inscreva-se e deixe seu like para ver onde isso me levou."
• CTA INÍCIO: "Um estranho na rua mudou minha vida em um segundo. Quer saber o que ele me ofereceu? Inscreva-se e deixe seu like!"
• CTA MEIO: "O que você faria no meu lugar? Descobri que meu tio foi traído pelo próprio irmão. Comente o que você acha e compartilhe."
• CTA FINAL: "Minha jornada da rua à redenção acabou. O que você achou dessa reviravolta? Inscreva-se para mais histórias intensas como esta."

❌ PROIBIDO (quebra a perspectiva):
• Falar sobre "o protagonista", "ele/ela", "a história dele/dela"
• Usar "esta história" → Use "minha história"
• Usar nomes próprios em 3ª pessoa → Use "eu/meu"
• Capitalizar tudo: "EU/MEU/MINHA" → Use "eu/meu/minha"
• ⚠️ NUNCA use "Se essa reviravolta ME atingiu" → O narrador ESTÁ vivendo a história, não assistindo!
• ⚠️ NUNCA use "Se isso TE impactou..." sem contexto específico → Muito genérico!
'''
        : '''
+----------------------------------------------------------------+
│ 👁️ OBRIGATÓRIO: TERCEIRA PESSOA - NARRADOR EXTERNO ENVOLVENTE │
+----------------------------------------------------------------+

O NARRADOR É UM OBSERVADOR EXTERNO contando a história de outras pessoas.

⚠️ REGRA ABSOLUTA: CTAs devem falar dos PERSONAGENS de forma externa, MAS mantendo a INTENSIDADE EMOCIONAL do roteiro!

✅ CAPITALIZAÇÃO CORRETA:
- "esta/esse/essa" (minúsculas no meio da frase!)
- "Esta/Este/Essa" (Maiúscula APENAS no início da frase)
- Nomes próprios sempre com inicial maiúscula: "Kátia", "William"

✅ PALAVRAS OBRIGATÓRIAS:
- Nomes dos personagens (Kátia, William, etc.)
- "ela/dele", "esta história"
- Tom DRAMÁTICO, não jornalístico!

✅ EXEMPLOS CORRETOS (Terceira Pessoa ENVOLVENTE):
• "Kátia descobriu que seu próprio filho transformou sua casa em uma arma. Se esta traição te chocou, inscreva-se e deixe seu like"
• "William escondeu segredos nas paredes por anos. O que você faria no lugar de Kátia? Comente o que está achando"
• "A história de Kátia chegou ao fim com um desfecho poderoso. O que você achou? Inscreva-se para mais histórias como esta"
• "Esta família foi destroçada pela vingança. Compartilhe com quem entende dor de verdade"

❌ EXEMPLOS RUINS (muito formais/distantes):
• "A jornada de [personagem] revelou..." → Parece documentário chato
• "Narrativas que exploram..." → Parece crítica literária
• "Compartilhe esta história com quem aprecia..." → Muito genérico

❌ PROIBIDO (quebra a perspectiva):
• Usar "eu", "meu/minha", "comigo" → Isso é primeira pessoa!
• "Se minha história te tocou" → Use "Se a história de [personagem] te tocou"
• "O que você faria no meu lugar?" → Use "no lugar de [personagem]"

⚠️ REGRA DE OURO: Use DETALHES ESPECÍFICOS DO ROTEIRO nos CTAs!
- Não diga "segredo chocante" → Diga "dispositivo de metal corrosivo nas paredes"
- Não diga "decisão difícil" → Diga "expulsar o próprio filho de casa"
- Não diga "jornada emocional" → Diga "descobrir que seu filho é um vingador"
''';

    // 🐛 CORREÇÃO CRÍTICA: Enviar INÍCIO + FINAL do roteiro
    // Para que CTAs de início usem detalhes iniciais E CTAs finais reflitam o desfecho real
    final scriptLength = scriptContent.length;
    final initialChunk = scriptContent.substring(
      0,
      scriptLength > 2000 ? 2000 : scriptLength,
    );

    // Extrair últimos 1500 caracteres (para CTA final analisar o desfecho)
    final finalChunk = scriptLength > 1500
        ? scriptContent.substring(scriptLength - 1500)
        : ''; // Se roteiro for muito curto, final chunk fica vazio

    return '''
🛑🛑🛑 REGRA #0: IDIOMA OBRIGATÓRIO - $language 🛑🛑🛑
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ERRO CRÍTICO REAL DETECTADO EM GERAÇÕES ANTERIORES:

❌ ROTEIRO em Français (French), mas CTAs em Português (PT-BR):
   Roteiro: "ma femme m'a quitté pour son patron..."
   CTA ERRADO: "De um professor humilhado a uma fortuna que apaga o passado..."
   👉 IDIOMA INCONSISTENTE! CTA REJEITADO! 🚫

✅ REGRA ABSOLUTA DE IDIOMA:
   • Se roteiro está em $language → TODOS os CTAs em $language
   • ZERO palavras em outro idioma
   • ZERO mistura de idiomas
   • 100% pureza linguística!

🔍 VALIDAÇÃO ANTES DE GERAR:
   1. 🤔 "O roteiro está em $language?"
   2. 🤔 "Vou escrever os CTAs em $language?"
   3. 🤔 "Há alguma palavra em outro idioma nos meus CTAs?"
   👉 Se SIM na pergunta 3 = PARE! Reescreva em $language!

⚠️ CUIDADO ESPECIAL - ERROS COMUNS POR IDIOMA:
   • English → Não misture: português ("mas", "quando"), espanhol ("pero")
   • Français → Não misture: português ("mas", "de", "para"), inglês ("but", "from")
   • Español → Não misture: português ("mas", "quando"), inglês ("but", "when")
   • Português → Não misture: inglês ("but", "when"), espanhol ("pero", "cuando")

🛑 SE HOUVER UMA ÚNICA PALAVRA EM OUTRO IDIOMA, TODOS OS CTAs SERÃO REJEITADOS!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🛑🛑🛑 ATENÇÃO CRÍTICA: PERSPECTIVA NARRATIVA É A REGRA #1 🛑🛑🛑

$perspectiveInstruction

---------------------------------------------------------------

Gere CTAs (calls-to-action) personalizados em $language para este roteiro.

CONTEXTO DO ROTEIRO: $scriptContext
TEMA PERSONALIZADO: ${customTheme ?? 'Não especificado'}

ROTEIRO - TRECHO INICIAL (para CTAs de início/meio):
$initialChunk

${finalChunk.isNotEmpty ? '''
---------------------------------------------------------------
ROTEIRO - TRECHO FINAL (para CTA de conclusão):
$finalChunk
---------------------------------------------------------------
''' : ''}
---------------------------------------------------------------
🎯 PROPÓSITO ESPECÍFICO DE CADA TIPO DE CTA:
---------------------------------------------------------------

🔔 "subscription" (CTA DE INÍCIO):
   • Objetivo: Pedir INSCRIÇÃO no canal + LIKE
   • Momento: Logo no INÍCIO da história, após o gancho inicial
   
   ⚠️ ERRO COMUM A EVITAR:
   ❌ "Se essa reviravolta ME atingiu..." → Narrador falando de si mesmo em 3ª pessoa (ERRADO!)
   ❌ "Se essa reviravolta TE atingiu..." → Muito genérico, sem gancho específico
   ❌ "No meu aniversário, meu marido levou tudo..." → NÃO REPITA A PRIMEIRA FRASE DO ROTEIRO! (ERRO FATAL!)
   
   ✅ REGRA CRÍTICA - EXTRAIR DETALHES DO ROTEIRO:
   👉 PROIBIDO copiar ou parafrasear a primeira frase do roteiro
   👉 PROIBIDO usar frases genéricas desconectadas do conteúdo
   👉 OBRIGATÓRIO ler os primeiros 3-5 parágrafos e extrair:
      • Objetos específicos mencionados (bolo, tapete persa, envelope, carro, etc.)
      • Ações concretas (ele saiu, ela encontrou, queimaram, esconderam)
      • Nomes de personagens secundários que aparecem logo no início
      • Locações específicas (sala vazia, escritório, rua X)
   👉 Use ESSES detalhes para criar o gancho (não invente detalhes!)
   
   ✅ MÉTODO CORRETO - ANÁLISE DO INÍCIO DO ROTEIRO:
   1. Leia os primeiros 3-5 parágrafos do roteiro
   2. Liste mentalmente: Quais objetos? Quais ações? Quais nomes?
   3. Escolha 2-3 detalhes MARCANTES (não a primeira frase)
   4. Monte o CTA usando ESSES detalhes específicos
   
   • Exemplo ERRADO (genérico, desconectado):
     ❌ "Minha vida virou do avesso. Inscreva-se para ver o que aconteceu."
   
   • Exemplo CERTO (detalhes reais do roteiro):
     ✅ "Eles levaram tudo, até o tapete persa que herdei. Mas esqueceram meu celular com a gravação. Inscreva-se e deixe seu like para ver minha vingança."
     ✅ "Um bolo de 45 velinhas intacto, uma casa vazia e um envelope pardo. Inscreva-se para descobrir como transformei essa traição em justiça."
   
   👉 ESTRUTURA CORRETA:
   [2-3 detalhes específicos DO ROTEIRO] + [Promessa de reviravolta/vingança] + "Inscreva-se e deixe seu like"
   
   • Exemplo (1ª pessoa): "Encontrei documentos escondidos no sótão e uma chave que não reconheci. Inscreva-se e deixe seu like para descobrir o que eles revelaram."
   • Exemplo (3ª pessoa): "Kátia descobriu um dispositivo nos canos instalado pelo próprio filho. Inscreva-se para ver sua vingança."

💬 "engagement" (CTA DE MEIO):
   • Objetivo: Pedir COMENTÁRIOS sobre o que estão achando + COMPARTILHAMENTOS
   • Momento: No MEIO da história, após uma reviravolta importante
   • Estrutura: Pergunta direta sobre opinião + "comente o que está achando" + "compartilhe"
   • Exemplo (1ª pessoa): "O que você faria no meu lugar? Comente o que está achando dessa situação e compartilhe com quem entenderia."
   • Exemplo (3ª pessoa): "O que você acha da decisão de Kátia? Comente o que está achando e compartilhe com amigos."

🏁 "final" (CTA DE CONCLUSÃO):
   • Objetivo: CTA CONCLUSIVO - história acabou, pedir FEEDBACK + INSCRIÇÃO para mais histórias
   • Momento: No FINAL da história, após a resolução
   
   🛑🛑🛑 ERRO CRÍTICO QUE VOCÊ COMETE SEMPRE:
   ❌ "Levaram tudo... O que você achou dessa frieza?" → Fala como se protagonista ainda estivesse PERDENDO!
   ❌ "Eles me destruíram... Inscreva-se..." → Ignora que a história JÁ TEVE RESOLUÇÃO!
   ❌ Focar na TRAGÉDIA INICIAL em vez do DESFECHO REAL!
   
   ✅ REGRA ABSOLUTA - CTA DEVE REFLETIR O FINAL REAL:
   👉 OBRIGATÓRIO usar o TRECHO FINAL DO ROTEIRO fornecido acima
   👉 Identificar o DESFECHO REAL no trecho final:
      • Protagonista venceu? → CTA de VITÓRIA
      • Protagonista perdeu? → CTA de DERROTA
      • Final ambíguo? → CTA de REFLEXÃO
   👉 Mencionar COMO a história terminou (prisão do vilão, vingança concluída, fuga, morte, reconciliação)
   
   ✅ MÉTODO CORRETO - ANÁLISE DO TRECHO FINAL:
   1. Leia o TRECHO FINAL DO ROTEIRO fornecido acima
   2. Pergunte: "Como a protagonista está AGORA?"
      • Vencedora? → "Consegui fazer justiça"
      • Destruída? → "Perdi tudo"
      • Reconstruindo? → "Estou começando de novo"
   3. O CTA deve COMBINAR com esse estado final!
   
   👉 EXEMPLO ERRADO (final de vitória com CTA de derrota):
   Final do roteiro: "Marcos foi preso. Recuperei meu dinheiro. Era justiça."
   CTA ERRADO: "Levaram tudo e me deixaram sem nada. O que você achou?" ❌
   
   👉 EXEMPLO CERTO (final de vitória com CTA de vitória):
   Final do roteiro: "Marcos foi preso. Recuperei meu dinheiro. Era justiça."
   CTA CERTO: "Da casa vazia à prisão dele. Recuperei tudo e o coloquei atrás das grades. O que você achou da minha vingança? Inscreva-se para mais histórias de justiça como esta." ✅
   
   👉 ESTRUTURA CORRETA:
   [Resumo do DESFECHO REAL] + [Mencionar resultado final] + "O que você achou?" + "Inscreva-se para mais histórias"
   
   • Exemplo (final de vitória - 1ª pessoa): 
     ✅ "De vítima a vencedora. Ele está preso, eu recuperei o que era meu. O que você achou dessa virada? Inscreva-se para mais histórias de vingança como esta."
   
   • Exemplo (final de derrota - 1ª pessoa):
     ✅ "Perdi tudo, mas ganhei minha liberdade. Às vezes, recomeçar é a única vitória possível. O que você achou? Inscreva-se para mais histórias intensas."
   
   • Exemplo (final ambíguo - 3ª pessoa):
     ✅ "Kátia expulsou o filho, mas a casa ficou vazia. Será que valeu a pena? O que você acha? Inscreva-se para mais dilemas como este."
   
   ✅ CHECKLIST DO CTA FINAL:
   ☑️ Li o TRECHO FINAL DO ROTEIRO fornecido acima?
   ☑️ Identifiquei se protagonista venceu/perdeu/ficou no meio-termo?
   ☑️ Meu CTA reflete esse desfecho REAL?
   ☑️ Mencionei o resultado concreto (prisão, vitória, perda, fuga)?
   ☑️ Não estou falando da tragédia inicial quando a história já teve resolução?

---------------------------------------------------------------

GERE OS SEGUINTES TIPOS DE CTA:
$requestedTypes

---------------------------------------------------------------

FORMATO DE RESPOSTA (JSON):
{
  "subscription": "texto do CTA aqui",
  "engagement": "texto do CTA aqui",
  "pre_conclusion": "texto do CTA aqui",
  "final": "texto do CTA aqui"
}

---------------------------------------------------------------

REQUISITOS OBRIGATÓRIOS:
1. 👁️ PERSPECTIVA NARRATIVA É PRIORIDADE #1 - RELEIA AS INSTRUÇÕES NO TOPO AGORA!
2. ✅ CAPITALIZAÇÃO CORRETA - "eu/meu/minha" em MINÚSCULAS (não "EU/MEU/MINHA")!
3. 🎯 CADA CTA TEM UM PROPÓSITO ESPECÍFICO - Releia a seção "PROPÓSITO ESPECÍFICO" acima!
   • subscription = inscrição + like
   • engagement = comentários + compartilhamento
   • final = feedback + inscrição para mais histórias
4. 🔔 CTA DE INÍCIO: Extraia detalhes REAIS do TRECHO INICIAL fornecido (objetos, ações, nomes)
5. 🏁 CTA FINAL: Use o TRECHO FINAL fornecido e reflita o DESFECHO REAL (vitória/derrota/recomeço)
6. 🚫 PROIBIDO usar palavras genéricas: "jornada", "narrativa", "explorar", "revelar"
7. ⚠️ OBRIGATÓRIO mencionar ELEMENTOS CHOCANTES: nomes, objetos, ações específicas
8. Cada CTA: 25-45 palavras (DIRETO E IMPACTANTE, com espaço para CTAs completos)
9. Linguagem VISCERAL e DRAMÁTICA em $language (não formal/acadêmica)
10. Tom emocional IGUAL ao do roteiro (se é intenso, CTA é intenso; se é suave, CTA é suave)
11. Se protagonista tomou DECISÃO EXTREMA (expulsar filho, confrontar vilão), mencione isso!
12. NÃO prometa eventos futuros que já aconteceram no roteiro
13. Retorne JSON válido apenas

🛑🛑🛑 CHECKLIST FINAL - RESPONDA ANTES DE GERAR: 🛑🛑🛑
❓ 🌐 TODOS os CTAs estão 100% em $language (ZERO palavras em outro idioma)?
❓ Reli as instruções de PERSPECTIVA NARRATIVA no topo?
❓ ${isPrimeiraPessoa ? "Vou usar 'eu/meu/minha' em MINÚSCULAS (não EU/MEU/MINHA)?" : "Vou usar nomes próprios/ela/ele/esta história?"}
❓ Cada CTA segue seu PROPÓSITO ESPECÍFICO?
  • subscription = inscrição + like?
  • engagement = comentários + compartilhamento?
  • final = feedback + inscrição para mais histórias?
❓ No CTA DE INÍCIO: Extraí detalhes REAIS do TRECHO INICIAL fornecido (objetos, ações, nomes)?
❓ No CTA DE INÍCIO: NÃO repeti/parafraseei a primeira frase do roteiro?
❓ No CTA FINAL: Li o TRECHO FINAL DO ROTEIRO fornecido e identifiquei o DESFECHO REAL?
❓ No CTA FINAL: Meu CTA reflete se protagonista venceu/perdeu/está recomeçando?
❓ Mencionei DETALHES ESPECÍFICOS do roteiro (nomes, objetos-chave, ações concretas)?
❓ EVITEI palavras genéricas ("jornada", "narrativa", "revelar", "explorar")?
❓ O tom do CTA está TÃO INTENSO quanto o roteiro?
❓ Formato JSON está correto?

⚠️ ERROS FATAIS A EVITAR NO CTA DE INÍCIO:
❌ "Se essa reviravolta ME atingiu, inscreva-se..." → Narrador falando de si em 3ª pessoa!
❌ "Se essa história TE impactou..." → Muito genérico, sem gancho!
❌ "No meu aniversário, meu marido levou tudo..." → NUNCA REPITA A PRIMEIRA FRASE DO ROTEIRO! (ERRO CRÍTICO!)
❌ Copiar ou parafrasear a frase de abertura do roteiro → Use OUTROS detalhes específicos!
❌ Frases genéricas desconectadas do texto → Leia os primeiros parágrafos e extraia objetos/ações REAIS!
✅ CORRETO: Extrair 2-3 detalhes específicos dos primeiros parágrafos + promessa de reviravolta
• Exemplo: "Eles levaram até o tapete persa. Mas esqueceram meu celular com a gravação. Inscreva-se para ver minha vingança."
• Exemplo: "45 velinhas, um bolo intacto e documentos escondidos no sótão. Inscreva-se para descobrir o que eles revelaram."

⚠️ ERROS FATAIS A EVITAR NO CTA FINAL:
❌ "Levaram tudo... O que você achou dessa frieza?" → Fala do início quando história já teve resolução!
❌ Ignorar o desfecho real e focar na tragédia inicial → Use o TRECHO FINAL fornecido!
❌ CTA de vítima quando protagonista VENCEU → Desonesto com a história!
❌ CTA de vitória quando protagonista PERDEU → Também desonesto!

⚠️ ERRO REAL DETECTADO - AMBIGUIDADE FATAL:
❌ "Da caixa de papelão aos portões da prisão" → Quem foi preso? Protagonista ou vilão?
   • Se VILÃO foi preso: "Da caixa de papelão ao império - e ele atrás das grades"
   • Se PROTAGONISTA foi preso: "Da caixa de papelão à prisão - minha vingança falhou"
   
❌ "Do fracasso à redenção" → Redenção de quem? Protagonista ou antagonista?
   • SEMPRE especifique: "Do fracasso à MINHA redenção" ou "Do fracasso à redenção DELE"

✅ REGRA ABSOLUTA DE CLAREZA:
   • CTAs finais DEVEM especificar quem sofreu/venceu
   • Use "EU" (1ª pessoa) ou NOME/ELE/ELA (3ª pessoa)
   • Nunca deixe ambíguo quem foi preso/derrotado/venceu
   
✅ CORRETO: Resumir o DESFECHO REAL do TRECHO FINAL (prisão, vingança concluída, perda, recomeço)
• Exemplo (vitória): "Da casa vazia à prisão DELE. Recuperei tudo e o coloquei atrás das grades. O que você achou?"
• Exemplo (derrota): "Perdi tudo, mas ganhei liberdade. Recomeçar é a única vitória. O que você achou?"
• Exemplo (vitória 3ª pessoa): "Robert passou de mendigo a milionário - e Marcus está na cadeia. O que você achou?"

🛑 SE VOCÊ USAR LINGUAGEM GENÉRICA, CAPITALIZAÇÃO ERRADA, QUEBRAR A PERSPECTIVA OU MISTURAR IDIOMAS, O CTA SERÁ REJEITADO! 🛑

🛑🛑🛑 VALIDAÇÃO FINAL DE IDIOMA ANTES DE ENVIAR: 🛑🛑🛑
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ANTES DE ENVIAR O JSON, RELEIA CADA CTA E PERGUNTE:
❓ "Este CTA está 100% em $language?"
❓ "Há alguma palavra em português/inglês/espanhol/francês (outro idioma)?"
❓ "Se o roteiro é em français, meus CTAs estão em français?"
❓ "Se o roteiro é em english, meus CTAs estão em english?"

SE VOCÊ ENCONTRAR UMA PALAVRA EM IDIOMA ERRADO:
🛑 PARE AGORA!
🛑 REESCREVA O CTA INTEIRO EM $language!
🛑 NÃO ENVIE COM IDIOMA MISTURADO!

⚠️ EXEMPLOS DE ERROS FATAIS:
❌ Roteiro em French, CTA: "De um professor humilhado..." → Português! ERRO!
❌ Roteiro em Spanish, CTA: "But when everything changed..." → Inglês! ERRO!
❌ Roteiro em English, CTA: "mas quando tudo mudou..." → Português! ERRO!

✅ VALIDAÇÃO PASSOU SE:
• Cada CTA usa APENAS palavras de $language
• ZERO palavras de outro idioma
• Linguagem 100% coerente com o roteiro

🛑 LEMBRE-SE: Um único erro de idioma invalida TODOS os CTAs! 🛑
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXEMPLOS DE DETALHES ESPECÍFICOS (use este nível de concretude):
❌ RUIM: "A protagonista descobriu um segredo"
✅ BOM: "Kátia encontrou um dispositivo corrosivo escondido nos canos por William"

❌ RUIM: "Uma decisão difícil foi tomada"
✅ BOM: "Kátia expulsou o próprio filho de casa após descobrir sua vingança"

❌ RUIM: "Se esta história te impactou"
✅ BOM: "Se a traição de William dentro das paredes te chocou"
''';
  }

  static Map<String, String> getCtaTypeDescriptions(String language) {
    return {
      'subscription': 'CTA para inscrição no canal',
      'engagement': 'CTA para interação (like, comentário)',
      'pre_conclusion': 'CTA antes da conclusão',
      'final': 'CTA de fechamento',
    };
  }

  // ================== VIRAL HOOK GENERATION ==================

  /// 🎣 Gera o prompt para criar um gancho viral de alta retenção
  /// Usado apenas quando startWithTitlePhrase = false
  static String buildViralHookPrompt({
    required String title,
    required String tema,
    required String language,
  }) {
    return """
ROLE: Especialista em YouTube e Copywriting Viral (Estilo MrBeast/Canais Dark).
TAREFA: Criar um "Hook" (Gancho de Retenção) para os primeiros 5 segundos deste vídeo.

DADOS DO VÍDEO:
- Título: "$title"
- Tema: "$tema"
- Idioma: "$language"

INSTRUÇÃO DE PENSAMENTO (Oculto):
1. Analise o título e crie 3 opções mentais: uma pergunta chocante, uma afirmação polêmica ou um mistério imediato.
2. Selecione a MELHOR opção (a que gera mais curiosidade e retenção).
3. O texto deve ser curto, direto e impactante (máximo 2 frases).

SAÍDA FINAL (Obrigatório):
Escreva APENAS o texto do gancho escolhido no idioma "$language". 
NÃO coloque aspas, NÃO coloque "Opção 1". Apenas a frase pronta para o narrador ler.
""";
  }
}
