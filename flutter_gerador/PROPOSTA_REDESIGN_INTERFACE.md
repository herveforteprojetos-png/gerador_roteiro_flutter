# 🎨 PROPOSTA DE REDESIGN DA INTERFACE

## 📊 ANÁLISE DE IMPACTO DOS PARÂMETROS ATUAIS

### **PARÂMETROS DE ALTO IMPACTO** ✅ (Manter e destacar)

| Campo | Impacto | Por quê |
|-------|---------|---------|
| **Título** | 10/10 | Gancho de abertura, define primeira cena |
| **☑️ Começar com frase do título** | 9/10 | Transforma título em primeira frase narrativa |
| **Perspectiva Narrativa** | 9/10 | Muda completamente a voz (1ª vs 3ª pessoa) |
| **Tema + Subtema** | 8/10 | Direciona toda linha narrativa |
| **Quantidade de palavras** | 10/10 | Define extensão precisa com validação |
| **Idioma** | 10/10 | Primeira linha do prompt, afeta tudo |

### **PARÂMETROS DE MÉDIO IMPACTO** ⚠️ (Revisar apresentação)

| Campo | Impacto | Problema Atual |
|-------|---------|----------------|
| **Localização** | 7/10 | Funciona mas IA pode interpretar vagamente |
| **Regionalismo** | 6/10 | Só 2 opções (Global/Local), poderia ter mais |
| **Tipo de História** | 5/10 | Só afeta banco de nomes (Normal vs Western) |

### **PARÂMETROS DE BAIXO IMPACTO** ❌ (Remover ou transformar)

| Campo | Impacto | Por quê Falha |
|-------|---------|---------------|
| **Contexto do Roteiro** | 3/10 | • Perdido no meio do prompt (linha única)<br>• Sem destaque visual no prompt<br>• IA prioriza Tema/Subtema sobre ele<br>• Placeholder genérico "Descreva o enredo..."<br>• Usuário perde tempo escrevendo, IA ignora |

---

## 🚨 PROBLEMA PRINCIPAL: "CONTEXTO DO ROTEIRO"

### **Como funciona hoje:**

**Na Interface:**
```
┌─────────────────────────────────────────────────┐
│ Contexto do Roteiro                             │
│ ┌─────────────────────────────────────────────┐ │
│ │ Descreva o enredo, personagens principais,  │ │
│ │ cenário, tom da história...                 │ │
│ │                                             │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

**No Prompt enviado à IA (linha 2688):**
```
[...300 linhas de regras sobre nomes, metáforas, consistência...]
TEMA: Vingança
SUBTEMA: Vingança Destrutiva
LOCALIZAÇÃO: Não especificado
CONTEXTO ADICIONAL: Descreva o enredo, personagens principais, cenário...
[...mais 150 linhas de regras...]
```

### **Por quê a IA ignora:**

1. **Posição ruim:** Linha única perdida em prompt de 450+ linhas
2. **Sem peso:** Nenhuma formatação especial (sem `🚨`, `━━━`, `OBRIGATÓRIO`)
3. **Conflito hierárquico:** Tema/Subtema têm mais destaque, IA prioriza eles
4. **Placeholder genérico:** Parece exemplo, não instrução real

### **Evidência:**

```dart
// Linha 2688 do gemini_service.dart
'${contextTranslationNote}${labels['additionalContext']}: ${c.context}\n'

// Compare com Tema (linha 2675-2677) - tem seção dedicada:
final temaSection = c.tema == 'Livre (Sem Tema)' 
    ? '// Modo Livre: Desenvolva o roteiro baseado APENAS no título e contexto fornecidos\n'
    : '${labels['theme']}: ${c.tema}\n${labels['subtheme']}: ${c.subtema}\n';
