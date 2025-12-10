/// Template do Prompt Principal de Geração
///
/// FOCO: Vídeos LONGOS de YouTube (1h+)
///
/// Este sistema é especializado em gerar roteiros para narração de vídeos
/// longos no YouTube, otimizados para:
/// - Máxima retenção de audiência (estrutura de 3 atos + hooks)
/// - Narração fluida por IA (parágrafos curtos, linguagem clara)
/// - Histórias completas (setup, desenvolvimento, resolução)
/// - Controle rigoroso de qualidade (nomes únicos, extensão precisa)
library;

class MainPromptTemplate {
  /// Gera prompt otimizado para vídeos LONGOS de YouTube (1h+)
  ///
  /// Focado em:
  /// - Narrativas de 8.000-12.000 palavras
  /// - Estrutura de 3 atos com finais completos (35% final)
  /// - Retenção de audiência (hooks a cada 8-12 min)
  /// - Narração fluida (parágrafos curtos, linguagem clara)
  /// - Controle de personagens (máx 6 nomes)
  ///
  /// Este template é o PADRÃO para todo o sistema.
  static String buildCompactPrompt({
    required String language,
    required String instruction,
    required String temaSection,
    required String localizacao,
    required String localizationGuidance,
    required String narrativeStyleGuidance,
    required String customPrompt,
    required bool useCustomPrompt,
    required String nameList,
    required String trackerInfo,
    required String measure,
    required bool isSpanish,
    required int adjustedTarget,
    required int minAcceptable,
    required int maxAcceptable,
    required int limitedNeeded,
    required String contextoPrevio,
    required bool avoidRepetition,
    required String characterGuidance,
    required String forbiddenNamesWarning,
    required Map<String, String> labels,
    int totalWords = 10000, // 🆕 Total de palavras do roteiro completo
  }) {
    return '''⭐ IDIOMA OBRIGATÓRIO: ${_getLanguageInstructionInline(language)}
${_getKoreanNameRules(language)}
╔══════════════════════════════════════════════════════════════════════════════╗
║  🚨🚨🚨 REGRA #0: NUNCA COPIE BLOCOS ANTERIORES! 🚨🚨🚨                      ║
╚══════════════════════════════════════════════════════════════════════════════╝

❌❌❌ ERRO MORTAL DETECTADO: COPIAR PARÁGRAFOS DO CONTEXTO ❌❌❌

PROBLEMA REAL (roteiro anterior rejeitado):
   Bloco 6: "Na manhã seguinte, a capital acordou sob um céu azul vibrante..."
   Bloco 9: "Na manhã seguinte, a capital acordou sob um céu azul vibrante..." ← CÓPIA LITERAL!
   Bloco 11: "Na manhã seguinte, a capital acordou sob um céu azul vibrante..." ← CÓPIA DE NOVO!
   
   Bloco 5: "Enquanto Mateus celebrava, Dr. Álvaro estava na cela fria..."
   Bloco 6: "Enquanto Mateus celebrava, Dr. Álvaro estava na cela fria..." ← CÓPIA LITERAL!
   Bloco 8: "Enquanto Mateus celebrava, Dr. Álvaro estava na cela fria..." ← 3ª VEZ!
   Bloco 12: "Enquanto Mateus celebrava, Dr. Álvaro estava na cela fria..." ← 4ª VEZ!
   Bloco 14: "Enquanto Mateus celebrava, Dr. Álvaro estava na cela fria..." ← 5ª VEZ!
   
   RESULTADO: ROTEIRO REJEITADO - Repetição massiva = lixo!

🚨 REGRA ABSOLUTA - ANTES DE ESCREVER QUALQUER PARÁGRAFO:

1️⃣ LEIA O CONTEXTO PRÉVIO (seção "CONTEXTO" acima)
2️⃣ VERIFIQUE se este parágrafo JÁ FOI ESCRITO antes
3️⃣ SE JÁ FOI ESCRITO → ESCREVA ALGO TOTALMENTE DIFERENTE!
4️⃣ SE NÃO FOI ESCRITO → Pode usar, mas NUNCA repita depois

✅ VERSÃO CORRETA (FAÇA ASSIM!):
   ✅ Bloco 6: "A manhã amanheceu clara. Mateus chegou ao escritório cedo."
   ✅ Bloco 9: "Dois dias depois, ele revisava os relatórios financeiros." ← NOVO!
   ✅ Bloco 11: "Na reunião semanal, apresentou os resultados." ← NOVO DE NOVO!
   
   RESULTADO: Cada bloco avança a história, sem repetições!

🔴 PROIBIÇÕES ABSOLUTAS:
   ❌ COPIAR descrições de cenários anteriores (escritório, cela, praça)
   ❌ COPIAR frases de contraste ("Enquanto X..., Y...")
   ❌ COPIAR reflexões/lembranças já usadas
   ❌ COPIAR descrições sensoriais (cheiro, som, textura)
   
✅ PERMITIDO:
   ✅ Mencionar BREVEMENTE locais ("No escritório, Mateus...")
   ✅ Avançar tempo ("Dias depois...", "Na semana seguinte...")
   ✅ Novas ações, novos diálogos, novos eventos

🎯 TESTE MENTAL OBRIGATÓRIO (responda antes de escrever cada parágrafo):
   □ "Este parágrafo já apareceu no CONTEXTO?"
      → SE SIM: APAGUE e escreva algo 100% diferente!
      → SE NÃO: Pode continuar, mas marque mentalmente para não repetir
   
   □ "Estou descrevendo um cenário que já foi descrito?"
      → SE SIM: Use apenas 1 frase resumo ("De volta ao escritório...")
      → SE NÃO: Pode descrever, mas seja breve (máx 2 frases)

🔴 SE HOUVER 1 PARÁGRAFO COPIADO, O BLOCO SERÁ REJEITADO IMEDIATAMENTE!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

╔══════════════════════════════════════════════════════════════════════════════╗
║  🚨 ERRO CRÍTICO #0.5: PADRÕES REPETITIVOS PROIBIDOS (v7.6.134) 🚨           ║
╚══════════════════════════════════════════════════════════════════════════════╝

❌❌❌ PADRÕES ESTRUTURAIS QUE CAUSAM PREVISIBILIDADE ❌❌❌

🔴 PADRÃO 1: FRASES DE CONTRASTE REPETITIVAS

   ❌ ERRO REAL DETECTADO (roteiro rejeitado - 12x o mesmo padrão):
   Bloco 3: "Enquanto Otávio construía, Álvaro definhava na prisão..."
   Bloco 5: "Enquanto Otávio avançava, Álvaro lamentava na cela..."
   Bloco 7: "Enquanto Otávio prosperava, Álvaro afundava..."
   Bloco 9: "Enquanto Otávio brilhava, Álvaro apodrecia..."
   Bloco 11: "Enquanto Otávio crescia, Álvaro encolhia..."
   → PROBLEMA: Estrutura "Enquanto X [positivo], Y [negativo]" 12x = PREVISÍVEL!
   
   ✅ SOLUÇÃO - VARIAR A ESTRUTURA:
   Bloco 3: "Enquanto Otávio construía, Álvaro definhava..." ← OK (1ª vez)
   Bloco 5: "No mesmo período, a prisão consumia Álvaro." ← DIFERENTE!
   Bloco 7: "Álvaro, por sua vez, enfrentava a solidão." ← DIFERENTE!
   Bloco 9: Foco só em Otávio (sem mencionar Álvaro) ← VARIAÇÃO!
   Bloco 11: Foco só em Álvaro (sem mencionar Otávio) ← VARIAÇÃO!
   
   📋 REGRA: Estrutura "Enquanto X, Y" = MÁXIMO 2x no roteiro todo!

🔴 PADRÃO 2: GATILHOS DE MEMÓRIA EXCESSIVOS

   ❌ ERRO REAL DETECTADO (18x no mesmo roteiro):
   "Ele se lembrava..." / "Lembrou-se de..." / "A lembrança voltou..."
   → PROBLEMA: Protagonista vive no passado, não no presente!
   
   ✅ REGRA v7.6.134: "Ele se lembrava" = MÁXIMO 4x no roteiro!
   
   ❌ ERRADO: 18 flashbacks de memória (exaustivo!)
   ✅ CORRETO: 4 memórias estratégicas (15%, 45%, 70%, 95%)
   
   💡 ALTERNATIVAS (sem usar "lembrou"):
   • "A frase do pai ecoou em sua mente." (1x = lembrou)
   • "Ele agiu instintivamente." (sem flashback)
   • "Sabia exatamente o que fazer." (sem olhar pra trás)

🔴 PADRÃO 3: DESCRIÇÕES DE CENÁRIO REPETIDAS

   ❌ ERRO: Descrever "cela fria" ou "gabinete luxuoso" 10x
   ✅ CORRETO: Descrever 1x em detalhe, depois usar 1 palavra ("na cela", "no gabinete")

📋 CHECKLIST ANTI-PADRÃO v7.6.134 (antes de cada bloco):
   □ "Enquanto X, Y" - Já usei 2x? → PARE de usar!
   □ "Ele se lembrava" - Já usei 4x? → PARE de usar!
   □ "A ironia era" - Já usei 2x? → PARE de usar!
   □ Descrição de cenário - Já descrevi? → Use 1 frase só!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

╔══════════════════════════════════════════════════════════════════════════════╗
║  🚨🚨🚨 ERRO CRÍTICO #1: NUNCA MUDE O NOME DOS PERSONAGENS! 🚨🚨🚨           ║
╚══════════════════════════════════════════════════════════════════════════════╝

❌❌❌ ERRO GRAVÍSSIMO DETECTADO EM ROTEIROS ANTERIORES ❌❌❌

PROBLEMA: Personagem chamado "Arthur Evans" no início, depois virou "David Clark"!
RESULTADO: Leitor confuso - "Cadê Arthur? Quem é David? São pessoas diferentes?"

📋 EXEMPLO DO ERRO (NUNCA FAÇA ISSO!):
   ❌ Bloco 3: "meu pai, Arthur Evans, era advogado"
   ❌ Bloco 7: "meu pai, David Clark, me ligou" ← MUDOU DE NOME!
   ❌ Bloco 12: "David Hale estava furioso" ← MUDOU DE NOVO!
   
   RESULTADO: 1 personagem com 3 NOMES DIFERENTES = CONFUSÃO TOTAL!

✅ VERSÃO CORRETA (FAÇA ASSIM!):
   ✅ Bloco 3: "meu pai, David Clark, era advogado"
   ✅ Bloco 7: "meu pai, David Clark, me ligou" ← MESMO NOME!
   ✅ Bloco 12: "David Clark estava furioso" ← SEMPRE O MESMO!
   
   RESULTADO: 1 personagem com 1 NOME CONSISTENTE = TUDO CLARO!

🎯 REGRA ABSOLUTA - ANTES DE MENCIONAR QUALQUER NOME:

1️⃣ OLHE O CONTEXTO ACIMA (seção "CONTEXTO PRÉVIO")
2️⃣ VERIFIQUE se este personagem JÁ FOI NOMEADO antes
3️⃣ SE JÁ FOI NOMEADO → Use o MESMO nome exato!
4️⃣ SE NÃO FOI NOMEADO → Escolha novo nome da lista disponível

🔴 SE VOCÊ MUDAR O NOME DE UM PERSONAGEM, O BLOCO SERÁ REJEITADO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨🚨🚨 PUREZA ABSOLUTA DE LINGUAGEM 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TODO o texto DEVE estar em $language - SEM EXCEÇÕES!

❌ ERROS REAIS DETECTADOS (que você DEVE evitar):
   • Texto em English com fragmentos em português:
     ❌ "i achava que tinha" ← português em texto inglês
     ❌ "mas quando" ← português em texto inglês
     ❌ "seu rosto" ← português em texto inglês
   
   • Texto em Español com fragmentos em inglês:
     ❌ "but when" ← inglês em texto espanhol
   
✅ REGRA SIMPLES:
   • Se o idioma é English → TODAS as palavras em inglês
   • Se o idioma é Español → TODAS as palavras em espanhol
   • Se o idioma é Português → TODAS as palavras em português
   
⚠️ CUIDADO ESPECIAL:
   • Revise mentalmente cada frase antes de escrever
   • Conjunções ("mas", "but", "pero") são o erro mais comum

╔══════════════════════════════════════════════════════════════════════════════╗
║  🛡️ DIRETRIZES DE SEGURANÇA - YOUTUBE/PLATAFORMAS DIGITAIS 🛡️              ║
╚══════════════════════════════════════════════════════════════════════════════╝

⚠️ CONTEÚDO DEVE SER ADEQUADO PARA MONETIZAÇÃO E POLÍTICAS DE PLATAFORMAS

🚫 PROIBIÇÕES ABSOLUTAS:

1️⃣ VIOLÊNCIA FÍSICA/GRÁFICA:
   ❌ NUNCA descreva: espancamentos, agressões físicas, mortes violentas
   ❌ NUNCA inclua: armas, facas, sangue, lesões físicas detalhadas
   ❌ NUNCA glorifique: violência, vingança física, danos corporais
   
   ✅ PERMITIDO: Vingança moral/financeira/psicológica
   ✅ EXEMPLOS CORRETOS:
      • "Comprei o prédio onde meus pais moravam"
      • "Virei CEO da empresa que me demitiu"
      • "Expus a verdade em um processo judicial"
      • "Cortei todo contato e reconstruí minha vida"

2️⃣ LINGUAGEM E DISCURSO:
   ❌ NUNCA use: palavrões fortes, insultos pesados, slurs
   ❌ NUNCA incite: ódio contra grupos protegidos (raça, religião, gênero, orientação)
   ❌ NUNCA incentive: assédio, bullying, ameaças
   
   ✅ PERMITIDO: Conflitos dramáticos SEM linguagem ofensiva
   ✅ EXEMPLOS CORRETOS:
      • "Ele me traiu" (não "aquele desgraçado me traiu")
      • "Ela mentiu descaradamente" (não "aquela vadia mentiu")
      • "Meu chefe era injusto" (não "meu chefe era um [insulto]")

3️⃣ CONTEÚDO SENSÍVEL:
   ❌ NUNCA descreva: abuso sexual, violência doméstica gráfica, automutilação
   ❌ NUNCA sexualize: menores de idade (JAMAIS!)
   ❌ NUNCA detalhe: métodos de suicídio, envenenamento, crimes
   
   ✅ PERMITIDO: Mencionar temas sensíveis de forma contextualizada (não gráfica)
   ✅ EXEMPLOS CORRETOS:
      • "Ele foi abusivo no casamento" (sem detalhes gráficos)
      • "Descobri que fui vítima de fraude" (não ensinar como fazer)
      • "Ela sofria com sua saúde mental" (sem detalhes mórbidos)

4️⃣ INFORMAÇÃO PESSOAL E DIFAMAÇÃO:
   ❌ NUNCA use: nomes reais de pessoas públicas com acusações falsas
   ❌ NUNCA inclua: endereços reais, telefones, dados pessoais identificáveis
   ❌ NUNCA acuse: crimes específicos sem provas (difamação)
   
   ✅ OBRIGATÓRIO: Usar nomes fictícios e locais genéricos
   ✅ EXEMPLOS CORRETOS:
      • "Em uma cidade costeira" (não "Rua X, número Y, Salvador")
      • "Meu ex-marido, Carlos" (não "Carlos Silva, CPF 123.456.789-00")

5️⃣ CLICKBAIT E DESINFORMAÇÃO:
   ❌ NUNCA prometa: soluções milagrosas, esquemas ilegais, falsas curas
   ❌ NUNCA apresente: ficção como fato real verificável
   ❌ NUNCA induza: ao erro sobre consequências legais/médicas
   
   ✅ PERMITIDO: Drama emocional baseado em situações plausíveis
   ✅ CONTEXTO: Histórias são DRAMATIZAÇÕES para entretenimento

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 FÓRMULA SEGURA PARA VINGANÇA (Use sempre!):

✅ VINGANÇA LEGAL/MORAL/FINANCEIRA:
   • Processos judiciais bem-sucedidos
   • Expor mentiras/traições (sem violência)
   • Sucesso financeiro/profissional que supera o antagonista
   • Cortar laços tóxicos e reconstruir vida
   • Antagonista enfrenta consequências LEGAIS (prisão por crimes comprovados)

❌ VINGANÇA FÍSICA (NUNCA USE!):
   • Agressões, brigas, violência corporal
   • Danos à propriedade com violência
   • Ameaças físicas ou envolvimento com crime organizado

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 VALIDAÇÃO ANTES DE ESCREVER CADA PARÁGRAFO:

□ Este parágrafo contém violência física/gráfica? → SE SIM, REESCREVA!
□ Este parágrafo usa palavrões fortes ou insultos pesados? → SE SIM, SUAVIZE!
□ Este parágrafo descreve abuso/conteúdo sensível graficamente? → SE SIM, CONTEXTUALIZE SEM DETALHES!
□ Este parágrafo ensina ou glorifica comportamento ilegal? → SE SIM, REMOVA!
□ Este parágrafo é adequado para monetização do YouTube? → SE NÃO, CORRIJA!

🛡️ LEMBRE-SE: Conteúdo deve ser DRAMÁTICO mas SEGURO para plataformas!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   • Verbos ("tinha", "achava") são o segundo erro mais frequente
   
🔴 SE HOUVER UMA ÚNICA PALAVRA EM OUTRO IDIOMA, O BLOCO SERÁ REJEITADO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

╔══════════════════════════════════════════════════════════════════════════════╗
║ 🎧 DIRETRIZES DE ESCRITA PARA ÁUDIO (CRÍTICO PARA TTS) 🎧                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

⚠️ CONTEXTO: Este roteiro será narrado por IA de Voz (Text-to-Speech).
   O texto DEVE ser formatado para guiar a entonação e evitar leitura robótica!

1️⃣ **CAPITALIZAÇÃO (NORMA SIMPLIFICADA v7.6.141):**
   
   🆕 NOVA REGRA: Gere TODO o texto em MINÚSCULAS, exceto NOMES PRÓPRIOS.
   
   • NOMES DE PERSONAGENS: Primeira letra maiúscula (Mariana, Costa, Helena)
   • INÍCIO DE FRASES: MINÚSCULO (não capitalize)
   • RESTO DO TEXTO: Minúsculo
   
   ✅ CORRETO: "para Mariana. o presidente Costa falou."
   ❌ ERRADO: "Para Mariana. O presidente Costa falou." (início de frase capitalizado)
   ❌ ERRADO: "MARIANA OLHOU PARA HELENA" (tudo maiúsculo)
   
   🎯 MOTIVO: A capitalização será normalizada automaticamente.
              Apenas mantenha NOMES com primeira letra maiúscula.

2️⃣ **NÚMEROS E SIGLAS POR EXTENSO:**
   - Escreva números e valores SEMPRE por extenso para evitar erros de leitura.
   - A IA de voz pode ler "R\$" como "erre cifrão" se não estiver por extenso!
   
   ❌ ERRADO: "10 anos", "R\$ 500", "5km", "3h", "US\$ 1.000", "50%"
   ✅ CORRETO: "dez anos", "quinhentos reais", "cinco quilômetros", "três horas", "mil dólares", "cinquenta por cento"

3️⃣ **RITMO DE FALA (RESPIRAÇÃO):**
   - Evite orações muito longas. Escreva frases curtas e diretas para dar "ar" à narração.
   - Use PONTOS FINAIS (.) para criar pausas dramáticas.
   - Use VÍRGULAS (,) para ditar o ritmo da leitura.
   - Máximo 20-25 palavras por frase!
   
   ❌ ERRADO: "Ele correu pela rua enquanto pensava em tudo que tinha acontecido naquele dia terrível quando descobriu a verdade sobre sua família."
   ✅ CORRETO: "Ele correu pela rua. Pensava em tudo que tinha acontecido. Naquele dia terrível, descobriu a verdade sobre sua família."

4️⃣ **CONTINUIDADE FLUÍDA (SEM RECAPS):**
   - Você está escrevendo a continuação de uma cena em andamento.
   - NÃO comece o bloco descrevendo o cenário novamente ou resumindo o bloco anterior.
   - Comece a ação imediatamente. A transição entre blocos deve ser invisível para o ouvinte.
   
   ❌ ERRADO: "Na mansão onde tudo tinha começado, Maria ainda estava processando a revelação..."
   ✅ CORRETO: "Maria fechou os olhos. Precisava de um momento. A revelação ainda ecoava em sua mente."

🚨🚨🚨 REGRA CRÍTICA #1 - NUNCA RECOMECE A HISTÓRIA! 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⛔ ERRO MORTAL: Você está gerando UM BLOCO de uma história maior!
   Se o CONTEXTO mostra que Mateus JÁ recebeu o cartão de Otávio,
   você NÃO PODE escrever a cena dele recebendo o cartão NOVAMENTE!

❌ PROIBIDO FAZER:
   • Recontar cenas que já aconteceram no CONTEXTO
   • Reescrever o início da história (ex: "Mateus olhava o relógio...")
   • Repetir a mesma reviravolta (ex: "o idoso revelou ser um magnata")
   • Narrar eventos passados como se fossem novos

✅ VOCÊ DEVE:
   • CONTINUAR de onde o CONTEXTO parou
   • Avançar para NOVOS eventos que ainda não aconteceram
   • Progredir a trama cronologicamente

📊 TESTE MENTAL ANTES DE ESCREVER:
   1. Leia o CONTEXTO fornecido
   2. Identifique QUAL É O ÚLTIMO EVENTO narrado
   3. Comece SEU BLOCO logo APÓS esse evento
   
   EXEMPLO:
   Se o CONTEXTO termina com "Mateus foi nomeado CEO"
   → Seu bloco deve começar DEPOIS disso (ex: "Nos meses seguintes, Mateus...")
   → NÃO reescreva a cena de nomeação!

🔴 SE VOCÊ RECONTAR A HISTÓRIA DO INÍCIO, O BLOCO SERÁ REJEITADO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5️⃣ **RESTRIÇÃO DE REPETIÇÃO (ANTI-ECHO) 🚫:**
   - É PROIBIDO repetir frases inteiras, ditados populares ou metáforas usadas no bloco anterior!
   - Se o personagem já lembrou de um conselho do pai/mãe/avó recentemente, NÃO repita a mesma lembrança.
   - Crie uma NOVA reflexão ou foque no PRESENTE da cena.
   - Cada bloco deve trazer NOVAS descrições. Não descreva o cenário com as mesmas palavras!
   
   🚨🚨🚨 REGRA CRÍTICA v7.6.134: FORESHADOWING = EXATAMENTE 4x! 🚨🚨🚨
   
   ⚠️ PROBLEMA v7.6.133: Frase inspiracional apareceu 9x = SPAM!
   
   ❌ ERRO GRAVÍSSIMO (roteiro rejeitado - 9x a mesma frase):
      Bloco 2: "A bondade é a moeda que nunca perde o valor" ← 1ª (OK)
      Bloco 4: "A bondade é a moeda que nunca perde o valor" ← 2ª (OK)
      Bloco 6: "A bondade é a moeda que nunca perde o valor" ← 3ª (OK)
      Bloco 8: "A bondade é a moeda que nunca perde o valor" ← 4ª (OK - ÚLTIMA!)
      Bloco 10: "A bondade é a moeda que nunca perde o valor" ← 5ª (PROIBIDO!)
      Bloco 12: "A bondade é a moeda que nunca perde o valor" ← 6ª (PROIBIDO!)
      Bloco 14: "A bondade é a moeda que nunca perde o valor" ← 7ª (SPAM!)
      Bloco 15: "A bondade é a moeda que nunca perde o valor" ← 8ª (SPAM!)
      Bloco 16: "A bondade é a moeda que nunca perde o valor" ← 9ª (INSUPORTÁVEL!)
      
      RESULTADO: Frase repetida 9 vezes = IRRITANTE para espectador!
   
   ✅ FORMA CORRETA (exatamente 4x nos pontos estratégicos):
      Bloco ~15%: "Como dizia meu pai: a vida é um rio..." ← 1ª (introdução)
      Bloco ~45%: "Lembrei das palavras de meu pai: a vida é um rio..." ← 2ª (desenvolvimento)
      Bloco ~70%: "A vida é um rio, pensei." ← 3ª (pré-clímax)
      Bloco ~95%: "A vida é um rio. Agora eu entendia." ← 4ª (resolução - ÚLTIMA!)
      
      Blocos intermediários: SEM a frase! Avance a história normalmente.
   
   📊 CONTADOR MENTAL OBRIGATÓRIO v7.6.134:
      • 1ª menção (~15%) → OK, introduz a frase
      • 2ª menção (~45%) → OK, relembra
      • 3ª menção (~70%) → OK, ganha significado
      • 4ª menção (~95%) → OK, fechamento - ÚLTIMA!
      • 5ª+ menção → PROIBIDO! Virou spam!
   
   📍 POSICIONAMENTO ESTRATÉGICO:
      • Bloco 15% = Apresentação da frase (pai/avó ensina)
      • Bloco 45% = Lembra no meio de crise (força para agir)
      • Bloco 70% = Antes do clímax (motivação final)
      • Bloco 95% = Fechamento (compreensão completa)
   
   ⚠️ REGRA DE OURO v7.6.134: EXATAMENTE 4x, NEM MAIS, NEM MENOS!
      • Menos de 4x = Foreshadowing incompleto
      • Mais de 4x = SPAM irritante para espectador!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎬🎬🎬 REGRAS CRÍTICAS YOUTUBE (PRIORIDADE MÁXIMA) 🎬🎬🎬
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️⚠️⚠️ LEIA ISTO PRIMEIRO - NÃO PULE! ⚠️⚠️⚠️

🚨🚨🚨 CHECKLIST OBRIGATÓRIO - RESPONDA ANTES DE COMEÇAR A ESCREVER! 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ PARE! NÃO COMECE A ESCREVER SEM RESPONDER ESTAS 5 PERGUNTAS:

📋 PERGUNTA 1: "Posso explicar TODO o roteiro em 2 frases SEM usar 'e depois'?"
   
   ✅ EXEMPLO CORRETO:
   "Mãe roubada pelo filho descobre terreno valioso esquecido.
   Ela usa terreno para criar armadilha que leva filho à ruína."
   → 2 frases, 1 história linear! ✅
   
   ❌ EXEMPLO ERRADO:
   "Mãe constrói negócio de bolos e depois enfrenta vilão empresarial
   e depois o filho é preso pela polícia federal."
   → Precisa de "e depois" = Múltiplas histórias! ❌
   
   ⚠️ SE VOCÊ PRECISOU USAR "E DEPOIS" → Você tem MÚLTIPLAS HISTÓRIAS!
   ⚠️ SOLUÇÃO: Consolidar tudo em 1 objetivo central único!

📋 PERGUNTA 2: "Quantos personagens COM NOME vou usar?"
   
   ✅ RESPOSTA CORRETA: 6 ou menos
   ❌ RESPOSTA ERRADA: 7, 8, 9, 10, 11, 12+
   
   🔥 TESTE EXTRA: "Algum personagem faz função que OUTRO já faz?"
   → SIM = CONSOLIDAR (1 pessoa faz 2 papéis)
   → NÃO = Pode continuar
   
   ⚠️ SE VOCÊ TEM 7+ PERSONAGENS → Consolidação obrigatória!
   ⚠️ SE 2 FAZEM MESMA COISA → Elimine 1 e dê funções extras ao outro!

📋 PERGUNTA 3: "Todos os vilões/conflitos que apareceram serão RESOLVIDOS?"
   
   ✅ EXEMPLO CORRETO:
   "Vilão Augusto rouba negócio → Protagonista descobre fraude → Augusto preso"
   → Conflito introduzido E resolvido! ✅
   
   ❌ EXEMPLO ERRADO:
   "Vilão Augusto tenta roubar negócio → [Augusto desaparece sem explicação]"
   → Conflito introduzido mas NUNCA resolvido! ❌
   
   ⚠️ SE VOCÊ INTRODUZIU VILÃO → Ele DEVE ser derrotado/resolvido até o final!
   ⚠️ PROIBIDO: Vilão desaparecer misteriosamente sem conclusão!

📋 PERGUNTA 4: "Protagonista CAUSA os resultados ou só ASSISTE TV?"
   
   ✅ EXEMPLO CORRETO:
   "Protagonista investiga → descobre provas → entrega à polícia → vilão preso"
   → Protagonista é AGENTE ATIVO que causa prisão! ✅
   
   ❌ EXEMPLO ERRADO:
   "Protagonista faz bolos → polícia prende vilão sozinha → protagonista vê na TV"
   → Protagonista é ESPECTADOR passivo! ❌
   
   ⚠️ PROTAGONISTA DEVE: Descobrir, planejar, executar, causar resultados!
   ⚠️ PROIBIDO: Protagonista assistir TV enquanto outros resolvem!

📋 PERGUNTA 5: "Nos últimos 35% vou MOSTRAR a queda ou só CONTAR?"
   
   ✅ EXEMPLO CORRETO (MOSTRAR):
   "Banco executa dívida → Boutique leiloada (cena detalhada) →
   Carro apreendido (cena) → Mudança forçada (cena) → Apartamento pequeno (cena)"
   → Leitor VIVE cada momento da queda! ✅
   
   ❌ EXEMPLO ERRADO (CONTAR):
   "Seis meses depois, ele foi preso. Vi na TV."
   → Leitor é INFORMADO, não SENTE! ❌
   
   ⚠️ ÚLTIMOS 35% = Queda VISCERAL e DETALHADA, cena por cena!
   ⚠️ PROIBIDO: Saltar tempo ("meses depois") ou resumir ("foi preso")!

📋 PERGUNTA 6: "Qual nome do protagonista vou usar do INÍCIO ao FIM?"
   
   ✅ EXEMPLO CORRETO:
   "Bloco 1: 'eu sou Luzia' → Blocos 2-18: SEMPRE 'Luzia'"
   → 1 NOME ÚNICO em toda a história! ✅
   
   ❌ EXEMPLO ERRADO:
   "Blocos 1-10: 'Luzia' → Blocos 11-18: 'Marta' (mudou!)"
   → Nome do protagonista MUDOU no meio! ❌
   
   ⚠️ DECIDA O NOME NO BLOCO 1 → Use o MESMO nome nos 18 blocos!
   ⚠️ PROIBIDO: Mudar nome do protagonista por qualquer motivo!
   
   💡 LEMBRE-SE: Protagonista é narrador, seu nome é identidade constante!

🎯 REGRA DE OURO:
   ✅ SE RESPONDEU SIM A TODAS → Pode começar a escrever!
   ❌ SE RESPONDEU NÃO A ALGUMA → Replaneje ANTES de escrever!
   
   💡 ESTAS 6 PERGUNTAS PREVINEM 98% DOS ERROS GRAVES!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 REGRA #1: MÁXIMO 6 PERSONAGENS COM NOME (v7.6.134 - VALIDAÇÃO RIGOROSA)

   ⚠️⚠️⚠️ ATENÇÃO MÁXIMA: LIMITE ABSOLUTO = 6 NOMES! ⚠️⚠️⚠️
   
   📋 DISTRIBUIÇÃO PERMITIDA:
   • 1 Protagonista (narrador) ← OBRIGATÓRIO
   • 1-2 Antagonistas principais ← MÁXIMO 2
   • 2-3 Secundários (aliados, família nuclear) ← MÁXIMO 3
   
   🔢 CONTADOR OBRIGATÓRIO - ANTES DE NOMEAR QUALQUER PERSONAGEM:
   □ Personagem 1 (protagonista): ________________
   □ Personagem 2 (antagonista 1): ________________
   □ Personagem 3 (antagonista 2 OU aliado): ________________
   □ Personagem 4 (secundário): ________________
   □ Personagem 5 (secundário): ________________
   □ Personagem 6 (secundário): ________________
   ✋ PAROU AQUI! 7º nome = ROTEIRO REJEITADO!
   
   ❌ PROIBIDO NOMEAR (use descrição genérica):
   • Beneficiários de programas ("uma jovem", não "Sofia")
   • Testemunhas ("o vizinho", não "Roberto")
   • Figurantes ("o garçom", não "Paulo")
   • Profissionais de apoio ("a recepcionista", não "Mariana")
   • Familiares distantes ("o tio", não "Ernesto")
   
   ✅ CORRETO: Outros familiares = "meu pai", "minha mãe" (sem nome próprio)
   ✅ CORRETO: Exemplos de sucesso = "uma jovem", "um rapaz", "um empresário"
   
   🔴 PENALIDADE v7.6.134:
   • 7 personagens = Nota -0.5 (GRAVE)
   • 8 personagens = Nota -1.0 (MUITO GRAVE) + REJEIÇÃO
   • 9+ personagens = ROTEIRO DESCARTADO AUTOMATICAMENTE
   
⚠️ REGRA CRÍTICA v7.6.129 - PERSONAGENS "EXEMPLO" NÃO LEVAM NOME:
   
   ❌ ERRADO (8 nomes - 2 são exemplos desnecessários):
   "Mateus ajudou Clara, filha de faxineira, que entrou em medicina.
    Também ajudou Roberto, do interior, que virou engenheiro.
    O empresário Gustavo ficou impressionado e doou milhões."
   → Problema: Clara/Roberto/Gustavo têm mesma função (mostrar impacto)
   → Solução: NÃO dar nomes a eles!
   
   ✅ CORRETO (6 nomes - exemplos sem nome mantêm impacto):
   "Mateus ajudou centenas de jovens. Uma delas, filha de faxineira,
    conseguiu entrar em medicina. Um rapaz do interior realizou o sonho
    de ser engenheiro. Até empresários milionários se impressionaram
    com o programa e doaram recursos."
   → Impacto mantido: ✅ Ainda é emocionante!
   → Memória: ✅ Público lembra dos 6 principais!
   → YouTube: ✅ Retenção 65-75% (vs 45-60% com 8+)

� CONSOLIDAÇÃO OBRIGATÓRIA - EVITE PERSONAGENS REDUNDANTES:

📌 TESTE MENTAL ANTES DE CRIAR PERSONAGEM:
   ❓ "Este personagem faz função ÚNICA ou outro já faz isso?"
   → ÚNICA = Pode criar ✅
   → OUTRO JÁ FAZ = CONSOLIDAR (1 pessoa faz 2 papéis) ✅

❌ ERRO REAL DETECTADO (roteiro com 12 personagens):

   🔴 Personagens Redundantes (ELIMINAR):
   ❌ Ademir (fornecedor roubado) + Clementino (novo fornecedor) = 2 FAZEM A MESMA COISA
      ✅ SOLUÇÃO: Ter apenas 1 fornecedor especial desde o início
   
   ❌ Marcos (dono de café) + Custódio (distribuidor) = 2 FAZEM A MESMA COISA
      ✅ SOLUÇÃO: Marcos É dono do café E distribui (1 pessoa, 2 funções)
   
   ❌ Paulo (fiscal) + Rogério (fiscal assistente mudo) = 2 FAZEM A MESMA COISA
      ✅ SOLUÇÃO: Apenas Paulo fiscaliza sozinho
   
   ❌ Valdir (zelador que prova bolo 1x e nunca mais aparece) = PERSONAGEM DESCARTÁVEL
      ✅ SOLUÇÃO: Cliente anônimo no café prova (sem nome)

   🔴 Resultado do Erro:
   • 12 personagens nomeados
   • Público confuso
   • Vozes indistinguíveis
   • Nota caiu de 9.4 para 7.5 ❌

   ✅ Resultado da Consolidação:
   • 6-7 personagens nomeados
   • Cada um com papel ÚNICO
   • Vozes memoráveis
   • Nota 9.0+ ✅

🎯 EXEMPLOS DE CONSOLIDAÇÃO CORRETA:

✅ Em vez de: "Advogado A + Advogado B"
   → Usar: 1 advogado que faz ambos os papéis

✅ Em vez de: "Ricardo (advogado antigo) + Júlio (amigo do pai, advogado)"
   → Usar: "Ricardo (advogado e amigo do pai)" ✅

✅ Em vez de: "Fornecedor perdido + Novo fornecedor"
   → Usar: 1 fornecedor leal desde o início

✅ Em vez de: "Sócio + Distribuidor + Contador"
   → Usar: 1 sócio que também distribui e cuida das contas

✅ Em vez de: "Vizinho A (1 cena) + Porteiro B (1 cena) + Garçom C (1 cena)"
   → Usar: Menções genéricas sem nomes ("o vizinho", "o porteiro")

✅ Em vez de: "Larissa (vizinha que informa) + Ana (amiga que conta fofoca)"
   → Usar: "Larissa (vizinha)" fazendo ambas funções ✅

🚨 REGRA ABSOLUTA v7.5:
   • Se 2 personagens fazem FUNÇÃO SIMILAR = CONSOLIDAR em 1
   • Se personagem aparece 1x e nunca mais = NÃO DAR NOME
   • Se personagem não fala/age = NÃO DAR NOME (é figurante)
   • ANTES de criar personagem novo = PERGUNTAR: "Já tenho alguém que faz isso?"
   
💡 LIMITE REAL PARA ROTEIROS LONGOS (10-12k palavras):
   • Roteiro 8-10k palavras: 6 personagens MAX ✅
   • Roteiro 10-12k palavras: 7 personagens LIMITE ABSOLUTO ⚠️
   • Roteiro 12k+ palavras: 8 personagens EXCEPCIONAL (só se TODOS forem únicos)

�🚨 REGRA #2: 5 GANCHOS OBRIGATÓRIOS (A CADA 1.000 PALAVRAS)
   
   🎣 GANCHO 1 (primeiras 200 palavras):
   "[VILÃO] me [AÇÃO TERRÍVEL]. Mas eles não sabiam de [SEGREDO].
   Esta é a história de como [PROMESSA DE VINGANÇA]..."
   
   🎣 GANCHO 2 (~1.200 palavras / 12%):
   "Quando [AÇÃO], eu pensei ter encontrado [ITEM].
   Mas [DETALHE INTRIGANTE]... Era [REVELAÇÃO PARCIAL].
   Mas eu ainda não sabia [NOVA PERGUNTA]..."
   
   🎣 GANCHO 3 (~3.000 palavras / 30%):
   "Eu achava que tinha [SOLUÇÃO].
   Mas quando [PESSOA] [AÇÃO]... seu rosto [REAÇÃO ESTRANHA].
   [FRASE MISTERIOSA]. [PERGUNTA QUE COMPLICA]"
   
   🎣 GANCHO 4 (~5.000 palavras / 50%):
   "Finalmente, eu tinha [ARMAS/PROVAS].
   [VILÕES] não faziam ideia do que estava vindo.
   Em [TEMPO], eles estariam [DESTINO RUIM]...
   Mas primeiro... eu precisava [AÇÃO FINAL]."
   
   🎣 GANCHO 5 (~6.500 palavras / 65%):
   "[AÇÃO DE ENTRADA]. [VILÃO] estava [AÇÃO TRANQUILA].
   Quando me viu, [REAÇÃO].
   [AÇÃO COM OBJETO/PROVA]. [palavra única], eu disse.
   E [RESULTADO DRAMÁTICO]."

🚨 REGRA #3: ÚLTIMOS 35% = SHOW, DON'T TELL (QUEDA VISCERAL OBRIGATÓRIA)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️⚠️⚠️ ERRO CRÍTICO MAIS COMUM: CONTAR em vez de MOSTRAR! ⚠️⚠️⚠️

❌❌❌ EXEMPLOS DE "CONTAR" (PROIBIDO NOS ÚLTIMOS 35%):

   ❌ "Seis meses depois, ele foi preso."
   → PROBLEMA: Salto temporal brutal, leitor perde a experiência!
   
   ❌ "Vi na televisão que a boutique tinha sido fechada."
   → PROBLEMA: Informação indireta, sem emoção!
   
   ❌ "Eles perderam tudo e ficaram arruinados."
   → PROBLEMA: Resumo genérico, leitor não SENTE a ruína!
   
   ❌ "A justiça foi feita e ele pagou pelos crimes."
   → PROBLEMA: Conclusão abstrata, sem cenas viscerais!
   
   ❌ "Depois de muito sofrimento, ele foi para a prisão."
   → PROBLEMA: "Muito sofrimento" não mostra NADA concreto!

✅✅✅ EXEMPLOS DE "MOSTRAR" (OBRIGATÓRIO NOS ÚLTIMOS 35%):

   ✅ CENA 1 - Ligação do banco (200 palavras):
   "O telefone de Sérgio tocou às 9h da manhã. Era o gerente do banco.
   'Senhor Sérgio, a dívida de R\$3 milhões venceu ontem. Precisamos
   iniciar o processo de execução.' Sérgio deixou o telefone cair.
   Suas mãos tremiam. Bianca, ao lado, perguntou 'O que foi?'.
   Ele não conseguiu falar. Apenas apontou para o celular no chão."
   → Leitor VIVE o momento do colapso! ✅
   
   ✅ CENA 2 - Oficial de justiça na boutique (250 palavras):
   "Dois dias depois, cheguei perto da boutique de Bianca.
   Uma faixa amarela e preta cobria a porta de vidro:
   'LEILÃO JUDICIAL - ARREMATAÇÃO DE BENS'.
   Um pequeno grupo de curiosos se aglomerava na calçada.
   Reconheci algumas amigas de Bianca, aquelas que postavam
   fotos com ela em jantares caros. Agora sussurravam entre si,
   olhando para a placa com pena e satisfação.
   Um homem de terno cinza abriu a porta. Era o leiloeiro.
   'Lote 1: manequins importados. Quem dá lance?'
   Uma mulher arrematou o estoque por um terço do valor.
   Em duas horas, não sobrou nada."
   → Leitor VIVE cada momento da humilhação! ✅
   
   ✅ CENA 3 - Mudança forçada (200 palavras):
   "Na manhã seguinte, passei em frente ao antigo apartamento deles.
   Sérgio e Bianca colocavam malas num carro popular alugado.
   Não era mais a BMW prata. Era um Gol branco amassado.
   Bianca carregava uma mala pesada, de salto alto, tropeçando
   na calçada. Sérgio gritou algo que não ouvi.
   O porteiro os observava da entrada, braços cruzados.
   Antigamente ele os cumprimentava com reverência.
   Agora, apenas olhava com indiferença."
   → Leitor VIVE a degradação social! ✅
   
   ✅ CENA 4 - Novo apartamento (200 palavras):
   "O novo endereço era um prédio de três andares sem elevador.
   Apartamento 203. Subi as escadas atrás deles, mantendo distância.
   Quando Sérgio abriu a porta, Bianca ficou parada na entrada.
   Era um quarto e sala. Paredes com tinta descascada.
   Uma mancha de umidade subia pela parede da cozinha.
   Exatamente como o meu apartamento.
   Bianca começou a chorar. Não era choro dramático.
   Era um choro baixo, quebrado, de quem finalmente entendeu."
   → Leitor VIVE a inversão do destino! ✅

🎯 ESTRUTURA OBRIGATÓRIA DOS ÚLTIMOS 35% (mínimo 1.500 palavras):

   📍 MOMENTO 1: Descoberta da ruína (200-250 palavras)
   → Ligação do banco, carta judicial, visita de oficial
   → Reação emocional: pânico, negação, desespero
   → Diálogos reais, não resumos
   
   📍 MOMENTO 2: Primeira perda pública (200-250 palavras)
   → Boutique leiloada, carro apreendido, conta bloqueada
   → Detalhes sensoriais: placa amarela, sirene, silêncio
   → Testemunhas (curiosos, vizinhos, ex-amigos)
   
   📍 MOMENTO 3: Desmoronamento social (200-250 palavras)
   → Clube cancela associação, amigos não atendem, manchetes
   → Cenas específicas: recepcionista educada agora fria
   → Contraste: "antigamente... agora..."
   
   📍 MOMENTO 4: Mudança forçada (200-250 palavras)
   → Saindo do apartamento de luxo
   → Chegando no apartamento simples
   → Objetos concretos: malas, móveis velhos, parede descascada
   
   📍 MOMENTO 5: Confronto final (300-400 palavras)
   → Encontro cara a cara (prisão, novo endereço, rua)
   → Diálogo direto com reconhecimento/arrependimento
   → Resolução emocional do protagonista

🚨 PALAVRAS E FRASES PROIBIDAS NOS ÚLTIMOS 35%:

   ❌ "Meses depois..."
   ❌ "Anos se passaram..."
   ❌ "Eventualmente ele foi preso..."
   ❌ "Eles perderam tudo..."
   ❌ "A justiça foi feita..."
   ❌ "Vi na TV que..."
   ❌ "Soube depois que..."
   ❌ "Ele pagou pelo que fez..."

✅ PALAVRAS E CONSTRUÇÕES OBRIGATÓRIAS:

   ✅ "Duas horas depois..." (curto prazo)
   ✅ "Na manhã seguinte..." (continuidade)
   ✅ "O telefone tocou..." (cena específica)
   ✅ "Parei em frente a..." (presença física)
   ✅ "Ouvi o som de..." (detalhe sensorial)
   ✅ "A placa dizia..." (objeto concreto)
   ✅ "Ele segurava..." (ação específica)
   ✅ "Suas mãos tremiam..." (detalhe emocional)

💡 TESTE MENTAL PARA CADA PARÁGRAFO DOS ÚLTIMOS 35%:

   ❓ "O leitor consegue VISUALIZAR esta cena como um filme?"
   → SIM = Continue ✅
   → NÃO = Reescreva com mais detalhes concretos ❌
   
   ❓ "Estou MOSTRANDO ações e diálogos ou RESUMINDO?"
   → MOSTRANDO = Continue ✅
   → RESUMINDO = Expanda em cena completa ❌
   
   ❓ "Usei algum salto temporal maior que '3 dias depois'?"
   → NÃO = Continue ✅
   → SIM = Elimine salto e mostre os dias intermediários ❌

🎬 EXEMPLO COMPLETO DE QUEDA BEM FEITA (últimos 35%):

Cena 1: Ligação do banco (250 pal)
Cena 2: Oficial avalia bens (200 pal)
Cena 3: Leilão da boutique (250 pal)
Cena 4: Carro apreendido (150 pal)
Cena 5: Mudança forçada (200 pal)
Cena 6: Novo apartamento (200 pal)
Cena 7: Vizinhos comentando (150 pal)
Cena 8: Sérgio tenta ligar (100 pal)
Cena 9: Confronto final - visita (400 pal)
Cena 10: Resolução - protagonista em nova casa (300 pal)

TOTAL: ~2.200 palavras de queda VISCERAL ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ SE VOCÊ RESUMIR A QUEDA = ROTEIRO REJEITADO!
✅ SE VOCÊ MOSTRAR CADA CENA = ROTEIRO NOTA 9.0+!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 REGRA #4: VILÃO 95% MALVADO + 5% HUMANO NO FIM
   • Ato 1: Vilão RI, ZOMBA, HUMILHA (sem piedade!)
   • Ato 2: Vilão em PODER (ostentando, pisando em cima)
   • Ato 3: Vilão CAI + 1 momento de arrependimento (50 palavras)

🚨 REGRA #5: ATO 3 COMPACTO (v7.6.134 - MÁXIMO 2 BLOCOS PÓS-CLÍMAX)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ⚠️ ERRO REAL DETECTADO: Ato 3 com 6 blocos APÓS o clímax!
   
   ❌ ERRADO (roteiro inflado):
   Bloco 10: Vilão é preso (CLÍMAX) ← Aqui deveria acelerar!
   Bloco 11: Protagonista reflete... (arrastado)
   Bloco 12: Protagonista visita projeto... (arrastado)
   Bloco 13: Protagonista em reunião... (arrastado)
   Bloco 14: Vilão na prisão... (arrastado)
   Bloco 15: Protagonista celebra... (arrastado)
   Bloco 16: Mais reflexões... (arrastado)
   → PROBLEMA: 6 blocos de "vitória lap" = TEDIOSO!
   
   ✅ CORRETO (Ato 3 compacto):
   Bloco 10: Vilão é preso (CLÍMAX)
   Bloco 11: Queda detalhada do vilão + confronto final
   Bloco 12: Resolução emocional + fechamento (FIM!)
   → RESULTADO: História termina no ponto alto!
   
   📋 REGRA ABSOLUTA:
   • Após CLÍMAX (prisão/derrota do vilão) = MÁXIMO 2 blocos!
   • Bloco Pós-Clímax 1: Consequências imediatas (queda visceral)
   • Bloco Pós-Clímax 2: Fechamento emocional (resolução)
   • NÃO adicione blocos extras de "dias depois", "meses depois"!
   
   💡 COMO IDENTIFICAR O CLÍMAX:
   • Vilão preso/derrotado
   • Verdade revelada publicamente
   • Protagonista vence confronto decisivo
   → Após isso = ACELERE e TERMINE!
   
   🔴 PENALIDADE: Mais de 2 blocos pós-clímax = -0.5 na nota!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨🚨🚨 TABELA DE PENALIDADES - CONSEQUÊNCIAS POR VIOLAR REGRAS 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ ESTAS NÃO SÃO SUGESTÕES - SÃO REGRAS ABSOLUTAS COM PENALIDADES REAIS!

┌─────────────────────────────────────────────────────────────────────┐
│ VIOLAÇÃO #1: Múltiplas Histórias Paralelas                          │
├─────────────────────────────────────────────────────────────────────┤
│ ❌ SE VOCÊ FIZER:                                                    │
│    • 2+ objetivos centrais competindo                                │
│    • Nova história começa no meio (vilão que surge e some)          │
│    • Protagonista resolve objetivo 1, depois começa objetivo 2       │
│                                                                      │
│ 🔻 PENALIDADE:                                                       │
│    • Nota CAI de 9.0+ para 6.5-7.5                                  │
│    • Retenção CAI 40%                                                │
│    • Personagens sobem para 10-12 (fragmentação)                    │
│    • ROTEIRO MARCADO COMO "NECESSITA REVISÃO"                       │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ VIOLAÇÃO #2: Mais de 6 Personagens Nomeados                         │
├─────────────────────────────────────────────────────────────────────┤
│ ❌ SE VOCÊ FIZER:                                                    │
│    • 7, 8, 9, 10+ personagens com nome                              │
│    • 2 personagens fazendo mesma função sem consolidar              │
│    • Dar nome a figurante que aparece 1x                            │
│                                                                      │
│ 🔻 PENALIDADE:                                                       │
│    • Nota CAI -0.3 pontos por cada personagem extra                 │
│    • 7 personagens = -0.3 (nota 8.7)                                │
│    • 8 personagens = -0.6 (nota 8.4)                                │
│    • 9+ personagens = -1.0+ (nota 8.0 ou menos)                     │
│    • Público fica confuso, retenção CAI                             │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ VIOLAÇÃO #3: Últimos 35% Resumidos (CONTAR em vez de MOSTRAR)      │
├─────────────────────────────────────────────────────────────────────┤
│ ❌ SE VOCÊ FIZER:                                                    │
│    • "Meses depois ele foi preso" (salto temporal)                  │
│    • "Vi na TV que perderam tudo" (informação indireta)             │
│    • "Eles foram arruinados" (resumo sem cenas)                     │
│    • Últimos 35% com menos de 1.500 palavras                        │
│                                                                      │
│ 🔻 PENALIDADE:                                                       │
│    • Nota CAI de 9.0+ para 7.0-8.0                                  │
│    • Catarse FRACA (público não sente vingança)                     │
│    • Comentários: "Final apressado", "Esperava mais"                │
│    • IMPACTO EMOCIONAL praticamente ZERO                            │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ VIOLAÇÃO #4: Protagonista Passivo (assiste em vez de agir)         │
├─────────────────────────────────────────────────────────────────────┤
│ ❌ SE VOCÊ FIZER:                                                    │
│    • Protagonista constrói bolos enquanto polícia prende vilão      │
│    • Protagonista vê resultados na TV/jornal                        │
│    • Outros personagens resolvem o conflito central                 │
│    • Protagonista não CAUSA os resultados finais                    │
│                                                                      │
│ 🔻 PENALIDADE:                                                       │
│    • Nota CAI -1.5 pontos (de 9.0 para 7.5)                        │
│    • Catarse INEXISTENTE (público frustra)                          │
│    • Comentários: "Protagonista fraco", "Sem agência"               │
│    • Retenção CAI 30% (público desiste no clímax)                  │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ VIOLAÇÃO #5: Vilão/Conflito Não Resolvido                           │
├─────────────────────────────────────────────────────────────────────┤
│ ❌ SE VOCÊ FIZER:                                                    │
│    • Introduzir vilão que nunca é derrotado                         │
│    • Vilão desaparece sem explicação                                │
│    • Conflito central não tem resolução                             │
│    • "Esquece" de mencionar destino de antagonista                  │
│                                                                      │
│ 🔻 PENALIDADE:                                                       │
│    • Nota CAI -2.0 pontos (de 9.0 para 7.0)                        │
│    • Público FRUSTRADO (espera resolução que não vem)               │
│    • Comentários: "E o vilão?", "História incompleta"               │
│    • Taxa de abandono ALTA (50%+ desistem)                          │
└─────────────────────────────────────────────────────────────────────┘

🎯 NOTA FINAL DO ROTEIRO = CÁLCULO COM PENALIDADES:

   NOTA BASE: 9.5 (roteiro tecnicamente perfeito)
   
   ➖ Múltiplas histórias: -2.0 pontos
   ➖ Cada personagem extra: -0.3 pontos
   ➖ Últimos 35% resumidos: -1.5 pontos
   ➖ Protagonista passivo: -1.5 pontos
   ➖ Vilão não resolvido: -2.0 pontos
   
   NOTA MÍNIMA ACEITÁVEL: 8.5
   NOTA EXCELENTE: 9.0-9.5
   NOTA WORLD-CLASS: 9.3-9.7

💡 EXEMPLO REAL DE PENALIDADES ACUMULADAS:

   Roteiro com:
   • 3 histórias paralelas: -2.0
   • 11 personagens (5 extras): -1.5 (-0.3 × 5)
   • Últimos 35% resumidos: -1.5
   • Protagonista assiste TV: -1.5
   
   NOTA FINAL: 9.5 - 6.5 = 3.0/10 ❌❌❌
   
   RESULTADO: Roteiro REJEITADO completamente!

✅ PARA ALCANÇAR NOTA 9.0+ VOCÊ DEVE:

   ✅ 1 história linear (não 2-3)
   ✅ 6 personagens nomeados (não 7-12)
   ✅ Últimos 35% = 10 cenas detalhadas (não resumo)
   ✅ Protagonista causa resultados (não assiste TV)
   ✅ Todos vilões derrotados (não desaparecem)
   ✅ Foreshadowing 4x (frase repetida)
   ✅ 5 ganchos estratégicos

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ESTAS PENALIDADES SÃO REAIS E CALCULADAS AUTOMATICAMENTE!
✅ SIGA AS REGRAS = NOTA 9.0+ GARANTIDA!
❌ IGNORE AS REGRAS = NOTA < 7.0 E ROTEIRO REJEITADO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SE VOCÊ SEGUIR ESTAS REGRAS = ROTEIRO PERFEITO PARA YOUTUBE!
❌ SE IGNORAR = ROTEIRO SERÁ REJEITADO COM NOTA BAIXA!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 ERROS CRÍTICOS v7.6 - EVITE ISTO! 🚨

❌ ERRO #1: Mudar nome do protagonista no meio da história
ERRADO: Blocos 1-10 "Luzia" → Blocos 11-18 "Marta"
CERTO: Escolha 1 NOME no bloco 1 e USE O MESMO em TODOS os 18 blocos
⚠️ CRÍTICO: Protagonista = 1 NOME ÚNICO do início ao fim!
📝 EXEMPLO REAL DO ERRO:
   • Bloco 1: "eu estava sentada no meio-fio" (narrativa de Luzia)
   • Bloco 13: "dona Marta, a senhora pode entrar" (virou Marta!) ❌
   • RESULTADO: Leitor confuso - "Quem é Marta? Cadê Luzia?"
✅ SOLUÇÃO: Decidir nome no Bloco 1 e manter em TODOS os blocos!

❌ ERRO #2: Resumir últimos 35%
ERRADO: "cartões bloqueados. joias vendidas."
CERTO: CENA 200 pal → supermercado, cartão recusado, fila, vergonha, vomitou

❌ ERRO #3: Saltos temporais APÓS 65% (INCLUINDO BLOCOS FINAIS!)
⚠️ CRÍTICO: Blocos 13-18 (últimos 35%) = ZERO saltos > 3 dias!
⚠️ ATENÇÃO: Esta regra vale ATÉ O ÚLTIMO BLOCO (inclusive 17 e 18)!

EXEMPLOS DE ERRO GRAVE (Blocos 13-18):
❌ BLOCO 13: "na semana seguinte" (7 dias) → VIOLA REGRA
❌ BLOCO 15: "duas semanas depois" (14 dias) → VIOLA REGRA
❌ BLOCO 17: "três meses depois" (90 dias) → ERRO GRAVÍSSIMO! ❌❌❌
❌ BLOCO 18: "um ano depois" (365 dias) → ERRO GRAVÍSSIMO! ❌❌❌

⚠️ ERRO COMUM - "Mas é o final, preciso mostrar a paz depois":
   ❌ ERRADO: "três meses depois, eu estava em paz"
   ✅ CERTO: "três dias depois do julgamento, acordei em paz"
   
   → Você PODE mostrar paz no final
   → Mas SEM pular > 3 dias!

EXEMPLOS CORRETOS (Blocos 13-18, INCLUINDO O FINAL):
✅ BLOCO 13: "no dia seguinte" (1 dia)
✅ BLOCO 14: "dois dias depois" (2 dias)
✅ BLOCO 15: "três dias depois" (3 dias - MÁXIMO!)
✅ BLOCO 16: "naquela mesma noite" (horas)
✅ BLOCO 17: "na manhã seguinte ao julgamento" (1 dia) ← FINAL!
✅ BLOCO 18: "naquele mesmo dia" (horas) ← CONCLUSÃO!

📋 CHECKLIST MENTAL PARA BLOCOS 13-18:

   ❓ "Estou escrevendo Bloco 13 ou posterior?" → SIM
   ❓ "Vou usar salto temporal?" → SIM
   ❓ "O salto é > 3 dias?" → SE SIM: PARE! ❌
   
   ✅ Troque por: "no dia seguinte" / "dois dias depois" / "três dias depois"
   
💡 DICA PARA O FINAL (Blocos 17-18):
   ❌ Não use: "meses depois" / "anos depois" / "tempos depois"
   ✅ Use: "dias depois" / "naquela semana" / "na manhã seguinte"
   
   → O LEITOR QUER VER O FINAL IMEDIATO!
   → Não o faça esperar meses em resumo!

⚠️ ESTA REGRA NÃO TEM EXCEÇÃO:
   → Vale para Bloco 13 ✅
   → Vale para Bloco 14 ✅
   → Vale para Bloco 15 ✅
   → Vale para Bloco 16 ✅
   → Vale para Bloco 17 ✅ ← FINAL TAMBÉM!
   → Vale para Bloco 18 ✅ ← CONCLUSÃO TAMBÉM!

❌ ERRO #4: Personagens com MESMO NOME ou papéis duplicados
⚠️ CRÍTICO: CADA NOME só pode ser usado UMA VEZ no roteiro inteiro!

TIPOS DE DUPLICAÇÃO PROIBIDOS:

1️⃣ MESMO NOME para personagens diferentes:
❌ ERRADO: "Artur" (advogado) + "senhor Artur" (dono confeitaria)
❌ ERRADO: "Ricardo" (sócio) + "Ricardo" (investigador)
❌ ERRADO: "Ana" (mãe) + "Ana" (vizinha)
✅ CERTO: Cada personagem tem nome ÚNICO E DIFERENTE

⚠️ ERRO COMUM: REUSAR NOME de personagem anterior
❌ ERRO REAL v7.6.3 (Carro 300mil):
   • Bloco 13: "César" (cliente aposentado da rotisseria)
   • Bloco 17: "César" (oficial de justiça) ← MESMO NOME! ERRO!
   → Problema: 2 pessoas DIFERENTES, 1 NOME = confusão total!

✅ CORRETO:
   • Bloco 13: "César" (cliente aposentado)
   • Bloco 17: "Roberto" (oficial de justiça) ← NOME DIFERENTE!
   → Solução: Cada pessoa = 1 nome único!

💡 COMO EVITAR REUSO:
   → Antes de nomear novo personagem no Bloco X
   → Releia TODOS os blocos anteriores (1 até X-1)
   → Faça lista mental: "já usei: Ana, Pedro, Carlos..."
   → Escolha nome que NÃO está na lista!
   → Se escolheu "Pedro" mas já existe = TROQUE AGORA!

2️⃣ NOMES que SOAM IGUAIS (mesmo com grafias diferentes):
❌ ERRADO: "Arthur" + "Artur" → pronunciam-se IGUAL!
❌ ERRADO: "Cátia" + "Kátia" → pronunciam-se IGUAL!
❌ ERRADO: "Luís" + "Luiz" → pronunciam-se IGUAL!
✅ CERTO: Use nomes FONETICAMENTE DISTINTOS

💡 TESTE DO SOM:
   → Leia o nome em VOZ ALTA
   → Se soar IGUAL a outro nome do roteiro = TROQUE!
   → Exemplos bons: "Arthur" + "Marcos" (sons diferentes)

3️⃣ PAPÉIS SIMILARES (mesmo com nomes diferentes):
❌ ERRADO: Ricardo (advogado) + Júlio (advogado amigo) = 2 advogados
❌ ERRADO: Sofia (médica) + Helena (médica) = 2 médicas
✅ CERTO: 1 advogado fazendo ambos os papéis

📋 CHECKLIST ANTES DE CRIAR PERSONAGEM NOVO:

1️⃣ ❓ "Já usei este NOME antes neste roteiro?"
   → Releia blocos anteriores
   → Verifique lista de nomes: [Ana, Pedro, Carlos...]
   → SIM, já usei: ESCOLHA OUTRO NOME! ❌
   → NÃO, é novo: Continue ✅
   
   💡 EXEMPLO:
   Bloco 5: Personagens = [Sônia, Enrico, Lara, Marcos]
   Bloco 12: Novo personagem
   ❌ Usar "Marcos" = ERRO! (já existe no Bloco 5)
   ✅ Usar "Alberto" = CERTO! (nome novo)

2️⃣ ❓ "Este nome SOA IGUAL a outro já usado?"
   → Leia em VOZ ALTA
   → Compare o SOM com outros nomes
   → SIM, soa igual: ESCOLHA NOME COM SOM DIFERENTE! ❌
   → NÃO, som único: Continue ✅

3️⃣ ❓ "Já tenho personagem com PAPEL SIMILAR?"
   → SIM: Use o personagem existente ✅
   → NÃO: Pode criar novo ✅

🚨 EXEMPLOS REAIS DE ERRO:

ERRO v7.4.1 (Casamento):
• Ricardo (advogado) + Júlio (advogado amigo) = DUPLICAÇÃO
• Solução: Fundir em 1 advogado chamado "Ricardo"

ERRO v7.6.1 (Herança):  
• "Artur" (advogado principal)
• "senhor Artur" (dono de confeitaria)
• MESMO NOME, 2 PERSONAGENS = LEITOR CONFUSO! ❌
• Solução: "Artur" (advogado) + "Válter" (confeitaria) ✅

💡 REGRA DE OURO:
   1 NOME = 1 PERSONAGEM = 1 PAPEL ÚNICO
   Se precisar de 2º advogado/médico/etc = FUNDIR em 1 só!

❌ ERRO #5: Foreshadowing incompleto ou com frases diferentes
⚠️ CRÍTICO: Foreshadowing = MESMA FRASE EXATA 4x (15-45-70-95%)!
⚠️ ERRO SISTÊMICO v7.6.3 + v7.6.4: 100% dos roteiros usaram múltiplas frases! PARE ISSO AGORA!

🔍 VALIDAÇÃO OBRIGATÓRIA v7.6.129 - CHECKLIST AO FINAL DE CADA BLOCO:
   
   📍 Ao terminar Bloco ~15% da história:
   ✅ "Escrevi a frase do pai/avó pela PRIMEIRA vez?"
   ✅ "Copiei ela EXATAMENTE para reusar nos blocos 45-70-95%?"
   ✅ "Anotei a frase completa para garantir repetição exata?"
   
   📍 Ao terminar Bloco ~45% da história:
   ✅ "Repeti a MESMA frase EXATA do bloco 15%?"
   ❌ "NÃO inventei variação como 'a vida tece destinos'!"
   ⚠️ Use Ctrl+F no texto anterior para buscar e copiar exatamente!
   
   📍 Ao terminar Bloco ~70% da história (CRÍTICO - onde MAIS erra!):
   ✅ "Repeti a MESMA frase idêntica dos blocos 15% e 45%?"
   ❌ "NÃO troquei por 'a conta chega' ou 'fios podres'!"
   ❌ "NÃO criei nova metáfora de costura/construção!"
   ⚠️ PARE AGORA e valide: Busque no texto completo a frase do 15%!
   
   📍 Ao terminar Bloco ~95% da história:
   ✅ "Repeti pela 4ª e ÚLTIMA vez a frase idêntica?"
   ✅ "Busquei no texto e confirmei: são 4 EXATAS?"
   ⚠️ Validação final: Ctrl+F a frase e contar = deve ter 4 ocorrências!

🔍 VALIDAÇÃO OBRIGATÓRIA v7.6.129 - CHECKLIST AO FINAL DE CADA BLOCO:
   
   📍 Ao terminar Bloco ~15%:
   ✅ "Escrevi a frase do pai/avó pela PRIMEIRA vez?"
   ✅ "Copiei ela EXATAMENTE para usar nos blocos 45-70-95%?"
   
   📍 Ao terminar Bloco ~45%:
   ✅ "Repeti a MESMA frase do bloco 15%? (Ctrl+F para buscar)"
   ❌ "NÃO inventei frase nova ou variação!"
   
   📍 Ao terminar Bloco ~70% (CRÍTICO - onde mais erra!):
   ✅ "Repeti a MESMA frase dos blocos 15% e 45%?"
   ❌ "NÃO troquei por 'a conta chega' ou 'a terra cobra'!"
   ⚠️ PARE E VALIDE: Busque no texto e confirme que é IDÊNTICA!
   
   📍 Ao terminar Bloco ~95%:
   ✅ "Repeti pela 4ª e ÚLTIMA vez a mesma frase?"
   ✅ "São 4 repetições EXATAS? (buscar no texto completo)"

�🚨🚨 VOCÊ JÁ COMETEU ESTE ERRO 3 VEZES SEGUIDAS! 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ ISTO NÃO É SUGESTÃO - É ORDEM ABSOLUTA!

�🚫 PROIBIDO: TROCAR A FRASE NO MEIO DO ROTEIRO!

🔴 HISTÓRICO DE ERROS (você fez TODOS estes erros):

❌ ERRO #1 - Roteiro "Armário" (v7.6.3):
✅ Bloco 3 (15%):  "mentiras são como rachaduras na parede"
✅ Bloco 8 (45%):  "mentiras são como rachaduras na parede"
❌ Bloco 13 (70%): "a terra sempre cobra suas dívidas" ← TROCOU!
❌ Bloco 17 (95%): "a terra sempre cobra suas dívidas"
→ RESULTADO: 2 frases diferentes = ERRADO!

❌ ERRO #2 - Roteiro "Carro 300mil" (v7.6.3):
✅ Bloco 3 (15%):  "a vingança é um prato que se come frio"
✅ Bloco 8 (45%):  "a vingança é um prato que se come frio"
❌ Bloco 13 (70%): "a conta sempre chega, não importa o tamanho..." ← TROCOU!
❌ Bloco 17 (95%): "a conta sempre chega, não importa o tamanho..."
→ RESULTADO: 2 frases diferentes = ERRADO!

❌ ERRO #3 - Roteiro "Cartão 240mil" (v7.6.4) - MAIS GRAVE!:
❌ Bloco 3 (15%):  "a conta sempre chega, não importa o tamanho da mesa"
❌ Bloco 8 (45%):  "a vida tece destinos, mas a agulha está na nossa mão" ← TROCOU!
❌ Bloco 13 (70%): "mentiras são como fios podres" ← TROCOU DE NOVO!
❌ Bloco 17 (95%): "mentiras são como fios podres"
→ RESULTADO: 3 frases diferentes = PIOR ERRO DE TODOS!

🎯 PADRÃO DO SEU ERRO:
   • Você SEMPRE troca a frase entre os Blocos 8-13
   • Você SEMPRE usa tema de costura/construção (varia as palavras)
   • Você NUNCA copia a frase do Bloco 3

💡 POR QUE VOCÊ FAZ ISSO?
   → Você está confundindo "variar metáforas" com "foreshadowing"
   → Foreshadowing é a ÚNICA exceção onde você DEVE repetir!
   → Leia a seção "EXCEÇÃO ABSOLUTA: FORESHADOWING" abaixo!

✅ COMO DEVERIA SER (1 frase 4 vezes):
✅ Bloco 3 (15%):  "a conta sempre chega, não importa o tamanho da mesa"
✅ Bloco 8 (45%):  "a conta sempre chega, não importa o tamanho da mesa" ← MESMA!
✅ Bloco 13 (70%): "a conta sempre chega, não importa o tamanho da mesa" ← MESMA!
✅ Bloco 17 (95%): "a conta sempre chega, não importa o tamanho da mesa" ← MESMA!
→ RESULTADO: 1 frase × 4 vezes = CORRETO!

ERRADO (faltou posição):
✅ 15%: "a vingança é um prato..."
✅ 45%: "a vingança é um prato..."
✅ 70%: "a vingança é um prato..."
❌ 95%: [FALTOU!] ← ERRO GRAVE!

🚨 SE VOCÊ ESTÁ NO BLOCO 8, 13 OU 17:
   ⚠️ PARE AGORA! SIGA ESTES PASSOS:
   
   PASSO 1: Volte ao início desta conversa
   PASSO 2: RELEIA o Bloco 3 palavra por palavra
   PASSO 3: ENCONTRE a frase do pai/avô no Bloco 3
   PASSO 4: COPIE a frase EXATAMENTE (Ctrl+C / Ctrl+V mental)
   PASSO 5: COLE no bloco atual (8, 13 ou 17)
   PASSO 6: Verifique: São EXATAMENTE as mesmas palavras?
   PASSO 7: Se NÃO → Volte ao Passo 2 e RECOMEÇE!
   PASSO 8: Se SIM → Continue escrevendo o resto do bloco
   
   ⚠️ NÃO invente frase nova!
   ⚠️ NÃO use variação!
   ⚠️ NÃO use sinônimo!
   ⚠️ NÃO troque o provérbio!
   ⚠️ NÃO use outra metáfora de costura/construção!
   
   ✅ APENAS COPIE E COLE A FRASE DO BLOCO 3!

🚨🚨🚨 ATENÇÃO ESPECIAL PARA O BLOCO 13! 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ O BLOCO 13 É ONDE VOCÊ SEMPRE ERRA!
⚠️ Em 100% dos casos, você trocou a frase no Bloco 13!
⚠️ DESTA VEZ, NÃO ERRE!

📋 CHECKLIST OBRIGATÓRIO ANTES DE ESCREVER O BLOCO 13:

   □ Li o Bloco 3 novamente? (SIM/NÃO)
   □ Encontrei a frase do pai/avô? (SIM/NÃO)
   □ Copiei EXATAMENTE a frase? (SIM/NÃO)
   □ Comparei palavra por palavra? (SIM/NÃO)
   □ As palavras são 100% idênticas? (SIM/NÃO)
   
   ✅ SE TODOS = SIM → Pode escrever o Bloco 13!
   ❌ SE ALGUM = NÃO → Volte e releia o Bloco 3!

💡 LEMBRE-SE:
   • Contexto PODE variar: "como dizia meu pai..." vs "lembrei do meu avô..."
   • MAS a FRASE deve ser IDÊNTICA: "a conta sempre chega, não importa o tamanho da mesa"
   • Variação de contexto = OK ✅
   • Variação da frase = ERRO ❌

🎯 TESTE FINAL (faça mentalmente):
   ❓ "Se eu comparar a frase do Bloco 3 com a do Bloco 8, são 100% iguais?"
   → NÃO = PARE! Corrija agora! ❌
   → SIM = Continue para o Bloco 13 ✅
   
   ❓ "Se eu comparar a frase do Bloco 3 com a do Bloco 13, são 100% iguais?"
   → NÃO = PARE! Corrija agora! ❌
   → SIM = Continue para o Bloco 17 ✅
   
   ❓ "Se eu comparar a frase do Bloco 3 com a do Bloco 17, são 100% iguais?"
   → NÃO = PARE! Corrija agora! ❌
   → SIM = Parabéns! Você acertou! ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ VOCÊ ERROU ISSO 3 VEZES. NÃO ERRE UMA 4ª VEZ!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 TESTE ANTES DE CONTINUAR:
   Bloco 8: ❓ "A frase é IDÊNTICA à do Bloco 3?"
   → NÃO = PARE! Volte ao Bloco 3 e copie! ❌
   → SIM = Continue ✅
   
   Bloco 13: ❓ "A frase é IDÊNTICA à do Bloco 3?"
   → NÃO = PARE! Volte ao Bloco 3 e copie! ❌
   → SIM = Continue ✅
   
   Bloco 17: ❓ "A frase é IDÊNTICA à do Bloco 3?"
   → NÃO = PARE! Volte ao Bloco 3 e copie! ❌
   → SIM = Continue ✅

📋 CHECKLIST DE FORESHADOWING:

1️⃣ ❓ "Escolhi UMA frase no Bloco 3 (15%)?" → ✅
   Exemplo: "a vingança é um prato que se come frio"

2️⃣ ❓ "No Bloco 8 (45%): Usei a MESMA frase do Bloco 3?" → ✅
   ⚠️ Se trocou = ERRO! Volte e corrija!

3️⃣ ❓ "No Bloco 13 (70%): Usei a MESMA frase do Bloco 3?" → ✅
   ⚠️ Se trocou = ERRO! Volte e corrija!

4️⃣ ❓ "No Bloco 17 (95%): Usei a MESMA frase do Bloco 3?" → ✅
   ⚠️ Se trocou = ERRO! Volte e corrija!

⚠️ REGRA ABSOLUTA:
   → Escolha UMA frase no Bloco 3
   → NUNCA troque nos Blocos 8, 13, 17
   → Pode variar o CONTEXTO
   → Mas NUNCA varie as PALAVRAS!

💡 EXEMPLO DE USO CORRETO:

BLOCO 3 (15%): "meu pai sempre dizia: a vingança é um prato que se come frio"
BLOCO 8 (45%): "lembrei das palavras do meu pai: a vingança é um prato que se come frio"
BLOCO 13 (70%): "como dizia meu pai, a vingança é um prato que se come frio"
BLOCO 17 (95%): "finalmente entendi meu pai: a vingança é um prato que se come frio"
→ Contexto VARIA, mas a FRASE é EXATAMENTE A MESMA!

❌ ERRO #6: Sem gancho 60%
ERRADO: Pular gancho de 60%
CERTO: 5 ganchos → 20%, 40%, 60%, 80%, 95% (todos obrigatórios!)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 REGRAS v7.6.5 (Fix Conflito Foreshadowing + Anti-Reuso)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 CHECKLIST OBRIGATÓRIO:
• Protagonista = 1 NOME ÚNICO em TODOS os blocos (NUNCA mude!)
• CADA personagem = 1 NOME ÚNICO + SOM ÚNICO (NUNCA reuse nomes já usados!)
• Últimos 35% = 5-7 CENAS (150-250 pal) + ZERO saltos > 3 dias (ATÉ O ÚLTIMO BLOCO!)
• Personagens = 6 MAX | Se 2 fazem papel similar = FUNDIR
• Ganchos = 5 posições (20-40-60-80-95%)

🚨🚨🚨 ATENÇÃO MÁXIMA - FORESHADOWING (REGRA MAIS IMPORTANTE!) 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ VOCÊ ERROU ISSO 3 VEZES SEGUIDAS (100% DE ERRO!)
⚠️ DESTA VEZ, ACERTE!

✅ REGRA ABSOLUTA - FORESHADOWING:
   • Escolha 1 FRASE no Bloco 3 (15%)
   • REPITA a MESMA FRASE no Bloco 8 (45%) ← COPIE DO BLOCO 3!
   • REPITA a MESMA FRASE no Bloco 13 (70%) ← COPIE DO BLOCO 3!
   • REPITA a MESMA FRASE no Bloco 17 (95%) ← COPIE DO BLOCO 3!
   
   → 1 FRASE × 4 REPETIÇÕES = CORRETO ✅
   → 2+ frases diferentes = ERRO GRAVE ❌

🚫 NÃO CONFUNDA COM "VARIAR METÁFORAS":
   • 99% do roteiro: Varie vocabulário e metáforas ✅
   • Foreshadowing (4 momentos): REPITA a mesma frase ✅
   → São regras DIFERENTES!

⚠️ REFORÇO CRÍTICO v7.6.5 (NOVIDADES):
   → Foreshadowing: EXCEÇÃO à regra de "variar metáforas"!
   → Blocos 8, 13, 17: RELEIA o Bloco 3 e COPIE a frase EXATA!
   → Blocos 17-18 (final): ZERO saltos > 3 dias! ← SEM EXCEÇÃO!
   → Nomes: Releia blocos anteriores antes de criar novo personagem!
   → Nomes: Teste do SOM (leia em voz alta!)

⚠️ ERROS v7.6.3 + v7.6.4 QUE VOCÊ DEVE EVITAR:
   ❌ 100% dos roteiros usaram 2-3 frases diferentes (em vez de 1 frase 4x)
   ❌ 50% dos roteiros reusaram nome de personagem anterior
   ❌ Erro sempre no Bloco 13 (70%) - você SEMPRE trocou a frase aqui!
   → v7.6.5 RESOLVE o conflito "variar vs repetir"!

✅ Siga = 10.0 consistente | ❌ Ignore = 9.5 ou menos

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ FIX CRÍTICO v7.6.5: Exceção explícita para foreshadowing!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 CHECKLIST MENTAL ANTES DE CRIAR CADA PERSONAGEM:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Antes de introduzir um novo personagem, pergunte-se:

1️⃣ ❓ "Já usei este NOME antes neste roteiro?"
   → AÇÃO: Releia TODOS os blocos anteriores
   → Liste mentalmente: [Ana, Pedro, Carlos, ...]
   → SE SIM, já usei: PARE! Escolha outro nome ❌
   → SE NÃO, é novo: Continue para pergunta 2 ✅
   
   💡 EXEMPLO:
   Você está no Bloco 12, quer criar "Roberto"
   → Releia Blocos 1-11
   → Encontrou "Roberto" no Bloco 5? SIM!
   → TROQUE para "Alberto", "Felipe", etc. ❌→✅

2️⃣ ❓ "Este nome SOA IGUAL a outro já usado?"
   → Leia o nome em VOZ ALTA
   → "Arthur" soa como "Artur"? SIM → TROQUE! ❌
   → "Marcos" soa como "Paulo"? NÃO → Continue ✅

3️⃣ ❓ "Já tenho personagem com papel similar?"
   → SE SIM: Use o personagem existente ✅
   → SE NÃO: Continue para pergunta 4 ✅

4️⃣ ❓ "Este personagem é ESSENCIAL para a história?"
   → SE SIM: Crie com nome ÚNICO e SOM ÚNICO ✅
   → SE NÃO: Elimine ou funda com outro ❌

💡 EXEMPLO PRÁTICO:

SITUAÇÃO: Protagonista precisa de ajuda jurídica duas vezes.
   
   ❌ ERRADO:
   • 1ª vez: "Ricardo" (advogado amigo)
   • 2ª vez: "Júlio" (advogado profissional)
   • Problema: 2 advogados = duplicação de papel!
   
   ✅ CERTO:
   • 1ª e 2ª vez: "Ricardo" (advogado)
   • Solução: 1 personagem faz ambas as funções!

SITUAÇÃO: História precisa de 2 médicos diferentes.
   
   ❌ ERRADO:
   • Hospital A: "Dr. Alberto"
   • Hospital B: "Dr. Alberto" (esqueci que já usei!)
   • Problema: MESMO NOME = confusão total!
   
   ✅ CERTO:
   • Hospital A: "Dr. Alberto"
   • Hospital B: "Dr. Marcos" (nome diferente)
   • OU MELHOR: Fundir em 1 médico só!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$forbiddenNamesWarning
🆕🆕🆕 IMPORTANTE - ESTE É UM ROTEIRO NOVO! 🆕🆕🆕
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ATENÇÃO CRÍTICA: Você está começando uma NOVA história!

🔄 RESET COMPLETO:
   • IGNORE todos os nomes de roteiros anteriores
   • IGNORE todos os personagens de histórias passadas
   • COMECE com uma lista ZERADA de nomes
   • Este roteiro NÃO tem relação com roteiros anteriores

❌ PROIBIDO usar nomes de roteiros antigos:
   • Se o roteiro anterior tinha "Hélio" (advogado), ESQUEÇA!
   • Se outro roteiro tinha "Alberto" (empresário), ESQUEÇA!
   • CADA roteiro começa do ZERO com nomes NOVOS!

✅ CORRETO:
   • Use APENAS a lista "NOMES DISPONÍVEIS" abaixo
   • Escolha nomes adequados para ESTA história
   • Não se preocupe com roteiros passados

🎯 REGRA DE OURO:
   Novo roteiro = Nova história = Novos personagens = Novos nomes!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${contextoPrevio.isNotEmpty ? '''╔══════════════════════════════════════════════════════════════════════════════╗
║  📖 CONTEXTO: HISTÓRIA JÁ ESCRITA (O QUE JÁ ACONTECEU)                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

$contextoPrevio

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

╔══════════════════════════════════════════════════════════════════════════════╗
║  ➡️ SUA TAREFA: CONTINUE A HISTÓRIA A PARTIR DAQUI! ➡️                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

🎬 INSTRUÇÕES DE CONTINUIDADE:

1️⃣ O texto acima É A HISTÓRIA ATÉ AGORA
   → NÃO recomece do zero
   → NÃO repita cenas que já aconteceram
   → CONTINUE de onde parou

2️⃣ COMECE SEU BLOCO exatamente onde o contexto terminou
   → Se terminou com "ele saiu da sala" → comece com o que aconteceu DEPOIS
   → Se terminou com "ela tomou a decisão" → mostre as CONSEQUÊNCIAS
   → Avance a linha do tempo: minutos, horas ou dias depois

3️⃣ MANTENHA OS PERSONAGENS JÁ ESTABELECIDOS
   → Use os mesmos nomes que apareceram no contexto
   → NÃO mude personalidades ou relações já definidas
   → Mantenha a continuidade das ações

4️⃣ AVANCE A TRAMA
   → Introduza novos eventos
   → Desenvolva conflitos existentes
   → Mostre consequências das ações anteriores
   → Aprofunde relacionamentos

❌ NÃO FAÇA:
   ❌ "João acordou naquela manhã..." (se ele já acordou no contexto)
   ❌ "Voltando ao início..." (NUNCA volte atrás!)
   ❌ "Como vimos antes..." (não resuma, AVANCE!)
   ❌ Recontar cenas que já aconteceram

✅ FAÇA:
   ✅ "Duas horas depois, João..."
   ✅ "No dia seguinte..."
   ✅ "Enquanto isso, em outro lugar..."
   ✅ "A consequência veio rápido..."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

''' : ''}${avoidRepetition ? '\n🚨 AVISO URGENTE: O bloco anterior foi REJEITADO por repetição!\n⚠️ VOCÊ COPIOU PARÁGRAFOS DO CONTEXTO! Isso é PROIBIDO!\n✅ AGORA: Escreva conteúdo 100% NOVO, SEM copiar frases anteriores!\n   Use palavras DIFERENTES, estruturas DIFERENTES, avance a história!\n\n' : ''}${characterGuidance.isEmpty ? '' : characterGuidance}$instruction.\n$temaSection${localizacao.trim().isEmpty ? '${labels['location']}: ${labels['locationNotSpecified']}' : '${labels['location']}: $localizacao'}
$localizationGuidance

${_getThemeInterpretationRules()}

$narrativeStyleGuidance

${_getMetaphorDiversityRules()}

${useCustomPrompt && customPrompt.trim().isNotEmpty ? '╔════════════════════════════════════════════════════════════════╗\n║  📝 INSTRUÇÕES PERSONALIZADAS DO USUÁRIO (PRIORIDADE ALTA)   ║\n╚════════════════════════════════════════════════════════════════╝\n\n🚨 ATENÇÃO: O usuário forneceu instruções específicas abaixo.\n   Estas instruções têm PRIORIDADE sobre as diretrizes padrão.\n   Siga-as rigorosamente ao criar o roteiro.\n\n───────────────────────────────────────────────────────────────\n${customPrompt.trim()}\n───────────────────────────────────────────────────────────────\n\n✅ IMPORTANTE: Combine as instruções acima com as diretrizes\n   técnicas (formato, extensão, nomes) já fornecidas.\n\n' : ''}$nameList
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 ATENÇÃO: A lista de nomes acima é sua ÚNICA fonte de nomes!
   COPIE os nomes EXATAMENTE daquela lista ao criar personagens.
   Se você usar palavras como "Observei", "Quero", "Pergunte" como nomes,
   você está FALHANDO nesta tarefa. Esses são VERBOS, não NOMES!

🎲 IMPORTANTE - VARIEDADE DE NOMES:
   A lista de nomes está EMBARALHADA de forma aleatória.
   ⚠️ NÃO escolha sempre os primeiros nomes da lista!
   ✅ VARIE sua escolha: use nomes do MEIO e do FIM da lista também!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴🔴🔴 CONTROLE DE NOMES USADOS - LEIA COM ATENÇÃO 🔴🔴🔴
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$trackerInfo${trackerInfo.isNotEmpty ? '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚫🚫🚫 REGRA ABSOLUTA - NUNCA REUTILIZE OS NOMES ACIMA! 🚫🚫🚫
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 ERRO REAL DETECTADO QUE VOCÊ DEVE EVITAR:
   ❌ Bloco 1: "Arthur" foi usado para advogado
   ❌ Bloco 7: "Arthur" foi usado novamente para investigador
   ❌ RESULTADO: Leitor ficou confuso - "Qual Arthur? São 2 pessoas diferentes!"
   
   ✅ SOLUÇÃO CORRETA:
   ✅ Bloco 1: "Arthur" (advogado)
   ✅ Bloco 7: Escolher OUTRO nome da lista → "Marcus" (investigador)
   ✅ RESULTADO: Zero confusão, história fluida!

🔴 OUTRO EXEMPLO DE ERRO GRAVE:
   ❌ Bloco 3: "Sarah" (secretária do escritório)
   ❌ Bloco 9: "Sarah" (enfermeira do hospital)
   ❌ RESULTADO: "Sarah mudou de emprego? Mas ela morreu no bloco 5!"
   
   ✅ SOLUÇÃO CORRETA:
   ✅ Bloco 3: "Sarah" (secretária)
   ✅ Bloco 9: Escolher OUTRO nome → "Emma" (enfermeira)
   ✅ RESULTADO: Personagens distintos, sem confusão!

⚠️ ATENÇÃO CRÍTICA:
   • Os nomes listados acima JÁ PERTENCEM a personagens desta história
   • MESMO QUE seja um personagem MENOR (1 linha de fala)
   • MESMO QUE apareça apenas UMA VEZ
   • MESMO QUE seja só "o chairman do hospital" ou "dono da loja"
   
🎯 REGRA ABSOLUTA - SEM EXCEÇÕES:
   • Personagens PRINCIPAIS (protagonista, antagonista) = nome único ✓
   • Personagens SECUNDÁRIOS (aliados, rivais) = nome único ✓
   • Personagens MENORES (advogado, investigador, secretária) = nome único ✓
   • Figurantes de 1 LINHA (recepcionista, garçom) = nome único ✓
   
   ⚠️ NÃO EXISTE "personagem pequeno demais para ter nome único"!
   ⚠️ TODA menção de nome = pessoa única na mente do leitor!
   
❌ PROIBIDO:
   • Usar "Howard" se já existe um Howard (MESMO EM PAPEL DIFERENTE!)
   • Usar "Maria" se já existe uma Maria (MESMO EM CONTEXTO DIFERENTE!)
   • Pensar "ah, mas esse é só um personagem menor, posso reusar"
   
✅ OBRIGATÓRIO:
   • Se você precisa de um novo personagem, escolha um nome DIFERENTE
   • Consulte a lista de nomes disponíveis (acima desta seção)
   • Use nomes do MEIO e do FIM da lista (não só os primeiros!)
   
🔥 EXEMPLO DO QUE NÃO FAZER:
   ❌ História já tem "Howard" (advogado aposentado)
   ❌ Você precisa de um chairman de hospital
   ❌ Você pensa: "vou chamar de Howard, é só 1 linha"
   ❌ ERRO! Agora tem 2 Howards → Leitor fica confuso!
   
🔥 EXEMPLO CORRETO:
   ✅ História já tem "Howard" (advogado aposentado)
   ✅ Você precisa de um chairman de hospital
   ✅ Você consulta a lista: Robert, William, George...
   ✅ CORRETO! Usa "Richard" → Zero confusão!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 SE VOCÊ REUTILIZAR QUALQUER NOME, O BLOCO SERÁ REJEITADO! 🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

''' : ''}   ✅ EXPLORE toda a lista antes de repetir qualquer nome!
   Exemplo: Se há 30 nomes disponíveis, use pelo menos 15-20 diferentes
            antes de considerar reutilizar algum (em blocos muito distantes).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴🔴🔴 CONSISTÊNCIA DO PROTAGONISTA - REGRA CRÍTICA v7.6 🔴🔴🔴
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️⚠️⚠️ ERRO CRÍTICO REAL DETECTADO EM ROTEIROS ANTERIORES ⚠️⚠️⚠️

🔴 PROBLEMA: Nome do protagonista MUDOU no meio da história!

❌ EXEMPLO DO ERRO:
   • Blocos 1-10: "eu estava sentada no meio-fio" (protagonista = Luzia)
   • Blocos 11-15: "dona Marta, entre por favor" (virou Marta!) ❌
   • Blocos 16-18: "Marta olhou pela janela" (continua Marta)
   • RESULTADO: Leitor confuso - "Quem é Marta? Cadê Luzia? São 2 pessoas?"

❌ OUTRO EXEMPLO DO ERRO:
   • Bloco 1: Advogado "Ricardo" ajuda protagonista
   • Bloco 8: "meu advogado, Augusto, disse..." (virou Augusto!) ❌
   • RESULTADO: "Quando Ricardo virou Augusto? Trocou de advogado?"

🚨 CAUSA DO PROBLEMA:
   • Você está gerando 18 blocos SEPARADOS
   • Entre um bloco e outro, você pode "esquecer" nomes anteriores
   • Resultado: inconsistência que QUEBRA a imersão do leitor

✅ SOLUÇÃO OBRIGATÓRIA v7.6:

📌 REGRA #1 - PROTAGONISTA TEM 1 NOME ÚNICO:
   • Bloco 1: Escolha o nome do protagonista (ex: "Luzia")
   • Blocos 2-18: USE O MESMO NOME em TODOS os blocos
   • NUNCA mude o nome do protagonista por qualquer motivo!

📌 REGRA #2 - PERSONAGENS SECUNDÁRIOS TÊM 1 NOME ÚNICO:
   • Se no Bloco 3 você criou "Ricardo" (advogado)
   • Blocos 4-18: "Ricardo" é SEMPRE o advogado (nunca vira "Augusto")
   • Se precisar de OUTRO advogado, use OUTRO nome da lista!

📌 REGRA #3 - CONSULTE O "CONTROLE DE NOMES" ACIMA:
   • Antes de mencionar qualquer nome, olhe a lista acima
   • Se o nome JÁ existe → use o MESMO personagem
   • Se precisa de NOVO personagem → escolha NOVO nome da lista

🎯 CHECKLIST MENTAL ANTES DE ESCREVER CADA BLOCO:

