/// Sistema de Regras de Estrutura Narrativa
/// Gerencia regras de 3 atos, checkpoints, fases narrativas e progressão de blocos
library;

/// Informações sobre o Ato atual
class ActInfo {
  final int actNumber; // 1, 2 ou 3
  final String actName; // "ATO 1 - INÍCIO", etc
  final int actCurrentWords; // palavras já escritas no Ato atual
  final int actMaxWords; // máximo de palavras permitidas no Ato
  final int actRemainingWords; // palavras restantes antes do limite
  final bool isOverLimit; // true se ultrapassou o limite

  const ActInfo({
    required this.actNumber,
    required this.actName,
    required this.actCurrentWords,
    required this.actMaxWords,
    required this.actRemainingWords,
    required this.isOverLimit,
  });
}

/// Classe principal para regras de estrutura narrativa
class StructureRules {
  /// 🆕 v7.6.142: Calcula informações do Ato atual baseado em palavras acumuladas
  static ActInfo getActInfo({
    required int currentTotalWords,
    required int targetTotalWords,
  }) {
    final act1Limit = (targetTotalWords * 0.25).round(); // 25%
    final act2End = (targetTotalWords * 0.65)
        .round(); // Ato 1 (25%) + Ato 2 (40%) = 65%
    final act2MaxWords = (targetTotalWords * 0.40)
        .round(); // Ato 2 sozinho = 40%

    // Determinar em qual Ato estamos
    if (currentTotalWords <= act1Limit) {
      // Estamos no Ato 1
      return ActInfo(
        actNumber: 1,
        actName: 'ATO 1 - INÍCIO (Setup)',
        actCurrentWords: currentTotalWords,
        actMaxWords: act1Limit,
        actRemainingWords: act1Limit - currentTotalWords,
        isOverLimit: false,
      );
    } else if (currentTotalWords <= act2End) {
      // Estamos no Ato 2
      final act2CurrentWords = currentTotalWords - act1Limit;
      return ActInfo(
        actNumber: 2,
        actName: 'ATO 2 - MEIO (Desenvolvimento)',
        actCurrentWords: act2CurrentWords,
        actMaxWords: act2MaxWords,
        actRemainingWords: act2MaxWords - act2CurrentWords,
        isOverLimit: false,
      );
    } else {
      // Estamos no Ato 3
      final act3CurrentWords = currentTotalWords - act2End;
      final act3MinWords = (targetTotalWords * 0.35).round();
      final act3RemainingWords = act3MinWords - act3CurrentWords;

      return ActInfo(
        actNumber: 3,
        actName: 'ATO 3 - FIM (Resolução)',
        actCurrentWords: act3CurrentWords,
        actMaxWords: act3MinWords, // Usar mínimo como "máximo" para Ato 3
        actRemainingWords: act3RemainingWords,
        isOverLimit:
            currentTotalWords > act2End && act3CurrentWords < act3MinWords,
      );
    }
  }

