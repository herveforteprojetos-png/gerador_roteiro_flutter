import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/services/gemini/tracking/character_tracker.dart';
import 'package:flutter_gerador/data/services/scripting/world_state_manager.dart';
import 'package:flutter_gerador/data/services/prompts/base_rules.dart';
import 'package:flutter_gerador/data/services/prompts/main_prompt_template.dart';
import 'package:flutter_gerador/data/services/gemini/utils/perspective_utils.dart';
import 'package:flutter_gerador/data/services/scripting/script_prompt_builder.dart';
import 'package:flutter_gerador/data/services/scripting/narrative_style_manager.dart';
import 'package:flutter_gerador/data/services/prompts/structure_rules.dart';

class BlockPromptBuilder {
  /// Constrói o prompt completo para um bloco de roteiro
  static Future<String> buildBlockPrompt({
    required String previous,
    required int target,
    required String phase,
    required ScriptConfig c,
    required CharacterTracker tracker,
    required int blockNumber,
    required int totalBlocks,
    bool avoidRepetition = false,
    WorldState? worldState,
  }) async {
    // 🎯 IMPORTANTE: target vem SEMPRE em PALAVRAS
    final needed = target;
    if (needed <= 0) return '';

    // 🆕 v7.6.142: Calcular palavras totais acumuladas até agora
    final currentTotalWords = _countWords(previous);

    // 🚀 OTIMIZAÇÃO CRÍTICA: Limitar contexto aos últimos N blocos
    final isPortuguese = c.language.toLowerCase().contains('portugu');
    final maxContextBlocks = isPortuguese ? 3 : 4;

    // Blocos iniciais (1-4): contexto completo
    // Blocos médios/finais (5+): últimos N blocos apenas
    String contextoPrevio = previous.isEmpty
        ? ''
        : buildLimitedContext(previous, blockNumber, maxContextBlocks);

    if (kDebugMode && previous.isNotEmpty) {
      final contextUsed = contextoPrevio.length;
      final contextType = blockNumber <= maxContextBlocks
          ? 'COMPLETO'
          : 'LIMITADO (últimos $maxContextBlocks blocos)';
      debugPrint(
        '📝 CONTEXTO $contextType: $contextUsed chars (${_countWords(contextoPrevio)} palavras)',
      );
    }

    // 🛡️ SOLUÇÃO 3: Reforçar os nomes confirmados no prompt para manter consistência
    String trackerInfo = '';

    // 🧠 v7.6.36: LEMBRETE CRÍTICO DE NOMES - Muito mais agressivo!
    if (tracker.confirmedNames.isNotEmpty && blockNumber > 1) {
      final nameReminder = StringBuffer();
      nameReminder.writeln('');
      nameReminder.writeln(
        '🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑',
      );
      nameReminder.writeln(
        '⚠️ LEMBRETE OBRIGATÓRIO DE NOMES - LEIA ANTES DE CONTINUAR! ⚠️',
      );
      nameReminder.writeln(
        '🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑',
      );
      nameReminder.writeln('');
      nameReminder.writeln(
        '👥 PERSONAGENS DESTA HISTÓRIA (USE SEMPRE ESTES NOMES):',
      );
      nameReminder.writeln('');

      // Listar cada personagem com seu papel de forma MUITO clara
      for (final name in tracker.confirmedNames) {
        final role = tracker.getRole(name) ?? 'personagem';
        nameReminder.writeln('   👉 $name = $role');
      }

      nameReminder.writeln('');
      nameReminder.writeln('🚫 PROIBIDO MUDAR ESTES NOMES! 🚫');
      nameReminder.writeln('');

      // Adicionar protagonista de forma EXTRA enfática
      final protagonistName = c.protagonistName.trim();
      if (protagonistName.isNotEmpty) {
        nameReminder.writeln(
          '👑 A PROTAGONISTA/NARRADORA SE CHAMA: $protagonistName',
        );
        nameReminder.writeln('   👉 Quando ela fala de si mesma: "i" ou "me"');
        nameReminder.writeln(
          '   👉 Quando outros falam dela: "$protagonistName"',
        );
        nameReminder.writeln(
          '   🚫 NUNCA mude para Emma, Jessica, Lauren, Sarah, etc!',
        );
        nameReminder.writeln('');
      }

      // Listar mapeamento reverso (papel -> nome) para reforçar
      final roleMap = tracker.roleToNameMap;
      if (roleMap.isNotEmpty) {
        nameReminder.writeln('🗺️ MAPEAMENTO PAPEL → NOME (CONSULTE SEMPRE):');
        for (final entry in roleMap.entries) {
          nameReminder.writeln('   • ${entry.key} → ${entry.value}');
        }
        nameReminder.writeln('');
      }

      nameReminder.writeln(
        '⚠️ SE VOCÊ TROCAR UM NOME, O ROTEIRO SERÁ REJEITADO! ⚠️',
      );
      nameReminder.writeln(
        '🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑',
      );
      nameReminder.writeln('');

      trackerInfo = nameReminder.toString();
    } else if (tracker.confirmedNames.isNotEmpty) {
      // Bloco 1: lista mais simples
      trackerInfo =
          '\n⚠️ NOMES JÁ USADOS - NUNCA REUTILIZE: ${tracker.confirmedNames.join(", ")}\n';
      trackerInfo +=
          '💡 Se precisa de novo personagem, use NOME TOTALMENTE DIFERENTE!\n';

      final mapping = tracker.getCharacterMapping();
      if (mapping.isNotEmpty) {
        trackerInfo += mapping;
        trackerInfo +=
            '\n⚠️ REGRA CRÍTICA: NUNCA use o mesmo nome para personagens diferentes!\n';
      }
    }

    // 🛡️ CORREÇÃO CRÍTICA: SEMPRE injetar nome da protagonista
    final protagonistName = c.protagonistName.trim();
    if (protagonistName.isNotEmpty && !trackerInfo.contains(protagonistName)) {
      trackerInfo +=
          '\n⚠️ ATENÇÃO ABSOLUTA: O NOME DA PROTAGONISTA É "$protagonistName"!\n';
      trackerInfo += '   👉 NUNCA mude para outro nome (Wanessa, Carla, etc)\n';
      trackerInfo +=
          '   👉 SEMPRE use "$protagonistName" quando se referir à protagonista!\n';
    }
    final characterGuidance = buildCharacterGuidance(c, tracker);

    // 🌍 v7.6.52: WORLD STATE CONTEXT - Memória Infinita
    // 🔧 v7.6.147: Passa blockNumber para otimizar fatos nos blocos finais
    String worldStateContext = '';
    if (worldState != null && blockNumber > 1) {
      worldStateContext = worldState.getContextForPrompt(
        currentBlock: blockNumber,
      );
    }

    // 📏 IMPORTANTE: Limitar palavras por bloco para estabilidade
    final limitedNeeded = min(needed, 3500);

    // 🌍 AJUSTE POR IDIOMA: Compensar verbosidade natural de cada idioma
    final languageMultiplier = getLanguageVerbosityMultiplier(c.language);
    final adjustedTarget = (limitedNeeded * languageMultiplier).round();

    final isSpanish =
        c.language.toLowerCase().contains('espanhol') ||
        c.language.toLowerCase().contains('spanish') ||
        c.language.toLowerCase().contains('español');

    // 🆕 v7.6.142: CONTADOR PROGRESSIVO - Mostrar situação do Ato atual
    final actInfo = StructureRules.getActInfo(
      currentTotalWords: currentTotalWords,
      targetTotalWords: c.quantity,
    );

    // 📊 Log do contador progressivo
    if (kDebugMode) {
      debugPrint('');
      debugPrint(
        '📊 ════════════════════════════════════════════════════════════',
      );
      debugPrint('📊 CONTADOR PROGRESSIVO - Bloco $blockNumber/$totalBlocks');
      debugPrint(
        '📊 ════════════════════════════════════════════════════════════',
      );
      debugPrint('📍 Ato: ${actInfo.actNumber} - ${actInfo.actName}');
      debugPrint(
        '📈 Palavras do Ato: ${actInfo.actCurrentWords}/${actInfo.actMaxWords}',
      );
      debugPrint('⏳ Restantes: ${actInfo.actRemainingWords} palavras');
      debugPrint('📊 Total acumulado: $currentTotalWords palavras');
      if (actInfo.actNumber == 2 && actInfo.actRemainingWords < 300) {
        debugPrint('🚨 ALERTA: Ato 2 próximo do limite!');
      }
      if (actInfo.actNumber == 3 && actInfo.actRemainingWords > 500) {
        debugPrint('✅ Ato 3 com espaço suficiente');
      }
      debugPrint(
        '📊 ════════════════════════════════════════════════════════════',
      );
      debugPrint('');
    }

    // 🚨 Construir mensagem visual do contador
    final progressCounter = _buildProgressCounter(actInfo, isSpanish);

    // 📏 CONTROLE RIGOROSO DE CONTAGEM: ±8% aceitável
    final minAcceptable = (adjustedTarget * 0.92).round();
    final maxAcceptable = (adjustedTarget * 1.08).round();
    
    // 🚨 v7.6.157: LIMITE DE CARACTERES ajustado por idioma + AVISO ULTRA-AGRESSIVO
    final charsPerWord = getCharsPerWordForLanguage(c.language);
    final maxChars = (adjustedTarget * charsPerWord * 1.08).round(); // +8% margem

    final measure = isSpanish
        ? '🚨🚨🚨 EXTREMADAMENTE CRÍTICO 🚨🚨🚨\nGERE EXATAMENTE $adjustedTarget palabras (MÍNIMO $minAcceptable, MÁXIMO $maxAcceptable).\n\n⛔⛔⛔ LÍMITE ABSOLUTO: MÁXIMO $maxChars CARACTERES! ⛔⛔⛔\n❌ CUALQUIER RESPUESTA CON MÁS DE $maxChars CARACTERES SERÁ RECHAZADA AUTOMÁTICAMENTE!\n✅ RESPUESTAS CON MENOS DE $maxAcceptable PALABRAS TAMBIÉN SON ACEPTABLES SI EVITAN EXCEDER EL LÍMITE DE CARACTERES!\n\n⚠️ SI EL BLOQUE SE ESTÁ HACIENDO MUY LARGO, ¡TERMINE ANTICIPADAMENTE!'
        : '🚨🚨🚨 EXTREMAMENTE CRÍTICO 🚨🚨🚨\nGERE EXATAMENTE $adjustedTarget palavras (MÍNIMO $minAcceptable, MÁXIMO $maxAcceptable).\n\n⛔⛔⛔ LIMITE ABSOLUTO: MÁXIMO $maxChars CARACTERES! ⛔⛔⛔\n❌ QUALQUER RESPOSTA COM MAIS DE $maxChars CARACTERES SERÁ REJEITADA AUTOMATICAMENTE!\n✅ RESPOSTAS COM MENOS DE $maxAcceptable PALAVRAS TAMBÉM SÃO ACEITÁVEIS SE EVITAREM ULTRAPASSAR O LIMITE DE CARACTERES!\n\n⚠️ SE O BLOCO ESTÁ FICANDO MUITO LONGO, ENCERRE ANTECIPADAMENTE!';

    final localizationGuidance = BaseRules.buildLocalizationGuidance(c);
    final narrativeStyleGuidance = NarrativeStyleManager.getStyleGuidance(c);

    // 🎣 INTEGRAR TÍTULO COMO HOOK IMPACTANTE NO INÍCIO
    String instruction;
    String viralHookSection = '';

    if (previous.isEmpty) {
      // 🎣 v7.6.65: Gerar viral hook dinâmico para o primeiro bloco
      final viralHook = ScriptPromptBuilder.generateViralHook(
        title: c.title,
        tema: c.tema,
        language: c.language,
      );

      viralHookSection =
          '''

🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣
🎣 GANCHO VIRAL PARA ABERTURA (PRIMEIROS 5 SEGUNDOS)
🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣

📌 SUGESTÃO DE ABERTURA (adapte ao contexto):
"$viralHook"

✅ USE ESTE GANCHO OU CRIE UM SIMILAR QUE:
   • Desperte curiosidade IMEDIATA nos primeiros 5 segundos
   • Faça uma PROMESSA implícita ao espectador
   • Crie TENSÃO ou MISTÉRIO logo de cara
   • NÃO revele o final - apenas PROVOQUE

❌ EVITE ABERTURAS FRACAS:
   • "Esta é a história de..." (muito genérico)
   • "Era uma vez..." (muito infantil para YouTube)
   • "Vou te contar sobre..." (quebra imersão)
   • Descrições longas de cenário (perde atenção)

🎯 OBJETIVO: O espectador DEVE querer saber mais após a PRIMEIRA FRASE!
🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣🎣

''';

      if (c.startWithTitlePhrase && c.title.trim().isNotEmpty) {
        instruction = BaseRules.getStartInstruction(
          c.language,
          withTitle: true,
          title: c.title,
        );
      } else {
        instruction = BaseRules.getStartInstruction(
          c.language,
          withTitle: false,
        );
      }
    } else {
      instruction = BaseRules.getContinueInstruction(c.language);
    }

    // 🏷️ Obter labels traduzidos para os metadados
    final labels = BaseRules.getMetadataLabels(c.language);

    // 🏷️ Definir se inclui tema/subtema ou modo livre
    final temaSection = c.tema == 'Livre (Sem Tema)'
        ? '// Modo Livre: Desenvolva o roteiro baseado APENAS no título e contexto fornecidos\n'
        : '${labels['theme']}: ${c.tema}\n${labels['subtheme']}: ${c.subtema}\n';

    // 📌 v7.6.44: SEMPRE incluir título como base da história
    final titleSection = c.title.trim().isNotEmpty
        ? '\n📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌\n'
              '📢 TÍTULO/PREMISSA OBRIGATÓRIA DA HISTÓRIA:\n'
              '📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌\n'
              '"${c.title}"\n'
              '\n'
              '⚠️ REGRA ABSOLUTA:\n'
              '   • A história DEVE desenvolver os elementos deste título\n'
              '   • Personagens, ações e contexto do título são OBRIGATÓRIOS\n'
              '   • NÃO invente uma história diferente da proposta no título\n'
              '   • O título é a PROMESSA feita ao espectador - CUMPRA-A!\n'
              '\n'
              '💡 EXEMPLOS:\n'
              '   ✅ Título: "편의점 알바생이 배고픈 노인에게 도시락을 줬더니"\n'
              '      👉 História DEVE ter: funcionário de conveniência + idoso faminto + marmita compartilhada\n'
              '   \n'
              '   ✅ Título: "Bilionário me ofereceu emprego após eu ajudar um mendigo"\n'
              '      👉 História DEVE ter: protagonista + mendigo ajudado + revelação (mendigo = bilionário)\n'
              '   \n'
              '   ❌ ERRO: Ignorar título e criar história sobre CEO infiltrado em empresa\n'
              '      👉 Isso QUEBRA a promessa feita ao espectador!\n'
              '📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌📌\n\n'
        : '';

    // 🚫 CONSTRUIR LISTA DE NOMES PROIBIDOS (já usados nesta história)
    String forbiddenNamesWarning = '';
    if (tracker.confirmedNames.isNotEmpty) {
      final forbiddenList = tracker.confirmedNames.join(', ');
      forbiddenNamesWarning =
          '🚫🚫🚫 NOMES PROIBIDOS - NÃO USE ESTES NOMES! 🚫🚫🚫\n'
          '🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑\n'
          '⚠️ Os seguintes nomes JÁ ESTÃO EM USO nesta história:\n'
          '   👉 $forbiddenList\n'
          '\n'
          '⚠️ REGRA ABSOLUTA:\n'
          '   • NUNCA reutilize os nomes acima!\n'
          '   • Cada nome = 1 personagem único\n'
          '   • Se precisar de novo personagem, escolha nome DIFERENTE\n'
          '🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑\n'
          '\n';
    }

    // Personagens sem fechamento são agora gerenciados automaticamente pelo tracker

    '   \n'
        '   ✅ Se "Robert revelou que seu pai Harold foi enganado":\n'
        '      👉 No clímax: "Robert entrou no tribunal. Olhou Alan nos olhos..."\n'
        '      👉 No desfecho: "Robert finalmente tinha paz. A verdade sobre Harold veio à tona."\n'
        '   \n'
        '   ✅ Se "Kimberly, a paralegal, guardou cópias dos documentos":\n'
        '      👉 No clímax: "Kimberly testemunhou. \'Alan me ordenou falsificar a assinatura\'..."\n'
        '      👉 No desfecho: "Kimberly foi elogiada por sua coragem em preservar as evidências."\n'
        '   \n'
        '   ✅ Se "David, o contador, descobriu a fraude primeiro":\n'
        '      👉 No clímax: "David apresentou os registros financeiros alterados..."\n'
        '      👉 No desfecho: "David foi promovido a CFO após a queda de Alan."\n'
        '   \n'
        '   ❌ NUNCA faça isso:\n'
        '      • "Robert me deu o documento" → [nunca mais mencionado] → ERRO!\n'
        '      • "Kimberly tinha as provas" → [some da história] → ERRO!\n'
        '      • "David descobriu tudo" → [não aparece no final] → ERRO!\n'
        '\n'
        '⏱️ REGRAS DE MARCADORES TEMPORAIS:\n'
        '   • Entre mudanças de cena/localização: SEMPRE incluir marcador temporal\n'
        '   • Exemplos: "três dias depois...", "na manhã seguinte...", "uma semana se passou..."\n'
        '   • Flashbacks: iniciar com "anos atrás..." ou "naquele dia em [ano]..."\n'
        '   • Saltos grandes (meses/anos): ser específico: "seis meses depois" não "algum tempo depois"\n'
        '   • Isso mantém o leitor orientado na linha temporal da história\n'
        '\n'
        '👨‍👩‍👧‍👦 REGRAS DE COERÊNCIA DE RELACIONAMENTOS FAMILIARES:\n'
        '   ⚠️ ERRO CRÍTICO: Relacionamentos familiares inconsistentes!\n'
        '   \n'
        '   ANTES de introduzir QUALQUER relação familiar, VALIDE:\n'
        '   \n'
        '   ✅ CORRETO - Lógica familiar coerente:\n'
        '      • "meu irmão Paul casou com Megan" → Megan é minha CUNHADA\n'
        '      • "Paul é meu irmão" + "Megan é esposa de Paul" = "Megan é minha cunhada"\n'
        '      • "minha irmã Maria casou com João" → João é meu CUNHADO\n'
        '   \n'
        '   ❌ ERRADO - Contradições:\n'
        '      • Chamar de "my sister-in-law" (cunhada) E depois "my brother married her" → CONFUSO!\n'
        '      • "meu sogro Carlos" mas nunca mencionar cônjuge → QUEM é casado com filho/filha dele?\n'
        '      • "my father-in-law Alan" mas protagonista solteiro → IMPOSSÍVEL!\n'
        '   \n'
        '   📋 TABELA DE VALIDAÇÃO (USE ANTES DE ESCREVER):\n'
        '   \n'
        '   SE escrever: "my brother Paul married Megan"\n'
        '   👉 Megan é: "my sister-in-law" (cunhada)\n'
        '   👉 Alan (pai de Megan) é: "my brother\'s father-in-law" (sogro do meu irmão)\n'
        '   👉 NUNCA chamar Alan de "my father-in-law" (seria se EU casasse com Megan)\n'
        '   \n'
        '   SE escrever: "my wife Sarah\'s father Robert"\n'
        '   👉 Robert é: "my father-in-law" (meu sogro)\n'
        '   👉 Sarah é: "my wife" (minha esposa)\n'
        '   👉 Irmão de Sarah é: "my brother-in-law" (meu cunhado)\n'
        '   \n'
        '   💡 REGRA DE OURO:\n'
        '      Antes de usar "cunhado/cunhada/sogro/sogra/genro/nora":\n'
        '      1. Pergunte: QUEM é casado com QUEM?\n'
        '      2. Desenhe mentalmente a árvore genealógica\n'
        '      3. Valide se a relação faz sentido matemático\n'
        '      4. Se confuso, use nomes próprios em vez de relações\n'
        '   \n'
        '   ⚠️ SE HOUVER DÚVIDA: Use "Megan" em vez de tentar definir relação familiar!\n'
        '🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑\n';

    // 🎭 CRITICAL: ADICIONAR INSTRUÇÃO DE PERSPECTIVA/GÊNERO NO INÍCIO DO PROMPT
    final perspectiveInstruction = PerspectiveUtils.getPerspectiveInstruction(
      c.perspective,
      c,
    );

    // 🎣 NOVO: Combinar prompt do template (compacto) + informações de bloco
    final compactPrompt = MainPromptTemplate.buildCompactPrompt(
      language: BaseRules.getLanguageInstruction(c.language),
      instruction: instruction,
      temaSection: temaSection,
      localizacao: c.localizacao,
      localizationGuidance: localizationGuidance,
      narrativeStyleGuidance: narrativeStyleGuidance,
      customPrompt: c.customPrompt,
      useCustomPrompt: c.useCustomPrompt,
      nameList: '', // Não mais necessário
      trackerInfo: trackerInfo,
      characterGuidance: characterGuidance,
      forbiddenNamesWarning: forbiddenNamesWarning,
      isSpanish: c.language.toLowerCase().contains('espanhol'),
      adjustedTarget: needed,
      minAcceptable: minAcceptable,
      maxAcceptable: maxAcceptable,
      limitedNeeded: needed,
      contextoPrevio: contextoPrevio,
      measure: measure,
      avoidRepetition: avoidRepetition,
      labels: {},
      totalWords: c.quantity,
    );

    final prompt =
        '$perspectiveInstruction\n🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑\n\n$progressCounter\n\n$viralHookSection$worldStateContext$titleSection$compactPrompt';

    return prompt;
  }

