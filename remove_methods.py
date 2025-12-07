import re

# Ler arquivo
with open(r'c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Encontrar e remover o bloco de métodos extraídos
# De "/// 🎯 v7.6.17: Detecta e registra" até o fim de "_validateFamilyRelations"
pattern = r'''  /// 🎯 v7.6\.17: Detecta e registra o nome da protagonista no Bloco 1.*?/// 🔍 VALIDAÇÃO FORTALECIDA: Detecta quando um nome é reutilizado.*?detectado como: \$role \(bloco \$blockNumber\)'\);
        \}
      \}
    \}
  \}

'''

# Substituir pelo comentário de referência
replacement = '''  // 🏗️ v7.6.101: Métodos de validação de personagens extraídos para CharacterValidation module:
  //   - detectAndRegisterProtagonist()
  //   - detectProtagonistNameChange()
  //   - validateProtagonistName()
  //   - validateFamilyRelationships()
  //   - validateUniqueNames()
  //   - validateNameReuse()
  //   - validateFamilyRelations()

'''

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

if new_content != content:
    with open(r'c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Arquivo atualizado. Linhas removidas: {content.count(chr(10)) - new_content.count(chr(10))}")
else:
    print("Padrão não encontrado. Tentando abordagem alternativa...")
    
    # Abordagem alternativa: por linhas
    lines = content.split('\n')
    
    # Encontrar início (linha com "void _detectAndRegisterProtagonist")
    start_idx = None
    for i, line in enumerate(lines):
        if 'void _detectAndRegisterProtagonist(' in line:
            # Voltar algumas linhas para pegar o docstring
            start_idx = i - 2  # Pega "/// 🎯 v7.6.17..."
            break
    
    # Encontrar fim (linha após "}" de _validateFamilyRelations)
    end_idx = None
    for i, line in enumerate(lines):
        if '_detectCharacterNameChanges(' in line and 'List<Map<String, String>>' in lines[i-1]:
            # Voltar para pegar o "}" anterior e os comentários
            end_idx = i - 3  # linha antes de "/// ?? NOVA VALIDAÇÃO"
            break
    
    if start_idx and end_idx:
        new_lines = lines[:start_idx] + [
            '  // 🏗️ v7.6.101: Métodos de validação de personagens extraídos para CharacterValidation module:',
            '  //   - detectAndRegisterProtagonist()',
            '  //   - detectProtagonistNameChange()',
            '  //   - validateProtagonistName()',
            '  //   - validateFamilyRelationships()',
            '  //   - validateUniqueNames()',
            '  //   - validateNameReuse()',
            '  //   - validateFamilyRelations()',
            ''
        ] + lines[end_idx:]
        
        with open(r'c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart', 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_lines))
        print(f"Arquivo atualizado via linhas. Linhas: {len(lines)} -> {len(new_lines)}")
    else:
        print(f"Não encontrou: start_idx={start_idx}, end_idx={end_idx}")
