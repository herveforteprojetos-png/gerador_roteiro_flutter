# 📊 ANÁLISE DO GEMINI_SERVICE.DART - Top Ofensores

> **Data:** 04 de Dezembro de 2025  
> **Arquivo:** `lib/data/services/gemini_service.dart`  
> **Total de linhas:** 8.240

---

## 🏆 1. TOP 5 OFENSORES (Métodos/Classes que Ocupam Mais Espaço)

| # | Elemento | Linhas | % do Total | Descrição |
|---|----------|--------|------------|-----------|
| **1** | `_CharacterTracker` + classes auxiliares | ~625 | 7.6% | Classe interna (linhas 7614-8239) + `_CharacterNote` + `_CharacterHistory` |
| **2** | `_getPerspectiveInstruction()` | ~380 | 4.6% | Templates de perspectiva narrativa (linhas 5237-5617) |
| **3** | `_getNarrativeStyleGuidance()` | ~385 | 4.7% | 6 estilos narrativos gigantes (linhas 2620-3005) |
| **4** | `_validateNameReuse()` + `_extractRoleForName()` | ~400 | 4.9% | Validação de nomes com RegExps (linhas 4419-4820) |
| **5** | `_nameStopwords` (Set<String>) | ~200 | 2.4% | Lista de stopwords gigante (linhas 5022-5222) |

**Total dos Top 5: ~1.990 linhas (24% do arquivo)**

---

## 🔍 2. VERIFICAÇÃO DE CÓDIGO DUPLICADO/NÃO USADO

### ✅ CÓDIGO LEGADO REMOVIDO CORRETAMENTE
- ❌ `_makeApiRequest` - **REMOVIDO** (apenas comentário de migração na linha 6288)
- ❌ `_WorldState` / `_WorldCharacter` - **REMOVIDOS** (migrados para `world_state_manager.dart`)

### ⚠️ POSSÍVEIS DUPLICAÇÕES DETECTADAS

| Código | Local | Observação |
|--------|-------|------------|
| `_normalizeRole()` | Linhas 3958 E 7883 | **DUPLICADO!** Existe no GeminiService E no _CharacterTracker |
| Templates de perspectiva | `_getPerspectiveInstruction()` | Similar ao `ScriptPromptBuilder.getPerspectiveInstruction()` |
| Templates de estilo | `_getNarrativeStyleGuidance()` | ~385 linhas de strings literais |

---

## 📦 3. CLASSES INTERNAS

### 3.1 `_CharacterTracker` (linhas 7734-8239)
**Tamanho: ~505 linhas**

```
_CharacterTracker
├── _confirmedNames (Set<String>)
├── _characterRoles (Map<String, String>)
├── _roleToName (Map<String, String>)
├── _characterHistories (Map<String, _CharacterHistory>)
├── _detectedProtagonistName (String?)
├── _characterResolution (Map<String, bool>)
│
├── addName() (~120 linhas) ⚠️ MUITO GRANDE
├── _normalizeRole() (~55 linhas) ⚠️ DUPLICADO
├── addNoteToCharacter()
├── getCharacterMapping() (~50 linhas)
├── detectResolutionInText() (~100 linhas)
├── getUnresolvedCharacters()
└── getClosureRate()
```

### 3.2 `_CharacterHistory` (linhas 7627-7730)
**Tamanho: ~103 linhas**

### 3.3 `_CharacterNote` (linhas 7614-7625)
**Tamanho: ~11 linhas**

---

## 📝 4. STRING TEMPLATES GIGANTES

### 4.1 `_getNarrativeStyleGuidance()` (385 linhas)
**Ainda está no arquivo!** Contém 6 estilos narrativos com templates de ~50-70 linhas cada:
- `reflexivo_memorias` (~60 linhas)
- `epico_periodo` (~75 linhas)
- `educativo_curioso` (~70 linhas)
- `acao_rapida` (~65 linhas)
- `lirico_poetico` (~70 linhas)
- `ficcional_livre` (~45 linhas)

