import zipfile
import os
from pathlib import Path

# Diretório com os arquivos do Release
release_dir = Path(r'c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\build\windows\x64\runner\Release')

# Arquivo de saída
output_file = Path(r'c:\Users\Guilherme\Desktop\flutter_gerador_v7.6.152.zip')

print(f'Criando pacote {output_file.name}...')

# Criar ZIP
with zipfile.ZipFile(output_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, dirs, files in os.walk(release_dir):
        for file in files:
            file_path = Path(root) / file
            arcname = file_path.relative_to(release_dir)
            zipf.write(file_path, arcname)
            print(f'  + {arcname}')

file_size_mb = output_file.stat().st_size / (1024 * 1024)
print(f'\nPacote criado com sucesso!')
print(f'Arquivo: {output_file}')
print(f'Tamanho: {file_size_mb:.2f} MB')
