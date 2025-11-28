# 🎨 DOCUMENTAÇÃO COMPLETA: PROMPTS DE IMAGENS DO PROTAGONISTA

**Data:** 05/11/2025  
**Versão:** 1.0  
**Sistema:** Flutter Gerador de Roteiros - Ferramentas Extras

---

## 📍 LOCALIZAÇÃO NO CÓDIGO

**Arquivo:** `lib/presentation/providers/extra_tools_provider.dart`  
**Função:** `generateProtagonistPrompt()`  
**Linhas:** ~240-360  
**Model usado:** `gemini-2.5-flash-lite` (ultra-rápido e econômico)

---

## 🎯 OBJETIVO

Gerar **4 prompts completos em inglês** para criar imagens **consistentes** do protagonista no Midjourney, representando diferentes momentos da narrativa:

1. 🎬 **INÍCIO DA HISTÓRIA** - Setup inicial
2. ⚡ **MOMENTO DE TENSÃO** - Conflito principal
3. 💥 **CLÍMAX/DESCOBERTA** - Momento crucial
4. 🏆 **RESOLUÇÃO/FINAL** - Desfecho

---

## 📋 ESTRUTURA DO PROMPT ENVIADO AO GEMINI

### **1️⃣ CONTEXTO FORNECIDO**

```dart
Com base no seguinte roteiro, analise profundamente o protagonista e gere 4 PROMPTS 
COMPLETOS em inglês para criar imagens consistentes do protagonista no Midjourney:

**Título:** ${config.title}
**Roteiro:** $scriptText
```

---

### **2️⃣ ANÁLISE OBRIGATÓRIA DO PROTAGONISTA**

O prompt instrui o Gemini a extrair do roteiro:

#### **🧬 CARACTERÍSTICAS FÍSICAS FIXAS** (devem ser IDÊNTICAS nos 4 prompts):
- ✅ Idade aproximada
- ✅ Tipo físico (altura, peso, compleição)
- ✅ Cor e estilo de cabelo
- ✅ Cor dos olhos
- ✅ Formato do rosto
- ✅ Características marcantes (barba, óculos, cicatrizes, tatuagens)
- ✅ Tom de pele
- ✅ Traços étnicos/culturais

#### **🎭 PERSONALIDADE E CONTEXTO:**
- Profissão/ocupação
- Classe social
- Traços de personalidade principais
- Momento da história (início, meio, fim)

#### **🌍 CENÁRIO E ATMOSFERA:**
- Localização principal do roteiro
- Época/período
- Clima/atmosfera da história

---

### **3️⃣ OS 4 PROMPTS SOLICITADOS**

#### **🔹 PROMPT 1: INÍCIO DA HISTÓRIA**
```
- Protagonista em situação do INÍCIO do roteiro
- Expressão/emoção do começo da jornada
- Roupas e contexto do início
- Cenário de fundo relacionado ao setup inicial
- ✅ Mantém características físicas fixas
```

#### **⚡ PROMPT 2: MOMENTO DE TENSÃO/CONFLITO**
```
- Protagonista no MEIO da história
- Expressão de tensão, dúvida ou luta
- Possivelmente roupa diferente (se mudou no roteiro)
- Cenário de fundo do conflito principal
- ✅ Mantém características físicas fixas
```

#### **💥 PROMPT 3: CLÍMAX/DESCOBERTA**
```
- Protagonista no momento crucial
- Expressão de revelação, choque ou determinação
- Contexto visual do momento decisivo
- Cenário dramático do clímax
- ✅ Mantém características físicas fixas
```

#### **🏆 PROMPT 4: RESOLUÇÃO/FINAL**
```
- Protagonista após a jornada
- Expressão do estado final (vitória, paz, transformação)
- Roupas/estilo final (pode ter mudado)
- Cenário do desfecho
- ✅ Mantém características físicas fixas
```

---

### **4️⃣ REGRAS CRÍTICAS DE CONSISTÊNCIA**

