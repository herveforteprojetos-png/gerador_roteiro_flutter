import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/data/models/generation_config.dart';
import 'package:flutter_gerador/data/services/gemini_service.dart';
import 'package:flutter_gerador/data/services/srt_service.dart';

class ExtraToolsNotifier extends StateNotifier<ExtraToolsState> {
  ExtraToolsNotifier() : super(const ExtraToolsState());

  Future<String> generateSRTSubtitles(GenerationConfig config, String scriptText) async {
    state = state.copyWith(isGeneratingSRT: true, srtError: null);
    
    try {
      // Configurações específicas para CapCut baseadas na imagem
      final srtContent = SrtService.generateSrt(
        scriptText,
        wordsPerMinute: 120, // Mais lento para não encavalar
        maxCharactersPerSubtitle: 500, // Máximo de caracteres por bloco (CapCut)
        maxLinesPerSubtitle: 3, // Permitir até 3 linhas
        minDisplayTime: 2.0, // Duração mínima por bloco (30 palavras ÷ 15 = 2s)
        maxDisplayTime: 8.0, // Duração máxima por bloco (100 palavras ÷ 12.5 = 8s)
        gapBetweenSubtitles: 1.0, // Intervalo de 1 segundo entre blocos
        minWordsPerBlock: 30, // Mínimo de palavras por bloco
        maxWordsPerBlock: 100, // Máximo de palavras por bloco
        blockDurationSeconds: 30, // Duração base de 30 segundos por bloco
        intervalBetweenBlocks: 20, // Intervalo de 20 segundos entre blocos
      );

      state = state.copyWith(
        isGeneratingSRT: false,
        generatedSRT: srtContent,
      );

      return srtContent;
    } catch (e) {
      state = state.copyWith(
        isGeneratingSRT: false,
        srtError: 'Erro ao gerar SRT: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<String> generateYouTubeDescription(GenerationConfig config, String scriptText) async {
    state = state.copyWith(isGeneratingYouTube: true, youtubeError: null);
    
    try {
      final geminiService = GeminiService();
      
      final youtubePrompt = '''
Com base no seguinte roteiro, crie uma descrição SIMPLES e CONCISA para YouTube:

**Título do Vídeo:** ${config.title}
**Roteiro:**
$scriptText

**INSTRUÇÕES ESPECÍFICAS:**

1. Crie APENAS uma descrição sobre o vídeo (máximo 500 caracteres)
2. Liste tags relevantes baseadas no conteúdo
3. Adapte completamente para o idioma: ${config.language}

**FORMATO OBRIGATÓRIO:**

🎬 **SOBRE O VÍDEO**
[Descrição envolvente do conteúdo em máximo 500 caracteres, destacando os pontos principais da história]

�️ **TAGS SUGERIDAS**
[Lista de tags separadas por espaços, incluindo gênero, tema, idioma e palavras-chave relevantes - ex: #horror #misterio #storytelling #${config.language.toLowerCase()}]

**IMPORTANTE:**
- Responda COMPLETAMENTE em ${config.language}
- Seja conciso e envolvente
- Foque nos elementos mais interessantes da história
- Use tags que ajudem na descoberta do conteúdo
''';

      final response = await geminiService.generateText(
        prompt: youtubePrompt,
        apiKey: config.apiKey,
        model: 'gemini-1.5-flash',
      );

      state = state.copyWith(
        isGeneratingYouTube: false,
        generatedYouTube: response,
      );

      return response;
    } catch (e) {
      state = state.copyWith(
        isGeneratingYouTube: false,
        youtubeError: 'Erro ao gerar descrição: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<String> generateProtagonistPrompt(GenerationConfig config, String scriptText) async {
    state = state.copyWith(isGeneratingPrompts: true, promptsError: null);
    
    try {
      final geminiService = GeminiService();
      
      final protagonistPrompt = '''
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

      final result = await geminiService.generateText(
        prompt: protagonistPrompt,
        apiKey: config.apiKey,
        model: config.model,
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

  Future<String> generateScenarioPrompt(GenerationConfig config, String scriptText) async {
    state = state.copyWith(isGeneratingScenario: true, scenarioError: null);
    
    try {
      final geminiService = GeminiService();
      
      final scenarioPrompt = '''
Com base no seguinte roteiro, gere um prompt em inglês para criar uma imagem do cenário principal no Midjourney:

**Título:** ${config.title}
**Roteiro:**
$scriptText

**Instruções:**
- Gere um prompt do cenário principal onde a história acontece
- Baseado no contexto e ambientação do roteiro
- O prompt deve ser em inglês para melhor compreensão da IA
- Inclua detalhes de localização, atmosfera, iluminação e elementos visuais
- Use estilo realista e cinematográfico
- Foque no ambiente, não em pessoas

**Formato:** Apenas o prompt em inglês, sem explicações adicionais.
''';

      final result = await geminiService.generateText(
        prompt: scenarioPrompt,
        apiKey: config.apiKey,
        model: config.model,
      );
      
      state = state.copyWith(
        isGeneratingScenario: false,
        generatedScenario: result,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        isGeneratingScenario: false,
        scenarioError: 'Erro ao gerar prompt do cenário: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<String> generateAdditionalPrompts(GenerationConfig config, String scriptText) async {
    state = state.copyWith(isGeneratingPrompts: true, promptsError: null);
    
    try {
      final geminiService = GeminiService();
      
      final promptsTemplate = '''
Com base no seguinte roteiro, gere prompts adicionais para criação de conteúdo:

**Título:** ${config.title}
**Roteiro:**
$scriptText

**Gere os seguintes prompts:**

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

      final response = await geminiService.generateText(
        prompt: promptsTemplate,
        apiKey: config.apiKey,
        model: 'gemini-1.5-flash', // Usar Flash para auxiliary tools por ser mais confiável
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
    state = state.copyWith(generatedSRT: null, srtError: null);
  }

  void clearYouTube() {
    state = state.copyWith(generatedYouTube: null, youtubeError: null);
  }

  void clearPrompts() {
    state = state.copyWith(generatedPrompts: null, promptsError: null);
  }

  void clearAll() {
    state = const ExtraToolsState();
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
    );
  }
}

final extraToolsProvider = StateNotifierProvider<ExtraToolsNotifier, ExtraToolsState>((ref) {
  return ExtraToolsNotifier();
});
