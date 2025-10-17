# 🔍 DIAGNÓSTICO: Western não está usando nomes corretos

**Data**: 17/10/2025  
**Problema relatado**: Quando seleciona "Western", os nomes não são do tema Western

---

## ✅ **O QUE ESTÁ CORRETO**

### 1️⃣ **Banco de dados de nomes Western EXISTE e está completo**

```dart
// Localização: lib/data/services/name_generator_service.dart
static const Map<String, Map<String, List<String>>> _westernNames = {
  'masculino': {
    'todos': [
      'Jedediah', 'Ezekiel', 'Josiah', 'Caleb', 'Silas', 'Amos', 
      'Wyatt', 'Clint', 'Colt', 'Buck', 'Tex', 'Jake', 'Luke', 
      'Cole', 'Wade', 'Rex', 'Hank', 'Clay', 'Beau', 'Jeb', ...
    ]
  },
  'feminino': {
    'todos': [
      'Clementine', 'Evangeline', 'Prudence', 'Temperance', 
      'Belle', 'Rose', 'Sage', 'Pearl', 'Ruby', 'Opal', ...
    ]
  }
}
```

**STATUS**: ✅ **PERFEITO** - 30+ nomes masculinos e 30+ nomes femininos

---

### 2️⃣ **Função de geração está correta**

```dart
// Localização: lib/data/services/name_generator_service.dart
static String getNameListForPrompt({
  required String language,
  String? genre,
  int maxNamesPerCategory = 30,
}) {
  final buffer = StringBuffer();
  
  // Se for western, usar apenas nomes temáticos
  if (genre == 'western') {
    buffer.writeln('NOMES WESTERN (use APENAS estes para histórias de faroeste):');
    
    if (_westernNames.containsKey('masculino')) {
      final maleNames = _westernNames['masculino']!['todos']!
          .take(maxNamesPerCategory).toList();
      buffer.writeln('  Masculinos: ${maleNames.join(', ')}');
    }
    
    if (_westernNames.containsKey('feminino')) {
      final femaleNames = _westernNames['feminino']!['todos']!
          .take(maxNamesPerCategory).toList();
      buffer.writeln('  Femininos: ${femaleNames.join(', ')}');
    }
    
    return buffer.toString();
  }
  
  // ... resto do código para outros idiomas
}
```

**STATUS**: ✅ **PERFEITA** - Lógica está correta

---

### 3️⃣ **Função É CHAMADA no prompt do Gemini**

```dart
// Localização: lib/data/services/gemini_service.dart (linha ~3243)
final nameList = NameGeneratorService.getNameListForPrompt(
  language: c.language,
  genre: c.genre, // ← Aqui passa o genre
  maxNamesPerCategory: 30,
);

// E depois é incluído no prompt:
final prompt = '...\n'
    '$nameList\n'  // ← Lista de nomes inserida aqui
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '🚨 ATENÇÃO: A lista de nomes acima é sua ÚNICA fonte de nomes!\n'
    ...
```

**STATUS**: ✅ **CORRETO** - Lista de nomes É enviada para o Gemini

---

## ❓ **ONDE PODE ESTAR O PROBLEMA**

### **Hipótese 1: `genre` não está sendo definido na UI**

```dart
// VERIFICAR: lib/presentation/widgets/layout/sidebar_panel.dart
String? selectedGenre; // ← Esta variável está sendo populada?

// Quando gera roteiro:
await generationNotifier.generateScript(
  GenerationConfig(
    ...
    genre: selectedGenre, // ← Está chegando 'western' aqui?
  )
);
```

**O QUE VERIFICAR**:
1. Dropdown de "Tipo Temático" está funcional?
2. Quando seleciona "🤠 Western/Faroeste", a variável `selectedGenre` recebe `'western'`?
3. Esse valor está sendo passado para `GenerationConfig`?

---

### **Hipótese 2: Config não está passando `genre` corretamente**

```dart
// VERIFICAR: lib/data/models/script_config.dart
ScriptConfig.fromGenerationConfig(GenerationConfig config)
    : ...
      genre: config.genre, // ← Está pegando o valor?
```

---

### **Hipótese 3: Gemini está ignorando a lista**

Mesmo recebendo a lista correta de nomes Western, o Gemini pode estar:
- Inventando nomes aleatórios (problema de obediência ao prompt)
- Usando nomes de outros idiomas que estão no contexto anterior

---

## 🔧 **DEBUG ADICIONADO**

Adicionei prints de debug em `gemini_service.dart` (linha ~3243):

```dart
// 🐛 DEBUG: Verificar se genre está sendo passado
if (kDebugMode) {
  debugPrint('🎯 GENRE RECEBIDO: ${c.genre}');
  debugPrint('🌍 LANGUAGE RECEBIDO: ${c.language}');
}

// Gerar lista de nomes
final nameList = NameGeneratorService.getNameListForPrompt(...);

// 🐛 DEBUG: Verificar lista de nomes gerada
if (kDebugMode) {
  debugPrint('📝 PRIMEIROS 500 CHARS DA LISTA DE NOMES:\n...');
}
```

---

## 🧪 **TESTE PARA FAZER**

### **Passo a passo para diagnóstico:**

1. **Abrir app em modo debug**
2. **Selecionar configurações:**
   - Tema: "Velho Oeste"
   - Tipo Temático: "🤠 Western/Faroeste"
