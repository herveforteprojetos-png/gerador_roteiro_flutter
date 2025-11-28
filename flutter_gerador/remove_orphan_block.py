#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Remove o bloco órfão de texto literal das linhas 3894-6176 do gemini_service.dart
"""

def remove_orphan_block():
    file_path = r'lib\data\services\gemini_service.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    print(f"Total de linhas no arquivo: {len(lines)}")
    
    # Linhas a remover (índice começa em 0, então subtrair 1)
    # Linha 3894 = índice 3893
    # Linha 6176 = índice 6175
    start_index = 3893  # Linha 3894
    end_index = 6176    # Até linha 6177 (exclusive)
    
    # Verificar conteúdo das linhas
    print(f"\nLinha {start_index + 1}: {lines[start_index][:80]}")
    print(f"Linha {end_index}: {lines[end_index - 1][:80]}")
    
    # Remover as linhas
    new_lines = lines[:start_index] + lines[end_index:]
    
    print(f"\nNovas total de linhas: {len(new_lines)}")
    print(f"Linhas removidas: {len(lines) - len(new_lines)}")
    
    # Salvar arquivo
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    print(f"\n✅ Bloco órfão removido com sucesso!")
    print(f"   Arquivo: {file_path}")
    print(f"   Linhas removidas: {start_index + 1} a {end_index}")

if __name__ == '__main__':
    remove_orphan_block()
