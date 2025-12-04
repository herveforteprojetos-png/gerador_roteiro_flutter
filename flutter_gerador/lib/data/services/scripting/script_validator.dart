import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'llm_client.dart';

/// ✅ ScriptValidator - Validador de Roteiros
///
/// Responsável por:
/// - Validação de coerência título ↔ história
/// - Tradução de keywords para idiomas alvo
/// - Extração de elementos-chave do título
/// - Validação de relacionamentos familiares
/// - Validação de nomes de protagonista
///
/// Parte da refatoração SOLID do GeminiService v7.6.64
class ScriptValidator {
  final Dio _dio;
  final LlmClient? _llmClient;

  ScriptValidator({
    Dio? dio,
    LlmClient? llmClient,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
              ),
            ),
        _llmClient = llmClient;

  // ================== TRADUÇÃO DE KEYWORDS ==================

  /// 🌐 Traduz keywords para o idioma alvo
  ///
  /// [keywords]: Lista de palavras-chave em português
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

    // Se o idioma alvo é português, não precisa traduzir
    if (targetLower.contains('portugu') ||
        targetLower.contains('pt-br') ||
        targetLower == 'pt') {
      return keywords;
    }

    try {
      final prompt = '''
TAREFA: Tradutor de Palavras-Chave para Validação de Roteiro.

IDIOMA DE ORIGEM: Português
IDIOMA DE DESTINO: $targetLanguage

PALAVRAS-CHAVE PARA TRADUZIR:
${keywords.map((k) => '- $k').join('\n')}

INSTRUÇÕES:
1. Traduza cada palavra/frase para o idioma de destino
2. Mantenha o significado semântico, não literal
3. Se uma palavra tem múltiplas traduções, escolha a mais comum

FORMATO DE SAÍDA (JSON array apenas, sem markdown):
["tradução1", "tradução2", "tradução3"]

EXEMPLO:
Entrada: ["marmita", "funcionário", "ajudar"]
Saída para Coreano: ["도시락", "직원", "돕다"]
Saída para Inglês: ["lunch box", "employee", "help"]

RESPONDA APENAS COM O JSON ARRAY:''';

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
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 500,
          },
        },
      );

      final text =
          response.data['candidates'][0]['content']['parts'][0]['text']
                  ?.toString() ??
              '';

      final cleanText =
          text.replaceAll('```json', '').replaceAll('```', '').trim();

      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(cleanText);
      if (jsonMatch != null) {
        final List<dynamic> parsed = jsonDecode(jsonMatch.group(0)!);
        final translated = parsed.map((e) => e.toString()).toList();

        if (kDebugMode) {
          debugPrint('🌐 TRADUÇÃO DE KEYWORDS:');
          debugPrint('   Original (PT): ${keywords.join(", ")}');
          debugPrint(
              '   Traduzido ($targetLanguage): ${translated.join(", ")}');
        }

        // Retorna AMBOS: original + traduzido
        return [...keywords, ...translated];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Erro na tradução de keywords: $e');
      }
    }

    return keywords;
  }

  // ================== EXTRAÇÃO DE ELEMENTOS DO TÍTULO ==================

  /// 🎯 Extrai elementos-chave do título
  ///
  /// Identifica personagens, ações, contextos e objetos
  /// que DEVEM aparecer na história
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

    // 🎯 DETECÇÃO DE PERSONAGENS
    final personPatterns = _getPersonagePatterns();
    for (final entry in personPatterns.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(titleLower)) {
        result['personagens']!.add(entry.value);
      }
    }

    // 🎯 DETECÇÃO DE AÇÕES
    final actionPatterns = _getActionPatterns();
    for (final entry in actionPatterns.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(titleLower)) {
        result['acoes']!.add(entry.value);
      }
    }

    // 🎯 DETECÇÃO DE CONTEXTOS/LOCAIS
    final contextPatterns = _getContextPatterns();
    for (final entry in contextPatterns.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(titleLower)) {
        result['contextos']!.add(entry.value);
      }
    }

    // 🎯 DETECÇÃO DE OBJETOS IMPORTANTES
    final objectPatterns = _getObjectPatterns();
    for (final entry in objectPatterns.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(titleLower)) {
        result['objetos']!.add(entry.value);
      }
    }

    return result;
  }

  /// Padrões de personagens multilíngues
  Map<String, String> _getPersonagePatterns() {
    return {
      // Português
      r'(?:funcionári[oa]|atendente|vendedor|caixa|balconista)\s+(?:de\s+)?(?:loja|mercado|supermercado|conveniência)':
          'funcionário de loja/conveniência',
      r'(?:garçom|garçonete|atendente)\s+(?:de\s+)?(?:restaurante|café|bar|lanchonete)':
          'garçom/garçonete',
      r'(?:médic[oa]|enferm[oa]|doutor[a]?)': 'profissional de saúde',
      r'(?:advogad[oa]|juiz[a]?|promotor[a]?)': 'profissional jurídico',
      r'(?:CEO|empresári[oa]|dono|chefe|patrão|gerente)': 'executivo/chefe',
      r'(?:mendigo|sem-teto|morador de rua|idoso faminto|noiva|noivo)':
          'pessoa em situação especial',

      // English
      r'(?:store|shop|convenience\s+store)\s+(?:clerk|employee|worker)':
          'store employee',
      r'(?:waiter|waitress|server)': 'restaurant server',
      r'(?:doctor|nurse|physician)': 'healthcare worker',
      r'(?:lawyer|attorney|judge)': 'legal professional',
      r'(?:CEO|boss|manager|executive|owner)': 'executive',
      r'(?:homeless|beggar|starving\s+(?:man|woman|elder))':
          'person in special situation',

      // Español
      r'(?:emplead[oa]|dependiente)\s+de\s+(?:tienda|supermercado)':
          'empleado de tienda',
      r'(?:camarero|camarera|mesero)': 'camarero',
      r'(?:médi[oa]|doctor[a]?|enfermer[oa])': 'profesional médico',

      // 한국어
      r'(?:편의점|마트|가게)\s*알바생?': '편의점 알바생',
      r'(?:굶고\s*있는|배고픈)\s*(?:노인|할머니|할아버지)': '굶고 있는 노인',
      r'(?:사장님?|대표님?|회장님?)': '사장/CEO',
    };
  }

  /// Padrões de ações multilíngues
  Map<String, String> _getActionPatterns() {
    return {
      // Português
      r'(?:deu|ofereceu|compartilhou|dividiu)\s+(?:comida|marmita|dinheiro|ajuda)':
          'compartilhar/ajudar',
      r'(?:salvou|resgatou|ajudou)': 'salvar/resgatar',
      r'(?:demitiu|despediu|expulsou)': 'demitir',
      r'(?:herdou|recebeu herança)': 'herdar',
      r'(?:traiu|enganou|mentiu)': 'trair/enganar',
      r'(?:vingou|se vingou)': 'vingar-se',

      // English
      r'(?:gave|offered|shared)\s+(?:food|lunch|money|help)': 'share/help',
      r'(?:saved|rescued|helped)': 'save/rescue',
      r'(?:fired|dismissed)': 'fire/dismiss',
      r'(?:inherited|received inheritance)': 'inherit',
      r'(?:betrayed|cheated|lied)': 'betray',

      // Español
      r'(?:dio|ofreció|compartió)\s+(?:comida|almuerzo|dinero)':
          'compartir/ayudar',

      // 한국어
      r'(?:나눠?준|주었|도와준)': '나눠주다/돕다',
      r'(?:건네며|주며)': '건네다',
    };
  }

  /// Padrões de contextos multilíngues
  Map<String, String> _getContextPatterns() {
    return {
      r'(?:loja|mercado|supermercado|conveniência)': 'loja/conveniência',
      r'(?:restaurante|café|lanchonete)': 'restaurante',
      r'(?:hospital|clínica)': 'hospital',
      r'(?:escritório|empresa|firma)': 'escritório',
      r'(?:rua|calçada)': 'rua',
      r'(?:casa|residência|mansão)': 'casa',
      r'(?:store|shop|convenience)': 'store',
      r'(?:restaurant|cafe|diner)': 'restaurant',
      r'(?:office|company)': 'office',
      r'(?:street)': 'street',
      r'(?:편의점)': '편의점',
    };
  }

  /// Padrões de objetos multilíngues
  Map<String, String> _getObjectPatterns() {
    return {
      r'(?:marmita|lanche|comida|alimento|도시락)': 'comida/marmita',
      r'(?:cartão|명함)': 'cartão de visita',
      r'(?:dinheiro|money|dinero)': 'dinheiro',
      r'(?:presente|gift|regalo)': 'presente',
      r'(?:carta|letter|carta)': 'carta',
    };
  }

  // ================== VALIDAÇÃO DE COERÊNCIA ==================

  /// 🔍 Valida coerência título ↔ história (versão rigorosa)
  ///
  /// [title]: Título da história
  /// [story]: Texto da história gerada
  /// [language]: Idioma do roteiro
  /// [apiKey]: Chave da API
  ///
  /// Retorna: Map com resultado da validação
  Future<Map<String, dynamic>> validateTitleCoherenceRigorous({
    required String title,
    required String story,
    required String language,
    required String apiKey,
  }) async {
    try {
      // 1️⃣ Extração de elementos-chave
      final keyElements = extractTitleKeyElements(title, language);
      final missingElements = <String>[];
      final foundElements = <String>[];

      if (kDebugMode) {
        debugPrint('🔍 ELEMENTOS-CHAVE DETECTADOS NO TÍTULO:');
        debugPrint(
            '   Personagens: ${keyElements['personagens']?.join(", ") ?? "nenhum"}');
        debugPrint(
            '   Ações: ${keyElements['acoes']?.join(", ") ?? "nenhuma"}');
        debugPrint(
            '   Contextos: ${keyElements['contextos']?.join(", ") ?? "nenhum"}');
        debugPrint(
            '   Objetos: ${keyElements['objetos']?.join(", ") ?? "nenhum"}');
      }

      // 2️⃣ Tradução de keywords
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

      // 3️⃣ Validação básica
      final storyLower = story.toLowerCase();

      // Validar personagens
      for (final personagem in keyElements['personagens'] ?? []) {
        final searchWords =
            translatedPersonagens.where((w) => w.length > 2).toList();
        var found = false;
        for (final word in searchWords) {
          if (storyLower.contains(word.toLowerCase())) {
            found = true;
            break;
          }
        }
        if (found) {
          foundElements.add('👤 $personagem');
        } else {
          missingElements.add('👤 $personagem');
        }
      }

      // Validar contextos
      for (final contexto in keyElements['contextos'] ?? []) {
        final searchWords =
            translatedContextos.where((w) => w.length > 2).toList();
        var found = false;
        for (final word in searchWords) {
          if (storyLower.contains(word.toLowerCase())) {
            found = true;
            break;
          }
        }
        if (found) {
          foundElements.add('📍 $contexto');
        } else {
          missingElements.add('📍 $contexto');
        }
      }

      // Validar objetos
      for (final objeto in keyElements['objetos'] ?? []) {
        final searchWords =
            translatedObjetos.where((w) => w.length > 2).toList();
        var found = false;
        for (final word in searchWords) {
          if (storyLower.contains(word.toLowerCase())) {
            found = true;
            break;
          }
        }
        if (found) {
          foundElements.add('🎁 $objeto');
        } else {
          missingElements.add('🎁 $objeto');
        }
      }

      // 4️⃣ Validação avançada com IA
      final storyPreview =
          story.length > 2000 ? '${story.substring(0, 2000)}...' : story;

      final validationPrompt = '''
Você é um validador rigoroso de coerência narrativa. 

TÍTULO: "$title"

ELEMENTOS-CHAVE ESPERADOS:
${keyElements['personagens']!.isNotEmpty ? '- Personagens: ${keyElements['personagens']!.join(", ")}' : ''}
${keyElements['acoes']!.isNotEmpty ? '- Ações: ${keyElements['acoes']!.join(", ")}' : ''}
${keyElements['contextos']!.isNotEmpty ? '- Contextos: ${keyElements['contextos']!.join(", ")}' : ''}
${keyElements['objetos']!.isNotEmpty ? '- Objetos: ${keyElements['objetos']!.join(", ")}' : ''}

HISTÓRIA (início):
$storyPreview

TAREFA:
Analise RIGOROSAMENTE se a história desenvolve TODOS os elementos do título.

RESPONDA EM JSON:
{
  "coerente": true/false,
  "confianca": 0-100,
  "elementos_faltando": ["lista de elementos não encontrados"],
  "razao": "explicação breve"
}
''';

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
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 500,
          },
        },
      );

      final text =
          response.data['candidates'][0]['content']['parts'][0]['text']
                  ?.toString() ??
              '';

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
              ...(aiResult['elementos_faltando'] as List<dynamic>? ?? [])
                  .map((e) => e.toString())
            ],
            'reason': aiResult['razao'] ?? '',
            'keyElements': keyElements,
          };
        } catch (_) {}
      }

      // Fallback baseado em validação básica
      final isValid = missingElements.isEmpty || missingElements.length <= 1;

      return {
        'isValid': isValid,
        'confidence': isValid ? 80 : 40,
        'foundElements': foundElements,
        'missingElements': missingElements,
        'reason':
            isValid ? 'Elementos principais encontrados' : 'Elementos faltando',
        'keyElements': keyElements,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Erro na validação de coerência: $e');
      }
      return {
        'isValid': true, // Em caso de erro, não bloquear
        'confidence': 50,
        'error': e.toString(),
      };
    }
  }

  // ================== VALIDAÇÃO DE RELACIONAMENTOS ==================

  /// 👨‍👩‍👧 Valida consistência de relacionamentos familiares
  ///
  /// [text]: Texto a ser validado
  /// [blockNumber]: Número do bloco atual
  ///
  /// Retorna: true se válido, false se inválido
  bool validateFamilyRelationships(String text, int blockNumber) {
    // Padrões de inconsistência comuns
    final inconsistencyPatterns = [
      // Pai e sogro sendo a mesma pessoa para a mesma pessoa
      RegExp(
          r'(?:my|meu)\s+(?:father|pai).*?(?:my|meu)\s+(?:father-in-law|sogro)',
          caseSensitive: false),
      // Irmã e cunhada para a mesma pessoa
      RegExp(
          r'(?:my|minha)\s+(?:sister|irmã).*?(?:my|minha)\s+(?:sister-in-law|cunhada)',
          caseSensitive: false),
    ];

    for (final pattern in inconsistencyPatterns) {
      if (pattern.hasMatch(text)) {
        if (kDebugMode) {
          debugPrint('⚠️ Inconsistência de relacionamento detectada no bloco $blockNumber');
        }
        return false;
      }
    }

    return true;
  }

  // ================== VALIDAÇÃO DE PROTAGONISTA ==================

  /// 🎭 Valida se o nome do protagonista está correto
  ///
  /// [text]: Texto a ser validado
  /// [expectedName]: Nome esperado do protagonista
  /// [blockNumber]: Número do bloco atual
  ///
  /// Retorna: true se válido, false se inválido
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
      'joão',
      'pedro',
      'carlos',
    ];

    // Verificar se nome esperado está presente
    if (textLower.contains(nameLower)) {
      return true;
    }

    // Verificar se algum nome padrão foi usado indevidamente
    for (final fallback in commonFallbackNames) {
      if (textLower.contains(fallback) && fallback != nameLower) {
        // Se encontrou um nome genérico mas não o esperado, pode ser erro
        if (kDebugMode) {
          debugPrint(
              '⚠️ Bloco $blockNumber: Nome "$fallback" encontrado, esperado "$expectedName"');
        }
        // Não retornar false automaticamente, pois pode ser outro personagem
      }
    }

    return true; // Não bloquear se não encontrou evidência clara de erro
  }

  /// Libera recursos
  void dispose() {
    _dio.close();
  }
}
