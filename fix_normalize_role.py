#!/usr/bin/env python3
"""Script para substituir _normalizeRole por delegação ao RolePatterns."""

file_path = r"c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Encontrar início do método _normalizeRole
start_marker = "  /// 🔧 v7.6.26: Normaliza papel SELETIVAMENTE"
if start_marker not in content:
    # Tentar variação com encoding diferente
    start_marker = "  String _normalizeRole(String role) {"

start_idx = content.find(start_marker)
if start_idx == -1:
    print("Start marker not found! Trying alternative...")
    # Procurar pelo padrão do método
    import re
    match = re.search(r'  String _normalizeRole\(String role\) \{', content)
    if match:
        # Voltar para pegar o comentário
        comment_start = content.rfind('\n\n', 0, match.start())
        if comment_start != -1:
            start_idx = comment_start + 2
        else:
            start_idx = match.start()
        print(f"Found method at position {start_idx}")
    else:
        print("Method not found!")
        exit(1)

# Encontrar fim do método (próximo método ou fechamento de bloco)
method_body_start = content.find("{", start_idx)
if method_body_start == -1:
    print("Method body not found!")
    exit(1)

# Contar chaves para encontrar fim do método
brace_count = 0
end_idx = method_body_start
for i in range(method_body_start, len(content)):
    if content[i] == '{':
        brace_count += 1
    elif content[i] == '}':
        brace_count -= 1
        if brace_count == 0:
            end_idx = i + 1
            break

print(f"Found method from {start_idx} to {end_idx} ({end_idx - start_idx} chars)")
print(f"Method preview: {content[start_idx:start_idx+100]}...")

# Novo código delegando para RolePatterns
new_code = '''  /// 🎯 v7.6.74: Delegado ao módulo RolePatterns (SOLID)
  String _normalizeRole(String role) =>
      RolePatterns.normalizeRoleSelective(role);'''

# Substituir
new_content = content[:start_idx] + new_code + content[end_idx:]

# Salvar
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Successfully replaced {end_idx - start_idx} chars with {len(new_code)} chars")
print(f"Reduction: {end_idx - start_idx - len(new_code)} chars")
