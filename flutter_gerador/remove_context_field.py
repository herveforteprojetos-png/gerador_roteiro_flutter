import re

# Lê o arquivo
with open('lib/presentation/pages/home_page.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Encontra e substitui o bloco do campo de contexto
in_context_block = False
start_line = -1
indent_level = 0

for i, line in enumerate(lines):
    # Detecta o início do bloco
    if 'CAMPO CONTEXTO E BOTÃO GERAR (estado inicial)' in line or 'CAMPO CONTEXTO E BOTÃƒO GERAR (estado inicial)' in line:
        in_context_block = True
        start_line = i - 1  # Começa no "else" da linha anterior
        print(f"Encontrado bloco de contexto na linha {i+1}")
        continue
    
    # Conta o nível de indentação quando encontramos o bloco
    if in_context_block and start_line > 0:
        # Procura pelo fechamento correto do Container
        if 'Widget _buildScriptMetrics' in line:
            end_line = i - 3  # Volta algumas linhas para não pegar o fechamento do método
            print(f"Fim do bloco na linha {i-2}")
            
            # Substitui todo o bloco por um botão simples
            replacement = """                  else
                    // BOTÃO GERAR ROTEIRO (estado inicial)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: SizedBox(
                          width: 250,
                          height: 60,
                          child: ElevatedButton(
                            onPressed:
                                generationState.isGenerating ||
                                    !configNotifier.isValid
                                ? null
                                : _generateScript,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.fireOrange,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: generationState.isGenerating
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Gerar Roteiro',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
"""
            
            # Reconstrói o arquivo
            new_lines = lines[:start_line] + [replacement] + lines[end_line:]
            
            # Escreve o arquivo
            with open('lib/presentation/pages/home_page.dart', 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            
            print(f"✅ Campo 'Contexto do Roteiro' removido!")
            print(f"Linhas removidas: {start_line+1} até {end_line+1}")
            print(f"Total de linhas removidas: {end_line - start_line}")
            break

print("✅ Arquivo atualizado com sucesso!")
