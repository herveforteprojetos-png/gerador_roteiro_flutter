# 📚 DOCUMENTAÇÃO TÉCNICA - Flutter Gerador v7.6.172

**Data:** Dezembro 14, 2025  
**Versão Atual:** v7.6.172 (PRODUÇÃO)  
**Desenvolvedor:** Guilherme  

---

## 📋 ÍNDICE

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Módulos Principais](#módulos-principais)
4. [Serviços Core](#serviços-core)
5. [Otimizações Implementadas](#otimizações-implementadas)
6. [Idiomas Suportados](#idiomas-suportados)
7. [Fluxo de Geração](#fluxo-de-geração)
8. [Configurações e Constantes](#configurações-e-constantes)

---

## 🎯 VISÃO GERAL

**Flutter Gerador** é um sistema completo de geração automatizada de roteiros narrativos para YouTube usando Gemini AI (Google).

### Funcionalidades Principais
- ✅ Geração de roteiros em 12+ idiomas
- ✅ 3 modelos de qualidade: Flash, Pro, Ultra
- ✅ Estrutura em 12 blocos narrativos (3 atos)
- ✅ Trim inteligente com prioridade de parágrafos
- ✅ Filtro de pronomes (evita detecção falsa de personagens)
- ✅ Sistema híbrido Flash+Pro (otimização de custo/velocidade)
- ✅ Tracking de personagens e WorldState
- ✅ Geração de legendas SRT automáticas
- ✅ Suporte 2.000-30.000 palavras por roteiro

### Tecnologias
- **Framework:** Flutter 3.x
- **Linguagem:** Dart
- **AI:** Gemini 2.5-Flash, Gemini 2.0-Pro, Gemini 3.0-Ultra
- **HTTP:** Dio 5.x
- **State Management:** Provider/Riverpod

---

## 🏗️ ARQUITETURA DO SISTEMA

```
lib/
├── data/
│   ├── services/
│   │   ├── gemini_service.dart          # Orquestrador principal
│   │   ├── srt_service.dart             # Geração de legendas
│   │   ├── api_validation_service.dart  # Validação de API keys
│   │   ├── scripting/                   # Scripts e validação
│   │   ├── prompts/                     # Templates de prompts
│   │   └── gemini/                      # Módulos Gemini
│   │       ├── generation/              # Lógica de geração
│   │       ├── tracking/                # Tracking de personagens
│   │       ├── validation/              # Validação de respostas
│   │       ├── utils/                   # Utilitários
│   │       └── infra/                   # Rate limiting, etc
│   ├── models/                          # Modelos de dados
│   └── repositories/                    # Acesso a dados
├── presentation/                        # UI e providers
└── core/                                # Constantes e utils
```

---

## 🔧 MÓDULOS PRINCIPAIS

### 1. **gemini_service.dart** 
**Localização:** `lib/data/services/gemini_service.dart`

**Responsabilidade:** Orquestrador principal de geração de roteiros

**Funções Principais:**

#### `generateScript(ScriptConfig config, Function onProgress)`
```dart
Future<ScriptResult> generateScript(
  ScriptConfig config,
  void Function(GenerationProgress) onProgress,
)
```
- **Descrição:** Gera roteiro completo em 12 blocos
- **Parâmetros:**
  - `config`: Configuração (idioma, quantidade, tema, qualidade)
  - `onProgress`: Callback para atualização de progresso
- **Retorno:** `ScriptResult` com roteiro completo ou erro
- **Versão:** v7.6.169+ (híbrido Flash+Pro)

#### `_generateBlockContent()`
```dart
Future<String> _generateBlockContent({
  required int blockNumber,
  required int totalBlocks,
  required ScriptConfig config,
  // ... outros parâmetros
})
```
- **Descrição:** Gera conteúdo de um bloco individual
- **Features:**
  - v7.6.169: Seleção híbrida Flash/Pro por bloco
  - v7.6.170: Trim garantido (1.5× limite)
  - v7.6.171: Trim inteligente (paragraph > line > sentence)

#### `_trimBlockContent()`
```dart
String _trimBlockContent(String content, int hardLimit)
```
- **Descrição:** Corta conteúdo no limite com prioridade inteligente
- **Algoritmo v7.6.171:**
  1. Busca `\n\n` (parágrafo) nos últimos 20%
  2. Busca `\n` (linha) nos últimos 15%
  3. Busca `. ! ?` (pontuação) nos últimos 10%
  4. Hard cut como fallback
- **Logs:** `✂️ v7.6.171 TRIM INTELIGENTE: tipo = {paragraph|line|sentence|hard}`

---

### 2. **llm_client.dart**
**Localização:** `lib/data/services/scripting/llm_client.dart`

**Responsabilidade:** Cliente HTTP para APIs Gemini

**Funções Principais:**

#### `getModelForBlock()` (v7.6.169)
```dart
static String getModelForBlock({
  required String qualityMode,
  required int blockNumber,
  required int totalBlocks,
})
```
- **Descrição:** Seleciona modelo apropriado por bloco (Flash/Pro híbrido)
- **Lógica:**
  - `pro` ou `ultra`: Sempre usa modelo configurado
  - `flash`: 
    - Blocos 1-60%: Gemini Flash 2.5
    - Blocos 60%+: Gemini Pro (contexto >116k chars)
- **Threshold:** `(totalBlocks * 0.6).ceil()`
- **Exemplo:** 12 blocos → bloco 8+ usa Pro

#### `getModelForQuality()`
```dart
static String getModelForQuality(String qualityMode)
```
- **Retorna:**
  - `flash` → `gemini-2.5-flash`
  - `pro` → `gemini-2.0-pro`
  - `ultra` → `gemini-3.0-ultra`

#### `makeRequest()`
```dart
static Future<http.Response> makeRequest({
  required String model,
  required Map<String, dynamic> payload,
  required String apiKey,
})
```
- **Endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
- **Headers:** `Content-Type: application/json`
- **Timeout:** 180 segundos

---

### 3. **block_calculator.dart**
**Localização:** `lib/data/services/gemini/generation/block_calculator.dart`

**Responsabilidade:** Cálculo de blocos baseado em idioma e quantidade

**Funções Principais:**

#### `calculateTotalBlocks(ScriptConfig config)`
```dart
static int calculateTotalBlocks(ScriptConfig config)
```
- **Descrição:** Calcula número de blocos necessários
- **Fórmula:**
  1. Normalizar para palavras equivalentes (ratio por idioma)
  2. Calcular blocos: `CEIL(palavras ÷ targetPalBloco)`
  3. Aplicar compensação coreana (+18% se coreano)
  4. Aplicar limites: `CLAMP(blocos, 2, maxBlocks)`

**Ratios por Idioma:**
- Coreano (한국어): 4.2 chars/palavra
- Alemão: 6.5 chars/palavra
- Inglês (blocos 7+): 4.0 chars/palavra
- Padrão: 5.5 chars/palavra

**Limites de Blocos:**
- Coreano: max 35 blocos
- Cirílico (Russo, etc): max 30 blocos
- Outros: max 25 blocos

#### `calculateTargetForBlock()`
```dart
static int calculateTargetForBlock(
  int current,
  int total,
  ScriptConfig config,
)
```
- **Descrição:** Calcula meta de palavras para bloco específico
- **Ajustes:**
  - Cirílico >6k chars: -12%
  - Não-latino >6k chars: -15%
  - Diacríticos pesados >6k chars: -8%

#### `getTargetWordsPerBlock()`
```dart
static double getTargetWordsPerBlock(
  ScriptConfig config,
  LanguageCategory category,
)
```
- **Targets Base (Pro):**
  - Latino: 1350 palavras/bloco
  - Cirílico: 1000 palavras/bloco
  - Hangul (Coreano): 700 palavras/bloco
  - Diacríticos: 1200 palavras/bloco

**Multiplicadores por Modelo:**
- Ultra: 1.20× (blocos 20% maiores)
- Pro: 1.00× (referência)
- Flash: 0.67× (blocos 33% menores)

---

### 4. **character_tracker.dart** (v7.6.172)
**Localização:** `lib/data/services/gemini/tracking/character_tracker.dart`

**Responsabilidade:** Rastreamento e validação de personagens

**Funções Principais:**

#### `addName()` (v7.6.172)
```dart
bool addName(String name, {String? role, int? blockNumber})
```
- **Descrição:** Adiciona/valida nome de personagem
- **Validações:**
  1. **v7.6.172:** Filtro de pronomes (31 pronomes, 4 idiomas)
  2. **v7.6.136:** Detecção de frases (ex: "Mas João")
  3. **v7.6.136:** Whitelist de compostos (ex: "Dr. Silva")
  4. Detecção de conflitos de papel
- **Retorno:** `true` = sucesso/ignorado, `false` = conflito

**Blacklist de Pronomes (v7.6.172):**
```dart
static const _pronounBlacklist = {
  // Inglês
  'he', 'she', 'her', 'his', 'him', 'they', 'them', 'their',
  'it', 'its', 'i', 'you', 'we', 'us', 'our', 'my', 'your',
  // Português
  'ele', 'ela', 'seu', 'sua', 'dele', 'dela', 'eles', 'elas',
  'seus', 'suas', 'deles', 'delas', 'meu', 'minha', 'você',
  // Espanhol
  'él', 'ella', 'su', 'sus', 'lo', 'la', 'ellos', 'ellas',
  // Francês
  'il', 'elle', 'son', 'sa', 'ses', 'leur', 'leurs', 'ils', 'elles',
};
```

#### `getDetectedCharacters()`
```dart
List<String> getDetectedCharacters()
```
- **Retorna:** Lista de todos os personagens detectados

#### `hasNameConflict()`
```dart
bool hasNameConflict(String name1, String name2)
```
- **Descrição:** Detecta conflitos entre nomes similares
- **Usa:** Levenshtein distance e similaridade fonética

---

### 5. **block_prompt_builder.dart**
**Localização:** `lib/data/services/prompts/block_prompt_builder.dart`

**Responsabilidade:** Construção de prompts por bloco

**Funções Principais:**

#### `build()`
```dart
static String build({
  required int blockNumber,
  required int totalBlocks,
  required ScriptConfig config,
  // ... outros parâmetros
})
```
- **Descrição:** Monta prompt completo para geração de bloco
- **Componentes:**
  1. Instruções base (idioma, limites)
  2. Estrutura de 3 atos
  3. Regras de personagens
  4. Contexto de blocos anteriores
  5. WorldState atual
  6. Validações específicas

#### `getCharsPerWordForLanguage()` (v7.6.164)
```dart
static double getCharsPerWordForLanguage(
  String language,
  {int blockNumber = 1}
)
```
- **Descrição:** Retorna ratio chars/palavra por idioma
- **Casos Especiais:**
  - Coreano: 2.5
  - Alemão: 6.5
  - Inglês bloco 7+: 4.0 (vs 4.5 blocos 1-6)

#### `calculateCharLimit()`
```dart
static int calculateCharLimit({
  required int targetWords,
  required String language,
  required int blockNumber,
})
```
- **Descrição:** Calcula limite de caracteres
- **Fórmula:** `targetWords × ratio × 1.08 (margem de validação)`

---

### 6. **script_validator.dart**
**Localização:** `lib/data/services/scripting/script_validator.dart`

**Responsabilidade:** Validação de respostas da IA

**Funções Principais:**

#### `translateKeywords()`
```dart
static Future<List<String>> translateKeywords({
  required List<String> keywords,
  required String targetLanguage,
  required String apiKey,
})
```
- **Descrição:** Traduz keywords entre idiomas
- **Exemplo:** `["vingança", "amor"]` → `["revenge", "love"]` (PT→EN)
- **Modelo:** Gemini Flash 2.5

#### `validateBlock()`
```dart
static Future<ValidationResult> validateBlock({
  required String content,
  required int targetWords,
  required String language,
  required List<String> keywords,
})
```
- **Validações:**
  1. Contagem de palavras
  2. Presença de keywords traduzidas
  3. Qualidade narrativa
  4. Estrutura de parágrafos

---

### 7. **post_generation_fixer.dart**
**Localização:** `lib/data/services/gemini/validation/post_generation_fixer.dart`

**Responsabilidade:** Correções pós-geração

**Funções Principais:**

#### `fixCharacterIntroductions()`
```dart
static String fixCharacterIntroductions(String text)
```
- **Descrição:** Corrige apresentações repetidas de personagens
- **Lógica:** Mantém apenas primeira menção detalhada, simplifica demais

#### `resetIntroducedCharacters()`
```dart
static void resetIntroducedCharacters()
```
- **Descrição:** Reseta tracking entre histórias

---

### 8. **world_state_manager.dart**
**Localização:** `lib/data/services/scripting/world_state_manager.dart`

**Responsabilidade:** Tracking de estado do mundo narrativo

**Funções Principais:**

#### `updateWorldState()`
```dart
static Future<String> updateWorldState({
  required String previousContext,
  required String newBlock,
  required String language,
  required String model,
})
```
- **Descrição:** Atualiza fatos, personagens e itens da narrativa
- **Retorno:** JSON estruturado com:
  - `characters`: Lista de personagens com papéis
  - `facts`: Fatos importantes por bloco
  - `items`: Objetos relevantes por personagem

---

### 9. **srt_service.dart**
**Localização:** `lib/data/services/srt_service.dart`

**Responsabilidade:** Geração de legendas SRT

**Funções Principais:**

#### `generateSrtFromScript()`
```dart
Future<String> generateSrtFromScript({
  required String script,
  required String language,
})
```
- **Descrição:** Converte roteiro em arquivo SRT
- **Parâmetros:**
  - Tempo por palavra: ~0.4-0.6s
  - Máximo caracteres por legenda: 42
  - Quebra em pontuação natural

**Formato SRT:**
```
1
00:00:00,000 --> 00:00:03,500
He shared his lunch with a hungry stranger.

2
00:00:03,500 --> 00:00:06,800
Moments later, he was offered a job.
```

---

### 10. **rate_limiter.dart**
**Localização:** `lib/data/services/gemini/infra/rate_limiter.dart`

**Responsabilidade:** Controle de taxa de requisições

**Funções Principais:**

#### `checkRateLimit()`
```dart
static Future<void> checkRateLimit()
```
- **Descrição:** Verifica e aguarda se necessário
- **Limites:**
  - Flash: 15 RPM (4s entre requests)
  - Pro/Ultra: 2 RPM (30s entre requests)

---

## 🚀 OTIMIZAÇÕES IMPLEMENTADAS

### v7.6.169 - Modelo Híbrido Flash+Pro
**Arquivo:** `llm_client.dart`

**Problema Resolvido:** Flash ignora limites com contexto >116k chars

**Solução:**
```dart
if (mode == 'flash') {
  final switchThreshold = (totalBlocks * 0.6).ceil();
  if (blockNumber >= switchThreshold) {
    return modelPro; // Usa Pro para blocos finais
  }
  return modelFlash; // Flash para blocos iniciais
}
```

**Benefícios:**
- ✅ Velocidade do Flash em blocos iniciais (contexto pequeno)
- ✅ Confiabilidade do Pro em blocos finais (contexto grande)
- ✅ Custo otimizado

---

### v7.6.170 - Trim Garantido
**Arquivo:** `gemini_service.dart`

**Problema Resolvido:** Retries infinitos por tamanho

**Solução:**
```dart
if (rawData.length > hardLimit) {
  // Aceita resposta mesmo acima do limite
  // Corta no limite 1.5×
  final trimmed = rawData.substring(0, (hardLimit * 1.5).round());
  // Corta em sentence boundary
}
```

**Benefícios:**
- ✅ Zero retries por tamanho
- ✅ Tempo de geração previsível
- ✅ Sempre gera resultado

---

### v7.6.171 - Trim Inteligente
**Arquivo:** `gemini_service.dart`

**Problema Resolvido:** Cortes abruptos no meio de frases

**Solução:**
```dart
String _trimBlockContent(String content, int hardLimit) {
  final trimmed = content.substring(0, (hardLimit * 1.5).round());
  
  // Prioridade 1: Parágrafo (\n\n) nos últimos 20%
  final threshold80 = (hardLimit * 0.8).round();
  final lastDoubleLine = trimmed.lastIndexOf('\n\n');
  if (lastDoubleLine >= threshold80) {
    return trimmed.substring(0, lastDoubleLine);
  }
  
  // Prioridade 2: Linha (\n) nos últimos 15%
  final threshold85 = (hardLimit * 0.85).round();
  final lastSingleLine = trimmed.lastIndexOf('\n');
  if (lastSingleLine >= threshold85) {
    return trimmed.substring(0, lastSingleLine);
  }
  
  // Prioridade 3: Pontuação nos últimos 10%
  final threshold90 = (hardLimit * 0.9).round();
  final punctuation = ['.', '!', '?'];
  // ... busca última pontuação
  
  // Fallback: Hard cut
  return trimmed.substring(0, hardLimit);
}
```

**Benefícios:**
- ✅ 100% cortes em paragraph boundaries (testado)
- ✅ Narrativa fluida sem interrupções
- ✅ Qualidade profissional

---

### v7.6.172 - Filtro de Pronomes
**Arquivo:** `character_tracker.dart`

**Problema Resolvido:** "Her", "He", "She" detectados como personagens

**Solução:**
```dart
bool addName(String name, {String? role, int? blockNumber}) {
  if (_pronounBlacklist.contains(name.toLowerCase())) {
    debugPrint('⏭️ v7.6.172: "$name" ignorado (pronome comum)');
    return true; // Ignorar, não é erro
  }
  // ... resto da validação
}
```

**Benefícios:**
- ✅ Zero retries por pronomes (v7.6.171: 4 retries → v7.6.172: 0 retries)
- ✅ Tempo reduzido de 13min → 7min41s
- ✅ 31 pronomes em 4 idiomas cobertos

---

## 🌍 IDIOMAS SUPORTADOS

### Tabela de Configurações

| Idioma | Código | Ratio | Target (Pro) | Ajustes | Max Blocos |
|--------|--------|-------|--------------|---------|------------|
| **Português** | pt-BR | 5.5 | 1350 pal | +5% multiplicador | 25 |
| **Inglês** | en | 4.0-5.5 | 1350 pal | 4.0 bloco 7+ | 25 |
| **Espanhol** | es | 5.5 | 1350 pal | - | 25 |
| **Francês** | fr | 5.5 | 1350 pal | - | 25 |
| **Italiano** | it | 5.5 | 1350 pal | - | 25 |
| **Alemão** | de | 6.5 | 1350 pal | Palavras compostas | 25 |
| **Russo** | ru | 5.5 | 1000 pal | -12% >6k chars | 30 |
| **Búlgaro** | bg | 5.5 | 1000 pal | -12% >6k chars | 30 |
| **Sérvio** | sr | 5.5 | 1000 pal | -12% >6k chars | 30 |
| **Coreano** | ko | 4.2 | 700 pal | **+18% blocos** | **35** |
| **Turco** | tr | 5.5 | 1200 pal | -8% >6k chars | 25 |
| **Polonês** | pl | 5.5 | 1200 pal | -8% >6k chars | 25 |
| **Chinês** | zh | Ajustado | Ajustado | - | 25 |
| **Japonês** | ja | Ajustado | Ajustado | - | 25 |
| **Árabe** | ar | Ajustado | Ajustado | - | 25 |

### Categorias de Idiomas

**1. Latino** (ratio 5.5)
- Português, Inglês, Espanhol, Francês, Italiano

**2. Cirílico** (ratio 5.5, target 1000)
- Russo, Búlgaro, Sérvio

**3. Hangul** (ratio 4.2, target 700, +18%)
- Coreano (한국어)

**4. Diacríticos Pesados** (ratio 5.5, target 1200)
- Turco, Polonês, Tcheco, Vietnamita, Húngaro

**5. Outros Não-Latinos**
- Hebraico, Grego, Tailandês

---

## 🔄 FLUXO DE GERAÇÃO

### Diagrama Simplificado

```
1. USUÁRIO CONFIGURA
   ├─ Idioma: Coreano
   ├─ Quantidade: 10625 palavras
   ├─ Tema: Vingança
   ├─ Qualidade: Flash
   └─ Título: "..."

2. GEMINI_SERVICE.generateScript()
   ├─ Calcula blocos: 12 blocos
   ├─ Gera sinopse comprimida
   └─ Loop 12 blocos:

3. POR BLOCO (1-12)
   ├─ BlockCalculator.calculateTargetForBlock()
   │   └─ Target: ~885 palavras/bloco
   ├─ LlmClient.getModelForBlock()
   │   ├─ Blocos 1-7: Flash ⚡
   │   └─ Blocos 8-12: Pro 🎯
   ├─ BlockPromptBuilder.build()
   │   ├─ Monta prompt com contexto
   │   ├─ Aplica limites por idioma
   │   └─ Adiciona WorldState
   ├─ LlmClient.makeRequest()
   │   └─ Chama Gemini API
   ├─ _trimBlockContent() (v7.6.171)
   │   └─ Corte inteligente (paragraph)
   ├─ CharacterTracker.validateNames() (v7.6.172)
   │   └─ Filtra pronomes
   ├─ WorldStateManager.updateWorldState()
   │   └─ Atualiza fatos/personagens
   └─ onProgress() → UI atualiza

4. PÓS-PROCESSAMENTO
   ├─ PostGenerationFixer.fixCharacterIntroductions()
   ├─ Concatena 12 blocos
   └─ Retorna ScriptResult

5. OPCIONAL: SrtService.generateSrtFromScript()
   └─ Gera legendas .srt
```

### Tempos Médios (Flash mode, 10k palavras)

| Fase | Tempo | Modelo |
|------|-------|--------|
| Sinopse | ~10s | Flash |
| Blocos 1-7 (Flash) | ~35s/bloco | Flash 2.5 |
| Blocos 8-12 (Pro) | ~35s/bloco | Pro 2.0 |
| WorldState (3×) | ~8s/vez | Flash |
| **TOTAL** | **~7-8min** | Híbrido |

---

## ⚙️ CONFIGURAÇÕES E CONSTANTES

### ScriptConfig
**Localização:** `lib/data/models/script_config.dart`

```dart
class ScriptConfig {
  final int quantity;          // 2000-30000
  final String measureType;    // 'palavras' ou 'caracteres'
  final String language;        // 'Português', 'Inglês', etc
  final String theme;           // 'Vingança', 'Amor', etc
  final String qualityMode;     // 'flash', 'pro', 'ultra'
  final String title;
  final List<String> keywords; // ['vingança', 'traição', ...]
}
```

### GenerationProgress
**Localização:** `lib/data/models/generation_progress.dart`

```dart
class GenerationProgress {
  final String stage;        // 'Preparação', 'Introdução', 'Clímax', 'Finalização'
  final int currentBlock;    // 1-12
  final int totalBlocks;     // 12
  final double percentage;   // 0.0-1.0
}
```

### ScriptResult
**Localização:** `lib/data/models/script_result.dart`

```dart
class ScriptResult {
  final bool success;
  final String? script;           // Roteiro completo
  final String? viralHook;        // Gancho viral
  final String? errorMessage;
  final int? actualWordCount;
  final Map<String, dynamic>? metadata;
}
```

---

## 📊 LOGS E DEBUGGING

### Logs Importantes

**v7.6.169 - Seleção de Modelo:**
```
🔄 v7.6.169 HÍBRIDO: Bloco 7/12 usando Gemini Flash
🔄 v7.6.169 HÍBRIDO: Bloco 8/12 usando Pro (contexto grande)
```

**v7.6.171 - Trim Inteligente:**
```
✂️ v7.6.171 TRIM INTELIGENTE: Bloco 4 cortado 8866 → 6782 chars (tipo: paragraph, limite: 7122)
✂️ v7.6.171 TRIM INTELIGENTE: Bloco 5 cortado 13499 → 6565 chars (tipo: paragraph, limite: 7109)
```

**v7.6.172 - Filtro de Pronomes:**
```
⏭️ v7.6.172: "Her" ignorado (pronome comum, não nome)
⏭️ v7.6.172: "He" ignorado (pronome comum, não nome)
```

**Cálculo de Blocos:**
```
📊 CÁLCULO DE BLOCOS (DEBUG):
   Idioma: "Coreano"
   IsKoreanMeasure? true
   Ratio: 4.2
   WordsEquivalent: 2619
   🇰🇷 COREANO (FLASH): 2619 palavras → 550 target = 5 → 6 blocos (~437 pal/bloco)
```

### Debug Mode

Habilitar logs detalhados em `lib/data/services/gemini_service.dart`:

```dart
final kDebugMode = true; // Mostrar logs detalhados
```

---

## 🧪 TESTES

### Testes Unitários
**Localização:** `test/`

**Principais:**
- `block_calculator_test.dart` - Validação de cálculos por idioma
- `char_limit_test.dart` - Limites de caracteres por idioma
- `name_validation_test.dart` - Validação de nomes e pronomes
- `otimizacoes_v7_6_172_test.dart` - Validação das otimizações

**Executar:**
```bash
flutter test
```

### Testes de Produção Realizados

**v7.6.172 (Inglês, 10625 palavras):**
- ✅ Tempo: 7min 41s
- ✅ Palavras: 11410 (+7.4%)
- ✅ Retries pronomes: 0
- ✅ Trim: 100% paragraph

**Coreano (15000 palavras estimadas):**
- ✅ Hangul: Perfeito
- ✅ Autenticidade: 10/10
- ✅ Ratio 4.2: Aplicado
- ✅ Compensação +18%: Funcionou

---

## 🔐 SEGURANÇA E API KEYS

### Validação de API Key
**Arquivo:** `api_validation_service.dart`

```dart
Future<bool> validateApiKey(String apiKey)
```
- Testa API key com request mínimo
- Retorna `true` se válida
- Cacheia resultado

### Armazenamento
**Não comitar API keys no Git!**

- Use `.env` ou variáveis de ambiente
- Configure em `lib/core/constants/api_constants.dart`

```dart
class ApiConstants {
  static String get geminiApiKey => 
    const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
}
```

---

## 📦 DEPENDÊNCIAS

**pubspec.yaml (principais):**

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  dio: ^5.4.0
  shared_preferences: ^2.2.2
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## 🚀 DEPLOY E BUILD

### Build para Produção

**Windows:**
```bash
flutter build windows --release
```

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

---

## 📞 SUPORTE E MANUTENÇÃO

### Contato
- **Desenvolvedor:** Guilherme
- **Versão Atual:** v7.6.172
- **Data:** Dezembro 14, 2025

### Próximas Melhorias Sugeridas

1. **Adicionar mais idiomas:** Italiano, Húngaro, etc.
2. **UI para exportar SRT:** Interface gráfica para legendas
3. **Histórico de gerações:** Salvar roteiros anteriores
4. **Templates de temas:** Pré-configurações por gênero
5. **Métricas de qualidade:** Score automático do roteiro
6. **Retry inteligente:** Apenas em erros críticos

---

## 📝 CHANGELOG

### v7.6.172 (14/12/2025) - ATUAL
- ✅ Filtro de pronomes (31 pronomes, 4 idiomas)
- ✅ Zero retries de pronomes
- ✅ Tempo reduzido 13min → 7min41s

### v7.6.171 (13/12/2025)
- ✅ Trim inteligente (paragraph > line > sentence)
- ✅ 100% cortes limpos
- ✅ +1% precisão de palavras

### v7.6.170 (12/12/2025)
- ✅ Trim garantido (1.5× limite)
- ✅ Zero retries por tamanho

### v7.6.169 (11/12/2025)
- ✅ Modelo híbrido Flash+Pro
- ✅ Threshold 60% (bloco 8/12)
- ✅ Otimização custo/velocidade

### v7.6.136
- ✅ Whitelist de compostos
- ✅ Detecção de frases

### v7.6.135
- ✅ Compensação coreana +18%
- ✅ Max 35 blocos para coreano

---

## 🎓 REFERÊNCIAS

- [Gemini API Documentation](https://ai.google.dev/docs)
- [Flutter Documentation](https://docs.flutter.dev)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- `MATEMATICA_BLOCOS_12_IDIOMAS_v7.6.125.md` - Fórmulas detalhadas
- `DIAGNOSTICO_PERFORMANCE_v7.6.125.md` - Análise de performance
- `COMPARACAO_PRO_VS_FLASH_v7.6.125.md` - Comparativo de modelos

---

**FIM DA DOCUMENTAÇÃO TÉCNICA v7.6.172**

*Gerado em: Dezembro 14, 2025*
