#!/usr/bin/env python3
"""Script para substituir métodos de validação de nomes por delegações ao módulo NameValidator."""

import re

file_path = r"c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart"

# Ler arquivo
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Padrão a procurar: métodos _looksLikePersonName até _isCommonWord
old_pattern = r'''  bool _looksLikePersonName\(String value\) \{
    final cleaned = value\.trim\(\);
    if \(cleaned\.isEmpty\) return false;

    // v7\.6\.63: Valida.*?
    if \(_isLikelyName\(cleaned\) && !_isCommonWord\(cleaned\)\) \{
      return true;
    \}

    // Fallback: estrutura.*?
    if \(_hasValidNameStructure\(cleaned\) && !_isCommonWord\(cleaned\)\) \{
      return true;
    \}

    return false;
  \}

  /// v7\.6\.63: Valida.*?
  /// Resolve bug de rejeitar nomes coreanos, compostos, etc\.
  bool _isLikelyName\(String text\) \{
    if \(text\.isEmpty\) return false;
    // Aceita qualquer string que comece com letra maiuscula
    // e contenha apenas letras, espacos, hifens ou apostrofos
    final nameRegex = RegExp\(
      r"\^\[A-Z\\u00C0-\\u00DC\\u0100-\\u017F\\uAC00-\\uD7AF\]\[a-zA-Z\\u00C0-\\u00FF\\u0100-\\u017F\\uAC00-\\uD7AF\\s\\-\\'\]\+\$",
    \);
    return nameRegex\.hasMatch\(text\.trim\(\)\);
  \}

  /// .*? v7\.6\.17: Verifica estrutura.*?
  bool _hasValidNameStructure\(String name\) \{
    // M.*?nimo 2 caracteres, m.*?ximo 15
    if \(name\.length < 2 \|\| name\.length > 15\) return false;

    // Primeira letra mai.*?scula
    if \(name\[0\] != name\[0\]\.toUpperCase\(\)\) return false;

    // Resto em min.*?sculas \(permite acentos\)
    final rest = name\.substring\(1\);
    if \(rest != rest\.toLowerCase\(\)\) return false;

    // Apenas letras \(permite acentua.*?o\)
    final validPattern = RegExp\(r'\^\[A-Z.*?\]\[a-z.*?\]\+\$'\);
    return validPattern\.hasMatch\(name\);
  \}

  /// .*? v7\.6\.17: Verifica se.*? palavra comum \(n.*?o-nome\)
  bool _isCommonWord\(String word\) \{
    final lower = word\.toLowerCase\(\);

    // Palavras comuns em m.*?ltiplos idiomas.*?
    final commonWords = \{
      // Portugu.*?s
      'ent.*?o', 'quando', 'depois', 'antes', 'agora', 'hoje',
      'ontem', 'sempre', 'nunca', 'muito', 'pouco', 'nada',
      'tudo', 'algo', 'algu.*?m', 'ningu.*?m', 'mesmo', 'outra',
      'outro', 'cada', 'toda', 'todo', 'todos', 'onde', 'como',
      'porque', 'por.*?m', 'mas', 'para', 'com', 'sem', 'por',
      'sobre', 'entre', 'durante', 'embora', 'enquanto',
      // English
      'then', 'when', 'after', 'before', 'now', 'today',
      'yesterday', 'always', 'never', 'much', 'little', 'nothing',
      'everything', 'something', 'someone', 'nobody', 'same', 'other',
      'each', 'every', 'where', 'because', 'however', 'though',
      'while', 'about', 'between',
      // Espa.*?ol.*?
      'entonces', 'despu.*?s', 'ahora', 'hoy', 'ayer', 'siempre',
      'mucho', 'alguien', 'nadie', 'mismo', 'pero', 'sin', 'aunque',
      'mientras',
    \};

    return commonWords\.contains\(lower\);
  \}'''

new_code = '''  /// 🎯 v7.6.73: Delegado ao módulo NameValidator (SOLID)
  bool _looksLikePersonName(String value) =>
      NameValidator.looksLikePersonName(value);

  /// 🎯 v7.6.73: Delegado ao módulo NameValidator (SOLID)
  bool _isLikelyName(String text) => NameValidator.isLikelyName(text);

  /// 🎯 v7.6.73: Delegado ao módulo NameValidator (SOLID)
  bool _hasValidNameStructure(String name) =>
      NameValidator.hasValidNameStructure(name);

  /// 🎯 v7.6.73: Delegado ao módulo NameValidator (SOLID)
  bool _isCommonWord(String word) => NameValidator.isCommonWord(word);'''

# Procurar e remover os métodos antigos (usando busca simples)
# Encontrar início: "  bool _looksLikePersonName(String value) {"
start_marker = "  bool _looksLikePersonName(String value) {"
end_marker = "return commonWords.contains(lower);\n  }"

start_idx = content.find(start_marker)
if start_idx == -1:
    print("Start marker not found!")
    exit(1)

# Encontrar fim do método _isCommonWord
temp_content = content[start_idx:]
end_idx = temp_content.find(end_marker)
if end_idx == -1:
    print("End marker not found!")
    exit(1)

end_idx = start_idx + end_idx + len(end_marker)

print(f"Found block from {start_idx} to {end_idx} ({end_idx - start_idx} chars)")

# Substituir
new_content = content[:start_idx] + new_code + content[end_idx:]

# Salvar
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Successfully replaced {end_idx - start_idx} chars with {len(new_code)} chars")
print(f"Reduction: {end_idx - start_idx - len(new_code)} chars")
