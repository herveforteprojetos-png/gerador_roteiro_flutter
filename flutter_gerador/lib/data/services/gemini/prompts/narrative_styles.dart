// 🏗️ v7.6.67: Módulo extraído de gemini_service.dart
// Sistema de Estilos Narrativos - Templates para diferentes tons de narração
// Parte da arquitetura SOLID - Single Responsibility Principle

library narrative_styles;

import 'package:flutter_gerador/data/models/script_config.dart';

/// 🎭 Classe para geração de orientações de estilo narrativo
class NarrativeStyleBuilder {
  /// Extrai ano de strings como "Ano 1890, Velho Oeste" ou "1920, Nova York"
  static String extractYear(String localizacao) {
    if (localizacao.trim().isEmpty) return '';

    // Padrões: "Ano 1890", "ano 1920", "Year 1850", "1776"
    final yearRegex = RegExp(r'(?:Ano|ano|Year|year)?\s*(\d{4})');
    final match = yearRegex.firstMatch(localizacao);

    if (match != null) {
      final year = match.group(1)!;
      final yearInt = int.tryParse(year);

      // Validar se é um ano razoável (1000-2100)
      if (yearInt != null && yearInt >= 1000 && yearInt <= 2100) {
        return year;
      }
    }

    return '';
  }

  /// Retorna lista de anacronismos a evitar baseado no ano
  static List<String> getAnachronismList(String year) {
    if (year.isEmpty) return [];

    final yearInt = int.tryParse(year);
    if (yearInt == null) return [];

    final anachronisms = <String>[];

    // Tecnologias por período (data da invenção/popularização)
    if (yearInt < 1876) anachronisms.add('Telefone (inventado em 1876)');
    if (yearInt < 1879) {
      anachronisms.add('Lâmpada elétrica (inventada em 1879)');
    }
    if (yearInt < 1886) {
      anachronisms.add('Automóvel a gasolina (inventado em 1886)');
    }
    if (yearInt < 1895) anachronisms.add('Cinema (inventado em 1895)');
    if (yearInt < 1903) anachronisms.add('Avião (inventado em 1903)');
    if (yearInt < 1920) {
      anachronisms.add('Rádio comercial (popularizado em 1920)');
    }
    if (yearInt < 1927) anachronisms.add('Cinema sonoro (1927)');
    if (yearInt < 1936) anachronisms.add('Televisão comercial (1936)');
    if (yearInt < 1946) anachronisms.add('Computador eletrônico (ENIAC 1946)');
    if (yearInt < 1950) anachronisms.add('Cartão de crédito (1950)');
    if (yearInt < 1969) anachronisms.add('Internet/ARPANET (1969)');
    if (yearInt < 1973) anachronisms.add('Telefone celular (1973)');
    if (yearInt < 1981) anachronisms.add('Computador pessoal (IBM PC 1981)');
    if (yearInt < 1983) anachronisms.add('Internet comercial (1983)');
    if (yearInt < 1991) anachronisms.add('World Wide Web (1991)');
    if (yearInt < 2001) anachronisms.add('Wikipedia (2001)');
    if (yearInt < 2004) anachronisms.add('Facebook (2004)');
    if (yearInt < 2006) anachronisms.add('Twitter (2006)');
    if (yearInt < 2007) anachronisms.add('iPhone/Smartphone moderno (2007)');

    return anachronisms;
  }