3. **Clicar em "Gerar Roteiro"**
4. **Observar console de debug:**

**O que deve aparecer:**
```
🎯 GENRE RECEBIDO: western
🌍 LANGUAGE RECEBIDO: pt (ou outro)
📝 PRIMEIROS 500 CHARS DA LISTA DE NOMES:
NOMES WESTERN (use APENAS estes para histórias de faroeste):
  Masculinos: Jedediah, Ezekiel, Josiah, Caleb, Silas, Amos, Obadiah, Thaddeus, Bartholomew, Zebedee, Malachi, Gideon, Solomon, Abraham, Isaac, Wyatt, Clint, Colt, Buck, Tex, Jake, Luke, Cole, Wade, Rex, Hank, Clay, Beau, Jeb, Zeke, Ike
  Femininos: Clementine, Evangeline, Prudence, Temperance, Charity, Faith, Hope, Grace, Mercy, Patience, Constance, Felicity, Serenity, Trinity, Belle, Rose, Sage, Pearl, Ruby, Opal, Jade, Star, Dawn, Luna, Iris, Hazel, Fern, Lily, Daisy, Violet
```

---

## 📊 **POSSÍVEIS CENÁRIOS**

### ✅ **CENÁRIO 1: Tudo está funcionando**
```
Console mostra:
🎯 GENRE RECEBIDO: western
📝 PRIMEIROS 500 CHARS: NOMES WESTERN (use APENAS...)

Mas roteiro usa: Roberto, Ana, Carlos, etc.
```

**CONCLUSÃO**: O problema é o **Gemini ignorando a lista**

**SOLUÇÃO**: Fortalecer prompt com instruções mais enfáticas sobre Western

---

### ❌ **CENÁRIO 2: Genre não está chegando**
```
Console mostra:
🎯 GENRE RECEBIDO: null
📝 PRIMEIROS 500 CHARS: NOMES DISPONÍVEIS (lista normal pt)
```

**CONCLUSÃO**: UI não está passando o `genre` corretamente

**SOLUÇÃO**: Verificar dropdown e binding de `selectedGenre`

---

### ⚠️ **CENÁRIO 3: Genre chega errado**
```
Console mostra:
🎯 GENRE RECEBIDO: Western (com W maiúsculo)
📝 PRIMEIROS 500 CHARS: NOMES DISPONÍVEIS (lista normal pt)
```

**CONCLUSÃO**: Comparação `genre == 'western'` está falhando (case-sensitive)

**SOLUÇÃO**: Normalizar para lowercase antes de comparar

---

## 🎯 **PRÓXIMOS PASSOS**

### **1. Execute o teste acima** ✅
- Rode app em debug
- Selecione Western
- Copie exatamente o que aparece no console
- Cole aqui para análise

### **2. Se `genre` for null:**
- Verificar `sidebar_panel.dart`
- Verificar `script_settings_section.dart`
- Verificar binding do dropdown

### **3. Se `genre` estiver correto mas nomes errados:**
- Fortalecer prompt do Gemini
- Adicionar validação pós-geração
- Criar sistema de retry se nomes não-Western forem detectados

---

## 💡 **SOLUÇÃO RÁPIDA (SE GEMINI IGNORA)**

Se o problema for o Gemini ignorando a lista, podemos:

### **Opção A: Prompt mais forte**
```dart
if (genre == 'western') {
  prompt += '\n'
    '🚨🚨🚨 ATENÇÃO CRÍTICA - NOMES WESTERN 🚨🚨🚨\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    '⚠️ ESTA É UMA HISTÓRIA DE VELHO OESTE (WESTERN/FAROESTE)!\n'
    '⚠️ VOCÊ DEVE USAR *APENAS* NOMES DA LISTA WESTERN ACIMA!\n'
    '⚠️ NOMES MODERNOS COMO "Roberto", "Ana", "Carlos" SÃO PROIBIDOS!\n'
    '\n'
    '❌ PROIBIDO: Roberto, Ana, Carlos, Daniel, Maria, José\n'
    '✅ OBRIGATÓRIO: Wyatt, Clint, Jedediah, Belle, Clementine, Rose\n'
    '\n'
    '🔍 ANTES DE ESCREVER QUALQUER NOME:\n'
    '   1. Olhe para a lista "NOMES WESTERN" acima\n'
    '   2. Escolha um nome DAQUELA lista\n'
    '   3. Copie EXATAMENTE como está escrito\n'
    '   4. NUNCA invente ou use nomes de fora da lista\n'
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
}
```

### **Opção B: Validação pós-geração**
```dart
// Após Gemini gerar bloco:
if (config.genre == 'western') {
  final invalidNames = _detectNonWesternNames(generatedText);
  if (invalidNames.isNotEmpty) {
    // Refazer bloco ou substituir nomes automaticamente
  }
}
```

---

## 📝 **RESUMO**

**Sistema atual:**
```
✅ Banco Western existe (30+ nomes)
✅ Função getNameListForPrompt() funciona
✅ Lista É enviada para Gemini
❓ Genre chega como 'western'? (PRECISA TESTAR)
❓ Gemini obedece a lista? (VERIFICAR)
```

**Para descobrir o problema real:**
→ **Execute o teste e me envie os logs do console!** 🔍

---

**Status**: 🟡 **Aguardando teste de diagnóstico**
