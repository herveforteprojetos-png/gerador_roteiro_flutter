// 🏗️ v7.6.70: Módulo extraído de gemini_service.dart
// Sistema de Período Histórico e Anacronismos
// Parte da arquitetura SOLID - Single Responsibility Principle

/// 📅 Classe para validação de períodos históricos e anacronismos
class PeriodHelper {
  PeriodHelper._(); // Previne instanciação

  /// Extrai ano de strings como "Ano 1890, Velho Oeste" ou "1920, Nova York"
  static String extractYear(String localizacao) {
    if (localizacao.trim().isEmpty) return '';

    // Padrões: "Ano 1890", "ano 1920", "Year 1850", "1776"
    final yearRegex = RegExp(r'(?:Ano|ano|Year|year)?\s*(\d{4})');
    final match = yearRegex.firstMatch(localizacao);

    if (match != null) {
      final year = match.group(1)!;
      final yearInt = int.tryParse(year);

      // Validar se é um ano razoável (1000-2100)
      if (yearInt != null && yearInt >= 1000 && yearInt <= 2100) {
        return year;
      }
    }

    return '';
  }

  /// Retorna lista de anacronismos a evitar baseado no ano
  static List<String> getAnachronismList(String year) {
    if (year.isEmpty) return [];

    final yearInt = int.tryParse(year);
    if (yearInt == null) return [];

    final anachronisms = <String>[];

    // Tecnologias por período (data da invenção/popularização)
    if (yearInt < 1876) anachronisms.add('Telefone (inventado em 1876)');
    if (yearInt < 1879) {
      anachronisms.add('Lâmpada elétrica (inventada em 1879)');
    }
    if (yearInt < 1886) {
      anachronisms.add('Automóvel a gasolina (inventado em 1886)');
    }
    if (yearInt < 1895) anachronisms.add('Cinema (inventado em 1895)');
    if (yearInt < 1903) anachronisms.add('Avião (inventado em 1903)');
    if (yearInt < 1920) {
      anachronisms.add('Rádio comercial (popularizado em 1920)');
    }
    if (yearInt < 1927) anachronisms.add('Cinema sonoro (1927)');
    if (yearInt < 1936) anachronisms.add('Televisão comercial (1936)');
    if (yearInt < 1946) anachronisms.add('Computador eletrônico (ENIAC 1946)');
    if (yearInt < 1950) anachronisms.add('Cartão de crédito (1950)');
    if (yearInt < 1969) anachronisms.add('Internet/ARPANET (1969)');
    if (yearInt < 1973) anachronisms.add('Telefone celular (1973)');
    if (yearInt < 1981) anachronisms.add('Computador pessoal (IBM PC 1981)');
    if (yearInt < 1983) anachronisms.add('Internet comercial (1983)');
    if (yearInt < 1991) anachronisms.add('World Wide Web (1991)');
    if (yearInt < 2001) anachronisms.add('Wikipedia (2001)');
    if (yearInt < 2004) anachronisms.add('Facebook (2004)');
    if (yearInt < 2006) anachronisms.add('Twitter (2006)');
    if (yearInt < 2007) anachronisms.add('iPhone/Smartphone moderno (2007)');

    return anachronisms;
  }

