import re

# Lê o arquivo
with open('lib/presentation/pages/home_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove _showErrorDialog
pattern1 = r'  void _showErrorDialog\(String message\) \{.*?\n  \}\n\n'
content = re.sub(pattern1, '', content, flags=re.DOTALL)

# Remove _showSuccessDialog
pattern2 = r'  void _showSuccessDialog\(String message\) \{.*?\n  \}\n\n'
content = re.sub(pattern2, '', content, flags=re.DOTALL)

# Escreve o arquivo
with open('lib/presentation/pages/home_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Métodos de dialog não usados removidos:")
print("  - _showErrorDialog")
print("  - _showSuccessDialog")
