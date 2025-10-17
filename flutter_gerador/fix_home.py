import re

# Lê o arquivo
with open('lib/presentation/pages/home_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove o listener do auxiliaryToolsProvider (linhas 409-420)
pattern = r"    ref\.listen\(auxiliaryToolsProvider,.*?\}\);[ \t]*\n[ \t]*\n"
content = re.sub(pattern, '', content, flags=re.DOTALL)

# Remove contextController do ExpandedHeaderWidget
content = content.replace(
    'ExpandedHeaderWidget(contextController: contextController)',
    'const ExpandedHeaderWidget()'
)

# Escreve o arquivo
with open('lib/presentation/pages/home_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Arquivo corrigido!")
print("- Removido listener do auxiliaryToolsProvider")
print("- Removido contextController do ExpandedHeaderWidget")
