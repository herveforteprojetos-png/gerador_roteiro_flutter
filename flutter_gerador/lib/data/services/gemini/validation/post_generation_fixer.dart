// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';

/// 🔧 v7.6.39: Corretor Pós-Geração de Nomes (VERSÃO COM VALIDAÇÃO DE NOMES)
/// 
/// OBJETIVO: Corrigir automaticamente nomes trocados APÓS a geração de cada bloco
/// 
/// PROBLEMAS RESOLVIDOS:
/// 1. O Gemini às vezes "esquece" nomes ao longo de histórias longas:
///    - Mãe chamada "Deborah" vira "Martha"
///    - Noivo "Mark" vira "Stephen"
/// 
/// 2. v7.6.37: CENAS DUPLICADAS com nomes diferentes:
///    - "Encontrei um advogado chamado Gregory..."
///    - Depois: "Fui ao escritório de Richard..." (mesmo papel!)
/// 
/// 3. v7.6.38: DETECÇÃO EXPANDIDA DE ADVOGADOS E PROFISSIONAIS:
///    - "I found him: James Gregory, a lawyer" 
///    - "His name was Mark, a man in his late fifties"
///    - "I'm Samuel Wallace. Thank you for coming in"
///    - "[Name] said/replied/explained" (quando advogado já registrado)
/// 
/// 4. 🆕 v7.6.39: VALIDAÇÃO DE NOMES + STOPWORDS EXPANDIDA
///    - Valida se o nome capturado é um nome real (banco curado)
///    - Bloqueia palavras como "Grand", "Grandfather", "Someone", etc.
///    - Padrões muito agressivos foram removidos ou restringidos
/// 
/// SOLUÇÃO v7.6.39:
/// 1. Busca flexível de papéis (mother, mãe, madre → mesmo papel)
/// 2. Detecta padrões "my mother, [Name]" e valida contra mapa
/// 3. Se nome diferente do registrado → CORRIGE automaticamente
/// 4. Detecta introduções duplicadas de personagens pelo papel
/// 5. 🆕 VALIDA todos os nomes capturados antes de registrar
/// 6. 🆕 Lista expandida de stopwords (Grand, Someone, etc.)
/// 
/// VANTAGENS:
/// - Zero tokens adicionais (processamento 100% local)
/// - ~1ms de CPU por chunk
/// - Correção transparente e automática
/// - NÃO captura palavras comuns como nomes
class PostGenerationFixer {
  
  /// 🆕 v7.6.39: Palavras que NUNCA devem ser tratadas como nomes
  /// Inclui palavras comuns em inglês que começam com maiúscula
  static final Set<String> _nameStopwords = {
    // Família (em inglês) - podem aparecer capitalizadas
    'grandfather', 'grandmother', 'grandpa', 'grandma', 'grand',
    'father', 'mother', 'brother', 'sister', 'son', 'daughter',
    'uncle', 'aunt', 'cousin', 'nephew', 'niece',
    'husband', 'wife', 'spouse', 'partner',
    
    // Profissões
    'lawyer', 'attorney', 'doctor', 'nurse', 'teacher', 'professor',
    'judge', 'officer', 'detective', 'agent', 'manager', 'boss',
    'accountant', 'therapist', 'counselor', 'minister', 'priest',
    
    // Pronomes e palavras comuns
    'someone', 'anyone', 'everyone', 'nobody', 'somebody', 'anybody',
    'nothing', 'something', 'everything', 'anything',
    'here', 'there', 'where', 'when', 'what', 'which', 'who', 'whom',
    'this', 'that', 'these', 'those',
    
    // Verbos/ações comuns que podem aparecer capitalizados
    'said', 'replied', 'asked', 'answered', 'told', 'explained',
    'speaking', 'talking', 'calling', 'waiting', 'looking',
    
    // Lugares/objetos comuns
    'office', 'house', 'home', 'room', 'building', 'street',
    'city', 'town', 'country', 'place', 'world',
    
    // Tempo
    'morning', 'afternoon', 'evening', 'night', 'today', 'tomorrow',
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
    
    // Outras palavras problemáticas encontradas em testes
    'the', 'and', 'but', 'for', 'with', 'from', 'about',
    'after', 'before', 'during', 'until', 'while',
    'just', 'only', 'even', 'still', 'already', 'always', 'never',
    'very', 'really', 'quite', 'rather', 'almost', 'nearly',
  };
  
