class ScriptConfig {
  final String apiKey;
  final String model;
  final String title;
  final String context;
  final String measureType;
  final int quantity;
  final String language;
  final bool includeCallToAction;

  ScriptConfig({
    required this.apiKey,
    required this.model,
    required this.title,
    required this.context,
    required this.measureType,
    required this.quantity,
    required this.language,
    required this.includeCallToAction,
  });
}
