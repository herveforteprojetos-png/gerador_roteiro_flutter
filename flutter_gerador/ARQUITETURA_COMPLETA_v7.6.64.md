# 🎬 ARQUITETURA COMPLETA - Gerador de Roteiros YouTube v7.6.64

> **Data:** Dezembro 2024  
> **Versão:** v7.6.64  
> **Motor:** Gemini AI (Pro 2.5 / Flash 2.0 / Ultra 3.0)

---

## 📋 ÍNDICE

1. [Visão Geral do Sistema](#1-visão-geral-do-sistema)
2. [Arquitetura de Modelos (LLM)](#2-arquitetura-de-modelos-llm)
3. [Configurações do Usuário](#3-configurações-do-usuário)
4. [Sistema de Geração em Blocos](#4-sistema-de-geração-em-blocos)
5. [Sistema de Pacing (6 Fases)](#5-sistema-de-pacing-6-fases)
6. [World State (Memória Infinita)](#6-world-state-memória-infinita)
7. [Sistema de Nomes de Personagens](#7-sistema-de-nomes-de-personagens)
8. [Sistema Anti-Duplicação de Nomes](#8-sistema-anti-duplicação-de-nomes)
9. [Validadores de Qualidade](#9-validadores-de-qualidade)
10. [Sistema de Prompts](#10-sistema-de-prompts)
11. [Regras TTS (Text-to-Speech)](#11-regras-tts-text-to-speech)
12. [Sistema de CTAs](#12-sistema-de-ctas)
13. [Níveis de Localização](#13-níveis-de-localização)
14. [Estilos Narrativos](#14-estilos-narrativos)
15. [Sistema de Logs e Debug](#15-sistema-de-logs-e-debug)
16. [Fluxo Completo de Geração](#16-fluxo-completo-de-geração)

---

## 1. VISÃO GERAL DO SISTEMA

### 1.1 Propósito
Gerador automático de roteiros para vídeos YouTube usando IA generativa, otimizado para narração TTS (Text-to-Speech).

### 1.2 Stack Tecnológico
- **Frontend:** Flutter/Dart (Windows Desktop)
- **Backend:** Gemini API (Google AI)
- **Fallback:** OpenAI API (opcional)
- **Estado:** Riverpod (Provider)

### 1.3 Arquivos Principais
```
lib/
├── data/
│   ├── models/
│   │   ├── script_config.dart         # Configurações do roteiro
│   │   ├── generation_config.dart     # Config de geração
│   │   └── localization_level.dart    # Níveis de localização
│   └── services/
│       ├── gemini_service.dart        # Motor principal (~9000 linhas)
│       └── prompts/
│           ├── main_prompt_template.dart  # Templates de prompt
│           ├── youtube_rules.dart         # Regras YouTube
│           ├── base_rules.dart            # Regras base
│           ├── character_rules.dart       # Regras de personagens
│           └── structure_rules.dart       # Regras de estrutura
├── presentation/
│   ├── pages/
│   │   └── home_page.dart             # Página principal
│   ├── widgets/
│   │   └── layout/
│   │       └── expanded_header_widget.dart  # Configurações UI
│   └── providers/
│       └── generation_config_provider.dart  # Estado global
```

---

## 2. ARQUITETURA DE MODELOS (LLM)

### 2.1 Modelos Disponíveis

| Modo | Modelo | Uso | Custo |
|------|--------|-----|-------|
| `flash` | gemini-2.0-flash-exp | Tarefas simples, CTAs | Baixo |
| `pro` | gemini-2.5-pro-preview-05-06 | Escrita criativa (padrão) | Médio |
| `ultra` | gemini-3.0-preview | Máxima qualidade | Alto |

### 2.2 Seleção de Modelo
```dart
static String _getSelectedModel(String qualityMode) {
  return qualityMode == 'flash'
      ? 'gemini-2.0-flash-exp'
      : qualityMode == 'ultra'
          ? 'gemini-3.0-preview'
          : 'gemini-2.5-pro-preview-05-06'; // pro (padrão)
}
```

### 2.3 Arquitetura Híbrida (Pipeline)
- **Escrita Criativa:** Pro/Ultra (qualidade)
- **Extração JSON:** Flash (velocidade)
- **Análise de Contexto:** Flash
- **Geração de CTAs:** Flash (forçado v7.6.62)
- **Tradução de Keywords:** Flash (v7.6.64)
- **Validação de Coerência:** Flash

### 2.4 Configuração de Tokens
```dart
// Limites por idioma
final maxTokensLimit = 50000; // Padrão
final tokenMultiplier = isCyrillic || isTurkish ? 5.0 : 2.5;
```

---

## 3. CONFIGURAÇÕES DO USUÁRIO

### 3.1 ScriptConfig - Parâmetros Principais

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `apiKey` | String | Chave API Gemini |
| `openAIKey` | String? | Chave OpenAI (fallback) |
| `selectedProvider` | String | 'gemini' ou 'openai' |
| `title` | String | Título do roteiro |
| `tema` | String | Tema principal |
| `subtema` | String | Subtema/detalhes |
| `localizacao` | String | Local/época da história |
| `language` | String | Idioma do roteiro |
| `perspective` | String | Perspectiva narrativa |
| `measureType` | String | 'palavras' ou 'caracteres' |
| `quantity` | int | Quantidade desejada |
| `qualityMode` | String | 'flash', 'pro', 'ultra' |
| `localizationLevel` | LocalizationLevel | Global/Nacional/Regional |
| `narrativeStyle` | String | Estilo de narração |
| `videoFormat` | VideoFormat | Formato YouTube |
| `customPrompt` | String | Prompt personalizado |
| `useCustomPrompt` | bool | Usar prompt custom |

### 3.2 Perspectivas Disponíveis
- `primeira_pessoa_feminino` - "Eu" (narradora)
- `primeira_pessoa_masculino` - "Eu" (narrador)
- `terceira_pessoa_feminino` - "Ela" (protagonista)
- `terceira_pessoa_masculino` - "Ele" (protagonista)

### 3.3 Formatos de Vídeo
```dart
enum VideoFormat {
  standard,      // Variável
  youtubeShort,  // 1-3 min (400 palavras)
  youtubeMedium, // 8-15 min (2200 palavras)
  youtubeLong,   // 20-30 min (5000 palavras)
}
```

### 3.4 Limites de Quantidade
- **Palavras:** 500 - 14.000
- **Caracteres:** 1.000 - 100.000

---

## 4. SISTEMA DE GERAÇÃO EM BLOCOS

### 4.1 Conceito
Roteiros longos são divididos em blocos menores para:
- Manter contexto gerenciável
- Evitar timeout de API
- Permitir validação incremental
- Streaming de progresso

### 4.2 Cálculo de Blocos
```dart
// Tamanho máximo por bloco
final maxBlockSize = measureType == 'caracteres' ? 15000 : 5000;

// Número de blocos
int numBlocks = (targetQuantity / maxBlockSize).ceil();
if (numBlocks < 2) numBlocks = 2;  // Mínimo 2 blocos
if (numBlocks > 20) numBlocks = 20; // Máximo 20 blocos
```

### 4.3 Contexto Entre Blocos
```dart
// Últimos N blocos como contexto
final maxContextBlocks = isPortuguese ? 3 : 4;
String contextoPrevio = _buildLimitedContext(previous, blockNumber, maxContextBlocks);
```

### 4.4 Delay Entre Blocos
```dart
// Delays adaptativos por fase
if (progress <= 0.15) return 50;   // Preparação
if (progress <= 0.30) return 75;   // Introdução
if (progress <= 0.65) return 100;  // Desenvolvimento
if (progress <= 0.80) return 125;  // Clímax
if (progress <= 0.95) return 75;   // Resolução
return 50;                          // Finalização
```

---

## 5. SISTEMA DE PACING (6 FASES)

### 5.1 Fases Narrativas

| Fase | Progresso | Descrição |
|------|-----------|-----------|
| **Preparação** | 0-15% | Setup inicial, apresentação |
| **Introdução** | 15-30% | Estabelecer personagens e conflito |
| **Desenvolvimento** | 30-65% | Expandir trama, tensão crescente |
| **Clímax** | 65-80% | Pico de tensão, confronto |
| **Resolução** | 80-95% | Resolver conflitos |
| **Finalização** | 95-100% | Conclusão, fechamento |

### 5.2 Cálculo de Fase
```dart
int _getPhaseIndexFromProgress(double p) {
  if (p <= 0.15) return 0; // Preparação
  if (p <= 0.30) return 1; // Introdução
  if (p <= 0.65) return 2; // Desenvolvimento
  if (p <= 0.80) return 3; // Clímax
  if (p <= 0.95) return 4; // Resolução
  return 5;                 // Finalização
}
```

### 5.3 Instruções por Fase
```dart
final phaseInstruction = {
  'Preparação': 'Apresente o cenário e protagonista',
  'Introdução': 'Estabeleça o conflito principal',
  'Desenvolvimento': 'Expanda a trama com tensão crescente',
  'Clímax': 'Momento de maior tensão e confronto',
  'Resolução': 'Resolva os conflitos pendentes',
  'Finalização': 'Conclua definitivamente a história',
};
```

---

## 6. WORLD STATE (MEMÓRIA INFINITA)

### 6.1 Estrutura
```dart
class _WorldState {
  Map<String, _WorldCharacter> personagens;  // Personagens
  Map<String, List<String>> inventario;       // Objetos por personagem
  List<Map<String, dynamic>> fatos;           // Eventos importantes
  int ultimoBloco;                            // Último bloco processado
  String resumoAcumulado;                     // Resumo cumulativo
  String sinopseComprimida;                   // Sinopse ≤500 tokens
}
```

### 6.2 Estrutura de Personagem
```dart
class _WorldCharacter {
  final String nome;
  final String papel;
  final String status;       // 'ativo', 'resolvido', 'ausente'
  final String? localAtual;  // Última localização conhecida
}
```

### 6.3 Contexto em 3 Camadas (Sanduíche)
```
═══════════════════════════════════════════════════
📊 CONTEXTO ESTRUTURADO - Pipeline v7.6.53
═══════════════════════════════════════════════════

🔵 CAMADA 1 - SINOPSE DA HISTÓRIA (Estática):
   [Sinopse comprimida ≤500 tokens]

🟢 CAMADA 2 - PERSONAGENS ATIVOS:
   {"protagonista": {"nome":"Kim Min-jun","papel":"protagonista"}}

🟡 CAMADA 3 - FATOS RECENTES:
   [{"bloco":3,"evento":"Encontrou o documento secreto"}]
```

### 6.4 Atualização do World State
```dart
Future<void> _updateWorldState({
  required String blockText,
  required int blockNumber,
  required String apiKey,
  required _WorldState worldState,
  required _CharacterTracker tracker,
}) async {
  // Usa Flash para extração de JSON (tarefa simples)
  final extractionPrompt = '''
    Analise o texto e extraia:
    - Novos personagens (nome, papel)
    - Novos objetos importantes
    - Eventos/fatos relevantes
    Responda em JSON...
  ''';
}
```

---

## 7. SISTEMA DE NOMES DE PERSONAGENS

### 7.1 Arquitetura: LLM-Driven (100% Dinâmico)

O sistema **NÃO usa banco de dados estático**. Nomes são gerados pelo próprio LLM baseado em:
- Idioma do roteiro
- Localização/cultura
- Contexto da história

### 7.2 Fluxo de Geração de Nomes
```
┌─────────────────────────────────────────┐
│  1. Usuário configura idioma/localização │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  2. Gemini Pro gera roteiro com nomes   │
│     culturalmente apropriados           │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  3. Gemini Flash extrai nomes do texto  │
│     via _updateWorldState()             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  4. _isLikelyName() valida estrutura    │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  5. CharacterTracker guarda os nomes    │
└─────────────────────────────────────────┘
```

### 7.3 Validação Estrutural
```dart
bool _isLikelyName(String text) {
  if (text.isEmpty || text.length < 2 || text.length > 50) return false;
  
  // Regex Unicode-aware
  final namePattern = RegExp(
    r"^[A-Z\u00C0-\u00DC\u0100-\u017F\uAC00-\uD7AF]"  // Início maiúsculo
    r"[a-zA-Z\u00C0-\u00FF\u0100-\u017F\uAC00-\uD7AF\s\-']+$"
  );
  
  return namePattern.hasMatch(text);
}
```

**Suporte a:**
- Letras latinas (A-Z, a-z)
- Acentos (À-Ü, à-ÿ)
- Caracteres europeus estendidos (Ā-ſ)
- Hangul coreano (가-힣)
- Espaços, hífens, apóstrofos

### 7.4 Lembrete Agressivo no Prompt
```
🚨🚨🚨 LEMBRETE OBRIGATÓRIO DE NOMES 🚨🚨🚨

📋 PERSONAGENS DESTA HISTÓRIA:
   👤 Protagonista: 김민준 (Kim Min-jun)
   👤 Vilão: 박영수 (Park Young-su)
   
⚠️ USE EXATAMENTE ESTES NOMES!
🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨
```

---

## 8. SISTEMA ANTI-DUPLICAÇÃO DE NOMES

### 8.1 5 Camadas de Proteção

#### Camada 1: CharacterTracker (Registro Central)
```dart
class _CharacterTracker {
  final Set<String> _confirmedNames = {};         // Nomes usados
  final Map<String, String> _characterRoles = {}; // nome → papel
  final Map<String, String> _roleToName = {};     // papel → nome
}
```

#### Camada 2: Validação de Sobreposição (v7.6.30)
```dart
// Detecta: "Arthur" conflita com "Arthur Evans"
final commonWords = nameWords.toSet().intersection(existingWords.toSet());
if (commonWords.isNotEmpty) {
  return true; // BLOQUEAR
}
```

#### Camada 3: Validação Bidirecional (v7.6.25)
- **Mesmo NOME em PAPÉIS diferentes** = ❌ ERRO
- **Mesmo PAPEL com NOMES diferentes** = ❌ ERRO

#### Camada 4: Possessivos Singulares (v7.6.33)
```dart
// "my lawyer, Richard" (Bloco 5)
// "my lawyer, Mark" (Bloco 10) → REJEITADO!

final possessiveSingularPattern = RegExp(
  r'\b(?:my|nossa)\s+(?:lawyer|doctor|therapist|...)(?![a-z])',
  caseSensitive: false,
);
```

#### Camada 5: Forbidden Names Warning
```
🚫🚫🚫 NOMES PROIBIDOS - NÃO USE! 🚫🚫🚫
⛔ Já em uso: Kim Min-jun, Park Young-su, Lee Ji-hoon
```

### 8.2 Fluxo de Validação
```
BLOCO GERADO
     ↓
_validateNamesInText() → Checa duplicatas
     ↓
_validateUniqueNames() → Checa papéis
     ↓
CONFLITO? → SIM → REJEITA E REGENERA
     ↓ NÃO
ACEITA E ADICIONA AO TRACKER
```

---

## 9. VALIDADORES DE QUALIDADE

### 9.1 Lista de Validadores

| Validador | Função | Ação |
|-----------|--------|------|
| `_validateProtagonistName` | Nome correto da protagonista | Rejeita bloco |
| `_validateFamilyRelationships` | Relacionamentos familiares | Rejeita bloco |
| `_validateUniqueNames` | Nomes únicos por papel | Rejeita bloco |
| `_validateNamesInText` | Nomes não duplicados | Rejeita bloco |
| `_validateTitleCoherenceRigorous` | Coerência título↔história | Alerta/Recovery |
| `_filterDuplicateParagraphs` | Remove parágrafos duplicados | Filtra texto |

### 9.2 Validação de Coerência Título↔História (v7.6.64)
```dart
Future<Map<String, dynamic>> _validateTitleCoherenceRigorous({
  required String title,
  required String story,
  required String language,
  required String apiKey,
}) async {
  // 1. Extrair elementos-chave do título
  final keyElements = _extractTitleKeyElements(title, language);
  
  // 2. Traduzir keywords para idioma do roteiro (v7.6.64)
  final translatedKeywords = await _translateKeywordsToTargetLang(
    keyElements, language, apiKey
  );
  
  // 3. Validar presença no texto
  // 4. Validação semântica via IA (Flash)
}
```

### 9.3 Taxa de Fechamento (Bloco Final)
```dart
if (blockNumber == totalBlocks) {
  final closureRate = tracker.getClosureRate();
  if (closureRate < 0.90) { // 90% mínimo
    return ''; // Força regeneração
  }
}
```

---

## 10. SISTEMA DE PROMPTS

### 10.1 Arquivos de Prompts
```
lib/data/services/prompts/
├── main_prompt_template.dart  # Template principal
├── youtube_rules.dart         # Regras YouTube
├── base_rules.dart            # Regras fundamentais
├── character_rules.dart       # Regras de personagens
└── structure_rules.dart       # Regras de estrutura
```

### 10.2 Estrutura do Prompt Principal
```dart
final prompt =
    perspectiveInstruction +      // Gênero/perspectiva
    worldStateContext +           // World State (memória)
    titleSection +                // Título da história
    MainPromptTemplate.buildCompactPrompt(
      language: ...,
      instruction: ...,           // Instrução da fase
      temaSection: ...,
      localizacao: ...,
      localizationGuidance: ...,  // Nível de localização
      narrativeStyleGuidance: ...,
      customPrompt: ...,
      nameList: ...,              // Nomes confirmados
      trackerInfo: ...,           // Info do tracker
      contextoPrevio: ...,        // Blocos anteriores
      avoidRepetition: ...,       // Flag anti-repetição
      forbiddenNamesWarning: ..., // Nomes proibidos
    ) +
    blockInfo;                    // Info do bloco atual
```

### 10.3 Checklist YouTube (Incluído no Prompt)
```
🚨 CHECKLIST OBRIGATÓRIO 🚨

📋 PERGUNTA 1: "Posso explicar TODO o roteiro em 2 frases?"
📋 PERGUNTA 2: "Quantos personagens COM NOME vou usar?" (máx 6)
📋 PERGUNTA 3: "Todos os vilões serão RESOLVIDOS?"
📋 PERGUNTA 4: "Há conexão lógica entre começo e fim?"
📋 PERGUNTA 5: "A história tem UM objetivo central claro?"
```

---

## 11. REGRAS TTS (TEXT-TO-SPEECH)

### 11.1 Diretrizes de Escrita para Áudio

#### 1️⃣ Capitalização & Pontuação (Entonação)
```
❌ ERRADO: "o presidente olhou e disse oi."
✅ CORRETO: "O Presidente olhou e disse: 'Oi!'"
```

#### 2️⃣ Números por Extenso
```
❌ ERRADO: "10 anos", "R$ 500", "5km"
✅ CORRETO: "dez anos", "quinhentos reais", "cinco quilômetros"
```

#### 3️⃣ Ritmo de Fala (Máx 20-25 palavras/frase)
```
❌ ERRADO: "Ele correu pela rua enquanto pensava em tudo que tinha 
           acontecido naquele dia terrível quando descobriu a verdade."

✅ CORRETO: "Ele correu pela rua. Pensava em tudo que tinha acontecido.
            Naquele dia terrível, descobriu a verdade."
```

#### 4️⃣ Continuidade Fluída (Sem Recaps)
```
❌ ERRADO: "Na mansão onde tudo tinha começado, Maria ainda estava..."
✅ CORRETO: "Maria fechou os olhos. Precisava de um momento."
```

#### 5️⃣ Anti-Echo (v7.6.64) - Proibição de Repetição
```
❌ PROIBIDO: Repetir "Como dizia meu pai: a vida é um rio..." em múltiplos blocos
❌ PROIBIDO: Usar o mesmo ditado/provérbio mais de 1 vez
❌ PROIBIDO: Fazer personagem ter "mesma lembrança" repetidamente

✅ CORRETO: Variar entre reflexão e ação
✅ CORRETO: Se usou ditado no bloco 2, no bloco 3 avance sem filosofar
```

---

## 12. SISTEMA DE CTAs

### 12.1 Tipos de CTA Disponíveis
- `subscribe` - Inscrição no canal
- `like` - Curtir o vídeo
- `comment` - Comentar
- `share` - Compartilhar
- `notification` - Ativar notificações
- `playlist` - Ver playlist
- `related` - Vídeos relacionados

### 12.2 Geração de CTAs
```dart
Future<Map<String, String>> generateCtasForScript({
  required String scriptContent,
  required String apiKey,
  required List<String> ctaTypes,
  String? customTheme,
  String language = 'Português',
  String perspective = 'primeira_pessoa_feminino',
}) async {
  // 1. Analisar contexto (Flash)
  final scriptContext = await _analyzeScriptContext(...);
  
  // 2. Gerar CTAs contextualizados (Flash - v7.6.62)
  final prompt = _buildAdvancedCtaPrompt(...);
  
  // 3. Parse e validação
  return _parseCtaResponseWithValidation(result, ctaTypes, scriptContent);
}
```

### 12.3 CTAs Respeitam Perspectiva
```dart
// Primeira pessoa
"Eu nunca imaginei que minha história tocaria tantas pessoas..."

// Terceira pessoa
"A história de Maria tocou milhares de pessoas..."
```

---

## 13. NÍVEIS DE LOCALIZAÇÃO

### 13.1 Enum LocalizationLevel

| Nível | Descrição | Uso |
|-------|-----------|-----|
| `global` | Sem regionalismos, traduzível | Público internacional |
| `national` | Referências do país | Todo território |
| `regional` | Gírias e referências locais | Público específico |

### 13.2 Modo Global - Restrições
```
❌ NOMES PROIBIDOS: João, Maria, José, Fernanda, Carla
✅ NOMES PERMITIDOS: Marco, Lucas, Sofia, Alex, Elena

❌ NEGÓCIOS: "Delícias da Vovó", "Padaria do Seu João"
✅ NEGÓCIOS: "Anna's Bakery", "Golden Residence"

❌ COMIDAS: bolo de fubá, brigadeiro, açaí, coxinha
✅ COMIDAS: pão, bolo (genérico), café, torta

❌ TRATAMENTOS: "dona Helena", "seu Afonso", "Vovó Estela"
✅ TRATAMENTOS: "Mrs. Elena", "Mr. Paul", "Grandma Elena"

❌ INSTITUIÇÕES: SUS, INSS, Detran
✅ INSTITUIÇÕES: "sistema de saúde", "previdência"
```

### 13.3 Teste de Ouro
> "Isso existe naturalmente em Polônia, Rússia, Japão, Alemanha?"
> → NÃO = substituir por versão universal

---

## 14. ESTILOS NARRATIVOS

### 14.1 Estilos Disponíveis

| Estilo | Descrição |
|--------|-----------|
| `ficcional_livre` | Narração livre (padrão) |
| `reflexivo_memorias` | Nostálgico, introspectivo |
| `epico_periodo` | Grandioso, histórico |
| `suspense_thriller` | Tenso, ritmo acelerado |
| `comedia_leve` | Humorístico, descontraído |
| `drama_intenso` | Emocional, profundo |

### 14.2 Exemplo: Reflexivo (Memórias)
```
Tom: Nostálgico, pausado, introspectivo
Ritmo: Lento e contemplativo

Vocabulário:
- "gentil", "singelo", "sutil", "delicado"
- "naqueles dias", "antigamente", "costumava"
- Verbos no imperfeito: "era", "tinha", "fazia"

Técnicas:
- Digressões naturais
- Comparações passado × presente
- "Se não me engano...", "Creio que..."
```

### 14.3 Exemplo: Épico de Período
```
Tom: Grandioso, formal, heroico
Ritmo: Cadenciado e majestoso

Vocabulário:
- "honra", "destino", "coragem", "sacrifício"
- "sob o sol escaldante", "nas sombras da história"
- Evitar contrações: "não havia" (não "não tinha")

🚨 ANACRONISMOS A EVITAR (baseado no ano):
- Se 1800: ❌ telefone, carro, avião
- Se 1950: ❌ internet, celular, GPS
```

---

## 15. SISTEMA DE LOGS E DEBUG

### 15.1 Debug Logger
```dart
class _DebugLogger {
  void info(String message, {String? details, Map<String, dynamic>? metadata});
  void error(String message, {int? blockNumber, String? details, Map<String, dynamic>? metadata});
  void warning(String message, {int? blockNumber, String? details});
}
```

### 15.2 Logs por Categoria
```
📊 CONTEXTO: COMPLETO/LIMITADO (últimos N blocos)
🔍 ELEMENTOS-CHAVE DETECTADOS NO TÍTULO
🌐 KEYWORDS TRADUZIDAS PARA [idioma]
🎯 qualityMode = "pro"
🤖 selectedModel = "gemini-2.5-pro-preview-05-06"
❌ BLOCO N REJEITADO: [motivo]
✅ TODOS os personagens têm fechamento!
```

### 15.3 Métricas de Geração
```dart
// Callback de progresso
onProgress?.call(ScriptProgress(
  currentBlock: block,
  totalBlocks: numBlocks,
  currentPhase: phase,
  totalPhases: _phases.length,
  partialText: accumulatedText,
  progress: block / numBlocks,
  estimatedTimeRemaining: ...,
));
```

---

## 16. FLUXO COMPLETO DE GERAÇÃO

### 16.1 Diagrama de Alto Nível
```
┌─────────────────────────────────────────────────────────────────┐
│  USUÁRIO CONFIGURA                                              │
│  - Título, Tema, Idioma, Quantidade                             │
│  - Perspectiva, Localização, Estilo Narrativo                   │
│  - Modelo (Flash/Pro/Ultra)                                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  INICIALIZAÇÃO                                                  │
│  - Criar CharacterTracker                                       │
│  - Criar WorldState                                             │
│  - Calcular número de blocos                                    │
│  - Gerar sinopse comprimida (Camada 1)                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  LOOP DE BLOCOS (1 a N)                                         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  1. Determinar fase (Pacing)                              │  │
│  │  2. Montar prompt com:                                    │  │
│  │     - World State (3 camadas)                             │  │
│  │     - Contexto dos blocos anteriores                      │  │
│  │     - Nomes confirmados + proibidos                       │  │
│  │     - Instruções da fase                                  │  │
│  │     - Regras TTS + YouTube                                │  │
│  │  3. Chamar API (Pro/Ultra)                                │  │
│  │  4. Validar bloco gerado                                  │  │
│  │     - Nome protagonista                                   │  │
│  │     - Relacionamentos familiares                          │  │
│  │     - Nomes únicos                                        │  │
│  │  5. Se inválido → Regenerar (máx 3 tentativas)           │  │
│  │  6. Filtrar parágrafos duplicados                         │  │
│  │  7. Atualizar World State (Flash)                         │  │
│  │  8. Atualizar CharacterTracker                            │  │
│  │  9. Delay adaptativo                                      │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  PÓS-PROCESSAMENTO                                              │
│  - Validar coerência título↔história                            │
│  - Verificar taxa de fechamento (≥90%)                          │
│  - Recovery se elementos faltando                               │
│  - Filtrar duplicatas globais                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  SAÍDA FINAL                                                    │
│  - Roteiro completo                                             │
│  - Metadados (personagens, fatos)                               │
│  - CTAs contextualizados (opcional)                             │
└─────────────────────────────────────────────────────────────────┘
```

### 16.2 Tratamento de Erros
```dart
// Retry com exponential backoff
for (int attempt = 0; attempt < maxRetries; attempt++) {
  try {
    final result = await _makeApiRequest(...);
    if (result != null) return result;
  } catch (e) {
    final delay = Duration(seconds: pow(2, attempt).toInt());
    await Future.delayed(delay);
  }
}
```

### 16.3 Adaptive Delay Manager
```dart
// Registra sucesso/falha para ajustar delays
void _recordApiSuccess() { ... }
void _recordApiFailure() { ... }
int _getAdaptiveDelay() { ... }
```

---

## 📊 MÉTRICAS DO SISTEMA

| Métrica | Valor |
|---------|-------|
| **Linhas de código (gemini_service.dart)** | ~9.000 |
| **Versão atual** | v7.6.64 |
| **Fases narrativas** | 6 |
| **Camadas de World State** | 3 |
| **Camadas anti-duplicação** | 5 |
| **Modelos suportados** | 3 (Flash, Pro, Ultra) |
| **Idiomas testados** | PT, EN, ES, KO, RU |
| **Máx tokens/bloco** | 50.000 |
| **Máx blocos** | 20 |
| **Taxa fechamento mínima** | 90% |

---

## 🔧 PONTOS DE LAPIDAÇÃO SUGERIDOS

### Alta Prioridade
1. **Otimização de Tokens** - Reduzir tamanho dos prompts
2. **Cache de Traduções** - Evitar traduzir mesmas keywords
3. **Paralelização** - World State update em paralelo

### Média Prioridade
4. **Métricas de Qualidade** - Score automático por roteiro
5. **A/B Testing** - Comparar Pro vs Ultra
6. **Compressão de Contexto** - Resumir blocos antigos

### Baixa Prioridade
7. **UI de Debug** - Visualizar World State em tempo real
8. **Export/Import** - Salvar/carregar configurações
9. **Batch Generation** - Gerar múltiplos roteiros

---

> **Documento gerado em:** Dezembro 2024  
> **Autor:** Sistema de Documentação Automática  
> **Versão do Motor:** v7.6.64