  /// 🚀 OTIMIZAÇÃO: Limita contexto aos últimos blocos para evitar timeouts
  static String buildLimitedContext(
    String fullContext,
    int currentBlock,
    int maxRecentBlocks,
  ) {
    if (fullContext.isEmpty || currentBlock <= maxRecentBlocks) {
      return fullContext; // Blocos iniciais usam tudo
    }

    // 🛡️ LIMITE ABSOLUTO OTIMIZADO: Reduzido para evitar timeout em idiomas pesados
    // 🚨 v7.6.153: REDUZIDO 3500→2000 para economizar tokens em Free Tier
    // Coreano: 2000 palavras × 5.5 = 11.000 chars (vs 19.250 anterior)
    // Economia: ~2.000 tokens por request = permite mais requests/min
    const maxContextWords = 2000;
    final currentWords = _countWords(fullContext);

    if (currentWords <= maxContextWords) {
      return fullContext; // Contexto ainda está em tamanho seguro
    }

    // Separar em blocos (parágrafos duplos ou mais)
    final blocks = fullContext.split(RegExp(r'\n{2,}'));
    if (blocks.length <= maxRecentBlocks + 5) {
      return fullContext; // Ainda não tem muitos blocos
    }

    // Pegar resumo inicial (primeiros 3 parágrafos)
    final initialSummary = blocks.take(3).join('\n\n');

    // Pegar últimos N blocos completos
    final recentBlocks = blocks
        .skip(max(0, blocks.length - maxRecentBlocks * 3))
        .join('\n\n');

    final result = '$initialSummary\n\n[...]\n\n$recentBlocks';

    // Verificar se ainda está muito grande
    if (_countWords(result) > maxContextWords) {
      // Reduzir ainda mais - só últimos blocos
      return blocks
          .skip(max(0, blocks.length - maxRecentBlocks * 2))
          .join('\n\n');
    }

    return result;
  }