```

**Conclusão:** Tema tem lógica condicional e destaque. Contexto é apenas uma linha genérica.

---

## 💡 PROPOSTA 1: REMOVER "CONTEXTO DO ROTEIRO"

### **Justificativa:**

✅ **Impacto mínimo:** 3/10 de influência real  
✅ **Frustrante para usuário:** Perde tempo escrevendo, IA gera genérico do mesmo jeito  
✅ **Redundante:** Tema + Subtema já direcionam a narrativa  
✅ **Simplifica UI:** Uma caixa de texto gigante a menos  

### **Como compensar a remoção:**

**OPÇÃO A - Fortalecer Tema/Subtema:**
- Adicionar mais opções de subtemas (atualmente apenas ~3 por tema)
- Criar combinações mais específicas que capturam a intenção do usuário

**OPÇÃO B - Transformar em campo opcional "Notas Rápidas":**
```
┌─────────────────────────────────────────────────┐
│ 💡 Notas Rápidas (opcional)                     │
│ ┌─────────────────────────────────────────────┐ │
│ │ Ex: "protagonista é médica", "final feliz"  │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```
- Campo menor (1-2 linhas)
- Expectativa clara: apenas diretrizes, não enredo completo
- Usuário não frustra esperando controle total

---

## ➕ PROPOSTA 2: ADICIONAR CAMPOS DE ALTO IMPACTO

### **1. TOM NARRATIVO** (Impacto estimado: 8/10)

```
┌─────────────────────────────────────────────────┐
│ Tom da Narrativa                                │
│ ┌─────────────────────────────────────────────┐ │
│ │ ▼ Reflexivo e Introspectivo                 │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘

Opções:
• Reflexivo e Introspectivo (muitos pensamentos dos personagens)
• Ação e Movimento (eventos rápidos, pouca reflexão)
• Equilibrado (mix de ação e reflexão)
• Poético e Lírico (linguagem elaborada, metáforas)
• Direto e Simples (linguagem clara, sem floreios)
```

**Impacto no prompt:**
```dart
// Adicionar na linha 2690 (depois de localizationGuidance)
'TOM NARRATIVO OBRIGATÓRIO: ${_getToneGuidance(c.narrativeTone)}\n'

String _getToneGuidance(String tone) {
  switch (tone) {
    case 'reflective':
      return '🧠 REFLEXIVO: Priorize pensamentos e sentimentos dos personagens. Use monólogos internos longos.';
    case 'action':
      return '⚡ AÇÃO: Mantenha ritmo rápido. Foque em eventos e diálogos, minimize reflexões.';
    case 'poetic':
      return '🎭 POÉTICO: Use linguagem elaborada e metáforas variadas. Crie atmosferas ricas.';
    case 'simple':
      return '📝 DIRETO: Linguagem clara e objetiva. Evite metáforas excessivas.';
    default:
      return '⚖️ EQUILIBRADO: Balance ação e reflexão. Varie entre eventos e pensamentos.';
  }
}
```

**Vantagem:** Controla diretamente o estilo que o usuário recebe.

---

### **2. EXTENSÃO DE DIÁLOGOS** (Impacto estimado: 7/10)

```
┌─────────────────────────────────────────────────┐
│ Quantidade de Diálogos                          │
│ ┌─────────────────────────────────────────────┐ │
│ │ ▼ Moderada (30-40% da história)            │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘

Opções:
• Mínima (10-20%) - Mais narração, poucos diálogos
• Moderada (30-40%) - Equilíbrio clássico
• Alta (50-60%) - História driven por conversas
```

**Impacto no prompt:**
```dart
'DIÁLOGOS: ${_getDialogueGuidance(c.dialogueLevel)}\n'

