#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Remove o bloco try{} órfão duplicado nas linhas 3889-3894
"""

def fix_duplicate_try():
    file_path = r'lib\data\services\gemini_service.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    print(f"Total de linhas: {len(lines)}")
    
    # Remover linhas 3889-3894 (índices 3888-3893)
    # Linha 3889: try {
    # Linha 3890: // comentário
    # Linha 3891: // comentário 
    # Linha 3892: 
    # Linha 3893: // comentário órfão
    start_remove = 3888  # Linha 3889 (try órfão)
    end_remove = 3893    # Linha 3894 (última linha antes do if válido)
    
    print(f"\nRemovendo linhas {start_remove + 1} a {end_remove + 1}:")
    for i in range(start_remove, end_remove + 1):
        print(f"  {i + 1}: {lines[i][:80]}")
    
    # Criar novo conteúdo
    new_lines = lines[:start_remove] + lines[end_remove + 1:]
    
    print(f"\nNovo total de linhas: {len(new_lines)}")
    
    # Salvar
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    print("✅ Bloco try órfão removido!")

if __name__ == '__main__':
    fix_duplicate_try()
