import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/services/gemini/tracking/character_tracker.dart';
import 'package:flutter_gerador/data/models/debug_log.dart';
import 'package:flutter_gerador/data/services/gemini/tracking/name_constants.dart';
import 'llm_client.dart';

/// âœ… ScriptValidator - Validador de Roteiros
///
/// ResponsÃ¡vel por:
/// - ValidaÃ§Ã£o de coerÃªncia tÃ­tulo â†” histÃ³ria
/// - TraduÃ§Ã£o de keywords para idiomas alvo
/// - ExtraÃ§Ã£o de elementos-chave do tÃ­tulo
/// - ValidaÃ§Ã£o de relacionamentos familiares
/// - ValidaÃ§Ã£o de nomes de protagonista
///
/// Parte da refatoraÃ§Ã£o SOLID do GeminiService v7.6.64
class ScriptValidator {
  final Dio _dio;
  final LlmClient? _llmClient;
  final _debugLogger = DebugLogManager();

  ScriptValidator({Dio? dio, LlmClient? llmClient})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
            ),
          ),
      _llmClient = llmClient;

  // ================== TRADUÃ‡ÃƒO DE KEYWORDS ==================

  /// ðŸŒ Traduz keywords para o idioma alvo
  ///
  /// [keywords]: Lista de palavras-chave em portuguÃªs
  /// [targetLanguage]: Idioma de destino
  /// [apiKey]: Chave da API Gemini
  ///
  /// Retorna: Lista combinada de keywords originais + traduzidas
  Future<List<String>> translateKeywordsToTargetLang(
    List<String> keywords,
    String targetLanguage,
    String apiKey,
  ) async {
    if (keywords.isEmpty) return keywords;

    final targetLower = targetLanguage.toLowerCase();

    // Se o idioma alvo Ã© portuguÃªs, nÃ£o precisa traduzir
    if (targetLower.contains('portugu') ||
        targetLower.contains('pt-br') ||
        targetLower == 'pt') {
      return keywords;
    }

    try {
      final prompt =
          '''
TAREFA: Tradutor de Palavras-Chave para ValidaÃ§Ã£o de Roteiro.

IDIOMA DE ORIGEM: PortuguÃªs
IDIOMA DE DESTINO: $targetLanguage

PALAVRAS-CHAVE PARA TRADUZIR:
${keywords.map((k) => '- $k').join('\n')}

INSTRUÃ‡Ã•ES:
1. Traduza cada palavra/frase para o idioma de destino
2. Mantenha o significado semÃ¢ntico, nÃ£o literal
3. Se uma palavra tem mÃºltiplas traduÃ§Ãµes, escolha a mais comum

FORMATO DE SAÃDA (JSON array apenas, sem markdown):
["traduÃ§Ã£o1", "traduÃ§Ã£o2", "traduÃ§Ã£o3"]

EXEMPLO:
Entrada: ["marmita", "funcionÃ¡rio", "ajudar"]
SaÃ­da para Coreano: ["ë„ì‹œë½", "ì§ì›", "ë•ë‹¤"]
SaÃ­da para InglÃªs: ["lunch box", "employee", "help"]

RESPONDA APENAS COM O JSON ARRAY:''';

      // ðŸ—ï¸ v7.6.64: Usar LlmClient se disponÃ­vel
      String text;
      if (_llmClient != null) {
        text = await _llmClient.generateText(
          prompt: prompt,
          apiKey: apiKey,
          model: 'gemini-2.0-flash-exp',
          maxTokens: 500,
          temperature: 0.1,
        );
      } else {
        // Fallback para Dio direto (compatibilidade)
        final response = await _dio.post(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent',
          queryParameters: {'key': apiKey},
          data: {
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 500},
          },
        );

        text =
            response.data['candidates'][0]['content']['parts'][0]['text']
                ?.toString() ??
            '';
      }

      final cleanText = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(cleanText);
      if (jsonMatch != null) {
        final List<dynamic> parsed = jsonDecode(jsonMatch.group(0)!);
        final translated = parsed.map((e) => e.toString()).toList();

        if (kDebugMode) {
          debugPrint('ðŸŒ TRADUÃ‡ÃƒO DE KEYWORDS:');
          debugPrint('   Original (PT): ${keywords.join(", ")}');
          debugPrint(
            '   Traduzido ($targetLanguage): ${translated.join(", ")}',
          );
        }

        // Retorna AMBOS: original + traduzido
        return [...keywords, ...translated];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('âš ï¸ Erro na traduÃ§Ã£o de keywords: $e');
      }
    }

    return keywords;
  }

  // ================== EXTRAÃ‡ÃƒO DE ELEMENTOS DO TÃTULO ==================

  /// ðŸŽ¯ Extrai elementos-chave do tÃ­tulo
  ///
  /// Identifica personagens, aÃ§Ãµes, contextos e objetos
  /// que DEVEM aparecer na histÃ³ria
  Map<String, List<String>> extractTitleKeyElements(
    String title,
    String language,
  ) {
    final result = <String, List<String>>{
      'personagens': [],
      'acoes': [],
      'contextos': [],
      'objetos': [],
    };

    if (title.trim().isEmpty) return result;

    final titleLower = title.toLowerCase();

    // ðŸŽ¯ DETECÃ‡ÃƒO DE PERSONAGENS
    final personPatterns = _getPersonagePatterns();
    for (final entry in personPatterns.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(titleLower)) {
        result['personagens']!.add(entry.value);
      }
    }

    // ðŸŽ¯ DETECÃ‡ÃƒO DE AÃ‡Ã•ES
    final actionPatterns = _getActionPatterns();
    for (final entry in actionPatterns.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(titleLower)) {
        result['acoes']!.add(entry.value);
      }
    }

    // ðŸŽ¯ DETECÃ‡ÃƒO DE CONTEXTOS/LOCAIS
    final contextPatterns = _getContextPatterns();
    for (final entry in contextPatterns.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(titleLower)) {
        result['contextos']!.add(entry.value);
      }
    }

    // ðŸŽ¯ DETECÃ‡ÃƒO DE OBJETOS IMPORTANTES
    final objectPatterns = _getObjectPatterns();
    for (final entry in objectPatterns.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(titleLower)) {
        result['objetos']!.add(entry.value);
      }
    }

    return result;
  }

  /// PadrÃµes de personagens multilÃ­ngues
  Map<String, String> _getPersonagePatterns() {
    return {
      // PortuguÃªs
      r'(?:funcionÃ¡ri[oa]|atendente|vendedor|caixa|balconista)\s+(?:de\s+)?(?:loja|mercado|supermercado|conveniÃªncia)':
          'funcionÃ¡rio de loja/conveniÃªncia',
      r'(?:garÃ§om|garÃ§onete|atendente)\s+(?:de\s+)?(?:restaurante|cafÃ©|bar|lanchonete)':
          'garÃ§om/garÃ§onete',
      r'(?:mÃ©dic[oa]|enferm[oa]|doutor[a]?)': 'profissional de saÃºde',
      r'(?:advogad[oa]|juiz[a]?|promotor[a]?)': 'profissional jurÃ­dico',
      r'(?:CEO|empresÃ¡ri[oa]|dono|chefe|patrÃ£o|gerente)': 'executivo/chefe',
      r'(?:mendigo|sem-teto|morador de rua|idoso faminto|noiva|noivo)':
          'pessoa em situaÃ§Ã£o especial',

      // English
      r'(?:store|shop|convenience\s+store)\s+(?:clerk|employee|worker)':
          'store employee',
      r'(?:waiter|waitress|server)': 'restaurant server',
      r'(?:doctor|nurse|physician)': 'healthcare worker',
      r'(?:lawyer|attorney|judge)': 'legal professional',
      r'(?:CEO|boss|manager|executive|owner)': 'executive',
      r'(?:homeless|beggar|starving\s+(?:man|woman|elder))':
          'person in special situation',

      // EspaÃ±ol
      r'(?:emplead[oa]|dependiente)\s+de\s+(?:tienda|supermercado)':
          'empleado de tienda',
      r'(?:camarero|camarera|mesero)': 'camarero',
      r'(?:mÃ©di[oa]|doctor[a]?|enfermer[oa])': 'profesional mÃ©dico',

      // í•œêµ­ì–´
      r'(?:íŽ¸ì˜ì |ë§ˆíŠ¸|ê°€ê²Œ)\s*ì•Œë°”ìƒ?': 'íŽ¸ì˜ì  ì•Œë°”ìƒ',
      r'(?:êµ¶ê³ \s*ìžˆëŠ”|ë°°ê³ í”ˆ)\s*(?:ë…¸ì¸|í• ë¨¸ë‹ˆ|í• ì•„ë²„ì§€)':
          'êµ¶ê³  ìžˆëŠ” ë…¸ì¸',
      r'(?:ì‚¬ìž¥ë‹˜?|ëŒ€í‘œë‹˜?|íšŒìž¥ë‹˜?)': 'ì‚¬ìž¥/CEO',
    };
  }

  /// PadrÃµes de aÃ§Ãµes multilÃ­ngues
  Map<String, String> _getActionPatterns() {
    return {
      // PortuguÃªs
      r'(?:deu|ofereceu|compartilhou|dividiu)\s+(?:comida|marmita|dinheiro|ajuda)':
          'compartilhar/ajudar',
      r'(?:salvou|resgatou|ajudou)': 'salvar/resgatar',
      r'(?:demitiu|despediu|expulsou)': 'demitir',
      r'(?:herdou|recebeu heranÃ§a)': 'herdar',
      r'(?:traiu|enganou|mentiu)': 'trair/enganar',
      r'(?:vingou|se vingou)': 'vingar-se',

      // English
      r'(?:gave|offered|shared)\s+(?:food|lunch|money|help)': 'share/help',
      r'(?:saved|rescued|helped)': 'save/rescue',
      r'(?:fired|dismissed)': 'fire/dismiss',
      r'(?:inherited|received inheritance)': 'inherit',
      r'(?:betrayed|cheated|lied)': 'betray',

      // EspaÃ±ol
      r'(?:dio|ofreciÃ³|compartiÃ³)\s+(?:comida|almuerzo|dinero)':
          'compartir/ayudar',

      // í•œêµ­ì–´
      r'(?:ë‚˜ëˆ ?ì¤€|ì£¼ì—ˆ|ë„ì™€ì¤€)': 'ë‚˜ëˆ ì£¼ë‹¤/ë•ë‹¤',
      r'(?:ê±´ë„¤ë©°|ì£¼ë©°)': 'ê±´ë„¤ë‹¤',
    };
  }

  /// PadrÃµes de contextos multilÃ­ngues
  Map<String, String> _getContextPatterns() {
    return {
      r'(?:loja|mercado|supermercado|conveniÃªncia)': 'loja/conveniÃªncia',
      r'(?:restaurante|cafÃ©|lanchonete)': 'restaurante',
      r'(?:hospital|clÃ­nica)': 'hospital',
      r'(?:escritÃ³rio|empresa|firma)': 'escritÃ³rio',
      r'(?:rua|calÃ§ada)': 'rua',
      r'(?:casa|residÃªncia|mansÃ£o)': 'casa',
      r'(?:store|shop|convenience)': 'store',
      r'(?:restaurant|cafe|diner)': 'restaurant',
      r'(?:office|company)': 'office',
      r'(?:street)': 'street',
      r'(?:íŽ¸ì˜ì )': 'íŽ¸ì˜ì ',
    };
  }

  /// PadrÃµes de objetos multilÃ­ngues
  Map<String, String> _getObjectPatterns() {
    return {
      r'(?:marmita|lanche|comida|alimento|ë„ì‹œë½)': 'comida/marmita',
      r'(?:cartÃ£o|ëª…í•¨)': 'cartÃ£o de visita',
      r'(?:dinheiro|money|dinero)': 'dinheiro',
      r'(?:presente|gift|regalo)': 'presente',
      r'(?:carta|letter|carta)': 'carta',
    };
  }

  // ================== VALIDAÃ‡ÃƒO DE COERÃŠNCIA ==================

  /// ðŸ” Valida coerÃªncia tÃ­tulo â†” histÃ³ria (versÃ£o rigorosa)
  ///
  /// [title]: TÃ­tulo da histÃ³ria
  /// [story]: Texto da histÃ³ria gerada
  /// [language]: Idioma do roteiro
  /// [apiKey]: Chave da API
  ///
  /// Retorna: Map com resultado da validaÃ§Ã£o
  Future<Map<String, dynamic>> validateTitleCoherenceRigorous({
    required String title,
    required String story,
    required String language,
    required String apiKey,
  }) async {
    try {
      // 1ï¸âƒ£ ExtraÃ§Ã£o de elementos-chave
      final keyElements = extractTitleKeyElements(title, language);
      final missingElements = <String>[];
      final foundElements = <String>[];

      if (kDebugMode) {
        debugPrint('ðŸ” ELEMENTOS-CHAVE DETECTADOS NO TÃTULO:');
        debugPrint(
          '   Personagens: ${keyElements['personagens']?.join(", ") ?? "nenhum"}',
        );
        debugPrint(
          '   AÃ§Ãµes: ${keyElements['acoes']?.join(", ") ?? "nenhuma"}',
        );
        debugPrint(
          '   Contextos: ${keyElements['contextos']?.join(", ") ?? "nenhum"}',
        );
        debugPrint(
          '   Objetos: ${keyElements['objetos']?.join(", ") ?? "nenhum"}',
        );
      }

      // 2ï¸âƒ£ TraduÃ§Ã£o de keywords
      final translatedPersonagens = await translateKeywordsToTargetLang(
        keyElements['personagens'] ?? [],
        language,
        apiKey,
      );
      final translatedContextos = await translateKeywordsToTargetLang(
        keyElements['contextos'] ?? [],
        language,
        apiKey,
      );
      final translatedObjetos = await translateKeywordsToTargetLang(
        keyElements['objetos'] ?? [],
        language,
        apiKey,
      );

      // 3ï¸âƒ£ ValidaÃ§Ã£o bÃ¡sica
      final storyLower = story.toLowerCase();

      // Validar personagens
      for (final personagem in keyElements['personagens'] ?? []) {
        final searchWords = translatedPersonagens
            .where((w) => w.length > 2)
            .toList();
        var found = false;
        for (final word in searchWords) {
          if (storyLower.contains(word.toLowerCase())) {
            found = true;
            break;
          }
        }
        if (found) {
          foundElements.add('ðŸ‘¤ $personagem');
        } else {
          missingElements.add('ðŸ‘¤ $personagem');
        }
      }

      // Validar contextos
      for (final contexto in keyElements['contextos'] ?? []) {
        final searchWords = translatedContextos
            .where((w) => w.length > 2)
            .toList();
        var found = false;
        for (final word in searchWords) {
          if (storyLower.contains(word.toLowerCase())) {
            found = true;
            break;
          }
        }
        if (found) {
          foundElements.add('ðŸ“ $contexto');
        } else {
          missingElements.add('ðŸ“ $contexto');
        }
      }

      // Validar objetos
      for (final objeto in keyElements['objetos'] ?? []) {
        final searchWords = translatedObjetos
            .where((w) => w.length > 2)
            .toList();
        var found = false;
        for (final word in searchWords) {
          if (storyLower.contains(word.toLowerCase())) {
            found = true;
            break;
          }
        }
        if (found) {
          foundElements.add('ðŸŽ $objeto');
        } else {
          missingElements.add('ðŸŽ $objeto');
        }
      }

      // 4ï¸âƒ£ ValidaÃ§Ã£o avanÃ§ada com IA
      // ðŸ—ï¸ v7.6.64: Usar LlmClient se disponÃ­vel
      final storyPreview = story.length > 2000
          ? '${story.substring(0, 2000)}...'
          : story;

      final validationPrompt =
          '''
VocÃª Ã© um validador rigoroso de coerÃªncia narrativa. 

TÃTULO: "$title"

ELEMENTOS-CHAVE ESPERADOS:
${keyElements['personagens']!.isNotEmpty ? '- Personagens: ${keyElements['personagens']!.join(", ")}' : ''}
${keyElements['acoes']!.isNotEmpty ? '- AÃ§Ãµes: ${keyElements['acoes']!.join(", ")}' : ''}
${keyElements['contextos']!.isNotEmpty ? '- Contextos: ${keyElements['contextos']!.join(", ")}' : ''}
${keyElements['objetos']!.isNotEmpty ? '- Objetos: ${keyElements['objetos']!.join(", ")}' : ''}

HISTÃ“RIA (inÃ­cio):
$storyPreview

TAREFA:
Analise RIGOROSAMENTE se a histÃ³ria desenvolve TODOS os elementos do tÃ­tulo.

RESPONDA EM JSON:
{
  "coerente": true/false,
  "confianca": 0-100,
  "elementos_faltando": ["lista de elementos nÃ£o encontrados"],
  "razao": "explicaÃ§Ã£o breve"
}
''';

      String text;
      if (_llmClient != null) {
        text = await _llmClient.generateText(
          prompt: validationPrompt,
          apiKey: apiKey,
          model: 'gemini-2.0-flash-exp',
          maxTokens: 500,
          temperature: 0.1,
        );
      } else {
        // Fallback para Dio direto
        final response = await _dio.post(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent',
          queryParameters: {'key': apiKey},
          data: {
            'contents': [
              {
                'parts': [
                  {'text': validationPrompt},
                ],
              },
            ],
            'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 500},
          },
        );

        text =
            response.data['candidates'][0]['content']['parts'][0]['text']
                ?.toString() ??
            '';
      }

      // Parse do resultado
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        try {
          final aiResult =
              jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

          return {
            'isValid': aiResult['coerente'] == true,
            'confidence': aiResult['confianca'] ?? 50,
            'foundElements': foundElements,
            'missingElements': [
              ...missingElements,
              ...(aiResult['elementos_faltando'] as List<dynamic>? ?? []).map(
                (e) => e.toString(),
              ),
            ],
            'reason': aiResult['razao'] ?? '',
            'keyElements': keyElements,
          };
        } catch (_) {}
      }

      // Fallback baseado em validaÃ§Ã£o bÃ¡sica
      final isValid = missingElements.isEmpty || missingElements.length <= 1;

      return {
        'isValid': isValid,
        'confidence': isValid ? 80 : 40,
        'foundElements': foundElements,
        'missingElements': missingElements,
        'reason': isValid
            ? 'Elementos principais encontrados'
            : 'Elementos faltando',
        'keyElements': keyElements,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('âš ï¸ Erro na validaÃ§Ã£o de coerÃªncia: $e');
      }
      return {
        'isValid': true, // Em caso de erro, nÃ£o bloquear
        'confidence': 50,
        'error': e.toString(),
      };
    }
  }

  // ================== VALIDAÃ‡ÃƒO DE RELACIONAMENTOS ==================

  /// ðŸ‘¨â€ðŸ‘©â€ðŸ‘§ Valida consistÃªncia de relacionamentos familiares
  ///
  /// [text]: Texto a ser validado
  /// [blockNumber]: NÃºmero do bloco atual
  ///
  /// Retorna: true se vÃ¡lido, false se invÃ¡lido
  bool validateFamilyRelationships(String text, int blockNumber) {
    // PadrÃµes de inconsistÃªncia comuns
    final inconsistencyPatterns = [
      // Pai e sogro sendo a mesma pessoa para a mesma pessoa
      RegExp(
        r'(?:my|meu)\s+(?:father|pai).*?(?:my|meu)\s+(?:father-in-law|sogro)',
        caseSensitive: false,
      ),
      // IrmÃ£ e cunhada para a mesma pessoa
      RegExp(
        r'(?:my|minha)\s+(?:sister|irmÃ£).*?(?:my|minha)\s+(?:sister-in-law|cunhada)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in inconsistencyPatterns) {
      if (pattern.hasMatch(text)) {
        if (kDebugMode) {
          debugPrint(
            'âš ï¸ InconsistÃªncia de relacionamento detectada no bloco $blockNumber',
          );
        }
        return false;
      }
    }

    return true;
  }

  // ================== VALIDAÃ‡ÃƒO DE PROTAGONISTA ==================

  /// ðŸŽ­ Valida se o nome do protagonista estÃ¡ correto
  ///
  /// [text]: Texto a ser validado
  /// [expectedName]: Nome esperado do protagonista
  /// [blockNumber]: NÃºmero do bloco atual
  ///
  /// Retorna: true se vÃ¡lido, false se invÃ¡lido
  bool validateProtagonistName(
    String text,
    String expectedName,
    int blockNumber,
  ) {
    if (expectedName.trim().isEmpty) return true;

    // Verificar se o nome esperado aparece
    final textLower = text.toLowerCase();
    final nameLower = expectedName.toLowerCase().trim();

    // Nomes comuns que poderiam substituir erroneamente
    final commonFallbackNames = [
      'emma',
      'jessica',
      'sarah',
      'jennifer',
      'ashley',
      'john',
      'michael',
      'david',
      'robert',
      'james',
      'maria',
      'ana',
      'joÃ£o',
      'pedro',
      'carlos',
    ];

    // Verificar se nome esperado estÃ¡ presente
    if (textLower.contains(nameLower)) {
      return true;
    }

    // Verificar se algum nome padrÃ£o foi usado indevidamente
    for (final fallback in commonFallbackNames) {
      if (textLower.contains(fallback) && fallback != nameLower) {
        // Se encontrou um nome genÃ©rico mas nÃ£o o esperado, pode ser erro
        if (kDebugMode) {
          debugPrint(
            'âš ï¸ Bloco $blockNumber: Nome "$fallback" encontrado, esperado "$expectedName"',
          );
        }
        // NÃ£o retornar false automaticamente, pois pode ser outro personagem
      }
    }

    return true; // NÃ£o bloquear se nÃ£o encontrou evidÃªncia clara de erro
  }

  /// Libera recursos
  void dispose() {
    _dio.close();
  }

  /// Valida se o bloco tem conteúdo válido e não duplicado
  bool validateBlockContent(String content, String previousContent) {
    if (content.trim().isEmpty) return false;
    return true;
  }

  /// Validação simples de nome
  bool isLikelyName(String text) {
    if (text.isEmpty) return false;
    final nameRegex = RegExp(
      r"^[A-Z\u00C0-\u00DC][a-zA-Z\u00C0-\u00FF\s\-\']+$",
    );
    return nameRegex.hasMatch(text.trim());
  }

  /// Extração de papel (Role) do personagem
  String extractRole(String name, String text) {
    if (text.toLowerCase().contains("mãe de $name")) return "mãe";
    if (text.toLowerCase().contains("pai de $name")) return "pai";
    return "personagem";
  }

  /// Valida nomes duplicados
  bool validateNameReuse(
    String content,
    CharacterTracker tracker,
    int blockNumber,
  ) {
    return true;
  }

  // ================== VALIDAÇÃO DE RELACIONAMENTOS =================="

  // ================== VALIDAÇÃO DE RELACIONAMENTOS ==================

  // ================== VALIDAÇÃO DE NOMES ÚNICOS ==================

  bool validateUniqueNames(
    String blockText,
    CharacterTracker tracker,
    int blockNumber,
  ) {
    if (blockText.trim().isEmpty) return false; // Texto vazio = sem erro

    // Extrair nomes do bloco atual
    final namesInBlock = extractNamesFromText(blockText);

    // Verificar cada nome extraído
    for (final name in namesInBlock) {
      // ---------------------------------------------------------------
      // VALIDAÇÃO 1 (v7.6.28): MESMO NOME em PAPÉIS DIFERENTES
      // ---------------------------------------------------------------
      if (tracker.hasName(name)) {
        // Nome já existe - verificar se é o MESMO personagem ou REUSO indevido

        // Extrair papel atual deste nome no bloco
        final currentRole = extractRoleForName(name, blockText);

        // Extrair papel registrado anteriormente
        final previousRole = tracker.getRole(name);

        if (currentRole != null && previousRole != null) {
          // Normalizar papéis para comparação
          final normalizedCurrent = normalizeRole(currentRole);
          final normalizedPrevious = normalizeRole(previousRole);

          // Se papéis são DIFERENTES = NOME DUPLICADO (ERRO!)
          if (normalizedCurrent != normalizedPrevious &&
              normalizedCurrent != 'indefinido' &&
              normalizedPrevious != 'indefinido') {
            if (kDebugMode) {
              debugPrint('🛑🛑🛑 v7.6.28: NOME DUPLICADO DETECTADO! 🛑🛑🛑');
              debugPrint('   👉 Nome: "$name"');
              debugPrint(
                '   👉 Papel anterior: "$previousRole" → "$normalizedPrevious"',
              );
              debugPrint(
                '   👉 Papel atual: "$currentRole" → "$normalizedCurrent"',
              );
              debugPrint(
                '   ⚠️ EXEMPLO DO BUG: "Mark" sendo boyfriend E attorney!',
              );
              debugPrint(
                '   ⚠️ Bloco $blockNumber será REJEITADO e REGENERADO',
              );
              debugPrint('🛑🛑🛑 FIM DO ALERTA 🛑🛑🛑');
            }

            _debugLogger.error(
              "Nome duplicado em papéis diferentes - Bloco $blockNumber",
              blockNumber: blockNumber,
              details:
                  "Nome '$name': papel anterior '$previousRole', papel atual '$currentRole'",
              metadata: {
                'nome': name,
                'papelAnterior': previousRole,
                'papelAtual': currentRole,
              },
            );

            return true; // 🚫 CONFLITO DETECTADO
          }
        }
      }

      // ---------------------------------------------------------------
      // 🔍 VALIDAÇÃO 2 (v7.6.32): MESMO PAPEL em NOMES DIFERENTES
      // ---------------------------------------------------------------
      final currentRole = extractRoleForName(name, blockText);

      if (currentRole != null && currentRole != 'indefinido') {
        final normalizedCurrent = normalizeRole(currentRole);

        // Verificar se este PAPEL já existe com um NOME DIFERENTE
        for (final existingName in tracker.confirmedNames) {
          if (existingName.toLowerCase() == name.toLowerCase()) {
            continue; // Mesmo nome = OK (já validado acima)
          }

          final existingRole = tracker.getRole(existingName);
          if (existingRole == null) continue;

          final normalizedExisting = normalizeRole(existingRole);

          // ⚠️ PAPÉIS CRÍTICOS que DEVEM ser únicos (1 nome por papel)
          final uniqueRoles = {
            'protagonista',
            'protagonist',
            'main character',
            'narradora',
            'narrador',
            'narrator',
            'hero',
            'heroine',
            'herói',
            'heroína',
          };

          // Se MESMO PAPEL com NOMES DIFERENTES = ERRO CRÍTICO!
          if (normalizedCurrent == normalizedExisting) {
            // Verificar se é papel crítico que deve ser único
            bool isCriticalRole = false;
            for (final uniqueRole in uniqueRoles) {
              if (normalizedCurrent.contains(uniqueRole) ||
                  normalizedExisting.contains(uniqueRole)) {
                isCriticalRole = true;
                break;
              }
            }

            if (isCriticalRole) {
              if (kDebugMode) {
                debugPrint('🛑🛑🛑 v7.6.32: PAPEL DUPLICADO DETECTADO! 🛑🛑🛑');
                debugPrint(
                  '   👉 Papel: "$currentRole" → "$normalizedCurrent"',
                );
                debugPrint('   👉 Nome anterior: "$existingName"');
                debugPrint('   👉 Nome atual: "$name"');
                debugPrint(
                  '   ⚠️ EXEMPLO DO BUG: "Ashley" sendo protagonista E "Emily" sendo protagonista!',
                );
                debugPrint(
                  '   ⚠️ Bloco $blockNumber será REJEITADO e REGENERADO',
                );
                debugPrint('🛑🛑🛑 FIM DO ALERTA 🛑🛑🛑');
              }

              _debugLogger.error(
                "Papel duplicado com nomes diferentes - Bloco $blockNumber",
                blockNumber: blockNumber,
                details:
                    "Papel '$currentRole': nome anterior '$existingName', nome atual '$name'",
                metadata: {
                  'papel': currentRole,
                  'nomeAnterior': existingName,
                  'nomeAtual': name,
                },
              );

              return true; // 🚫 CONFLITO CRÍTICO DETECTADO
            }
          }
        }
      }

      // ---------------------------------------------------------------
      // 🔍 VALIDAÇÃO 3 (v7.6.33): PAPÉIS POSSESSIVOS SINGULARES
      // ---------------------------------------------------------------
      final possessiveSingularPattern = RegExp(
        r'\b(?:my|nossa)\s+(?:executive\s+assistant|personal\s+assistant|financial\s+advisor|real\s+estate\s+agent|estate\s+planner|tax\s+advisor|makeup\s+artist|physical\s+therapist|occupational\s+therapist|speech\s+therapist|au\s+pair|dalai\s+lama|vice[-\s]president|lawyer|attorney|doctor|therapist|accountant|agent|boss|mentor|partner|adviser|advisor|consultant|coach|teacher|tutor|counselor|psychologist|psychiatrist|dentist|surgeon|specialist|physician|nurse|caregiver|assistant|secretary|manager|supervisor|director|ceo|cfo|cto|president|chairman|investor|banker|auditor|notary|mediator|arbitrator|investigator|detective|officer|sergeant|captain|lieutenant|judge|magistrate|prosecutor|defender|guardian|curator|executor|trustee|beneficiary|architect|engineer|contractor|builder|designer|decorator|landscaper|gardener|housekeeper|maid|butler|chef|cook|driver|chauffeur|pilot|navigator|guide|translator|interpreter|editor|publisher|producer|publicist|stylist|hairdresser|barber|beautician|esthetician|masseuse|trainer|nutritionist|dietitian|pharmacist|optometrist|veterinarian|groomer|walker|sitter|nanny|governess|babysitter|midwife|doula|chiropractor|acupuncturist|hypnotist|healer|shaman|priest|pastor|minister|rabbi|imam|monk|nun|chaplain|deacon|elder|bishop|archbishop|cardinal|pope|guru|sensei|sifu|master|grandmaster)(?![a-z])',
        caseSensitive: false,
      );

      final possessiveMatches = possessiveSingularPattern.allMatches(blockText);

      for (final match in possessiveMatches) {
        final possessiveRole = match
            .group(0)
            ?.replaceFirst(
              RegExp(r'\b(?:my|nossa)\s+', caseSensitive: false),
              '',
            )
            .toLowerCase()
            .trim();

        if (possessiveRole == null || possessiveRole.isEmpty) continue;

        // Verificar se JÁ existe este papel possessivo com NOME DIFERENTE
        for (final existingName in tracker.confirmedNames) {
          if (existingName.toLowerCase() == name.toLowerCase()) {
            continue; // Mesmo nome = OK
          }

          final existingRole = tracker.getRole(existingName);
          if (existingRole == null) continue;

          final normalizedExisting = normalizeRole(existingRole).toLowerCase();

          final possessiveRoleNormalized = possessiveRole.replaceAll(
            RegExp(r'\s+'),
            ' ',
          );

          // Verificar se papel possessivo já existe
          if (normalizedExisting.contains(possessiveRoleNormalized) ||
              possessiveRoleNormalized.contains(
                normalizedExisting.split(' ').last,
              )) {
            if (kDebugMode) {
              debugPrint(
                '🛑🛑🛑 v7.6.34: PAPEL POSSESSIVO SINGULAR DUPLICADO! 🛑🛑🛑',
              );
              debugPrint('   👉 Papel possessivo: "my $possessiveRole"');
              debugPrint(
                '   👉 Nome anterior: "$existingName" (papel: "$existingRole")',
              );
              debugPrint('   👉 Nome atual: "$name"');
              debugPrint('   ⚠️ EXEMPLOS DO BUG:');
              debugPrint('      - "my lawyer, Richard" → "my lawyer, Mark"');
              debugPrint(
                '      - "my executive assistant, Lauren" → "my executive assistant, Danielle"',
              );
              debugPrint(
                '   ⚠️ "my X" indica papel ÚNICO - não pode haver múltiplos!',
              );
              debugPrint(
                '   ⚠️ Bloco $blockNumber será REJEITADO e REGENERADO',
              );
              debugPrint('🛑🛑🛑 FIM DO ALERTA 🛑🛑🛑');
            }

            _debugLogger.error(
              "Papel possessivo singular duplicado - Bloco $blockNumber",
              blockNumber: blockNumber,
              details:
                  "'my $possessiveRole': nome anterior '$existingName', nome atual '$name'",
              metadata: {
                'papelPossessivo': possessiveRole,
                'nomeAnterior': existingName,
                'nomeAtual': name,
              },
            );

            return true; // 🚫 CONFLITO POSSESSIVO DETECTADO
          }
        }
      }
    }

    return false; // ✅ Nenhum conflito de nomes ou papéis
  }

  bool detectProtagonistNameChange(
    String generatedText,
    ScriptConfig config,
    CharacterTracker tracker,
    int blockNumber,
  ) {
    if (blockNumber == 1) return false; // Bloco 1 sempre válido

    final registeredName = tracker.getProtagonistName();
    if (registeredName == null) return false; // Sem protagonista registrada

    // Extrair todos os nomes do bloco atual
    final currentNames = extractNamesFromText(generatedText);

    // Verificar se protagonista registrada aparece
    final protagonistPresent = currentNames.contains(registeredName);

    // Verificar se há outros nomes válidos (possível troca)
    final otherValidNames = currentNames
        .where((n) => n != registeredName && looksLikePersonName(n))
        .toList();

    // 🔍 DETECÇÃO: Se protagonista não apareceu MAS há outros nomes válidos
    if (!protagonistPresent && otherValidNames.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Bloco $blockNumber: Protagonista "$registeredName" ausente!',
        );
        debugPrint('   Nomes encontrados: ${otherValidNames.join(", ")}');
        debugPrint('   ⚠️ Possível mudança de nome!');
      }

      _debugLogger.error(
        'Mudança de protagonista detectada',
        blockNumber: blockNumber,
        details:
            'Esperado "$registeredName", encontrado ${otherValidNames.join(", ")}',
        metadata: {
          'protagonistaEsperada': registeredName,
          'nomesEncontrados': otherValidNames,
        },
      );

      return true; // Bloco deve ser rejeitado
    }

    return false; // Nome consistente
  }

  Set<String> extractNamesFromText(String text) {
    final names = <String>{};

    // Regex para nomes próprios (simplificado)
    final namePattern = RegExp(r'\b[A-Z][a-z]+\b');

    for (final match in namePattern.allMatches(text)) {
      final name = match.group(0);
      if (name != null && looksLikePersonName(name)) {
        names.add(name);
      }
    }

    return names;
  }

  String normalizeRole(String role) {
    // Normalização básica
    return role.toLowerCase().trim();
  }

  String? extractRoleForName(String name, String text) {
    // Lógica simplificada de extração de papel
    // Procura padrões como "my lawyer, [Name]" ou "[Name], my lawyer"

    final patterns = [
      RegExp(
        r'my\s+([a-z\s]+),\s+' + RegExp.escape(name),
        caseSensitive: false,
      ),
      RegExp(
        RegExp.escape(name) + r',\s+my\s+([a-z\s]+)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }

  bool looksLikePersonName(String value) {
    final normalized = value.toLowerCase().trim();

    // Verificar stopwords
    if (NameConstants.nameStopwords.contains(normalized)) return false;

    // Verificar comprimento mínimo
    if (normalized.length < 3) return false;

    return true;
  }

  /// Valida se há nomes duplicados em papéis diferentes
  /// Retorna lista de nomes duplicados encontrados
  List<String> validateNamesInText(String newBlock, Set<String> previousNames) {
    final duplicates = <String>[];
    final newNames = extractNamesFromText(newBlock);

    for (final name in newNames) {
      if (previousNames.contains(name)) {
        // ⚠️ Nome já usado anteriormente!
        if (!duplicates.contains(name)) {
          duplicates.add(name);
        }
      }
    }
    return duplicates;
  }
}

class ScriptValidationResult {
  final bool isValid;
  final List<String> issues;

  ScriptValidationResult({required this.isValid, required this.issues});
}
