# Script para substituir _validateNamesInText e _extractNamesFromSnippet por delegates
import re

file_path = r'c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

original_count = len(lines)
print(f"Original: {original_count} lines")

# 1. Encontrar _extractNamesFromSnippet
start1 = None
end1 = None
for i, line in enumerate(lines):
    if 'Map<String, int> _extractNamesFromSnippet(String snippet)' in line:
        start1 = i
    if start1 is not None and end1 is None:
        if line.strip() == 'return counts;':
            for j in range(i, min(i+3, len(lines))):
                if lines[j].strip() == '}':
                    end1 = j
                    break
            break

if start1 is not None and end1 is not None:
    print(f"Found _extractNamesFromSnippet: lines {start1+1} to {end1+1}")
    new_method1 = [
        '  /// 🔧 v7.6.77: Delegado ao módulo NameValidator (SOLID)\n',
        '  Map<String, int> _extractNamesFromSnippet(String snippet) =>\n',
        '      NameValidator.extractNamesFromSnippet(snippet);\n',
    ]
    lines = lines[:start1] + new_method1 + lines[end1+1:]
    print(f"Replaced _extractNamesFromSnippet ({end1-start1+1} lines -> {len(new_method1)} lines)")
else:
    print(f"ERROR: Could not find _extractNamesFromSnippet (start={start1}, end={end1})")

# 2. Encontrar _validateNamesInText
start2 = None
end2 = None
for i, line in enumerate(lines):
    if 'List<String> _validateNamesInText(' in line:
        # Voltar para pegar comentário
        for j in range(max(0, i-3), i):
            if 'Valida se' in lines[j] or 'duplicados' in lines[j]:
                start2 = j
                break
        if start2 is None:
            start2 = i
    if start2 is not None and end2 is None:
        if line.strip() == 'return duplicates;':
            for j in range(i, min(i+3, len(lines))):
                if lines[j].strip() == '}':
                    end2 = j
                    break
            break

if start2 is not None and end2 is not None:
    print(f"Found _validateNamesInText: lines {start2+1} to {end2+1}")
    new_method2 = [
        '\n',
        '  /// 🔧 v7.6.77: Delegado ao módulo NameValidator (SOLID)\n',
        '  List<String> _validateNamesInText(\n',
        '    String newBlock,\n',
        '    Set<String> previousNames,\n',
        '  ) =>\n',
        '      NameValidator.validateNamesInText(newBlock, previousNames);\n',
    ]
    lines = lines[:start2] + new_method2 + lines[end2+1:]
    print(f"Replaced _validateNamesInText ({end2-start2+1} lines -> {len(new_method2)} lines)")
else:
    print(f"ERROR: Could not find _validateNamesInText (start={start2}, end={end2})")

# Write result
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

new_count = len(lines)
print(f"\nTotal: {original_count} -> {new_count} lines (reduced by {original_count - new_count})")