  /// Gera regras de estrutura de 3 atos
  static String getThreeActStructure({
    required int totalWords,
    required int blockNumber,
    required int totalBlocks,
  }) {
    final act1Limit = (totalWords * 0.25).round();
    final act2Limit = (totalWords * 0.45).round(); // MÁXIMO 45%
    final act3Min = (totalWords * 0.35).round(); // MÍNIMO 35%

    return '''
🚨 ESTRUTURA DE 3 ATOS - OBRIGATÓRIA PARA HISTÓRIAS COMPLETAS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ATENÇÃO CRÍTICA: A história DEVE ter INÍCIO, MEIO e FIM COMPLETOS!

🚨 DISTRIBUIÇÃO OBRIGATÓRIA DO ESPAÇO:
   • ATO 1 - INÍCIO (Setup): 25% do roteiro = ~$act1Limit palavras
     → Apresentar protagonista, conflito, mundo
     → Estabelecer o que está em jogo
     → Gancho que lança a história

   • ATO 2 - MEIO (Desenvolvimento): 40% do roteiro ← 🚨 LIMITE MÁXIMO: 45% = $act2Limit palavras!
     → Protagonista age e enfrenta obstáculos
     → Complicações e reviravoltas
     → Tensão crescente até o clímax
     🛑 HARD LIMIT: Se ultrapassar $act2Limit palavras, você ESTÁ FALHANDO! Corte imediatamente!

   • ATO 3 - FIM (Resolução): 35% do roteiro ← 🚨 NÃO NEGOCIÁVEL! = MÍNIMO $act3Min palavras!
     → Clímax final (confronto decisivo)
     → Resolução do conflito principal
     → Protagonista consegue ou perde objetivo
     → Desfecho emocional satisfatório
     🛑 HARD LIMIT: Se Ato 3 < $act3Min palavras, você REPROVOU! Volte e corte Ato 2!

📊 BLOCOS ATUAL vs PLANEJAMENTO:
   • Bloco atual: $blockNumber de $totalBlocks
   • Progresso: ${((blockNumber / totalBlocks) * 100).toStringAsFixed(1)}%
   ${blockNumber < totalBlocks ? '• Este NÃO é o último bloco - CONTINUE desenvolvendo!' : '• Este é o BLOCO FINAL - CONCLUA a história AGORA!'}
''';
  }

  /// Gera instruções detalhadas do Ato 3
  static String getAct3Details() {
    return '''
🎬 ESTRUTURA DETALHADA DO ATO 3 (35% FINAL) - OBRIGATÓRIO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ O ATO 3 é o CLÍMAX e RESOLUÇÃO. Deve SEMPRE incluir TODAS as 3 partes:

📍 PARTE 1: EXECUÇÃO DA VINGANÇA/REVELAÇÃO (15% do roteiro)
   ✅ Protagonista USA a "arma" obtida no Ato 2
   ✅ Confronto direto OU revelação pública acontece NA TELA
   ✅ Antagonistas DESCOBREM a verdade (mostre reação)
   ✅ Momento da virada: "tudo vem à tona"

📍 PARTE 2: QUEDA DOS ANTAGONISTAS (10% do roteiro) ← 🚨 MOSTRE, NÃO RESUMA!
   ✅ Consequências IMEDIATAS e VISÍVEIS mostradas EM CENA
   ✅ Perda de dinheiro/poder/reputação EXPLICITADA com detalhes
   ✅ Reação emocional dos antagonistas (choque, desespero, raiva) MOSTRADA
   ✅ Antagonistas em posição FINAL (prisão, falência, humilhação) DETALHADA
   ❌ PROIBIDO: "Eles perderam tudo" sem MOSTRAR como perderam
   ❌ PROIBIDO: "Foi um escândalo" sem DESCREVER o escândalo
   ❌ PROIBIDO: "Foram presos" sem MOSTRAR a prisão acontecendo

📍 PARTE 3: RESOLUÇÃO DO PROTAGONISTA (10% do roteiro) ← 🚨 CENA FINAL!
   ✅ Protagonista em posição final clara COM CENA DESCRITIVA
   ✅ Reflexão sobre jornada completada (não apenas "aprendi X")
   ✅ Fechamento emocional satisfatório MOSTRADO, não narrado
   ✅ Mensagem/lição final transmitida através de AÇÃO ou DIÁLOGO
   ❌ PROIBIDO: Terminar com apenas "E assim aprendi que..."
   ❌ PROIBIDO: Final apenas narrativo sem cena final memorável

✅ EXEMPLOS DE FINAIS COMPLETOS (COPIE ESTE PADRÃO):
   • "François foi preso por fraude. A empresa faliu. Quentin assumiu o controle"
   • "Caroline viu Marc transformado no restaurante. Percebeu seu erro. Ele a recusou"
   • "Paul foi exposto publicamente. As irmãs perderam tudo. Adrien ofereceu apenas um bolo"
   • "Étienne perdeu ambos os projetos. Caroline o deixou. Marc assumiu a empresa"

❌ FINAIS PROIBIDOS (NUNCA FAÇA ISSO):
   • "Quentin tinha a arma em mãos. Sorriu. A guerra começava" ← SEM EXECUÇÃO
   • "Marc convidou Caroline ao restaurante. Ela chegou. Ele se revelou" ← SEM RESOLUÇÃO
   • "A vingança estava pronta para acontecer" ← SEM AÇÃO
   • "Descobri a verdade sobre meu irmão. Agora posso agir" ← PAROU NO MEIO
   • "Le scandale a été énorme. Ils ont tout perdu." ← RESUMO, NÃO CENA! ❌
   • "Eles foram presos. A empresa faliu. Eu venci." ← OFF-SCREEN! ❌
   • "Semanas depois, tudo estava resolvido" ← NARRAÇÃO VAZIA! ❌
''';
  }

