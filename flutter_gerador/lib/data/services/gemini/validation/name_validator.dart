import 'package:flutter/foundation.dart';
import 'package:flutter_gerador/data/services/name_generator_service.dart';

/// 🔍 Validador de nomes de personagens
class NameValidator {
  /// Stopwords - palavras que NÃO são nomes de pessoas
  static final Set<String> nameStopwords = {
    // Plataformas/sites
    'youtube',
    'internet',
    'instagram',
    'facebook',
    'whatsapp',
    'tiktok',
    'google',
    'cta',

    // Países/lugares
    'brasil',
    'portugal',
    'portugues',

    // Pronomes e palavras comuns
    'ele',
    'ela',
    'eles',
    'elas',
    'nao',
    'sim',
    'mas',
    'mais',
    'cada',
    'todo',
    'toda',
    'todos',
    'meu',
    'minha',
    'meus',
    'minhas',
    'seu',
    'sua',
    'seus',
    'suas',
    'nosso',
    'nossa',
    'esse',
    'essa',
    'esses',
    'essas',
    'aquele',
    'aquela',
    'aquilo',
    'isto',
    'isso',
    'tudo',
    'nada',
    'algo',
    'alguem',
    'ninguem',
    'qualquer',
    'outro',
    'outra',
    'mesmo',
    'mesma',
    'esta',
    'este',
    'estes',
    'estas',

    // Substantivos comuns
    'filho',
    'filha',
    'filhos',
    'pai',
    'mae',
    'pais',
    'irmao',
    'irma',
    'tio',
    'tia',
    'avo',
    'neto',
    'neta',
    'marido',
    'esposa',
    'noivo',
    'noiva',
    'amigo',
    'amiga',
    'primo',
    'prima',
    'sobrinho',
    'sobrinha',
    'senhor',
    'senhora',
    'doutor',
    'doutora',
    'cliente',
    'pessoa',
    'pessoas',
    'gente',
    'familia',
    'casa',
    'mundo',
    'vida',
    'tempo',
    'dia',
    'noite',
    'momento',

    // Advérbios/conjunções/preposições
    'entao',
    'depois',
    'antes',
    'agora',
    'hoje',
    'ontem',
    'amanha',
    'sempre',
    'nunca',
    'talvez',
    'porem',
    'contudo',
    'entretanto',
    'portanto',
    'enquanto',
    'quando',
    'onde',
    'havia',
    'houve',
    'tinha',
    'foram',
    'eram',
    'estava',
    'estavam',
    'dentro',
    'fora',
    'acima',
    'abaixo',
    'perto',
    'longe',
    'aqui',
    'ali',
    'alem',
    'apenas',
    'somente',
    'tambem',
    'inclusive',
    'ate',
    'ainda',
    'logo',
    'ja',
    'nem',

    // Preposições e artigos
    'com',
    'sem',
    'sobre',
    'para',
    'pela',
    'pelo',
    'uma',
    'umas',
    'uns',
    'por',

    // Palavras fantasma (a AI usou como nomes por engano)
    'lagrimas',
    'lágrimas',
    'justica',
    'justiça',
    'ponto',
    'semanas',
    'aconteceu',
    'todas',
    'ajuda',
    'consolo',
    'vamos',
    'conheço',
    'conheco',
    'lembra',

    // Verbos comuns
    'era',
    'foi',
    'seria',
    'pode',
    'podia',
    'deve',
    'devia',
    'senti',
    'sentiu',
    'pensei',
    'pensou',
    'vi',
    'viu',
    'ouvi',
    'ouviu',
    'fiz',
    'fez',
    'disse',
    'falou',
    'quis',
    'pude',
    'pôde',
    'tive',
    'teve',
    'sabia',
    'soube',
    'imaginei',
    'imaginou',
    'acreditei',
    'acreditou',
    'percebi',
    'percebeu',
    'notei',
    'notou',
    'lembrei',
    'lembrou',
    'passei',
    'abri',
    'olhei',
    'escrevo',
    'escreveu',
    'podes',
    'queria',
    'quer',
    'tenho',
    'tem',
    'levei',
    'levou',
    'trouxe',
    'deixei',
    'deixou',
    'encontrei',
    'encontrou',
    'cheguei',
    'chegou',
    'sai',
    'saiu',
    'entrei',
    'entrou',
    'peguei',
    'pegou',
    'coloquei',
    'colocou',
    'tirei',
    'tirou',
    'guardei',
    'guardou',
    'voltei',
    'voltou',
    'segui',
    'seguiu',
    'comecei',
    'começou',
    'terminei',
    'terminou',
  };

