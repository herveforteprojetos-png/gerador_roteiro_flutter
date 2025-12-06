// ignore: unused_import
import 'package:flutter/foundation.dart';

/// 📢 CtaGenerator - Geração de CTAs (Call-to-Action) para roteiros
///
/// Responsável por:
/// - Gerar CTAs personalizados para diferentes momentos do roteiro
/// - Validar consistência dos CTAs com o conteúdo
/// - Parsear respostas JSON de CTAs
///
/// Parte da refatoração SOLID do GeminiService v7.6.66
class CtaGenerator {
  /// Analisa contexto do roteiro para geração de CTAs
  static String buildContextAnalysisPrompt(
    String scriptContent,
    String language,
  ) {
    return '''
Analise rapidamente este roteiro em $language e identifique:
1. Tema principal (1-2 palavras)
2. Público-alvo (ex: jovens, adultos, famílias)
3. Tom (ex: motivacional, informativo, dramático)

Responda em formato simples: "Tema: X, Público: Y, Tom: Z"

ROTEIRO:
${scriptContent.substring(0, scriptContent.length > 1000 ? 1000 : scriptContent.length)}
''';
  }

  /// Retorna descrições dos tipos de CTA
  static Map<String, String> getCtaTypeDescriptions(String language) {
    return {
      'subscription': 'CTA para inscrição no canal',
      'engagement': 'CTA para interação (like, comentário)',
      'pre_conclusion': 'CTA antes da conclusão',
      'final': 'CTA de fechamento',
    };
  }

  /// Constrói o prompt avançado para geração de CTAs
  static String buildAdvancedCtaPrompt(
    String scriptContent,
    List<String> ctaTypes,
    String? customTheme,
    String language,
    String scriptContext,
    String perspective,
  ) {
    final ctaDescriptions = getCtaTypeDescriptions(language);
    final requestedTypes = ctaTypes
        .map(
          (type) =>
              '"$type": ${ctaDescriptions[type] ?? "Call-to-action personalizado"}',
        )
        .join('\n');

    final isPrimeiraPessoa = perspective.contains('primeira_pessoa');

    if (kDebugMode) {
      debugPrint('🎯 Perspectiva Configurada pelo Usuário: $perspective');
      debugPrint(
        '   → ${isPrimeiraPessoa ? "PRIMEIRA PESSOA" : "TERCEIRA PESSOA"}',
      );
    }

    final perspectiveInstruction = isPrimeiraPessoa
        ? _getFirstPersonInstructions()
        : _getThirdPersonInstructions();

    // Extrair trechos do roteiro
    final scriptLength = scriptContent.length;
    final initialChunk = scriptContent.substring(
      0,
      scriptLength > 2000 ? 2000 : scriptLength,
    );
    final finalChunk = scriptLength > 1500
        ? scriptContent.substring(scriptLength - 1500)
        : '';

    return _buildFullPrompt(
      language: language,
      perspectiveInstruction: perspectiveInstruction,
      scriptContext: scriptContext,
      customTheme: customTheme,
      initialChunk: initialChunk,
      finalChunk: finalChunk,
      requestedTypes: requestedTypes,
      isPrimeiraPessoa: isPrimeiraPessoa,
    );
  }

