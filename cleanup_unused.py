#!/usr/bin/env python3
"""Remove métodos não usados."""

file_path = r"c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Encontrar e remover os métodos não usados
old_block = '''  /// 🎯 v7.6.73: Delegado ao módulo NameValidator (SOLID)
  bool _hasValidNameStructure(String name) =>
      NameValidator.hasValidNameStructure(name);

  /// 🎯 v7.6.73: Delegado ao módulo NameValidator (SOLID)
  bool _isCommonWord(String word) => NameValidator.isCommonWord(word);

'''

if old_block in content:
    content = content.replace(old_block, '')
    print("Removed unused methods")
else:
    print("Block not found - checking for variations")
    # Tentar encontrar linha por linha
    lines = content.split('\n')
    new_lines = []
    skip_count = 0
    for i, line in enumerate(lines):
        if skip_count > 0:
            skip_count -= 1
            continue
        if '_hasValidNameStructure' in line or '_isCommonWord' in line:
            # Pular esta linha e as próximas relacionadas
            if 'bool _hasValidNameStructure' in line:
                skip_count = 2  # Pular a linha e mais 2
                print(f"Skipping _hasValidNameStructure at line {i}")
                continue
            elif 'bool _isCommonWord' in line:
                skip_count = 1  # Pular a linha e mais 1
                print(f"Skipping _isCommonWord at line {i}")
                continue
        new_lines.append(line)
    content = '\n'.join(new_lines)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
