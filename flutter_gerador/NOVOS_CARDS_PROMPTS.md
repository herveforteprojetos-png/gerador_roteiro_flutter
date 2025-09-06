# Novos Cards: Prompt Protagonista e Prompt Cenário

## 📋 Resumo das Alterações

Substituição do card "Prompts Extras" por dois cards específicos e mais úteis para criação de conteúdo visual.

## 🆕 Novos Cards Implementados

### 1. **Prompt Protagonista** 👤
- **Ícone**: `Icons.person`
- **Título**: "Prompt Protagonista"
- **Descrição**: "Imagem do personagem principal"

**Funcionalidade:**
- Gera prompt em inglês para Midjourney
- Protagonista da cintura para cima
- De frente para a câmera
- Com roupa normal baseada no contexto do roteiro
- Estilo realista e fotográfico

### 2. **Prompt Cenário** 🏞️
- **Ícone**: `Icons.landscape`
- **Título**: "Prompt Cenário"
- **Descrição**: "Imagem do ambiente principal"

**Funcionalidade:**
- Gera prompt em inglês para Midjourney
- Cenário principal onde a história acontece
- Baseado na ambientação do roteiro
- Inclui localização, atmosfera e iluminação
- Estilo realista e cinematográfico
- Foco no ambiente, não em pessoas

## 🔧 Arquivos Modificados

### 1. `extra_tools_provider.dart`
**Novos métodos adicionados:**
- `generateProtagonistPrompt()` - Gera prompt do personagem principal
- `generateScenarioPrompt()` - Gera prompt do cenário

**Estado atualizado:**
- Adicionado `isGeneratingScenario` 
- Adicionado `generatedScenario`
- Adicionado `scenarioError`

### 2. `extra_tools_panel.dart`
**Cards atualizados:**
- Removido: "Prompts Extras" (genérico)
- Adicionado: "Prompt Protagonista" (específico)
- Adicionado: "Prompt Cenário" (específico)

## 🎯 Benefícios

✅ **Mais específico**: Cada card tem função clara e definida
✅ **Melhor UX**: Cards focados em necessidades reais do usuário
✅ **Prompts em inglês**: Melhor compreensão pelas IAs (Midjourney)
✅ **Contexto inteligente**: Prompts baseados no roteiro gerado
✅ **Pronto para uso**: Resultado direto para copiar no Midjourney

## 📝 Prompts Gerados

### Exemplo Protagonista:
```
"A confident middle-aged man, waist up portrait, facing camera, wearing casual blue shirt, warm smile, professional lighting, realistic photography style, detailed facial features, 4K quality --ar 16:9"
```

### Exemplo Cenário:
```
"Modern office environment, glass windows, cityscape background, natural lighting, professional workspace, clean minimalist design, corporate atmosphere, cinematic lighting, realistic photography --ar 16:9"
```

## 🚀 Como Usar

1. **Gere seu script** normalmente no aplicativo
2. **Acesse Ferramentas Extras** no painel direito
3. **Clique em "Prompt Protagonista"** para gerar descrição do personagem
4. **Clique em "Prompt Cenário"** para gerar descrição do ambiente
5. **Copie os prompts** e cole diretamente no Midjourney
6. **Gere as imagens** com prompts otimizados em inglês

---
*Cards implementados em: Dezembro 2024*
*Otimizados para: Midjourney, DALL-E, Stable Diffusion*