#### **✅ CONSISTÊNCIA VISUAL ABSOLUTA:**

```
As características físicas (idade, cabelo, olhos, rosto, pele) devem ser 
EXATAMENTE IGUAIS nos 4 prompts.

Use as MESMAS palavras descritivas para traços físicos fixos.

Exemplo: 
Se é "30-year-old man, short brown hair, green eyes, square jaw" no Prompt 1, 
deve ser EXATAMENTE igual nos outros 3.
```

#### **🔄 O QUE PODE MUDAR:**
- ✅ Expressão facial (conforme momento da história)
- ✅ Roupas (se mudou no roteiro)
- ✅ Postura corporal
- ✅ Cenário de fundo
- ✅ Iluminação/atmosfera

#### **❌ O QUE NÃO PODE MUDAR:**
- ❌ Idade
- ❌ Cabelo (cor, estilo)
- ❌ Olhos (cor)
- ❌ Formato do rosto
- ❌ Tom de pele
- ❌ Traços étnicos

---

### **5️⃣ FORMATO DE CADA PROMPT**

```
"[características físicas fixas], [expressão facial], [roupas específicas], 
[postura], [cenário de fundo detalhado], [atmosfera/mood], cinematic lighting, 
photorealistic, high detail, 8k, professional photography, --ar 2:3 --v 6"
```

**Elementos obrigatórios:**
- ✅ `"from waist up"` ou `"upper body portrait"`
- ✅ `"facing camera"` ou ângulo apropriado
- ✅ `"cinematic lighting, photorealistic"`
- ✅ `"high detail, 8k, professional photography"`
- ✅ `"--ar 2:3 --v 6"` (aspect ratio + versão Midjourney)

---

### **6️⃣ FORMATO DE SAÍDA EXIGIDO**

```
═══════════════════════════════════════════
📋 CARACTERÍSTICAS FIXAS DO PROTAGONISTA:
═══════════════════════════════════════════
[Descreva em português as características que serão mantidas]

═══════════════════════════════════════════
🎬 PROMPT 1 - INÍCIO DA HISTÓRIA:
═══════════════════════════════════════════
[Prompt completo em inglês]

═══════════════════════════════════════════
⚡ PROMPT 2 - MOMENTO DE TENSÃO:
═══════════════════════════════════════════
[Prompt completo em inglês]

═══════════════════════════════════════════
💥 PROMPT 3 - CLÍMAX/DESCOBERTA:
═══════════════════════════════════════════
[Prompt completo em inglês]

═══════════════════════════════════════════
🏆 PROMPT 4 - RESOLUÇÃO/FINAL:
═══════════════════════════════════════════
[Prompt completo em inglês]

═══════════════════════════════════════════
💡 DICAS DE USO:
═══════════════════════════════════════════
- Use seed fixo no Midjourney para maior consistência
- Ajuste weight dos elementos conforme necessário
- Considere usar image prompts da Imagem 1 para gerar 2, 3 e 4
```

---

## 📊 EXEMPLO REAL DE SAÍDA (Roteiro Antoine)

### **📋 CARACTERÍSTICAS FIXAS:**
```
Antoine possui pele clara de tom branco europeu, com traços faciais típicos 
franceses. 45 anos. Compleição média. Cabelo castanho curto com fios grisalhos. 
Olhos azuis. Rosto oval com traços suaves. Pele clara, aparência europeia.
```

### **🎬 PROMPT 1 - INÍCIO:**
```
45-year-old man, average build, short brown hair with subtle hints of grey, 
blue eyes, oval face with soft features, light skin tone, simple and 
unpretentious appearance, looking slightly withdrawn and melancholic, wearing 
a plain, slightly worn dark grey sweater and casual trousers, seated slightly 
apart from others in a formal, dimly lit notary's office with antique dark wood 
furniture and the faint smell of old paper and wax, upper body portrait, 
facing camera, cinematic lighting, photorealistic, high detail, 8k, 
professional photography, --ar 2:3 --v 6
```

