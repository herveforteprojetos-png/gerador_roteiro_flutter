import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/generation_config.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/name_generator_service.dart';
import 'script_generation_provider.dart'; // Para acessar defaultGeminiServiceProvider

class AuxiliaryToolsNotifier extends StateNotifier<AuxiliaryToolsState> {
  final GeminiService _geminiService;
  
  AuxiliaryToolsNotifier(this._geminiService) : super(const AuxiliaryToolsState());

  Future<String> generateContext(GenerationConfig config) async {
    state = state.copyWith(isGeneratingContext: true, contextError: null);
    
    try {
      // CORREÇÃO: Usar instância injetada em vez de criar nova
      // final geminiService = GeminiService(); // <- VAZAMENTO DE MEMÓRIA!
      
      // 🎭 SISTEMA COMPLETO: Detectar gênero e idade por TODAS as perspectivas
      String protagonistGender = 'masculino'; // padrão para terceira_pessoa
      String protagonistAge = 'maduro'; // padrão
      
      // MAPEAMENTO COMPLETO DE TODAS AS PERSPECTIVAS
      switch (config.perspective) {
        case 'primeira_pessoa_homem_idoso':
          protagonistGender = 'masculino';
          protagonistAge = 'idoso';
          break;
        case 'primeira_pessoa_homem_jovem':
          protagonistGender = 'masculino';
          protagonistAge = 'jovem';
          break;
        case 'primeira_pessoa_mulher_idosa':
          protagonistGender = 'feminino';
          protagonistAge = 'idoso';
          break;
        case 'primeira_pessoa_mulher_jovem':
          protagonistGender = 'feminino';
          protagonistAge = 'jovem';
          break;
        case 'terceira_pessoa':
        default:
          // Para terceira pessoa, usar tema para determinar se mais apropriado masculino/feminino
          if (config.tema.toLowerCase().contains('vingança') && config.title.toLowerCase().contains('nora')) {
            protagonistGender = 'feminino'; // Sogra vs nora = protagonista feminina
            protagonistAge = 'idoso';
          } else {
            protagonistGender = 'masculino'; // padrão
            protagonistAge = 'maduro';
          }
          break;
      }
      
      final protagonistName = config.protagonistName.trim().isNotEmpty 
          ? config.protagonistName.trim()
          : NameGeneratorService.generateName(
              gender: protagonistGender, // CORRIGIDO: Baseado na perspectiva
              ageGroup: 'maduro', // jovem, maduro, idoso
              language: config.language.toLowerCase() == 'português' ? 'pt' : 'en'
            );
      
      // 🎭 PERSONAGEM SECUNDÁRIO: Gênero oposto e faixa etária complementar
      String secondaryGender = protagonistGender == 'masculino' ? 'feminino' : 'masculino';
      String secondaryAge = protagonistAge == 'jovem' ? 'idoso' : 'jovem'; // Contraste interessante
      
      final secondaryName = config.secondaryCharacterName.trim().isNotEmpty
          ? config.secondaryCharacterName.trim()
          : NameGeneratorService.generateName(
              gender: secondaryGender,
              ageGroup: secondaryAge, 
              language: config.language.toLowerCase() == 'português' ? 'pt' : 'en'
            );
      
      // 🎯 PROMPT MELHORADO: Sistema completo de perspectivas
      final perspectiveLabel = GenerationConfig.perspectiveLabels[config.perspective] ?? config.perspective;
      final genderDescription = protagonistGender == 'masculino' ? 'HOMEM' : 'MULHER';
      final ageDescription = protagonistAge == 'jovem' ? 'JOVEM' : (protagonistAge == 'idoso' ? 'IDOSO(A)' : 'ADULTO(A)');
      
      final contextPrompt = '''
Crie um contexto COMPLETO em PORTUGUÊS para uma história YouTube baseada nas especificações EXATAS:

**CONFIGURAÇÃO OBRIGATÓRIA:**
- Título: ${config.title}
- Tema: ${config.tema}  
- Perspectiva: $perspectiveLabel
- Idioma: ${config.language}

🎭 **PERSONAGENS DEFINIDOS:**
- PROTAGONISTA: "$protagonistName" - $genderDescription $ageDescription (conforme perspectiva $perspectiveLabel)
- PERSONAGEM RELACIONADO: "$secondaryName"

📋 **ESTRUTURA OBRIGATÓRIA:**

**PROTAGONISTA "$protagonistName":**
Gênero: $genderDescription | Idade: $ageDescription | Personalidade marcante relacionada ao tema "${config.tema}" | Motivação clara e interessante para YouTube.

**CENÁRIO REALISTA:**
Localização brasileira atual, ambiente onde a história acontece, detalhes que tornam a situação believável.

**CONFLITO CENTRAL:**
Situação dramática específica envolvendo "${config.tema}" que cria tensão e interesse para o público YouTube.

**ATMOSFERA:**
Tom envolvente mas adequado para YouTube - interessante sem ser excessivamente pesado.

🔥 **CRÍTICO:** O protagonista "$protagonistName" DEVE ser exatamente um(a) $genderDescription $ageDescription conforme a perspectiva "$perspectiveLabel". Use os nomes EXATOS fornecidos. Crie contexto envolvente para narrativa YouTube.
''';

      final response = await _geminiService.generateTextWithApiKey(
        prompt: contextPrompt,
        apiKey: config.apiKey,
        model: 'gemini-2.5-pro', // CORREÇÃO: Apenas Pro 2.5 para qualidade máxima
      );

      debugPrint('AuxiliaryTools: Resposta recebida - Length: ${response.length}');
      debugPrint('AuxiliaryTools: Primeiros 100 chars: ${response.length > 100 ? response.substring(0, 100) : response}');

      if (response.isEmpty) {
        throw Exception('Resposta vazia do servidor Gemini');
      }

      state = state.copyWith(
        isGeneratingContext: false,
        generatedContext: response,
      );

      return response;
    } catch (e) {
      // Melhorar mensagem de erro baseada no tipo de erro
      String errorMessage;
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('503')) {
        errorMessage = 'Servidor do Gemini temporariamente indisponível. Tente novamente em alguns minutos.';
      } else if (errorStr.contains('429')) {
        errorMessage = 'Muitas solicitações. Aguarde um momento antes de tentar novamente.';
      } else if (errorStr.contains('timeout') || errorStr.contains('connection')) {
        errorMessage = 'Problema de conexão. Verifique sua internet e tente novamente.';
      } else if (errorStr.contains('api')) {
        errorMessage = 'Verifique se sua chave API está configurada corretamente.';
      } else {
        errorMessage = 'Erro inesperado ao gerar contexto. Tente novamente.';
      }
      
      state = state.copyWith(
        isGeneratingContext: false,
        contextError: errorMessage,
      );
      rethrow;
    }
  }

  Future<String> generateImagePrompt(GenerationConfig config, String context) async {
    state = state.copyWith(isGeneratingImagePrompt: true, imagePromptError: null);
    
    try {
      // CORREÇÃO: Usar instância injetada
      // final geminiService = GeminiService(); // <- VAZAMENTO DE MEMÓRIA!
      
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

      final response = await _geminiService.generateTextWithApiKey(
        prompt: imagePromptTemplate,
        apiKey: config.apiKey,
        model: 'gemini-2.5-pro', // CORREÇÃO: Apenas Pro 2.5 para qualidade máxima
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

// Provider para auxiliary tools
final auxiliaryToolsProvider = StateNotifierProvider<AuxiliaryToolsNotifier, AuxiliaryToolsState>((ref) {
  final geminiService = ref.watch(defaultGeminiServiceProvider);
  return AuxiliaryToolsNotifier(geminiService);
});
