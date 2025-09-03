import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/generation_config.dart';
import '../../data/services/gemini_service.dart';

class AuxiliaryToolsNotifier extends StateNotifier<AuxiliaryToolsState> {
  AuxiliaryToolsNotifier() : super(const AuxiliaryToolsState());

  Future<String> generateContext(GenerationConfig config) async {
    state = state.copyWith(isGeneratingContext: true, contextError: null);
    
    try {
      final geminiService = GeminiService();
      
      // Prompt especializado para geração de contexto
      final contextPrompt = '''
Gere um contexto detalhado para um roteiro com as seguintes especificações:

**Título:** ${config.title}
**Idioma:** ${config.language}
**Perspectiva:** ${GenerationConfig.perspectiveLabels[config.perspective] ?? config.perspective}
**Extensão:** ${config.quantity} ${config.measureType}

Por favor, crie um contexto que inclua:

1. **Gênero e Tom:** Defina o gênero principal e o tom desejado
2. **Protagonista:** Descreva o personagem principal, suas motivações e conflitos
3. **Cenário:** Estabeleça onde e quando a história se passa
4. **Conflito Central:** Identifique o problema principal que move a narrativa
5. **Arco Narrativo:** Esboce a jornada do protagonista
6. **Elementos Únicos:** Adicione detalhes que tornem a história interessante

Responda em ${config.language} e mantenha um contexto rico mas conciso para orientar a criação do roteiro.
''';

      final response = await geminiService.generateText(
        prompt: contextPrompt,
        apiKey: config.apiKey,
      );

      state = state.copyWith(
        isGeneratingContext: false,
        generatedContext: response,
      );

      return response;
    } catch (e) {
      state = state.copyWith(
        isGeneratingContext: false,
        contextError: 'Erro ao gerar contexto: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<String> generateImagePrompt(GenerationConfig config, String context) async {
    state = state.copyWith(isGeneratingImagePrompt: true, imagePromptError: null);
    
    try {
      final geminiService = GeminiService();
      
      // Prompt especializado para geração de prompt de imagem
      final imagePromptTemplate = '''
Com base no seguinte contexto de roteiro, crie um prompt detalhado para geração de imagem:

**Título:** ${config.title}
**Contexto:** $context

Gere um prompt em inglês para criação de imagem que capture a essência visual da história. O prompt deve incluir:

1. **Estilo Visual:** (cinematográfico, artístico, realista, etc.)
2. **Composição:** (enquadramento, perspectiva, profundidade)
3. **Elementos Visuais:** (personagens, cenário, objetos importantes)
4. **Atmosfera:** (iluminação, cores, mood)
5. **Qualidade:** (resolução, detalhes técnicos)

Formato do prompt: Uma descrição concisa e rica em detalhes visuais, otimizada para IA de geração de imagens como DALL-E, Midjourney ou Stable Diffusion.

Responda apenas com o prompt final em inglês, sem explicações adicionais.
''';

      final response = await geminiService.generateText(
        prompt: imagePromptTemplate,
        apiKey: config.apiKey,
      );

      state = state.copyWith(
        isGeneratingImagePrompt: false,
        generatedImagePrompt: response,
      );

      return response;
    } catch (e) {
      state = state.copyWith(
        isGeneratingImagePrompt: false,
        imagePromptError: 'Erro ao gerar prompt de imagem: ${e.toString()}',
      );
      rethrow;
    }
  }

  void clearContext() {
    state = state.copyWith(
      generatedContext: null,
      contextError: null,
    );
  }

  void clearImagePrompt() {
    state = state.copyWith(
      generatedImagePrompt: null,
      imagePromptError: null,
    );
  }

  void clearAll() {
    state = const AuxiliaryToolsState();
  }
}

class AuxiliaryToolsState {
  final bool isGeneratingContext;
  final bool isGeneratingImagePrompt;
  final String? generatedContext;
  final String? generatedImagePrompt;
  final String? contextError;
  final String? imagePromptError;

  const AuxiliaryToolsState({
    this.isGeneratingContext = false,
    this.isGeneratingImagePrompt = false,
    this.generatedContext,
    this.generatedImagePrompt,
    this.contextError,
    this.imagePromptError,
  });

  AuxiliaryToolsState copyWith({
    bool? isGeneratingContext,
    bool? isGeneratingImagePrompt,
    String? generatedContext,
    String? generatedImagePrompt,
    String? contextError,
    String? imagePromptError,
  }) {
    return AuxiliaryToolsState(
      isGeneratingContext: isGeneratingContext ?? this.isGeneratingContext,
      isGeneratingImagePrompt: isGeneratingImagePrompt ?? this.isGeneratingImagePrompt,
      generatedContext: generatedContext ?? this.generatedContext,
      generatedImagePrompt: generatedImagePrompt ?? this.generatedImagePrompt,
      contextError: contextError ?? this.contextError,
      imagePromptError: imagePromptError ?? this.imagePromptError,
    );
  }
}

final auxiliaryToolsProvider = StateNotifierProvider<AuxiliaryToolsNotifier, AuxiliaryToolsState>((ref) {
  return AuxiliaryToolsNotifier();
});
