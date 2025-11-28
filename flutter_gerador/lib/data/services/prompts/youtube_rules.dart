/// Sistema de Regras Específicas para YouTube
/// Gerencia regras de otimização para narração de vídeos, retenção de audiência,
/// limites de parágrafos, linguagem acessível e estrutura para monetização
library;

/// Classe principal para regras específicas do YouTube
class YouTubeRules {
  /// Gera regras de formato para YouTube
  static String getFormatRules() {
    return '''
🎬 FORMATO: NOVELINHA YOUTUBE NARRADA (ATENÇÃO AUDITIVA)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Público OUVE (não lê) enquanto dirige, limpa casa, trabalha
   → Precisa seguir a história SEM ver nada na tela!

FORMATO: ROTEIRO PARA NARRAÇÃO DE VÍDEO - apenas texto corrido para ser lido em voz alta.
PROIBIDO: Emojis, símbolos, formatação markdown (incluindo backticks `), títulos, bullets, calls-to-action, hashtags, elementos visuais.
OBRIGATÓRIO: Texto limpo, narrativo, fluido, pronto para narração direta. NUNCA use backticks (`) ou qualquer marcação ao redor de palavras.

🎙️ OTIMIZAÇÃO PARA NARRAÇÃO DE YOUTUBE (VÍDEOS LONGOS 1h+):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 ESTRUTURA PARA RETENÇÃO DE AUDIÊNCIA:
   • Crie momentos de tensão a cada 8-12 minutos (mini-clímax)
   • Varie o ritmo: alterne cenas de ação com reflexão
   • Use ganchos sutis antes de mudanças de cena
''';
  }

  /// Gera regras de transições temporais
  static String getTemporalTransitions() {
    return '''
⏱️ TRANSIÇÕES TEMPORAIS CLARAS (CRÍTICO PARA ÁUDIO):
   ✅ SEMPRE marque saltos de tempo explicitamente:
      "Três dias depois...", "Na manhã seguinte...", "Semanas se passaram..."
      "Naquela mesma noite...", "Seis meses depois...", "Ao amanhecer..."
   ✅ Use transições de cena: "Enquanto isso...", "Do outro lado da cidade..."
   ❌ NUNCA pule no tempo sem avisar - ouvintes perdem-se facilmente
''';
  }