### 4.2 `_getPerspectiveInstruction()` (380 linhas)
**Ainda está no arquivo!** Templates de perspectiva:
- Primeira pessoa (mulher idosa/madura/jovem)
- Primeira pessoa (homem idoso/maduro/jovem)
- Terceira pessoa

### 4.3 `_nameStopwords` (200 linhas)
**Ainda está no arquivo!** Set gigante com ~200+ palavras de stopwords.

### 4.4 Templates de CTA (`_buildAdvancedCtaPrompt`)
**Ainda está no arquivo!** Templates de Call-to-Action (linhas 7022-7500+)

---

## ⚠️ 5. PROBLEMAS IDENTIFICADOS

### 5.1 Duplicação de `_normalizeRole()`
```dart
// LINHA 3958 - No GeminiService
String _normalizeRole(String role) { ... }

// LINHA 7883 - No _CharacterTracker
String _normalizeRole(String role) { ... }
```
**Ação:** Remover um deles ou extrair para utility

### 5.2 Templates Não Migrados
Os seguintes templates deveriam estar em módulos separados:
- `_getNarrativeStyleGuidance()` → `NarrativeStyleManager`
- `_getPerspectiveInstruction()` → `ScriptPromptBuilder` (parcialmente duplicado)
- `_nameStopwords` → `NameValidator` ou constantes

### 5.3 _CharacterTracker Muito Grande
A classe `_CharacterTracker` com ~505 linhas deveria ser extraída para um módulo próprio:
```
lib/data/services/scripting/character_tracker.dart
```

---

## 📋 6. RECOMENDAÇÕES DE EXTRAÇÃO

| Prioridade | Elemento | Linhas | Destino Sugerido |
|------------|----------|--------|------------------|
| **ALTA** | `_CharacterTracker` + auxiliares | ~625 | `character_tracker.dart` |
| **ALTA** | `_getNarrativeStyleGuidance()` | ~385 | `narrative_style_manager.dart` |
| **MÉDIA** | `_getPerspectiveInstruction()` | ~380 | Migrar para `ScriptPromptBuilder` |
| **MÉDIA** | `_nameStopwords` | ~200 | `name_constants.dart` |
| **MÉDIA** | `_validateNameReuse()` e relacionados | ~400 | `name_validator.dart` |
| **BAIXA** | Templates de CTA | ~400 | `cta_builder.dart` |

**Potencial de redução total: ~2.390 linhas (29% do arquivo)**

---

## 📊 7. RESUMO EXECUTIVO

```
┌─────────────────────────────────────────────────────────────┐
│ SITUAÇÃO ATUAL                                              │
├─────────────────────────────────────────────────────────────┤
│ Linhas totais: 8.240                                        │
│ Classes internas: 3 (_CharacterTracker, _CharacterHistory,  │
│                      _CharacterNote)                        │
│ Templates de string gigantes: 4 (~1.365 linhas)             │
│ Código duplicado: 1 método (_normalizeRole)                 │
│ Código legado não usado: NENHUM (✅ limpo)                  │
├─────────────────────────────────────────────────────────────┤
│ POTENCIAL DE REDUÇÃO                                        │
├─────────────────────────────────────────────────────────────┤
│ Se extrair _CharacterTracker: -625 linhas                   │
│ Se extrair estilos narrativos: -385 linhas                  │
│ Se migrar perspectivas: -380 linhas                         │
│ Se extrair validadores de nome: -400 linhas                 │
│ Se extrair stopwords: -200 linhas                           │
├─────────────────────────────────────────────────────────────┤
│ TOTAL POTENCIAL: -1.990 a -2.390 linhas                     │
│ RESULTADO ESPERADO: ~5.850 a 6.250 linhas                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 8. PRÓXIMO PASSO RECOMENDADO

**Extrair `_CharacterTracker`** é a ação de maior impacto:
- Remove 625 linhas de uma só vez
- É uma classe autocontida
- Fácil de testar isoladamente
- Não tem dependências circulares

```dart
// Criar: lib/data/services/scripting/character_tracker.dart
class CharacterTracker { ... }
class CharacterHistory { ... }
class CharacterNote { ... }
```

---

*Análise gerada em 04/12/2025*