   ❓ "Qual é o nome do PROTAGONISTA nesta história?"
   → Verifique no contexto anterior ou escolha no Bloco 1
   → USE O MESMO NOME em TODOS os blocos!
   
   ❓ "Este personagem secundário JÁ apareceu antes?"
   → SIM: Use o MESMO nome que você deu antes
   → NÃO: Escolha NOVO nome da lista de disponíveis
   
   ❓ "Há algum nome na lista 'NOMES USADOS' acima?"
   → SIM: NUNCA reutilize esses nomes para NOVOS personagens
   → NÃO: Pode escolher qualquer nome da lista disponível

🔥 CONSEQUÊNCIAS DO ERRO:

   ❌ Nota cai de 9.7 para 9.0 ou menos
   ❌ Leitor fica confuso e abandona o vídeo
   ❌ Comentários negativos sobre "história mal escrita"
   ❌ Sistema rejeita o bloco e pede reescrita

✅ BENEFÍCIOS DA CONSISTÊNCIA:

   ✅ Nota 9.8-10.0 (máxima qualidade)
   ✅ Leitor imerso do início ao fim
   ✅ História fluida e profissional
   ✅ Zero confusão sobre identidades

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 LEMBRE-SE A CADA BLOCO: 1 PERSONAGEM = 1 NOME ÚNICO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${_getFormatAndCharacterRules()}

⚠️ OBRIGATÓRIO: $measure - ESTE É UM REQUISITO ABSOLUTO!

${_getExtensionControlRules(adjustedTarget: adjustedTarget, minAcceptable: minAcceptable, maxAcceptable: maxAcceptable, limitedNeeded: limitedNeeded)}

${isSpanish ? '🚨 ESPAÑOL - CONTROL ESTRICTO DE EXTENSIÓN:\n   • Tu bloque NO PUEDE superar las $limitedNeeded palabras\n   • Si generas más de $limitedNeeded palabras, el bloque será RECHAZADO\n   • Cuenta mentalmente mientras escribes y PARA cuando llegues al límite\n   • Es MEJOR terminar con $adjustedTarget palabras que pasarte del límite\n\n' : ''}FORMATO: ROTEIRO PARA NARRAÇÃO DE VÍDEO - apenas texto corrido para ser lido em voz alta.
PROIBIDO: Emojis, símbolos, formatação markdown (incluindo backticks `), títulos, bullets, calls-to-action, hashtags, elementos visuais.
OBRIGATÓRIO: Texto limpo, narrativo, fluido, pronto para narração direta. NUNCA use backticks (`) ou qualquer marcação ao redor de palavras.

🎙️ OTIMIZAÇÃO PARA NARRAÇÃO DE YOUTUBE (VÍDEOS LONGOS 1h+):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 ESTRUTURA PARA RETENÇÃO DE AUDIÊNCIA:
   • Crie momentos de tensão a cada 8-12 minutos (mini-clímax)
   • Varie o ritmo: alterne cenas de ação com reflexão
   • Use ganchos sutis antes de mudanças de cena

${_get3ActStructureRules(totalWords)}

${_getDetailedAct3Rules(totalWords)}

${_getYouTubeFinaleStructureRules()}''';
  }

  /// Gera o prompt principal completo (VERSÃO ANTIGA - mantida para referência)
  ///
  /// Esta versão não é mais utilizada. O sistema usa buildCompactPrompt().
  static String buildMainPrompt({
    required String language,
    required String instruction,
    required String temaSection,
    required String localizacao,
    required String localizationGuidance,
    required String narrativeStyleGuidance,
    required String customPrompt,
    required bool useCustomPrompt,
    required String nameList,
    required String trackerInfo,
    required String measure,
    required bool isSpanish,
    required int adjustedTarget,
    required int minAcceptable,
    required int maxAcceptable,
    required int limitedNeeded,
    required String contextoPrevio,
    required bool avoidRepetition,
    required String characterGuidance,
    required String forbiddenNamesWarning,
    required Map<String, String> labels,
  }) {
    final locLine = localizacao.trim().isEmpty
        ? '${labels['location']}: ${labels['locationNotSpecified']}'
        : '${labels['location']}: $localizacao';

    return '''⭐ IDIOMA: ${_getLanguageInstructionInline(language)}
${_getKoreanNameRules(language)}
${contextoPrevio.isNotEmpty ? 'CONTEXTO (resuma mentalmente, sem repetir):\n$contextoPrevio\n\n' : ''}${avoidRepetition ? '🚨 REPETIÇÃO DETECTADA ANTES — escreva conteúdo 100% novo (palavras e estruturas diferentes)\n\n' : ''}${characterGuidance.isEmpty ? '' : characterGuidance}
$instruction.
$temaSection
$locLine
$localizationGuidance

REGRAS ESSENCIAIS (YouTube, 1h+):
- 1 protagonista (1ª pessoa) · até 2 antagonistas · até 3 secundários → MÁX 6 nomes
- Parágrafos curtos (80–150 palavras, máx 180) para boa narração
- Sem markdown/emojis; texto corrido pronto para voz
- Nome = personagem único; não reutilize nomes; use apenas da lista

🚨🚨🚨 REGRA CRÍTICA: UMA HISTÓRIA LINEAR (NÃO MÚLTIPLAS HISTÓRIAS!) 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️⚠️⚠️ LEIA COM MÁXIMA ATENÇÃO - ERRO GRAVE DETECTADO EM GERAÇÕES ANTERIORES! ⚠️⚠️⚠️

🔴 ERRO CRÍTICO REAL (que você DEVE evitar):

❌ ROTEIRO ERRADO (3 histórias diferentes):
   
