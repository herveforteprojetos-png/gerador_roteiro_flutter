import re

# Lê o arquivo
with open('lib/presentation/pages/home_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove o comentário e a classe _ExpandedContextDialog completa
# Procura desde o comentário até o fechamento da classe (antes de _ExpandedScriptDialog)
pattern = r'// Widget separado para o dialog expandido com contador dinÃ¢mico\nclass _ExpandedContextDialog.*?(?=// Widget separado para o dialog expandido de ediÃ§Ã£o de roteiro)'
content = re.sub(pattern, '', content, flags=re.DOTALL)

# Escreve o arquivo
with open('lib/presentation/pages/home_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Widget _ExpandedContextDialog removido completamente!")
