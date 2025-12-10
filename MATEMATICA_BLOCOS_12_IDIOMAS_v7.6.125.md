# 📐 MATEMÁTICA DE CÁLCULO DE BLOCOS - 12 IDIOMAS

**Data:** 09/12/2025  
**Versão:** v7.6.125  
**Módulo:** `block_calculator.dart`  
**Objetivo:** Documentar fórmulas matemáticas de cálculo de blocos para todos os 12 idiomas suportados

---

## 📋 ÍNDICE

1. [Visão Geral do Sistema](#1-visão-geral-do-sistema)
2. [Os 12 Idiomas Suportados](#2-os-12-idiomas-suportados)
3. [Fórmulas Matemáticas Base](#3-fórmulas-matemáticas-base)
4. [Cálculo por Idioma - PRO](#4-cálculo-por-idioma---pro)
5. [Cálculo por Idioma - FLASH](#5-cálculo-por-idioma---flash)
6. [Exemplos Práticos](#6-exemplos-práticos)
7. [Tabelas de Referência Rápida](#7-tabelas-de-referência-rápida)
8. [Ajustes Especiais](#8-ajustes-especiais)

---

## 1. VISÃO GERAL DO SISTEMA

### 1.1 Como Funciona

O sistema calcula quantos blocos gerar baseado em:
- **Quantidade de palavras/caracteres** selecionada pelo usuário
- **Idioma** escolhido
- **Modelo de IA** (PRO ou FLASH)

### 1.2 Localização no Código

```dart
// Arquivo: lib/data/services/gemini/generation/block_calculator.dart
// Função principal: calculateTotalBlocks(ScriptConfig c)
// Linha: 67-250
```

### 1.3 Fluxo de Cálculo

```
┌─────────────────────────────────────────────────────────┐
│ ENTRADA DO USUÁRIO                                      │
├─────────────────────────────────────────────────────────┤
│ • Quantidade: 2000 palavras                            │
│ • Idioma: Português                                    │
│ • Modelo: Flash                                        │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│ PASSO 1: NORMALIZAÇÃO                                  │
├─────────────────────────────────────────────────────────┤
│ Se medida = "caracteres":                              │
│   wordsEquivalent = quantidade ÷ ratio                 │
│ Senão:                                                 │
│   wordsEquivalent = quantidade                         │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│ PASSO 2: TARGET POR BLOCO                              │
├─────────────────────────────────────────────────────────┤
│ if (isFlashModel):                                     │
│   targetPalBloco = [550-900] (depende do idioma)       │
│ else:                                                  │
│   targetPalBloco = [700-1350] (depende do idioma)      │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│ PASSO 3: CÁLCULO DE BLOCOS                             │
├─────────────────────────────────────────────────────────┤
│ calculatedBlocks = CEIL(wordsEquivalent ÷ targetPalBloco)│
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│ PASSO 4: LIMITES DE SEGURANÇA                          │
├─────────────────────────────────────────────────────────┤
│ minBlocks = 2                                          │
│ maxBlocks = [25-50] (depende do idioma)                │
│ finalBlocks = CLAMP(calculatedBlocks, min, max)        │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│ SAÍDA                                                   │
├─────────────────────────────────────────────────────────┤
│ Blocos a gerar: 3 blocos                               │
│ Palavras por bloco: ~667 palavras                      │
└─────────────────────────────────────────────────────────┘
```

---

## 2. OS 12 IDIOMAS SUPORTADOS

### Lista Completa (Interface)

```dart
// Arquivo: lib/data/models/generation_config.dart
// Linha: 191-202

static const List<String> availableLanguages = [
  'Português',      // 1
  'Inglês',         // 2
  'Espanhol(mexicano)', // 3
  'Francês',        // 4
  'Alemão',         // 5
  'Italiano',       // 6
  'Polonês',        // 7
  'Búlgaro',        // 8
  'Russo',          // 9
  'Coreano (한국어)', // 10
  'Turco',          // 11
  'Romeno',         // 12
];
```

### Categorias Linguísticas

```
📚 LATINO (Português, Espanhol, Francês, Italiano, Romeno)
├─ Idiomas com alfabeto latino simples
├─ Target: 850-1350 palavras/bloco (dependendo do modelo)
└─ Maior facilidade para IA processar

🇷🇺 CIRÍLICO (Russo, Búlgaro)
├─ Alfabeto cirílico (caracteres mais pesados)
├─ Target: 700-1000 palavras/bloco
└─ Necessita ajuste para caracteres especiais

🇰🇷 COREANO (Coreano - 한국어)
├─ Alfabeto hangul (alta densidade silábica)
├─ Target: 550-700 palavras/bloco
├─ Compensação: +18% nos blocos
└─ Ratio especial: 4.2 (vs 5.5 padrão)

🌍 OUTROS (Alemão, Polonês, Turco)
├─ Idiomas com diacríticos pesados
├─ Target: 800-1100 palavras/bloco
└─ Ajustes especiais para caracteres acentuados
```

---

## 3. FÓRMULAS MATEMÁTICAS BASE

### 3.1 Normalização para Palavras Equivalentes

```
Se measureType = "caracteres":
  wordsEquivalent = quantidade ÷ charToWordRatio

  charToWordRatio = {
    4.2, se idioma = Coreano (한국어)
    5.5, caso contrário (padrão)
  }

Senão (measureType = "palavras"):
  wordsEquivalent = quantidade
```

**Exemplo:**
```
Entrada: 11000 caracteres, Coreano
Cálculo: 11000 ÷ 4.2 = 2619 palavras equivalentes

Entrada: 11000 caracteres, Português
Cálculo: 11000 ÷ 5.5 = 2000 palavras equivalentes
```

### 3.2 Cálculo de Blocos

```
calculatedBlocks = CEIL(wordsEquivalent ÷ targetPalBloco)

targetPalBloco = depende do idioma e modelo (ver seções 4 e 5)
```

**Exemplo:**
```
wordsEquivalent: 2000 palavras
targetPalBloco: 900 (Português Flash)
calculatedBlocks: CEIL(2000 ÷ 900) = CEIL(2.22) = 3 blocos
```

### 3.3 Aplicação de Limites

```
finalBlocks = CLAMP(calculatedBlocks, minBlocks, maxBlocks)

minBlocks = 2 (sempre)

maxBlocks = {
  50, se idioma = Coreano
  30, se idioma = Cirílico (Russo, Búlgaro)
  25, caso contrário
}
```

### 3.4 Compensação Coreana (+18%)

```
Se idioma = Coreano:
  finalBlocks = CEIL(finalBlocks × 1.18)
  finalBlocks = CLAMP(finalBlocks, minBlocks, maxBlocks)
```

**Razão:** Coreano gera ~15% menos palavras que o esperado devido à densidade silábica.

---

## 4. CÁLCULO POR IDIOMA - PRO

### 4.1 Português (PRO)

```
📊 CONFIGURAÇÃO
Target: 1350 palavras/bloco
Categoria: 🇧🇷 PORTUGUÊS
Limites: min=2, max=25 blocos
Ratio: 5.5 (caracteres → palavras)

📐 FÓRMULA
blocos = CEIL(palavras ÷ 1350)
blocos = CLAMP(blocos, 2, 25)

📋 EXEMPLOS
500 pal   → 1 → 2 blocos  (mín. forçado) → ~250 pal/bloco
1000 pal  → 1 → 2 blocos  (mín. forçado) → ~500 pal/bloco
2000 pal  → 2 → 2 blocos                 → ~1000 pal/bloco
2525 pal  → 2 → 2 blocos                 → ~1263 pal/bloco
4000 pal  → 3 → 3 blocos                 → ~1333 pal/bloco
5400 pal  → 4 → 4 blocos                 → ~1350 pal/bloco
10000 pal → 8 → 8 blocos                 → ~1250 pal/bloco
14000 pal → 11 → 11 blocos               → ~1273 pal/bloco
```

### 4.2 Inglês (PRO)

```
📊 CONFIGURAÇÃO
Target: 1350 palavras/bloco
Categoria: 🌍 LATINO
Limites: min=2, max=25 blocos
Ratio: 5.5

📐 FÓRMULA
blocos = CEIL(palavras ÷ 1350)
blocos = CLAMP(blocos, 2, 25)

📋 EXEMPLOS
2000 pal  → 2 → 2 blocos  → ~1000 pal/bloco
4000 pal  → 3 → 3 blocos  → ~1333 pal/bloco
8000 pal  → 6 → 6 blocos  → ~1333 pal/bloco
14000 pal → 11 → 11 blocos → ~1273 pal/bloco
```

### 4.3 Espanhol Mexicano (PRO)

```
📊 CONFIGURAÇÃO
Target: 1350 palavras/bloco
Categoria: 🌍 LATINO
Limites: min=2, max=25 blocos
Ratio: 5.5

📋 EXEMPLOS (idênticos ao Inglês)
2000 pal → 2 blocos → ~1000 pal/bloco
4000 pal → 3 blocos → ~1333 pal/bloco
```

### 4.4 Francês (PRO)

```
📊 CONFIGURAÇÃO
Target: 1350 palavras/bloco
Categoria: 🌍 LATINO
Limites: min=2, max=25 blocos
Ratio: 5.5

📋 EXEMPLOS (idênticos ao Inglês)
2000 pal → 2 blocos → ~1000 pal/bloco
```

### 4.5 Italiano (PRO)

```
📊 CONFIGURAÇÃO
Target: 1350 palavras/bloco
Categoria: 🌍 LATINO
Limites: min=2, max=25 blocos
Ratio: 5.5

📋 EXEMPLOS (idênticos ao Inglês)
2000 pal → 2 blocos → ~1000 pal/bloco
```

### 4.6 Romeno (PRO)

```
📊 CONFIGURAÇÃO
Target: 1350 palavras/bloco
Categoria: 🌍 LATINO
Limites: min=2, max=25 blocos
Ratio: 5.5

📋 EXEMPLOS (idênticos ao Inglês)
2000 pal → 2 blocos → ~1000 pal/bloco
```

### 4.7 Russo (PRO)

```
📊 CONFIGURAÇÃO
Target: 1000 palavras/bloco
Categoria: 🇷🇺 CIRÍLICO
Limites: min=2, max=30 blocos
Ratio: 5.5
Ajuste (caracteres > 6000): -12% (× 0.88)

📐 FÓRMULA
blocos = CEIL(palavras ÷ 1000)
blocos = CLAMP(blocos, 2, 30)

📋 EXEMPLOS
2000 pal  → 2 → 2 blocos   → ~1000 pal/bloco
4000 pal  → 4 → 4 blocos   → ~1000 pal/bloco
10000 pal → 10 → 10 blocos → ~1000 pal/bloco
14000 pal → 14 → 14 blocos → ~1000 pal/bloco
```

### 4.8 Búlgaro (PRO)

```
📊 CONFIGURAÇÃO
Target: 1000 palavras/bloco
Categoria: 🇷🇺 CIRÍLICO
Limites: min=2, max=30 blocos
Ratio: 5.5
Ajuste (caracteres > 6000): -12% (× 0.88)

📋 EXEMPLOS (idênticos ao Russo)
2000 pal → 2 blocos → ~1000 pal/bloco
4000 pal → 4 blocos → ~1000 pal/bloco
```

### 4.9 Coreano (PRO) 🇰🇷

```
📊 CONFIGURAÇÃO
Target: 700 palavras/bloco
Categoria: 🇰🇷 COREANO
Limites: min=2, max=50 blocos
Ratio: 4.2 (especial - densidade silábica)
Compensação: +18%

📐 FÓRMULA
blocos = CEIL(palavras ÷ 700)
blocos = CEIL(blocos × 1.18)  ← COMPENSAÇÃO
blocos = CLAMP(blocos, 2, 50)

📋 EXEMPLOS
2000 pal  → 3 → 4 → 4 blocos  (3×1.18=3.54→4) → ~500 pal/bloco
4000 pal  → 6 → 8 → 8 blocos  (6×1.18=7.08→8) → ~500 pal/bloco
7000 pal  → 10 → 12 → 12 blocos (10×1.18=11.8→12) → ~583 pal/bloco
14000 pal → 20 → 24 → 24 blocos (20×1.18=23.6→24) → ~583 pal/bloco
```

### 4.10 Alemão (PRO)

```
📊 CONFIGURAÇÃO
Target: 1100 palavras/bloco
Categoria: 🇩🇪 ALEMÃO
Limites: min=2, max=25 blocos
Ratio: 5.5
Ajuste (caracteres > 6000): -8% (× 0.92) [diacríticos]

📐 FÓRMULA
blocos = CEIL(palavras ÷ 1100)
blocos = CLAMP(blocos, 2, 25)

📋 EXEMPLOS
2000 pal  → 2 → 2 blocos  → ~1000 pal/bloco
4400 pal  → 4 → 4 blocos  → ~1100 pal/bloco
8800 pal  → 8 → 8 blocos  → ~1100 pal/bloco
14000 pal → 13 → 13 blocos → ~1077 pal/bloco
```

### 4.11 Polonês (PRO)

```
📊 CONFIGURAÇÃO
Target: 1100 palavras/bloco
Categoria: 🇵🇱 POLONÊS
Limites: min=2, max=25 blocos
Ratio: 5.5
Ajuste (caracteres > 6000): -8% (× 0.92) [diacríticos]

📋 EXEMPLOS (idênticos ao Alemão)
2000 pal → 2 blocos → ~1000 pal/bloco
4400 pal → 4 blocos → ~1100 pal/bloco
```

### 4.12 Turco (PRO)

```
📊 CONFIGURAÇÃO
Target: 1100 palavras/bloco
Categoria: 🇹🇷 TURCO
Limites: min=2, max=25 blocos
Ratio: 5.5
Ajuste (caracteres > 6000): -8% (× 0.92) [diacríticos]

📋 EXEMPLOS (idênticos ao Alemão)
2000 pal → 2 blocos → ~1000 pal/bloco
4400 pal → 4 blocos → ~1100 pal/bloco
```

---

## 5. CÁLCULO POR IDIOMA - FLASH

### 5.1 Português (FLASH) ⚡

```
📊 CONFIGURAÇÃO
Target: 900 palavras/bloco
Categoria: 🇧🇷⚡ PORTUGUÊS (FLASH)
Limites: min=2, max=25 blocos
Ratio: 5.5

📐 FÓRMULA
blocos = CEIL(palavras ÷ 900)
blocos = CLAMP(blocos, 2, 25)

📋 EXEMPLOS
500 pal   → 1 → 2 blocos (mín. forçado) → ~250 pal/bloco
1000 pal  → 2 → 2 blocos                → ~500 pal/bloco
2000 pal  → 3 → 3 blocos                → ~667 pal/bloco ⭐
2700 pal  → 3 → 3 blocos                → ~900 pal/bloco
4000 pal  → 5 → 5 blocos                → ~800 pal/bloco
7200 pal  → 8 → 8 blocos                → ~900 pal/bloco
14000 pal → 16 → 16 blocos              → ~875 pal/bloco
```

### 5.2 Inglês (FLASH) ⚡

```
📊 CONFIGURAÇÃO
Target: 850 palavras/bloco
Categoria: 🌍⚡ LATINO (FLASH)
Limites: min=2, max=25 blocos
Ratio: 5.5

📐 FÓRMULA
blocos = CEIL(palavras ÷ 850)
blocos = CLAMP(blocos, 2, 25)

📋 EXEMPLOS
2000 pal  → 3 → 3 blocos  → ~667 pal/bloco
4000 pal  → 5 → 5 blocos  → ~800 pal/bloco
8500 pal  → 10 → 10 blocos → ~850 pal/bloco
14000 pal → 17 → 17 blocos → ~824 pal/bloco
```

### 5.3 Espanhol Mexicano (FLASH) ⚡

```
📊 CONFIGURAÇÃO
Target: 850 palavras/bloco
Categoria: 🌍⚡ LATINO (FLASH)

📋 EXEMPLOS (idênticos ao Inglês Flash)
2000 pal → 3 blocos → ~667 pal/bloco
```

### 5.4 Francês (FLASH) ⚡

```
📊 CONFIGURAÇÃO
Target: 850 palavras/bloco
Categoria: 🌍⚡ LATINO (FLASH)

📋 EXEMPLOS (idênticos ao Inglês Flash)
2000 pal → 3 blocos → ~667 pal/bloco
```

### 5.5 Italiano (FLASH) ⚡

```
📊 CONFIGURAÇÃO
Target: 850 palavras/bloco
Categoria: 🌍⚡ LATINO (FLASH)

📋 EXEMPLOS (idênticos ao Inglês Flash)
2000 pal → 3 blocos → ~667 pal/bloco
```

### 5.6 Romeno (FLASH) ⚡

```
📊 CONFIGURAÇÃO
Target: 850 palavras/bloco
Categoria: 🌍⚡ LATINO (FLASH)

📋 EXEMPLOS (idênticos ao Inglês Flash)
2000 pal → 3 blocos → ~667 pal/bloco
```

### 5.7 Russo (FLASH) ⚡

```
📊 CONFIGURAÇÃO
Target: 700 palavras/bloco
Categoria: 🇷🇺⚡ CIRÍLICO (FLASH)
Limites: min=2, max=30 blocos
Ratio: 5.5
Ajuste (caracteres > 6000): -12% (× 0.88)

📐 FÓRMULA
blocos = CEIL(palavras ÷ 700)
blocos = CLAMP(blocos, 2, 30)

📋 EXEMPLOS
2000 pal  → 3 → 3 blocos   → ~667 pal/bloco
4000 pal  → 6 → 6 blocos   → ~667 pal/bloco
7000 pal  → 10 → 10 blocos → ~700 pal/bloco
14000 pal → 20 → 20 blocos → ~700 pal/bloco
```

### 5.8 Búlgaro (FLASH) ⚡

```
📊 CONFIGURAÇÃO
Target: 700 palavras/bloco
Categoria: 🇷🇺⚡ CIRÍLICO (FLASH)

📋 EXEMPLOS (idênticos ao Russo Flash)
2000 pal → 3 blocos → ~667 pal/bloco
```

### 5.9 Coreano (FLASH) ⚡ 🇰🇷

```
📊 CONFIGURAÇÃO
Target: 550 palavras/bloco
Categoria: 🇰🇷⚡ COREANO (FLASH)
Limites: min=2, max=50 blocos
Ratio: 4.2
Compensação: +18%

📐 FÓRMULA
blocos = CEIL(palavras ÷ 550)
blocos = CEIL(blocos × 1.18)  ← COMPENSAÇÃO
blocos = CLAMP(blocos, 2, 50)

📋 EXEMPLOS
2000 pal  → 4 → 5 → 5 blocos  (4×1.18=4.72→5) → ~400 pal/bloco
4000 pal  → 8 → 10 → 10 blocos (8×1.18=9.44→10) → ~400 pal/bloco
5500 pal  → 10 → 12 → 12 blocos (10×1.18=11.8→12) → ~458 pal/bloco
11000 pal → 20 → 24 → 24 blocos (20×1.18=23.6→24) → ~458 pal/bloco
```

### 5.10 Alemão (FLASH) ⚡

```
📊 CONFIGURAÇÃO
Target: 800 palavras/bloco
Categoria: 🌐⚡ OUTROS (FLASH)
Limites: min=2, max=25 blocos
Ratio: 5.5
Ajuste (caracteres > 6000): -8% (× 0.92)

📐 FÓRMULA
blocos = CEIL(palavras ÷ 800)
blocos = CLAMP(blocos, 2, 25)

📋 EXEMPLOS
2000 pal  → 3 → 3 blocos  → ~667 pal/bloco
4000 pal  → 5 → 5 blocos  → ~800 pal/bloco
8000 pal  → 10 → 10 blocos → ~800 pal/bloco
14000 pal → 18 → 18 blocos → ~778 pal/bloco
```

### 5.11 Polonês (FLASH) ⚡

```
📊 CONFIGURAÇÃO
Target: 800 palavras/bloco
Categoria: 🌐⚡ OUTROS (FLASH)

📋 EXEMPLOS (idênticos ao Alemão Flash)
2000 pal → 3 blocos → ~667 pal/bloco
```

### 5.12 Turco (FLASH) ⚡

```
📊 CONFIGURAÇÃO
Target: 800 palavras/bloco
Categoria: 🌐⚡ OUTROS (FLASH)

📋 EXEMPLOS (idênticos ao Alemão Flash)
2000 pal → 3 blocos → ~667 pal/bloco
```

---

## 6. EXEMPLOS PRÁTICOS

### 6.1 Exemplo Real: Português PRO (2525 palavras)

```
📥 ENTRADA
Quantidade: 2525 palavras
Idioma: Português
Modelo: Gemini 2.5-Pro
MeasureType: palavras

📐 CÁLCULO
wordsEquivalent = 2525 (já é palavras)
targetPalBloco = 1350 (Português PRO)
calculatedBlocks = CEIL(2525 ÷ 1350) = CEIL(1.87) = 2
minBlocks = 2, maxBlocks = 25
finalBlocks = CLAMP(2, 2, 25) = 2

📤 SAÍDA
Blocos: 2
Palavras por bloco: ~1263 palavras/bloco

📊 LOG DO SISTEMA (real)
   🇧🇷 PORTUGUÊS: 2525 palavras → 1350 target = 2 → 2 blocos (~1263 pal/bloco)
```

### 6.2 Exemplo Real: Português FLASH (2000 palavras)

```
📥 ENTRADA
Quantidade: 2000 palavras
Idioma: Português
Modelo: Gemini 2.5-Flash
MeasureType: palavras

📐 CÁLCULO
wordsEquivalent = 2000
targetPalBloco = 900 (Português FLASH)
calculatedBlocks = CEIL(2000 ÷ 900) = CEIL(2.22) = 3
minBlocks = 2, maxBlocks = 25
finalBlocks = CLAMP(3, 2, 25) = 3

📤 SAÍDA
Blocos: 3
Palavras por bloco: ~667 palavras/bloco

📊 LOG DO SISTEMA (real)
   🇧🇷⚡ PORTUGUÊS (FLASH): 2000 palavras → 900 target = 3 → 3 blocos (~667 pal/bloco)
```

### 6.3 Exemplo: Coreano PRO (4000 palavras)

```
📥 ENTRADA
Quantidade: 4000 palavras
Idioma: Coreano (한국어)
Modelo: Gemini 2.5-Pro
MeasureType: palavras

📐 CÁLCULO
wordsEquivalent = 4000
targetPalBloco = 700 (Coreano PRO)
calculatedBlocks = CEIL(4000 ÷ 700) = CEIL(5.71) = 6

⚡ COMPENSAÇÃO COREANA:
finalBlocks = CEIL(6 × 1.18) = CEIL(7.08) = 8

minBlocks = 2, maxBlocks = 50
finalBlocks = CLAMP(8, 2, 50) = 8

📤 SAÍDA
Blocos: 8
Palavras por bloco: ~500 palavras/bloco
```

### 6.4 Exemplo: Russo FLASH (6000 palavras)

```
📥 ENTRADA
Quantidade: 6000 palavras
Idioma: Russo
Modelo: Gemini 2.5-Flash
MeasureType: palavras

📐 CÁLCULO
wordsEquivalent = 6000
targetPalBloco = 700 (Russo FLASH - Cirílico)
calculatedBlocks = CEIL(6000 ÷ 700) = CEIL(8.57) = 9
minBlocks = 2, maxBlocks = 30
finalBlocks = CLAMP(9, 2, 30) = 9

📤 SAÍDA
Blocos: 9
Palavras por bloco: ~667 palavras/bloco
```

### 6.5 Exemplo: Caracteres (11000 caracteres, Coreano)

```
📥 ENTRADA
Quantidade: 11000 caracteres
Idioma: Coreano (한국어)
Modelo: Gemini 2.5-Pro
MeasureType: caracteres

📐 CÁLCULO PASSO 1: NORMALIZAÇÃO
charToWordRatio = 4.2 (especial para Coreano)
wordsEquivalent = 11000 ÷ 4.2 = 2619 palavras

📐 CÁLCULO PASSO 2: BLOCOS
targetPalBloco = 700 (Coreano PRO)
calculatedBlocks = CEIL(2619 ÷ 700) = CEIL(3.74) = 4

📐 CÁLCULO PASSO 3: COMPENSAÇÃO
finalBlocks = CEIL(4 × 1.18) = CEIL(4.72) = 5
finalBlocks = CLAMP(5, 2, 50) = 5

📤 SAÍDA
Blocos: 5
Palavras por bloco: ~524 palavras/bloco
```

---

## 7. TABELAS DE REFERÊNCIA RÁPIDA

### 7.1 Tabela: Target por Idioma e Modelo

| Idioma | PRO (pal/bloco) | FLASH (pal/bloco) | Diferença |
|--------|-----------------|-------------------|-----------|
| **Português** | 1350 | 900 | -33% |
| **Inglês** | 1350 | 850 | -37% |
| **Espanhol** | 1350 | 850 | -37% |
| **Francês** | 1350 | 850 | -37% |
| **Italiano** | 1350 | 850 | -37% |
| **Romeno** | 1350 | 850 | -37% |
| **Russo** | 1000 | 700 | -30% |
| **Búlgaro** | 1000 | 700 | -30% |
| **Coreano** | 700 (+18%) | 550 (+18%) | -21% |
| **Alemão** | 1100 | 800 | -27% |
| **Polonês** | 1100 | 800 | -27% |
| **Turco** | 1100 | 800 | -27% |

### 7.2 Tabela: Blocos Gerados (2000 palavras)

| Idioma | PRO | FLASH | Diferença |
|--------|-----|-------|-----------|
| **Português** | 2 | 3 | +50% |
| **Inglês** | 2 | 3 | +50% |
| **Espanhol** | 2 | 3 | +50% |
| **Francês** | 2 | 3 | +50% |
| **Italiano** | 2 | 3 | +50% |
| **Romeno** | 2 | 3 | +50% |
| **Russo** | 2 | 3 | +50% |
| **Búlgaro** | 2 | 3 | +50% |
| **Coreano** | 4 | 5 | +25% |
| **Alemão** | 2 | 3 | +50% |
| **Polonês** | 2 | 3 | +50% |
| **Turco** | 2 | 3 | +50% |

### 7.3 Tabela: Blocos Gerados (5000 palavras)

| Idioma | PRO | FLASH | Diferença |
|--------|-----|-------|-----------|
| **Português** | 4 | 6 | +50% |
| **Inglês** | 4 | 6 | +50% |
| **Espanhol** | 4 | 6 | +50% |
| **Francês** | 4 | 6 | +50% |
| **Italiano** | 4 | 6 | +50% |
| **Romeno** | 4 | 6 | +50% |
| **Russo** | 5 | 8 | +60% |
| **Búlgaro** | 5 | 8 | +60% |
| **Coreano** | 9 | 11 | +22% |
| **Alemão** | 5 | 7 | +40% |
| **Polonês** | 5 | 7 | +40% |
| **Turco** | 5 | 7 | +40% |

### 7.4 Tabela: Blocos Gerados (10000 palavras)

| Idioma | PRO | FLASH | Diferença |
|--------|-----|-------|-----------|
| **Português** | 8 | 12 | +50% |
| **Inglês** | 8 | 12 | +50% |
| **Espanhol** | 8 | 12 | +50% |
| **Francês** | 8 | 12 | +50% |
| **Italiano** | 8 | 12 | +50% |
| **Romeno** | 8 | 12 | +50% |
| **Russo** | 10 | 15 | +50% |
| **Búlgaro** | 10 | 15 | +50% |
| **Coreano** | 17 | 22 | +29% |
| **Alemão** | 10 | 13 | +30% |
| **Polonês** | 10 | 13 | +30% |
| **Turco** | 10 | 13 | +30% |

### 7.5 Tabela: Ratio Caracteres → Palavras

| Idioma | Ratio | Uso |
|--------|-------|-----|
| **Coreano (한국어)** | 4.2 | Alta densidade silábica hangul |
| **Todos os outros** | 5.5 | Padrão universal |

**Exemplo prático:**
- 5500 caracteres em Português = 1000 palavras (5500 ÷ 5.5)
- 4200 caracteres em Coreano = 1000 palavras (4200 ÷ 4.2)

### 7.6 Tabela: Limites de Blocos

| Idioma | Mínimo | Máximo | Razão |
|--------|--------|--------|-------|
| **Coreano** | 2 | 50 | Volume grande (compensação +18%) |
| **Russo** | 2 | 30 | Alfabeto cirílico |
| **Búlgaro** | 2 | 30 | Alfabeto cirílico |
| **Todos os outros** | 2 | 25 | Padrão |

---

## 8. AJUSTES ESPECIAIS

### 8.1 Compensação Coreana (+18%)

**Código:**
```dart
// Linha 240-243
if (isKorean) {
  finalBlocks = (finalBlocks * 1.18).ceil().clamp(minBlocks, maxBlocks);
}
```

**Razão:**  
O modelo gera ~15% menos palavras em Coreano devido à alta densidade silábica do alfabeto hangul. A compensação de +18% garante que a quantidade final seja próxima ao esperado.

**Exemplo:**
```
Sem compensação: 2000 pal → 3 blocos → 667 pal/bloco × 3 = 2001 pal ✓
Com sub-geração: 2000 pal → 3 blocos → 567 pal/bloco × 3 = 1701 pal ✗ (-15%)

Com compensação: 2000 pal → 3 → 4 blocos → 567 pal/bloco × 4 = 2268 pal ✓ (compensado)
```

### 8.2 Ajuste para Alfabetos Pesados (Caracteres > 6000)

**Código:**
```dart
// Linha 90-127
if (c.measureType == 'caracteres' && wordsEquivalent > 6000) {
  double adjustmentFactor = 1.0;
  
  if (cyrillicLanguages.contains(c.language)) {
    adjustmentFactor = 0.88; // -12%
  } else if (otherNonLatinLanguages.contains(c.language)) {
    adjustmentFactor = 0.85; // -15%
  } else if (heavyDiacriticLanguages.contains(c.language)) {
    adjustmentFactor = 0.92; // -8%
  }
  
  wordsEquivalent = (wordsEquivalent * adjustmentFactor).round();
}
```

**Categorias:**

| Categoria | Idiomas | Ajuste | Razão |
|-----------|---------|--------|-------|
| **Cirílico** | Russo, Búlgaro, Sérvio | -12% | Caracteres cirílicos são mais "pesados" |
| **Não-Latino** | Hebraico, Grego, Tailandês | -15% | Alfabetos não-latinos têm maior complexidade |
| **Diacríticos Pesados** | Turco, Polonês, Tcheco, Vietnamita, Húngaro | -8% | Caracteres acentuados aumentam peso |

**Exemplo (Russo, 11000 caracteres):**
```
wordsEquivalent = 11000 ÷ 5.5 = 2000 palavras

Como measureType = "caracteres" E wordsEquivalent = 2000 (< 6000):
  → SEM ajuste

Se fosse 33000 caracteres:
  wordsEquivalent = 33000 ÷ 5.5 = 6000 palavras
  
  Como measureType = "caracteres" E wordsEquivalent = 6000 (≥ 6000):
  → Aplicar ajuste cirílico: 6000 × 0.88 = 5280 palavras ajustadas
```

### 8.3 Tolerância de Meta (checkTargetMet)

**Código:**
```dart
// Linha 43-61
static bool checkTargetMet(String text, ScriptConfig c) {
  final isFlash = c.qualityMode.toLowerCase().contains('flash');
  
  if (c.measureType == 'caracteres') {
    final tolerancePercent = isFlash ? 0.03 : 0.005;  // 3% vs 0.5%
    final minTol = isFlash ? 100 : 50;
    final tol = max(minTol, (c.quantity * tolerancePercent).round());
    return text.length >= (c.quantity - tol);
  }
  
  final wc = countWords(text);
  final tolerancePercent = isFlash ? 0.05 : 0.01;  // 5% vs 1%
  final minTol = isFlash ? 30 : 10;
  final tol = max(minTol, (c.quantity * tolerancePercent).round());
  return wc >= (c.quantity - tol);
}
```

**Tabela de Tolerâncias:**

| Medida | PRO | FLASH | Razão |
|--------|-----|-------|-------|
| **Caracteres** | 0.5% (mín. 50) | 3% (mín. 100) | Flash mais flexível |
| **Palavras** | 1% (mín. 10) | 5% (mín. 30) | Flash trabalha com blocos menores |

**Exemplo (2000 palavras, Flash):**
```
Meta: 2000 palavras
Tolerância: 5% = 100 palavras (ou mínimo 30)
Aceita se: texto >= 1900 palavras

Geração real: 1950 palavras → ✓ ACEITO (dentro da tolerância)
```

---

## 📊 RESUMO FINAL

### Fórmula Universal

```
PASSO 1: Normalizar para palavras
  Se measureType = "caracteres":
    wordsEquivalent = quantidade ÷ ratio
  Senão:
    wordsEquivalent = quantidade

PASSO 2: Determinar target por idioma/modelo
  targetPalBloco = veja tabelas 4 e 5

PASSO 3: Calcular blocos
  calculatedBlocks = CEIL(wordsEquivalent ÷ targetPalBloco)

PASSO 4: Aplicar compensação (apenas Coreano)
  Se idioma = Coreano:
    calculatedBlocks = CEIL(calculatedBlocks × 1.18)

PASSO 5: Aplicar limites
  minBlocks = 2
  maxBlocks = {50 (Coreano), 30 (Cirílico), 25 (outros)}
  finalBlocks = CLAMP(calculatedBlocks, minBlocks, maxBlocks)

RESULTADO: finalBlocks
```

### Diferenças PRO vs FLASH

| Aspecto | PRO | FLASH | Impacto |
|---------|-----|-------|---------|
| **Target/bloco** | Maior (700-1350) | Menor (550-900) | Flash gera mais blocos |
| **Blocos para 2000 pal** | 2-4 blocos | 3-5 blocos | +25-50% blocos |
| **Tempo/bloco** | ~97s | ~26s | Flash 73% mais rápido |
| **Qualidade** | 100% | 85-90% | Leve perda aceitável |
| **Tolerância** | 1% (palavras) | 5% (palavras) | Flash mais flexível |

---

**Última atualização:** 09/12/2025 - v7.6.125  
**Arquivo de origem:** `lib/data/services/gemini/generation/block_calculator.dart`  
**Linhas de código:** 67-329