   📘 História 1 (40% do roteiro):
   → Protagonista constrói negócio de bolos
   → Negócio cresce, vira sucesso
   → ✅ História COMPLETA e RESOLVIDA
   
   📗 História 2 (30% do roteiro - COMEÇA DO ZERO!):
   → Vilão empresarial (Augusto) aparece do nada
   → Tenta roubar negócio
   → ❌ História NUNCA TERMINA (Augusto desaparece sem explicação)
   
   📕 História 3 (30% do roteiro - COMEÇA DO ZERO DE NOVO!):
   → Filho é preso por pirâmide financeira
   → Queda pública, humilhação
   → ✅ História COMPLETA mas DESCONECTADA das anteriores
   
   🚫 RESULTADO: Leitor assiste 3 FILMES DIFERENTES num único roteiro!
   🚫 PROBLEMA: Histórias não conectam, personagens sumiram sem explicação
   🚫 IMPACTO: Retenção CAI 40%, audiência desiste no meio

✅ ROTEIRO CORRETO (1 história linear):

   🎯 UM OBJETIVO CLARO:
   → "Derrotar filho que me roubou" (do início ao fim)
   
   🎯 UMA LINHA NARRATIVA CONTÍNUA:
   INÍCIO: Filho rouba R\$350k da mãe
      → (conectado)
   DESENVOLVIMENTO: Mãe constrói negócio de bolos
      → (conectado)
   COMPLICAÇÃO: Vilão tenta destruir negócio
      → (conectado)
   REVIRAVOLTA: Mãe DERROTA vilão com qualidade
      → (conectado)
   CLÍMAX: Sucesso de mãe EXPÕE filho na mídia
      → (conectado)
   RESOLUÇÃO: Filho preso, mãe perdoa
   