  /// Parseia resposta de CTAs com validação
  static Map<String, String> parseCtaResponseWithValidation(
    String response,
    List<String> ctaTypes,
    String scriptContent,
  ) {
    try {
      if (kDebugMode) {
        debugPrint(
          '🎯 CTA Response original: ${response.substring(0, response.length > 200 ? 200 : response.length)}...',
        );
      }

      // Remover markdown code blocks
      String cleanedResponse = response;
      cleanedResponse = cleanedResponse.replaceAll(RegExp(r'```json\s*'), '');
      cleanedResponse = cleanedResponse.replaceAll(RegExp(r'```\s*'), '');
      cleanedResponse = cleanedResponse.trim();

      // Extrair JSON
      final jsonStart = cleanedResponse.indexOf('{');
      final jsonEnd = cleanedResponse.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('Formato JSON não encontrado na resposta');
      }

      final jsonString = cleanedResponse.substring(jsonStart, jsonEnd + 1);
      
      final Map<String, String> ctas = {};
      for (final type in ctaTypes) {
        final pattern = '"$type"\\s*:\\s*"([^"]*(?:\\\\.[^"]*)*)"';
        final regex = RegExp(pattern, multiLine: true, dotAll: true);
        final match = regex.firstMatch(jsonString);
        
        if (match != null) {
          String ctaText = match.group(1) ?? '';
          ctaText = ctaText.replaceAll(RegExp(r'\s+'), ' ').trim();

          // Validar CTA final
          if (type == 'final' && scriptContent.isNotEmpty) {
            final inconsistency = validateFinalCtaConsistency(
              ctaText,
              scriptContent,
            );
            if (inconsistency != null) {
              if (kDebugMode) {
                debugPrint('⚠️ CTA final inconsistente: $inconsistency');
              }
              ctaText = _cleanInconsistentCta(ctaText);
            }
          }

          ctas[type] = ctaText;
          if (kDebugMode) {
            debugPrint(
              '✅ CTA extraído [$type]: ${ctaText.substring(0, ctaText.length > 50 ? 50 : ctaText.length)}...',
            );
          }
        }
      }

      return ctas;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao fazer parse dos CTAs: $e');
        debugPrint('Stack trace: $stack');
      }
      return {};
    }
  }

  /// Valida consistência do CTA final com o roteiro
  static String? validateFinalCtaConsistency(
    String finalCta,
    String scriptContent,
  ) {
    if (kDebugMode) {
      debugPrint('🔍 Validando consistência do CTA final...');
    }

    final inconsistencyChecks = [
      {
        'pattern': RegExp(
          r'behind bars|atrás das grades|na cadeia|preso|imprisoned|arrested|jail',
          caseSensitive: false,
        ),
        'requiredInScript': RegExp(
          r'foi preso|was arrested|prisão|prison|cadeia|jail|condenado|sentenced|behind bars|atrás das grades',
          caseSensitive: false,
        ),
        'errorMessage':
            'CTA menciona prisão, mas roteiro não indica que alguém foi preso',
      },
      {
        'pattern': RegExp(
          r"he's dead|ela? morreu|she's dead|morte del[ea]|death|dead",
          caseSensitive: false,
        ),
        'requiredInScript': RegExp(
          r'morreu|died|death|funeral|enterro|corpo|body|faleceu|passed away',
          caseSensitive: false,
        ),
        'errorMessage':
            'CTA menciona morte, mas roteiro não indica que alguém morreu',
      },
      {
        'pattern': RegExp(
          r'lost everything|perdi tudo|left with nothing|fiquei sem nada',
          caseSensitive: false,
        ),
        'requiredInScript': RegExp(
          r'perdi tudo|lost everything|nada restou|nothing left|destruíd[oa]',
          caseSensitive: false,
        ),
        'errorMessage':
            'CTA menciona perda total, mas roteiro sugere vitória ou recuperação',
      },
    ];

    for (final check in inconsistencyChecks) {
      final pattern = check['pattern'] as RegExp;
      final required = check['requiredInScript'] as RegExp;
      final errorMsg = check['errorMessage'] as String;

      if (pattern.hasMatch(finalCta)) {
        if (!required.hasMatch(scriptContent)) {
          if (kDebugMode) {
            debugPrint('⚠️ INCONSISTÊNCIA DETECTADA: $errorMsg');
          }
          return errorMsg;
        }
      }
    }

    if (kDebugMode) {
      debugPrint('✅ CTA final validado - sem inconsistências detectadas');
    }
    return null;
  }

  // ============ MÉTODOS PRIVADOS ============

  static String _cleanInconsistentCta(String ctaText) {
    var cleaned = ctaText;
    cleaned = cleaned.replaceAll(
      RegExp(
        'He.s behind bars[^.]*\\.|Ele está preso[^.]*\\.',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(
        'behind bars[^,]*,?|atrás das grades[^,]*,?',
        caseSensitive: false,
      ),
      '',
    );
    return cleaned.trim();
  }

  static String _getFirstPersonInstructions() {
    return '''
╔════════════════════════════════════════════════════════════════╗
║ ⚠️ OBRIGATÓRIO: PRIMEIRA PESSOA - NARRADOR = PROTAGONISTA     ║
╚════════════════════════════════════════════════════════════════╝

O NARRADOR É O PROTAGONISTA CONTANDO SUA PRÓPRIA HISTÓRIA.

🚨 REGRA ABSOLUTA: CTAs devem falar como se o PERSONAGEM estivesse pedindo apoio.

✅ CAPITALIZAÇÃO CORRETA:
- "eu", "meu/minha" (MINÚSCULAS no meio da frase!)
- "Eu" (Maiúscula APENAS no início da frase)
- ❌ ERRADO: "EU pensei", "MEU filho", "MINHA casa"
- ✅ CERTO: "Eu pensei", "meu filho", "minha casa"

✅ PALAVRAS OBRIGATÓRIAS:
- "eu", "meu/minha", "minha história", "meu relato", "comigo", "me"

✅ EXEMPLOS CORRETOS (Primeira Pessoa):
• CTA INÍCIO: "Eu estava sem-teto e herdei 47 milhões. Mas a fortuna veio com um diário de vingança. Inscreva-se e deixe seu like para ver onde isso me levou."
• CTA MEIO: "O que você faria no meu lugar? Descobri que meu tio foi traído pelo próprio irmão. Comente o que você acha e compartilhe."
• CTA FINAL: "Minha jornada da rua à redenção acabou. O que você achou dessa reviravolta? Inscreva-se para mais histórias intensas como esta."

❌ PROIBIDO (quebra a perspectiva):
• Falar sobre "o protagonista", "ele/ela", "a história dele/dela"
• Usar "esta história" → Use "minha história"
• Capitalizar tudo: "EU/MEU/MINHA" → Use "eu/meu/minha"
''';
  }

  static String _getThirdPersonInstructions() {
    return '''
╔════════════════════════════════════════════════════════════════╗
║ ⚠️ OBRIGATÓRIO: TERCEIRA PESSOA - NARRADOR EXTERNO ENVOLVENTE ║
╚════════════════════════════════════════════════════════════════╝

O NARRADOR É UM OBSERVADOR EXTERNO contando a história de outras pessoas.

🚨 REGRA ABSOLUTA: CTAs devem falar dos PERSONAGENS de forma externa, MAS mantendo a INTENSIDADE EMOCIONAL do roteiro!

✅ CAPITALIZAÇÃO CORRETA:
- "esta/esse/essa" (minúsculas no meio da frase!)
- Nomes próprios sempre com inicial maiúscula: "Kátia", "William"

✅ PALAVRAS OBRIGATÓRIAS:
- Nomes dos personagens (Kátia, William, etc.)
- "ela/dele", "esta história"
- Tom DRAMÁTICO, não jornalístico!

✅ EXEMPLOS CORRETOS (Terceira Pessoa ENVOLVENTE):
• "Kátia descobriu que seu próprio filho transformou sua casa em uma arma. Se esta traição te chocou, inscreva-se e deixe seu like"
• "William escondeu segredos nas paredes por anos. O que você faria no lugar de Kátia? Comente o que está achando"
• "A história de Kátia chegou ao fim com um desfecho poderoso. O que você achou? Inscreva-se para mais histórias como esta"

❌ PROIBIDO (quebra a perspectiva):
• Usar "eu", "meu/minha", "comigo" → Isso é primeira pessoa!
• "Se minha história te tocou" → Use "Se a história de [personagem] te tocou"

🔥 REGRA DE OURO: Use DETALHES ESPECÍFICOS DO ROTEIRO nos CTAs!
''';
  }

  static String _buildFullPrompt({
    required String language,
    required String perspectiveInstruction,
    required String scriptContext,
    required String? customTheme,
    required String initialChunk,
    required String finalChunk,
    required String requestedTypes,
    required bool isPrimeiraPessoa,
  }) {
    return '''
🚨🚨🚨 REGRA #0: IDIOMA OBRIGATÓRIO - $language 🚨🚨🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ TODOS os CTAs DEVEM estar 100% em $language.
🔴 SE HOUVER UMA ÚNICA PALAVRA EM OUTRO IDIOMA, TODOS OS CTAs SERÃO REJEITADOS!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️⚠️⚠️ ATENÇÃO CRÍTICA: PERSPECTIVA NARRATIVA É A REGRA #1 ⚠️⚠️⚠️

$perspectiveInstruction

═══════════════════════════════════════════════════════════════

Gere CTAs (calls-to-action) personalizados em $language para este roteiro.

CONTEXTO DO ROTEIRO: $scriptContext
TEMA PERSONALIZADO: ${customTheme ?? 'Não especificado'}

ROTEIRO - TRECHO INICIAL (para CTAs de início/meio):
$initialChunk

${finalChunk.isNotEmpty ? '''
═══════════════════════════════════════════════════════════════
ROTEIRO - TRECHO FINAL (para CTA de conclusão):
$finalChunk
═══════════════════════════════════════════════════════════════
''' : ''}

═══════════════════════════════════════════════════════════════
🎯 PROPÓSITO ESPECÍFICO DE CADA TIPO DE CTA:
═══════════════════════════════════════════════════════════════

📌 "subscription" (CTA DE INÍCIO):
   • Objetivo: Pedir INSCRIÇÃO no canal + LIKE
   • Momento: Logo no INÍCIO da história, após o gancho inicial
   • Extrair 2-3 detalhes específicos dos primeiros parágrafos
   • NÃO REPETIR a primeira frase do roteiro!

📌 "engagement" (CTA DE MEIO):
   • Objetivo: Pedir COMENTÁRIOS + COMPARTILHAMENTOS
   • Momento: No MEIO da história, após uma reviravolta
   • Fazer pergunta direta sobre opinião

📌 "final" (CTA DE CONCLUSÃO):
   • Objetivo: FEEDBACK + INSCRIÇÃO para mais histórias
   • Momento: No FINAL da história, após a resolução
   • Deve refletir o DESFECHO REAL (vitória/derrota/recomeço)

═══════════════════════════════════════════════════════════════

GERE OS SEGUINTES TIPOS DE CTA:
$requestedTypes

═══════════════════════════════════════════════════════════════

FORMATO DE RESPOSTA (JSON):
{
  "subscription": "texto do CTA aqui",
  "engagement": "texto do CTA aqui",
  "pre_conclusion": "texto do CTA aqui",
  "final": "texto do CTA aqui"
}

═══════════════════════════════════════════════════════════════

REQUISITOS OBRIGATÓRIOS:
1. ⚠️ PERSPECTIVA NARRATIVA É PRIORIDADE #1
2. ⚠️ CAPITALIZAÇÃO CORRETA - "eu/meu/minha" em MINÚSCULAS
3. 🎯 CADA CTA TEM UM PROPÓSITO ESPECÍFICO
4. 🔥 CTA DE INÍCIO: Extraia detalhes REAIS do TRECHO INICIAL
5. 🔥 CTA FINAL: Use o TRECHO FINAL e reflita o DESFECHO REAL
6. 🚫 PROIBIDO usar palavras genéricas: "jornada", "narrativa", "explorar"
7. ✅ Cada CTA: 25-45 palavras
8. Linguagem VISCERAL e DRAMÁTICA em $language
9. Retorne JSON válido apenas

⚠️⚠️⚠️ CHECKLIST FINAL: ⚠️⚠️⚠️
□ TODOS os CTAs estão 100% em $language?
□ ${isPrimeiraPessoa ? "Vou usar 'eu/meu/minha' em MINÚSCULAS?" : "Vou usar nomes próprios/ela/ele/esta história?"}
□ Cada CTA segue seu PROPÓSITO ESPECÍFICO?
□ Formato JSON está correto?

🚨 SE VOCÊ USAR LINGUAGEM GENÉRICA OU MISTURAR IDIOMAS, O CTA SERÁ REJEITADO! 🚨
''';
  }
}