  /// Retorna elementos de época que DEVEM ser incluídos
  static List<String> getPeriodElements(String year, String? genre) {
    if (year.isEmpty) return [];

    final yearInt = int.tryParse(year);
    if (yearInt == null) return [];

    final elements = <String>[];

    // 🤠 WESTERN (1850-1900)
    if (genre == 'western' && yearInt >= 1850 && yearInt <= 1900) {
      elements.addAll([
        'Revólver (Colt Peacemaker comum após 1873)',
        'Saloon com portas batentes',
        'Cavalo como transporte principal',
        'Diligência (stagecoach)',
        'Xerife e delegados',
        'Lei do mais rápido',
      ]);

      if (yearInt >= 1869) {
        elements.add('Ferrovia transcontinental (completada em 1869)');
      }
      if (yearInt >= 1844) {
        elements.add('Telégrafo para comunicação à distância');
      }
    }

    // 📜 ELEMENTOS GERAIS POR PERÍODO
    if (yearInt < 1850) {
      // Era pré-industrial
      elements.addAll([
        'Iluminação a vela ou lampião a óleo',
        'Transporte por carroça ou cavalo',
        'Cartas entregues por mensageiro',
        'Vestimentas formais e conservadoras',
        'Sociedade rigidamente hierárquica',
      ]);
    } else if (yearInt >= 1850 && yearInt < 1900) {
      // Era vitoriana/industrial
      elements.addAll([
        'Iluminação a gás nas cidades',
        'Trem a vapor (ferrovias em expansão)',
        'Telégrafo para comunicação',
        'Fotografia (daguerreótipo)',
        'Jornais impressos',
      ]);
    } else if (yearInt >= 1900 && yearInt < 1920) {
      // Belle Époque / Era Eduardiana
      elements.addAll([
        'Primeiros automóveis (ainda raros)',
        'Telefone fixo (casas ricas)',
        'Cinema mudo',
        'Iluminação elétrica nas cidades',
        'Fonógrafo (música gravada)',
      ]);
    } else if (yearInt >= 1920 && yearInt < 1945) {
      // Entre-guerras
      elements.addAll([
        'Rádio como principal entretenimento',
        'Cinema sonoro (após 1927)',
        'Automóveis mais comuns',
        'Telefone residencial',
        'Aviões comerciais (raros)',
      ]);
    } else if (yearInt >= 1945 && yearInt < 1970) {
      // Pós-guerra / Era de ouro
      elements.addAll([
        'Televisão em preto e branco',
        'Automóvel como padrão',
        'Eletrodomésticos modernos',
        'Cinema em cores',
        'Discos de vinil',
      ]);
    } else if (yearInt >= 1970 && yearInt < 1990) {
      // Era moderna
      elements.addAll([
        'Televisão em cores',
        'Telefone residencial fixo',
        'Fitas cassete e VHS',
        'Primeiros computadores pessoais (após 1981)',
        'Walkman (música portátil)',
      ]);
    } else if (yearInt >= 1990 && yearInt < 2007) {
      // Era digital inicial
      elements.addAll([
        'Internet discada/banda larga',
        'Celular básico (sem smartphone)',
        'E-mail',
        'CDs e DVDs',
        'Computadores pessoais comuns',
      ]);
    } else if (yearInt >= 2007 && yearInt <= 2025) {
      // Era dos smartphones
      elements.addAll([
        'Smartphone touchscreen',
        'Redes sociais (Facebook, Twitter, Instagram)',
        'Wi-Fi ubíquo',
        'Streaming de vídeo/música',
        'Apps para tudo',
      ]);
    }

    return elements;
  }

  /// Gera seção de anacronismos formatada para prompt
  static String buildAnachronismSection(String year) {
    final anachronisms = getAnachronismList(year);
    if (anachronisms.isEmpty) return '';

    return '''

**⛔ ANACRONISMOS A EVITAR (Não existiam em $year):**
${anachronisms.map((a) => '  ❌ $a').join('\n')}
''';
  }

  /// Gera seção de elementos de período formatada para prompt
  static String buildPeriodSection(String year, String? genre) {
    final periodElements = getPeriodElements(year, genre);
    if (periodElements.isEmpty) return '';

    return '''

**✅ ELEMENTOS DO PERÍODO A INCLUIR (Existiam em $year):**
${periodElements.map((e) => '  ✓ $e').join('\n')}
''';
  }

  /// Verifica se uma tecnologia/conceito seria anacronismo para o ano dado
  static bool isAnachronism(String year, String technology) {
    final yearInt = int.tryParse(year);
    if (yearInt == null) return false;

    final techLower = technology.toLowerCase();

    // Mapeamento de tecnologias para ano de invenção
    final techYears = <String, int>{
      'telefone': 1876,
      'lampada': 1879,
      'lâmpada': 1879,
      'automovel': 1886,
      'automóvel': 1886,
      'carro': 1886,
      'cinema': 1895,
      'aviao': 1903,
      'avião': 1903,
      'radio': 1920,
      'rádio': 1920,
      'televisao': 1936,
      'televisão': 1936,
      'tv': 1936,
      'computador': 1946,
      'cartao de credito': 1950,
      'cartão de crédito': 1950,
      'internet': 1969,
      'celular': 1973,
      'pc': 1981,
      'web': 1991,
      'wikipedia': 2001,
      'facebook': 2004,
      'twitter': 2006,
      'smartphone': 2007,
      'iphone': 2007,
    };

    for (final entry in techYears.entries) {
      if (techLower.contains(entry.key)) {
        return yearInt < entry.value;
      }
    }

    return false;
  }
}