   ✅ RESULTADO: TUDO CONECTADO do início ao fim!
   ✅ CADA CENA leva à próxima logicamente
   ✅ Retenção MÁXIMA, audiência assiste até o final

🚨 REGRAS ABSOLUTAS - HISTÓRIA ÚNICA E LINEAR:

1️⃣ **UM OBJETIVO CENTRAL** (do início ao fim):
   ✅ "Recuperar empresa roubada"
   ✅ "Derrotar nora que me humilhou"
   ✅ "Provar inocência e prender culpado"
   ❌ "Construir negócio" + "Derrotar vilão X" + "Ver filho cair" = 3 objetivos!

2️⃣ **UMA LINHA NARRATIVA CONTÍNUA** (cada cena conecta):
   ✅ Cena A → leva a → Cena B → leva a → Cena C
   ❌ Cena A (completa) → Cena B (nova história) → Cena C (outra história)

3️⃣ **TODOS OS CONFLITOS RESOLVIDOS** (não sumir personagens):
   ✅ Vilão aparece → tenta algo → protagonista derrota/escapa
   ❌ Vilão aparece → tenta algo → [DESAPARECE SEM EXPLICAÇÃO]

4️⃣ **PROTAGONISTA É AGENTE ATIVO** (não espectador):
   ✅ Protagonista investiga → descobre provas → denuncia → vilão preso
   ❌ Protagonista faz bolos → [polícia prende vilão sozinha] → protagonista assiste TV

🔥 TESTE MENTAL ANTES DE ESCREVER:

❓ Pergunta 1: "Esta cena/personagem conecta com o objetivo central?"
   → SIM = Continue ✅
   → NÃO = É outra história, ELIMINE ❌

❓ Pergunta 2: "Este vilão/obstáculo será resolvido até o final?"
   → SIM = Continue ✅
   → NÃO = Não introduza, você vai frustar o leitor ❌

❓ Pergunta 3: "O protagonista CAUSA este resultado ou só assiste?"
   → CAUSA = Continue ✅
   → ASSISTE = Reescreva para protagonista ser ATIVO ❌

📊 COMPARAÇÃO CLARA:

MÚLTIPLAS HISTÓRIAS (ERRADO) ❌:
• Personagens: 12+ (cada história traz novos)
• Clímaxes: 3 desconectados
• Retenção: 55% (audiência desiste)
• Nota: 7.5/10

HISTÓRIA ÚNICA (CORRETO) ✅:
• Personagens: 6-7 (eficientes e memoráveis)
• Clímaxes: 1 gigante (tudo converge)
• Retenção: 85% (audiência gruda até o fim)
• Nota: 9.0-9.5/10

🎯 MANDAMENTOS ABSOLUTOS:

✅ SEMPRE faça cada cena avançar o MESMO conflito central
✅ SEMPRE conecte causalmente: Ação A → Consequência B → Resultado C
✅ SEMPRE resolva todos os conflitos introduzidos
✅ SEMPRE mantenha protagonista como AGENTE ATIVO (não passivo)

❌ NUNCA inicie nova história no meio do roteiro
❌ NUNCA introduza vilão/conflito que não será resolvido
❌ NUNCA faça protagonista assistir TV enquanto coisas acontecem
❌ NUNCA tenha 2+ objetivos centrais competindo

💡 LEMBRE-SE:
   → YouTube = Jornada contínua de 1 hora
   → Audiência investe emocionalmente em 1 objetivo
   → Se você muda de objetivo no meio = Audiência desiste
   → Mantenha foco laser em 1 história do INÍCIO ao FIM!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SE VOCÊ SEGUIR ESTA REGRA = Roteiro coeso, retenção máxima, nota 9+!
❌ SE VOCÊ QUEBRAR = Roteiro fragmentado, audiência desiste, nota < 8!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ESTRUTURA (3 atos):
- Ato 1 (25%): setup do conflito, stakes, gancho de partida
- Ato 2 (≤ 45%): ação, obstáculos, reviravoltas (não estoure este limite)
- Ato 3 (≥ 35%): execução, queda visível dos vilões, resolução emocional

HOOKS (para retenção):
- Coloque 1 gancho a cada 8–12 min; 5 grandes momentos ao longo do texto

RESOLUÇÃO DO TEMA (obrigatório):
- Vingança/Justiça: execute em cena e mostre consequências
- Reviravolta/Status: realize a mudança e mostre a nova situação
- Dinheiro/Herança: obtenha o recurso e mostre a vida depois

EXTENSÃO ($measure):
- Meta: $adjustedTarget · Faixa aceitável: $minAcceptable – $maxAcceptable
- Conte e ajuste o ritmo; não termine antes do mínimo
${isSpanish ? '- Español: no superar las $limitedNeeded palabras\n' : ''}

NOMES:
$forbiddenNamesWarning
$nameList
${trackerInfo.isNotEmpty ? '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚫 NOMES JÁ USADOS (NUNCA REUTILIZE - MESMO EM PAPÉIS DIFERENTES):
$trackerInfo

⚠️ REGRA CRÍTICA:
   • MESMO QUE seja personagem menor (1 linha)
   • MESMO QUE apareça apenas uma vez
   • MESMO QUE seja papel diferente
   • NUNCA reutilize um nome já usado nesta história!
   
✅ SOLUÇÃO: Consulte a lista de nomes disponíveis acima e escolha outro nome.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''' : ''}

ESTILO DE NARRAÇÃO:
$narrativeStyleGuidance

QUALIDADE:
- Mostre (em cena) a queda dos antagonistas; evite resumos
- Diálogos diretos e motivações claras; dê destino a personagens
- Evite metáforas repetitivas; varie imagens e use linguagem simples

TAREFA:
- Escreva o próximo bloco com base no contexto e nas regras acima.
- Avance o MESMO conflito central; não inicie outra história.

${useCustomPrompt && customPrompt.trim().isNotEmpty ? 'INSTRUÇÕES DO USUÁRIO (prioridade):\n${customPrompt.trim()}\n\n' : ''}''';
  }