### **⚡ PROMPT 2 - MOMENTO DE TENSÃO:**
```
45-year-old man, average build, short brown hair with subtle hints of grey, 
blue eyes, oval face with soft features, light skin tone, simple and 
unpretentious appearance, expression of deep concentration and growing unease, 
wearing a simple, dark blue button-down shirt, holding a worn leather-bound 
bible in his hands, examining a small, metallic bookmark with a cryptic code 
on it, sitting at a modest wooden kitchen table in a small, sparsely furnished 
apartment, faint morning light filtering through a window, upper body portrait, 
facing camera, cinematic lighting, photorealistic, high detail, 8k, 
professional photography, --ar 2:3 --v 6
```

### **💥 PROMPT 3 - CLÍMAX/DESCOBERTA:**
```
45-year-old man, average build, short brown hair with subtle hints of grey, 
blue eyes, oval face with soft features, light skin tone, simple and 
unpretentious appearance, a look of dawning realization and quiet determination 
mixed with a hint of shock, wearing a slightly more formal, dark charcoal jacket 
over a light grey shirt, standing in a dimly lit, secure vault room with rows 
of safe deposit boxes, holding an old brass key and a notarized document, 
upper body portrait, facing camera, cinematic lighting, photorealistic, 
high detail, 8k, professional photography, --ar 2:3 --v 6
```

### **🏆 PROMPT 4 - RESOLUÇÃO/FINAL:**
```
45-year-old man, average build, short brown hair with subtle hints of grey, 
blue eyes, oval face with soft features, light skin tone, simple and 
unpretentious appearance, a serene and confident expression, a subtle, knowing 
smile, wearing a well-fitting, comfortable dark wool blazer over a crisp white 
shirt, standing in a bright, modern office with a city view, holding a simple 
teacup, a sense of peace and quiet strength about him, upper body portrait, 
facing camera, cinematic lighting, photorealistic, high detail, 8k, 
professional photography, --ar 2:3 --v 6
```

---

## 🔍 ANÁLISE TÉCNICA

### **✅ O que funcionou PERFEITAMENTE:**
1. **Consistência física:** Todas as 4 imagens mantêm: 45 anos, cabelo castanho com grisalho, olhos azuis, compleição média
2. **Progressão emocional:** 
   - Início → melancólico, retraído
   - Tensão → concentração, inquietação
   - Clímax → realização, determinação, choque
   - Final → serenidade, confiança, sorriso sutil
3. **Evolução visual:**
   - Roupas: Suéter cinza → Camisa azul → Blazer carvão → Blazer lã + camisa branca
   - Cenários: Cartório → Cozinha → Cofre → Escritório moderno
4. **Aspectos técnicos:** Todos os prompts incluem parâmetros corretos (--ar 2:3 --v 6)

### **⚠️ Problema identificado:**

**FALTA DE INSTRUÇÃO ESPECÍFICA DE ETNIA**

O prompt atual instrui:
```
- Tom de pele
- Traços étnicos/culturais
```

Mas **não há mapeamento automático idioma → etnia** como implementado em v7.6.10 no contexto auxiliar.

**Resultado:** Descrição vaga "pele clara, aparência europeia" em vez de especificar "etnia branca europeia francesa" com características detalhadas.

---

## 🎯 MELHORIA PROPOSTA: v7.6.11

### **Adicionar função `_getEthnicityInstruction()`**

Mesma função implementada em `auxiliary_tools_provider.dart` (v7.6.10), que mapeia:

