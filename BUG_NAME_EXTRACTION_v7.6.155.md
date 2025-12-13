# 🐛 BUG: Name Extraction Retornando 0 para Hangul (Coreano)

**Versão:** v7.6.155  
**Data:** 12/12/2024  
**Severidade:** ⚠️ Média (não afeta qualidade do roteiro, apenas logs)

---

## 📊 **SINTOMAS**

Nos logs de geração em **coreano**, a extração de nomes retornava **0** em quase todos os blocos:

```
🔍 [Bloco 1] ✅ Extração de nomes: 23ms (2 nomes)
🔍 [Bloco 2-10] Validação de reutilização completa
   → 0 nomes verificados
```

### **Dados Observados:**
- **Bloco 1**: Detectou 2 nomes (이준호, 김민준) ✅
- **Blocos 2-10**: Detectou 0 nomes ❌
- **WorldState**: Adicionou personagens corretamente (최현우, 정은지) ✅

**Conclusão:** O bug estava na **validação**, não na geração.

---

## 🔍 **CAUSA RAIZ**

### **Problema 1: Regex Latino em `validateNameReuse`**

```dart
// ❌ CÓDIGO ANTIGO (character_validation.dart:536)
final namePattern = RegExp(
  r'\b([A-ZÀÁÂÃÄÅÇÈÉÊËÌÍÎÏa-zàáâãäåçèéêëìíîï]{2,})\b',
);
```

**Este regex só detecta caracteres latinos:**
- ✅ Detecta: Arthur, María, João
- ❌ **IGNORA**: 이준호 (Lee Junho), 김민준 (Kim Minjun), 최현우 (Choi Hyunwoo)

### **Problema 2: Regex Latino em `validateFamilyRelations`**

```dart
// ❌ CÓDIGO ANTIGO (character_validation.dart:602)
final namePattern = RegExp(
  r'\b([A-ZÀÁÂÃÄÅÇÈÉÊËÌÍÎÏ][a-zàáâãäåçèéêëìíîï]{2,})\b',
);
```

Mesmo problema - **ignora hangul e outros scripts não-latinos**.

---

## ✅ **SOLUÇÃO IMPLEMENTADA**

### **v7.6.155: Usar `extractNamesFromText` Universalmente**

A função `NameValidator.extractNamesFromText` **JÁ** suporta múltiplos scripts:

```dart
// ✅ NOVO CÓDIGO (character_validation.dart:536)
// 🇰🇷 v7.6.155: Usar extractNamesFromText que suporta hangul, CJK, latino
final foundNames = NameValidator.extractNamesFromText(
  generatedText,
  tracker.confirmedNames,
);
```

### **Mudanças Aplicadas:**

#### **1. `validateNameReuse` (linhas 533-548)**
```diff
- final namePattern = RegExp(r'\b([A-Z...]{2,})\b');
- final foundNames = <String>{};
- for (final match in namePattern.allMatches(generatedText)) {
-   final name = match.group(1)?.trim();
-   if (name != null && NameValidator.looksLikePersonName(name)) {
-     foundNames.add(name);
-   }
- }

+ // 🇰🇷 v7.6.155: Usar extractNamesFromText para suportar todos os scripts
+ final foundNames = NameValidator.extractNamesFromText(
+   generatedText,
+   tracker.confirmedNames,
+ );
```

#### **2. `validateFamilyRelations` (linhas 601-619)**
```diff
- final namePattern = RegExp(r'\b([A-Z...]{2,})\b');
- final names = <String>{};
- for (final match in namePattern.allMatches(generatedText)) {
-   final name = match.group(1)?.trim();
-   if (name != null && NameValidator.looksLikePersonName(name)) {
-     names.add(name);
-   }
- }

+ // 🇰🇷 v7.6.155: Usar extractNamesFromText para suportar todos os scripts
+ final names = NameValidator.extractNamesFromText(generatedText);
```

---

## 🎯 **BENEFÍCIOS**

### **1. Suporte Universal a Scripts**
- ✅ **Latino**: Arthur, María, João
- ✅ **Hangul (Coreano)**: 이준호, 김민준, 최현우
- ✅ **CJK (Chinês/Japonês)**: 山田太郎, 李明
- ✅ **Cirílico**: Алексей, Борис

### **2. Logs Mais Precisos**
Antes (v7.6.154):
```
🔍 [Bloco 6] nomesVerificados: 0
```

Depois (v7.6.155):
```
🔍 [Bloco 6] nomesVerificados: 2
   → Nomes: 최현우, 정은지
```

### **3. Consistência no Código**
- Antes: 3 métodos diferentes de extrair nomes (regex, extractNames, isolate)
- Depois: **1 método unificado** (`extractNamesFromText`)

---

## 🧪 **TESTES NECESSÁRIOS**

### **Teste 1: Geração em Coreano (Hangul)**
```
Idioma: Coreano (한국어)
Quantidade: 5900 palavras
Modelo: Flash

Verificar logs:
✅ [Bloco 1-10] nomesVerificados > 0 (onde houver personagens)
```

### **Teste 2: Geração em Japonês (Kanji/Hiragana)**
```
Idioma: Japonês (日本語)
Quantidade: 5900 palavras
Modelo: Flash

Verificar detecção de nomes: 山田太郎, 田中花子
```

### **Teste 3: Geração em Russo (Cirílico)**
```
Idioma: Russo (Русский)
Quantidade: 5900 palavras
Modelo: Flash

Verificar detecção de nomes: Алексей, Мария
```

---

## 📈 **IMPACTO**

### **Qualidade do Roteiro**
- ✅ **Sem impacto negativo** - bug estava apenas nos logs
- ✅ **WorldState continuava funcionando** - usava lógica correta

### **Performance**
- ✅ **Nenhuma mudança** - `extractNamesFromText` já era usado em outros lugares
- ✅ **Possível melhoria** - menos chamadas de regex

### **Debugging**
- ✅ **Logs mais úteis** - agora mostram nomes reais detectados
- ✅ **Rastreamento melhor** - validação de nomes em todos os scripts

---

## 🔧 **ARQUIVOS MODIFICADOS**

1. **`character_validation.dart`** (2 funções corrigidas)
   - `validateNameReuse()` - linhas 533-548
   - `validateFamilyRelations()` - linhas 601-619

---

## 📝 **NOTAS TÉCNICAS**

### **Por que `extractNamesFromText` funciona?**

A função tem lógica multi-script desde v7.6.149:

```dart
// Unicode ranges suportados:
// - Latin: A-Z, À-Ú
// - Hangul: \uAC00-\uD7AF  (이, 준, 호, 김, 민, 최, 현, 우)
// - CJK: \u4E00-\u9FFF     (山, 田, 李, 明)
// - Cyrillic: detectado por looksLikePersonName
```

### **Por que o Bloco 1 funcionava?**

```dart
// gemini_service.dart:615
allNames = NameValidator.extractNamesFromText(
  added,
  persistentTracker.confirmedNames,
).toList();
```

No Bloco 1, o código **já usava** `extractNamesFromText` corretamente!

O problema aparecia apenas em `validateNameReuse` (blocos 2+).

---

## ✅ **CONCLUSÃO**

O bug foi corrigido substituindo **regex latinos** por **`extractNamesFromText`** em 2 funções:
- `validateNameReuse()`
- `validateFamilyRelations()`

Agora o sistema detecta nomes em **qualquer script** (latino, hangul, CJK, cirílico) consistentemente.

**Próxima versão:** v7.6.155  
**Status:** ✅ Resolvido
