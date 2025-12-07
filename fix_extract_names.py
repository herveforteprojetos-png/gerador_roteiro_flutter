# Script para substituir _extractNamesFromText e _isCommonPhrase por delegates ao NameValidator
import re

file_path = r'c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

original_count = len(lines)
print(f"Original: {original_count} lines")

# 1. Encontrar _extractNamesFromText
start1 = None
end1 = None
for i, line in enumerate(lines):
    if 'Set<String> _extractNamesFromText(String text)' in line:
        start1 = i
    if start1 is not None and end1 is None:
        # Procurar "return names;" dentro deste método
        if line.strip() == 'return names;':
            # Próxima linha com "  }" é o fim
            for j in range(i, min(i+3, len(lines))):
                if lines[j].strip() == '}':
                    end1 = j
                    break
            break

if start1 is not None and end1 is not None:
    print(f"Found _extractNamesFromText: lines {start1+1} to {end1+1}")
    new_method1 = [
        '  /// 🔧 v7.6.76: Delegado ao módulo NameValidator (SOLID)\n',
        '  Set<String> _extractNamesFromText(String text) =>\n',
        '      NameValidator.extractNamesFromText(text);\n',
    ]
    lines = lines[:start1] + new_method1 + lines[end1+1:]
    print(f"Replaced _extractNamesFromText ({end1-start1+1} lines -> {len(new_method1)} lines)")
else:
    print(f"ERROR: Could not find _extractNamesFromText (start={start1}, end={end1})")

# 2. Encontrar _isCommonPhrase
start2 = None
end2 = None
for i, line in enumerate(lines):
    if 'bool _isCommonPhrase(String phrase)' in line:
        # Voltar para pegar o comentário
        for j in range(max(0, i-3), i):
            if 'v7.6.30' in lines[j] or 'Verifica se frase' in lines[j]:
                start2 = j
                break
        if start2 is None:
            start2 = i
    if start2 is not None and end2 is None:
        if 'return commonPhrases.contains(phraseLower);' in line:
            # Próxima linha com "  }" é o fim
            for j in range(i, min(i+3, len(lines))):
                if lines[j].strip() == '}':
                    end2 = j
                    break
            break

if start2 is not None and end2 is not None:
    print(f"Found _isCommonPhrase: lines {start2+1} to {end2+1}")
    new_method2 = [
        '\n',
        '  /// 🔧 v7.6.76: Delegado ao módulo NameValidator (SOLID)\n',
        '  bool _isCommonPhrase(String phrase) =>\n',
        '      NameValidator.isCommonPhrase(phrase);\n',
    ]
    lines = lines[:start2] + new_method2 + lines[end2+1:]
    print(f"Replaced _isCommonPhrase ({end2-start2+1} lines -> {len(new_method2)} lines)")
else:
    print(f"ERROR: Could not find _isCommonPhrase (start={start2}, end={end2})")

# Write result
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

new_count = len(lines)
print(f"\nTotal: {original_count} -> {new_count} lines (reduced by {original_count - new_count})")
