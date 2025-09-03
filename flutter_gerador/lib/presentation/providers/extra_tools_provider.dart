import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/generation_config.dart';
import '../../data/services/gemini_service.dart';

class ExtraToolsNotifier extends StateNotifier<ExtraToolsState> {
  ExtraToolsNotifier() : super(const ExtraToolsState());

  Future<String> generateSRTSubtitles(GenerationConfig config, String scriptText) async {
    state = state.copyWith(isGeneratingSRT: true, srtError: null);
    
    try {
      final geminiService = GeminiService();
      
      final srtPrompt = '''
Com base no seguinte roteiro, crie legendas no formato SRT para um vídeo:

**Roteiro:**
$scriptText

**Instruções:**
1. Divida o texto em segmentos apropriados para legendas (máximo 2 linhas por legenda)
2. Calcule tempos realistas considerando uma velocidade de fala natural
3. Use o formato SRT padrão:
   - Número da legenda
   - Tempo inicial --> Tempo final
   - Texto da legenda
   - Linha em branco

**Exemplo de formato:**
1
00:00:01,000 --> 00:00:04,000
Primeira linha da legenda
Segunda linha se necessário

2
00:00:05,000 --> 00:00:08,000
Próxima legenda

Gere as legendas em ${config.language} mantendo sincronia natural com a narrativa.
''';

      final response = await geminiService.generateText(
        prompt: srtPrompt,
        apiKey: config.apiKey,
      );

      state = state.copyWith(
        isGeneratingSRT: false,
        generatedSRT: response,
      );

      return response;
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
Com base no seguinte roteiro, crie uma descrição otimizada para YouTube:

**Título do Vídeo:** ${config.title}
**Roteiro:**
$scriptText

**Crie uma descrição que inclua:**

🎬 **SOBRE O VÍDEO**
[Resumo envolvente do conteúdo em 2-3 frases]

📖 **SINOPSE**
[Descrição mais detalhada da história/conteúdo]

🎭 **DESTAQUES**
• [Ponto interessante 1]
• [Ponto interessante 2] 
• [Ponto interessante 3]

⏰ **CAPÍTULOS** (se aplicável)
00:00 - Introdução
[Adicionar timestamps baseados no roteiro]

🏷️ **TAGS SUGERIDAS**
#tag1 #tag2 #tag3 #storytelling #${config.language}

📱 **CONECTE-SE**
[Espaço para links das redes sociais]

Responda em ${config.language} com uma descrição profissional e otimizada para SEO.
''';

      final response = await geminiService.generateText(
        prompt: youtubePrompt,
        apiKey: config.apiKey,
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
  final String? generatedSRT;
  final String? generatedYouTube;
  final String? generatedPrompts;
  final String? srtError;
  final String? youtubeError;
  final String? promptsError;

  const ExtraToolsState({
    this.isGeneratingSRT = false,
    this.isGeneratingYouTube = false,
    this.isGeneratingPrompts = false,
    this.generatedSRT,
    this.generatedYouTube,
    this.generatedPrompts,
    this.srtError,
    this.youtubeError,
    this.promptsError,
  });

  ExtraToolsState copyWith({
    bool? isGeneratingSRT,
    bool? isGeneratingYouTube,
    bool? isGeneratingPrompts,
    String? generatedSRT,
    String? generatedYouTube,
    String? generatedPrompts,
    String? srtError,
    String? youtubeError,
    String? promptsError,
  }) {
    return ExtraToolsState(
      isGeneratingSRT: isGeneratingSRT ?? this.isGeneratingSRT,
      isGeneratingYouTube: isGeneratingYouTube ?? this.isGeneratingYouTube,
      isGeneratingPrompts: isGeneratingPrompts ?? this.isGeneratingPrompts,
      generatedSRT: generatedSRT ?? this.generatedSRT,
      generatedYouTube: generatedYouTube ?? this.generatedYouTube,
      generatedPrompts: generatedPrompts ?? this.generatedPrompts,
      srtError: srtError ?? this.srtError,
      youtubeError: youtubeError ?? this.youtubeError,
      promptsError: promptsError ?? this.promptsError,
    );
  }
}

final extraToolsProvider = StateNotifierProvider<ExtraToolsNotifier, ExtraToolsState>((ref) {
  return ExtraToolsNotifier();
});
