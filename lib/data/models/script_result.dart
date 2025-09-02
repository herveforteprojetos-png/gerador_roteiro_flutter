class ScriptResult {
  final String scriptText;
  final int wordCount;
  final int charCount;
  final int paragraphCount;
  final int readingTime;

  ScriptResult({
    required this.scriptText,
    required this.wordCount,
    required this.charCount,
    required this.paragraphCount,
    required this.readingTime,
  });
}