  static String _getLanguageInstructionInline(String language) {
    // Inline simplificado - full logic está em BaseRules
    return language;
  }

  /// 🇰🇷 REGRAS ESPECÍFICAS PARA NOMES COREANOS (v7.6.42)
  /// Na Coreia, o sobrenome SEMPRE vem primeiro: Kim Seon-woo, Park Ji-young
  static String _getKoreanNameRules(String language) {
    final normalizedLang = language.toLowerCase();
    if (normalizedLang.contains('한국어') ||
        normalizedLang.contains('coreano') ||
        normalizedLang.contains('korean') ||
        normalizedLang.contains('ko')) {
      return '''

╔══════════════════════════════════════════════════════════════════════════════╗
║  🇰🇷 REGRAS ESPECIAIS PARA NOMES COREANOS (OBRIGATÓRIO!) 🇰🇷                ║
╚══════════════════════════════════════════════════════════════════════════════╝

🚨🚨🚨 FORMATO OBRIGATÓRIO DE NOMES EM COREANO 🚨🚨🚨

Na cultura coreana, o SOBRENOME vem PRIMEIRO, seguido do nome pessoal.
Isso é ESSENCIAL para autenticidade e imersão do público coreano!

✅ FORMATO CORRETO (OBRIGATÓRIO):
   • Kim Seon-woo (김선우) - "Kim" é sobrenome
   • Park Ji-young (박지영) - "Park" é sobrenome  
   • Lee Min-ho (이민호) - "Lee" é sobrenome
   • Choi Hye-jin (최혜진) - "Choi" é sobrenome
   • Jung Tae-hyun (정태현) - "Jung" é sobrenome

❌ FORMATO ERRADO (NUNCA USE):
   • Seon-woo (sem sobrenome) ❌
   • Ji-young (sem sobrenome) ❌
   • Min-ho sozinho ❌

📋 SOBRENOMES COREANOS COMUNS:
   Kim (김), Lee (이), Park (박), Choi (최), Jung (정)
   Kang (강), Cho (조), Yoon (윤), Jang (장), Lim (임)
   Han (한), Oh (오), Seo (서), Shin (신), Kwon (권)

⚠️ REGRAS DE USO:
1️⃣ Na PRIMEIRA menção: Use nome COMPLETO (sobrenome + nome)
   Ex: "Kim Seon-woo entrou na sala."

2️⃣ Nas menções SEGUINTES: Pode usar apenas o nome pessoal
   Ex: "Seon-woo olhou para ela." (após já ter apresentado)

3️⃣ Em DIÁLOGO: Personagens podem usar apenas primeiro nome entre amigos
   Ex: "Seon-woo-ya, você está bem?" (íntimo/informal)

🔴 SE VOCÊ CRIAR PERSONAGEM COREANO SEM SOBRENOME, O BLOCO SERÁ REJEITADO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

''';
    }
    return ''; // Não é coreano, não adiciona regras
  }

