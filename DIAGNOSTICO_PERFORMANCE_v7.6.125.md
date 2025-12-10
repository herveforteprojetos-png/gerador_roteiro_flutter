# 📊 DIAGNÓSTICO DE PERFORMANCE - v7.6.125

**Data:** 09/12/2025  
**Arquivo:** `lib/data/services/gemini_service.dart`  
**Problema:** Geração de roteiro levando ~20 minutos (inviável)  
**Objetivo:** Identificar gargalos através de cronometragem detalhada

---

## 📋 ÍNDICE

1. [Análise de Delays (Rate Limit)](#1-análise-de-delays-rate-limit)
2. [Análise de Retries (Rejeição)](#2-análise-de-retries-rejeição)
3. [Análise de Payload (Contexto)](#3-análise-de-payload-contexto)
4. [Logs de Tempo Implementados](#4-logs-de-tempo-implementados-v7625)
5. [Suspeitos do Gargalo](#5-suspeitos-do-gargalo-de-20-minutos)
6. [Próximos Passos](#6-próximos-passos-recomendados)

---

## 1. ANÁLISE DE DELAYS (Rate Limit)

### 1.1 Delay Fixo no Loop Principal

**❌ NÃO existe delay fixo obrigatório entre blocos**

O sistema só aplica delay SE houver erros 503 recentes:

```dart
// Linha 273 - gemini_service.dart
if (block > 1 && _consecutive503Errors > 0) {
  await Future.delayed(_getAdaptiveDelay(blockNumber: block));
}
```

### 1.2 Configuração de Espera Adaptativa

**Método:** `_getAdaptiveDelay()` (Linhas 809-831)

| Faixa de Blocos | Delay Normal | Delay com Erro 503 |
|-----------------|--------------|-------------------|
| **Blocos 1-5**  | 250ms        | 5-15 segundos     |
| **Blocos 6-15** | 500ms        | 5-15 segundos     |
| **Blocos 16-25**| 750ms        | 5-15 segundos     |
| **Blocos 26+**  | 1 segundo    | 5-15 segundos     |

**Código completo:**

```dart
Duration _getAdaptiveDelay({required int blockNumber}) {
  if (_lastSuccessfulCall != null &&
      DateTime.now().difference(_lastSuccessfulCall!) <
          const Duration(seconds: 3)) {
    _consecutiveSuccesses++;
    if (_consecutiveSuccesses >= 2) {
      return blockNumber <= 10
          ? const Duration(milliseconds: 300)
          : const Duration(milliseconds: 800);
    }
  }
  if (_consecutive503Errors > 0) {
    _consecutiveSuccesses = 0;
    return Duration(seconds: min(5 * _consecutive503Errors, 15));
  }
  _consecutiveSuccesses = 0;
  _consecutive503Errors = max(0, _consecutive503Errors - 1);
  
  // 🚀 v7.6.117: Delays reduzidos para acelerar geração
  if (blockNumber <= 5) return const Duration(milliseconds: 250);
  if (blockNumber <= 15) return const Duration(milliseconds: 500);
  if (blockNumber <= 25) return const Duration(milliseconds: 750);
  return const Duration(seconds: 1);
}
```

### 1.3 Delays Secundários (Negligíveis)

- **UI Update:** 10ms a cada 4 blocos (Linha 268)
- **WorldState Update:** 50ms (Linha 622)

### ⚠️ **PROBLEMA IDENTIFICADO #1**

Se a API Gemini retornar **erros 503 frequentes**, o delay escala para:
- **5s × número de erros (máximo 15s)**
- Em 30 blocos com 2 erros = **30-90 segundos extras**

---

## 2. ANÁLISE DE RETRIES (Rejeição)

### 2.1 Cenário A: Bloco Vazio Após Geração Inicial

**Localização:** Linha 303-326  
**Tentativas:** 3 retries  
**Delays:** 1s + 2s + 3s = **6 segundos totais**

```dart
if (added.trim().isEmpty && acc.isNotEmpty) {
  // 🚀 v7.6.118: Retries rápidos (1s/2s/3s ao invés de 3s/6s/9s)
  for (int retry = 1; retry <= 3; retry++) {
    final retryDelay = retry; // 1s, 2s, 3s
    await Future.delayed(Duration(seconds: retryDelay));
    
    added = await _retryOnRateLimit(
      () => _generateBlockContent(
        contextForRetry,
        targetForBlock,
        phase,
        config,
        persistentTracker,
        block,
        totalBlocks,
        worldState: worldState,
      ),
    );
    
    if (added.trim().isNotEmpty) break;
  }
}
```

### 2.2 Cenário B: Bloco Vazio Após Validações

**Localização:** Linha 568-598  
**Tentativas:** 3 retries  
**Delays:** 1s + 2s + 3s = **6 segundos totais**

```dart
if (added.trim().isEmpty) {
  int retryCount = 0;
  // 🚀 v7.6.118: Delays reduzidos para 1s/2s/3s (era 2s/4s/6s)
  while (retryCount < 3 && added.trim().isEmpty) {
    retryCount++;
    await Future.delayed(Duration(seconds: retryCount));
    added = await _retryOnRateLimit(...);
    
    if (added.trim().isNotEmpty) {
      final hasConflict = _characterValidation.validateUniqueNames(...);
      final trackerValid = _characterValidation.updateTrackerFromContextSnippet(...);
      
      if (!hasConflict && trackerValid) {
        break;
      }
      added = '';
    }
  }
}
```

### 2.3 Cenário C: Mudança de Nome Detectada

**Localização:** Linha 457-478  
**Tentativas:** 1 retry (otimizado!)  
**Delays:** Nenhum (regenera imediatamente)

```dart
if (protagonistChanged || characterNameChanges.isNotEmpty) {
  String? regenerated;
  // 🚀 v7.6.118: Apenas 1 retry (era 3) - a maioria resolve na primeira
  for (int i = 1; i <= 1; i++) {
    regenerated = await _generateBlockContent(
      acc,
      targetForBlock,
      phase,
      config,
      persistentTracker,
      block,
      totalBlocks,
      avoidRepetition: true,
      worldState: worldState,
    );
    if (regenerated.trim().isNotEmpty &&
        !_characterValidation.detectProtagonistNameChange(...)) {
      break;
    }
  }
  if (regenerated != null && regenerated.trim().isNotEmpty)
    added = regenerated;
}
```

### 2.4 Cenário D: Rate Limit 429 (Too Many Requests)

**Localização:** Linha 862-865  
**Tentativas:** Até 3  
**Delays:** 5s + 10s + 15s = **30 segundos totais**

```dart
if (errorStr.contains('429') && attempt < maxRetries - 1) {
  await Future.delayed(Duration(seconds: (attempt + 1) * 5));
  continue;
}
```

### 2.5 Cenário E: 503 Service Unavailable

**Localização:** Linha 848-858  
**Tentativas:** Até 3  
**Delays:** Exponencial até 90s  
**Cálculo:** `10s × 2^attempt` (máximo 90s)

```dart
if (errorStr.contains('503') ||
    errorStr.contains('service unavailable')) {
  _consecutive503Errors++;
  _consecutiveSuccesses = 0;
  if (attempt < maxRetries - 1) {
    final delay = Duration(seconds: min(10 * (1 << attempt), 90));
    await Future.delayed(delay);
    continue;
  }
  throw Exception('Servidor Gemini indisponível após múltiplas tentativas.');
}
```

**Progressão de delays 503:**
- Tentativa 1: 10 segundos
- Tentativa 2: 20 segundos
- Tentativa 3: 40 segundos
- Tentativa 4+: 90 segundos

### 2.6 Cenário F: Timeout/Connection Errors

**Localização:** Linha 867-870  
**Tentativas:** Até 3  
**Delays:** 1s + 2s + 3s = **6 segundos totais**

```dart
if ((errorStr.contains('timeout') || errorStr.contains('connection')) &&
    attempt < maxRetries - 1) {
  await Future.delayed(Duration(seconds: attempt + 1));
  continue;
}
```

### ⚠️ **PROBLEMA IDENTIFICADO #2**

**Rejeições frequentes multiplicam o tempo:**

| Cenário | Blocos Afetados | Tempo Extra por Bloco | Tempo Total (30 blocos) |
|---------|-----------------|----------------------|------------------------|
| **20% blocos vazios** | 6 blocos | 6s | +36 segundos |
| **50% blocos vazios** | 15 blocos | 6s | +90 segundos |
| **10 erros 503** | 10 blocos | 10-40s | +100-400 segundos |
| **5 erros 429** | 5 blocos | 15-30s | +75-150 segundos |

---

## 3. ANÁLISE DE PAYLOAD (Contexto)

### ✅ **BOA NOTÍCIA: Janela Deslizante Implementada**

**Localização:** Linhas 907-912 em `_generateBlockContent()`

```dart
final maxContextBlocks = ContextBuilder.getMaxContextBlocks(c.language);
final contextoPrevio = previous.isEmpty
    ? ''
    : ContextBuilder.buildLimitedContext(
        previous,
        blockNumber,
        maxContextBlocks, // 🎯 LIMITA O CONTEXTO!
        TextUtils.countWords,
      );
```

### 3.1 Como Funciona

**NÃO envia `fullScript` inteiro para a API!**

1. **`getMaxContextBlocks(language)`**: Define quantos blocos anteriores incluir
2. **`buildLimitedContext()`**: Extrai apenas os últimos N blocos
3. **Benefício**: Prompts menores = respostas mais rápidas + menor custo

### 3.2 Exemplo Prático

```
Bloco 1: 800 palavras → Contexto: 0 palavras
Bloco 2: 850 palavras → Contexto: 800 palavras (bloco 1)
Bloco 3: 900 palavras → Contexto: 1650 palavras (blocos 1-2)
Bloco 10: 1000 palavras → Contexto: 5000 palavras (blocos 7-9)
Bloco 30: 1200 palavras → Contexto: 5000 palavras (blocos 27-29)
```

**Tamanho do contexto estabiliza após ~10 blocos!**

### ✅ **INOCENTE**

O payload/contexto **NÃO é o gargalo**. A implementação já está otimizada.

---

## 4. LOGS DE TEMPO IMPLEMENTADOS (v7.6.125)

### 4.1 Cronometragem Adicionada

**Commit:** v7.6.125  
**Objetivo:** Identificar exatamente onde o tempo é gasto em cada bloco

### 4.2 Pontos de Medição

| # | Localização | Métrica | Linha |
|---|-------------|---------|-------|
| 1 | Início do bloco | Timestamp inicial | 233-237 |
| 2 | Delay adaptativo | Tempo de espera | 278-282 |
| 3 | Geração inicial | Tempo de chamada API | 288-305 |
| 4 | Retry por bloco vazio | Tempo de retry + delay | 318-322 |
| 5 | Extração de nomes | Tempo de processamento | 494-519 |
| 6 | Regeneração por nome | Tempo de regeneração | 462-465 |
| 7 | Fim do bloco | Tempo total do bloco | 612-620 |
| 8 | Chamada API interna | Tempo de resposta Gemini | 1043-1065 |

### 4.3 Exemplo de Saída no Console

```
🔵 ═══════════════════════════════════════════
⏱️ [Bloco 1/30] INÍCIO
⏱️ [Bloco 1] 🎬 Gerando conteúdo (meta: 800 palavras)...
⏱️ [Bloco 1] Iniciando chamada API...
   📦 Prompt: 2847 chars
⏱️ [Bloco 1] API respondeu em 4523ms (4s)
   📝 Resposta: 1234 chars
⏱️ [Bloco 1] ✅ Geração inicial: 5s (1234 chars)
⏱️ [Bloco 1] 🔍 Extraindo nomes...
⏱️ [Bloco 1] ✅ Extração de nomes: 12ms (3 nomes)
⏱️ [Bloco 1] ⏹️ CONCLUÍDO em 6s (6234ms)
   📊 Palavras acumuladas: 245
🔵 ═══════════════════════════════════════════

🔵 ═══════════════════════════════════════════
⏱️ [Bloco 2/30] INÍCIO
⏱️ [Bloco 2] ⚠️ Aplicando delay adaptativo: 250ms (erros 503: 0)
⏱️ [Bloco 2] 🎬 Gerando conteúdo (meta: 850 palavras)...
⏱️ [Bloco 2] Iniciando chamada API...
⏱️ [Bloco 2] API respondeu em 18234ms (18s) ⬅️ LENTO!
⏱️ [Bloco 2] ⚠️ VAZIO - Iniciando ciclo de retries...
⏱️ [Bloco 2] 🔄 Retry 1/3 - Aguardando 1s...
⏱️ [Bloco 2] Iniciando chamada API...
⏱️ [Bloco 2] API respondeu em 5421ms (5s)
⏱️ [Bloco 2] ✅ Geração inicial: 24s (987 chars)
⏱️ [Bloco 2] 🔍 Extraindo nomes...
⏱️ [Bloco 2] ✅ Extração de nomes: 8ms (2 nomes)
⏱️ [Bloco 2] ⏹️ CONCLUÍDO em 25s (25234ms)
   📊 Palavras acumuladas: 490
🔵 ═══════════════════════════════════════════

🔵 ═══════════════════════════════════════════
⏱️ [Bloco 3/30] INÍCIO
⏱️ [Bloco 3] 🎬 Gerando conteúdo (meta: 900 palavras)...
⏱️ [Bloco 3] Iniciando chamada API...
⏱️ [Bloco 3] API respondeu em 32145ms (32s) ⬅️ MUITO LENTO!
⏱️ [Bloco 3] ✅ Geração inicial: 33s (2341 chars)
⏱️ [Bloco 3] 🔍 Extraindo nomes (isolate)...
⏱️ [Bloco 3] ✅ Extração de nomes: 156ms (5 nomes)
⏱️ [Bloco 3] ⚠️ Mudança de nome detectada - Regenerando...
⏱️ [Bloco 3] Iniciando chamada API...
⏱️ [Bloco 3] API respondeu em 28734ms (28s)
⏱️ [Bloco 3] ⏹️ CONCLUÍDO em 62s (62145ms) ⬅️ MAIS DE 1 MINUTO!
   📊 Palavras acumuladas: 1290
🔵 ═══════════════════════════════════════════
```

### 4.4 Código dos Logs

**Início do bloco:**
```dart
final blockStartTime = DateTime.now();
if (kDebugMode) {
  debugPrint('\n🔵 ═══════════════════════════════════════════');
  debugPrint('⏱️ [Bloco $block/$totalBlocks] INÍCIO');
}
```

**API (já existia, linha 1043):**
```dart
final apiStartTime = DateTime.now();
if (kDebugMode) {
  debugPrint('⏱️ [Bloco $blockNumber] Iniciando chamada API...');
  debugPrint('   📦 Prompt: ${prompt.length} chars');
}

final data = await _llmClient.generateText(...);

final apiDuration = apiEndTime.difference(apiStartTime);
if (kDebugMode) {
  debugPrint('⏱️ [Bloco $blockNumber] API respondeu em ${apiDuration.inMilliseconds}ms (${apiDuration.inSeconds}s)');
  debugPrint('   📝 Resposta: ${data.length} chars');
}
```

**Fim do bloco:**
```dart
final blockTotalTime = DateTime.now().difference(blockStartTime);
if (kDebugMode) {
  debugPrint('⏱️ [Bloco $block] ⏹️ CONCLUÍDO em ${blockTotalTime.inSeconds}s (${blockTotalTime.inMilliseconds}ms)');
  debugPrint('   📊 Palavras acumuladas: ${TextUtils.countWords(acc)}');
  debugPrint('🔵 ═══════════════════════════════════════════\n');
}
```

---

## 5. SUSPEITOS DO GARGALO DE 20 MINUTOS

### 🔴 SUSPEITO #1: API Gemini Lenta (PRINCIPAL)

**Probabilidade:** 🔴 **ALTA (80%)**

**Sintomas:**
- Cada bloco esperando 15-30 segundos pela resposta da API
- Tempo cresce com tamanho do prompt (contexto maior = resposta mais lenta)

**Cálculo:**
```
Cenário Pessimista:
30 blocos × 25s por bloco = 12,5 minutos APENAS na API
+ Retries/validações = 15-20 minutos total ✅ CORRESPONDE!
```

**Como confirmar nos logs:**
```
⏱️ [Bloco X] API respondeu em XXXXXms
```
Se a maioria dos blocos mostrar **15.000ms+**, este é o gargalo!

**Soluções possíveis:**
1. Reduzir tamanho do prompt (já otimizado com janela deslizante)
2. Usar modelo mais rápido (Flash ao invés de Pro)
3. Reduzir `maxTokens` na resposta
4. Fazer pré-processamento do contexto (resumir blocos anteriores)

### 🟡 SUSPEITO #2: Erros 503 Frequentes

**Probabilidade:** 🟡 **MÉDIA (40%)**

**Sintomas:**
- Servidor Gemini sobrecarregado retornando 503
- Delays exponenciais: 10s → 20s → 40s → 90s

**Cálculo:**
```
10 erros 503 em 30 blocos:
- 5 blocos com 10s delay = 50s
- 3 blocos com 20s delay = 60s
- 2 blocos com 40s delay = 80s
Total: +190 segundos (3 minutos extras)
```

**Como confirmar nos logs:**
```
⏱️ [Bloco X] ⚠️ Aplicando delay adaptativo: XXXXms (erros 503: Y)
```
Se `Y > 1` frequentemente, este é um gargalo secundário!

**Soluções possíveis:**
1. Trocar de API key (pode estar em rate limit)
2. Usar região diferente do Gemini
3. Implementar circuit breaker (parar após X erros seguidos)
4. Reduzir paralelismo (se houver)

### 🟡 SUSPEITO #3: Validações Rejeitando Blocos

**Probabilidade:** 🟡 **MÉDIA (30%)**

**Sintomas:**
- Blocos vazios após geração inicial
- Mudanças de nome detectadas
- Rejeições por qualidade/repetição

**Cálculo:**
```
50% dos blocos rejeitados (15 blocos):
- 15 blocos × 6s de retry = 90 segundos
- 15 blocos × 1 chamada API extra (20s) = 300 segundos
Total: +390 segundos (6,5 minutos extras)
```

**Como confirmar nos logs:**
```
⏱️ [Bloco X] ⚠️ VAZIO - Iniciando ciclo de retries...
⏱️ [Bloco X] ⚠️ Mudança de nome detectada - Regenerando...
```
Se aparecer em >30% dos blocos, este é um gargalo!

**Soluções possíveis:**
1. Relaxar validações (aceitar mais variação)
2. Melhorar prompt para reduzir rejeições
3. Reduzir número de retries de 3 para 2
4. Implementar cache de blocos válidos

### 🟢 SUSPEITO #4: Processamento Local Lento

**Probabilidade:** 🟢 **BAIXA (5%)**

**Sintomas:**
- Extração de nomes demorando muito
- Validações complexas com regex
- WorldState update lento

**Cálculo:**
```
30 blocos × 200ms de processamento = 6 segundos total
```
**NEGLIGÍVEL** comparado aos outros gargalos.

**Como confirmar nos logs:**
```
⏱️ [Bloco X] ✅ Extração de nomes: XXXXms
⏱️ [Bloco X] WorldState update: XXXXms
```
Se passar de **1000ms** frequentemente, pode ser gargalo.

---

## 6. PRÓXIMOS PASSOS RECOMENDADOS

### 6.1 Teste de Diagnóstico

**Execute uma geração CURTA:**

1. **Configuração sugerida:**
   - Quantidade: **1500 palavras** (5-10 blocos)
   - Modo: **Debug** (não Release)
   - Tema: Simples (ex: "História de superação")

2. **Durante a geração:**
   - Abra o **Debug Console** no VS Code
   - Copie TODOS os logs que aparecerem

3. **Após a geração:**
   - Envie os logs completos
   - Indique o tempo total gasto

### 6.2 Análise dos Logs

**Com os logs, identificaremos:**

✅ **Tempo médio de resposta da API:**
```
Buscar: "API respondeu em"
Calcular média dos valores em ms
```

✅ **Frequência de erros 503/429:**
```
Buscar: "erros 503:" ou "429"
Contar ocorrências
```

✅ **Taxa de rejeição:**
```
Buscar: "VAZIO" ou "Mudança de nome"
Dividir por total de blocos
```

✅ **Tempo por bloco:**
```
Buscar: "CONCLUÍDO em"
Comparar com tempo de API
```

### 6.3 Soluções Baseadas em Diagnóstico

**Se API > 15s em média:**
- ✂️ Reduzir `maxContextBlocks` (menos contexto)
- ⚡ Trocar para Gemini Flash (mais rápido)
- 📉 Reduzir `maxTokens` por bloco

**Se erros 503 > 3 ocorrências:**
- 🔑 Trocar API key
- ⏸️ Aumentar delays preventivos
- 🔄 Implementar fallback para outro modelo

**Se rejeições > 30%:**
- 🎯 Melhorar instruções no prompt
- 📏 Relaxar validações (tolerância maior)
- 🔢 Reduzir retries de 3 para 2

**Se processamento local > 500ms:**
- 💾 Implementar cache de validações
- 🚀 Otimizar regex de extração de nomes
- 🧵 Usar mais isolates

### 6.4 Comando para Executar

**Windows (PowerShell):**
```powershell
cd 'c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador'
flutter run -d windows
```

**Linux/Mac (Terminal):**
```bash
cd ~/Desktop/Flutter\ Gerador/flutter_gerador
flutter run -d windows # ou linux/macos
```

**Monitorar logs:**
- No VS Code: Aba "Debug Console"
- No terminal: Saída padrão

### 6.5 Checklist de Diagnóstico

- [ ] Executar geração curta (1500 palavras)
- [ ] Copiar logs completos do Debug Console
- [ ] Anotar tempo total de geração
- [ ] Identificar padrões nos logs:
  - [ ] Tempo médio de API
  - [ ] Quantidade de erros 503
  - [ ] Taxa de rejeições
  - [ ] Tempo de processamento local
- [ ] Compartilhar resultados para análise final

---

## 📈 TABELA RESUMO: TEMPOS ESPERADOS

| Componente | Tempo Normal | Tempo com Problema | Ação |
|------------|--------------|-------------------|------|
| **API Gemini** | 3-8s | 15-30s | Otimizar prompt/trocar modelo |
| **Delay adaptativo** | 250-1000ms | 5-15s | Investigar erros 503 |
| **Retry por vazio** | 0s (sem retry) | 6-18s | Melhorar prompt |
| **Extração nomes** | 10-50ms | 500ms+ | Otimizar regex/cache |
| **WorldState** | 50-200ms | 1s+ | Simplificar updates |
| **Bloco completo** | 5-12s | 30-60s+ | Múltiplos gargalos |

**Meta ideal:** 8-10 segundos por bloco = **4-5 minutos para 30 blocos**

---

## 📝 NOTAS FINAIS

### Versão do Diagnóstico
- **v7.6.125** - Implementação completa de cronometragem
- **Data:** 09/12/2025
- **Autor:** GitHub Copilot (Claude Sonnet 4.5)

### Arquivos Modificados
- `lib/data/services/gemini_service.dart` (linhas 233-620, 1043-1065)

### Tempo de Compilação
- **Debug mode:** ~15s
- **Release mode:** ~40s

### Dependências Monitoradas
- `_llmClient.generateText()` - Chamada API Gemini
- `ContextBuilder.buildLimitedContext()` - Janela deslizante
- `NameValidator.extractNamesFromText()` - Extração de nomes
- `_characterValidation.*` - Validações de personagens
- `_worldStateManager.updateFromGeneratedBlock()` - WorldState

---

## 🎯 CONCLUSÃO PRELIMINAR

**Hipótese principal:** O gargalo de 20 minutos é causado principalmente pela **API Gemini respondendo lentamente** (15-30s por bloco), agravado por **retries devido a validações** e possíveis **erros 503 esporádicos**.

**Prioridade de investigação:**
1. 🔴 **Tempo de resposta da API** (mais provável)
2. 🟡 **Taxa de rejeição por validação** (segundo mais provável)
3. 🟡 **Erros 503 do servidor Gemini** (possível)
4. 🟢 **Processamento local** (improvável)

**Próximo passo crítico:** Executar teste de diagnóstico e analisar logs reais.

---

**Última atualização:** 09/12/2025 - v7.6.125
