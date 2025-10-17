═══════════════════════════════════════════════════════════════════
  GERADOR DE ROTEIROS - VERSÃO 1.5 (Build Release)
═══════════════════════════════════════════════════════════════════

📅 DATA: 15 de Outubro de 2025
🏢 DESENVOLVEDOR: Guilherme
📦 VERSÃO: 1.5 (Build de Produção)

═══════════════════════════════════════════════════════════════════
  🚀 NOVIDADES DA VERSÃO 1.5
═══════════════════════════════════════════════════════════════════

Esta versão traz CORREÇÕES CRÍTICAS que melhoram significativamente
a qualidade dos roteiros gerados:

✅ 1. CALIBRAÇÃO PERFEITA DE CONTAGEM DE PALAVRAS
   - ANTES: Roteiros variavam entre -9% e +30% do alvo
   - AGORA: Roteiros ficam entre -10% e +10% do alvo (±10%)
   - EXEMPLO: Pediu 8.600 palavras? Receberá entre 7.740 e 9.460
   - RESULTADO: Previsibilidade e controle total do tamanho

✅ 2. VALIDAÇÃO AVANÇADA DE NOMES
   - CORREÇÃO: Detecta quando mesmo nome é usado para personagens diferentes
   - EXEMPLO: "Regina" não pode ser sogra E amiga ao mesmo tempo
   - PROTEÇÃO: Sistema alerta e previne confusões narrativas
   - RESULTADO: Zero reutilização de nomes em papéis diferentes

✅ 3. DIVERSIFICAÇÃO DE METÁFORAS
   - MELHORIA: Limita uso excessivo da mesma metáfora
   - ANTES: Mesma imagem repetida 15+ vezes (saturação)
   - AGORA: Máximo 5-8 vezes + 3-4 metáforas diferentes
   - RESULTADO: Narrativa mais rica e menos previsível

═══════════════════════════════════════════════════════════════════
  📊 RESULTADOS COMPROVADOS
═══════════════════════════════════════════════════════════════════

TESTE ANTES DAS CORREÇÕES (Roteiro Helena):
  • Nota: 7.5/10 (BOM)
  • Palavras: +30% acima do alvo (+2.600 palavras extras!)
  • Erros de nomes: 1 (Regina como sogra E amiga)
  • Metáforas repetidas: 15+ vezes

TESTE DEPOIS DAS CORREÇÕES (Roteiro Odete):
  • Nota: 9.5/10 (EXCELENTE) ⭐
  • Palavras: +4% acima do alvo (apenas +350 palavras)
  • Erros de nomes: 0 (ZERO erros!)
  • Metáforas repetidas: 8 vezes + variedade

MELHORIA GERAL: +27% na qualidade dos roteiros! 🎉

═══════════════════════════════════════════════════════════════════
  💻 REQUISITOS DO SISTEMA
═══════════════════════════════════════════════════════════════════

• Sistema Operacional: Windows 10 ou superior (64-bit)
• RAM: 4 GB mínimo (8 GB recomendado)
• Espaço em Disco: 500 MB livres
• Conexão com Internet: Necessária (API Google Gemini)
• Chave API: Necessário cadastrar chave do Google Gemini

═══════════════════════════════════════════════════════════════════
  📝 INSTRUÇÕES DE INSTALAÇÃO
═══════════════════════════════════════════════════════════════════

1. Extraia TODOS os arquivos desta pasta para um local de sua escolha
   (Exemplo: C:\Programas\Gerador_Roteiros)

2. Execute o arquivo: flutter_gerador.exe

3. Na primeira execução, o sistema solicitará sua chave API do Google

4. Configure seus parâmetros de geração:
   - Idioma do roteiro
   - Quantidade de palavras/caracteres
   - Tema e subtema
   - Localização e contexto

5. Clique em "Gerar Roteiro" e aguarde!

═══════════════════════════════════════════════════════════════════
  🔑 CONFIGURAÇÃO DA API GOOGLE GEMINI