  // 🌍 MULTIPLICADORES DE VERBOSIDADE POR IDIOMA
  static double getLanguageVerbosityMultiplier(String language) {
    final normalized = language.toLowerCase().trim();

    // 🇪🇸 ESPANHOL: Tende a ser ~15-20% mais verboso que português
    if (normalized.contains('espanhol') ||
        normalized.contains('spanish') ||
        normalized.contains('español') ||
        normalized == 'es' ||
        normalized == 'es-mx') {
      return 0.85; // Pedir 15% menos para compensar
    }

    // 🇺🇸 INGLÊS: Tende a ser ~15-20% mais CONCISO que português
    if (normalized.contains('inglês') ||
        normalized.contains('ingles') ||
        normalized.contains('english') ||
        normalized == 'en' ||
        normalized == 'en-us') {
      return 1.05; // Pedir 5% MAIS para compensar concisão
    }

    // 🇫🇷 FRANCÊS: Tende a ser ~10-15% mais verboso que português
    if (normalized.contains('franc') ||
        normalized.contains('french') ||
        normalized == 'fr') {
      return 0.90; // Pedir 10% menos para compensar
    }

    // 🇮🇹 ITALIANO: Tende a ser ~10% mais verboso que português
    if (normalized.contains('italia') ||
        normalized.contains('italian') ||
        normalized == 'it') {
      return 0.92; // Pedir 8% menos para compensar
    }

    // 🇩🇪 ALEMÃO: Similar ao português
    if (normalized.contains('alem') ||
        normalized.contains('german') ||
        normalized == 'de') {
      return 1.0; // Sem ajuste
    }

    // 🇷🇺 RUSSO: Muito conciso (sem artigos, casos gramaticais)
    if (normalized.contains('russo') ||
        normalized.contains('russian') ||
        normalized == 'ru') {
      return 1.15; // Pedir 15% MAIS
    }

    // 🇧🇬 BÚLGARO: Conciso similar ao russo
    if (normalized.contains('búlgar') ||
        normalized.contains('bulgar') ||
        normalized.contains('bulgarian') ||
        normalized == 'bg') {
      return 1.15; // Pedir 15% MAIS
    }

    // �🇷 CROATA: Ligeiramente mais conciso que português
    if (normalized.contains('croata') ||
        normalized.contains('croatian') ||
        normalized.contains('hrvatski') ||
        normalized == 'hr') {
      return 1.05; // Pedir 5% MAIS
    }

    // �🇵🇱 POLONÊS: Ligeiramente mais conciso que português
    if (normalized.contains('polon') ||
        normalized.contains('polish') ||
        normalized == 'pl') {
      return 1.05; // Pedir 5% MAIS
    }

    // 🇹🇷 TURCO: Muito conciso (aglutinação de palavras)
    if (normalized.contains('turco') ||
        normalized.contains('turk') ||
        normalized.contains('turkish') ||
        normalized == 'tr') {
      return 1.10; // Pedir 10% MAIS
    }

    // 🇷🇴 ROMENO: Similar ao italiano/português
    if (normalized.contains('romeno') ||
        normalized.contains('roman') ||
        normalized == 'ro') {
      return 0.92; // Pedir 8% menos para compensar
    }

    // 🇰🇷 COREANO: Muito conciso
    if (normalized.contains('coreano') ||
        normalized.contains('korean') ||
        normalized == 'ko') {
      return 1.20; // Pedir 20% MAIS
    }

    // 🇧🇷 PORTUGUÊS ou OUTROS: Baseline perfeito
    return 1.0;
  }