  /// Gera regras de queda detalhada dos antagonistas
  static String getDetailedFallRules() {
    return '''
▸ PARTE 2: QUEDA DETALHADA (15% = 800-1.000 palavras)
   
   🚨🚨🚨 OBRIGATÓRIO: Público PRECISA VER cada passo da queda! 🚨🚨🚨
   ❌ PROIBIDO: "Eles foram presos. Fim." (50 palavras)
   ✅ OBRIGATÓRIO: Escrever OS 5 BEATS abaixo (mínimo 1.000 palavras)
   
   🎬 Beat 1 - Chegada da Autoridade (MÍNIMO 150 palavras):
   
   EXEMPLO OBRIGATÓRIO (COPIE ESTA ESTRUTURA):
   "Três minutos depois da minha ligação, sirenes.
   
   Cinco viaturas da polícia cercaram o prédio.
   Oito policiais entraram pela porta principal.
   
   [VILÃO] olhou pela janela. Seu rosto empalideceu.
   
   Não... isso não pode estar acontecendo, ele sussurrou.
   
   Mas estava. A justiça tinha chegado."
   
   ✅ USE: Números concretos (5 viaturas, 8 policiais)
   ✅ USE: Reação do vilão (empalideceu, sussurrou)
   ✅ USE: Mínimo 150 palavras neste beat!
   
   🎬 Beat 2 - Momento da Prisão (MÍNIMO 200 palavras):
   
   EXEMPLO OBRIGATÓRIO (COPIE ESTA ESTRUTURA):
   "O delegado mostrou o mandado.
   
   [VILÃO], você está preso por fraude, lavagem de dinheiro
   e apropriação indébita.
   
   [VILÃO] tentou sorrir, aquele sorriso confiante de sempre.
   
   Há um engano. Eu sou [PROFISSÃO]. Vocês não podem...
   
   Vire-se. Mãos atrás das costas.
   
   As algemas clicaram.
   
   O som ecoou pelo escritório silencioso.
   Todos os funcionários observavam, imóveis.
   
   [VILÃO2] gritou: [VILÃO]! Faça alguma coisa!
   
   Mas não havia nada a fazer.
   O império estava desmoronando."
   
   ✅ USE: Diálogo do vilão tentando se defender
   ✅ USE: Som das algemas
   ✅ USE: Reação de testemunhas
   ✅ USE: Mínimo 200 palavras neste beat!
   
   🎬 Beat 3 - Desmoronamento Imediato (MÍNIMO 250 palavras):
   
   EXEMPLO OBRIGATÓRIO (COPIE ESTA ESTRUTURA):
   "Enquanto [VILÃO] era levado, seu celular começou a explodir.
   
   [VILÃO2] pegou o aparelho da mesa.
   
   47 notificações.
   
   Ela abriu a primeira: Cancelando o contrato.
   A segunda: Retiramos todos os fundos.
   A terceira: Nosso escritório não pode ser associado a fraude.
   
   Em 20 minutos, cinco clientes cancelaram.
   Em uma hora, dez.
   Em duas horas, todos os contratos estavam cancelados.
   
   O telefone do escritório tocava sem parar.
   
   É verdade que o Sr. [VILÃO] foi preso?
   Nosso dinheiro está seguro?
   Queremos transferir imediatamente!
   
   O império que eles construíram com MEU dinheiro
   estava desmoronando diante dos olhos dela.
   
   E tudo que ela podia fazer era assistir."
   
   ✅ USE: Números concretos (47 notificações, 5 clientes)
   ✅ USE: Timeline (20 min, 1 hora, 2 horas)
   ✅ USE: Diálogos de clientes cancelando
   ✅ USE: Mínimo 250 palavras neste beat!
   
   🎬 Beat 4 - Consequências Públicas (MÍNIMO 200 palavras):
   
   EXEMPLO OBRIGATÓRIO (COPIE ESTA ESTRUTURA):
   "No dia seguinte, a manchete:
   
   [PROFISSÃO] PROEMINENTE PRESO POR FRAUDE MILIONÁRIA
   
   O jornal local. O jornal nacional. A internet.
   
   O clube de [ESPORTE/LAZER] cancelou o membership de [VILÃO].
   Não podemos ter criminosos como sócios.
   
   O restaurante favorito deles ligou:
   Sua reserva permanente foi cancelada.
   
   Amigos pararam de atender.
   
   [VILÃO2] tentou ir ao [LOCAL SOCIAL] de sempre.
   As outras [PESSOAS] viraram as costas.
   
   Ela saiu correndo, com lágrimas escorrendo.
   
   O banco bloqueou as contas.
   A casa foi marcada para leilão.
   Os carros de luxo foram rebocados.
   
   Em uma semana, eles passaram de elite para párias."
   
   ✅ USE: Manchete completa
   ✅ USE: Múltiplas perdas (clube, restaurante, amigos)
   ✅ USE: Cena de humilhação pública
   ✅ USE: Mínimo 200 palavras neste beat!
   
   🎬 Beat 5 - Destino Final (MÍNIMO 200 palavras):
   
   EXEMPLO OBRIGATÓRIO (COPIE ESTA ESTRUTURA):
   "Três meses depois, o julgamento.
   
   [VILÃO] entrou no tribunal de uniforme laranja.
   Ele estava 15 kg mais magro.
   O cabelo estava bagunçado.
   As mãos tremiam.
   
   [VILÃO2] não estava na plateia.
   Ela não tinha dinheiro para gasolina.
   
   [X] anos em regime fechado, o juiz declarou.
   
   Sem expressão. Sem piedade.
   
   [VILÃO] olhou para o chão.
   
   O homem que [CRIME], que destruiu vidas com um sorriso,
   agora era apenas o prisioneiro número [NÚMERO].
   
   A mansão foi leiloada por 60% do valor.
   Os carros foram vendidos em leilão.
   As roupas de grife foram para brechó.
   
   O nome [VILÃO] virou sinônimo de fraude.
   
   Esse era o legado dele."
   
   ✅ USE: Descrição física da decadência
   ✅ USE: Sentença do juiz
   ✅ USE: Número de prisioneiro
   ✅ USE: Lista de perdas materiais
   ✅ USE: Mínimo 200 palavras neste beat!
   
   🚨 TOTAL DOS 5 BEATS: MÍNIMO 1.000 PALAVRAS!
   Se você escreveu menos que 1.000 palavras = VOCÊ FALHOU!
   Volte e EXPANDA cada beat até atingir o mínimo!
''';
  }

