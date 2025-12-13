import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/localization_level.dart';

/// 📋 BASE RULES
/// Regras universais aplicadas a TODOS os roteiros
/// - Instruções de idioma
/// - Formatação de texto
/// - Regionalização
/// - Traduções de metadados
class BaseRules {
  /// 🌍 Mapa de traduções de termos de parentesco por idioma
  static const Map<String, Map<String, String>> familyTermsTranslations = {
    'português': {
      'Pai': 'pai',
      'pai': 'pai',
      'Mãe': 'mãe',
      'mãe': 'mãe',
      'Filho': 'filho',
      'filho': 'filho',
      'Filha': 'filha',
      'filha': 'filha',
      'Avô': 'avô',
      'avô': 'avô',
      'Avó': 'avó',
      'avó': 'avó',
      'Esposa': 'esposa',
      'esposa': 'esposa',
      'Marido': 'marido',
      'marido': 'marido',
      'Irmão': 'irmão',
      'irmão': 'irmão',
      'Irmã': 'irmã',
      'irmã': 'irmã',
      'Tio': 'tio',
      'tio': 'tio',
      'Tia': 'tia',
      'tia': 'tia',
    },
    'inglês': {
      'Pai': 'father',
      'pai': 'father',
      'Mãe': 'mother',
      'mãe': 'mother',
      'Filho': 'son',
      'filho': 'son',
      'Filha': 'daughter',
      'filha': 'daughter',
      'Avô': 'grandfather',
      'avô': 'grandfather',
      'Avó': 'grandmother',
      'avó': 'grandmother',
      'Esposa': 'wife',
      'esposa': 'wife',
      'Marido': 'husband',
      'marido': 'husband',
      'Irmão': 'brother',
      'irmão': 'brother',
      'Irmã': 'sister',
      'irmã': 'sister',
      'Tio': 'uncle',
      'tio': 'uncle',
      'Tia': 'aunt',
      'tia': 'aunt',
    },
    'espanhol(mexicano)': {
      'Pai': 'padre',
      'pai': 'padre',
      'Mãe': 'madre',
      'mãe': 'madre',
      'Filho': 'hijo',
      'filho': 'hijo',
      'Filha': 'hija',
      'filha': 'hija',
      'Avô': 'abuelo',
      'avô': 'abuelo',
      'Avó': 'abuela',
      'avó': 'abuela',
      'Esposa': 'esposa',
      'esposa': 'esposa',
      'Marido': 'esposo',
      'marido': 'esposo',
      'Irmão': 'hermano',
      'irmão': 'hermano',
      'Irmã': 'hermana',
      'irmã': 'hermana',
      'Tio': 'tío',
      'tio': 'tío',
      'Tia': 'tía',
      'tia': 'tía',
    },
    'francês': {
      'Pai': 'père',
      'pai': 'père',
      'Mãe': 'mère',
      'mãe': 'mère',
      'Filho': 'fils',
      'filho': 'fils',
      'Filha': 'fille',
      'filha': 'fille',
      'Avô': 'grand-père',
      'avô': 'grand-père',
      'Avó': 'grand-mère',
      'avó': 'grand-mère',
      'Esposa': 'épouse',
      'esposa': 'épouse',
      'Marido': 'mari',
      'marido': 'mari',
      'Irmão': 'frère',
      'irmão': 'frère',
      'Irmã': 'sœur',
      'irmã': 'sœur',
      'Tio': 'oncle',
      'tio': 'oncle',
      'Tia': 'tante',
      'tia': 'tante',
    },
    'alemão': {
      'Pai': 'Vater',
      'pai': 'Vater',
      'Mãe': 'Mutter',
      'mãe': 'Mutter',
      'Filho': 'Sohn',
      'filho': 'Sohn',
      'Filha': 'Tochter',
      'filha': 'Tochter',
      'Avô': 'Großvater',
      'avô': 'Großvater',
      'Avó': 'Großmutter',
      'avó': 'Großmutter',
      'Esposa': 'Ehefrau',
      'esposa': 'Ehefrau',
      'Marido': 'Ehemann',
      'marido': 'Ehemann',
      'Irmão': 'Bruder',
      'irmão': 'Bruder',
      'Irmã': 'Schwester',
      'irmã': 'Schwester',
      'Tio': 'Onkel',
      'tio': 'Onkel',
      'Tia': 'Tante',
      'tia': 'Tante',
    },
    'italiano': {
      'Pai': 'padre',
      'pai': 'padre',
      'Mãe': 'madre',
      'mãe': 'madre',
      'Filho': 'figlio',
      'filho': 'figlio',
      'Filha': 'figlia',
      'filha': 'figlia',
      'Avô': 'nonno',
      'avô': 'nonno',
      'Avó': 'nonna',
      'avó': 'nonna',
      'Esposa': 'moglie',
      'esposa': 'moglie',
      'Marido': 'marito',
      'marido': 'marito',
      'Irmão': 'fratello',
      'irmão': 'fratello',
      'Irmã': 'sorella',
      'irmã': 'sorella',
      'Tio': 'zio',
      'tio': 'zio',
      'Tia': 'zia',
      'tia': 'zia',
    },
    'russo': {
      'Pai': 'отец',
      'pai': 'отец',
      'Mãe': 'мать',
      'mãe': 'мать',
      'Filho': 'сын',
      'filho': 'сын',
      'Filha': 'дочь',
      'filha': 'дочь',
      'Avô': 'дедушка',
      'avô': 'дедушка',
      'Avó': 'бабушка',
      'avó': 'бабушка',
      'Esposa': 'жена',
      'esposa': 'жена',
      'Marido': 'муж',
      'marido': 'муж',
      'Irmão': 'брат',
      'irmão': 'брат',
      'Irmã': 'сестра',
      'irmã': 'сестра',
      'Tio': 'дядя',
      'tio': 'дядя',
      'Tia': 'тётя',
      'tia': 'тётя',
    },
    'polonês': {
      'Pai': 'ojciec',
      'pai': 'ojciec',
      'Mãe': 'matka',
      'mãe': 'matka',
      'Filho': 'syn',
      'filho': 'syn',
      'Filha': 'córka',
      'filha': 'córka',
      'Avô': 'dziadek',
      'avô': 'dziadek',
      'Avó': 'babcia',
      'avó': 'babcia',
      'Esposa': 'żona',
      'esposa': 'żona',
      'Marido': 'mąż',
      'marido': 'mąż',
      'Irmão': 'brat',
      'irmão': 'brat',
      'Irmã': 'siostra',
      'irmã': 'siostra',
      'Tio': 'wujek',
      'tio': 'wujek',
      'Tia': 'ciocia',
      'tia': 'ciocia',
    },
    'croata': {
      'Pai': 'otac',
      'pai': 'otac',
      'Mãe': 'majka',
      'mãe': 'majka',
      'Filho': 'sin',
      'filho': 'sin',
      'Filha': 'kći',
      'filha': 'kći',
      'Avô': 'djed',
      'avô': 'djed',
      'Avó': 'baka',
      'avó': 'baka',
      'Esposa': 'supruga',
      'esposa': 'supruga',
      'Marido': 'suprug',
      'marido': 'suprug',
      'Irmão': 'brat',
      'irmão': 'brat',
      'Irmã': 'sestra',
      'irmã': 'sestra',
      'Tio': 'ujak',
      'tio': 'ujak',
      'Tia': 'teta',
      'tia': 'teta',
    },
    'búlgaro': {
      'Pai': 'баща',
      'pai': 'баща',
      'Mãe': 'майка',
      'mãe': 'майка',
      'Filho': 'син',
      'filho': 'син',
      'Filha': 'дъщеря',
      'filha': 'дъщеря',
      'Avô': 'дядо',
      'avô': 'дядо',
      'Avó': 'баба',
      'avó': 'баба',
      'Esposa': 'съпруга',
      'esposa': 'съпруга',
      'Marido': 'съпруг',
      'marido': 'съпруг',
      'Irmão': 'брат',
      'irmão': 'брат',
      'Irmã': 'сестра',
      'irmã': 'сестра',
      'Tio': 'чичо',
      'tio': 'чичо',
      'Tia': 'леля',
      'tia': 'леля',
    },
    'turco': {
      'Pai': 'baba',
      'pai': 'baba',
      'Mãe': 'anne',
      'mãe': 'anne',
      'Filho': 'oğul',
      'filho': 'oğul',
      'Filha': 'kız',
      'filha': 'kız',
      'Avô': 'dede',
      'avô': 'dede',
      'Avó': 'nine',
      'avó': 'nine',
      'Esposa': 'eş',
      'esposa': 'eş',
      'Marido': 'koca',
      'marido': 'koca',
      'Irmão': 'erkek kardeş',
      'irmão': 'erkek kardeş',
      'Irmã': 'kız kardeş',
      'irmã': 'kız kardeş',
      'Tio': 'amca',
      'tio': 'amca',
      'Tia': 'teyze',
      'tia': 'teyze',
    },
    'romeno': {
      'Pai': 'tată',
      'pai': 'tată',
      'Mãe': 'mamă',
      'mãe': 'mamă',
      'Filho': 'fiu',
      'filho': 'fiu',
      'Filha': 'fiică',
      'filha': 'fiică',
      'Avô': 'bunic',
      'avô': 'bunic',
      'Avó': 'bunică',
      'avó': 'bunică',
      'Esposa': 'soție',
      'esposa': 'soție',
      'Marido': 'soț',
      'marido': 'soț',
      'Irmão': 'frate',
      'irmão': 'frate',
      'Irmã': 'soră',
      'irmã': 'soră',
      'Tio': 'unchi',
      'tio': 'unchi',
      'Tia': 'mătușă',
      'tia': 'mătușă',
    },
  };

