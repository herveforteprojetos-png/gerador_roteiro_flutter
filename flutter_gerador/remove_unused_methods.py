import re

# Lê o arquivo
with open('lib/presentation/pages/home_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove o método _generateContextAutomatically (completo com comentário)
pattern1 = r'  /// Gera contexto automaticamente.*?  void _generateContextAutomatically\(\) async \{.*?\n  \}\n\n'
content = re.sub(pattern1, '', content, flags=re.DOTALL)

# Remove o método _clearContext (completo com comentário)
pattern2 = r'  /// Limpa o campo de contexto\n  void _clearContext\(\) \{.*?\n  \}\n\n'
content = re.sub(pattern2, '', content, flags=re.DOTALL)

# Remove o método _showExpandedContextEditor
pattern3 = r'  Future<void> _showExpandedContextEditor\(BuildContext context\) async \{.*?\n  \}\n\n'
content = re.sub(pattern3, '', content, flags=re.DOTALL)

# Escreve o arquivo
with open('lib/presentation/pages/home_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Métodos não usados removidos:")
print("  - _generateContextAutomatically")
print("  - _clearContext")
print("  - _showExpandedContextEditor")