  /// Gera instruções de checkpoints de progresso
  static String getProgressCheckpoints({
    required int totalWords,
    required int currentWords,
  }) {
    final progress = (currentWords / totalWords * 100).round();
    final checkpoint25 = (totalWords * 0.25).round();
    final checkpoint40 = (totalWords * 0.40).round();
    final checkpoint45 = (totalWords * 0.45).round();
    final checkpoint60 = (totalWords * 0.60).round();
    final checkpoint70 = (totalWords * 0.70).round();
    final checkpoint80 = (totalWords * 0.80).round();

    return '''
📊 SISTEMA DE MONITORAMENTO DE PROGRESSO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 CRITICAL: VOCÊ DEVE CONTAR PALAVRAS A CADA PARÁGRAFO!

⚠️ Durante a escrita, MONITORE constantemente onde você está:
   • Progresso atual: $currentWords de $totalWords palavras ($progress%)

📍 CHECKPOINT 25% (fim do Ato 1) = $checkpoint25 palavras:
   → Protagonista JÁ deve estar com conflito estabelecido
   ${progress >= 25 ? '✅ PASSOU' : '⏳ Ainda não atingido'}

📍 CHECKPOINT 40% (meio do Ato 2) = $checkpoint40 palavras:
   → Protagonista JÁ deve estar no meio da investigação/preparação
   ${progress >= 40 ? '✅ PASSOU' : '⏳ Ainda não atingido'}

📍 🛑 CHECKPOINT 45% (LIMITE ABSOLUTO DO ATO 2) = $checkpoint45 palavras 🛑:
   → Protagonista DEVE ter a "arma" (prova, plano, aliados)
   → Se ainda não tem, PULE para obtenção IMEDIATAMENTE!
   ${progress >= 45 ? '🚨 LIMITE ULTRAPASSADO! Vá para Ato 3 AGORA!' : '⏳ Ainda dentro do limite'}
   → ⚠️ SE VOCÊ PASSOU DE 45%, VOCÊ FALHOU! PARE AGORA!
   → 🚨 DAQUI EM DIANTE: Foque APENAS no Ato 3!
   → ❌ PROIBIDO: Adicionar mais desenvolvimento/complicações
   → ✅ OBRIGATÓRIO: Iniciar Parte 1 do Ato 3 (Execução)

📍 CHECKPOINT 60% (meio do Ato 3 - Parte 1) = $checkpoint60 palavras:
   → Parte 1 (Execução) JÁ deve estar completa
   → Confronto/revelação JÁ deve ter acontecido
   ${progress >= 60 ? '✅ PASSOU' : '⏳ Ainda não atingido'}

📍 CHECKPOINT 70% (transição Parte 1 → Parte 2) = $checkpoint70 palavras:
   → Parte 2 (Queda) deve estar em andamento
   → Antagonistas JÁ devem estar perdendo poder/dinheiro
   ${progress >= 70 ? '✅ PASSOU' : '⏳ Ainda não atingido'}

📍 CHECKPOINT 80% (transição Parte 2 → Parte 3) = $checkpoint80 palavras:
   → Parte 2 (Queda) JÁ deve estar completa
   → Antagonistas JÁ devem estar na posição final (prisão/falência)
   → Iniciar Parte 3 (Resolução do protagonista)
   ${progress >= 80 ? '✅ PASSOU' : '⏳ Ainda não atingido'}

📍 CHECKPOINT 90-100% (Parte 3 - Resolução):
   → Cena final memorável
   → Reflexão do protagonista
   → Última frase impactante
   ${progress >= 90 ? '✅ ENTRANDO NO FINAL' : '⏳ Ainda não atingido'}

🎯 AUTOAVALIAÇÃO OBRIGATÓRIA A CADA 500 PALAVRAS:
   Conte suas palavras escritas: $currentWords palavras
   Calcule: $currentWords ÷ $totalWords = $progress%
   Pergunte: "Estou em $progress%. Estou no ato certo?"
   ${progress > 45 && progress < 60 ? '🚨 VOCÊ PASSOU DO LIMITE! Vá para Ato 3!' : ''}
   ${progress >= 60 && progress < 70 ? '✅ Você está no Ato 3 - Continue para a Parte 2!' : ''}
   ${progress >= 70 && progress < 80 ? '✅ Parte 2 em andamento - Mostre a queda completa!' : ''}
   ${progress >= 80 ? '✅ Finalize com Parte 3 - Resolução do protagonista!' : ''}
''';
  }