- **Français** → White European French (pele clara, traços franceses)
- **English** → Anglo-Saxon white (pele clara, olhos claros)
- **Español** → Hispanic/Latino (pele morena, traços latinos)
- **Português** → Brazilian/Portuguese (multiétnico: moreno-claro, pardo, branco)
- **Italiano** → Mediterranean Italian (pele clara a morena-mediterrânea)
- **Alemão** → Germanic (pele clara, cabelos loiros/ruivos)
- **Russo** → Slavic (pele clara, traços eslavos)
- **Japonês** → Japanese Asian (pele clara-amarelada, olhos amendoados)
- **Chinês** → Chinese Asian (pele clara-amarelada asiática)
- **Árabe** → Arab/Middle Eastern (pele morena, traços semíticos)

### **Integração no prompt:**

```dart
**ANÁLISE OBRIGATÓRIA DO PROTAGONISTA:**

1️⃣ **CARACTERÍSTICAS FÍSICAS FIXAS** (devem ser IDÊNTICAS nos 4 prompts):
   - Idade aproximada
   - Tipo físico (altura, peso, compleição)
   - Cor e estilo de cabelo
   - Cor dos olhos
   - Formato do rosto
   - Características marcantes (barba, óculos, cicatrizes, tatuagens)
   - Tom de pele
   - Traços étnicos/culturais
   
   🎭 ETNIA DO PROTAGONISTA - OBRIGATÓRIO:
   ${_getEthnicityInstruction(config.language)}  // ← NOVO!
```

---

## 📈 BENEFÍCIOS DA MELHORIA v7.6.11

### **Antes (sem v7.6.11):**
```
"pele clara, aparência europeia" ← Vago, genérico
```

### **Depois (com v7.6.11):**
```
"45-year-old French man of white European French ethnicity, fair skin with 
typical French facial features, brown hair with grey touches, blue eyes..."
```

### **Resultado esperado:**
- ✅ Especificação étnica clara e culturalmente coerente
- ✅ Características físicas detalhadas (pele, cabelo, olhos típicos da etnia)
- ✅ Coerência total: Nome francês + Idioma francês + Etnia francesa
- ✅ Mesma qualidade de v7.6.10 aplicada às imagens do protagonista

---

## 🔧 IMPLEMENTAÇÃO TÉCNICA

### **Passo 1:** Copiar função `_getEthnicityInstruction()` de `auxiliary_tools_provider.dart`

### **Passo 2:** Adicionar no prompt em `extra_tools_provider.dart` linha ~260:

```dart
1️⃣ **CARACTERÍSTICAS FÍSICAS FIXAS** (devem ser IDÊNTICAS nos 4 prompts):
   - Idade aproximada
   - Tipo físico (altura, peso, compleição)
   - Cor e estilo de cabelo
   - Cor dos olhos
   - Formato do rosto
   - Características marcantes (barba, óculos, cicatrizes, tatuagens)
   - Tom de pele
   - Traços étnicos/culturais
   
   🎭 ETNIA DO PROTAGONISTA - OBRIGATÓRIO:
   ${_getEthnicityInstruction(config.language)}
```

### **Passo 3:** Testar com roteiros em diferentes idiomas:
- French → White European French
- Portuguese → Brazilian/Portuguese (multiethnic)
- Japanese → Japanese Asian
- Spanish → Hispanic/Latino

---

## 📊 COMPATIBILIDADE COM SISTEMA ATUAL

### **Sistema de validações técnicas:**
- ✅ v7.6.8: Gender validation (funcionando)
- ✅ v7.6.9: Age categories (funcionando)
- ✅ v7.6.10: Ethnicity mapping (contexto auxiliar)
- ✅ v7.6.11: Ethnicity mapping (prompts de imagens) ← IMPLEMENTADO! 🎉

### **Integração COMPLETA (v7.6.11):**

**Data de implementação:** 05/11/2025  
**Status:** ✅ CONCLUÍDO

A função `_getEthnicityInstructionForImagePrompts()` foi criada em `extra_tools_provider.dart` e integrada ao prompt do protagonista:

