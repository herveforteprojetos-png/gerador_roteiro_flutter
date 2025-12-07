# Script para substituir _buildCharacterGuidance e _extractCharacterHintsFromTitle
# Usa posição de linha para ser mais robusto com encoding

file_path = r'c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

original_count = len(lines)
print(f"Original: {original_count} lines")

# Encontrar linha de início de _buildCharacterGuidance
start1 = None
end1 = None
for i, line in enumerate(lines):
    if 'String _buildCharacterGuidance(' in line:
        start1 = i
    if start1 is not None and end1 is None:
        # Procurar a linha com "Nunca substitua esses nomes"
        if 'Nunca substitua esses nomes' in line:
            # A próxima linha com apenas "  }" é o fim
            for j in range(i, min(i+3, len(lines))):
                if lines[j].strip() == '}':
                    end1 = j
                    break
            break

if start1 is not None and end1 is not None:
    print(f"Found _buildCharacterGuidance: lines {start1+1} to {end1+1}")
    # Substituir por delegate
    new_method1 = [
        '  /// 🔧 Delegado ao módulo CharacterGuidanceBuilder (SOLID v7.6.75)\n',
        '  String _buildCharacterGuidance(\n',
        '    ScriptConfig config,\n',
        '    CharacterTracker tracker,\n',
        '  ) =>\n',
        '      CharacterGuidanceBuilder.buildGuidance(config, tracker);\n',
    ]
    lines = lines[:start1] + new_method1 + lines[end1+1:]
    print(f"Replaced _buildCharacterGuidance ({end1-start1+1} lines -> {len(new_method1)} lines)")
else:
    print(f"ERROR: Could not find _buildCharacterGuidance (start={start1}, end={end1})")
    exit(1)

# Re-scan for _extractCharacterHintsFromTitle
start2 = None
end2 = None
for i, line in enumerate(lines):
    if 'Set<String> _extractCharacterHintsFromTitle(' in line:
        # Voltar algumas linhas para pegar os comentários
        for j in range(max(0, i-5), i):
            if 'CORRIGIDO: Extrair hints' in lines[j]:
                start2 = j
                break
        if start2 is None:
            start2 = i
    if start2 is not None and end2 is None:
        if line.strip() == 'return hints;':
            # A próxima linha com apenas "  }" é o fim
            for j in range(i, min(i+3, len(lines))):
                if lines[j].strip() == '}':
                    end2 = j
                    break
            break

if start2 is not None and end2 is not None:
    print(f"Found _extractCharacterHintsFromTitle: lines {start2+1} to {end2+1}")
    # Substituir por delegate
    new_method2 = [
        '\n',
        '  /// 🔧 Delegado ao módulo CharacterGuidanceBuilder (SOLID v7.6.75)\n',
        '  Set<String> _extractCharacterHintsFromTitle(String title, String context) =>\n',
        '      CharacterGuidanceBuilder.extractHintsFromTitle(title, context);\n',
    ]
    lines = lines[:start2] + new_method2 + lines[end2+1:]
    print(f"Replaced _extractCharacterHintsFromTitle ({end2-start2+1} lines -> {len(new_method2)} lines)")
else:
    print(f"ERROR: Could not find _extractCharacterHintsFromTitle (start={start2}, end={end2})")

# Write result
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

new_count = len(lines)
print(f"\nTotal: {original_count} -> {new_count} lines (reduced by {original_count - new_count})")
