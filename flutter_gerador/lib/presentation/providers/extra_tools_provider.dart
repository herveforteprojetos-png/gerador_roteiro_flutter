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

2. **TAGS ESTRATÉGICAS**:
   - Gênero da história (ex: #mistério #drama #horror #comédia)
   - Elementos narrativos (ex: #storytelling #históriaverdadeira #ficção)
   - Perfil do protagonista (ex: #mulheridosa #jovem #vingança)
   - Temas universais (ex: #família #justiça #amor #traição)
   - Idioma: #$languageTag
   - Palavras-chave específicas do roteiro

3. **ADAPTAÇÃO COMPLETA PARA ${config.language}**

**FORMATO OBRIGATÓRIO:**

🎬 **SOBRE O VÍDEO**
[Descrição de 400-500 caracteres com hook forte, resumo envolvente e pergunta final para engajamento]

📱 **TAGS SUGERIDAS**
[15-20 tags relevantes incluindo gênero, tema, perfil, elementos narrativos e idioma]

**DIRETRIZES DE QUALIDADE:**
- Seja específico, não genérico
- Use palavras que geram emoção
- Inclua elementos de suspense sem spoilers
- Adapte completamente para ${config.language}
- Foque na experiência emocional que o vídeo oferece
''';

      print('📤 Enviando para Gemini...');
      final response = await _geminiService.generateTextWithApiKey(
        prompt: youtubePrompt,
        apiKey: config.apiKey,
        model: 'gemini-2.5-flash-lite', // Ultra rápido e econômico
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
Com base no seguinte roteiro, gere um prompt em inglês para criar uma imagem do protagonista no Midjourney:

**Título:** ${config.title}
**Roteiro:**
$scriptText

**Instruções:**
- Gere um prompt do protagonista da cintura para cima
- De frente para a câmera
- Com roupa normal dele (baseada no contexto do roteiro)
- O prompt deve ser em inglês para melhor compreensão da IA
- Inclua detalhes físicos, roupas e expressão
- Use estilo realista e fotográfico

**Formato:** Apenas o prompt em inglês, sem explicações adicionais.
''';

      final result = await _geminiService.generateTextWithApiKey(
        prompt: protagonistPrompt,
        apiKey: config.apiKey,
        model: 'gemini-2.5-flash-lite', // Ultra rápido e econômico
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

  Future<String> generateScenarioPrompt(
    GenerationConfig config,
    String scriptText,
  ) async {
    print('🏔️ ExtraTools: Iniciando geração Scenario Prompt');
    print(
      '  📋 Config: ${config.title}, ${config.language}, API Key: ${config.apiKey.isNotEmpty ? "Present" : "Missing"}',
    );
    print('  📝 Script length: ${scriptText.length} chars');

    state = state.copyWith(isGeneratingScenario: true, scenarioError: null);

    try {
      final scenarioPrompt =
          '''
Com base no seguinte roteiro, gere um prompt em inglês otimizado para criar uma imagem do cenário principal no Midjourney:

**Título:** ${config.title}
**Roteiro:**
$scriptText

**INSTRUÇÕES ESPECÍFICAS:**
- Analise o roteiro e identifique o cenário/ambiente principal onde a ação acontece
- Crie um prompt detalhado em inglês para gerar uma imagem cinematográfica
- Inclua detalhes específicos de: localização, atmosfera, época, iluminação, clima
- Use estilo fotorrealista e cinematográfico (cinematic, photorealistic)
- Adicione elementos visuais que transmitam o mood da história
- Inclua aspectos técnicos de câmera e composição quando relevante
- NÃO inclua pessoas/personagens, apenas o ambiente
- Use palavras-chave que funcionam bem no Midjourney

**ELEMENTOS OBRIGATÓRIOS:**
- Descrição detalhada do ambiente principal
- Época/período histórico se relevante
- Atmosfera e mood da cena
- Detalhes de iluminação
- Estilo visual (cinematic, photorealistic, etc.)
- Aspectos técnicos da composição

**FORMATO:** Prompt completo em inglês, pronto para usar no Midjourney, sem explicações adicionais.

**EXEMPLO DE ESTRUTURA:**
"[ambiente detalhado], [época/período], [atmosfera/mood], [iluminação], [estilo visual], [aspectos técnicos], --ar 16:9 --v 6"
''';

      print('📤 Enviando scenario prompt para Gemini...');
      final result = await _geminiService.generateTextWithApiKey(
        prompt: scenarioPrompt,
        apiKey: config.apiKey,
        model: 'gemini-2.5-flash-lite', // Ultra rápido e econômico
      );

      print('✅ Resposta scenario recebida do Gemini');
      print('📊 Result length: ${result.length} chars');

      state = state.copyWith(
        isGeneratingScenario: false,
        generatedScenario: result,
      );

      return result;
    } catch (e) {
      print('❌ ERRO na geração Scenario: $e');
      state = state.copyWith(
        isGeneratingScenario: false,
        scenarioError: 'Erro ao gerar prompt do cenário: ${e.toString()}',
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
        model: 'gemini-2.5-flash-lite', // Ultra rápido e econômico
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
