import re

# Lê o arquivo
with open('lib/presentation/pages/home_page.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Procura e remove os três métodos
output_lines = []
skip_lines = False
brace_count = 0
method_start_line = -1

for i, line in enumerate(lines, 1):
    # Detecta início dos métodos a remover
    if ('void _generateContextAutomatically()' in line or 
        'void _clearContext()' in line or
        'Future<void> _showExpandedContextEditor' in line):
        skip_lines = True
        brace_count = 0
        method_start_line = i
        print(f"Removendo método na linha {i}: {line.strip()[:60]}")
        continue
    
    if skip_lines:
        # Conta chaves para saber quando o método termina
        brace_count += line.count('{') - line.count('}')
        if brace_count <= 0 and '}' in line:
            skip_lines = False
            print(f"Método removido até linha {i}")
            continue
   
    if not skip_lines:
        output_lines.append(line)

# Remove linhas que ainda referenciam contextController
final_lines = []
skip_block = False
for line in output_lines:
    # Pula o listener do context
    if 'ref.listen(auxiliaryToolsProvider' in line:
        skip_block = True
        brace_count = 0
        
    if skip_block:
        brace_count += line.count('{') - line.count('}')
        if brace_count <= 0 and '});' in line:
            skip_block = False
        continue
        
    # Pula linha que passa contextController para ExpandedHeaderWidget
    if 'ExpandedHeaderWidget(contextController:' in line:
        final_lines.append('            const ExpandedHeaderWidget(),\n')
        continue
        
    final_lines.append(line)

# Escreve o arquivo
with open('lib/presentation/pages/home_page.dart', 'w', encoding='utf-8') as f:
    f.writelines(final_lines)

print(f"\n✅ Arquivo atualizado!")
print(f"Linhas originais: {len(lines)}")
print(f"Linhas finais: {len(final_lines)}")
print(f"Linhas removidas: {len(lines) - len(final_lines)}")