  /// Retorna chars por palavra para cada idioma (usado no limite de caracteres)
  static double getCharsPerWordForLanguage(String language) {
    final normalized = language.toLowerCase().trim();

    // 🇰🇷 COREANO: 2-3 chars/palavra
    if (normalized.contains('coreano') ||
        normalized.contains('korean') ||
        normalized == 'ko') {
      return 2.5;
    }

    // �🇪 ALEMÃO: 6-7 chars/palavra (palavras compostas longas)
    if (normalized.contains('alem') || // Captura: alemão, alemao, Alemão (encoding quebrado)
        normalized.contains('german') ||
        normalized == 'de') {
      return 6.5;
    }

    // 🇷🇺 RUSSO: 5-6 chars/palavra (alfabeto cirílico)
    if (normalized.contains('russo') ||
        normalized.contains('russian') ||
        normalized == 'ru') {
      return 5.5;
    }

    // �🇬 BÚLGARO: 5-6 chars/palavra (alfabeto cirílico, similar ao russo)
    if (normalized.contains('búlg') || // Búlgaro com acento
        normalized.contains('bulg') || // Bulgaro sem acento / Bulgarian
        normalized == 'bg') {
      return 5.5;
    }
    // 🇭🇷 CROATA: 5.5-6 chars/palavra (diacríticos, similar ao polonês)
    if (normalized.contains('croata') ||
        normalized.contains('croatian') ||
        normalized.contains('hrvatski') ||
        normalized == 'hr') {
      return 5.7;
    }
    // 🇵🇱 POLONÊS: 5.5-6 chars/palavra (diacríticos)
    if (normalized.contains('polon') || // Captura: polonês, polones, Polonês (encoding quebrado)
        normalized.contains('polish') ||
        normalized == 'pl') {
      return 5.8;
    }

    // 🇹🇷 TURCO: 5-5.5 chars/palavra
    if (normalized.contains('turco') ||
        normalized.contains('turk') ||
        normalized.contains('turkish') ||
        normalized == 'tr') {
      return 5.3;
    }

    // 🇷🇴 ROMENO: 5-5.5 chars/palavra (similar ao italiano)
    if (normalized.contains('romeno') ||
        normalized.contains('roman') ||
        normalized == 'ro') {
      return 5.3;
    }

    // �🇫🇷 FRANCÊS: 5-5.5 chars/palavra
    if (normalized.contains('franc') || // Captura: francês, Frances, Francês (encoding quebrado)
        normalized.contains('french') ||
        normalized == 'fr') {
      return 5.3;
    }

    // 🇮🇹 ITALIANO: 5-5.5 chars/palavra
    if (normalized.contains('italia') ||
        normalized.contains('italian') ||
        normalized == 'it') {
      return 5.2;
    }

    // 🇪🇸 ESPANHOL: 5-5.5 chars/palavra
    if (normalized.contains('espanhol') ||
        normalized.contains('spanish') ||
        normalized.contains('español') ||
        normalized == 'es' ||
        normalized == 'es-mx') {
      return 5.3;
    }

    // 🇺🇸 INGLÊS: 4.5-5 chars/palavra
    if (normalized.contains('ingl') || // Captura: inglês, ingles, Inglês (encoding quebrado)
        normalized.contains('english') ||
        normalized == 'en' ||
        normalized == 'en-us') {
      return 4.7;
    }

    // 🇧🇷 PORTUGUÊS ou OUTROS: 5-5.5 chars/palavra
    // Captura: português, portugues, Português (encoding quebrado)
    return 5.2;
  }