  /// 🌍 Retorna instrução de idioma para o prompt
  static String getLanguageInstruction(String language) {
    final normalized = language.toLowerCase().trim();

    if (normalized.contains('portugu') || normalized == 'pt') {
      return 'Português brasileiro natural e simples - use palavras que qualquer pessoa entende no dia a dia, evite vocabulário rebuscado ou erudito';
    }

    if (normalized.contains('ingl') ||
        normalized == 'en' ||
        normalized == 'english') {
      return 'Simple, natural English - use everyday words that anyone can understand, avoid complex vocabulary';
    }

    if (normalized.contains('espanhol') ||
        normalized.contains('spanish') ||
        normalized.contains('español') ||
        normalized == 'es' ||
        normalized == 'es-mx') {
      return 'Español mexicano natural y sencillo - usa palabras cotidianas que cualquiera entiende, evita vocabulario rebuscado';
    }

    if (normalized.contains('franc') ||
        normalized.contains('french') ||
        normalized == 'fr') {
      return 'Français naturel et simple - utilisez des mots quotidiens que tout le monde comprend, évitez le vocabulaire complexe';
    }

    if (normalized.contains('alem') ||
        normalized.contains('german') ||
        normalized == 'de') {
      return 'Natürliches, einfaches Deutsch - verwenden Sie alltägliche Wörter, die jeder versteht, vermeiden Sie komplexes Vokabular';
    }

    if (normalized.contains('italia') ||
        normalized.contains('italian') ||
        normalized == 'it') {
      return 'Italiano naturale e semplice - usa parole quotidiane che tutti capiscono, evita vocabolario complesso';
    }

    if (normalized.contains('polon') ||
        normalized.contains('polish') ||
        normalized == 'pl') {
      return 'Naturalny, prosty polski - używaj codziennych słów, które każdy rozumie, unikaj skomplikowanego słownictwa';
    }

    if (normalized.contains('búlgar') ||
        normalized.contains('bulgar') ||
        normalized == 'bg') {
      return 'Естествен, прост български - използвайте ежедневни думи, които всеки разбира, избягвайте сложна лексика';
    }

    if (normalized.contains('croat') ||
        normalized.contains('hrvat') ||
        normalized == 'hr') {
      return 'Prirodni, jednostavan hrvatski - koristite svakodnevne riječi koje svatko razumije, izbjegavajte složen vokabular';
    }

    if (normalized.contains('turco') ||
        normalized.contains('turk') ||
        normalized == 'tr') {
      return 'Doğal, basit Türkçe - herkesin anlayabileceği günlük kelimeler kullanın, karmaşık kelime dağarcığından kaçının';
    }

    if (normalized.contains('romen') ||
        normalized.contains('roman') ||
        normalized == 'ro') {
      return 'Română naturală și simplă - folosiți cuvinte de zi cu zi pe care oricine le înțelege, evitați vocabularul complicat';
    }

    if (normalized.contains('russo') ||
        normalized.contains('russian') ||
        normalized == 'ru') {
      return 'Естественный, простой русский - используйте повседневные слова, которые все понимают, избегайте сложной лексики';
    }

    if (normalized.contains('coreano') ||
        normalized.contains('korean') ||
        normalized.contains('한국어') ||
        normalized == 'ko') {
      return '자연스럽고 간단한 한국어 - 누구나 이해할 수 있는 일상 단어를 사용하고 복잡한 어휘는 피하세요 (Natural, simple Korean - use everyday words that anyone can understand, avoid complex vocabulary)';
    }

    // Default para português
    return 'Português brasileiro natural e simples - use palavras que qualquer pessoa entende no dia a dia';
  }

