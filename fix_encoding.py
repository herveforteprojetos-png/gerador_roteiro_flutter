# -*- coding: utf-8 -*-
import codecs

# Ler o arquivo
with codecs.open(r'c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\scripting\script_validator.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Substituições UTF-8
replacements = [
    ('ðŸ"', '🔍'),
    ('TÃTULO', 'TÍTULO'),
]

modified = content
found = 0
for old, new in replacements:
    if old in modified:
        modified = modified.replace(old, new)
        found += 1
        print(f'OK: {repr(old)} -> {repr(new)}')
    else:
        print(f'NAO ENCONTRADO: {repr(old)}')

# Salvar
with codecs.open(r'c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\scripting\script_validator.dart', 'w', encoding='utf-8') as f:
    f.write(modified)

print(f'\n{found} substituicoes feitas!')