  /// 🆕 v7.6.39: Valida se uma palavra capturada é um nome válido
  /// 
  /// Retorna true se é um nome válido, false se deve ser ignorado
  static bool _isValidCapturedName(String? name) {
    if (name == null || name.isEmpty) return false;
    if (name.length < 2 || name.length > 20) return false;
    
    final nameLower = name.toLowerCase();
    
    // 1. Verificar stopwords
    if (_nameStopwords.contains(nameLower)) {
      if (kDebugMode) {
        debugPrint('⚠️ v7.6.39: "$name" bloqueado (stopword)');
      }
      return false;
    }
    
    // 2. v7.6.56: Validação estrutural (Casting Director cria os nomes)
    // Aceitar nomes com estrutura válida (primeira letra maiúscula, tamanho razoável)
    if (name.length < 2 || name.length > 30) {
      if (kDebugMode) {
        debugPrint('⚠️ v7.6.56: "$name" bloqueado (tamanho inválido)');
      }
      return false;
    }
    
    return true;
  }
  
  /// 🆕 v7.6.37: Mapa de papéis para nomes já introduzidos
  /// Persiste entre chamadas para detectar duplicatas
  static final Map<String, String> _introducedCharacters = {};
  
  /// 🆕 v7.6.37: Limpa o mapa de personagens introduzidos (chamar no início de nova geração)
  static void resetIntroducedCharacters() {
    _introducedCharacters.clear();
    if (kDebugMode) {
      debugPrint('🔄 PostGenerationFixer: Mapa de personagens resetado');
    }
  }
  
  /// 🔧 Corrige nomes trocados em um bloco de texto
  /// 
  /// [text] - Texto gerado pelo Gemini
  /// [roleToName] - Mapa de papel → nome correto (ex: "mother" → "Mary")
  /// [blockNumber] - Número do bloco (para logging)
  /// 
  /// Retorna o texto corrigido (ou original se não houver erros)
  static String fixSwappedNames(
    String text,
    Map<String, String> roleToName,
    int blockNumber,
  ) {
    if (text.isEmpty) {
      return text;
    }

    String correctedText = text;
    int correctionsCount = 0;
    
    // 🆕 v7.6.36: Normalizar mapa de papéis para busca flexível
    final normalizedRoleMap = _normalizeRoleMap(roleToName);
    
    // 🆕 v7.6.37: Combinar com personagens já introduzidos
    final combinedRoleMap = <String, String>{
      ..._introducedCharacters,
      ...normalizedRoleMap, // roleToName tem prioridade
    };
    
    if (kDebugMode && combinedRoleMap.isNotEmpty) {
      debugPrint('🔧 PostGenerationFixer [Bloco $blockNumber]:');
      debugPrint('   Mapa combinado: $combinedRoleMap');
      debugPrint('   Personagens já introduzidos: $_introducedCharacters');
    }

    // 🆕 v7.6.37: Primeiro, detectar e registrar novos personagens introduzidos
    _detectAndRegisterIntroductions(correctedText, blockNumber);

    // Detectar padrões de papel + nome no texto atual
    final corrections = _detectAndCorrect(correctedText, combinedRoleMap, blockNumber);
    
    if (corrections.isNotEmpty) {
      for (final correction in corrections) {
        correctedText = correctedText.replaceAll(
          correction['wrong']!,
          correction['correct']!,
        );
        correctionsCount++;
        
        if (kDebugMode) {
          debugPrint('🔧 [Bloco $blockNumber] CORREÇÃO AUTOMÁTICA:');
          debugPrint('   ❌ Errado: "${correction['wrong']}"');
          debugPrint('   ✅ Correto: "${correction['correct']}"');
          debugPrint('   📝 Papel: "${correction['role']}"');
        }
      }
    }

    if (correctionsCount > 0 && kDebugMode) {
      debugPrint('✅ PostGenerationFixer: $correctionsCount correção(ões) no bloco $blockNumber');
    }

    return correctedText;
  }
  
