import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/data/models/generation_config.dart';
import 'package:flutter_gerador/data/services/gemini_service.dart';
import 'package:flutter_gerador/data/services/srt_service.dart';
import 'script_generation_provider.dart'; // Para acessar defaultGeminiServiceProvider

class ExtraToolsNotifier extends StateNotifier<ExtraToolsState> {
  final GeminiService _geminiService;

  ExtraToolsNotifier(this._geminiService) : super(const ExtraToolsState());

  // Helper para converter nomes de idiomas para códigos de tags
  String _getLanguageTag(String language) {
    switch (language.toLowerCase()) {
      case 'português':
        return 'portuguese';
      case 'inglês':
        return 'english';
      case 'espanhol(mexicano)':
        return 'spanish';
      case 'francês':
        return 'french';
      case 'alemão':
        return 'german';
      case 'italiano':
        return 'italian';
      case 'polonês':
        return 'polish';
      case 'búlgaro':
        return 'bulgarian';
      case 'russo':
        return 'russian';
      case 'croata':
        return 'croatian';
      case 'turco':
        return 'turkish';
      case 'romeno':
        return 'romanian';
      default:
        return 'multilingual';
    }
  }

  // 🔄 Método para invalidar SRT quando texto do roteiro for editado
  void invalidateSrtIfTextChanged(String currentScriptText) {
    // Verificação mais robusta
    final hasGeneratedSrt = state.generatedSRT != null;
    final hasSourceText = state.srtSourceText != null;
    final textChanged = state.srtSourceText != currentScriptText;

    print('🔍 Verificando validade do SRT:');
    print('  - Tem SRT gerado: $hasGeneratedSrt');
    print('  - Tem texto fonte: $hasSourceText');
    print('  - Texto mudou: $textChanged');
    print('  - SRT atual válido: ${state.isSrtValid}');

    if (hasGeneratedSrt && textChanged) {
      print('🔄 SRT invalidado: texto do roteiro foi editado');
      print('  - Texto antigo: ${state.srtSourceText?.length ?? 0} chars');
      print('  - Texto novo: ${currentScriptText.length} chars');

      state = state.copyWith(
        isSrtValid: false,
        srtError: 'SRT precisa ser atualizado - roteiro foi editado',
      );
    }
  }

  // 🔄 Método para auto-regenerar SRT se necessário
  Future<String?> autoRegenerateSrtIfNeeded(
    GenerationConfig config,
    String currentScriptText,
  ) async {
    // Se não há SRT ou não é válido, regenera automaticamente
    if (state.generatedSRT == null || !state.isSrtValid) {
      print('🔄 Auto-regenerando SRT...');
      try {
        return await generateSRTSubtitles(config, currentScriptText);
      } catch (e) {
        print('❌ Erro na auto-regeneração do SRT: $e');
        return null;
      }
    }
    return state.generatedSRT;
  }

  Future<String> generateSRTSubtitles(
    GenerationConfig config,
    String scriptText,
  ) async {
    // 🔄 Verificar se o texto mudou e forçar regeneração
    final shouldRegenerate =
        state.srtSourceText != scriptText || !state.isSrtValid;

    print('🔄 generateSRTSubtitles chamado:');
    print('  - Texto atual: ${scriptText.length} caracteres');
    print(
      '  - Texto fonte SRT: ${state.srtSourceText?.length ?? 0} caracteres',
    );
    print('  - SRT válido: ${state.isSrtValid}');
    print('  - Deve regenerar: $shouldRegenerate');

    // 🔄 SEMPRE limpar SRT anterior para garantir regeneração com texto atual
    state = state.copyWith(
      isGeneratingSRT: true,
      srtError: null,
      generatedSRT: null, // ✅ Limpa SRT anterior
      isSrtValid: false, // ✅ Marca como inválido durante geração
    );

    try {
      // Configurações específicas para CapCut baseadas na imagem
      final srtContent = SrtService.generateSrt(
        scriptText,
        wordsPerMinute: 120, // Mais lento para não encavalar
        maxCharactersPerSubtitle:
            500, // Máximo de caracteres por bloco (CapCut)
        maxLinesPerSubtitle: 3, // Permitir até 3 linhas
        minDisplayTime: 2.0, // Duração mínima por bloco (30 palavras ÷ 15 = 2s)
        maxDisplayTime:
            8.0, // Duração máxima por bloco (100 palavras ÷ 12.5 = 8s)
        gapBetweenSubtitles: 1.0, // Intervalo de 1 segundo entre blocos
        minWordsPerBlock: 30, // Mínimo de palavras por bloco
        maxWordsPerBlock: 100, // Máximo de palavras por bloco
        blockDurationSeconds: 30, // Duração base de 30 segundos por bloco
        intervalBetweenBlocks: 20, // Intervalo de 20 segundos entre blocos
      );

      state = state.copyWith(
        isGeneratingSRT: false,
        generatedSRT: srtContent,
        // 🔄 Marca como válido e salva texto fonte
        srtSourceText: scriptText,
        isSrtValid: true,
      );

      return srtContent;
    } catch (e) {
      state = state.copyWith(
        isGeneratingSRT: false,
        srtError: 'Erro ao gerar SRT: ${e.toString()}',
        generatedSRT: null, // ✅ Garante que não fica com SRT inválido
        isSrtValid: false,
      );
      rethrow;
    }
  }