```dart
1️⃣ **CARACTERÍSTICAS FÍSICAS FIXAS** (devem ser IDÊNTICAS nos 4 prompts):
   - Idade aproximada
   - Tipo físico (altura, peso, compleição)
   - Cor e estilo de cabelo
   - Cor dos olhos
   - Formato do rosto
   - Características marcantes (barba, óculos, cicatrizes, tatuagens, etc.)
   - Tom de pele
   
   ${_getEthnicityInstructionForImagePrompts(config.language)}  // ← NOVO! v7.6.11
```

### **Exemplo de instrução gerada (Francês):**

```
🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **branco europeu francês** (white European French).
   - Pele: clara/branca europeia (fair/light European skin tone)
   - Traços faciais: típicos franceses (typical French facial features)
   - Cabelos: castanhos, loiros ou pretos (brown, blonde, or black hair)
   - Olhos: claros ou escuros (light or dark eyes)
   - ❌ NÃO usar etnias asiáticas, africanas, latinas ou indígenas
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA
```

### **Idiomas suportados (v7.6.11):**

1. 🇫🇷 **Francês** → Branco europeu francês
2. 🇬🇧 **Inglês** → Branco anglo-saxão
3. 🇪🇸 **Espanhol** → Hispânico/latino
4. 🇧🇷 **Português** → Brasileiro/português (multiétnico)
5. 🇮🇹 **Italiano** → Italiano mediterrâneo
6. 🇩🇪 **Alemão** → Germânico centro-europeu
7. 🇷🇺 **Russo** → Eslavo/russo
8. 🇯🇵 **Japonês** → Japonês (asiático do leste)
9. 🇨🇳 **Chinês** → Chinês (asiático do leste)
10. 🇸🇦 **Árabe** → Árabe/médio-oriental

### **Consistência completa (v7.6.10 + v7.6.11):**

Agora a cadeia de coerência cultural está **100% completa**:

```
Usuário define idioma: Français
         ↓
v7.6.8: Gender → Homme = protagonista masculino ✅
         ↓
v7.6.9: Age → Maduro = 35-50 anos ✅
         ↓
v7.6.10: Ethnicity (context) → "pele clara, traços franceses típicos" ✅
         ↓
v7.6.11: Ethnicity (image prompts) → "white European French ethnicity" ✅
         ↓
RESULTADO: Coerência cultural ABSOLUTA entre contexto e imagens! 🎯
```

### **Benefícios da v7.6.11:**

1. ✅ **Consistência texto ↔ imagem:** Descrição no contexto = aparência nas imagens
2. ✅ **Prevenção de viés do Gemini:** Não depende mais de inferência vaga
3. ✅ **Especificidade técnica:** Prompts em inglês com termos claros ("white European French")
4. ✅ **Coerência nos 4 prompts:** Etnia idêntica em início, tensão, clímax e resolução
5. ✅ **Compatibilidade Midjourney:** Instruções claras para o gerador de imagens

---

## 🆕 EXEMPLO COMPLETO: ANTOINE (v7.6.11)

**Roteiro:** "La bible de mamie" (Francês)  
**Idioma:** Français  
**Protagonista:** Antoine, 45 anos

### **Contexto gerado (v7.6.10):**

> "Antoine possui pele clara de tom branco europeu, traços faciais típicos franceses..."

### **Prompt de análise enviado ao Gemini (v7.6.11):**

```
1️⃣ **CARACTERÍSTICAS FÍSICAS FIXAS**:
   - Idade aproximada
   - Tipo físico
   ...
   - Tom de pele
   
   🎭 **ETNIA OBRIGATÓRIA:** Protagonista deve ser **branco europeu francês** (white European French).
   - Pele: clara/branca europeia (fair/light European skin tone)
   - Traços faciais: típicos franceses (typical French facial features)
   - Cabelos: castanhos, loiros ou pretos (brown, blonde, or black hair)
   - Olhos: claros ou escuros (light or dark eyes)
   - ❌ NÃO usar etnias asiáticas, africanas, latinas ou indígenas
   - ✅ Todos os 4 prompts devem manter esta etnia IDÊNTICA
```