  /// Retorna elementos de época que DEVEM ser incluídos
  static List<String> getPeriodElements(String year, String? genre) {
    if (year.isEmpty) return [];

    final yearInt = int.tryParse(year);
    if (yearInt == null) return [];

    final elements = <String>[];

    // 🤠 WESTERN (1850-1900)
    if (genre == 'western' && yearInt >= 1850 && yearInt <= 1900) {
      elements.addAll([
        'Revólver (Colt Peacemaker comum após 1873)',
        'Saloon com portas batentes',
        'Cavalo como transporte principal',
        'Diligência (stagecoach)',
        'Xerife e delegados',
        'Lei do mais rápido',
      ]);

      if (yearInt >= 1869) {
        elements.add('Ferrovia transcontinental (completada em 1869)');
      }
      if (yearInt >= 1844) {
        elements.add('Telégrafo para comunicação à distância');
      }
    }

    // 📅 ELEMENTOS GERAIS POR PERÍODO
    if (yearInt < 1850) {
      // Era pré-industrial
      elements.addAll([
        'Iluminação a vela ou lampião a óleo',
        'Transporte por carroça ou cavalo',
        'Cartas entregues por mensageiro',
        'Vestimentas formais e conservadoras',
        'Sociedade rigidamente hierárquica',
      ]);
    } else if (yearInt >= 1850 && yearInt < 1900) {
      // Era vitoriana/industrial
      elements.addAll([
        'Iluminação a gás nas cidades',
        'Trem a vapor (ferrovias em expansão)',
        'Telégrafo para comunicação',
        'Fotografia (daguerreótipo)',
        'Jornais impressos',
      ]);
    } else if (yearInt >= 1900 && yearInt < 1920) {
      // Belle Époque / Era Eduardiana
      elements.addAll([
        'Primeiros automóveis (ainda raros)',
        'Telefone fixo (casas ricas)',
        'Cinema mudo',
        'Iluminação elétrica nas cidades',
        'Fonógrafo (música gravada)',
      ]);
    } else if (yearInt >= 1920 && yearInt < 1945) {
      // Entre-guerras
      elements.addAll([
        'Rádio como principal entretenimento',
        'Cinema sonoro (após 1927)',
        'Automóveis mais comuns',
        'Telefone residencial',
        'Aviões comerciais (raros)',
      ]);
    } else if (yearInt >= 1945 && yearInt < 1970) {
      // Pós-guerra / Era de ouro
      elements.addAll([
        'Televisão em preto e branco',
        'Automóvel como padrão',
        'Eletrodomésticos modernos',
        'Cinema em cores',
        'Discos de vinil',
      ]);
    } else if (yearInt >= 1970 && yearInt < 1990) {
      // Era moderna
      elements.addAll([
        'Televisão em cores',
        'Telefone residencial fixo',
        'Fitas cassete e VHS',
        'Primeiros computadores pessoais (após 1981)',
        'Walkman (música portátil)',
      ]);
    } else if (yearInt >= 1990 && yearInt < 2007) {
      // Era digital inicial
      elements.addAll([
        'Internet discada/banda larga',
        'Celular básico (sem smartphone)',
        'E-mail',
        'CDs e DVDs',
        'Computadores pessoais comuns',
      ]);
    } else if (yearInt >= 2007 && yearInt <= 2025) {
      // Era dos smartphones
      elements.addAll([
        'Smartphone touchscreen',
        'Redes sociais (Facebook, Twitter, Instagram)',
        'Wi-Fi ubíquo',
        'Streaming de vídeo/música',
        'Apps para tudo',
      ]);
    }

    return elements;
  }