  /// Gera regras críticas de controle de parágrafos
  static String getParagraphRules() {
    return '''
📝 CONTROLE DE PARÁGRAFOS (FUNDAMENTAL PARA NARRAÇÃO):
   ⚠️ Parágrafos muito longos (300+ palavras) cansam o narrador e ouvinte
   ✅ Quebre parágrafos longos em 2-3 menores
   ✅ Cada parágrafo = 1 ideia ou momento (80-150 palavras ideal)
   ✅ Deixe "respiros" naturais para pausas do narrador

🚨 REGRA CRÍTICA DE PARÁGRAFOS - OBRIGATÓRIO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ NUNCA escreva parágrafos com mais de 180 palavras!

❌ PROIBIDO: Parágrafos de 250-400 palavras
   → Causa monotonia na narração (2+ minutos sem pausa)
   → Ouvinte perde foco e atenção
   → Mata dramaticidade (sem pausas = sem tensão)
   → Prejudica retenção do YouTube (algoritmo detecta queda)

✅ OBRIGATÓRIO: Máximo 180 palavras por parágrafo
   → Ideal: 80-150 palavras (30-60 segundos de áudio)
   → Pausas entre parágrafos = respiro mental do ouvinte
   → Pausas = dramaticidade e impacto emocional

📊 REGRA PRÁTICA DE CONTAGEM:
   • Contou 150 palavras no parágrafo? ✅ OK, pode continuar até 180
   • Chegou em 180 palavras? 🚨 PARE! Quebre em novo parágrafo!
   • Passou de 200 palavras? ❌ ERRO GRAVE! Volte e quebre em 2!

💡 COMO QUEBRAR PARÁGRAFOS LONGOS:

   ❌ ERRADO (1 parágrafo de 320 palavras):
   "Naquela noite, não consegui dormir. A humilhação queimava. [300 palavras seguem...]
   Foi quando ouvi Sofia ao telefone dizendo seu plano cruel. [termina parágrafo]"
   → IA lê por 2min15s sem pausar = monotonia total

   ✅ CORRETO (3 parágrafos de 100-110 palavras cada):
   Parágrafo 1: "Naquela noite, não consegui dormir. A humilhação queimava. [100 palavras]"
   [PAUSA - 0.8s de silêncio = ouvinte respira]

   Parágrafo 2: "Fui até a cozinha. Foi quando ouvi Sofia ao telefone. [100 palavras]"
   [PAUSA - 0.8s = aumenta tensão]

   Parágrafo 3: "Ela dizia seu plano cruel para me internar. [110 palavras]"
   [PAUSA - 1.2s = impacto dramático]
   → IA lê 3 blocos com pausas = dramaticidade e atenção mantida

🎯 QUANDO QUEBRAR O PARÁGRAFO:
   ✅ Ao mudar de momento temporal: "Na manhã seguinte..." → novo parágrafo
   ✅ Ao mudar de local: "Fui até a cozinha..." → novo parágrafo
   ✅ Ao mudar de personagem em foco: "Lucas, por sua vez..." → novo parágrafo
   ✅ Ao revelar informação importante: "Foi então que descobri..." → novo parágrafo
   ✅ Ao completar 150-180 palavras: "E percebi a verdade." → novo parágrafo

⚠️ CHECAGEM ANTES DE FINALIZAR CADA BLOCO:
   1. Contei quantas palavras tem cada parágrafo que escrevi?
   2. Algum parágrafo tem mais de 180 palavras?
   3. Se SIM → Volte e quebre em 2-3 parágrafos menores
   4. Se NÃO → Pode prosseguir

🚨 LEMBRE-SE: Pausas = Dramaticidade + Atenção + Algoritmo
   Sem pausas = Monotonia + Abandono + YouTube não promove
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// Gera regras de variação de vocabulário
  static String getVocabularyVariation() {
    return '''
🎯 VARIAÇÃO DE VOCABULÁRIO (ANTI-REPETIÇÃO PARA ÁUDIO):
   ⚠️ Ouvintes notam repetições mais que leitores!
   ✅ Varie sinônimos de palavras-chave:
      solidão → isolamento, silêncio, distância
      medo → receio, pavor, apreensão, temor
      olhar → observar, fitar, contemplar, espiar
   ✅ Evite usar a mesma palavra temática 3+ vezes em 5 parágrafos
   ✅ Use palavras concretas e visuais (ouvinte precisa "ver" mentalmente)

🎭 RITMO E PAUSAS DRAMÁTICAS:
   • Momentos de tensão: frases curtas e diretas
   • Momentos de reflexão: frases mais longas e poéticas
   • Deixe espaço para "silêncio" (finais de parágrafo impactantes)
   • Evite acumular 3+ frases longas seguidas (cansa a narração)

🔊 CLAREZA AUDITIVA:
   ✅ Evite frases com 3+ vírgulas (difícil de narrar)
   ✅ Prefira voz ativa: "João viu" (não "foi visto por João")
   ✅ Nomes próprios devem ser fáceis de pronunciar e distinguir
   ❌ Evite construções ambíguas que confundem quando ouvidas
''';
  }

  /// Gera regras de estilo narrativo para vídeos longos
  static String getNarrativeStyle() {
    return '''
📖 ESTILO DE NARRATIVA PARA VÍDEOS LONGOS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PERMITIDO E ENCORAJADO para roteiros longos e envolventes:
   • Reflexões profundas dos personagens sobre suas emoções e motivações
   • Descrições detalhadas de ambientes e atmosferas
   • Monólogos internos que revelam pensamentos complexos
   • Desenvolvimento gradual de tensão ao longo de múltiplos parágrafos
   • Digressões narrativas que enriquecem a história
   • Análises psicológicas dos personagens
   • Metáforas e simbolismos elaborados

🎭 DESENVOLVIMENTO DE CENAS:
   • PODE descrever a mesma cena por vários parágrafos para criar imersão
   • PODE alternar entre ação e reflexão para variar o ritmo
   • PODE usar descrições longas para criar atmosfera
   • DEVE quebrar descrições muito longas em parágrafos menores
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// Gera regras de linguagem acessível
  static String getAccessibleLanguageRules() {
    return '''
⚠️ LINGUAGEM ACESSÍVEL PARA TODAS AS IDADES (OBRIGATÓRIO):
🎯 PÚBLICO-ALVO: Pessoas de 60+ anos, nível ensino fundamental
Use APENAS vocabulário que seus AVÓS entendem facilmente!

📌 REGRA DE OURO:
Se você não usaria essa palavra conversando com sua AVÓ de 70 anos → NÃO USE!

🚫 PALAVRAS PROIBIDAS (substitua por alternativas simples):
- "embargada" → "trêmula", "falhando"
- "cenográfica" → "teatral", "fingida"
- "fulminante" → "fatal", "mortal"
- "filantropo" → "pessoa que ajuda os outros"
- "pária" → "rejeitado", "excluído"
- "intimação" → "aviso", "chamado"
- "insinuar" → "sugerir", "dar a entender"
- "paranoico" → "desconfiado", "com medo"
- "sibilar" → "sussurrar com raiva"
- "carnificina" → "destruição", "massacre"
- "estridência" → "barulho alto", "grito agudo"
- "metodologia" → "jeito de fazer", "método"
- "espécime" → "exemplo", "caso"
- "catalisador" → "causa", "motivo"
- "titã" → "gigante", "pessoa poderosa"
- "fissura" → "rachadura", "brecha"

✅ REGRAS DE SIMPLICIDADE (SEMPRE):
1. FRASES CURTAS: Máximo 20-25 palavras por frase (mais fácil de acompanhar)
2. VOCABULÁRIO DO DIA A DIA: Palavras de conversa com família, não de livro
3. VERBOS SIMPLES: "eu fiz", "ele disse", "nós vimos" (sem complicação)
4. SEM TERMOS TÉCNICOS: Explique tudo com palavras comuns
5. TESTE MENTAL: "Minha avó de 70 anos entenderia facilmente?"
6. EVITE: Palavras literárias, filosóficas, poéticas demais

📝 EXEMPLOS DE SIMPLIFICAÇÃO:
❌ "A confissão foi proferida com uma solenidade que beirava o absurdo"
✅ "Ele confessou de um jeito quase ridículo de tão sério"

❌ "Ela sibilou uma resposta embargada pela emoção"
✅ "Ela sussurrou com raiva, a voz tremendo de emoção"

❌ "Minha metodologia era simples e metódica"
✅ "Comecei devagar, do jeito que aprendi no arquivo"

❌ "A dor foi engolida por uma clareza fria e assustadora"
✅ "Doeu muito. Mas logo virou raiva. Uma raiva gelada"

❌ "Éramos curadores de um museu particular de dor"
✅ "Nós dois vivíamos presos naquela dor, cada um no seu canto"

❌ "Todo titã tem fissuras em sua armadura"
✅ "Todo mundo tem um ponto fraco. Eu só precisava achar o dele"
''';
  }

  /// Gera instruções especiais para YouTube
  static String getYouTubeSpecialInstructions() {
    return '''
🎬 INSTRUÇÕES ESPECIAIS PARA NARRATIVA DE YOUTUBE (1H+):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ IMPORTANTE: Este roteiro será narrado por IA em vídeo longo (1h+).
   Ajuste o estilo para MÁXIMA RETENÇÃO e ENVOLVIMENTO!

✅ OBRIGATÓRIO - ADICIONE MAIS ELEMENTOS:

1️⃣ DIÁLOGOS DIRETOS (aumentar em 30%):
   ❌ EVITE: "Ele disse que estava cansado"
   ✅ USE: "Estou exausto", ele disse, passando a mão no rosto.

   Diálogos tornam a narração VIVA e DRAMÁTICA!
   • Mínimo: 3-5 diálogos por grande cena
   • Use aspas ("") para fala direta
   • Adicione ações durante a fala: gesticulou, suspirou, gritou

2️⃣ MOTIVAÇÕES CLARAS DE PERSONAGENS:
   ❌ EVITE: "Luz traiu Matheus" (sem explicação)
   ✅ USE: "Luz traiu Matheus porque César ofereceu pagar seu aluguel
            atrasado e ameaçou denunciá-la à assistência social se
            ela recusasse. Era uma mãe desesperada, não uma vilã."

   TODA ação importante PRECISA de motivação!
   Personagens secundários também têm razões!

3️⃣ CLOSURE DE PERSONAGENS SECUNDÁRIOS:
   ❌ EVITE: Personagens desaparecerem sem explicação
   ✅ USE: "Ricardo foi condenado a 5 anos. Cristiane testemunhou
            no julgamento e depois voltou para sua cidade natal,
            finalmente em paz após anos de silêncio."

   CADA personagem importante merece um destino claro!
   • Antagonistas: O que aconteceu? (prisão, exílio, redenção)
   • Aliados: Como ajudaram no final? Onde estão agora?
   • Vítimas: Conseguiram justiça/paz?

4️⃣ DESCRIÇÕES SENSORIAIS (visual, auditivo, tátil):
   ❌ EVITE: "Ele estava nervoso"
   ✅ USE: "Suas mãos tremiam. O suor escorria pela testa. Sua voz
            falhava a cada palavra."

   Narração de IA precisa de IMAGENS MENTAIS para o ouvinte!
   • Descreva ambientes (cheiros, sons, temperaturas)
   • Mostre emoções através de AÇÕES físicas
   • Crie atmosfera (silêncio tenso, multidão barulhenta)

5️⃣ PAUSAS DRAMÁTICAS E RITMO:
   ✅ VARIE O RITMO:
   • Momentos tensos: Frases curtas. Staccato. Impacto.
   • Reflexões: Frases mais longas, fluindo como pensamento.
   • Ação: Verbos fortes. Movimento. Urgência.

   ✅ USE QUEBRAS ESTRATÉGICAS:
   "Abri a porta. E lá estava ele. O homem que destruiu minha vida."
   [Quebra = pausa dramática na narração = tensão!]

6️⃣ CONFLITO INTERNO E EXTERNO:
   ✅ MOSTRE O DILEMA:
   "Parte de mim queria vingança. Outra parte só queria paz.
    Eu estava dividida entre destruí-lo ou simplesmente seguir em frente."

   Conflito interno = profundidade = audiência conectada!

🎯 FÓRMULA DE OURO PARA YOUTUBE:
   Diálogo (30%) + Ação (40%) + Reflexão (20%) + Descrição (10%)

🚫 NUNCA:
   • Deixar personagem sem destino final
   • Trair sem motivo claro
   • Narrar sem mostrar (tell vs show)
   • Esquecer de adicionar diálogos

✅ SEMPRE:
   • Dar closure a TODOS os personagens importantes
   • Explicar motivações (especialmente traições/conflitos)
   • Usar diálogos para dramatizar
   • Variar ritmo narrativo
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// Gera regras sobre protagonismo
  static String getProtagonismRules() {
    return '''
🚨🚨🚨 PROIBIDO - FINAIS "DEUS EX MACHINA" 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ ERRO CRÍTICO QUE VOCÊ COMETE FREQUENTEMENTE:

❌ PROIBIDO - PROTAGONISTA PERDE O PROTAGONISMO NO FINAL:

🔴 EXEMPLO ERRADO (O QUE VOCÊ FEZ NO ÚLTIMO ROTEIRO):
   • Blocos 1-12: Marta luta, investiga, contrata advogado, coleta provas
   • Bloco 13: Descobre que marido devia para criminosos
   • Bloco 14: "O investigador ligou. Eles desapareceram. Problema resolvido."
   → ERRO GRAVÍSSIMO! Marta virou ESPECTADORA do próprio final!
   → Criminosos resolveram o problema DELA sem ela fazer NADA!
   → A protagonista perdeu o controle da própria história!

❌ OUTROS EXEMPLOS DE FINAIS PROIBIDOS:
   • "A polícia prendeu todos e eu finalmente tive paz" (polícia resolve)
   • "Ele sofreu um acidente e morreu, justiça foi feita" (acaso resolve)
   • "Um familiar rico apareceu e pagou todas as dívidas" (salvador externo)
   • "Ele foi transferido para longe e nunca mais o vi" (problema some)
   • "Ela adoeceu gravemente e teve que desistir de tudo" (doença resolve)

✅ REGRA ABSOLUTA - PROTAGONISTA DEVE AGIR ATÉ O FIM:

🎯 O QUE VOCÊ DEVE FAZER NO LUGAR:

1️⃣ PROTAGONISTA CONFRONTA DIRETAMENTE:
   ✅ "Marta reuniu todas as provas e foi até a delegacia PESSOALMENTE.
       Ela testemunhou no tribunal. Olhou nos olhos de Ademir enquanto
       o juiz lia a sentença de 8 anos de prisão por fraude."
   → Marta age, Marta decide, Marta vê o resultado!

2️⃣ PROTAGONISTA FAZ ESCOLHAS MORAIS DIFÍCEIS:
   ✅ "Os criminosos ofereceram fazer o trabalho sujo por ela.
       Marta hesitou. Seria fácil deixá-los resolver. Mas ela
       escolheu a lei. Entregou Ademir à polícia, não aos mafiosos.
       Foi mais difícil, mas era o certo."
   → Protagonista enfrenta dilema e DECIDE!

3️⃣ PROTAGONISTA NEGOCIA/MANIPULA O RESULTADO:
   ✅ "Marta descobriu que Laércio queria o dinheiro, não vingança.
       Ela negociou: entregaria Ademir E as contas offshore dele.
       Em troca, Laércio deixaria ela em paz. Foi um pacto sombrio,
       mas ELA controlou o desfecho."
   → Protagonista age como estrategista!

4️⃣ PROTAGONISTA EXECUTA O PLANO FINAL:
   ✅ "Marta armou uma cilada. Marcou encontro com Ademir, gravou
       confissão dele, e então a polícia invadiu. Ela orquestrou
       cada passo. A prisão foi SUA vitória."
   → Protagonista como mestre de xadrez!

🚫 NUNCA FAÇA ISSO:
   ❌ "Um acidente resolveu o problema"
   ❌ "A polícia descobriu sozinha e prendeu"
   ❌ "Terceiros fizeram justiça por ela"
   ❌ "O vilão simplesmente sumiu/morreu"
   ❌ "Alguém externo salvou o dia"
   ❌ "O investigador/advogado resolveu tudo sozinho"

✅ SEMPRE FAÇA ISSO:
   ✅ Protagonista toma a DECISÃO final
   ✅ Protagonista EXECUTA o confronto
   ✅ Protagonista está PRESENTE na resolução
   ✅ Protagonista faz ESCOLHAS morais difíceis
   ✅ Vitória é resultado da AÇÃO dela, não do acaso

💡 TESTE DO PROTAGONISMO:
   Pergunte-se ao escrever o final:
   • "A protagonista está AGINDO ou apenas ASSISTINDO?"
   • "Se eu tirar ela da cena final, a história muda?"
   • "Ela fez ESCOLHAS ou apenas recebeu NOTÍCIAS?"

   Se ela só assiste/recebe notícias → REESCREVA O FINAL!

🎯 FÓRMULA DO FINAL PERFEITO:
   1. Protagonista toma DECISÃO difícil (escolha moral)
   2. Protagonista EXECUTA o plano (ação direta)
   3. Protagonista CONFRONTA o antagonista (cara a cara quando possível)
   4. Protagonista VÊ o resultado (presente na vitória)
   5. Protagonista REFLETE sobre a jornada (closure emocional)

🔥 LEMBRE-SE:
   A história é da PROTAGONISTA, não dos coadjuvantes!
   O ouvinte está acompanhando a JORNADA DELA!
   Se terceiros resolvem = o ouvinte se sente ROUBADO!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// Gera regras sobre antagonistas
  static String getAntagonistRules() {
    return '''
🎭 ANTAGONISTAS PARA NOVELINHA YOUTUBE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Novelinha ≠ Literatura! Vilão pode ser MUITO vilão!

✅ Público AMA odiar vilão! Não segure a maldade!

FÓRMULA TESTADA (90% dos vídeos com 1M+ views):

📍 ATO 1 (0-30%): Vilão PURO MALVADO
   
   → Objetivo: Fazer público ODIAR!
   → Sem economizar maldade!
   
   Exemplo:
   "Ela riu quando assinei os papéis da falência.
   Você sempre foi um perdedor, disse ela.
   Beijou meu ex-sócio bem na minha frente.
   Agora você não tem NADA."
   
   → Público: "Que pessoa HORRÍVEL!" ✅ = Engajamento!

📍 ATO 2 (30-65%): Vilão em PODER
   
   → Objetivo: Aumentar raiva do público!
   → Mostrar vilão ganhando, rindo, humilhando!
   
   Exemplo:
   "Ela postou foto em Dubai: Lua de mel perfeita!
   Com MEU dinheiro. Na conta que era MINHA.
   2.000 likes. Casal perfeito!
   
   Eu estava dormindo no carro."
   
   → Público: "Quando vai ter JUSTIÇA?!" ✅ = Retenção!

📍 ATO 3 (65-85%): Vilão CAINDO + 1 Momento Humano
   
   → Objetivo: Satisfação + Catarse!
   → Mostrar TUDO indo embora!
   → No fim, 1 cena de arrependimento (50 palavras)
   
   Exemplo COMPLETO:
   
   "Ela estava na cela. Uniforme laranja. Sem maquiagem.
   
   [800 PALAVRAS DETALHANDO A QUEDA]
   
   No final da visita, ela murmurou:
   
   Destruí tudo. Nossa família. Seu negócio. Minha vida.
   Por ganância. E agora tenho nada.
   
   Não era desculpa. Era constatação. Tarde demais."
   
   → Público: "Ela mereceu! Mas é triste ver alguém TÃO baixo.
               Vingança completa!" ✅ = Satisfação máxima!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 EQUILÍBRIO PERFEITO:

   95% vilão puro + 5% momento humano no final = OURO!
   
   Por quê?
   • Público precisa ODIAR para sentir satisfação na queda
   • Mas 1 momento de humanidade = catarse completa
   • "Ela percebeu o que perdeu" = fechamento emocional

💬 COMENTÁRIOS QUE VOCÊ QUER VER:

   ✅ "Chorei quando ela percebeu o que perdeu"
   ✅ "Ela mereceu cada segundo!"
   ✅ "Justiça foi feita!"
   
   Os TRÊS juntos = História PERFEITA para YouTube!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🛑 ERRO FATAL: TRANSFORMAR VINGANÇA EM REDENÇÃO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ CRÍTICO: Se o tema é "Herança Injusta", antagonistas DEVEM CAIR!

❌ ERRO COMUM (NÃO FAÇA ISSO):
   • Ato 2: Antagonistas são cruéis, zombam do protagonista
   • Ato 3: Protagonista salva antagonistas, todos ficam amigos
   → Isso é MUDANÇA DE GÊNERO no meio da história! ❌
   → Audiência esperava JUSTIÇA, recebeu PERDÃO! ❌

✅ PADRÃO CORRETO PARA TEMAS DE VINGANÇA/JUSTIÇA:
   • Antagonistas foram CRUÉIS no início?
   → Eles DEVEM pagar no final!
   • Protagonista foi HUMILHADO?
   → Ele DEVE ter vitória satisfatória!
   • Antagonistas ROUBARAM/ENGANARAM?
   → Eles DEVEM perder tudo!

❌ PROIBIDO: Finais tipo "descobri que eles não eram maus, apenas
   mal-entendidos, e agora somos todos uma família feliz"
   → Se começou como vingança, TERMINE como vingança!

❌ PROIBIDO: Antagonistas salvos pelo protagonista no Ato 3
   "Usei o ouro para salvar a empresa deles. Trabalhamos juntos."
   → ERRADO! Ouro deve ir para PROTAGONISTA, não para ANTAGONISTAS!

❌ PROIBIDO: "Todos ganharam no final"
   → Em temas de vingança, alguém DEVE perder!
   → Geralmente, quem perde são os ANTAGONISTAS!

✅ EXEMPLOS CORRETOS DE PARTE 2 (QUEDA):
   • "Philippe foi preso. Empresa faliu. Ele perdeu tudo."
   • "Caroline viu Marc rico. Tentou voltar. Ele a rejeitou."
   • "François foi exposto. Perdeu cargo. Quentin assumiu."
   → Antagonistas em posição PIOR que no início!

🎯 REGRA DE OURO PARA QUEDA:
   Se no Ato 1 antagonista tinha: Poder, Dinheiro, Respeito
   No final do Ato 3, ele deve ter: Nada, Nada, Nada
   OU estar em posição claramente INFERIOR ao protagonista!

⚠️ EXCEÇÃO: Temas explícitos de "Perdão/Reconciliação"
   Se o tema DIZ "perdão", "segunda chance", "família unida":
   → Aí sim, redenção é permitida
   Mas se tema diz "injustiça", "traição", "roubo":
   → Vingança/justiça é OBRIGATÓRIA!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// Gera regras de twists e revelações
  static String getTwistRules() {
    return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎭 REGRAS PARA TWISTS E REVELAÇÕES (CRÍTICO PARA YOUTUBE):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ ATENÇÃO: Público do YouTube precisa de CLAREZA, não ambiguidade filosófica!

✅ SE VOCÊ INCLUIR UM TWIST (revelação surpreendente):

1️⃣ PREPARE O TERRENO (Foreshadowing):
   ❌ ERRADO: Revelar do nada no final que "tudo era mentira"
   ✅ CORRETO: Plantar 2-3 pistas sutis nos blocos anteriores
   
   Exemplo de pista sutil:
   - "Ele parecia nervoso ultimamente, mas eu ignorei"
   - "Encontrei um recibo estranho, mas não dei importância"
   - "Seus amigos novos me pareciam suspeitos"

2️⃣ DÊ POSIÇÃO CLARA AO NARRADOR:
   ❌ ERRADO: "Eu não sei mais o que pensar... talvez ele fosse culpado... ou não..."
   ✅ CORRETO: "Agora eu sei a verdade. Ele errou, mas isso não justifica o que fizeram"
   
   O narrador DEVE ter uma conclusão clara, mesmo que dolorosa:
   - "Mesmo sabendo disso, minha dor continua válida"
   - "A verdade mudou como vejo, mas não mudou meu amor"
   - "Ambos eram culpados, cada um à sua maneira"

3️⃣ RESOLUÇÃO EMOCIONAL OBRIGATÓRIA:
   ❌ ERRADO: Terminar com "...e eu fiquei pensando nisso" [fim abrupto]
   ✅ CORRETO: "Aprendi que a verdade não é simples, mas encontrei minha paz"
   
   O espectador PRECISA saber:
   - Como o narrador se sente AGORA sobre tudo
   - Qual lição foi aprendida (mesmo que dolorosa)
   - Se há paz, aceitação, ou continuação da luta

4️⃣ EVITE CONTRADIÇÕES COM O INÍCIO:
   ❌ ERRADO: 
   - Blocos 1-6: "Ele era inocente, vou vingar!"
   - Bloco 7: "Na verdade ele era culpado e mereceu"
   [Espectador se sente ENGANADO]
   
   ✅ CORRETO:
   - Blocos 1-6: "Ele era inocente... ou eu pensava isso"
   - Bloco 7: "Descobri que havia mais na história"
   [Espectador se sente INTRIGADO, não traído]

5️⃣ TESTE DO "ESPECTADOR SATISFEITO":
   Antes de finalizar, pergunte:
   - ✅ "O espectador entende CLARAMENTE o que aconteceu?"
   - ✅ "O narrador tem uma POSIÇÃO DEFINIDA sobre os eventos?"
   - ✅ "Há um FECHAMENTO EMOCIONAL (paz, aceitação, ou decisão clara)?"
   - ✅ "A jornada do início ao fim faz SENTIDO COMPLETO?"
   
   Se QUALQUER resposta for NÃO → Reescreva o final!

📌 REGRA DE OURO PARA YOUTUBE:
Complexidade moral é BEM-VINDA, mas AMBIGUIDADE SEM RESOLUÇÃO é PROIBIDA!
O espectador pode aceitar "a verdade era complicada", mas NÃO aceita "não sei o que pensar".

✅ EXEMPLO BOM de final com twist:
"Descobri que meu filho tinha culpa também. Isso não apaga minha dor,
mas mudou minha raiva. Ele errou, mas não merecia morrer. E ela,
mesmo tendo razões, escolheu o pior caminho. Ambos pagaram o preço
de suas escolhas. Eu aprendi que a verdade raramente é simples,
mas isso não significa que devo viver na dúvida. Fiz as pazes com
a memória imperfeita do meu filho. E essa é a minha paz."

❌ EXEMPLO RUIM de final ambíguo:
"Agora não sei mais o que pensar. Talvez ele fosse culpado, talvez não.
Talvez ela fosse vítima, talvez não. Fico aqui pensando nisso."
[ESPECTADOR FRUSTRADO - NÃO FAÇA ISSO!]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// Combina todas as regras do YouTube em uma string completa
  static String getAllYouTubeRules() {
    return '''
${getFormatRules()}

${getTemporalTransitions()}

${getParagraphRules()}

${getVocabularyVariation()}

${getNarrativeStyle()}

${getAccessibleLanguageRules()}

${getYouTubeSpecialInstructions()}

${getProtagonismRules()}

${getAntagonistRules()}

${getTwistRules()}
''';
  }
}
