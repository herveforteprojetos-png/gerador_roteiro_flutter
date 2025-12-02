import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/generation_config.dart';
import '../../data/models/localization_level.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/name_generator_service.dart';
import 'script_generation_provider.dart'; // Para acessar defaultGeminiServiceProvider

class AuxiliaryToolsNotifier extends StateNotifier<AuxiliaryToolsState> {
  final GeminiService _geminiService;

  AuxiliaryToolsNotifier(this._geminiService)
    : super(const AuxiliaryToolsState());

  Future<String> generateContext(GenerationConfig config) async {
    state = state.copyWith(isGeneratingContext: true, contextError: null);

    try {
      // CORREÇÃO: Usar instância injetada em vez de criar nova
      // final geminiService = GeminiService(); // <- VAZAMENTO DE MEMÓRIA!

      // 🎭 SISTEMA COMPLETO: Detectar gênero e idade por TODAS as perspectivas
      String protagonistGender =
          'neutro'; // 🔧 CORRIGIDO: padrão neutro para terceira_pessoa
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
          // 🔧 MELHORADO: Detectar gênero por palavras-chave no TÍTULO
          final tituloLower = config.title.toLowerCase();

          // Detectar FEMININO por palavras-chave
          if (tituloLower.contains('ma femme') ||
              tituloLower.contains('minha esposa') ||
              tituloLower.contains('ma fille') ||
              tituloLower.contains('minha filha') ||
              tituloLower.contains('ma mère') ||
              tituloLower.contains('minha mãe') ||
              tituloLower.contains('mamie') ||
              tituloLower.contains('vovó') ||
              tituloLower.contains('grand-mère') ||
              tituloLower.contains('avó') ||
              tituloLower.contains('nora') ||
              tituloLower.contains('sogra') ||
              tituloLower.contains('belle-fille') ||
              tituloLower.contains('belle-mère') ||
              tituloLower.contains('wife') ||
              tituloLower.contains('daughter') ||
              tituloLower.contains('mother') ||
              tituloLower.contains('grandma')) {
            protagonistGender = 'feminino';
          }
          // Detectar MASCULINO por palavras-chave
          else if (tituloLower.contains('mon frère') ||
              tituloLower.contains('meu irmão') ||
              tituloLower.contains('mon fils') ||
              tituloLower.contains('meu filho') ||
              tituloLower.contains('mon père') ||
              tituloLower.contains('meu pai') ||
              tituloLower.contains('papy') ||
              tituloLower.contains('vovô') ||
              tituloLower.contains('grand-père') ||
              tituloLower.contains('avô') ||
              tituloLower.contains('brother') ||
              tituloLower.contains('son') ||
              tituloLower.contains('father') ||
              tituloLower.contains('grandpa')) {
            protagonistGender = 'masculino';
          }
          // Se não detectar, manter neutro para Gemini decidir
          else {
            protagonistGender = 'neutro';
          }
          protagonistAge = 'maduro';
          break;
      }

      final protagonistName = config.protagonistName.trim().isNotEmpty
          ? config.protagonistName.trim()
          : (protagonistGender == 'neutro'
                ? '' // Deixar Gemini decidir o nome
                : NameGeneratorService.generateName(
                    gender: protagonistGender,
                    ageGroup: 'maduro',
                    language: config.language.toLowerCase() == 'português'
                        ? 'pt'
                        : 'en',
                  ));

      // 🎭 PERSONAGEM SECUNDÁRIO: Gênero oposto e faixa etária complementar
      String secondaryGender = protagonistGender == 'masculino'
          ? 'feminino'
          : (protagonistGender == 'feminino' ? 'masculino' : 'neutro');
      String secondaryAge = protagonistAge == 'jovem'
          ? 'idoso'
          : 'jovem'; // Contraste interessante

      final secondaryName = config.secondaryCharacterName.trim().isNotEmpty
          ? config.secondaryCharacterName.trim()
          : (secondaryGender == 'neutro'
                ? '' // Deixar Gemini decidir
                : NameGeneratorService.generateName(
                    gender: secondaryGender,
                    ageGroup: secondaryAge,
                    language: config.language.toLowerCase() == 'português'
                        ? 'pt'
                        : 'en',
                  ));

      // 🎯 PROMPT MELHORADO: Sistema completo de perspectivas
      final perspectiveLabel =
          GenerationConfig.perspectiveLabels[config.perspective] ??
          config.perspective;
      final genderDescription = protagonistGender == 'masculino'
          ? 'homem'
          : (protagonistGender == 'feminino' ? 'mulher' : 'pessoa');
      final ageDescription = protagonistAge == 'jovem'
          ? 'jovem'
          : (protagonistAge == 'idoso' ? 'idoso(a)' : 'adulto(a)');

      // 🌍 Detectar localização e época baseada no tema e configurações
      String locationGuidance = '';
      String eraGuidance = '';
      String technologyGuidance = '';

      // Análise do tema para detectar época histórica
      final temaLower = config.tema.toLowerCase();
      final localizacaoLower = config.localizacao.toLowerCase();
      final tituloLower = config.title.toLowerCase();

      // 🕰️ DETECÇÃO AUTOMÁTICA DE ÉPOCA HISTÓRICA
      bool isHistorical = false;
      String detectedEra = '';

      // Detectar Velho Oeste / Western
      if (temaLower.contains('velho oeste') ||
          temaLower.contains('western') ||
          temaLower.contains('cowboy') ||
          temaLower.contains('vaquero') ||
          localizacaoLower.contains('1800') ||
          localizacaoLower.contains('1880') ||
          localizacaoLower.contains('1890') ||
          tituloLower.contains('vaquero') ||
          tituloLower.contains('cowboy')) {
        isHistorical = true;
        detectedEra = 'Velho Oeste (1850-1900)';
        eraGuidance =
            'A história se passa durante o período do Velho Oeste (entre 1850-1900).';
        technologyGuidance =
            'Tecnologia da época: cavalos, revólveres, rifles, chapéus de couro, saloons/cantinas, telégrafos. NÃO há carros, telefones, eletricidade, internet ou qualquer tecnologia moderna.';
      }
      // Detectar Piratas / Era da Pirataria
      else if (temaLower.contains('pirata') ||
          temaLower.contains('piracy') ||
          temaLower.contains('corsário') ||
          temaLower.contains('buccaneer') ||
          localizacaoLower.contains('1500') ||
          localizacaoLower.contains('1600') ||
          localizacaoLower.contains('1700') ||
          tituloLower.contains('pirate') ||
          tituloLower.contains('pirata')) {
        isHistorical = true;
        detectedEra = 'Era da Pirataria (1500-1730)';
        eraGuidance =
            'A história se passa durante a Era Dourada da Pirataria (entre 1500-1730).';
        technologyGuidance =
            'Tecnologia da época: navios de madeira com velas, pistolas de pederneira, espadas/cutelos, canhões, bússolas, mapas do tesouro, tavernas. NÃO há motores, rádios, GPS ou tecnologia moderna.';
      }
      // Detectar Era Medieval
      else if (temaLower.contains('medieval') ||
          temaLower.contains('cavaleiro') ||
          temaLower.contains('knight') ||
          temaLower.contains('castelo') ||
          localizacaoLower.contains('1200') ||
          localizacaoLower.contains('1300') ||
          localizacaoLower.contains('1400')) {
        isHistorical = true;
        detectedEra = 'Era Medieval (1000-1500)';
        eraGuidance =
            'A história se passa durante a Idade Média (entre 1000-1500).';
        technologyGuidance =
            'Tecnologia da época: espadas, armaduras, castelos de pedra, cavalos, arcos e flechas, catapultas. NÃO há armas de fogo, eletricidade ou tecnologia moderna.';
      }
      // Detectar Samurai / Japão Feudal
      else if (temaLower.contains('samurai') ||
          temaLower.contains('feudal') ||
          localizacaoLower.contains('japão') ||
          localizacaoLower.contains('japan') ||
          localizacaoLower.contains('edo') ||
          localizacaoLower.contains('1600') ||
          localizacaoLower.contains('1700') ||
          localizacaoLower.contains('1800')) {
        isHistorical = true;
        detectedEra = 'Japão Feudal (1600-1868)';
        eraGuidance =
            'A história se passa durante o período feudal do Japão (entre 1600-1868).';
        technologyGuidance =
            'Tecnologia da época: katanas, arcos, castelos japoneses, quimonos, código bushido. NÃO há tecnologia ocidental moderna ou eletricidade.';
      }
      // Detectar Segunda Guerra Mundial
      else if (temaLower.contains('guerra mundial') ||
          temaLower.contains('world war') ||
          temaLower.contains('wwii') ||
          temaLower.contains('1940') ||
          localizacaoLower.contains('1940') ||
          localizacaoLower.contains('1944') ||
          localizacaoLower.contains('1945')) {
        isHistorical = true;
        detectedEra = 'Segunda Guerra Mundial (1939-1945)';
        eraGuidance =
            'A história se passa durante a Segunda Guerra Mundial (1939-1945).';
        technologyGuidance =
            'Tecnologia da época: rifles, tanques, aviões de guerra, rádios, uniformes militares, bunkers. NÃO há internet, celulares, computadores ou drones.';
      }
      // Detectar Era Vitoriana
      else if (temaLower.contains('vitoriana') ||
          temaLower.contains('victorian') ||
          localizacaoLower.contains('1800') ||
          localizacaoLower.contains('1850') ||
          localizacaoLower.contains('1880') ||
          localizacaoLower.contains('1890')) {
        isHistorical = true;
        detectedEra = 'Era Vitoriana (1837-1901)';
        eraGuidance =
            'A história se passa durante a Era Vitoriana (1837-1901).';
        technologyGuidance =
            'Tecnologia da época: lampiões a gás, carruagens, trens a vapor, telégrafos, vestuário formal (cartolas, vestidos longos). NÃO há carros, aviões, eletricidade doméstica ou tecnologia moderna.';
      }

      // 🌍 APLICAR NÍVEL DE REGIONALISMO à localização
      // Se tem localização customizada, usar ela COM FILTRO de regionalismo
      if (config.localizacao.trim().isNotEmpty) {
        final customLocation = config.localizacao.trim();

        // Aplicar filtro baseado no nível de regionalismo
        switch (config.localizationLevel) {
          case LocalizationLevel.global:
            // Transformar localização específica em descrição genérica
            locationGuidance =
                'um cenário urbano genérico, sem mencionar países, cidades ou regiões específicas. Use descrições universais (ex: "uma grande cidade", "a periferia urbana", "um bairro operário")';
            break;
          case LocalizationLevel.national:
            // Manter apenas o país, sem cidade
            locationGuidance = _extractCountryOnly(
              customLocation,
              config.language,
            );
            break;
          case LocalizationLevel.regional:
            // Pode usar a localização completa
            locationGuidance = customLocation;
            break;
        }
      } else {
        // Sem localização configurada: aplicar regras baseadas no regionalismo
        switch (config.localizationLevel) {
          case LocalizationLevel.global:
            // MODO GLOBAL: Sem mencionar país nenhum
            locationGuidance =
                'um cenário genérico e universal, sem mencionar países, cidades ou culturas específicas. Use descrições que funcionem em QUALQUER lugar do mundo';
            break;
          case LocalizationLevel.national:
            // MODO NACIONAL: Pode mencionar o país do idioma
            switch (config.language.toLowerCase()) {
              case 'português':
              case 'portugues':
              case 'portuguese':
                locationGuidance =
                    'em um país de língua portuguesa (Brasil ou Portugal), sem mencionar cidades específicas';
                break;
              case 'español':
              case 'espanhol':
              case 'spanish':
                locationGuidance =
                    'em um país hispanohablante, sem mencionar cidades específicas';
                break;
              case 'english':
              case 'inglês':
              case 'ingles':
                locationGuidance =
                    'em um país anglófono, sem mencionar cidades específicas';
                break;
              default:
                locationGuidance =
                    'apropriada ao idioma ${config.language}, sem mencionar cidades específicas';
            }
            break;
          case LocalizationLevel.regional:
            // MODO REGIONAL: Pode escolher uma região/cidade coerente
            switch (config.language.toLowerCase()) {
              case 'português':
              case 'portugues':
              case 'portuguese':
                locationGuidance =
                    'brasileira ou portuguesa (pode escolher uma cidade/região específica coerente com o tema)';
                break;
              case 'español':
              case 'espanhol':
              case 'spanish':
                locationGuidance =
                    'mexicana, colombiana, argentina, espanhola ou de outro país hispanohablante (pode escolher uma cidade/região específica)';
                break;
              case 'english':
              case 'inglês':
              case 'ingles':
                locationGuidance =
                    'americana, inglesa ou de outro país anglófono (pode escolher uma cidade/região específica)';
                break;
              default:
                locationGuidance = 'apropriada ao idioma ${config.language}';
            }
            break;
        }
      }

      // 🎯 EXEMPLO ADAPTADO AO NÍVEL DE REGIONALISMO
      String exampleContext;
      if (isHistorical) {
        exampleContext =
            '"A história se passa no México em 1880, durante o período do Velho Oeste. O protagonista Alejandro é um vaqueiro mexicano de 45 anos, seguindo o código de honra dos vaqueiros. Isabella é uma jovem que ele salva. O cenário inclui desertos áridos do norte do México, pequenos pueblos com cantinas de madeira, ranchos isolados. Tecnologia da época: cavalos como transporte principal, revólveres Colt, rifles Winchester, chapéus de couro, botas com esporas. Não há carros, telefones, eletricidade ou tecnologia moderna - apenas telégrafos nas cidades maiores. A comunicação é por mensageiros a cavalo. O conflito envolve bandidos que ameaçam a comunidade. Dois dias após salvar Isabella, Alejandro retorna com toda sua tribo de vaqueiros para um confronto. A atmosfera é de western clássico com tensão, honra e justiça pela própria mão."';
      } else {
        switch (config.localizationLevel) {
          case LocalizationLevel.global:
            exampleContext =
                '"O protagonista Carlos é um homem de 45 anos, trabalhador rural experiente. Ele é paciente mas determinado. Sandra, uma executiva sem escrúpulos, usou documentos fraudulentos para roubar a propriedade rural da família de Carlos. O cenário são planícies vastas e terrenos alagadiços da região rural. Carlos encontra Sandra presa em um atoleiro e, seguindo seu código de honra, a salva. Mas dois dias depois, ele retorna com toda a comunidade de trabalhadores rurais prejudicados por ela, não para violência, mas para um cerco estratégico usando conhecimento do terreno e exposição pública dos crimes dela. A atmosfera é de suspense e justiça."';
            break;
          case LocalizationLevel.national:
            exampleContext =
                '"O protagonista Carlos é um homem de 45 anos, trabalhador rural do país. Ele é paciente mas determinado. Sandra, uma executiva sem escrúpulos, usou documentos fraudulentos para roubar a propriedade rural da família de Carlos. O cenário é uma região rural do país, com suas planícies vastas. Carlos encontra Sandra presa em um atoleiro e, seguindo o código de honra local, a salva. Mas dois dias depois, ele retorna com toda a comunidade de trabalhadores prejudicados por ela, não para violência, mas para um cerco estratégico. A atmosfera é de suspense e justiça."';
            break;
          case LocalizationLevel.regional:
            exampleContext =
                '"O protagonista Carlos é um homem de 45 anos, vaqueiro do Pantanal. Ele é paciente mas determinado. Sandra, uma executiva sem escrúpulos, usou documentos fraudulentos para roubar a fazenda da família de Carlos. O cenário é o Pantanal brasileiro, com suas planícies vastas e atoleiros traiçoeiros. Carlos encontra Sandra presa em um atoleiro e, seguindo o código de honra dos vaqueiros, a salva. Mas dois dias depois, ele retorna com toda a comunidade de fazendeiros prejudicados por ela, não para violência, mas para um cerco estratégico usando conhecimento do terreno e exposição pública dos crimes ambientais dela. A atmosfera é de western moderno com suspense."';
            break;
        }
      }

      final contextPrompt =
          '''
Crie um contexto limpo e direto para uma história baseada nestas especificações:

TÍTULO: ${config.title}
TEMA: ${config.tema}
${isHistorical ? 'ÉPOCA DETECTADA: $detectedEra' : ''}
LOCALIZAÇÃO: $locationGuidance
PERSPECTIVA: $perspectiveLabel
IDIOMA DO ROTEIRO: ${config.language}
${protagonistName.isNotEmpty ? 'PROTAGONISTA: $protagonistName ($genderDescription, $ageDescription)' : 'PROTAGONISTA: Determinar gênero baseado no contexto da história ($ageDescription)'}
${secondaryName.isNotEmpty ? 'PERSONAGEM RELACIONADO: $secondaryName' : 'PERSONAGEM RELACIONADO: Determinar gênero apropriado'}

${isHistorical ? '⚠️ HISTÓRIA DE ÉPOCA: $eraGuidance' : ''}
${isHistorical ? technologyGuidance : ''}

INSTRUÇÕES:
1. ${isHistorical ? 'COMECE especificando a época/ano exato (ex: "A história se passa em 1880...")' : 'Descreva quando e onde a história acontece RESPEITANDO a LOCALIZAÇÃO acima'}
2. INCORPORE os elementos do TÍTULO "${config.title}" na construção do contexto - o título deve fazer sentido dentro da história descrita
3. Descreva o protagonista $protagonistName: personalidade, profissão típica da época, como se relaciona com o tema "${config.tema}"
   🎭 ETNIA DO PROTAGONISTA - OBRIGATÓRIO:
   ${_getEthnicityInstruction(config.language)}
4. ${isHistorical ? 'Descreva o cenário de época: ambiente, arquitetura, vestimentas, costumes da época' : 'Descreva o cenário RESPEITANDO EXATAMENTE a LOCALIZAÇÃO indicada acima (se for genérica, use descrições universais; se for nacional, mencione apenas o país; se for regional, pode usar cidade/região)'}
5. ${isHistorical ? 'Liste a TECNOLOGIA DISPONÍVEL na época (transporte, armas, comunicação) e o que NÃO existe ainda' : 'Descreva o ambiente e contexto'}
6. Descreva o conflito central: situação dramática envolvendo "${config.tema}" e conectada ao TÍTULO
7. Explique a motivação do protagonista e relação com $secondaryName
8. Defina a atmosfera: tom emocional da narrativa

⚠️ CRÍTICO:
- O contexto DEVE refletir os elementos do TÍTULO "${config.title}" - todos os componentes do título devem estar presentes na narrativa
- Escreva APENAS o contexto puro, SEM formatação markdown
- SEM emojis, asteriscos, hashtags ou símbolos especiais
- SEM títulos ou seções marcadas (como "### Título" ou "**Negrito**")
- APENAS texto corrido, natural e descritivo
- Use os nomes EXATOS: $protagonistName e $secondaryName
${isHistorical ? '- SEJA ESPECÍFICO sobre a época, tecnologia disponível e o que NÃO existe' : ''}
- RESPEITE RIGOROSAMENTE a LOCALIZAÇÃO indicada acima - não invente cidades ou países se não for permitido
- Mantenha conciso: máximo 500-800 palavras
- Responda em PORTUGUÊS (você traduzirá isso depois para orientar a geração no idioma ${config.language})

EXEMPLO DE FORMATO CORRETO${isHistorical ? ' PARA ÉPOCA HISTÓRICA' : ''} (sem formatação):
$exampleContext

Escreva o contexto agora:
''';

      final response = await _geminiService.generateTextWithApiKey(
        prompt: contextPrompt,
        apiKey: config.apiKey,
        model: 'gemini-2.5-flash-lite', // Ultra-rápido para geração de contexto
      );

      debugPrint(
        'AuxiliaryTools: Resposta recebida - Length: ${response.length}',
      );
      debugPrint(
        'AuxiliaryTools: Primeiros 100 chars: ${response.length > 100 ? response.substring(0, 100) : response}',
      );

      if (response.isEmpty) {
        throw Exception('Resposta vazia do servidor Gemini');
      }

      // 🧹 LIMPAR FORMATAÇÃO MARKDOWN E ELEMENTOS INDESEJADOS
      String cleanedResponse = _cleanContextResponse(response);

      debugPrint(
        'AuxiliaryTools: Contexto limpo - Length: ${cleanedResponse.length}',
      );
      debugPrint(
        'AuxiliaryTools: Primeiros 100 chars limpos: ${cleanedResponse.length > 100 ? cleanedResponse.substring(0, 100) : cleanedResponse}',
      );

      state = state.copyWith(
        isGeneratingContext: false,
        generatedContext: cleanedResponse,
      );

      return cleanedResponse;
    } catch (e) {
      // Melhorar mensagem de erro baseada no tipo de erro
      String errorMessage;
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('503')) {
        errorMessage =
            'Servidor do Gemini temporariamente indisponível. Tente novamente em alguns minutos.';
      } else if (errorStr.contains('429')) {
        errorMessage =
            'Muitas solicitações. Aguarde um momento antes de tentar novamente.';
      } else if (errorStr.contains('timeout') ||
          errorStr.contains('connection')) {
        errorMessage =
            'Problema de conexão. Verifique sua internet e tente novamente.';
      } else if (errorStr.contains('api')) {
        errorMessage =
            'Verifique se sua chave API está configurada corretamente.';
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

  Future<String> generateImagePrompt(
    GenerationConfig config,
    String context,
  ) async {
    state = state.copyWith(
      isGeneratingImagePrompt: true,
      imagePromptError: null,
    );

    try {
      // CORREÇÃO: Usar instância injetada
      // final geminiService = GeminiService(); // <- VAZAMENTO DE MEMÓRIA!

      // Prompt especializado para geração de prompt de imagem
      final imagePromptTemplate =
          '''
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
        model: 'gemini-2.5-flash-lite', // Ultra-rápido para prompts de imagem
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

  /// 🧹 Remove formatação markdown e elementos indesejados do contexto gerado
  String _cleanContextResponse(String response) {
    String cleaned = response;

    // 1. Remover linhas que começam com # (títulos markdown)
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s+.*$', multiLine: true), '');

    // 2. Remover linhas com apenas --- ou === (separadores markdown)
    cleaned = cleaned.replaceAll(RegExp(r'^[\-=]{3,}$', multiLine: true), '');

    // 3. Remover emojis (Unicode emoji ranges)
    cleaned = cleaned.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F000}-\u{1F02F}]|[\u{1F0A0}-\u{1F0FF}]|[\u{1F100}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F910}-\u{1F96B}]|[\u{1F980}-\u{1F9E0}]',
        unicode: true,
      ),
      '',
    );

    // 4. Remover formatação em negrito (**texto** ou __texto__)
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'__(.+?)__'), r'$1');

    // 5. Remover formatação em itálico (*texto* ou _texto_)
    cleaned = cleaned.replaceAll(RegExp(r'\*(.+?)\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'_(.+?)_'), r'$1');

    // 6. Remover bullets e listas (linhas que começam com -, *, números)
    cleaned = cleaned.replaceAll(RegExp(r'^[\*\-\+]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');

    // 7. Remover linhas em branco excessivas (mais de 2 seguidas)
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 8. Remover espaços em branco no início e fim
    cleaned = cleaned.trim();

    // 9. Remover frases introdutórias comuns da IA
    final introPatterns = [
      RegExp(r'^Com certeza[!.]?\s*', caseSensitive: false, multiLine: true),
      RegExp(r'^Claro[!.]?\s*', caseSensitive: false, multiLine: true),
      RegExp(r'^Aqui está.*?:\s*', caseSensitive: false, multiLine: true),
      RegExp(r'^Vou criar.*?:\s*', caseSensitive: false, multiLine: true),
      RegExp(
        r'^Segue o contexto.*?:\s*',
        caseSensitive: false,
        multiLine: true,
      ),
    ];

    for (final pattern in introPatterns) {
      cleaned = cleaned.replaceFirst(pattern, '');
    }

    // 10. Limpar novamente após remoções
    cleaned = cleaned.trim();

    return cleaned;
  }

  // 🌍 Método auxiliar para extrair apenas o país de uma localização
  String _extractCountryOnly(String location, String language) {
    final locationLower = location.toLowerCase();

    // Padrões comuns de localizações com cidade + país
    if (locationLower.contains('brasil') || locationLower.contains('brazil')) {
      return 'em um local no Brasil, sem mencionar cidades ou estados específicos';
    } else if (locationLower.contains('portugal')) {
      return 'em um local em Portugal, sem mencionar cidades específicas';
    } else if (locationLower.contains('méxico') ||
        locationLower.contains('mexico')) {
      return 'em um local no México, sem mencionar cidades ou estados específicos';
    } else if (locationLower.contains('espanha') ||
        locationLower.contains('spain')) {
      return 'em um local na Espanha, sem mencionar cidades específicas';
    } else if (locationLower.contains('argentina')) {
      return 'em um local na Argentina, sem mencionar cidades específicas';
    } else if (locationLower.contains('colômbia') ||
        locationLower.contains('colombia')) {
      return 'em um local na Colômbia, sem mencionar cidades específicas';
    } else if (locationLower.contains('estados unidos') ||
        locationLower.contains('eua') ||
        locationLower.contains('usa')) {
      return 'em um local nos Estados Unidos, sem mencionar cidades ou estados específicos';
    } else if (locationLower.contains('inglaterra') ||
        locationLower.contains('england') ||
        locationLower.contains('uk')) {
      return 'em um local no Reino Unido, sem mencionar cidades específicas';
    }

    // Se não reconheceu, retornar descrição genérica do país baseada no idioma
    switch (language.toLowerCase()) {
      case 'português':
      case 'portugues':
      case 'portuguese':
        return 'em um país de língua portuguesa, sem mencionar cidades específicas';
      case 'español':
      case 'espanhol':
      case 'spanish':
        return 'em um país hispanohablante, sem mencionar cidades específicas';
      case 'english':
      case 'inglês':
      case 'ingles':
        return 'em um país anglófono, sem mencionar cidades específicas';
      default:
        return 'em um local apropriado ao idioma $language, sem mencionar cidades específicas';
    }
  }

  void clearContext() {
    state = state.copyWith(generatedContext: null, contextError: null);
  }

  void clearImagePrompt() {
    state = state.copyWith(generatedImagePrompt: null, imagePromptError: null);
  }

  void clearAll() {
    state = const AuxiliaryToolsState();
  }

  // 🎭 NOVA FUNÇÃO: Gerar instrução de etnia baseada no idioma
  String _getEthnicityInstruction(String language) {
    final languageLower = language.toLowerCase();

    if (languageLower.contains('français') ||
        languageLower.contains('francês') ||
        languageLower == 'french') {
      return '''O protagonista deve ser de **etnia branca europeia francesa** (caucasiano europeu).
   - Aparência física típica: pele clara/branca europeia, traços faciais franceses típicos
   - Características: pode ter cabelos castanhos, loiros ou pretos; olhos claros ou escuros
   - ❌ NÃO usar etnias asiáticas, africanas, latinas ou indígenas para protagonista francês
   - ✅ Etnia coerente com contexto cultural francês/europeu''';
    }

    if (languageLower.contains('english') ||
        languageLower.contains('inglês') ||
        languageLower.contains('ingles')) {
      return '''O protagonista deve ser de **etnia branca anglo-saxônica** (caucasiano anglo-saxão).
   - Aparência física típica: pele clara/branca, traços faciais anglo-saxões típicos
   - Características: cabelos loiros, ruivos, castanhos ou pretos; olhos claros (azuis/verdes/cinza) ou escuros
   - ❌ NÃO usar etnias asiáticas, latinas ou indígenas para protagonista anglófono padrão
   - ✅ Etnia coerente com contexto cultural britânico/americano/australiano''';
    }

    if (languageLower.contains('español') ||
        languageLower.contains('espanhol') ||
        languageLower == 'spanish') {
      return '''O protagonista deve ser de **etnia hispânica/latina** (mestiço ou branco latino).
   - Aparência física típica: pele morena-clara a morena, traços latinos típicos
   - Características: cabelos pretos ou castanhos escuros, olhos escuros, traços mestiços ou mediterrâneos
   - ❌ NÃO usar etnias asiáticas, africanas ou anglo-saxônicas para protagonista hispânico
   - ✅ Etnia coerente com contexto cultural latino-americano ou espanhol''';
    }

    if (languageLower.contains('português') ||
        languageLower.contains('portugues') ||
        languageLower == 'portuguese') {
      return '''O protagonista deve ser de **etnia brasileira/portuguesa** (moreno-claro, pardo ou branco brasileiro).
   - Aparência física típica: pele morena-clara a branca, traços brasileiros/portugueses mistos
   - Características: cabelos castanhos, pretos ou loiros (menos comum); olhos castanhos, verdes ou azuis
   - Brasil é país multiétnico: pode ser branco-brasileiro, pardo, moreno ou mestiço
   - ❌ NÃO usar etnias asiáticas puras ou africanas puras (exceto se temática exigir)
   - ✅ Etnia coerente com diversidade brasileira/portuguesa''';
    }

    if (languageLower.contains('italiano') || languageLower == 'italian') {
      return '''O protagonista deve ser de **etnia italiana** (caucasiano mediterrâneo).
   - Aparência física típica: pele clara a morena-mediterrânea, traços italianos típicos
   - Características: cabelos pretos ou castanhos escuros, olhos castanhos ou verdes, traços mediterrâneos
   - ❌ NÃO usar etnias nórdicas, asiáticas ou africanas para protagonista italiano
   - ✅ Etnia coerente com contexto cultural italiano/mediterrâneo''';
    }

    if (languageLower.contains('alemão') ||
        languageLower.contains('alemao') ||
        languageLower == 'german') {
      return '''O protagonista deve ser de **etnia germânica** (caucasiano centro-europeu).
   - Aparência física típica: pele clara/branca, traços germânicos típicos
   - Características: cabelos loiros, castanhos ou ruivos; olhos claros (azuis/verdes) ou castanhos; estrutura facial germânica
   - ❌ NÃO usar etnias mediterrâneas, asiáticas ou africanas para protagonista alemão
   - ✅ Etnia coerente com contexto cultural alemão/austríaco/suíço-alemão''';
    }

    if (languageLower.contains('russo') || languageLower == 'russian') {
      return '''O protagonista deve ser de **etnia eslava/russa** (caucasiano eslavo).
   - Aparência física típica: pele clara/branca, traços eslavos típicos
   - Características: cabelos loiros, castanhos ou pretos; olhos claros (azuis/cinza) ou castanhos; estrutura facial eslava
   - ❌ NÃO usar etnias asiáticas centrais, africanas ou mediterrâneas para protagonista russo
   - ✅ Etnia coerente com contexto cultural russo/eslavo''';
    }

    if (languageLower.contains('japonês') ||
        languageLower.contains('japones') ||
        languageLower == 'japanese') {
      return '''O protagonista deve ser de **etnia japonesa** (asiático do leste - japonês).
   - Aparência física típica: pele clara-amarelada asiática, traços faciais japoneses típicos
   - Características: cabelos pretos e lisos, olhos castanhos escuros e amendoados, estrutura facial japonesa
   - ❌ NÃO usar etnias brancas, africanas, latinas ou de outros países asiáticos
   - ✅ Etnia coerente com contexto cultural japonês''';
    }

    // CHINÊS REMOVIDO - Não há YouTube na China

    if (languageLower.contains('coreano') ||
        languageLower.contains('korean') ||
        languageLower.contains('한국어') ||
        languageLower == 'ko') {
      return '''O protagonista deve ser de **etnia coreana** (asiático do leste - coreano).
   - Aparência física típica: pele clara-amarelada asiática, traços faciais coreanos típicos
   - Características: cabelos pretos e lisos, olhos castanhos escuros e amendoados, estrutura facial coreana
   - ❌ NÃO usar etnias brancas, africanas, latinas ou de outros países asiáticos
   - ✅ Etnia coerente com contexto cultural coreano''';
    }

    if (languageLower.contains('árabe') ||
        languageLower.contains('arabe') ||
        languageLower == 'arabic') {
      return '''O protagonista deve ser de **etnia árabe/médio-oriental** (caucasiano do oriente médio).
   - Aparência física típica: pele morena-clara a morena-escura, traços árabes típicos
   - Características: cabelos pretos ou castanhos escuros, olhos castanhos ou pretos, traços semíticos
   - ❌ NÃO usar etnias europeias, asiáticas ou africanas subsaarianas para protagonista árabe
   - ✅ Etnia coerente com contexto cultural árabe/médio-oriental''';
    }

    // Idiomas sem especificação de etnia
    return '''O protagonista deve ter **etnia coerente com o contexto cultural do idioma ${language}**.
   - Aparência física: apropriada ao contexto linguístico e geográfico da história
   - ✅ Etnia deve fazer sentido com localização e cultura apresentadas''';
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
      isGeneratingImagePrompt:
          isGeneratingImagePrompt ?? this.isGeneratingImagePrompt,
      generatedContext: generatedContext ?? this.generatedContext,
      generatedImagePrompt: generatedImagePrompt ?? this.generatedImagePrompt,
      contextError: contextError ?? this.contextError,
      imagePromptError: imagePromptError ?? this.imagePromptError,
    );
  }
}

// Provider para auxiliary tools
final auxiliaryToolsProvider =
    StateNotifierProvider<AuxiliaryToolsNotifier, AuxiliaryToolsState>((ref) {
      final geminiService = ref.watch(defaultGeminiServiceProvider);
      return AuxiliaryToolsNotifier(geminiService);
    });