String _getDialogueGuidance(String level) {
  switch (level) {
    case 'minimal':
      return 'Use poucos diálogos (10-20%). Priorize narração e descrição.';
    case 'high':
      return 'Use muitos diálogos (50-60%). Desenvolva a história através de conversas.';
    default:
      return 'Use diálogos moderadamente (30-40%). Balance com narração.';
  }
}
```

---

### **3. CONFIGURAÇÃO DE PERSONAGENS** (Impacto estimado: 9/10)

**Problema atual:** Só temos "Nome da Protagonista" e "Personagem Secundário"

**Proposta - Expandir para:**

```
┌─────────────────────────────────────────────────┐
│ Personagens Principais                          │
│ ┌─────────────────────────────────────────────┐ │
│ │ 👤 Protagonista: [Maria]                    │ │
│ │ 💼 Profissão: [Professora] (opcional)       │ │
│ │ 🎂 Idade aproximada: [35-45 anos]          │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ 👥 Personagens Secundários (opcional)       │ │
│ │ [João] - Marido                             │ │
│ │ [+ Adicionar]                               │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

**Vantagem:** 
- IA recebe informações estruturadas (não texto livre)
- Evita inventar profissões/idades aleatórias
- Sistema de tracking já funciona perfeitamente (v1.7)

---

### **4. FINAL DESEJADO** (Impacto estimado: 8/10)

```
┌─────────────────────────────────────────────────┐
│ Tipo de Final                                   │
│ ┌─────────────────────────────────────────────┐ │
│ │ ▼ Livre (IA decide)                         │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘

Opções:
• Livre (IA decide baseado na história)
• Feliz (resolução positiva)
• Trágico (final sombrio)
• Aberto (sem resolução definitiva)
• Esperançoso (superação, novo começo)
```

**Impacto no prompt:**
```dart
// Adicionar no último bloco apenas
if (current == total && c.endingType != 'free') {
  prompt += '\n🎬 FINAL OBRIGATÓRIO: ${_getEndingGuidance(c.endingType)}\n';
}

String _getEndingGuidance(String type) {
  switch (type) {
    case 'happy':
      return 'Termine com resolução positiva. Protagonista supera desafios.';
    case 'tragic':
      return 'Final sombrio. Protagonista falha ou perde algo importante.';
    case 'open':
      return 'Deixe questões em aberto. Não resolva todos os conflitos.';
    case 'hopeful':
      return 'Final de superação e recomeço. Tom esperançoso.';
    default:
      return '';
  }
}
```

---

### **5. RITMO NARRATIVO** (Impacto estimado: 7/10)

```
┌─────────────────────────────────────────────────┐
│ Ritmo da História                               │
│ ┌─────────────────────────────────────────────┐ │
│ │ ○ Lento (muitas descrições e reflexões)     │ │
│ │ ● Médio (equilíbrio entre ação e pausa)     │ │
│ │ ○ Rápido (eventos acontecem rapidamente)    │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

**Impacto no prompt:**
```dart
'RITMO: ${_getPaceGuidance(c.narrativePace)}\n'

String _getPaceGuidance(String pace) {
  switch (pace) {
    case 'slow':
      return 'Ritmo LENTO. Desenvolva cenas detalhadamente. Use 3-4 parágrafos por cena.';
    case 'fast':
      return 'Ritmo RÁPIDO. Eventos acontecem rapidamente. 1-2 parágrafos por cena.';
    default:
      return 'Ritmo MÉDIO. Balance cenas longas e curtas.';
  }
}
```

---

## 🎨 MOCKUP DA NOVA INTERFACE (PRIORIDADES)

### **SEÇÃO 1 - CONFIGURAÇÃO DO CONTEÚDO** (Essencial)

```
┌──────────────────────────────────────────────────────┐
│ 🎯 CONFIGURAÇÃO DO CONTEÚDO                          │
├──────────────────────────────────────────────────────┤
│                                                      │
│ Título do Roteiro                                    │
│ ┌──────────────────────────────────────────────────┐ │
│ │ [Digite o título da sua história...]             │ │
│ └──────────────────────────────────────────────────┘ │
│                                                      │
│ ☑ Começar o roteiro com a frase do título           │
│                                                      │
│ ┌───────────────────┬──────────────────────────────┐ │
│ │ Tema              │ Subtema                      │ │
│ │ ▼ Vingança        │ ▼ Vingança Destrutiva        │ │
│ └───────────────────┴──────────────────────────────┘ │
│                                                      │
│ Onde se passa a história:                            │
│ ┌──────────────────────────────────────────────────┐ │
│ │ [Ex: Tóquio, Sertão da Bahia, Interior...]      │ │
│ └──────────────────────────────────────────────────┘ │
│                                                      │
│ ┌───────────────────┬──────────────────────────────┐ │
│ │ Idioma            │ Regionalismo                 │ │
│ │ ▼ Português       │ ▼ Global (Sem Regionalismos) │ │
│ └───────────────────┴──────────────────────────────┘ │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### **SEÇÃO 2 - PERSONAGENS** (Novo - Alto Impacto)