  /// Gera orientação de estilo narrativo baseado na configuração
  static String getNarrativeStyleGuidance(ScriptConfig config) {
    final style = config.narrativeStyle;

    switch (style) {
      case 'reflexivo_memorias':
        return _getReflexivoMemoriasStyle();

      case 'epico_periodo':
        return _getEpicoPeriodoStyle(config);

      case 'educativo_curioso':
        return _getEducativoCuriosoStyle();

      case 'acao_rapida':
        return _getAcaoRapidaStyle();

      case 'lirico_poetico':
        return _getLiricoPoeticoStyle();

      default: // ficcional_livre
        return _getFiccionalLivreStyle();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTILOS NARRATIVOS INDIVIDUAIS
  // ═══════════════════════════════════════════════════════════════════════════

  static String _getReflexivoMemoriasStyle() {
    return '''
════════════════════════════════════════════════════════════════════════════════
📚 ESTILO NARRATIVO: REFLEXIVO (MEMÓRIAS)
════════════════════════════════════════════════════════════════════════════════

**Tom:** Nostálgico, pausado, introspectivo, suave
**Ritmo:** Lento e contemplativo, com pausas naturais
**Perspectiva emocional:** Olhar do presente para o passado com sabedoria

**ESTRUTURA NARRATIVA:**
1. Começar com gatilhos de memória: "Eu me lembro...", "Naquele tempo...", "Era uma época em que..."
2. Intercalar presente e passado sutilmente
3. Usar pausas reflexivas (reticências, silêncios)
4. Incluir detalhes sensoriais: cheiro, textura, luz, sons
5. Mencionar pequenas coisas que marcam época (objetos, costumes)

**VOCABULÁRIO:**
- Palavras suaves: "gentil", "singelo", "sutil", "delicado"
- Expressões temporais: "naqueles dias", "antigamente", "costumava"
- Verbos no imperfeito: "era", "tinha", "fazia", "lembrava"

**TÉCNICAS:**
- Digressões naturais (como alguém contando história oral)
- Comparações passado → presente
- Admitir falhas de memória: "Se não me engano...", "Creio que..."
- Tom de sabedoria adquirida com o tempo

**EXEMPLO DE NARRAÇÃO:**
"Eu me lembro... O cheiro do café coado na manhã, ainda quente na caneca de porcelana.
As mãos da minha avó, calejadas mas gentis, preparando o pão caseiro.
Naquela época, as coisas eram mais simples. Não tínhamos pressa.
O tempo... ah, o tempo parecia se mover de outra forma.
Hoje, quando sinto o aroma de café, sou transportada de volta àqueles dias..."

**EVITE:**
❌ Ação frenética ou tensão extrema
❌ Vocabulário técnico ou moderno demais
❌ Narrativa onisciente (manter ponto de vista pessoal)
❌ Tom jovial ou energia excessiva
❌ Certezas absolutas (memórias são fluidas)
''';
  }

  static String _getEpicoPeriodoStyle(ScriptConfig config) {
    final year = extractYear(config.localizacao);
    final anachronisms = getAnachronismList(year);
    final periodElements = getPeriodElements(year, config.genre);

    String anachronismSection = '';
    if (anachronisms.isNotEmpty) {
      anachronismSection = '''

**🚫 ANACRONISMOS A EVITAR (Não existiam em \$year):**
\${anachronisms.map((a) => '  ❌ \$a').join('\\n')}
''';
    }

    String periodSection = '';
    if (periodElements.isNotEmpty) {
      periodSection = '''

**✅ ELEMENTOS DO PERÍODO A INCLUIR (Existiam em \$year):**
\${periodElements.map((e) => '  ✓ \$e').join('\\n')}
''';
    }

    return '''
════════════════════════════════════════════════════════════════════════════════
🏰 ESTILO NARRATIVO: ÉPICO DE PERÍODO${year.isNotEmpty ? ' (Ano: $year)' : ''}
════════════════════════════════════════════════════════════════════════════════

**Tom:** Grandioso, formal, heroico, majestoso
**Ritmo:** Cadenciado e majestoso, com construção dramática
**Perspectiva:** Narrador que conhece a importância histórica dos eventos

**ESTRUTURA NARRATIVA:**
1. Descrições detalhadas e vívidas do período histórico
2. Diálogos formais e apropriados à época (sem gírias modernas)
3. Enfatizar valores, honra e códigos morais da época
4. Usar linguagem elevada mas compreensível
5. Construir tensão com descrições atmosféricas

**VOCABULÁRIO:**
- Palavras de peso: "honra", "destino", "coragem", "sacrifício"
- Descrições grandiosas: "sob o sol escaldante", "nas sombras da história"
- Evitar contrações: "não havia" em vez de "não tinha"

**TÉCNICAS:**
- Começar com estabelecimento de época e lugar
- Usar marcos históricos reais quando possível
- Descrever vestimentas, armas, tecnologia da época
- Criar senso de inevitabilidade histórica
- Pausas dramáticas antes de momentos cruciais$anachronismSection$periodSection

**EXEMPLO DE NARRAÇÃO:**
"${year.isNotEmpty ? 'No ano de $year' : 'Naquele tempo'}, sob o sol escaldante do Velho Oeste,
Jake ajustou o revólver no coldre de couro gasto. O duelo seria ao meio-dia.
A cidade inteira observava em silêncio das janelas empoeiradas,
sabendo que a justiça seria feita pela lei do mais rápido.
O vento quente soprava pela rua deserta, levantando nuvens de poeira vermelha.
Dois homens. Um código. Um destino."

**EVITE:**
❌ Anacronismos (tecnologias que não existiam na época)
❌ Gírias modernas ou linguagem informal
❌ Referências contemporâneas
❌ Tom humorístico ou irreverente
❌ Ritmo apressado (épico requer peso)
''';
  }

  static String _getEducativoCuriosoStyle() {
    return '''
════════════════════════════════════════════════════════════════════════════════
🎓 ESTILO NARRATIVO: EDUCATIVO (CURIOSIDADES)
════════════════════════════════════════════════════════════════════════════════

**Tom:** Entusiasta, acessível, didático, fascinante
**Ritmo:** Moderado, com pausas para absorção de conceitos
**Perspectiva:** Guia amigável que revela conhecimento surpreendente

**ESTRUTURA NARRATIVA (Framework de 4 Passos):**
1. **PERGUNTA INTRIGANTE:** Despertar curiosidade
2. **FATO SURPREENDENTE:** Resposta que causa "Uau!"
3. **EXPLICAÇÃO COM CONTEXTO:** Como/Por que funciona
4. **IMPACTO/APLICAÇÃO:** Por que isso importa

**FRASES-GATILHO (Use frequentemente):**
- "Você sabia que...?"
- "Mas aqui está o fascinante..."
- "E é por isso que..."
- "Isso explica por que..."
- "Surpreendentemente..."
- "O interessante é que..."
- "Aqui está a parte incrível..."

**TÉCNICAS DE ENGAJAMENTO:**
- Fazer perguntas retóricas para o espectador
- Usar analogias com coisas do cotidiano
- Comparações de escala (tamanho, tempo, distância)
- Fatos numéricos impressionantes
- Conexões inesperadas entre conceitos

**VOCABULÁRIO:**
- Palavras de descoberta: "revelador", "surpreendente", "fascinante"
- Verbos ativos: "descobrir", "revelar", "transformar", "conectar"
- Evitar jargão técnico SEM explicação simples

**EXEMPLO DE NARRAÇÃO:**
"Você sabia que o céu é azul por causa de um fenômeno chamado espalhamento de Rayleigh?

Mas aqui está o fascinante: quando a luz solar entra na atmosfera,
ela colide com moléculas minúsculas de ar. A luz é composta de diferentes cores,
cada uma com seu próprio comprimento de onda.

A luz azul tem ondas menores e mais curtas, então ela se espalha mais facilmente
ao colidir com as moléculas. É como jogar bolinhas de diferentes tamanhos
através de uma peneira - as menores ricocheteiam mais!

E é por isso que vemos azul durante o dia, mas laranja e vermelho no pôr do sol.
No final do dia, a luz precisa atravessar MUITO mais atmosfera,
então até as ondas maiores (vermelhas e laranjas) começam a se espalhar."

**EVITE:**
❌ Jargão técnico sem explicação
❌ Tom professoral ou autoritário ("vocês DEVEM saber...")
❌ Exemplos muito abstratos ou acadêmicos
❌ Informação sem contexto prático
❌ Monotonia (variar ritmo e entusiasmo)
''';
  }

  static String _getAcaoRapidaStyle() {
    return '''
════════════════════════════════════════════════════════════════════════════════
⚡ ESTILO NARRATIVO: AÇÃO RÁPIDA
════════════════════════════════════════════════════════════════════════════════

**Tom:** Urgente, intenso, visceral, adrenalina pura
**Ritmo:** FRENÉTICO - frases curtas e impactantes
**Perspectiva:** Imersão total no momento presente

**ESTRUTURA NARRATIVA:**
1. Frases CURTAS (5-10 palavras máximo)
2. Verbos de ação fortes e diretos
3. Tempo presente para imediatismo
4. Eliminação de adjetivos desnecessários
5. Foco em MOVIMENTO e IMPACTO

**TÉCNICA DE ESCRITA:**
- Cortar conjunções: "Jake corre. Pula. Rola." (não "Jake corre, pula e rola")
- Um verbo forte por frase
- Frases fragmentadas para urgência
- Pontuação agressiva: ponto final, não vírgula
- Onomatopeias quando apropriado: BAM! CRASH! BANG!

**VERBOS PREFERIDOS:**
- Movimento: corre, salta, mergulha, voa, derrapa
- Impacto: explode, estilhaça, rompe, perfura, esmaga
- Combate: ataca, esquiva, bloqueia, contra-ataca, elimina

**EXEMPLO DE NARRAÇÃO:**
"O tiro ecoa. Jake rola. Esquiva.
Vidro explode atrás dele. CRASH!
Levanta. Corre. Três passos.
Mira. Dispara. BAM!
O oponente cambaleia. Cai.
Silêncio.
Vitória."

**TÉCNICAS AVANÇADAS:**
- Frases de uma palavra para picos: "Agora." "Fogo!" "Corre!"
- Eliminar artigos: "Bala rasga ar" (não "A bala rasga o ar")
- Usar presente simples: "Ele ataca" (não "Ele está atacando")
- Staccato verbal: ritmo de metralhadora

**ESTRUTURA DE CENA DE AÇÃO:**
1. Estabelecer perigo (2 frases)
2. Reação instintiva (3-4 frases ultra-curtas)
3. Escalada (mais movimento, mais perigo)
4. Clímax (1-2 frases de impacto)
5. Resolução (1 frase de alívio)

**EVITE:**
❌ Descrições longas de cenário
❌ Reflexões filosóficas ou emocionais
❌ Diálogos extensos (máximo 3-4 palavras)
❌ Adjetivos múltiplos ("a bela e majestosa espada" → "a espada")
❌ Subordinadas complexas
❌ Explicações de motivação (ação pura)
''';
  }

  static String _getLiricoPoeticoStyle() {
    return '''
════════════════════════════════════════════════════════════════════════════════
🌸 ESTILO NARRATIVO: LÍRICO POÉTICO
════════════════════════════════════════════════════════════════════════════════

**Tom:** Melancólico, suave, contemplativo, etéreo
**Ritmo:** Cadenciado e musical, quase como versos livres
**Perspectiva:** Olhar artístico que transforma realidade em poesia

**ESTRUTURA NARRATIVA:**
1. Imagens sensoriais ricas e sinestésicas
2. Metáforas da natureza e elementos
3. Ritmo quase musical (atenção à sonoridade)
4. Simbolismo em vez de descrição direta
5. Repetições para ênfase emocional

**RECURSOS POÉTICOS:**

**Metáforas:**
- Comparar emoções com natureza: "dor como tempestade", "alegria como aurora"
- Personificar elementos: "o vento sussurra", "a noite abraça"
- Transformar concreto em abstrato: "olhos eram janelas de alma"

**Sinestesia (Misturar Sentidos):**
- "Som aveludado da voz"
- "Silêncio pesado"
- "Luz quente das palavras"
- "Sabor amargo da saudade"

**Aliteração e Assonância:**
- "Suave som do silêncio sussurra"
- "Lua lânguida lamenta"
- Atenção ao ritmo das palavras

**VOCABULÁRIO:**
- Palavras suaves: "etéreo", "efêmero", "sublime", "tênue"
- Natureza: "aurora", "crepúsculo", "orvalho", "brisa"
- Emoção profunda: "melancolia", "nostalgia", "anseio", "enlevo"

**EXEMPLO DE NARRAÇÃO:**
"A lua, pálida testemunha da noite eterna,
derramava sua luz prateada sobre os campos adormecidos.
O vento, esse mensageiro de segredos antigos,
sussurrava entre as folhas trementes das árvores.

E o tempo, esse eterno viajante sem repouso,
seguia seu curso inexorável,
levando consigo os momentos como pétalas ao vento,
enquanto as estrelas bordavam seus poemas silenciosos
no vasto manto azul do infinito."

**TÉCNICAS AVANÇADAS:**
- Repetição para ênfase: "Esperava. Sempre esperava. Como se esperar fosse seu destino."
- Frases longas e fluidas (contrário da ação rápida)
- Usar vírgulas para criar ritmo de respiração
- Imagens visuais como pinturas
- Deixar espaço para interpretação (não explicar tudo)

**ESTRUTURA EMOCIONAL:**
- Começar com imagem sensorial
- Construir camadas de significado
- Clímax emocional (não de ação)
- Resolução contemplativa ou em aberto

**EVITE:**
❌ Linguagem técnica ou prosaica
❌ Ação frenética ou violência explícita
❌ Diálogos diretos e funcionais
❌ Explicações literais
❌ Ritmo apressado ou urgente
❌ Jargão ou coloquialismo
''';
  }

  static String _getFiccionalLivreStyle() {
    return '''
════════════════════════════════════════════════════════════════════════════════
📖 ESTILO NARRATIVO: FICÇÃO LIVRE (SEM RESTRIÇÕES)
════════════════════════════════════════════════════════════════════════════════

**Tom:** Flexível - adapta-se ao tema e gênero
**Ritmo:** Balanceado - varia conforme necessidade
**Perspectiva:** Liberdade criativa total

**ORIENTAÇÕES GERAIS:**
✓ Misturar estilos conforme necessário (ação + reflexão + descrição)
✓ Adaptar tom ao tema escolhido (drama, comédia, suspense, etc.)
✓ Usar técnicas narrativas variadas
✓ Focar em contar uma boa história sem restrições formais
✓ Priorizar engajamento e fluidez

**ESTRUTURA SUGERIDA:**
1. Estabelecimento (contexto e personagens)
2. Desenvolvimento (conflito e progressão)
3. Clímax (momento de maior tensão)
4. Resolução (desfecho satisfatório)

**FLEXIBILIDADE:**
- Pode usar diálogos extensos ou ausentes
- Pode alternar entre ação e contemplação
- Pode misturar tempos verbais se necessário
- Pode variar entre formal e coloquial

**DICA:** Use os elementos dos outros estilos conforme a cena:
- Momentos intensos? Técnicas de "Ação Rápida"
- Momentos emotivos? Toques de "Lírico Poético"
- Flashbacks? Elementos de "Reflexivo Memórias"
- Período histórico? Cuidado com anacronismos do "Épico"
- Explicar algo? Clareza do "Educativo"
''';
  }
}