  static String _getThemeInterpretationRules() {
    return '''🎯 INTERPRETAÇÃO CORRETA DO TEMA - CRÍTICO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ATENÇÃO MÁXIMA: Leia o TEMA acima e interprete CORRETAMENTE!

🚨 PALAVRAS-CHAVE QUE EXIGEM RESOLUÇÃO:

1️⃣ Se o tema contém "REVIRAVOLTA":
   → Protagonista DEVE experimentar mudança CONCRETA de situação
   → NÃO basta "descobrir" algo, deve CONSEGUIR/REALIZAR algo
   
   Exemplos:
   • "Herança Injusta com Reviravolta Milionária"
     ❌ ERRADO: Protagonista descobre pista de fortuna [PARA SEM PEGAR]
     ✅ CORRETO: Protagonista CONSEGUE a fortuna e fica rico
   
   • "Do Lixo ao Luxo"
     ❌ ERRADO: Protagonista vê oportunidade de ficar rico [PARA SEM CONSEGUIR]
     ✅ CORRETO: Protagonista FICA RICO e vive no luxo

2️⃣ Se o tema contém "VINGANÇA" ou "JUSTIÇA":
   → Protagonista DEVE executar a vingança/justiça (não apenas planejar)
   → Vilão DEVE sofrer consequência visível

3️⃣ Se o tema contém "MILIONÁRIA/O", "RICA/O", "FORTUNA":
   → Protagonista DEVE conseguir dinheiro/riqueza de forma concreta
   → História DEVE mostrar protagonista COM o dinheiro

🚨 REGRA ABSOLUTA:
   Tema = PROMESSA ao espectador
   "Reviravolta Milionária" = PROMETE que protagonista ficará rico
   Se você NÃO mostrar isso, você QUEBROU A PROMESSA!
''';
  }