  /// Gera regras de ganchos de retenção
  static String getRetentionHooks() {
    return '''
🎣 GANCHOS DE RETENÇÃO (OBRIGATÓRIOS A CADA 8-12 MINUTOS):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ YouTube = Guerra contra o botão "fechar"!
   Sem ganchos = Ouvinte sai = Sem monetização = Desperdício!

📊 ONDE COLOCAR GANCHOS (fórmula de canais com 10M+ views):

🎣 GANCHO 1: Primeiros 30 segundos (0-2%)
   
   FÓRMULA: Resultado chocante + Promessa de vingança
   
   Template:
   "[VILÃO] me [AÇÃO TERRÍVEL], me deixando com [PERDA BRUTAL].
   
   Mas eles não sabiam de uma coisa.
   
   [SEGREDO/ARMA] que mudaria TUDO.
   
   Esta é a história de como eu passei de [BAIXO] para [ALTO],
   e eles passaram de [ALTO] para [BAIXO].
   
   E tudo começou com [OBJETO/MOMENTO MISTERIOSO]..."

🎣 GANCHO 2: Fim do Ato 1 (~12% = 8-10 min)
   
   TÉCNICA: Revelação parcial + Nova pergunta
   
   Template:
   "Quando [AÇÃO], eu pensei ter encontrado [ITEM/INFO].
   
   Mas [DETALHE INTRIGANTE]...
   
   Era [REVELAÇÃO PARCIAL].
   E isso mudaria TUDO.
   
   Mas eu ainda não sabia [NOVA PERGUNTA]..."

🎣 GANCHO 3: Meio do Ato 2 (~30% = 18-20 min)
   
   TÉCNICA: Complicação inesperada
   
   Template:
   "Eu achava que tinha [SOLUÇÃO].
   
   Mas quando [PESSOA] [AÇÃO]...
   seu rosto [REAÇÃO ESTRANHA].
   
   [FRASE MISTERIOSA]
   
   [PERGUNTA QUE COMPLICA TUDO]"

🎣 GANCHO 4: Antes do clímax (~50% = 30 min)
   
   TÉCNICA: Plano revelado + Contagem regressiva
   
   Template:
   "Finalmente, eu tinha [ARMAS/PROVAS].
   
   [VILÕES] não faziam ideia do que estava vindo.
   
   Em [TEMPO], eles estariam [DESTINO RUIM].
   E eu estaria [ESTADO BOM].
   
   Mas primeiro... eu precisava [AÇÃO FINAL]."

🎣 GANCHO 5: Início do clímax (~65% = 39-40 min)
   
   TÉCNICA: Execução começa
   
   Template:
   "[AÇÃO DE ENTRADA NA CENA].
   [VILÃO] estava [AÇÃO TRANQUILA].
   
   Quando me viu, [REAÇÃO].
   
   [DIÁLOGO HOSTIL]
   
   [AÇÃO COM OBJETO/PROVA].
   
   [Uma palavra], eu disse.
   
   [VILÃO] [AÇÃO].
   
   E [RESULTADO DRAMÁTICO]."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 FRASES MÁGICAS (usar frequentemente ao longo da história):

Mistério:
   • "Mas eu ainda não sabia..."
   • "O que eu estava prestes a descobrir..."
   • "Naquele momento, eu não imaginava que..."

Antecipação:
   • "Em X horas, tudo mudaria."
   • "Eles não faziam ideia do que estava vindo."
   • "O plano estava pronto. Faltava apenas..."

Tensão:
   • "E então, algo inesperado aconteceu."
   • "Foi quando percebi meu erro."
   • "Naquele segundo, tudo clicou."

Promessa de vingança:
   • "E eles pagariam. Cada centavo. Cada humilhação."
   • "Eles riram de mim. Em breve, eu riria deles."
   • "Justiça estava chegando. Sem piedade."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 MÉTRICA DE SUCESSO:

✅ A cada 10 minutos, ouvinte pensa: "E agora? O que vai acontecer?"
❌ Ouvinte pensa: "Tá, já entendi. Vou fechar."

🎯 REGRA DE OURO:
   Se passou 15 minutos sem gancho → ERRO FATAL!
   Volte e adicione revelação/complicação/tensão!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// Gera checklist de conclusão de roteiro
  static String getCompletionChecklist() {
    return '''
✅ CHECKLIST DO FINAL (OBRIGATÓRIO):
   Antes de terminar o roteiro, CONFIRME:
   □ Protagonista confrontou o antagonista/problema?
   □ Conflito principal foi RESOLVIDO (vitória ou derrota)?
   □ Protagonista conseguiu ou perdeu o que buscava?
   □ História tem DESFECHO EMOCIONAL claro?
   □ Audiência sabe "como terminou" a situação?
   □ Antagonistas tiveram destino FINAL mostrado?
   □ Não há perguntas "e depois?" sem resposta?

🚨 REGRA DE OURO DO FINAL COMPLETO:
   Se o leitor perguntar "E daí? O que aconteceu depois?"
   → O final está INCOMPLETO ❌

   Se o leitor sentir CATARSE e FECHAMENTO
   → O final está CORRETO ✅

💡 CHECKLIST ANTES DE FINALIZAR (TODOS devem ser SIM):
   □ Mostrei o protagonista USANDO a arma/informação do Ato 2?
   □ Mostrei o confronto/revelação ACONTECENDO?
   □ Mostrei os antagonistas DESCOBRINDO e REAGINDO?
   □ Mostrei as CONSEQUÊNCIAS para os antagonistas?
   □ Mostrei o protagonista em sua POSIÇÃO FINAL?
   □ A história TEM DESFECHO, não promessa de desfecho?
   □ NÃO há frases tipo "foi um escândalo" sem MOSTRAR o escândalo?
   □ NÃO há finais OFF-SCREEN (fora da tela)?
''';
  }

  /// Gera regras de limite de personagens
  static String getCharacterLimits() {
    return '''
🚨 LIMITE ABSOLUTO DE PERSONAGENS:
   • Protagonista: 1 (sempre o narrador em 1ª pessoa)
   • Antagonistas principais: MÁXIMO 2
     Exemplo: esposa traidora + amante dela ✅
     Exemplo: sócio + irmão traidor ✅
   • Personagens secundários: MÁXIMO 3
     Exemplo: aliado que ajuda + filho da protagonista + advogado
   
   TOTAL MÁXIMO: 6 personagens com nome
   
   ❌ PROIBIDO: Introduzir novo vilão após 40% da história
   ❌ PROIBIDO: Personagens que aparecem 1x e somem (use função)
   ❌ PROIBIDO: Múltiplas gerações (avô, pai, filho = confuso!)
   
📊 TESTE DE CLAREZA AUDITIVA:
   "Se alguém perdeu 5 minutos de áudio, consegue voltar e entender?"
   → Se NÃO = você tem personagens DEMAIS!
   
🎯 PADRÃO CAMPEÃO (canais com 1M+ subs):
   • 1 Protagonista (narrador)
   • 2 Vilões principais (quem causou a injustiça)
   • 1-2 Aliados (ajudam na vingança)
   • 0-1 Vítima secundária (opcional - ex: filho também prejudicado)
''';
  }

  /// Gera instruções de progresso de blocos
  static String getBlockProgressInstructions({
    required int blockNumber,
    required int totalBlocks,
  }) {
    final isFinalBlock = blockNumber >= totalBlocks;

    return '''
🚨 CRÍTICO - CONCLUSÃO DO ROTEIRO COMPLETO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 PROGRESSO DA GERAÇÃO:
   • Total de blocos planejados: $totalBlocks blocos
   • Bloco atual: bloco número $blockNumber de $totalBlocks
   ${!isFinalBlock ? '• Status: CONTINUAÇÃO - Este NÃO é o último bloco!' : '• Status: BLOCO FINAL - Conclua a história agora!'}

${!isFinalBlock ? '''
❌ PROIBIDO NESTE BLOCO:
   • NÃO finalize a história ainda!
   • NÃO escreva "THE END" ou equivalente
   • NÃO crie uma resolução completa e definitiva
   • NÃO conclua todos os arcos narrativos
   
✅ OBRIGATÓRIO NESTE BLOCO:
   • CONTINUE desenvolvendo a trama
   • Mantenha tensão e progressão narrativa
   • Deixe ganchos para os próximos blocos
   • A história DEVE ter continuação nos blocos seguintes
   • Apenas desenvolva, NÃO conclua!
''' : '''
✅ OBRIGATÓRIO NESTE BLOCO FINAL:
   • AGORA SIM finalize completamente a história
   • Resolva TODOS os conflitos pendentes
   • Dê fechamento a TODOS os personagens
   • Este é o ÚLTIMO bloco - conclusão definitiva!
'''}

💡 ATENÇÃO ESPECIAL:
   • Histórias longas precisam de TODOS os blocos planejados
   • NÃO termine prematuramente só porque "parece completo"
   • Cada bloco é parte de um roteiro maior - respeite o planejamento
   • Finais prematuros PREJUDICAM a qualidade e a experiência do ouvinte
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// Gera tabela de limites por tamanho de roteiro
  static String getLimitsTable() {
    return '''
📊 TABELA DE LIMITES ABSOLUTOS POR TAMANHO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛑 USE ESTA TABELA COMO REFERÊNCIA OBRIGATÓRIA!

Roteiro 5.000 palavras:
   • Ato 1: 1.250 palavras (25%)
   • Ato 2: 2.000 palavras (40%) ← MÁXIMO: 2.250 (45%)
   • Ato 3: 1.750 palavras (35%) ← MÍNIMO ABSOLUTO
   🚨 Se Ato 2 > 2.250 palavras: VOCÊ FALHOU!

Roteiro 8.000 palavras:
   • Ato 1: 2.000 palavras (25%)
   • Ato 2: 3.200 palavras (40%) ← MÁXIMO: 3.600 (45%)
   • Ato 3: 2.800 palavras (35%) ← MÍNIMO ABSOLUTO
   🚨 Se Ato 2 > 3.600 palavras: VOCÊ FALHOU!

Roteiro 10.000 palavras:
   • Ato 1: 2.500 palavras (25%)
   • Ato 2: 4.000 palavras (40%) ← MÁXIMO: 4.500 (45%)
   • Ato 3: 3.500 palavras (35%) ← MÍNIMO ABSOLUTO
   🚨 Se Ato 2 > 4.500 palavras: VOCÊ FALHOU!

Roteiro 12.000 palavras:
   • Ato 1: 3.000 palavras (25%)
   • Ato 2: 4.800 palavras (40%) ← MÁXIMO: 5.400 (45%)
   • Ato 3: 4.200 palavras (35%) ← MÍNIMO ABSOLUTO
   🚨 Se Ato 2 > 5.400 palavras: VOCÊ FALHOU!

🎯 COMO USAR ESTA TABELA:
   1. Identifique meta total de palavras do roteiro
   2. Calcule limites usando tabela acima
   3. A CADA 500 palavras escritas, conte e verifique
   4. Se aproximando do limite do Ato 2? PARE!
   5. Vá DIRETO para Ato 3, mesmo que pareça abrupto

⚠️ MELHOR UM ATO 2 CURTO QUE UM ATO 3 INEXISTENTE!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }
}
