#!/usr/bin/env python3
"""
Script para corrigir issues de deprecated .withOpacity() 
Substitui por .withValues(alpha: valor)
"""
import re
import os
from pathlib import Path

def fix_with_opacity(content):
    """Substitui .withOpacity(valor) por .withValues(alpha: valor)"""
    # Pattern: .withOpacity(número ou expressão)
    # Captura o valor dentro dos parênteses
    pattern = r'\.withOpacity\(([^)]+)\)'
    replacement = r'.withValues(alpha: \1)'
    return re.sub(pattern, replacement, content)

def process_file(file_path):
    """Processa um arquivo Dart"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original = f.read()
        
        fixed = fix_with_opacity(original)
        
        if fixed != original:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(fixed)
            return True
        return False
    except Exception as e:
        print(f"❌ Erro ao processar {file_path}: {e}")
        return False

def main():
    base_dir = Path(r"c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib")
    
    # Arquivos alvo (os que têm .withOpacity)
    target_files = [
        "presentation/widgets/script_output/script_result_view.dart",
        "presentation/widgets/script_output/modern_generation_progress_view.dart",
        "presentation/widgets/script_output/generation_progress_view.dart",
        "presentation/widgets/help/help_tooltip_widget.dart",
        "presentation/widgets/help/template_modal_widget.dart",
        "presentation/widgets/help/help_popup_widget.dart",
        "presentation/widgets/layout/expanded_header_widget.dart",
        "presentation/pages/home_page.dart",
        "core/theme/app_design_system.dart",
        "main.dart",
    ]
    
    fixed_count = 0
    for file_rel in target_files:
        file_path = base_dir / file_rel
        if file_path.exists():
            if process_file(file_path):
                fixed_count += 1
                print(f"✅ Corrigido: {file_rel}")
        else:
            print(f"⚠️  Não encontrado: {file_rel}")
    
    print(f"\n🎉 Total de arquivos corrigidos: {fixed_count}")
    print("✅ Deprecated .withOpacity() → .withValues(alpha:) substituído!")

if __name__ == "__main__":
    main()