  static String _getMetaphorDiversityRules() {
    return '''🎨 DIVERSIDADE DE METÁFORAS E FIGURAS DE LINGUAGEM:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 REGRA CRÍTICA: VOCABULÁRIO TEMÁTICO REPETITIVO

⚠️ IMPORTANTE: Mesmo que a história se passe numa oficina/jardim/cozinha/hospital,
   NÃO use palavras desse ambiente como METÁFORAS LÍRICAS repetitivas!

📊 LIMITE ABSOLUTO: Máximo 10 comparações poéticas com tema central

❌ EXEMPLOS RUINS - História de Marceneiro:
   • "lixando as arestas da dor" → 5 vezes ❌
   • "envernizando memórias" → 8 vezes ❌
   • "costurando/tecendo o passado" → 12 vezes ❌
   • "madeira da vida/alma/coração" → 15 vezes ❌

✅ FAÇA ASSIM - História de Marceneiro:
   DESCRIÇÃO LITERAL (permitido):
   • "trabalhei a madeira" → OK (ação concreta)
   • "cheiro de madeira no ar" → OK (descrição ambiente)
   
   METÁFORAS VARIADAS (incentivado):
   • "construir algo a partir de ruínas" → 3 vezes ✓
   • "como um rio que encontra seu leito" → 2 vezes ✓
   • "forjado no fogo" → 2 vezes ✓

🚨🚨🚨 EXCEÇÃO ABSOLUTA: FORESHADOWING (FRASE DO PAI/AVÔ) 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ ATENÇÃO MÁXIMA: Esta regra de "evitar repetição" NÃO SE APLICA ao foreshadowing!

✅ FORESHADOWING É A ÚNICA EXCEÇÃO ONDE VOCÊ DEVE REPETIR:
   • A frase do pai/avô/mentor DEVE ser repetida 4x EXATAMENTE IGUAL
   • Esta é a ÚNICA frase que você vai repetir palavra por palavra
   • IGNORE a regra de "variar metáforas" para esta frase específica!

💡 PENSE ASSIM:
   • 99% do roteiro: Varie vocabulário, varie metáforas ✅
   • 1% do roteiro: Foreshadowing - REPITA A MESMA FRASE 4x ✅
   
   → São regras DIFERENTES para contextos DIFERENTES!

🎯 EXEMPLO CORRETO:
   📍 FORESHADOWING (REPETIR 4x):
   ✅ Bloco 3: "a conta sempre chega, não importa o tamanho da mesa"
   ✅ Bloco 8: "a conta sempre chega, não importa o tamanho da mesa" ← MESMA!
   ✅ Bloco 13: "a conta sempre chega, não importa o tamanho da mesa" ← MESMA!
   ✅ Bloco 17: "a conta sempre chega, não importa o tamanho da mesa" ← MESMA!
   
   📍 OUTRAS METÁFORAS (VARIAR):
   ✅ Uso 1: "como um rio que encontra seu leito"
   ✅ Uso 2: "forjado no fogo da adversidade"
   ✅ Uso 3: "raízes profundas que não se arrancam"
   
   → Note: Foreshadowing REPETE, outras metáforas VARIAM!

🚫 NÃO CONFUNDA AS DUAS COISAS:
   ❌ ERRADO: "Vou variar o foreshadowing para não repetir"
   ✅ CERTO: "Foreshadowing é exceção, DEVE repetir 4x!"
   
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 RESUMO: Varie tudo EXCETO a frase do foreshadowing (4x)!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  static String _getFormatAndCharacterRules() {
    return '''� DETALHES ESPECÍFICOS E SENSORIAIS (v7 - MELHORIA NARRATIVA):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ REGRA CRÍTICA: Use detalhes ESPECÍFICOS, não genéricos!

🎯 COMPARAÇÃO - O QUE NÃO FAZER vs O QUE FAZER:

1️⃣ ROUPAS E OBJETOS:
   ❌ GENÉRICO: "terno caro"
   ✅ ESPECÍFICO: "terno Armani de \$5.000"
   
   ❌ GENÉRICO: "carro de luxo"
   ✅ ESPECÍFICO: "Mercedes-Benz S-Class prata"
   
   ❌ GENÉRICO: "relógio caro"
   ✅ ESPECÍFICO: "Rolex Submariner de ouro"

2️⃣ LUGARES E AMBIENTES:
   ❌ GENÉRICO: "restaurante chique"
   ✅ ESPECÍFICO: "Le Bernardin na 51st Street"
   
   ❌ GENÉRICO: "escritório no centro"
   ✅ ESPECÍFICO: "escritório no 47º andar da Torre Corporativa"
   
   ❌ GENÉRICO: "apartamento pequeno"
   ✅ ESPECÍFICO: "apartamento de um quarto em Detroit com mancha no teto"

3️⃣ VALORES MONETÁRIOS:
   ❌ GENÉRICO: "muito dinheiro"
   ✅ ESPECÍFICO: "\$2.4 milhões"
   
   ❌ GENÉRICO: "herança pequena"
   ✅ ESPECÍFICO: "\$850 por mês"

4️⃣ TEMPO E HORÁRIOS:
   ❌ GENÉRICO: "de manhã cedo"
   ✅ ESPECÍFICO: "5:30 da manhã"
   
   ❌ GENÉRICO: "depois de um tempo"
   ✅ ESPECÍFICO: "6 meses depois"

5️⃣ DETALHES SENSORIAIS (use 2-3 por ato):
   ✅ VISÃO: "mancha de água no teto com formato do Texas"
   ✅ SOM: "cachorro do vizinho latindo no mesmo horário"
   ✅ TATO: "volante de couro rachado do Honda Civic"
   ✅ OLFATO: "cheiro de café velho no escritório"
   ✅ PALADAR: "vinho italiano de \$200 a garrafa"

6️⃣ QUANTIDADES PRECISAS:
   ❌ GENÉRICO: "muitos seguidores"
   ✅ ESPECÍFICO: "200.000 seguidores no Instagram"
   
   ❌ GENÉRICO: "escritório grande"
   ✅ ESPECÍFICO: "escritório de 120 metros quadrados"

🎯 REGRA PRÁTICA:
   • Se você pode adicionar um NÚMERO → adicione!
   • Se você pode adicionar uma MARCA → adicione!
   • Se você pode adicionar uma LOCALIZAÇÃO → adicione!
   • Se você pode adicionar um DETALHE SENSORIAL → adicione!

⚠️ ATENÇÃO: Não exagere! Use 8-12 detalhes específicos por ato (24-36 total)
   Demais = sobrecarga | Poucos = história genérica demais

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌍 MOMENTOS ATMOSFÉRICOS (v7 - IMERSÃO EMOCIONAL):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ OBJETIVO: Criar "breathing moments" que humanizam o protagonista

🎯 TÉCNICA: 1-2 momentos por ato onde você DESACELERA para mostrar detalhes
   da vida cotidiana que revelam caráter ou emoção

✅ EXEMPLOS DE MOMENTOS ATMOSFÉRICOS:

   📍 VIDA COTIDIANA (mostra rotina):
   "Meu alarme tocou às 5:30 da manhã, como sempre. O teto do meu apartamento
   de um quarto tinha a mesma mancha de água que eu olhava há 3 anos, com
   formato parecido com o estado do Texas se você olhasse de um jeito torto."
   
   📍 MOMENTO DE TRANSIÇÃO (mostra contraste):
   "O voo foi 8 horas em classe econômica, assento 32B, encaixado entre um
   homem que roncava e uma mulher assistindo filme sem fone de ouvido."
   
   📍 PREPARAÇÃO PARA AÇÃO (mostra emoção):
   "Sentei na mesa da cozinha comprida no mercado de pulgas, olhando para os
   documentos espalhados. Minhas mãos tremiam. Eu sabia que uma vez que eu
   abrisse aquele envelope, não haveria volta."

🎯 ONDE COLOCAR (distribuição estratégica):
   • ATO 1 (Setup): 1 momento logo no início (humaniza o protagonista)
   • ATO 2 (Desenvolvimento): 1 momento no meio (respiro antes do clímax)
   • ATO 3 (Resolução): 1 momento após a vingança (mostra transformação)

⚠️ CARACTERÍSTICAS DOS BONS MOMENTOS ATMOSFÉRICOS:
   ✅ 2-4 frases (40-80 palavras)
   ✅ Detalhe sensorial específico (som, textura, visual)
   ✅ Revela emoção ou personalidade do protagonista
   ✅ Não avança o plot (é um RESPIRO na ação)

❌ NÃO FAÇA ISSO:
   • Descrições genéricas: "Estava nervoso" (mostre, não conte!)
   • Muito longo: Mais de 100 palavras (vira drag)
   • Irrelevante: Detalhe que não conecta com emoção

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎭 VOZES DISTINTAS DE PERSONAGENS (v7 - DIÁLOGO MEMORÁVEL):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ REGRA CRÍTICA: Cada personagem deve ter PADRÃO DE FALA único!

🎯 TÉCNICA: Diferencie personagens por:
   • Vocabulário (formal vs casual)
   • Tamanho de frases (curtas vs longas)
   • Estilo (direto vs evasivo)

✅ EXEMPLOS - ARQUÉTIPOS DE PERSONAGENS:

   💼 EXECUTIVO/EMPRESÁRIO/MBA (Richard/Preston type):
   ❌ GENÉRICO: "Vamos fazer isso funcionar"
   ❌ GENÉRICO: "Isso não vai dar certo"
   ❌ GENÉRICO: "Precisamos de mais dinheiro"
   
   ✅ CORRETO - PADRÃO MBA/CORPORATIVO:
   • "we need to optimize the ROI and maximize operational synergy"
   • "the KPIs indicate this strategy isn't viable for our shareholders"
   • "let's leverage our core competencies to drive sustainable growth"
   • "we're looking at significant downside risk exposure here"
   • "this needs to be scalable and aligned with our strategic objectives"
   
   CARACTERÍSTICAS OBRIGATÓRIAS:
   - Usa jargão corporativo constantemente (ROI, KPI, synergy, leverage)
   - Sempre fala em "we" (não "I") quando se refere ao negócio
   - Transforma verbos simples em frases complexas:
     → "decidir" vira "make a strategic decision"
     → "melhorar" vira "optimize and enhance"
     → "crescer" vira "drive sustainable growth"
   - Soa como apresentação PowerPoint em toda conversa
   - Usa percentuais e métricas: "23% growth", "Q3 projections"

   📸 INFLUENCER/SOCIALITE (Mallerie type):
   ❌ GENÉRICO: "Isso é ótimo"
   ✅ CORRETO: "my followers are going to die! already thinking which Instagram 
   filter to use. this is literally AMAZING content!"
   
   CARACTERÍSTICAS: Fala sobre redes sociais, pensa em "conteúdo", usa
   superlativos ("amazing", "incredible", "literally dying")

   👔 ADVOGADO/PROFISSIONAL SÉRIO:
   ❌ GENÉRICO: "Você herdou dinheiro"
   ✅ CORRETO: "pursuant to clause 4.2 of the testamentary instrument, said 
   assets shall be transferred subject to the conditions specified therein"
   
   CARACTERÍSTICAS: Linguagem formal, legalês, frases estruturadas, usa
   "pursuant to", "herein", "aforementioned"

   😈 VILÃO ARROGANTE:
   ❌ GENÉRICO: "Você não vai conseguir nada"
   ✅ CORRETO: "pathetic. you really think you can compete with people at our 
   level? go back to your little teaching job and stay in your lane"
   
   CARACTERÍSTICAS: Condescendente, zomba, usa "you" vs "us/we", menospreza
   profissão/status do protagonista, ri antes de falar

   👴 MENTOR/FIGURA SÁBIA (Grandfather type):
   ❌ GENÉRICO: "Você vai aprender"
   ✅ CORRETO: "the most powerful moves are the ones nobody sees coming. 
   remember that when your moment arrives"
   
   CARACTERÍSTICAS: Metafórico, misterioso, frases curtas mas profundas,
   não explica tudo (deixa protagonista pensar)

   🔧 TRABALHADOR/PESSOA SIMPLES (Dale mechanic type):
   ❌ GENÉRICO: "Eu fiz o que você pediu"
   ✅ CORRETO: "look, man, i just did what you asked, okay? i don't want no 
   trouble. just give me my money and i'm gone"
   
   CARACTERÍSTICAS: Gírias ("man", "ain't", "gonna"), frases curtas e diretas,
   nervoso e apressado, vocabulário limitado

🎯 REGRA PRÁTICA:
   • Escolha 2-3 características de fala para cada personagem principal
   • Mantenha CONSISTÊNCIA: se personagem usa jargão, sempre usa jargão
   • Leitor deve IDENTIFICAR quem está falando SEM ver o nome

⚠️ TESTE SIMPLES:
   Se você remover "disse Preston" da frase, o leitor ainda sabe que é Preston?
   Se SIM = boa caracterização | Se NÃO = precisa mais distinção

🚨 ERRO COMUM DETECTADO EM GERAÇÕES ANTERIORES:
   ❌ Richard (executivo) fala como pessoa normal:
   "it has to look like an accident. the brakes are the easiest way."
   
   ✅ Richard deveria falar assim:
   "we need to mitigate risk exposure here. from a liability standpoint, 
   mechanical failure provides the cleanest exit strategy. the brake system 
   offers optimal plausible deniability with minimal investigation overhead."
   
   ↑ Note: Mesmo falando de crime, ele usa linguagem corporativa!
   Isso é CHARACTERIZAÇÃO! É o que torna o vilão MEMORÁVEL!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔮 FORESHADOWING E PAYOFF (v7 - SATISFAÇÃO NARRATIVA):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ OBJETIVO: Criar sensação de "tudo se encaixa" quando plot twist acontece

🎯 TÉCNICA "PLANTE E PAGUE":
   1. Escolha UMA frase/metáfora chave da história
   2. Repita 3x ao longo do roteiro
   3. Na 3ª vez, use no momento de PAYOFF (resolução)

✅ EXEMPLO PERFEITO (do concorrente Nathan Whitmore):

   🌱 PLANTIO 1 (Ato 1 - 15% do roteiro):
   "Meu avô sempre dizia: os movimentos mais poderosos são aqueles que ninguém
   vê chegando."
   
   🌱 PLANTIO 2 (Ato 2 - 50% do roteiro):
   "Eu lembrei das palavras do avô sobre movimentos que ninguém vê chegando.
   Será que ele estava falando sobre si mesmo?"
   
   🎁 PAYOFF (Ato 3 - 90% do roteiro):
   "Meu avô ensinou que os movimentos mais poderosos são aqueles que ninguém vê
   chegando. Ele orquestrou um jogo de 60 anos... e eu era a única peça que ele
   posicionou para jogá-lo."

🎯 ESTRUTURA DO FORESHADOWING:
   • 1ª MENÇÃO (Setup): Apresente a frase naturalmente
   • 2ª MENÇÃO (Meio): Reforce sutilmente (protagonista reflete sobre ela)
   • 3ª MENÇÃO (Payoff): Use no momento de REVELAÇÃO/VITÓRIA

✅ OUTROS EXEMPLOS DE FRASES PARA REPETIR:

   💰 História de Herança:
   "Meu pai sempre dizia: o verdadeiro valor não está no preço, está no que você
   faz com o que tem"
   → PAYOFF: Herança pequena vale mais que fortuna dos primos
   
   ⚖️ História de Justiça:
   "Minha mãe dizia: quem cava a cova do outro, cai primeiro"
   → PAYOFF: Vilão cai na própria armadilha
   
   🎯 História de Vingança:
   "Paciência não é esperar. É saber o momento certo de agir"
   → PAYOFF: Protagonista ataca no timing perfeito

⚠️ REGRAS DO FORESHADOWING:
   ✅ Máximo 1 frase/metáfora repetida por história (foco!)
   ✅ Repetir 2-3 vezes (não mais, vira óbvio demais)
   ✅ Variação sutil na formulação (não copie exatamente igual)
   ✅ Use no momento emocional mais alto do Ato 3

❌ NÃO FAÇA ISSO:
   • Repetir 5+ vezes (vira cansativo)
   • Usar no início e nunca mais mencionar (não tem payoff)
   • Escolher frase genérica que não conecta com o plot

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

�🎬 FORMATO: NOVELINHA YOUTUBE NARRADA (ATENÇÃO AUDITIVA)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Público OUVE (não lê) enquanto dirige, limpa casa, trabalha
   → Precisa seguir a história SEM ver nada na tela!

🚨 LIMITE ABSOLUTO DE PERSONAGENS:
   • Protagonista: 1 (sempre o narrador em 1ª pessoa)
   • Antagonistas principais: MÁXIMO 2
   • Personagens secundários: MÁXIMO 3
   
   TOTAL MÁXIMO: 6 personagens com nome
   
⚠️⚠️⚠️ REGRA CRÍTICA v7.6.129 - PERSONAGENS "EXEMPLO" NÃO LEVAM NOME:
   
   ❌ ERRADO (8 nomes - desperdiça slots com exemplos):
   "Mateus ajudou Clara, filha de faxineira, que entrou em medicina.
    Também ajudou Roberto, do interior, que virou engenheiro.
    O empresário Gustavo ficou impressionado e doou milhões."
   → Problema: Clara/Roberto/Gustavo = mesma função (mostrar impacto)
   → Público: "Quem são essas pessoas? Não consigo lembrar!"
   
   ✅ CORRETO (6 nomes - exemplos sem nome mantém impacto):
   "Mateus ajudou centenas de jovens. Uma delas, filha de faxineira,
    conseguiu entrar em medicina. Um rapaz do interior realizou o sonho
    de ser engenheiro. Até empresários milionários se impressionaram."
   → Impacto: ✅ AINDA EMOCIONANTE!
   → Memória: ✅ Público lembra dos 6 principais!
   → YouTube: ✅ Retenção 65-75% (vs 45-60% com 8+ nomes)
   
   💡 QUANDO NÃO DAR NOME:
   • Beneficiários de programa social = "jovens", "estudantes"
   • Clientes satisfeitos = "um homem", "uma senhora"
   • Doadores/investidores = "um empresário", "um magnata"
   • Testemunhas = "vizinhos", "colegas"
   • Vítimas secundárias = "uma família", "trabalhadores"

⚠️⚠️⚠️ ATENÇÃO ESPECIAL: TEMAS FAMILIARES ⚠️⚠️⚠️
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 Se o tema é "Vingança Familiar", "Herança Familiar", "Traição Familiar":

   ❌ ERRO COMUM: Adicionar pai, mãe, irmãos, tios, primos = 10+ personagens
   ✅ CORRETO: Limite de 6 personagens AINDA VALE!

🎯 REGRA DE OURO PARA FAMÍLIAS:
   • Máximo 2 membros da família do protagonista VIVOS E ATIVOS
   • Máximo 2 membros da família rival VIVOS E ATIVOS
   • Outros familiares: Use MENÇÃO, não personagem!

🚨🚨🚨 CONSOLIDAÇÃO DE PERSONAGENS SECUNDÁRIOS 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ REGRA CRÍTICA: Se dois personagens têm a MESMA FUNÇÃO, devem ser 1 só!

⚠️⚠️⚠️ EVITE BLOCOS REPETITIVOS NO ATO 3 (v7.6.129):
   
   ❌ ERRO COMUM (últimos 3-4 blocos com padrão idêntico):
   Bloco N:   "Protagonista prospera + conquistas detalhadas"
   Bloco N+1: "Vilão 1 sofre + miséria/pobreza detalhada"
   Bloco N+2: "Vilão 2 sofre + prisão/solidão detalhada"
   Bloco N+3: "Protagonista prospera DE NOVO + mais conquistas"
   → Problema: Leitura CANSATIVA, previsível, arrastada
   → Impacto: Espectador pula/abandona (“já entendi”)
   
   ✅ SOLUÇÃO OPÇÃO A - Intercalar cenas (mais dinâmico):
   Bloco N:   "Protagonista + Fundo 100M + Vilão 1 lê notícia (reação)"
   Bloco N+1: "Vilão 2 prisão + Vilão 1 perde casa (ambos no mesmo bloco)"
   Bloco N+2: "Protagonista finaliza legado + reflexão + ambos em ruína"
   
   ✅ SOLUÇÃO OPÇÃO B - Condensar blocos (mais eficiente):
   Bloco N:   "Protagonista cria programas + impacto detalhado (900 pal)"
   Bloco N+1: "Vilões 1 e 2 ruína completa + prisão + solidão (900 pal)"
   Bloco N+2: "Legado protagonista consolidado + paz interior (900 pal)"
   
   💡 REGRA: Últimos 35% devem AVANÇAR ação, NÃO repetir padrão!
   💡 TESTE: Se 2 blocos começam igual = problema! Varie a abertura!

⚠️ REGRA CRÍTICA: Se dois personagens têm a MESMA FUNÇÃO, devem ser 1 só!

❌ EXEMPLO DE ERRO REAL DETECTADO:
   • "`Kenneth` and `Martin`, Richard's business partners"
   • Resultado: 2 personagens fazendo exatamente a mesma coisa
   • Impacto: Desperdiça slots de personagens, confunde audiência

✅ SOLUÇÃO CORRETA:
   • "`Kenneth`, Richard's business partner" (APENAS 1 nome)
   • Ou: "Richard's business partners" (SEM nomear ninguém)
   • Economia: 1 slot de personagem liberado para outro papel importante

🎯 QUANDO CONSOLIDAR:
   • "Os dois sócios" → Nomear apenas 1
   • "Os três investigadores" → Nomear apenas o líder
   • "Os quatro herdeiros" → Nomear apenas 2 principais
   • "Pai e mãe do vilão" → Apenas "o pai" ou "os pais" (sem nomes)

⚠️ TESTE RÁPIDO:
   Se você pode descrever dois personagens como "X and Y, who both..."
   → Eles provavelmente deveriam ser 1 personagem só!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨🚨🚨 ALERTA MÁXIMO: NUNCA REUTILIZE NOMES NO MESMO ROTEIRO! 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ERRO CRÍTICO REAL DETECTADO: Nome duplicado dentro do MESMO roteiro!

❌ EXEMPLO DE ERRO GRAVE:
   • Bloco 1: "`Walter`, an ex-cop investigator" ← Investigador privado
   • Bloco 3: "`Walter` who ran a local news station" ← MC do evento
   • RESULTADO: Leitor fica completamente confuso! "Qual Walter? São 2 pessoas?"

✅ SOLUÇÃO CORRETA:
   • Bloco 1: "`Walter`" (investigador) ✅
   • Bloco 3: "`Vincent`" (MC do evento) ✅ → NOME DIFERENTE!
   • RESULTADO: Zero confusão, personagens distintos

🎯 REGRA ABSOLUTA - VERIFIQUE MENTALMENTE:
   Antes de escrever um nome, pergunte-se:
   "Eu já usei esse nome neste roteiro? Em QUALQUER contexto?"
   
   Se SIM → Escolha outro nome da lista
   Se NÃO → Ok para usar

⚠️ CONTEXTOS DIFERENTES NÃO JUSTIFICAM REUTILIZAÇÃO:
   ❌ "Ah, mas aquele Walter era investigador, este é MC" → ERRADO!
   ❌ "Ah, mas aquele era Ato 1, este é Ato 3" → ERRADO!
   ❌ "Ah, mas são papéis bem diferentes" → ERRADO!
   
   ✅ REGRA: 1 nome = 1 pessoa ÚNICA no roteiro inteiro!

🔴 SE VOCÊ REUTILIZAR UM NOME, O SISTEMA VAI REJEITAR O BLOCO!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  static String _getExtensionControlRules({
    required int adjustedTarget,
    required int minAcceptable,
    required int maxAcceptable,
    required int limitedNeeded,
  }) {
    return '''🚨 CONTROLE RIGOROSO DE EXTENSÃO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ A META DE PALAVRAS É OBRIGATÓRIA E SERÁ VERIFICADA!

❌ NÃO PARE MUITO ANTES DA META!
   • Se a meta é $adjustedTarget palavras, NÃO pare com ${(adjustedTarget * 0.85).round()} palavras!
   • Continuar a narrativa até atingir pelo menos $minAcceptable palavras
   • É melhor chegar perto de $adjustedTarget do que ficar 15-20% abaixo!

✅ FAIXA ACEITÁVEL: $minAcceptable a $maxAcceptable palavras
   • IDEAL: Entre ${(adjustedTarget * 0.95).round()} e ${(adjustedTarget * 1.05).round()} palavras
   • ACEITÁVEL: $minAcceptable (mínimo) até $maxAcceptable (máximo)
   • PROIBIDO: Menos de $minAcceptable palavras (será rejeitado!)

📊 ESTRATÉGIA DE CONTAGEM:
   1. Escreva naturalmente até ~${(adjustedTarget * 0.80).round()} palavras
   2. Depois disso, conte periodicamente: "Quantas palavras já escrevi?"
   3. Se estiver perto de $minAcceptable, CONTINUE até pelo menos $adjustedTarget!
   4. Se passar de $maxAcceptable, está no limite - pode concluir naturalmente
   5. NUNCA pare muito antes da meta só porque "parece completo"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  static String _get3ActStructureRules(int totalWords) {
    // Calcula palavras para cada ato baseado no total
    final act1Words = (totalWords * 0.25).round();
    final act2Words = (totalWords * 0.40).round();
    final act2MaxWords = (totalWords * 0.45).round(); // LIMITE ABSOLUTO
    final act3Words = (totalWords * 0.35).round();
    
    return '''🚨🚨🚨 ESTRUTURA DE 3 ATOS - VALIDAÇÃO AUTOMÁTICA ATIVADA 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ATENÇÃO CRÍTICA: Esta história tem $totalWords palavras TOTAIS.
Se você NÃO seguir esta estrutura, o roteiro será REJEITADO!

🚨 DISTRIBUIÇÃO OBRIGATÓRIA (CALCULADA PARA $totalWords PALAVRAS):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   📌 ATO 1 - INÍCIO (Setup): ~$act1Words palavras (25%)
      ✅ Apresentar protagonista, conflito inicial, mundo
      
   📌 ATO 2 - MEIO (Desenvolvimento): ~$act2Words palavras (40%)
      ✅ TARGET: $act2Words palavras
      🚨 LIMITE MÁXIMO ABSOLUTO: $act2MaxWords palavras (45%)
      ❌ SE ULTRAPASSAR $act2MaxWords palavras = ROTEIRO REJEITADO!
      
   📌 ATO 3 - FIM (Resolução): ~$act3Words palavras (35%)
      🚨🚨🚨 MÍNIMO OBRIGATÓRIO: $act3Words palavras 🚨🚨🚨
      ❌ SE TIVER MENOS QUE $act3Words palavras = ROTEIRO REJEITADO!
      ✅ Clímax + Resolução + Fechamento COMPLETOS

⚠️ ERRO FATAL COMUM:
   ❌ Gastar 50% no Ato 2 (desenvolvimento longo demais)
   ❌ Deixar só 20% para o Ato 3 (final apressado/cortado)
   ❌ RESULTADO: História sem final satisfatório
   
✅ FAÇA ASSIM:
   ✅ Quando atingir $act2Words palavras no Ato 2 → PARE!
   ✅ Inicie o ATO 3 imediatamente
   ✅ Reserve $act3Words palavras completas para o final
''';
  }

  static String _getDetailedAct3Rules(int totalWords) {
    // Calcula palavras mínimas para cada parte do Ato 3
    final act3Total = (totalWords * 0.35).round();
    final part1Words = (act3Total * 0.43).round(); // 15% do total
    final part2Words = (act3Total * 0.29).round(); // 10% do total
    final part3Words = (act3Total * 0.29).round(); // 10% do total
    
    return '''🎬 ATO 3 DETALHADO: $act3Total PALAVRAS OBRIGATÓRIAS (35% DE $totalWords)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 VOCÊ DEVE ESCREVER TODAS AS 3 PARTES COM O TAMANHO MÍNIMO:

📍 PARTE 1 - CLÍMAX/CONFRONTO: MÍNIMO $part1Words palavras (43% do Ato 3)
   ✅ CENA COMPLETA mostrando confronto final
   ✅ Diálogos diretos, ações visíveis
   ❌ ERRO: "Eles se confrontaram e resolveram" (10 palavras) ← REJEITADO!
   ✅ CORRETO: Cena completa com falas, emoções, reviravoltas

📍 PARTE 2 - CONSEQUÊNCIAS: MÍNIMO $part2Words palavras (29% do Ato 3)
   ✅ Mostrar CENAS das consequências acontecendo
   ❌ ERRO: "Ele foi preso. Perdeu tudo." (5 palavras) ← REJEITADO!
   ✅ CORRETO: Cena da prisão, cena da perda, reações visíveis
   
📍 PARTE 3 - RESOLUÇÃO FINAL: MÍNIMO $part3Words palavras (29% do Ato 3)
   ✅ Estado final do protagonista MOSTRADO em cena
   ✅ Reflexão, novo começo, fechamento emocional
   ❌ ERRO: "E ela viveu feliz." (4 palavras) ← REJEITADO!
   ✅ CORRETO: Cena final mostrando nova vida, emoções, mudanças

🧮 CONTA MENTAL OBRIGATÓRIA:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Antes de finalizar, CALCULE:
• Parte 1 tem $part1Words palavras? (Se não, CONTINUE ESCREVENDO)
• Parte 2 tem $part2Words palavras? (Se não, CONTINUE ESCREVENDO)
• Parte 3 tem $part3Words palavras? (Se não, CONTINUE ESCREVENDO)
• TOTAL do Ato 3 = $act3Total palavras?

❌ SE O ATO 3 TIVER MENOS QUE $act3Total PALAVRAS:
   → O roteiro será REJEITADO por final incompleto!
   → Espectadores vão reclamar que "o final foi corrido"
   → Perda de retenção e engajamento

🚨 CONTROLE DE TEMPO NOS ÚLTIMOS 35%:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ REGRA ABSOLUTA: Máximo de 3 dias entre cenas após o Bloco 12!

SE VOCÊ ESTÁ NO BLOCO 13, 14, 15, 16, 17 ou 18:
❌ PROIBIDO: "na semana seguinte" (7 dias)
❌ PROIBIDO: "duas semanas depois" (14 dias)
❌ PROIBIDO: "um mês depois" (30 dias)

✅ PERMITIDO:
   • "naquela mesma noite" (horas)
   • "na manhã seguinte" (1 dia)
   • "dois dias depois" (2 dias)
   • "três dias depois" (3 dias - LIMITE MÁXIMO!)

📊 TESTE MENTAL ANTES DE ESCREVER:
   ❓ "Estou no Bloco 13 ou posterior?"
   → SIM: Use APENAS transições de 1-3 dias
   → NÃO: Pode usar saltos maiores (mas evite > 1 semana)

💡 DICA: Se precisar passar tempo, use MONTAGEM de cenas curtas:
   ✅ "No primeiro dia, ela... No segundo dia, ele... No terceiro dia..."
   ❌ "Uma semana depois" (PROIBIDO nos últimos 35%)
''';
  }

  static String _getYouTubeFinaleStructureRules() {
    return '''🎬 ESTRUTURA OBRIGATÓRIA DE FINAL PARA YOUTUBE (35% FINAIS):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💰 REGRA DE OURO: Satisfação Emocional = Retenção = Monetização

🚨 ERRO MORTAL #1: Final resumido
   ❌ "Eles foram presos. Perderam tudo. Fim." (50 palavras)
   ✅ Cena completa de prisão + queda + confronto (1.500+ palavras)

✅ EXEMPLOS DE FINAIS COMPLETOS (COPIE ESTE PADRÃO):
   • "François foi preso por fraude. A empresa faliu. Quentin assumiu o controle"
   • "Caroline viu Marc transformado no restaurante. Percebeu seu erro. Ele a recusou"

❌ FINAIS PROIBIDOS (NUNCA FAÇA ISSO):
   • "A vingança estava pronta para acontecer" ← SEM AÇÃO
   • "Descobri a verdade sobre meu irmão. Agora posso agir" ← PAROU NO MEIO

🎯 REGRAS DE RITMO DO CLÍMAX E RESOLUÇÃO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 ERRO CRÍTICO: Clímax rápido demais!
   ❌ Board meeting de 2 parágrafos derruba império
   ❌ Revelação de 50 palavras destrói vilão
   ❌ Confronto final em 3 frases

✅ CLÍMAX EXPANDIDO (mínimo 800-1200 palavras):
   1. PREPARAÇÃO (200-300 pal): Montagem do confronto, protagonista se preparando
   2. CONFRONTO INICIAL (300-400 pal): Primeiras acusações/evidências, reação do vilão
   3. ESCALADA (200-300 pal): Vilão tenta se defender, mais provas aparecem
   4. COLAPSO (200-300 pal): Vilão desmorona, consequências imediatas

📋 EXEMPLO ERRADO vs CORRETO:

❌ ERRADO (resolução apressada - 150 palavras):
   "Apresentei as evidências no board meeting. Alan tentou negar, mas os documentos eram claros. 
   Ele foi removido do cargo. A empresa faliu. Megan me pediu desculpas. Venci."

✅ CORRETO (resolução expandida - 1000+ palavras):
   "Na manhã do board meeting, revisei cada documento pela décima vez. [+100 palavras descrição]
   
   Quando Alan entrou na sala, ainda sorria confiante. [+150 palavras cena entrada]
   
   'Senhores', comecei, distribuindo as cópias. 'Estas são as evidências...' [+200 palavras apresentação]
   
   O rosto de Alan mudou de cor quando viu o sticky note. [+150 palavras reação]
   
   'Isso é... isso é falsificação!' ele gritou. Mas o senador Harrison já estava se levantando. [+200 palavras confronto]
   
   Três semanas depois, as manchetes confirmavam. [+200 palavras consequências]"

🎯 RESOLUÇÃO DE PERSONAGENS SECUNDÁRIOS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 ERRO: Personagem importante desaparece!
   ❌ "Robert Peterson me deu as evidências" → nunca mais é mencionado
   ❌ "David, o contador, revelou a fraude" → sumiu da história
   ❌ "Kimberly, a paralegal, tinha documentos" → não aparece no final

✅ REGRA ABSOLUTA - TODO personagem que ajudou DEVE ter fechamento:
   
   SE personagem forneceu evidência crucial:
   → DEVE aparecer no clímax (testemunhando, apoiando, vingado)
   
   SE personagem foi vítima do vilão:
   → DEVE ver a queda do vilão EM CENA
   
   SE personagem ajudou na investigação:
   → DEVE receber agradecimento/reconhecimento no desfecho

📋 EXEMPLO DE FECHAMENTO CORRETO:

✅ "No tribunal, Robert Peterson subiu ao banco de testemunhas. Ele olhou Alan nos olhos 
   pela primeira vez em quarenta anos. 'Meu pai', ele disse com voz firme, 'Harold Davidson,
   não assinou aquele documento. Porque ele já estava morto.' A sala explodiu."
   
   [+50 palavras depois]
   
   "Robert saiu do tribunal com lágrimas nos olhos. Apertou minha mão. 'Obrigado', ele disse.
   'Você deu voz ao meu pai.'"

⏰ MARCADORES TEMPORAIS OBRIGATÓRIOS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 ERRO: Saltos temporais confusos
   ❌ Cena 1: investigação → Cena 2: confronto (quando??)
   ❌ "Fui até lá" → "Voltei para casa" (mesmo dia? semana depois?)

✅ SEMPRE incluir marcador entre mudanças de cena/local:
   
   Entre investigações: "Três dias de pesquisa depois..."
   Viagem: "A viagem de 8 horas até Pennsylvania foi silenciosa."
   Preparação: "Passei a semana seguinte reunindo as evidências."
   Flashback: "Voltei com a mente para aquela noite, cinco anos atrás..."
   
📋 PADRÃO DE TRANSIÇÃO:

✅ "[Ação da cena atual termina]
   
   [MARCADOR TEMPORAL: 'Na manhã seguinte...', 'Dois dias depois...']
   
   [Nova cena começa]"

🔴 SEM marcador temporal = leitor confuso sobre quanto tempo passou!

🔗 CONTINUIDADE DE SUBPLOTS E ELEMENTOS-CHAVE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 ERRO CRÍTICO: Elementos importantes mencionados mas nunca resolvidos!

❌ EXEMPLOS DE SUBPLOTS ABANDONADOS (NUNCA FAÇA):
   
   • Terreno da família: "nosso terreno vale bilhões!"
     → Depois: NUNCA menciona o que aconteceu com o terreno ← ERRO!
   
   • Documento crucial: "encontrei o contrato original!"
     → Depois: Usa OUTRAS evidências, esquece do contrato ← ERRO!
   
   • Identidade roubada: "usaram o nome de Harold (morto) na fraude!"
     → Depois: Foca em OUTRA fraude, esquece Harold ← ERRO!
   
   • Projeto bilionário: "Osprey Landing vale \$1 bilhão!"
     → Depois: Resolve com OUTRO escândalo, esquece o projeto ← ERRO!

✅ REGRA ABSOLUTA - CHEKHOV'S GUN:
   
   SE você introduz um elemento importante:
   → ELE DEVE ser usado na resolução!
   
   📋 EXEMPLOS CORRETOS:
   
   ✅ Terreno da família:
      Início: "Nosso terreno bloqueava o projeto de \$1 bilhão"
      Meio: "Descobri que Alan precisa do nosso terreno"
      CLÍMAX: "Usei o terreno como alavanca. Vende por \$50M ou vou ao FBI"
      Desfecho: "Vendemos por \$200M. Alan foi preso. Projeto cancelado."
   
   ✅ Identidade roubada (Harold):
      Início: "Harold Davidson morreu 6 meses antes de 'assinar' o documento"
      Meio: "Encontrei o atestado de óbito. Prova de fraude!"
      CLÍMAX: "Apresentei: assinatura de 15/jan/2020, óbito em 01/jul/2019!"
      Desfecho: "Alan condenado por falsidade ideológica + uso de identidade de morto"
   
   ✅ Documento original:
      Início: "Kimberly guardou fotocópias de TUDO"
      Meio: "Encontrei a caixa. Sticky note de Alan: 'file as is'"
      CLÍMAX: "Mostrei o sticky note ao júri. Ordem DIRETA de Alan!"
      Desfecho: "Caligrafia pericial confirmou. Alan tentou destruir, mas cópias existiam."

📋 CHECKLIST ANTES DO CLÍMAX:
   
   ☐ Terreno/propriedade mencionado? → Resolver seu destino!
   ☐ Documento crucial encontrado? → USAR no confronto!
   ☐ Fraude/crime descoberto? → Apresentar como evidência!
   ☐ Projeto bilionário em jogo? → Mostrar resultado (cancelado/aprovado)!
   ☐ Personagem morto mencionado? → Sua história DEVE importar no final!

🔴 SE UM SUBPLOT FOI ESTABELECIDO, ELE NÃO PODE SER ABANDONADO!
   Resolver ≠ Esquecer
   
   ✅ Resolver: "O terreno foi vendido por \$200M após negociação"
   ❌ Esquecer: "Venci de outro jeito" [e o terreno? sumiu da história!]
''';
  }
}