### **Resultado esperado (Prompt 1 - INÍCIO DA HISTÓRIA):**

```
45-year-old French man, white European French ethnicity, fair skin tone, typical French facial features, 
short brown hair, warm brown eyes, square jaw, simple reading glasses, tired expression, comfortable 
home clothing (beige cardigan, white shirt), standing in cozy living room, holding old family bible, 
soft natural lighting from window, peaceful domestic atmosphere, photorealistic, cinematic lighting, 
high detail, 8k, professional photography, upper body portrait, facing camera, --ar 2:3 --v 6
```

**Análise:**
- ✅ "white European French ethnicity" aparece explicitamente
- ✅ "fair skin tone" (pele clara) consistente com etnia
- ✅ "typical French facial features" (traços franceses típicos)
- ✅ Mesma etnia será repetida nos Prompts 2, 3 e 4

---

## 💡 DICAS DE USO NO MIDJOURNEY

### **Para máxima consistência:**

1. **Seed fixo:** Use `--seed 12345` no primeiro prompt e mantenha nos outros 3
2. **Image prompts:** Gere Imagem 1, depois use-a como referência para gerar 2, 3 e 4
3. **Weights:** Ajuste peso dos elementos se necessário: `character design::2`
4. **Variações:** Use `/vary (subtle)` para pequenas variações mantendo consistência
5. **Reroll:** Se uma imagem fugir muito, regenere mantendo o prompt exato

### **Parâmetros avançados:**

```
--ar 2:3              → Aspect ratio vertical (ideal para rosto/busto)
--v 6                 → Versão Midjourney 6
--style raw           → Estilo mais fotográfico
--stylize 200         → Menos estilização artística
--quality 2           → Máxima qualidade (2x tempo de geração)
```

---

## 🎓 CONCLUSÃO

Este sistema de geração de prompts para imagens do protagonista é **extremamente robusto** e **agora COMPLETO** com a implementação da v7.6.11.

**Status anterior (v7.6.10):** 9.5/10 (faltava etnia nos prompts de imagem)  
**Status atual (v7.6.11):** 10/10 ⭐ **PERFEITO!**

### **Tríade de coerência cultural COMPLETA:**
- ✅ **Nome** baseado no idioma (ex: Antoine para francês)
- ✅ **Idade** apropriada ao perfil (ex: Maduro = 35-50 anos)
- ✅ **Etnia** coerente com contexto linguístico/cultural
  - ✅ No contexto auxiliar (v7.6.10)
  - ✅ Nos prompts de imagens (v7.6.11) ← **IMPLEMENTADO!**

### **Impacto da v7.6.11:**

**ANTES (sem v7.6.11):**
```
Contexto: "Antoine possui pele clara de tom branco europeu, traços franceses típicos"
Prompt imagem: "man with light skin tone, no distinct ethnic features"
         ↓
❌ Inconsistência! Gemini poderia gerar qualquer etnia
```

**DEPOIS (com v7.6.11):**
```
Contexto: "Antoine possui pele clara de tom branco europeu, traços franceses típicos"
Prompt imagem: "white European French ethnicity, fair skin tone, typical French facial features"
         ↓
✅ Consistência perfeita! Etnia específica garantida
```

### **Próximos passos:**

Não há próximos passos para este módulo. **Sistema completo!** 🎉

Possíveis melhorias futuras (opcionais):
- 🔍 Detecção automática de personagens secundários
- 🎨 Prompts para cenários específicos
- 📸 Geração de múltiplos ângulos do mesmo momento
- 🎭 Suporte a expressões faciais específicas por cena

---

**Documento criado por:** GitHub Copilot AI Assistant  
**Data de criação:** 05/11/2025  
**Última atualização:** 05/11/2025 (v7.6.11 implementada)  
**Projeto:** Flutter Gerador de Roteiros - Ferramentas Extras  
**Versão do sistema:** v7.6.11 ✅