═══════════════════════════════════════════════════════════════════

1. Acesse: https://makersuite.google.com/app/apikey
2. Faça login com sua conta Google
3. Clique em "Create API Key"
4. Copie a chave gerada
5. Cole no campo "API Key" dentro do aplicativo
6. A chave será salva automaticamente

IMPORTANTE: Mantenha sua chave API em segredo! Não compartilhe.

═══════════════════════════════════════════════════════════════════
  📁 ESTRUTURA DE ARQUIVOS
═══════════════════════════════════════════════════════════════════

flutter_gerador.exe           → Executável principal
flutter_windows.dll           → Biblioteca Flutter
screen_retriever_windows_plugin.dll → Plugin de tela
window_manager_plugin.dll    → Plugin de gerenciamento de janela
data/                         → Dados e recursos do app
  ├── app.so                  → Código compilado
  ├── icudtl.dat              → Dados de internacionalização
  └── flutter_assets/         → Recursos visuais (fontes, ícones)

⚠️ NÃO DELETE NENHUM ARQUIVO! Todos são necessários para o funcionamento.

═══════════════════════════════════════════════════════════════════
  🆘 SOLUÇÃO DE PROBLEMAS
═══════════════════════════════════════════════════════════════════

PROBLEMA: Aplicativo não abre
SOLUÇÃO: 
  • Verifique se todos os arquivos foram extraídos
  • Execute como Administrador (clique direito → Executar como Administrador)
  • Verifique se o Windows Defender não bloqueou o arquivo

PROBLEMA: Erro de API Key
SOLUÇÃO:
  • Verifique se a chave está correta (sem espaços extras)
  • Confirme que a API Gemini está habilitada na sua conta Google
  • Verifique sua conexão com a internet

PROBLEMA: Roteiro não gera ou trava
SOLUÇÃO:
  • Verifique conexão com internet
  • Verifique se há limite de uso da API (Google pode ter limites gratuitos)
  • Tente reduzir a quantidade de palavras solicitadas
  • Reinicie o aplicativo

PROBLEMA: Roteiro com qualidade baixa
SOLUÇÃO:
  • Forneça mais contexto na caixa "Contexto Adicional"
  • Seja específico no tema e subtema
  • Tente gerar novamente (IA pode ter variações)

═══════════════════════════════════════════════════════════════════
  📞 SUPORTE TÉCNICO
═══════════════════════════════════════════════════════════════════

Para suporte, melhorias ou reportar bugs:
  • Contate o desenvolvedor: Guilherme
  • Descreva o problema com detalhes
  • Se possível, anexe prints da tela

═══════════════════════════════════════════════════════════════════
  📋 HISTÓRICO DE VERSÕES
═══════════════════════════════════════════════════════════════════

v1.5 (15/10/2025) - BUILD ATUAL
  ✅ Calibração perfeita de contagem de palavras (±10%)
  ✅ Validação avançada de nomes de personagens
  ✅ Diversificação de metáforas e figuras de linguagem
  ✅ Sistema de debug visual implementado
  ✅ Qualidade geral: +27% de melhoria

v1.4 (Anterior)
  • Sistema de anti-repetição básico
  • Validação de nomes da protagonista
  • Janela de contexto expandida

v1.3 (Anterior)
  • Geração multi-blocos com isolates
  • Suporte a múltiplos idiomas
  • CTAs automáticos

═══════════════════════════════════════════════════════════════════
  ⚖️ LICENÇA E TERMOS DE USO
═══════════════════════════════════════════════════════════════════

Este software é fornecido "como está", sem garantias de qualquer tipo.
O uso da API Google Gemini está sujeito aos termos de serviço do Google.
Você é responsável por qualquer conteúdo gerado usando este software.

© 2025 - Todos os direitos reservados

═══════════════════════════════════════════════════════════════════

Aproveite a nova versão e boas criações! 🎬📝✨