```
┌──────────────────────────────────────────────────────┐
│ 👥 PERSONAGENS                                        │
├──────────────────────────────────────────────────────┤
│                                                      │
│ Protagonista                                         │
│ ┌──────────────────────────────────────────────────┐ │
│ │ Nome: [Maria]                                    │ │
│ │ Profissão (opcional): [Professora]               │ │
│ │ Idade aproximada: ▼ [35-45 anos]                 │ │
│ └──────────────────────────────────────────────────┘ │
│                                                      │
│ Personagem Secundário (opcional)                     │
│ ┌──────────────────────────────────────────────────┐ │
│ │ Nome: [João]                                     │ │
│ │ Relação: [Marido]                                │ │
│ └──────────────────────────────────────────────────┘ │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### **SEÇÃO 3 - ESTILO NARRATIVO** (Novo - Alto Impacto)

```
┌──────────────────────────────────────────────────────┐
│ 🎨 ESTILO NARRATIVO                                   │
├──────────────────────────────────────────────────────┤
│                                                      │
│ Tom da Narrativa                                     │
│ ┌──────────────────────────────────────────────────┐ │
│ │ ▼ Reflexivo e Introspectivo                      │ │
│ └──────────────────────────────────────────────────┘ │
│                                                      │
│ Quantidade de Diálogos                               │
│ ┌──────────────────────────────────────────────────┐ │
│ │ ▼ Moderada (30-40% da história)                  │ │
│ └──────────────────────────────────────────────────┘ │
│                                                      │
│ Tipo de Final                                        │
│ ┌──────────────────────────────────────────────────┐ │
│ │ ▼ Livre (IA decide)                              │ │
│ └──────────────────────────────────────────────────┘ │
│                                                      │
│ Perspectiva Narrativa                                │
│ ┌──────────────────────────────────────────────────┐ │
│ │ ● Primeira Pessoa Homem Idoso                    │ │
│ └──────────────────────────────────────────────────┘ │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### **SEÇÃO 4 - MEDIDA** (Manter)