  static String buildCharacterGuidance(
    ScriptConfig config,
    CharacterTracker tracker,
  ) {
    final lines = <String>[];
    final baseNames = <String>{};

    final protagonist = config.protagonistName.trim();
    if (protagonist.isNotEmpty) {
      final translatedProtagonist = BaseRules.translateFamilyTerms(
        config.language,
        protagonist,
      );
      lines.add(
        '- Protagonista: "$translatedProtagonist" — mantenha exatamente este nome e sua função.',
      );
      baseNames.add(protagonist.toLowerCase());
    }

    final secondary = config.secondaryCharacterName.trim();
    if (secondary.isNotEmpty) {
      final translatedSecondary = BaseRules.translateFamilyTerms(
        config.language,
        secondary,
      );
      lines.add(
        '- Personagem secundário: "$translatedSecondary" — preserve o mesmo nome em todos os blocos.',
      );
      baseNames.add(secondary.toLowerCase());
    }

    final additional =
        tracker.confirmedNames
            .where((n) => !baseNames.contains(n.toLowerCase()))
            .toList()
          ..sort((a, b) => a.compareTo(b));

    for (final name in additional) {
      // 🛡️ CORRIGIDO: Adicionar personagens mencionados
      if (name.startsWith('PERSONAGEM MENCIONADO')) {
        // Remover marcador e traduzir termo familiar antes de adicionar ao prompt
        final cleanName = name.replaceFirst('PERSONAGEM MENCIONADO: ', '');
        final translatedName = BaseRules.translateFamilyTerms(
          config.language,
          cleanName,
        );
        lines.add(
          '- Personagem mencionado: $translatedName (manter como referência familiar)',
        );
      } else {
        final translatedName = BaseRules.translateFamilyTerms(
          config.language,
          name,
        );
        lines.add(
          '- Personagem estabelecido: "$translatedName" — não altere este nome nem invente apelidos.',
        );
      }
    }

    if (lines.isEmpty) return '';

    return 'PERSONAGENS ESTABELECIDOS:\n${lines.join('\n')}\nNunca substitua esses nomes por variações ou apelidos.\n';
  }

