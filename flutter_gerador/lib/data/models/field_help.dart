/// Modelo para tooltip simples (hover)
class FieldTooltip {
  final String text;
  const FieldTooltip(this.text);
}

/// Modelo para help popup detalhado
class FieldHelp {
  final String title;
  final String description;
  final List<HelpSection> sections;
  final String? tip;
  
  const FieldHelp({
    required this.title,
    required this.description,
    required this.sections,
    this.tip,
  });
}

/// Seção do help popup
class HelpSection {
  final String emoji;
  final String title;
  final String forWhat;
  final String? combineWith;
  final String? example;
  final String? avoids;
  
  const HelpSection({
    required this.emoji,
    required this.title,
    required this.forWhat,
    this.combineWith,
    this.example,
    this.avoids,
  });
}

/// Template de configuração pré-definida
class ConfigTemplate {
  final String emoji;
  final String title;
  final String description;
  final Map<String, dynamic> config;
  final String? resultPreview;
  final List<String>? avoids;
  
  const ConfigTemplate({
    required this.emoji,
    required this.title,
    required this.description,
    required this.config,
    this.resultPreview,
    this.avoids,
  });
}