  /// Verifica se uma string parece um nome de pessoa
  /// 🔥 VALIDAÇÃO RIGOROSA: Usa banco de dados curado
  static bool looksLikePersonName(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return false;

    // Verificar se está no banco curado
    if (NameGeneratorService.isValidName(cleaned)) {
      return true; // ✅ Nome 100% confirmado
    }

    // 🚫 Se NÃO está no banco curado, REJEITAR
    if (kDebugMode) {
      debugPrint('⚠️ NOME REJEITADO (não está no banco curado): "$cleaned"');
    }
    return false;
  }

  /// Extrai nomes de um texto usando regex
  static Set<String> extractNamesFromText(String text) {
    final names = <String>{};
    if (text.isEmpty) return names;

    // Regex: palavras capitalizadas (possíveis nomes)
    final nameRegex = RegExp(
      r'\b([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+(?:\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)*)\b',
    );

    for (final match in nameRegex.allMatches(text)) {
      final potentialName = match.group(1)?.trim() ?? '';

      // Filtros
      if (potentialName.length < 3) continue;
      if (potentialName.length > 30)
        continue; // Nomes muito longos não são pessoas

      // Verificar se é stopword
      if (nameStopwords.contains(potentialName.toLowerCase())) continue;

      // Verificar se parece nome de pessoa (banco curado)
      if (!looksLikePersonName(potentialName)) continue;

      names.add(potentialName);
    }

    return names;
  }

  /// Valida se há nomes duplicados em papéis diferentes
  /// Retorna lista de nomes duplicados encontrados
  static List<String> validateNamesInText(
    String newBlock,
    Set<String> previousNames,
  ) {
    final duplicates = <String>[];
    final newNames = extractNamesFromText(newBlock);

    for (final name in newNames) {
      if (previousNames.contains(name)) {
        if (!duplicates.contains(name)) {
          duplicates.add(name);
        }
      }
    }

    return duplicates;
  }

  /// Extrai nomes de um snippet com contagem de ocorrências
  static Map<String, int> extractNamesFromSnippet(String snippet) {
    final counts = <String, int>{};
    final regex = RegExp(
      r'\b([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+(?:\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ][a-záàâãéêíóôõúç]+)*)\b',
    );

    for (final match in regex.allMatches(snippet)) {
      final candidate = match.group(1)?.trim() ?? '';
      if (!looksLikePersonName(candidate)) continue;
      final normalized = candidate.replaceAll(RegExp(r'\s+'), ' ');
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }

    return counts;
  }

  /// Extrai papel/relação de um nome em um texto
  /// Retorna o primeiro papel encontrado ou null
  static String? extractRoleForName(String name, String text) {
    final rolePatterns = {
      'marido': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:marido|esposo)(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'esposa': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:esposa|mulher)(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'pai': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Pp]ai(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'mãe': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Mm]ãe(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'filho': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Ff]ilho(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'filha': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Ff]ilha(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'irmão': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:irmão|irmao)(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'irmã': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:irmã|irma)(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'sogro': RegExp(
        r'(?:meu|seu|nosso|o)\s+sogro(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'sogra': RegExp(
        r'(?:minha|sua|nossa|a)\s+sogra(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'amigo': RegExp(
        r'(?:meu|seu|nosso|o)\s+amigo(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
      'amiga': RegExp(
        r'(?:minha|sua|nossa|a)\s+amiga(?:[^.]{0,30}\b$name\b|(?:,)?\s+$name)',
        caseSensitive: false,
      ),
    };

    for (final entry in rolePatterns.entries) {
      if (entry.value.hasMatch(text)) {
        return entry.key;
      }
    }

    return null;
  }
}
