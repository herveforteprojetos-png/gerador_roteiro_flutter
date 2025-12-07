# Script para substituir métodos de filtro de duplicatas por delegates ao TextFilter
import re

file_path = r'c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

original_count = len(lines)
print(f"Original: {original_count} lines")

# 1. Encontrar _filterDuplicateParagraphs (async)
start1 = None
end1 = None
for i, line in enumerate(lines):
    if 'Future<String> _filterDuplicateParagraphs(' in line:
        # Voltar para pegar comentário
        for j in range(max(0, i-3), i):
            if 'EXECUTAR EM ISOLATE' in lines[j]:
                start1 = j
                break
        if start1 is None:
            start1 = i
    if start1 is not None and end1 is None:
        if "'addition': addition," in line:
            for j in range(i, min(i+5, len(lines))):
                if lines[j].strip() == '});':
                    end1 = j
                    break
            break

if start1 is not None and end1 is not None:
    print(f"Found _filterDuplicateParagraphs: lines {start1+1} to {end1+1}")
    new_method1 = [
        '  /// 🔧 v7.6.78: Delegado ao módulo TextFilter (SOLID)\n',
        '  Future<String> _filterDuplicateParagraphs(\n',
        '    String existing,\n',
        '    String addition,\n',
        '  ) async =>\n',
        '      TextFilter.filterDuplicateParagraphs(existing, addition);\n',
    ]
    lines = lines[:start1] + new_method1 + lines[end1+1:]
    print(f"Replaced _filterDuplicateParagraphs ({end1-start1+1} lines -> {len(new_method1)} lines)")
else:
    print(f"ERROR: Could not find _filterDuplicateParagraphs (start={start1}, end={end1})")

# 2. Encontrar _filterDuplicateParagraphsSync
start2 = None
end2 = None
for i, line in enumerate(lines):
    if 'String _filterDuplicateParagraphsSync(String existing, String addition)' in line:
        # Voltar para pegar comentário
        for j in range(max(0, i-3), i):
            if 'sncrona' in lines[j] or 'Vers' in lines[j]:
                start2 = j
                break
        if start2 is None:
            start2 = i
    if start2 is not None and end2 is None:
        if "return buffer.join('\\n\\n');" in line:
            for j in range(i, min(i+3, len(lines))):
                if lines[j].strip() == '}':
                    end2 = j
                    break
            break

if start2 is not None and end2 is not None:
    print(f"Found _filterDuplicateParagraphsSync: lines {start2+1} to {end2+1}")
    # Remover completamente, pois não será mais usado
    lines = lines[:start2] + lines[end2+1:]
    print(f"Removed _filterDuplicateParagraphsSync ({end2-start2+1} lines)")
else:
    print(f"ERROR: Could not find _filterDuplicateParagraphsSync (start={start2}, end={end2})")

# 3. Encontrar _detectDuplicateParagraphsInFinalScript
start3 = None
end3 = None
for i, line in enumerate(lines):
    if 'void _detectDuplicateParagraphsInFinalScript(String fullScript)' in line:
        # Voltar para pegar comentário
        for j in range(max(0, i-3), i):
            if 'Detecta' in lines[j] or 'duplicados' in lines[j]:
                start3 = j
                break
        if start3 is None:
            start3 = i
    if start3 is not None and end3 is None:
        # Procurar pela última chave do método
        if 'Nenhuma duplica' in line:
            for j in range(i, min(i+8, len(lines))):
                if lines[j].strip() == '}' and j > i:
                    # Confirmar que é a chave final do método
                    if j+1 < len(lines) and (lines[j+1].strip() == '' or lines[j+1].strip() == '}'):
                        end3 = j
                        break
            if end3 is not None:
                break

if start3 is not None and end3 is not None:
    print(f"Found _detectDuplicateParagraphsInFinalScript: lines {start3+1} to {end3+1}")
    new_method3 = [
        '\n',
        '  /// 🔧 v7.6.78: Delegado ao módulo TextFilter (SOLID)\n',
        '  void _detectDuplicateParagraphsInFinalScript(String fullScript) =>\n',
        '      TextFilter.detectDuplicates(fullScript);\n',
    ]
    lines = lines[:start3] + new_method3 + lines[end3+1:]
    print(f"Replaced _detectDuplicateParagraphsInFinalScript ({end3-start3+1} lines -> {len(new_method3)} lines)")
else:
    print(f"ERROR: Could not find _detectDuplicateParagraphsInFinalScript (start={start3}, end={end3})")

# Write result
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

new_count = len(lines)
print(f"\nTotal: {original_count} -> {new_count} lines (reduced by {original_count - new_count})")