  /// 🌍 Retorna instrução de início internacionalizada
  static String getStartInstruction(
    String language, {
    required bool withTitle,
    String? title,
  }) {
    final normalized = language.toLowerCase().trim();

    // 🇺🇸 INGLÊS
    if (normalized.contains('ingl') ||
        normalized == 'en' ||
        normalized == 'english') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Begin a new story using EXACTLY this phrase as the opening hook: "$title". This phrase should start the first paragraph naturally and engagingly, as if it were part of the narrative';
      }
      return 'Begin a new story';
    }

    // 🇲🇽 ESPANHOL
    if (normalized.contains('espanhol') ||
        normalized.contains('spanish') ||
        normalized.contains('español') ||
        normalized == 'es' ||
        normalized == 'es-mx') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Comienza una nueva historia usando EXACTAMENTE esta frase como gancho de apertura: "$title". Esta frase debe iniciar el primer párrafo de forma natural y envolvente, como si fuera parte de la narrativa';
      }
      return 'Comienza una nueva historia';
    }

    // 🇫🇷 FRANCÊS
    if (normalized.contains('franc') ||
        normalized.contains('french') ||
        normalized == 'fr') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Commencez une nouvelle histoire en utilisant EXACTEMENT cette phrase comme accroche d\'ouverture: "$title". Cette phrase doit commencer le premier paragraphe de manière naturelle et engageante, comme si elle faisait partie du récit';
      }
      return 'Commencez une nouvelle histoire';
    }

    // 🇩🇪 ALEMÃO
    if (normalized.contains('alem') ||
        normalized.contains('german') ||
        normalized == 'de') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return 'Beginnen Sie eine neue Geschichte und verwenden Sie GENAU diesen Satz als Eröffnungshaken: "$title". Dieser Satz sollte den ersten Absatz auf natürliche und ansprechende Weise beginnen, als wäre er Teil der Erzählung';
      }
      return 'Beginnen Sie eine neue Geschichte';
    }

    // Outros idiomas omitidos por brevidade...
    // 🇰🇷 COREANO
    if (normalized.contains('coreano') ||
        normalized.contains('korean') ||
        normalized.contains('한국어') ||
        normalized == 'ko') {
      if (withTitle && title != null && title.trim().isNotEmpty) {
        return '이 문구를 오프닝 훅으로 사용하여 새로운 이야기를 시작하세요: "$title". 이 문구는 자연스럽고 매력적으로 첫 문단을 시작해야 합니다';
      }
      return '새로운 이야기를 시작하세요';
    }
    // 🇧🇷 PORTUGUÊS (default)
    if (withTitle && title != null && title.trim().isNotEmpty) {
      return 'Comece uma nova história usando EXATAMENTE esta frase como gancho de abertura: "$title". Esta frase deve iniciar o primeiro parágrafo de forma natural e envolvente, como se fosse parte da narrativa';
    }
    return 'Comece uma nova história';
  }

  /// 🌍 Retorna instrução de continuação internacionalizada
  static String getContinueInstruction(String language) {
    final normalized = language.toLowerCase().trim();

    if (normalized.contains('ingl') ||
        normalized == 'en' ||
        normalized == 'english') {
      return 'Continue the story';
    }
    if (normalized.contains('espanhol') ||
        normalized.contains('spanish') ||
        normalized.contains('español') ||
        normalized == 'es' ||
        normalized == 'es-mx') {
      return 'Continúa la historia';
    }
    if (normalized.contains('franc') ||
        normalized.contains('french') ||
        normalized == 'fr') {
      return 'Continuez l\'histoire';
    }
    if (normalized.contains('coreano') ||
        normalized.contains('korean') ||
        normalized.contains('한국어') ||
        normalized == 'ko') {
      return '이야기를 계속하세요';
    }

    return 'Continue a história'; // Português (default)
  }

  /// 🌍 Traduz labels de metadados (TEMA, SUBTEMA, etc) para o idioma selecionado
  static Map<String, String> getMetadataLabels(String language) {
    final normalized = language.toLowerCase().trim();

    // 🇺🇸 INGLÊS
    if (normalized.contains('ingl') ||
        normalized == 'en' ||
        normalized == 'english') {
      return {
        'theme': 'THEME',
        'subtheme': 'SUBTHEME',
        'location': 'LOCATION',
        'locationNotSpecified': 'Not specified',
        'additionalContext': 'ADDITIONAL CONTEXT',
      };
    }

    // 🇲🇽 ESPANHOL
    if (normalized.contains('espanhol') ||
        normalized.contains('spanish') ||
        normalized.contains('español') ||
        normalized == 'es' ||
        normalized == 'es-mx') {
      return {
        'theme': 'TEMA',
        'subtheme': 'SUBTEMA',
        'location': 'UBICACIÓN',
        'locationNotSpecified': 'No especificada',
        'additionalContext': 'CONTEXTO ADICIONAL',
      };
    }

    // 🇧🇷 PORTUGUÊS (default)
    return {
      'theme': 'TEMA',
      'subtheme': 'SUBTEMA',
      'location': 'LOCALIZAÇÃO',
      'locationNotSpecified': 'Não especificada',
      'additionalContext': 'CONTEXTO ADICIONAL',
    };
  }

  /// 🌍 Infere o país baseado no idioma (para modo Nacional/Regional sem localização especificada)
  static String inferCountryFromLanguage(String language) {
    final normalized = language.toLowerCase().trim();

    if (normalized.contains('português') ||
        normalized.contains('portugues') ||
        normalized.contains('portuguese') ||
        normalized == 'pt' ||
        normalized == 'pt-br') {
      return 'Brasil';
    }

    if (normalized.contains('ingl') ||
        normalized.contains('english') ||
        normalized == 'en' ||
        normalized == 'en-us') {
      return 'United States';
    }

    if (normalized.contains('espanhol') ||
        normalized.contains('español') ||
        normalized.contains('spanish') ||
        normalized == 'es') {
      return 'Mexico';
    }

    if (normalized.contains('franc') ||
        normalized.contains('french') ||
        normalized == 'fr') {
      return 'France';
    }

    if (normalized.contains('alem') ||
        normalized.contains('german') ||
        normalized == 'de') {
      return 'Germany';
    }

    if (normalized.contains('italia') ||
        normalized.contains('italian') ||
        normalized == 'it') {
      return 'Italy';
    }

    if (normalized.contains('polon') ||
        normalized.contains('polish') ||
        normalized == 'pl') {
      return 'Poland';
    }

    if (normalized.contains('búlg') ||
        normalized.contains('bulg') ||
        normalized == 'bg') {
      return 'Bulgaria';
    }

    if (normalized.contains('russo') ||
        normalized.contains('russian') ||
        normalized == 'ru') {
      return 'Russia';
    }

    if (normalized.contains('core') ||
        normalized.contains('korean') ||
        normalized == 'ko') {
      return 'South Korea';
    }

    if (normalized.contains('turc') ||
        normalized.contains('turk') ||
        normalized == 'tr') {
      return 'Turkey';
    }

    if (normalized.contains('romen') ||
        normalized.contains('roman') ||
        normalized == 'ro') {
      return 'Romania';
    }

    if (normalized.contains('croat') ||
        normalized.contains('hrvat') ||
        normalized == 'hr') {
      return 'Croatia';
    }

    return '';
  }

  /// 🌍 Constrói orientação de regionalização
  static String buildLocalizationGuidance(ScriptConfig config) {
    final levelInstruction = config.localizationLevel.geminiInstruction.trim();

    // Auto-detect país se necessário
    String location = config.localizacao.trim();
    final wasAutoDetected =
        location.isEmpty &&
        config.localizationLevel != LocalizationLevel.global;

    if (wasAutoDetected) {
      location = inferCountryFromLanguage(config.language);
    }

    String additionalGuidance;
    switch (config.localizationLevel) {
      case LocalizationLevel.global:
        additionalGuidance = location.isEmpty
            ? 'NÃO mencione países, cidades, moedas, instituições ou gírias específicas. O cenário deve soar universal e funcionar em QUALQUER lugar do mundo.'
            : 'Use "$location" apenas como inspiração ampla. Transforme qualquer detalhe específico em descrições neutras e universais, sem citar nomes de cidades, moedas, instituições ou gírias locais.';
        break;
      case LocalizationLevel.national:
        additionalGuidance = location.isEmpty
            ? 'Você pode mencionar o país e elementos culturais reconhecíveis nacionalmente, evitando estados, cidades ou gírias muito específicas.'
            : 'Trate "$location" como referência nacional ampla. Cite costumes e elementos que qualquer pessoa do país reconheça, evitando bairros ou gírias extremamente locais.';
        break;
      case LocalizationLevel.regional:
        additionalGuidance = location.isEmpty
            ? 'Escolha uma região coerente com o tema e traga gírias, hábitos, pontos de referência e clima típico da região.'
            : 'Inclua gírias, hábitos, pontos de referência e sensações autênticas de "$location" para reforçar o sabor regional.';
        break;
    }

    final locationLabel = location.isEmpty ? 'Não especificada' : location;
    return '''INSTRUÇÕES DE REGIONALISMO:
${levelInstruction.isEmpty ? '' : '$levelInstruction\n'}$additionalGuidance
LOCALIZAÇÃO INFORMADA: $locationLabel
''';
  }

  /// 🌍 Traduz termos de parentesco do português para o idioma do roteiro
  static String translateFamilyTerms(String text, String language) {
    final lang = language.toLowerCase().trim();

    // Se for português, retornar original
    if (lang.contains('portugu') || lang == 'pt') {
      return text;
    }

    // Obter mapa de traduções para o idioma
    final translations = familyTermsTranslations[lang];
    if (translations == null) {
      return text;
    }

    // Substituir todos os termos encontrados
    var result = text;
    for (final entry in translations.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result;
  }
}