```
┌──────────────────────────────────────────────────────┐
│ 📊 MEDIDA                                             │
├──────────────────────────────────────────────────────┤
│                                                      │
│ ┌───────────────────┬──────────────────────────────┐ │
│ │ Medida            │ Perspectiva Narrativa        │ │
│ │ ▼ Palavras        │ ▼ Primeira Pessoa Homem...   │ │
│ └───────────────────┴──────────────────────────────┘ │
│                                                      │
│         [────●────────────] 2000 palavras            │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## 📊 COMPARAÇÃO: ANTES vs DEPOIS

| Aspecto | ANTES (Atual) | DEPOIS (Proposta) |
|---------|---------------|-------------------|
| **Campos de configuração** | 10 campos | 12 campos (+2) |
| **Campos de alto impacto (8-10/10)** | 5 campos | 9 campos (+80%) |
| **Campos de baixo impacto (≤5/10)** | 2 campos | 0 campos (-100%) |
| **Campo genérico grande** | "Contexto do Roteiro" (ignorado) | Removido |
| **Controle de estilo** | Nenhum | Tom, Diálogos, Final, Ritmo |
| **Controle de personagens** | 2 nomes apenas | Nome + Profissão + Idade |
| **Experiência do usuário** | Frustrante (escreve muito, recebe genérico) | Preciso (seleciona opções, recebe direcionado) |

---

## 🚀 IMPLEMENTAÇÃO SUGERIDA

### **FASE 1 - Remoção e Simplificação** (1-2 horas)

1. ✂️ Remover "Contexto do Roteiro" da UI e do modelo
2. 📝 Atualizar `script_config.dart` (remover campo `context`)
3. 🧪 Testar geração sem contexto (deve funcionar normalmente)

### **FASE 2 - Adicionar Tom Narrativo** (2-3 horas)

1. ➕ Adicionar campo `narrativeTone` em `script_config.dart`
2. 🎨 Criar dropdown na UI com 5 opções
3. 📝 Implementar `_getToneGuidance()` no gemini_service.dart
4. 🧪 Testar com "Reflexivo" vs "Ação" (comparar resultados)

### **FASE 3 - Adicionar Final Desejado** (2-3 horas)

1. ➕ Adicionar campo `endingType` em `script_config.dart`
2. 🎨 Criar dropdown na UI com 5 opções
3. 📝 Implementar `_getEndingGuidance()` (só no último bloco)
4. 🧪 Testar com "Feliz" vs "Trágico"

### **FASE 4 - Expandir Personagens** (3-4 horas)

1. ➕ Adicionar `protagonistProfession` e `protagonistAge` em `script_config.dart`
2. 🎨 Criar inputs na UI (profissão = texto, idade = dropdown)
3. 📝 Adicionar ao prompt do primeiro bloco
4. 🧪 Testar: "Maria, 35-45, Professora" deve gerar coerente

### **FASE 5 - Adicionar Diálogos e Ritmo** (2-3 horas cada)

1. ➕ Campos `dialogueLevel` e `narrativePace`
2. 🎨 Dropdowns na UI
3. 📝 Implementar guidance functions
4. 🧪 Testar variações

---

## ✅ RECOMENDAÇÃO FINAL

### **PRIORIDADE ALTA** (Implementar já)
1. ✂️ **Remover "Contexto do Roteiro"** - Libera espaço, reduz frustração
2. ➕ **Adicionar "Tom Narrativo"** - Controle direto do estilo (impacto 8/10)
3. ➕ **Adicionar "Tipo de Final"** - Usuário controla resolução (impacto 8/10)

### **PRIORIDADE MÉDIA** (Next version)
4. 👤 **Expandir Personagens** (profissão + idade) - Coerência narrativa
5. 💬 **Adicionar "Quantidade de Diálogos"** - Controle de ritmo

### **PRIORIDADE BAIXA** (Opcional)
6. ⚡ **Adicionar "Ritmo Narrativo"** - Overlap com Tom, menos essencial

---

## 📈 IMPACTO ESPERADO

**Métricas de sucesso:**

| Métrica | Antes | Depois (estimado) |
|---------|-------|-------------------|
| **Satisfação com resultado** | 6/10 | 8.5/10 |
| **Percepção de controle** | 4/10 | 9/10 |
| **Tempo configurando** | 5 min | 3 min (-40%) |
| **Roteiros "genéricos"** | 60% | 20% (-66%) |
| **Usuários que preenchem contexto** | 80% | N/A (removido) |
| **Usuários que usam novos campos** | N/A | 90% (estimado) |

**ROI:** 10-15 horas de desenvolvimento para +40% satisfação do usuário.

---

**Pergunta para você:** Quer que eu implemente a **Fase 1** (remover contexto) agora? Ou prefere que eu mostre um mockup visual da nova interface antes?