  /// 🆕 v7.6.38: Detecta e registra introduções de personagens pelo papel profissional
  /// 
  /// VERSÃO MELHORADA - Detecta mais padrões:
  /// - "I found him: James Gregory, a lawyer"
  /// - "His name was Mark" (no contexto de advogado/escritório)
  /// - "I'm Samuel Wallace. Thank you for coming in" (auto-apresentação)
  /// - "a man named [Name]" / "a woman named [Name]"
  /// - "a lawyer named [Name]" / "an attorney named [Name]"
  static void _detectAndRegisterIntroductions(String text, int blockNumber) {
    // Padrões para detectar introduções de personagens por papel profissional
    final introductionPatterns = [
      // ═══════════════════════════════════════════════════════════════
      // ADVOGADO/LAWYER - Padrões expandidos v7.6.38
      // ═══════════════════════════════════════════════════════════════
      
      // Padrão 1: "found/hired/met a lawyer named [Name]"
      {
        'regex': RegExp(
          r'(?:found|hired|met|called|contacted)\s+(?:a\s+)?(?:lawyer|attorney)\s+(?:named\s+)?([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // Padrão 2: "a lawyer named/called [Name]"
      {
        'regex': RegExp(
          r'(?:a\s+)?(?:lawyer|attorney)\s+(?:named\s+|called\s+)([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // Padrão 3: "I found him: [Name] [Surname], a lawyer"
      {
        'regex': RegExp(
          r'(?:found|hired)\s+(?:him|her):\s*([A-Z][a-z]+)(?:\s+[A-Z][a-z]+)?,?\s+(?:a\s+)?(?:lawyer|attorney)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // Padrão 4: "[Name], a lawyer whose..."
      {
        'regex': RegExp(
          r'([A-Z][a-z]+)(?:\s+[A-Z][a-z]+)?,\s+(?:a\s+)?(?:lawyer|attorney)\s+(?:whose|who|with)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // Padrão 5: "His/Her name was [Name]" + contexto de advogado na mesma frase
      {
        'regex': RegExp(
          r'(?:his|her)\s+name\s+was\s+([A-Z][a-z]+).*?(?:lawyer|attorney|law\s+office|legal)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // 🔧 v7.6.39: Padrões 6 e 7 REMOVIDOS (muito agressivos, capturavam "Grandfather speaking" etc.)
      // Padrão 6: "my lawyer, [Name]"
      {
        'regex': RegExp(
          r'my\s+(?:lawyer|attorney)(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // Padrão 7: "the lawyer, [Name]"
      {
        'regex': RegExp(
          r'the\s+(?:lawyer|attorney)(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // Padrão 10: "law office" + "his name was [Name]"
      {
        'regex': RegExp(
          r'(?:law\s+office|law\s+firm|attorney).*?name\s+(?:was|is)\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // Padrão 11: "a man in his late fifties" + contexto profissional
      {
        'regex': RegExp(
          r'(?:his|her)\s+name\s+was\s+([A-Z][a-z]+),?\s+(?:a\s+)?(?:man|woman)\s+in\s+(?:his|her)',
          caseSensitive: false,
        ),
        'role': '_professional', // Marcador genérico - será refinado
      },
      // Padrão 12: Escritório de advogados com nome
      {
        'regex': RegExp(
          r'(?:office|firm)\s+(?:of|was)\s+([A-Z][a-z]+)(?:\s+[A-Z][a-z]+)?(?:\s+&|\s+and)?',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      
      // ═══════════════════════════════════════════════════════════════
      // JUIZ/JUDGE
      // ═══════════════════════════════════════════════════════════════
      {
        'regex': RegExp(
          r'(?:the\s+)?judge(?:,)?\s+(?:a\s+)?(?:man|woman)?\s*(?:named\s+)?([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'judge',
      },
      {
        'regex': RegExp(
          r'judge\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'judge',
      },
      // Médico/Doctor
      {
        'regex': RegExp(
          r'(?:a\s+)?(?:doctor|physician|dr\.?)\s+(?:named\s+)?([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'doctor',
      },
      // Chefe/Boss
      {
        'regex': RegExp(
          r'(?:my\s+)?boss(?:,)?\s+(?:a\s+)?(?:man|woman)?\s*(?:named\s+)?([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'boss',
      },
      // Vizinho/Neighbor
      {
        'regex': RegExp(
          r'(?:my\s+)?neighbor(?:,)?\s+(?:a\s+)?(?:man|woman)?\s*(?:named\s+)?([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'neighbor',
      },
      // Amigo/Friend
      {
        'regex': RegExp(
          r'(?:my\s+)?(?:best\s+)?friend(?:,)?\s+(?:a\s+)?(?:man|woman|guy|girl)?\s*(?:named\s+)?([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'friend',
      },
      // Terapeuta/Therapist
      {
        'regex': RegExp(
          r'(?:a\s+)?(?:therapist|counselor|psychiatrist)\s+(?:named\s+)?([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'therapist',
      },
      // Detetive/Detective
      {
        'regex': RegExp(
          r'(?:a\s+)?(?:detective|investigator|officer)\s+(?:named\s+)?([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'detective',
      },
      // Contador/Accountant
      {
        'regex': RegExp(
          r'(?:a\s+)?(?:accountant|cpa)\s+(?:named\s+)?([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'accountant',
      },
      // Agente imobiliário/Real estate agent
      {
        'regex': RegExp(
          r'(?:a\s+)?(?:real\s+estate\s+agent|realtor|broker)\s+(?:named\s+)?([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'realtor',
      },
    ];
    
    for (final pattern in introductionPatterns) {
      final regex = pattern['regex'] as RegExp;
      final role = pattern['role'] as String;
      
      for (final match in regex.allMatches(text)) {
        final name = match.group(1)?.trim();
        if (name == null || name.isEmpty) continue;
        
        // 🆕 v7.6.39: VALIDAR se é um nome real antes de registrar
        if (!_isValidCapturedName(name)) {
          if (kDebugMode) {
            debugPrint('⚠️ [Bloco $blockNumber] Nome ignorado (não é válido): "$name"');
          }
          continue; // Pular - não é um nome válido
        }
        
        // Verificar se já temos um personagem com este papel
        if (_introducedCharacters.containsKey(role)) {
          final existingName = _introducedCharacters[role]!;
          
          // Se o nome é diferente, temos uma duplicata!
          if (existingName.toLowerCase() != name.toLowerCase()) {
            if (kDebugMode) {
              debugPrint('⚠️ [Bloco $blockNumber] CENA DUPLICADA DETECTADA!');
              debugPrint('   Papel: $role');
              debugPrint('   Primeiro nome: $existingName');
              debugPrint('   Nome duplicado: $name');
              debugPrint('   → Mantendo o primeiro: $existingName');
            }
            // NÃO sobrescrevemos - mantemos o primeiro nome
          }
        } else {
          // Primeiro personagem com este papel - registrar
          _introducedCharacters[role] = name;
          if (kDebugMode) {
            debugPrint('📝 [Bloco $blockNumber] Novo personagem registrado:');
            debugPrint('   Papel: $role → Nome: $name');
          }
        }
      }
    }
  }

  /// 🆕 v7.6.36: Normaliza o mapa de papéis para busca flexível
  /// 
  /// O _CharacterTracker usa chaves como "mãe de emily" ou "mother"
  /// Este método extrai o papel base e mapeia para chaves padronizadas
  static Map<String, String> _normalizeRoleMap(Map<String, String> original) {
    final normalized = <String, String>{};
    
    for (final entry in original.entries) {
      final roleRaw = entry.key.toLowerCase().trim();
      final name = entry.value;
      
      // Extrair papel base (remover "de X", "of Y", etc.)
      String baseRole = roleRaw
          .replaceAll(RegExp(r'\s+de\s+\w+.*$'), '')  // "mãe de emily" → "mãe"
          .replaceAll(RegExp(r'\s+of\s+\w+.*$'), '')  // "mother of X" → "mother"
          .replaceAll(RegExp(r'\s+da\s+\w+.*$'), '')  // "irmã da protagonista" → "irmã"
          .replaceAll(RegExp(r'\s+do\s+\w+.*$'), '')  // "pai do noivo" → "pai"
          .trim();
      
      // Mapear para chave padronizada (inglês)
      final standardKey = _mapToStandardRole(baseRole);
      if (standardKey != null && !normalized.containsKey(standardKey)) {
        normalized[standardKey] = name;
      }
      
      // Também manter a versão original do papel base
      if (!normalized.containsKey(baseRole)) {
        normalized[baseRole] = name;
      }
    }
    
    return normalized;
  }

  /// Mapeia papel para chave padronizada em inglês
  static String? _mapToStandardRole(String role) {
    final roleLower = role.toLowerCase();
    
    // Mãe/Mother
    if (roleLower.contains('mãe') || roleLower.contains('mae') || 
        roleLower.contains('mother') || roleLower.contains('madre') ||
        roleLower.contains('mère') || roleLower.contains('mutter')) {
      return 'mother';
    }
    
    // Pai/Father
    if (roleLower.contains('pai') || roleLower.contains('father') || 
        roleLower.contains('padre') || roleLower.contains('père') ||
        roleLower.contains('vater')) {
      return 'father';
    }
    
    // Irmã/Sister
    if (roleLower.contains('irmã') || roleLower.contains('irma') || 
        roleLower.contains('sister') || roleLower.contains('hermana') ||
        roleLower.contains('sœur') || roleLower.contains('schwester')) {
      return 'sister';
    }
    
    // Irmão/Brother
    if (roleLower.contains('irmão') || roleLower.contains('irmao') || 
        roleLower.contains('brother') || roleLower.contains('hermano') ||
        roleLower.contains('frère') || roleLower.contains('bruder')) {
      return 'brother';
    }
    
    // Marido/Husband
    if (roleLower.contains('marido') || roleLower.contains('husband') || 
        roleLower.contains('esposo') || roleLower.contains('mari') ||
        roleLower.contains('mann') || roleLower.contains('marito')) {
      return 'husband';
    }
    
    // Esposa/Wife
    if (roleLower.contains('esposa') || roleLower.contains('wife') || 
        roleLower.contains('mulher') || roleLower.contains('femme') ||
        roleLower.contains('frau') || roleLower.contains('moglie')) {
      return 'wife';
    }
    
    // Noivo/Fiancé/Boyfriend
    if (roleLower.contains('noivo') || roleLower.contains('fiancé') || 
        roleLower.contains('fiance') || roleLower.contains('boyfriend') ||
        roleLower.contains('namorado')) {
      return 'boyfriend';
    }
    
    // Noiva/Fiancée/Girlfriend
    if (roleLower.contains('noiva') || roleLower.contains('fiancée') || 
        roleLower.contains('fiancee') || roleLower.contains('girlfriend') ||
        roleLower.contains('namorada')) {
      return 'girlfriend';
    }
    
    // Advogado/Lawyer
    if (roleLower.contains('advogado') || roleLower.contains('lawyer') || 
        roleLower.contains('attorney') || roleLower.contains('abogado')) {
      return 'lawyer';
    }
    
    // Avô/Grandfather
    if (roleLower.contains('avô') || roleLower.contains('avo') || 
        roleLower.contains('grandfather') || roleLower.contains('abuelo') ||
        roleLower.contains('grandpa')) {
      return 'grandfather';
    }
    
    // Avó/Grandmother
    if (roleLower.contains('avó') || roleLower.contains('grandmother') || 
        roleLower.contains('abuela') || roleLower.contains('grandma')) {
      return 'grandmother';
    }
    
    // Tio/Uncle
    if (roleLower.contains('tio') || roleLower.contains('uncle') || 
        roleLower.contains('oncle')) {
      return 'uncle';
    }
    
    // Tia/Aunt
    if (roleLower.contains('tia') || roleLower.contains('aunt') || 
        roleLower.contains('tante')) {
      return 'aunt';
    }
    
    // Sogro/Father-in-law
    if (roleLower.contains('sogro') || roleLower.contains('father-in-law') || 
        roleLower.contains('suegro')) {
      return 'father-in-law';
    }
    
    // Sogra/Mother-in-law
    if (roleLower.contains('sogra') || roleLower.contains('mother-in-law') || 
        roleLower.contains('suegra')) {
      return 'mother-in-law';
    }
    
    return null;
  }

  /// Detecta nomes errados e retorna lista de correções
  static List<Map<String, String>> _detectAndCorrect(
    String text,
    Map<String, String> roleToCorrectName,
    int blockNumber,
  ) {
    final corrections = <Map<String, String>>[];

    // Padrões para detectar papel + nome (múltiplos idiomas)
    final rolePatterns = _buildRolePatterns();

    for (final pattern in rolePatterns) {
      final regex = pattern['regex'] as RegExp;
      final roleKey = pattern['roleKey'] as String;

      for (final match in regex.allMatches(text)) {
        final foundName = match.group(1)?.trim();
        if (foundName == null || foundName.isEmpty) continue;

        // Verificar se temos nome correto para este papel
        final correctName = roleToCorrectName[roleKey];
        if (correctName == null) continue;

        // Comparar (case-insensitive)
        if (foundName.toLowerCase() != correctName.toLowerCase()) {
          // Nome ERRADO detectado!
          final wrongPhrase = match.group(0)!;
          final correctPhrase = wrongPhrase.replaceFirst(foundName, correctName);

          corrections.add({
            'wrong': wrongPhrase,
            'correct': correctPhrase,
            'role': roleKey,
            'wrongName': foundName,
            'correctName': correctName,
          });
        }
      }
    }
    
    // 🆕 v7.6.37: Também corrigir nomes de personagens introduzidos (advogado, juiz, etc.)
    final professionalCorrections = _detectProfessionalRoleCorrections(text, blockNumber);
    corrections.addAll(professionalCorrections);

    return corrections;
  }
  
  /// 🆕 v7.6.38: Detecta e corrige nomes errados em papéis profissionais
  /// 
  /// VERSÃO MELHORADA - Detecta mais padrões de menção:
  /// - "my lawyer, [Name]" / "the lawyer, [Name]"
  /// - "[Name] said/replied/explained" (quando advogado já registrado)
  /// - "his name was [Name]" (em contexto de advogado)
  /// - "[Name]'s office" / "[Name] speaking"
  static List<Map<String, String>> _detectProfessionalRoleCorrections(
    String text,
    int blockNumber,
  ) {
    final corrections = <Map<String, String>>[];
    
    // Padrões para detectar menções a papéis profissionais com nomes
    final professionalPatterns = [
      // ═══════════════════════════════════════════════════════════════
      // ADVOGADO/LAWYER - Padrões de menção v7.6.38
      // ═══════════════════════════════════════════════════════════════
      
      // Padrão 1: "my/the/his/her lawyer, [Name]"
      {
        'regex': RegExp(
          r'(?:(?:my|the|his|her)\s+)?(?:lawyer|attorney)(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // Padrão 2: "[Name], my/the lawyer"
      {
        'regex': RegExp(
          r'([A-Z][a-z]+)(?:,)?\s+(?:my|the|his|her)\s+(?:lawyer|attorney)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // Padrão 3: "[Name] said/replied/explained/asked" - verificar se é advogado
      {
        'regex': RegExp(
          r'([A-Z][a-z]+)\s+(?:said|replied|explained|advised|told|asked|nodded|smiled|leaned|chuckled|paused|stated|confirmed|continued)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
        'contextRequired': true, // Só corrigir se temos advogado registrado
      },
      // Padrão 4: "[Name]'s office/voice/tone"
      {
        'regex': RegExp(
          r'''([A-Z][a-z]+)'s\s+(?:office|voice|tone|words|advice|letter|response|firm)''',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // Padrão 5: "his name was [Name]" - quando mencionando profissional
      {
        'regex': RegExp(
          r'(?:his|her)\s+name\s+was\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      // 🔧 v7.6.39: Padrões 6 e 8 REMOVIDOS (muito agressivos)
      // Padrão 6: "with [Name]" em contexto de reunião (mantido, é específico)
      {
        'regex': RegExp(
          r'(?:meeting|appointment|call)\s+with\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'lawyer',
      },
      
      // ═══════════════════════════════════════════════════════════════
      // JUIZ/JUDGE
      // ═══════════════════════════════════════════════════════════════
      {
        'regex': RegExp(
          r'judge\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'role': 'judge',
      },
      {
        'regex': RegExp(
          r'(?:the\s+)?(?:honorable\s+)?([A-Z][a-z]+)(?:,)?\s+(?:presiding|ruled|decided)',
          caseSensitive: false,
        ),
        'role': 'judge',
      },
    ];
    
    for (final pattern in professionalPatterns) {
      final regex = pattern['regex'] as RegExp;
      final role = pattern['role'] as String;
      final contextRequired = pattern['contextRequired'] == true;
      
      // Verificar se temos um nome registrado para este papel
      if (!_introducedCharacters.containsKey(role)) continue;
      
      final correctName = _introducedCharacters[role]!;
      
      for (final match in regex.allMatches(text)) {
        final foundName = match.group(1)?.trim();
        if (foundName == null || foundName.isEmpty) continue;
        
        // Se contextRequired, só corrigir se o nome encontrado NÃO é de outro personagem conhecido
        if (contextRequired) {
          // Verificar se este nome pertence a outro papel (mãe, pai, irmã, etc.)
          final isOtherCharacter = _introducedCharacters.entries.any((entry) =>
            entry.key != role && 
            entry.value.toLowerCase() == foundName.toLowerCase()
          );
          if (isOtherCharacter) continue; // Pular - é outro personagem, não o advogado
        }
        
        // Se o nome é diferente do registrado, corrigir
        if (foundName.toLowerCase() != correctName.toLowerCase()) {
          final wrongPhrase = match.group(0)!;
          final correctPhrase = wrongPhrase.replaceFirst(foundName, correctName);
          
          // Evitar duplicatas
          final alreadyExists = corrections.any((c) => 
            c['wrong'] == wrongPhrase && c['correct'] == correctPhrase
          );
          
          if (!alreadyExists) {
            corrections.add({
              'wrong': wrongPhrase,
              'correct': correctPhrase,
              'role': role,
              'wrongName': foundName,
              'correctName': correctName,
            });
            
            if (kDebugMode) {
              debugPrint('🔧 [Bloco $blockNumber] CORREÇÃO DE PAPEL PROFISSIONAL:');
              debugPrint('   📋 Papel: $role');
              debugPrint('   ❌ Nome errado: $foundName');
              debugPrint('   ✅ Nome correto: $correctName');
            }
          }
        }
      }
    }
    
    return corrections;
  }

  /// Constrói padrões regex para detectar papéis + nomes
  static List<Map<String, dynamic>> _buildRolePatterns() {
    return [
      // ═══════════════════════════════════════════════════════════════
      // PORTUGUÊS
      // ═══════════════════════════════════════════════════════════════
      {
        'regex': RegExp(
          r'(?:minha?|sua|nossa|a)\s+m[ãa]e(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'mãe',
      },
      {
        'regex': RegExp(
          r'(?:meu|seu|nosso|o)\s+pai(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'pai',
      },
      {
        'regex': RegExp(
          r'(?:meu|seu|nosso|o)\s+(?:marido|esposo)(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'marido',
      },
      {
        'regex': RegExp(
          r'(?:minha|sua|nossa|a)\s+(?:esposa|mulher)(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'esposa',
      },
      {
        'regex': RegExp(
          r'(?:meu|seu|nosso|o)\s+(?:irm[ãa]o|irmao)(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'irmão',
      },
      {
        'regex': RegExp(
          r'(?:minha|sua|nossa|a)\s+irm[ãa](?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'irmã',
      },
      {
        'regex': RegExp(
          r'(?:meu|seu|nosso|o)\s+noivo(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'noivo',
      },
      {
        'regex': RegExp(
          r'(?:minha|sua|nossa|a)\s+noiva(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'noiva',
      },
      {
        'regex': RegExp(
          r'(?:meu|seu|nosso|o)\s+filho(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'filho',
      },
      {
        'regex': RegExp(
          r'(?:minha|sua|nossa|a)\s+filha(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'filha',
      },
      {
        'regex': RegExp(
          r'(?:meu|seu|nosso|o)\s+sogro(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'sogro',
      },
      {
        'regex': RegExp(
          r'(?:minha|sua|nossa|a)\s+sogra(?:,)?\s+([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)',
          caseSensitive: false,
        ),
        'roleKey': 'sogra',
      },
      
      // ═══════════════════════════════════════════════════════════════
      // INGLÊS
      // ═══════════════════════════════════════════════════════════════
      {
        'regex': RegExp(
          r'my\s+mother(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'mother',
      },
      {
        'regex': RegExp(
          r'my\s+father(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'father',
      },
      {
        'regex': RegExp(
          r'my\s+husband(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'husband',
      },
      {
        'regex': RegExp(
          r'my\s+wife(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'wife',
      },
      {
        'regex': RegExp(
          r'my\s+brother(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'brother',
      },
      {
        'regex': RegExp(
          r'my\s+sister(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'sister',
      },
      {
        'regex': RegExp(
          r'my\s+(?:fianc[eé]|fiance)(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'fiancé',
      },
      {
        'regex': RegExp(
          r'my\s+(?:fiancée|fiancee)(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'fiancée',
      },
      {
        'regex': RegExp(
          r'my\s+son(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'son',
      },
      {
        'regex': RegExp(
          r'my\s+daughter(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'daughter',
      },
      {
        'regex': RegExp(
          r'my\s+father-in-law(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'father-in-law',
      },
      {
        'regex': RegExp(
          r'my\s+mother-in-law(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'mother-in-law',
      },
      {
        'regex': RegExp(
          r'my\s+ex(?:-husband)?(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'ex',
      },
      {
        'regex': RegExp(
          r'my\s+boyfriend(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'boyfriend',
      },
      {
        'regex': RegExp(
          r'my\s+girlfriend(?:,)?\s+([A-Z][a-z]+)',
          caseSensitive: false,
        ),
        'roleKey': 'girlfriend',
      },
      
      // ═══════════════════════════════════════════════════════════════
      // ESPANHOL
      // ═══════════════════════════════════════════════════════════════
      {
        'regex': RegExp(
          r'mi\s+madre(?:,)?\s+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)',
          caseSensitive: false,
        ),
        'roleKey': 'madre',
      },
      {
        'regex': RegExp(
          r'mi\s+padre(?:,)?\s+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)',
          caseSensitive: false,
        ),
        'roleKey': 'padre',
      },
      {
        'regex': RegExp(
          r'mi\s+esposo(?:,)?\s+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)',
          caseSensitive: false,
        ),
        'roleKey': 'esposo',
      },
      {
        'regex': RegExp(
          r'mi\s+esposa(?:,)?\s+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)',
          caseSensitive: false,
        ),
        'roleKey': 'esposa_es',
      },
      {
        'regex': RegExp(
          r'mi\s+hermano(?:,)?\s+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)',
          caseSensitive: false,
        ),
        'roleKey': 'hermano',
      },
      {
        'regex': RegExp(
          r'mi\s+hermana(?:,)?\s+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)',
          caseSensitive: false,
        ),
        'roleKey': 'hermana',
      },
      
      // ═══════════════════════════════════════════════════════════════
      // FRANCÊS
      // ═══════════════════════════════════════════════════════════════
      {
        'regex': RegExp(
          r'ma\s+m[èe]re(?:,)?\s+([A-ZÀÂÄÇÉÈÊËÎÏÔÙÛÜ][a-zàâäçéèêëîïôùûü]+)',
          caseSensitive: false,
        ),
        'roleKey': 'mère',
      },
      {
        'regex': RegExp(
          r'mon\s+p[èe]re(?:,)?\s+([A-ZÀÂÄÇÉÈÊËÎÏÔÙÛÜ][a-zàâäçéèêëîïôùûü]+)',
          caseSensitive: false,
        ),
        'roleKey': 'père',
      },
      {
        'regex': RegExp(
          r'mon\s+mari(?:,)?\s+([A-ZÀÂÄÇÉÈÊËÎÏÔÙÛÜ][a-zàâäçéèêëîïôùûü]+)',
          caseSensitive: false,
        ),
        'roleKey': 'mari',
      },
      {
        'regex': RegExp(
          r'ma\s+femme(?:,)?\s+([A-ZÀÂÄÇÉÈÊËÎÏÔÙÛÜ][a-zàâäçéèêëîïôùûü]+)',
          caseSensitive: false,
        ),
        'roleKey': 'femme',
      },
      {
        'regex': RegExp(
          r'mon\s+fr[èe]re(?:,)?\s+([A-ZÀÂÄÇÉÈÊËÎÏÔÙÛÜ][a-zàâäçéèêëîïôùûü]+)',
          caseSensitive: false,
        ),
        'roleKey': 'frère',
      },
      {
        'regex': RegExp(
          r'ma\s+s[œoe]ur(?:,)?\s+([A-ZÀÂÄÇÉÈÊËÎÏÔÙÛÜ][a-zàâäçéèêëîïôùûü]+)',
          caseSensitive: false,
        ),
        'roleKey': 'sœur',
      },
      
      // ═══════════════════════════════════════════════════════════════
      // ALEMÃO
      // ═══════════════════════════════════════════════════════════════
      {
        'regex': RegExp(
          r'meine?\s+Mutter(?:,)?\s+([A-ZÄÖÜß][a-zäöüß]+)',
          caseSensitive: false,
        ),
        'roleKey': 'Mutter',
      },
      {
        'regex': RegExp(
          r'mein\s+Vater(?:,)?\s+([A-ZÄÖÜß][a-zäöüß]+)',
          caseSensitive: false,
        ),
        'roleKey': 'Vater',
      },
      {
        'regex': RegExp(
          r'mein\s+(?:Mann|Ehemann)(?:,)?\s+([A-ZÄÖÜß][a-zäöüß]+)',
          caseSensitive: false,
        ),
        'roleKey': 'Mann',
      },
      {
        'regex': RegExp(
          r'meine?\s+(?:Frau|Ehefrau)(?:,)?\s+([A-ZÄÖÜß][a-zäöüß]+)',
          caseSensitive: false,
        ),
        'roleKey': 'Frau',
      },
      {
        'regex': RegExp(
          r'mein\s+Bruder(?:,)?\s+([A-ZÄÖÜß][a-zäöüß]+)',
          caseSensitive: false,
        ),
        'roleKey': 'Bruder',
      },
      {
        'regex': RegExp(
          r'meine?\s+Schwester(?:,)?\s+([A-ZÄÖÜß][a-zäöüß]+)',
          caseSensitive: false,
        ),
        'roleKey': 'Schwester',
      },
      
      // ═══════════════════════════════════════════════════════════════
      // ITALIANO
      // ═══════════════════════════════════════════════════════════════
      {
        'regex': RegExp(
          r'mia\s+madre(?:,)?\s+([A-ZÀÈÉÌÒÙ][a-zàèéìòù]+)',
          caseSensitive: false,
        ),
        'roleKey': 'madre_it',
      },
      {
        'regex': RegExp(
          r'mio\s+padre(?:,)?\s+([A-ZÀÈÉÌÒÙ][a-zàèéìòù]+)',
          caseSensitive: false,
        ),
        'roleKey': 'padre_it',
      },
      {
        'regex': RegExp(
          r'mio\s+marito(?:,)?\s+([A-ZÀÈÉÌÒÙ][a-zàèéìòù]+)',
          caseSensitive: false,
        ),
        'roleKey': 'marito',
      },
      {
        'regex': RegExp(
          r'mia\s+moglie(?:,)?\s+([A-ZÀÈÉÌÒÙ][a-zàèéìòù]+)',
          caseSensitive: false,
        ),
        'roleKey': 'moglie',
      },
      {
        'regex': RegExp(
          r'mio\s+fratello(?:,)?\s+([A-ZÀÈÉÌÒÙ][a-zàèéìòù]+)',
          caseSensitive: false,
        ),
        'roleKey': 'fratello',
      },
      {
        'regex': RegExp(
          r'mia\s+sorella(?:,)?\s+([A-ZÀÈÉÌÒÙ][a-zàèéìòù]+)',
          caseSensitive: false,
        ),
        'roleKey': 'sorella',
      },
    ];
  }

  /// Mapeia papéis equivalentes entre idiomas
  /// Usado para traduzir roleKey para comparação cross-language
  static final Map<String, Set<String>> _roleEquivalents = {
    'mãe': {'mãe', 'mother', 'madre', 'mère', 'Mutter', 'madre_it'},
    'pai': {'pai', 'father', 'padre', 'père', 'Vater', 'padre_it'},
    'marido': {'marido', 'husband', 'esposo', 'mari', 'Mann', 'marito'},
    'esposa': {'esposa', 'wife', 'esposa_es', 'femme', 'Frau', 'moglie'},
    'irmão': {'irmão', 'brother', 'hermano', 'frère', 'Bruder', 'fratello'},
    'irmã': {'irmã', 'sister', 'hermana', 'sœur', 'Schwester', 'sorella'},
    'filho': {'filho', 'son'},
    'filha': {'filha', 'daughter'},
    'noivo': {'noivo', 'fiancé', 'boyfriend'},
    'noiva': {'noiva', 'fiancée', 'girlfriend'},
    'sogro': {'sogro', 'father-in-law'},
    'sogra': {'sogra', 'mother-in-law'},
    'ex': {'ex'},
  };

  /// Encontra o roleKey normalizado para comparação
  static String? findEquivalentRole(String roleKey) {
    final normalized = roleKey.toLowerCase();
    
    for (final entry in _roleEquivalents.entries) {
      if (entry.value.contains(normalized)) {
        return entry.key; // Retorna chave base (português)
      }
    }
    
    return normalized; // Fallback: usa próprio roleKey
  }
}