  /// 🆕 v7.6.142: Constrói mensagem visual do contador progressivo
  static String _buildProgressCounter(ActInfo actInfo, bool isSpanish) {
    final wordLabel = isSpanish ? 'PALABRA' : 'PALAVRA';
    final wordsLabel = isSpanish ? 'PALABRAS' : 'PALAVRAS';
    final remainingLabel = isSpanish ? 'FALTAN' : 'FALTAM';
    final currentActLabel = isSpanish ? 'ACTO ACTUAL' : 'ATO ATUAL';

    // Determinar cor/urgência com base nas palavras restantes
    String urgency;
    String icon;
    if (actInfo.actNumber == 2 && actInfo.actRemainingWords < 300) {
      // Ato 2 próximo do limite - URGÊNCIA MÁXIMA
      urgency = '🚨🚨🚨 ATENÇÃO CRÍTICA 🚨🚨🚨';
      icon = '🚨';
    } else if (actInfo.actNumber == 3 && actInfo.actRemainingWords > 500) {
      // Ato 3 com muito espaço ainda - ALERTA
      urgency = '✅ ESPAÇO SUFICIENTE ✅';
      icon = '✅';
    } else {
      urgency = '📊 PROGRESSO NORMAL 📊';
      icon = '📊';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );
    buffer.writeln('$icon CONTADOR PROGRESSIVO - $currentActLabel $icon');
    buffer.writeln(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );
    buffer.writeln('');
    buffer.writeln('📍 ${actInfo.actName}');
    buffer.writeln('');
    buffer.writeln(
      '$wordLabel ${actInfo.actCurrentWords} DE ${actInfo.actMaxWords} $wordsLabel',
    );
    buffer.writeln('$remainingLabel: ${actInfo.actRemainingWords} $wordsLabel');
    buffer.writeln('');
    buffer.writeln(urgency);
    buffer.writeln('');

    // Mensagens específicas por Ato
    if (actInfo.actNumber == 1) {
      buffer.writeln('⚠️ VOCÊ ESTÁ NO ATO 1 (Setup/Preparação)');
      buffer.writeln('   • Apresente protagonista, conflito e mundo');
      buffer.writeln(
        '   • Quando atingir ${actInfo.actMaxWords} palavras → INICIE Ato 2',
      );
    } else if (actInfo.actNumber == 2) {
      if (actInfo.actRemainingWords < 300) {
        buffer.writeln('🚨 VOCÊ ESTÁ CHEGANDO NO LIMITE DO ATO 2! 🚨');
        buffer.writeln(
          '   • Faltam apenas ${actInfo.actRemainingWords} palavras!',
        );
        buffer.writeln('   • PREPARE o clímax e ENCERRE este Ato!');
        buffer.writeln('   • ATO 3 precisa de MÍNIMO 35% do roteiro total!');
        buffer.writeln(
          '   • Se ultrapassar o limite, a história ficará INCOMPLETA!',
        );
      } else {
        buffer.writeln('⚠️ VOCÊ ESTÁ NO ATO 2 (Desenvolvimento)');
        buffer.writeln('   • Desenvolva conflitos e obstáculos');
        buffer.writeln(
          '   • 🛑 LIMITE MÁXIMO: ${actInfo.actMaxWords} palavras',
        );
        buffer.writeln('   • Quando chegar perto do limite → INICIE Ato 3');
      }
    } else if (actInfo.actNumber == 3) {
      if (actInfo.actRemainingWords > 500) {
        buffer.writeln('✅ VOCÊ ESTÁ NO ATO 3 (Resolução) - ESPAÇO SUFICIENTE');
        buffer.writeln(
          '   • Você tem ${actInfo.actRemainingWords} palavras restantes!',
        );
        buffer.writeln(
          '   • DESENVOLVA clímax, resolução e desfecho COMPLETOS',
        );
        buffer.writeln(
          '   • NÃO apresse o final - USE todo o espaço disponível!',
        );
      } else {
        buffer.writeln('⚠️ VOCÊ ESTÁ NO ATO 3 (Resolução)');
        buffer.writeln('   • Conclua com clímax + resolução + desfecho');
        buffer.writeln('   • MÍNIMO: ${actInfo.actMaxWords} palavras');
        buffer.writeln('   • Faltam: ${actInfo.actRemainingWords} palavras');
      }
    }

    buffer.writeln('');
    buffer.writeln(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

    return buffer.toString();
  }

  // Cache para evitar reprocessamento em contagens frequentes
  static final Map<int, int> _wordCountCache = {};

  /// 🧹 v7.6.153: Limpa cache entre gerações
  static void clearCache() {
    _wordCountCache.clear();
  }

  static int _countWords(String text) {
    if (text.isEmpty) return 0;

    // Cache baseado no hash do texto
    final hash = text.hashCode;
    if (_wordCountCache.containsKey(hash)) {
      return _wordCountCache[hash]!;
    }

    // Otimização: trim() uma única vez
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;

    // Conta palavras usando split otimizado
    final count = trimmed.split(RegExp(r'\s+')).length;

    // Limita cache a 100 entradas
    if (_wordCountCache.length > 100) {
      _wordCountCache.clear();
    }
    _wordCountCache[hash] = count;

    return count;
  }
}