  Future<String> generateYouTubeDescription(
    GenerationConfig config,
    String scriptText,
  ) async {
    print('🎬 ExtraTools: Iniciando geração YouTube Description');
    print(
      '  📋 Config: ${config.title}, ${config.language}, API Key: ${config.apiKey.isNotEmpty ? "Present" : "Missing"}',
    );
    print('  📝 Script length: ${scriptText.length} chars');

    state = state.copyWith(isGeneratingYouTube: true, youtubeError: null);

    try {
      print('🏷️ Gerando language tag para: ${config.language}');
      final languageTag = _getLanguageTag(config.language);
      print('✅ Language tag gerada: $languageTag');

      final youtubePrompt =
          '''
Com base no seguinte roteiro, crie uma descrição otimizada para YouTube que maximize o engajamento:

**Título:** ${config.title}
**Roteiro:**
$scriptText

**INSTRUÇÕES ESPECÍFICAS:**

1. **DESCRIÇÃO DO VÍDEO** (400-500 caracteres):
   - Crie um resumo cativante que desperte curiosidade sem entregar o final
   - Use linguagem envolvente e emocional que conecte com o público
   - Inclua um hook forte no início para prender a atenção
   - Destaque os elementos mais interessantes/chocantes da história
   - Termine com uma pergunta ou convite à reflexão

2. **TAGS ESTRATÉGICAS** (separadas por vírgula, SEM hashtag #):
   - Gênero da história (ex: mistério, drama, horror, comédia)
   - Elementos narrativos (ex: storytelling, história verdadeira, ficção)
   - Perfil do protagonista (ex: mulher idosa, jovem, vingança)
   - Temas universais (ex: família, justiça, amor, traição)
   - Idioma: $languageTag
   - Palavras-chave específicas do roteiro

3. **ADAPTAÇÃO COMPLETA PARA ${config.language}**

**FORMATO OBRIGATÓRIO:**

🎬 **SOBRE O VÍDEO**
[Descrição de 400-500 caracteres com hook forte, resumo envolvente e pergunta final para engajamento]

📱 **TAGS SUGERIDAS**
[15-20 tags relevantes separadas por VÍRGULA, sem hashtag #. Exemplo: mistério, drama, vingança, família, storytelling, $languageTag]

**DIRETRIZES DE QUALIDADE:**
- Seja específico, não genérico
- Use palavras que geram emoção
- Inclua elementos de suspense sem spoilers
- Adapte completamente para ${config.language}
- Foque na experiência emocional que o vídeo oferece
- ❌ NÃO use hashtag # nas tags
- ✅ Separe as tags com vírgula: tag1, tag2, tag3
''';

      print('📤 Enviando para Gemini (Flash fixo)...');
      final response = await _geminiService.generateTextWithApiKey(
        prompt: youtubePrompt,
        apiKey: config.apiKey,
        model: 'gemini-2.5-flash', // 🚀 v7.6.60: Sempre Flash para ferramentas extras (independente do modo)
      );

      print('✅ Resposta recebida do Gemini');
      print('📊 Response length: ${response.length} chars');

      state = state.copyWith(
        isGeneratingYouTube: false,
        generatedYouTube: response,
      );

      return response;
    } catch (e) {
      print('❌ ERRO na geração YouTube: $e');
      state = state.copyWith(
        isGeneratingYouTube: false,
        youtubeError: 'Erro ao gerar descrição: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<String> generateProtagonistPrompt(
    GenerationConfig config,
    String scriptText,
  ) async {
    state = state.copyWith(isGeneratingPrompts: true, promptsError: null);

    try {
      // CORREÇÃO: Usar instância injetada em vez de criar nova
      // final geminiService = GeminiService(instanceId: 'midjourney_tools'); // <- VAZAMENTO!

      final protagonistPrompt =
          '''
Com base no seguinte roteiro, analise profundamente o protagonista e gere 4 PROMPTS COMPLETOS em inglês para criar imagens consistentes do protagonista no Midjourney:

**Título:** ${config.title}
**Roteiro:**
$scriptText

**⚠️ VALIDAÇÃO RIGOROSA DE NOME DO PROTAGONISTA (v7.6.15):**

Antes de gerar os prompts, execute verificação COMPLETA:

1. **EXTRAIR TODOS OS NOMES DO PROTAGONISTA:**
   - Liste CADA variação de nome que aparece
   - Conte frequência de cada variação
   - Exemplos: "Dr. Miller" (5x), "Dr. Thompson" (3x), "Claire Wallace" (12x)

2. **DETECTAR INCONSISTÊNCIAS:**
   - Se mesmo personagem tem nomes diferentes = ERRO DO ROTEIRO
   - **AÇÃO:** Escolha o nome que aparece PRIMEIRO ou é mais COMPLETO
   - Documente a escolha na seção de validação

3. **ESCOLHER NOME DEFINITIVO:**
   - UM nome único para usar nos 4 prompts
   - Preferencialmente: nome completo (primeiro + sobrenome)
   - Se houver título profissional (Dr., Captain), use apenas o nome pessoal nos prompts Midjourney
   - Exemplo: "Dr. Claire Wallace" → use "Claire Wallace" nas imagens

4. **DOCUMENTAR CORREÇÃO:**
   - Se houve múltiplas variações, explique qual escolheu e por quê
   - Se nome era consistente, confirme isso

**ANÁLISE OBRIGATÓRIA DO PROTAGONISTA:**

1️⃣ **CARACTERÍSTICAS FÍSICAS FIXAS** (devem ser IDÊNTICAS nos 4 prompts):
   - Nome completo validado
   - Idade aproximada
   - Tipo físico (altura, peso, compleição)
   - Cor e estilo de cabelo
   - Cor dos olhos
   - Formato do rosto
   - Características marcantes (barba, óculos, cicatrizes, tatuagens, etc.)
   - Tom de pele
   
   ${_getEthnicityInstructionForImagePrompts(config.language)}
   
   ${_getAgeInstructionForImagePrompts(config.perspective)}

2️⃣ **PERSONALIDADE E CONTEXTO:**
   - Profissão/ocupação
   - Classe social
   - Traços de personalidade principais
   - Momento da história (início, meio, fim)

3️⃣ **CENÁRIO E ATMOSFERA:**
   - Localização principal do roteiro
   - Época/período
   - Clima/atmosfera da história

**GERE EXATAMENTE 4 PROMPTS DIFERENTES:**

🔹 **PROMPT 1: INÍCIO DA HISTÓRIA**
- Protagonista em situação do INÍCIO do roteiro
- Expressão/emoção do começo da jornada
- Roupas e contexto do início
- Cenário de fundo relacionado ao setup inicial
- Mantém características físicas fixas

🔹 **PROMPT 2: MOMENTO DE TENSÃO/CONFLITO**
- Protagonista no MEIO da história
- Expressão de tensão, dúvida ou luta
- Possivelmente roupa diferente (se mudou no roteiro)
- Cenário de fundo do conflito principal
- Mantém características físicas fixas

🔹 **PROMPT 3: CLÍMAX/DESCOBERTA**
- Protagonista no momento crucial
- Expressão de revelação, choque ou determinação
- Contexto visual do momento decisivo
- Cenário dramático do clímax
- Mantém características físicas fixas

🔹 **PROMPT 4: RESOLUÇÃO/FINAL**
- Protagonista após a jornada
- Expressão do estado final (vitória, paz, transformação)
- Roupas/estilo final (pode ter mudado)
- Cenário do desfecho
- Mantém características físicas fixas

**REGRAS CRÍTICAS:**

✅ **CONSISTÊNCIA DE NOME (v7.6.15 - VALIDAÇÃO RIGOROSA):**
- O protagonista deve ter APENAS UM NOME usado nos 4 prompts
- **ZERO TOLERÂNCIA** para mudanças de nome entre prompts
- Se roteiro tem inconsistências (Miller → Thompson → Wallace), escolha UM e documente
- **FORMATO:** Use nome pessoal completo, SEM títulos profissionais
- Exemplo: "Dr. Claire Wallace" → use "Claire Wallace" nos prompts
- Informe na seção "VALIDAÇÃO DE NOME" qual escolheu e por quê

✅ **CONSISTÊNCIA VISUAL ABSOLUTA:**
- As características físicas (idade, cabelo, olhos, rosto, pele) devem ser EXATAMENTE IGUAIS nos 4 prompts
- Use as MESMAS palavras descritivas para traços físicos fixos
- Exemplo: Se é "30-year-old man, short brown hair, green eyes, square jaw" no Prompt 1, deve ser EXATAMENTE igual nos outros 3

✅ **O QUE PODE MUDAR:**
- Expressão facial (conforme momento da história)
- Roupas (se mudou no roteiro)
- Postura corporal
- Cenário de fundo
- Iluminação/atmosfera

✅ **FORMATO DE CADA PROMPT:**
"[características físicas fixas], [expressão facial], [roupas específicas], [postura], [cenário de fundo detalhado], [atmosfera/mood], cinematic lighting, photorealistic, high detail, 8k, professional photography, --ar 2:3 --v 6"

✅ **ASPECTOS TÉCNICOS:**
- Sempre "from waist up" ou "upper body portrait"
- Sempre "facing camera" ou ângulo apropriado
- Incluir "cinematic lighting, photorealistic"
- Adicionar "--ar 2:3 --v 6" ao final

**FORMATO DE SAÍDA:**

Gere a resposta EXATAMENTE neste formato:

═══════════════════════════════════════════
🔍 VALIDAÇÃO DE NOME DO PROTAGONISTA (v7.6.15):
═══════════════════════════════════════════
**NOMES ENCONTRADOS NO ROTEIRO:**
[Liste todas as variações com frequência]
Exemplo:
- "Dr. Miller": 5 aparições
- "Dr. Thompson": 3 aparições  
- "Claire Wallace": 12 aparições
- "Dr. Wallace": 8 aparições

**NOME ESCOLHIDO PARA OS PROMPTS:** [Nome definitivo]

**JUSTIFICATIVA:**
[Explique a escolha se houve inconsistências]
Exemplo: "O roteiro usa três variações. Escolhi 'Claire Wallace' (nome completo) por ser o mais usado (12x) e o mais completo. Títulos profissionais ('Dr.') foram removidos para prompts Midjourney."

OU se foi consistente:
"Nome consistente no roteiro. Nenhuma correção necessária."

═══════════════════════════════════════════
📋 CARACTERÍSTICAS FIXAS DO PROTAGONISTA:
═══════════════════════════════════════════
[Descreva em português as características que serão mantidas, incluindo o nome validado acima]

═══════════════════════════════════════════
🎬 PROMPT 1 - INÍCIO DA HISTÓRIA:
═══════════════════════════════════════════
[Prompt completo em inglês]

═══════════════════════════════════════════
⚡ PROMPT 2 - MOMENTO DE TENSÃO:
═══════════════════════════════════════════
[Prompt completo em inglês]

═══════════════════════════════════════════
💥 PROMPT 3 - CLÍMAX/DESCOBERTA:
═══════════════════════════════════════════
[Prompt completo em inglês]

═══════════════════════════════════════════
🏆 PROMPT 4 - RESOLUÇÃO/FINAL:
═══════════════════════════════════════════
[Prompt completo em inglês]

═══════════════════════════════════════════
💡 DICAS DE USO:
═══════════════════════════════════════════
- Use seed fixo no Midjourney para maior consistência
- Ajuste weight dos elementos conforme necessário
- Considere usar image prompts da Imagem 1 para gerar 2, 3 e 4

**IMPORTANTE:** Cada prompt deve ser completo e funcional por si só, pronto para colar diretamente no Midjourney!
''';

      final result = await _geminiService.generateTextWithApiKey(
        prompt: protagonistPrompt,
        apiKey: config.apiKey,
        model: 'gemini-2.5-flash', // 🚀 v7.6.60: Sempre Flash para ferramentas extras (independente do modo)
      );

      state = state.copyWith(
        isGeneratingPrompts: false,
        generatedPrompts: result,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        isGeneratingPrompts: false,
        promptsError: 'Erro ao gerar prompt do protagonista: ${e.toString()}',
      );
      rethrow;
    }
  }

  // 🎬 v7.6.13: NOVA FERRAMENTA - PROMPT CENAS PRINCIPAIS
  // Substitui o antigo "generateScenarioPrompt" (clímax único)
  // Agora gera 4 CENAS CINEMATOGRÁFICAS completas com múltiplos personagens
  Future<String> generateKeyScenes(
    GenerationConfig config,
    String scriptText,
  ) async {
    print('🎬 ExtraTools: Iniciando geração CENAS PRINCIPAIS (v7.6.13)');
    print(
      '  📋 Config: ${config.title}, ${config.language}, API Key: ${config.apiKey.isNotEmpty ? "Present" : "Missing"}',
    );
    print('  📝 Script length: ${scriptText.length} chars');

    state = state.copyWith(isGeneratingScenario: true, scenarioError: null);

    try {
      final keyScenesPrompt =
          '''
Com base no seguinte roteiro, analise profundamente e gere 4 PROMPTS COMPLETOS em inglês para criar CENAS CINEMATOGRÁFICAS PRINCIPAIS no Midjourney:

**Título:** ${config.title}
**Roteiro:**
$scriptText

**OBJETIVO:**
Escolher as 4 CENAS MAIS IMPACTANTES e VISUALMENTE MARCANTES da história, onde o protagonista interage com outros personagens em momentos decisivos.

**CRITÉRIOS PARA SELEÇÃO DAS CENAS:**

✅ **Priorize cenas COM MÚLTIPLOS PERSONAGENS:**
   - Mínimo: Protagonista + 1 personagem secundário
   - Máximo: Até 4 personagens (ideal para Midjourney)
   - Cenas de diálogo, confronto, revelação, decisão importante

✅ **Escolha momentos VISUALMENTE DRAMÁTICOS:**
   - Cenas com ação, tensão emocional, revelações importantes
   - Evite cenas estáticas ou monólogos internos
   - Prefira locais interessantes e memoráveis

✅ **Distribua ao longo da narrativa:**
   - Cena 1: Momento importante do INÍCIO
   - Cena 2: Momento crucial do DESENVOLVIMENTO/CONFLITO
   - Cena 3: Momento decisivo do CLÍMAX
   - Cena 4: Momento emocional da RESOLUÇÃO

**⚠️ REGRAS CRÍTICAS - VALIDAÇÃO OBRIGATÓRIA DE NOMES (v7.6.15):**

Antes de gerar os prompts, você DEVE executar estas verificações:

1. **EXTRAIR TODOS OS NOMES:**
   - Liste CADA nome próprio que aparece no roteiro
   - Inclua primeiros nomes, sobrenomes, apelidos, títulos (Dr., Captain, etc.)
   - Marque quantas vezes cada nome aparece

2. **DETECTAR NOMES DUPLICADOS:**
   - ⚠️ ERRO CRÍTICO: Se DOIS PERSONAGENS DIFERENTES têm o MESMO NOME
   - Exemplo: "Kenneth" (capitão vilão) e "Kenneth" (cirurgião herói) = INACEITÁVEL
   - **AÇÃO:** Renomeie o personagem secundário para nome DIFERENTE
   - Escolha nome que combine com período/contexto (Marcus, William, Richard, Samuel, etc.)

3. **DETECTAR MUDANÇAS DE NOME (MESMO PERSONAGEM):**
   - ⚠️ INCONSISTÊNCIA: Protagonista muda de "Dr. Miller" → "Dr. Thompson" → "Dr. Wallace"
   - **AÇÃO:** Escolha UM nome (preferencialmente o primeiro ou mais completo)
   - Use APENAS esse nome em todas as 4 cenas

4. **VALIDAR PERSONAGENS SECUNDÁRIOS:**
   - Se personagem aparece SEM INTRODUÇÃO (ex: "Kenneth, the ship's old surgeon" do nada)
   - **AÇÃO:** Mencione na seção de validação que personagem não foi introduzido adequadamente
   - Use mesmo assim, mas alerte sobre problema no roteiro original

5. **CRIAR TABELA DE NOMES ÚNICOS:**
   - Liste TODOS os personagens com EXATAMENTE UM NOME cada
   - Se roteiro tinha duplicatas/inconsistências, documente correções feitas

**ANÁLISE OBRIGATÓRIA PARA CADA CENA:**

1️⃣ **PERSONAGENS NA CENA:**
   - Protagonista: Características físicas (idade, tipo físico, cabelo, olhos, rosto, pele, etnia)
   - Personagens secundários: Descrição física de CADA um (nome, idade aproximada, aparência, roupa)
   - Expressões faciais de cada personagem
   - Posicionamento espacial (quem está onde, como interagem)
   - ⚠️ **IMPORTANTE:** Use SEMPRE o mesmo nome para o mesmo personagem em todas as cenas
   
   ${_getEthnicityInstructionForImagePrompts(config.language)}

2️⃣ **CENÁRIO DA CENA:**
   - Localização específica (sala, rua, floresta, escritório, etc.)
   - Período/época (1716, anos 80, contemporâneo, futuro)
   - Elementos visuais marcantes (objetos, móveis, decoração)
   - Atmosfera/clima (tenso, nostálgico, dramático, esperançoso)

3️⃣ **ILUMINAÇÃO E COMPOSIÇÃO:**
   - Hora do dia (amanhecer, meio-dia, entardecer, noite)
   - Tipo de luz (natural, artificial, fogo, lua, velas)
   - Clima/atmosfera (nevoeiro, chuva, sol forte, sombras)

**FORMATO DE CADA PROMPT:**

"Wide shot, [descrição da ação da cena]. [Protagonista: nome, idade, etnia, características físicas, expressão, roupa], [Personagem 2: nome, idade, características, expressão, roupa], [Personagem 3 se houver...]. [Descrição detalhada do cenário, localização, período histórico]. [Elementos visuais importantes]. [Atmosfera, iluminação, clima]. Photorealistic, natural lighting, high detail, 8k, professional photography, --ar 16:9 --v 6"

**EXEMPLO DE PROMPT CORRETO:**

"Wide shot, dramatic escape scene in dark swamp at night. William, a young Black man in his 20s with desperate expression, worn slave clothing, running alongside Blake, a weathered white pirate in his 40s with grey eyes and determined look, torn dark shirt. Both waist-deep in murky black water, pushing through hanging spanish moss from ancient cypress trees. Distant torchlight and barking dogs behind them creating urgency. Atmospheric fog, moonlight filtering through dense canopy. Photorealistic, natural lighting, high detail, 8k, professional photography, --ar 16:9 --v 6"

**REGRAS CRÍTICAS:**

✅ **CONSISTÊNCIA DE NOMES (v7.6.15 - VALIDAÇÃO RIGOROSA):**
   - **ZERO TOLERÂNCIA para nomes duplicados:** Se dois personagens diferentes têm mesmo nome, RENOMEIE um deles
   - **ZERO TOLERÂNCIA para mudanças de nome:** Um personagem = UM nome em todas as cenas
   - Se roteiro tem "Kenneth" (vilão) e "Kenneth" (herói), renomeie um para "Marcus", "William", etc.
   - Se protagonista muda "Miller" → "Thompson" → "Wallace", escolha UM e mantenha
   - **DOCUMENTE** todas as correções na seção "VALIDAÇÃO DE NOMES"
   - Preferência: use o nome que aparece PRIMEIRO no roteiro, ou o mais COMPLETO

✅ **DETECÇÃO DE PERSONAGENS NÃO INTRODUZIDOS:**
   - Se personagem aparece tarde sem introdução (ex: "Kenneth, the surgeon" do nada)
   - **ALERTE** na validação: "⚠️ Personagem 'Kenneth (cirurgião)' aparece sem introdução prévia no roteiro"
   - Use mesmo assim nas cenas, mas documente o problema

✅ **CONSISTÊNCIA FÍSICA DOS PERSONAGENS:**
   - Características físicas do protagonista devem ser IDÊNTICAS nas 4 cenas
   - Personagens secundários que aparecem em múltiplas cenas devem manter consistência
   - Use as MESMAS palavras descritivas para cada personagem

❌ **EVITE:**
   - Cenas com protagonista completamente sozinho (sem interação)
   - Monólogos internos ou cenas muito estáticas
   - Mais de 4 personagens em uma cena (Midjourney tem dificuldade)
   - Cenas muito similares entre si

✅ **ASPECTOS TÉCNICOS OBRIGATÓRIOS:**
   - Sempre "Wide shot" no início (NÃO usar "Cinematic")
   - Sempre "Photorealistic, natural lighting, high detail, 8k, professional photography"
   - Sempre "--ar 16:9 --v 6" ao final
   - Descrição em inglês fluente e natural
   - ❌ NÃO usar: "cinematic lighting", "cinematography", "cinematic" (ficam artificiais)
   - ✅ USAR: "photorealistic", "natural lighting", "professional photography"

**FORMATO DE SAÍDA:**

Gere a resposta EXATAMENTE neste formato:

═══════════════════════════════════════════
📋 VALIDAÇÃO DE NOMES E PERSONAGENS (v7.6.15):
═══════════════════════════════════════════
**NOMES ENCONTRADOS NO ROTEIRO ORIGINAL:**
[Liste CADA nome que aparece, com frequência]
Exemplo:
- Kenneth: 15 vezes (capitão do Providence)
- Kenneth: 3 vezes (cirurgião do navio) ← ⚠️ NOME DUPLICADO DETECTADO
- Kenneth: 1 vez (príncipe morto mencionado) ← ⚠️ NOME DUPLICADO DETECTADO
- Arthur: 42 vezes (protagonista)
- Elizabeth: 28 vezes (princesa)

**CORREÇÕES APLICADAS:**
[Se houver duplicatas ou inconsistências, explique correções]
Exemplo:
✅ Kenneth (capitão vilão) → RENOMEADO para "Marcus" (evitar confusão)
✅ Kenneth (cirurgião) → RENOMEADO para "William" (evitar confusão)
✅ Kenneth (príncipe morto) → MANTIDO como "Kenneth" (personagem morto, menos confuso)

OU se houver mudanças de nome do mesmo personagem:
✅ Protagonista: "Dr. Miller" / "Dr. Thompson" / "Dr. Wallace" → ESCOLHIDO "Dr. Wallace" (nome completo mais usado)

**ALERTAS DE PROBLEMAS NO ROTEIRO:**
[Liste problemas estruturais detectados]
Exemplo:
⚠️ Personagem "William (cirurgião)" aparece sem introdução prévia no roteiro
⚠️ Personagem "Grant" desaparece sem resolução após confronto

═══════════════════════════════════════════
📋 PERSONAGENS PRINCIPAIS DA HISTÓRIA:
═══════════════════════════════════════════
[Liste protagonista + personagens secundários importantes com descrição física de cada um usando os nomes validados acima]

═══════════════════════════════════════════
🎬 CENA 1 - [NOME/DESCRIÇÃO DA CENA]:
═══════════════════════════════════════════
[Prompt completo em inglês - wide shot cinematográfico]

═══════════════════════════════════════════
🎬 CENA 2 - [NOME/DESCRIÇÃO DA CENA]:
═══════════════════════════════════════════
[Prompt completo em inglês - wide shot cinematográfico]

═══════════════════════════════════════════
🎬 CENA 3 - [NOME/DESCRIÇÃO DA CENA]:
═══════════════════════════════════════════
[Prompt completo em inglês - wide shot cinematográfico]

═══════════════════════════════════════════
🎬 CENA 4 - [NOME/DESCRIÇÃO DA CENA]:
═══════════════════════════════════════════
[Prompt completo em inglês - wide shot cinematográfico]

═══════════════════════════════════════════
💡 DICAS DE USO:
═══════════════════════════════════════════
- Use seed fixo no Midjourney para maior consistência entre personagens
- Para personagens recorrentes, use image prompts da primeira aparição
- Ajuste weights se algum personagem estiver dominando demais: [nome]::1.5
- Formato 16:9 é ideal para impressão em pôsteres ou uso em vídeos

**IMPORTANTE:** Cada prompt deve ser PHOTOREALISTIC (não cinematográfico artificial), com iluminação natural, pronto para colar diretamente no Midjourney!
''';

      print('📤 Enviando key scenes prompts para Gemini (Flash fixo)...');
      final result = await _geminiService.generateTextWithApiKey(
        prompt: keyScenesPrompt,
        apiKey: config.apiKey,
        model: 'gemini-2.5-flash', // 🚀 v7.6.60: Sempre Flash para ferramentas extras (independente do modo)
      );

      print('✅ Resposta key scenes recebida do Gemini');
      print('📊 Result length: ${result.length} chars');

      state = state.copyWith(
        isGeneratingScenario: false,
        generatedScenario: result,
      );

      return result;
    } catch (e) {
      print('❌ ERRO na geração Key Scenes: $e');
      state = state.copyWith(
        isGeneratingScenario: false,
        scenarioError:
            'Erro ao gerar prompts das cenas principais: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<String> generateAdvancedPrompts(
    GenerationConfig config,
    String scriptText,
  ) async {
    state = state.copyWith(isGeneratingPrompts: true, promptsError: null);

    try {
      // CORREÇÃO: Usar instância injetada em vez de criar nova
      // final geminiService = GeminiService(instanceId: 'extra_tools'); // <- VAZAMENTO!

      final promptsTemplate =
          '''
Com base no seguinte roteiro, crie uma coleção de prompts criativos:

**Título:** ${config.title}
**Roteiro:**
$scriptText

Gere os seguintes prompts temáticos:

🎨 **PROMPTS PARA IMAGENS (5 cenas principais)**
1. [Cena de abertura]
2. [Momento de tensão]
3. [Clímax]
4. [Resolução]
5. [Cena final]

🎵 **PROMPT PARA MÚSICA/TRILHA SONORA**
[Descrição do estilo musical, instrumentos, mood]

🎬 **PROMPT PARA STORYBOARD**
[Descrição de enquadramentos, ângulos de câmera, composição visual]

📱 **PROMPTS PARA REDES SOCIAIS**
• Instagram Post: [Descrição para post]
• TikTok/Shorts: [Versão condensada]
• Twitter Thread: [Sequência de tweets]

🎮 **PROMPT PARA VERSÃO INTERATIVA**
[Como adaptar para formato interativo/jogo]

📚 **PROMPT PARA EXPANDIR EM SÉRIE**
[Como desenvolver em múltiplos episódios]

Responda em ${config.language} com prompts detalhados e criativos.
''';

      final response = await _geminiService.generateTextWithApiKey(
        prompt: promptsTemplate,
        apiKey: config.apiKey,
        model: 'gemini-2.5-flash', // 🚀 v7.6.60: Sempre Flash para ferramentas extras (independente do modo)
      );

      state = state.copyWith(
        isGeneratingPrompts: false,
        generatedPrompts: response,
      );

      return response;
    } catch (e) {
      state = state.copyWith(
        isGeneratingPrompts: false,
        promptsError: 'Erro ao gerar prompts: ${e.toString()}',
      );
      rethrow;
    }
  }

  void clearSRT() {
    state = state.copyWith(
      generatedSRT: null,
      srtError: null,
      srtSourceText: null,
      isSrtValid: false,
    );
  }

  void clearYouTube() {
    state = state.copyWith(generatedYouTube: null, youtubeError: null);
  }

  void clearPrompts() {
    state = state.copyWith(generatedPrompts: null, promptsError: null);
  }

  void clearScenario() {
    state = state.copyWith(generatedScenario: null, scenarioError: null);
  }

  void clearAll() {
    state = state.copyWith(
      generatedSRT: null,
      generatedYouTube: null,
      generatedPrompts: null,
      generatedScenario: null,
      srtError: null,
      youtubeError: null,
      promptsError: null,
      scenarioError: null,
    );
  }

  // � v7.6.12: INSTRUÇÃO DE IDADE PARA PROMPTS DE IMAGENS DO PROTAGONISTA
  String _getAgeInstructionForImagePrompts(String ageCategory) {
    final ageLower = ageCategory.toLowerCase();

    if (ageLower.contains('jovem') || ageLower.contains('young')) {
      return '''🎂 **IDADE OBRIGATÓRIA:** Protagonista deve ter entre **20-35 anos** (young adult).
   - Aparência: jovem, energético, início/meio da carreira
   - Características físicas: pele lisa ou com mínimas linhas de expressão, aparência vibrante
   - Postura: dinâmica, moderna, confiante
   - Contexto: início de carreira, crescimento profissional/pessoal
   - ❌ NÃO representar como adolescente (muito jovem) ou maduro (40+)
   - ✅ Todos os 4 prompts devem manter esta faixa etária IDÊNTICA (20-35 anos)''';
    }

    if (ageLower.contains('maduro') || ageLower.contains('mature')) {
      return '''🎂 **IDADE OBRIGATÓRIA:** Protagonista deve ter entre **35-50 anos** (mature adult).
   - Aparência: experiente, consolidado, auge da carreira profissional
   - Características físicas: algumas linhas de expressão, aparência madura mas ainda vigorosa e ativa
   - Postura: confiante, estabelecida, profissional
   - Contexto: carreira consolidada, experiência de vida, possivelmente filhos adolescentes
   - ❌ NÃO representar como jovem (20s-early 30s) ou idoso (60+)
   - ✅ Todos os 4 prompts devem manter esta faixa etária IDÊNTICA (35-50 anos)''';
    }

    if (ageLower.contains('idoso') ||
        ageLower.contains('idosa') ||
        ageLower.contains('senior') ||
        ageLower.contains('elderly')) {
      return '''🎂 **IDADE OBRIGATÓRIA:** Protagonista deve ter **50+ anos** (senior adult).
   - Aparência: experiente, sábio, cabelos grisalhos ou brancos
   - Características físicas: rugas de expressão marcantes, sinais claros de maturidade, possível calvície parcial
   - Postura: elegante, digna, reflexiva
   - Contexto: aposentado ou perto, netos, legado familiar, sabedoria de vida
   - ❌ NÃO representar como jovem ou de meia-idade (30s-40s)
   - ✅ Todos os 4 prompts devem manter esta faixa etária IDÊNTICA (50+ anos)''';
    }

    // Fallback genérico
    return '''🎂 **IDADE:** Protagonista deve ter idade apropriada ao contexto da história.
   - Aparência física coerente com a faixa etária da narrativa
   - ✅ Todos os 4 prompts devem manter esta idade IDÊNTICA''';
  }

  // �🎭 v7.6.11: INSTRUÇÃO DE ETNIA PARA PROMPTS DE IMAGENS DO PROTAGONISTA
  String _getEthnicityInstructionForImagePrompts(String language) {
    final languageLower = language.toLowerCase();

    if (languageLower.contains('français') ||
        languageLower.contains('francês') ||
        languageLower == 'french') {
      return '''🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **branco europeu francês** (white European French).
   - Pele: clara/branca europeia (fair/light European skin tone)
   - Traços faciais: típicos franceses (typical French facial features)
   - Cabelos: castanhos, loiros ou pretos (brown, blonde, or black hair)
   - Olhos: claros ou escuros (light or dark eyes)
   - ❌ NÃO usar etnias asiáticas, africanas, latinas ou indígenas
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA''';
    }

    if (languageLower.contains('english') ||
        languageLower.contains('inglês') ||
        languageLower.contains('ingles')) {
      return '''🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **branco anglo-saxão** (white Anglo-Saxon).
   - Pele: clara/branca (fair/light skin tone)
   - Traços faciais: anglo-saxões típicos (typical Anglo-Saxon facial features)
   - Cabelos: loiros, ruivos, castanhos ou pretos (blonde, red, brown, or black hair)
   - Olhos: claros (azuis/verdes/cinza) ou escuros (blue/green/gray or dark eyes)
   - ❌ NÃO usar etnias asiáticas, latinas ou indígenas
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA''';
    }

    if (languageLower.contains('español') ||
        languageLower.contains('espanhol') ||
        languageLower == 'spanish') {
      return '''🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **hispânico/latino** (Hispanic/Latino).
   - Pele: morena-clara a morena (tan to brown skin tone)
   - Traços faciais: latinos típicos (typical Latino facial features)
   - Cabelos: pretos ou castanhos escuros (black or dark brown hair)
   - Olhos: escuros (dark eyes)
   - ❌ NÃO usar etnias asiáticas, africanas ou anglo-saxônicas
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA''';
    }

    if (languageLower.contains('português') ||
        languageLower.contains('portugues') ||
        languageLower == 'portuguese') {
      return '''🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **brasileiro/português** (Brazilian/Portuguese).
   - Pele: morena-clara a branca (tan-fair to white skin tone)
   - Traços faciais: brasileiros/portugueses mistos (mixed Brazilian/Portuguese features)
   - Cabelos: castanhos, pretos ou loiros (brown, black, or blonde hair)
   - Olhos: castanhos, verdes ou azuis (brown, green, or blue eyes)
   - Brasil é multiétnico: pode ser branco-brasileiro, pardo, moreno ou mestiço
   - ❌ NÃO usar etnias asiáticas puras ou africanas puras (exceto se temática exigir)
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA''';
    }

    if (languageLower.contains('italiano') || languageLower == 'italian') {
      return '''🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **italiano** (Italian, Mediterranean Caucasian).
   - Pele: clara a morena-mediterrânea (fair to Mediterranean tan skin tone)
   - Traços faciais: italianos típicos (typical Italian facial features)
   - Cabelos: pretos ou castanhos escuros (black or dark brown hair)
   - Olhos: castanhos ou verdes (brown or green eyes)
   - ❌ NÃO usar etnias nórdicas, asiáticas ou africanas
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA''';
    }

    if (languageLower.contains('alemão') ||
        languageLower.contains('alemao') ||
        languageLower == 'german') {
      return '''🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **germânico** (Germanic/German Caucasian).
   - Pele: clara/branca (fair/light skin tone)
   - Traços faciais: germânicos típicos (typical Germanic facial features)
   - Cabelos: loiros, castanhos ou ruivos (blonde, brown, or red hair)
   - Olhos: claros (azuis/verdes) ou castanhos (blue/green or brown eyes)
   - ❌ NÃO usar etnias mediterrâneas, asiáticas ou africanas
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA''';
    }

    if (languageLower.contains('russo') || languageLower == 'russian') {
      return '''🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **eslavo/russo** (Slavic/Russian Caucasian).
   - Pele: clara/branca (fair/light skin tone)
   - Traços faciais: eslavos típicos (typical Slavic facial features)
   - Cabelos: loiros, castanhos ou pretos (blonde, brown, or black hair)
   - Olhos: claros (azuis/cinza) ou castanhos (blue/gray or brown eyes)
   - ❌ NÃO usar etnias asiáticas centrais, africanas ou mediterrâneas
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA''';
    }

    if (languageLower.contains('japonês') ||
        languageLower.contains('japones') ||
        languageLower == 'japanese') {
      return '''🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **japonês** (Japanese East Asian).
   - Pele: clara-amarelada asiática (light-yellow Asian skin tone)
   - Traços faciais: japoneses típicos (typical Japanese facial features)
   - Cabelos: pretos e lisos (black straight hair)
   - Olhos: castanhos escuros e amendoados (dark brown almond-shaped eyes)
   - ❌ NÃO usar etnias brancas, africanas, latinas ou de outros países asiáticos
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA''';
    }

    // CHINÊS REMOVIDO - Não há YouTube na China

    if (languageLower.contains('coreano') ||
        languageLower.contains('korean') ||
        languageLower.contains('한국어') ||
        languageLower == 'ko') {
      return '''🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **coreano** (Korean East Asian).
   - Pele: clara-amarelada asiática (light-yellow Asian skin tone)
   - Traços faciais: coreanos típicos (typical Korean facial features)
   - Cabelos: pretos e lisos (black straight hair)
   - Olhos: castanhos escuros e amendoados (dark brown almond-shaped eyes)
   - ❌ NÃO usar etnias brancas, africanas, latinas ou de outros países asiáticos
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA''';
    }

    if (languageLower.contains('árabe') ||
        languageLower.contains('arabe') ||
        languageLower == 'arabic') {
      return '''🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **árabe/médio-oriental** (Arab/Middle Eastern).
   - Pele: morena-clara a morena-escura (tan to dark tan skin tone)
   - Traços faciais: árabes típicos (typical Arab facial features)
   - Cabelos: pretos ou castanhos escuros (black or dark brown hair)
   - Olhos: castanhos ou pretos (brown or black eyes)
   - ❌ NÃO usar etnias europeias, asiáticas ou africanas subsaarianas
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA''';
    }

    // Idiomas sem especificação de etnia
    return '''🎭 **ETNIA:** Protagonista deve ter etnia coerente com contexto cultural do idioma ${language}.
   - Aparência física apropriada ao contexto linguístico e geográfico
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA''';
  }
}

class ExtraToolsState {
  final bool isGeneratingSRT;
  final bool isGeneratingYouTube;
  final bool isGeneratingPrompts;
  final bool isGeneratingScenario;
  final String? generatedSRT;
  final String? generatedYouTube;
  final String? generatedPrompts;
  final String? generatedScenario;
  final String? srtError;
  final String? youtubeError;
  final String? promptsError;
  final String? scenarioError;
  // 🔄 Controle de validade do SRT
  final String? srtSourceText; // Texto original usado para gerar o SRT
  final bool isSrtValid; // Se o SRT está válido para o texto atual

  const ExtraToolsState({
    this.isGeneratingSRT = false,
    this.isGeneratingYouTube = false,
    this.isGeneratingPrompts = false,
    this.isGeneratingScenario = false,
    this.generatedSRT,
    this.generatedYouTube,
    this.generatedPrompts,
    this.generatedScenario,
    this.srtError,
    this.youtubeError,
    this.promptsError,
    this.scenarioError,
    // 🔄 Controle de validade do SRT
    this.srtSourceText,
    this.isSrtValid = false,
  });

  ExtraToolsState copyWith({
    bool? isGeneratingSRT,
    bool? isGeneratingYouTube,
    bool? isGeneratingPrompts,
    bool? isGeneratingScenario,
    String? generatedSRT,
    String? generatedYouTube,
    String? generatedPrompts,
    String? generatedScenario,
    String? srtError,
    String? youtubeError,
    String? promptsError,
    String? scenarioError,
    // 🔄 Controle de validade do SRT
    String? srtSourceText,
    bool? isSrtValid,
  }) {
    return ExtraToolsState(
      isGeneratingSRT: isGeneratingSRT ?? this.isGeneratingSRT,
      isGeneratingYouTube: isGeneratingYouTube ?? this.isGeneratingYouTube,
      isGeneratingPrompts: isGeneratingPrompts ?? this.isGeneratingPrompts,
      isGeneratingScenario: isGeneratingScenario ?? this.isGeneratingScenario,
      generatedSRT: generatedSRT ?? this.generatedSRT,
      generatedYouTube: generatedYouTube ?? this.generatedYouTube,
      generatedPrompts: generatedPrompts ?? this.generatedPrompts,
      generatedScenario: generatedScenario ?? this.generatedScenario,
      srtError: srtError ?? this.srtError,
      youtubeError: youtubeError ?? this.youtubeError,
      promptsError: promptsError ?? this.promptsError,
      scenarioError: scenarioError ?? this.scenarioError,
      // 🔄 Controle de validade do SRT
      srtSourceText: srtSourceText ?? this.srtSourceText,
      isSrtValid: isSrtValid ?? this.isSrtValid,
    );
  }
}

final extraToolsProvider =
    StateNotifierProvider<ExtraToolsNotifier, ExtraToolsState>((ref) {
      final geminiService = ref.watch(defaultGeminiServiceProvider);
      return ExtraToolsNotifier(geminiService);
    });
