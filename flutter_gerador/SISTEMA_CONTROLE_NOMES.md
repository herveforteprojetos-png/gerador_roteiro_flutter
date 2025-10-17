# 🎭 Como Funciona o Sistema de Controle de Nomes de Personagens

## 📌 VISÃO GERAL

O sistema usa uma classe chamada **`_CharacterTracker`** que funciona como um "registro global" de todos os personagens que aparecem no roteiro, garantindo que os nomes permaneçam constantes do início ao fim.

---

## 🏗️ ARQUITETURA DO SISTEMA

### 1️⃣ **Classe `_CharacterTracker`** (Linha 4679)

Esta é a classe principal que gerencia TODOS os personagens:

```dart
class _CharacterTracker {
  // Mapa: nome → papel do personagem
  final Map<String, String> _characters = {};
  
  // Mapa: nome → número do bloco onde apareceu pela primeira vez
  final Map<String, int> _firstAppearance = {};
  
  // Mapa: nome → histórico completo de ações/relações
  final Map<String, _CharacterHistory> _history = {};
  
  // Lista de todos os nomes confirmados
  List<String> get confirmedNames => _characters.keys.toList();
  
  // Adiciona um personagem ao rastreamento
  void addName(String name, {String? role, int? blockNumber});
  
  // Verifica se um nome já está sendo rastreado
  bool hasName(String name);
}
```

**O que ela faz:**
- 📝 **Registra cada personagem** que aparece no roteiro
- 🎭 **Armazena o papel** de cada um (protagonista, secundário, etc.)
- 📍 **Marca em qual bloco** cada personagem apareceu pela primeira vez
- 📚 **Mantém um histórico** de ações e relações de cada personagem

---

## 🔄 FLUXO COMPLETO: Como os Nomes São Mantidos Constantes

### **FASE 1: INICIALIZAÇÃO (Bootstrap)** 
📍 **Arquivo:** `gemini_service.dart`, linha 436-437

```dart
// Cria o tracker global para TODO o roteiro
final persistentTracker = _CharacterTracker();
_bootstrapCharacterTracker(persistentTracker, config);
```

#### **O que acontece:**
1. **Cria o tracker** que vai acompanhar TODA a geração
2. **Preenche com nomes iniciais** fornecidos pelo usuário:
   - Nome do protagonista (campo "Nome do Protagonista")
   - Nome do personagem secundário (campo "Personagem Secundário")
   - Nomes encontrados no título (ex: "A história de Maria")

#### **Exemplo de Log:**
```
🔐 TRACKER BOOTSTRAP - 2 nome(s) carregado(s):
   📌 Protagonista: Maria
   📌 Secundário: João
   ✅ Total: Maria, João
```

---

### **FASE 2: GERAÇÃO DE CADA BLOCO**
📍 **Arquivo:** `gemini_service.dart`, linhas 440-760

Para **cada bloco** do roteiro (ex: 8 blocos no total):

#### **2.1 - Preparar Contexto**
```dart
final characterGuidance = _buildCharacterGuidance(c, persistentTracker);
```

**O que acontece:**
- Monta uma lista de TODOS os personagens já confirmados
- Passa essa lista para a IA com instruções **RÍGIDAS**:

```
PERSONAGENS ESTABELECIDOS:
- Protagonista: "Maria" — mantenha exatamente este nome e sua função.
- Personagem secundário: "João" — preserve o mesmo nome em todos os blocos.
- Personagem estabelecido: "Pedro" — não altere este nome nem invente apelidos.

Nunca substitua esses nomes por variações ou apelidos.
```

#### **2.2 - IA Gera o Bloco**
A IA recebe:
- ✅ Lista de nomes que DEVE usar
- ✅ Contexto dos blocos anteriores
- ✅ Instruções para NÃO inventar nomes novos

#### **2.3 - Validação Pós-Geração** (Linhas 650-730)
```dart
// Após gerar o bloco, extrair TODOS os nomes que aparecem
final allNamesInBlock = _extractNamesFromSnippet(added);

for (final entry in allNamesInBlock.entries) {
  final name = entry.key;
  
  // Se o nome já existe no tracker, pular
  if (persistentTracker.hasName(name)) {
    continue; // Já rastreado, OK!
  }
  
  // Se é um nome NOVO e válido, adicionar ao tracker
  if (NameGeneratorService.isValidName(name)) {
    final role = _extractRoleForName(name, added);
    persistentTracker.addName(name, role: role, blockNumber: block);
  }
}
```

**O que acontece:**
1. 🔍 **Escaneia o bloco** em busca de nomes de personagens
2. ✅ **Valida cada nome** contra um banco de dados de nomes válidos
3. 📝 **Adiciona novos personagens** ao tracker (se necessário)
4. 🚫 **Impede duplicação** - se o nome já existe, não adiciona de novo

---

### **FASE 3: VALIDAÇÕES CRÍTICAS**
📍 **Arquivo:** `gemini_service.dart`, linhas 652-679

Após CADA bloco, o sistema executa 3 validações:

#### **Validação 1: Nome da Protagonista Mudou?**
```dart
_validateProtagonistName(added, config, block);
```
- Verifica se o nome principal continua o mesmo
- Se mudou, **ALERTA no console** (mas não interrompe)

#### **Validação 2: Algum Nome Foi Reutilizado?**
```dart
_validateNameReuse(added, persistentTracker, block);
```
- Verifica se IA não criou "Pedro Silva" quando já existia "Pedro"
- Impede variações do mesmo nome (ex: "Maria" vs "Maria Silva")

#### **Validação 3: Relações Familiares Consistentes?**
```dart
_validateFamilyRelations(added, block);
```
- Verifica se relações familiares fazem sentido
- Exemplo: Se "Maria" é mãe de "João" no bloco 2, não pode ser filha dele no bloco 5

---

### **FASE 4: ATUALIZAÇÃO CONTÍNUA**
📍 **Arquivo:** `gemini_service.dart`, linha 680

```dart
_updateTrackerFromContextSnippet(persistentTracker, config, added);
```

Após validar, atualiza o tracker com informações do bloco atual:
- Papéis de personagens que foram mencionados mas ainda não tinham papel
- Relações familiares que ficaram claras
- Histórico de ações (para referência futura)

---

### **FASE 5: BLOCOS SUBSEQUENTES HERDAM TUDO**
📍 **Arquivo:** `gemini_service.dart`, linha 447 (loop)

```dart
for (var block = 1; block <= totalBlocks && !_isCancelled; block++) {
  // A cada novo bloco, passa o tracker ATUALIZADO
  final characterGuidance = _buildCharacterGuidance(c, persistentTracker);
  // ... gera próximo bloco com TODOS os personagens anteriores
}
```

**Efeito cascata:**
- Bloco 1: Maria
- Bloco 2: Maria + João (herdados) + Pedro (novo)
- Bloco 3: Maria + João + Pedro (herdados) + Sofia (nova)
- Bloco 4: Maria + João + Pedro + Sofia (herdados)
- ...e assim por diante

---

## 🛡️ MECANISMOS DE PROTEÇÃO

### **1. Banco de Dados de Nomes Válidos**
```dart
NameGeneratorService.isValidName(name)
```
- Mantém lista curada de nomes por idioma
- Impede que verbos sejam confundidos com nomes
- Exemplo: ❌ "Observei", "Quero", "Pergunte" → Rejeitados
- Exemplo: ✅ "Maria", "João", "Pedro" → Aceitos

### **2. Stopwords (Palavras Bloqueadas)**
```dart
final _nameStopwords = {
  'ele', 'ela', 'isso', 'aquilo', 'meu', 'minha',
  'primeiro', 'segundo', 'último', 'vez', 'dia', 'noite'
  // ... mais de 300 palavras bloqueadas
};
```
- Impede que palavras comuns sejam tratadas como nomes
- Exemplo: "Ele disse" → "Ele" NÃO é registrado como personagem

### **3. Detecção de Similaridade**
```dart
if (newName.toLowerCase() == existingName.toLowerCase()) {
  // Nome duplicado, ignorar!
}
```
- Ignora variações como "MARIA" vs "Maria" vs "maria"
- Evita "Pedro Silva" quando já existe "Pedro"

### **4. Extração de Papéis**
```dart
final role = _extractRoleForName(name, snippet);
```
- Detecta automaticamente o papel do personagem no texto:
  - "protagonista" → mencionado como personagem principal
  - "mãe", "pai", "filho" → papel familiar
  - "secundário" → personagem de apoio
  - "indefinido" → papel ainda não claro

---

## 📊 EXEMPLO COMPLETO DE FLUXO

### **Input do Usuário:**
- Protagonista: "Maria"
- Tema: "Vingança"
- Quantidade: 8 blocos

### **Geração Bloco 1:**
```
🔐 TRACKER BOOTSTRAP - 1 nome(s):
   📌 Protagonista: Maria

Bloco 1 gerado:
"Maria olhava pela janela quando João chegou..."

🔒 TRACKING - Novo personagem detectado no bloco 1:
   Nome: João
   Papel: indefinido
   Frequência: 3 vezes
```

**Tracker agora contém:** Maria (protagonista), João (indefinido)

### **Geração Bloco 2:**
```
IA recebe instruções:
PERSONAGENS ESTABELECIDOS:
- Protagonista: "Maria"
- Personagem estabelecido: "João"

Bloco 2 gerado:
"Maria confrontou João sobre o segredo de Pedro..."

🔒 TRACKING - Novo personagem detectado no bloco 2:
   Nome: Pedro
   Papel: indefinido
   Frequência: 2 vezes
```

**Tracker agora contém:** Maria, João, Pedro

### **Geração Bloco 3:**
```
IA recebe instruções:
PERSONAGENS ESTABELECIDOS:
- Protagonista: "Maria"
- Personagem estabelecido: "João"
- Personagem estabelecido: "Pedro"

Bloco 3 gerado:
"Maria, João e Pedro se encontraram..."

✅ Nenhum nome novo detectado (todos já rastreados)
```

**Tracker mantém:** Maria, João, Pedro (constantes!)

---

## 🎯 POR QUE FUNCIONA?

1. **Persistência Global:** O `persistentTracker` existe durante TODA a geração
2. **Feedback Contínuo:** A cada bloco, a IA recebe a lista ATUALIZADA de personagens
3. **Validação Rigorosa:** Múltiplas camadas de verificação impedem inconsistências
4. **Banco de Dados Curado:** Apenas nomes reais são aceitos, verbos são rejeitados
5. **Histórico Acumulado:** Cada bloco herda informações dos anteriores

---

## 🚨 LIMITAÇÕES CONHECIDAS

### **1. IA Ainda Pode Inventar Variações**
- Problema: IA pode gerar "Maria Silva" quando já existe "Maria"
- Solução parcial: Validação detecta mas não corrige automaticamente
- **Solução ideal:** Sistema deveria rejeitar o bloco e regenerar

### **2. Apelidos Não São Detectados**
- Problema: "Pedro" virar "Pedrinho" não é detectado como mesmo personagem
- Causa: Sistema trata como nomes diferentes
- **Melhoria futura:** Detector de apelidos/variações

### **3. Homônimos**
- Problema: Se dois personagens têm o mesmo nome (ex: dois "José")
- Sistema não diferencia
- **Workaround:** Usuário deve usar nomes únicos inicialmente

### **4. Performance na Validação**
- Problema: Validar TODOS os nomes a cada bloco é lento (20-25% do tempo)
- Solução na análise: Processar nomes em batch no final
- **Trade-off:** Consistência vs Performance

---

## 💡 COMO O USUÁRIO PODE AJUDAR

### **✅ FAZER:**
1. Sempre preencher campo "Nome do Protagonista"
2. Se houver personagem secundário importante, preencher o campo
3. Usar nomes únicos e distintos
4. Revisar roteiro final em busca de inconsistências

### **❌ EVITAR:**
1. Deixar campos de nomes em branco (IA pode criar nomes aleatórios)
2. Usar apelidos/variações nos campos de input
3. Usar nomes muito comuns que possam confundir (ex: "João" + "João Pedro")

---

## 🔬 DIAGRAMA VISUAL

```
┌─────────────────────────────────────────┐
│  USUÁRIO PREENCHE CONFIGURAÇÃO          │
│  - Protagonista: "Maria"                │
│  - Secundário: "João"                   │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  FASE 1: BOOTSTRAP                      │
│  persistentTracker.addName("Maria")     │
│  persistentTracker.addName("João")      │
└─────────────────┬───────────────────────┘
                  │
                  ▼
         ┌────────────────┐
         │  BLOCO 1       │
         │  - Gera texto  │
         │  - Detecta:    │
         │    + Pedro (novo)
         └────────┬───────┘
                  │
      Tracker: Maria, João, Pedro
                  │
                  ▼
         ┌────────────────┐
         │  BLOCO 2       │
         │  - Recebe:     │
         │    Maria, João,│
         │    Pedro       │
         │  - Gera texto  │
         │  - Detecta:    │
         │    + Sofia (nova)
         └────────┬───────┘
                  │
   Tracker: Maria, João, Pedro, Sofia
                  │
                  ▼
         ┌────────────────┐
         │  BLOCO 3       │
         │  - Recebe:     │
         │    Maria, João,│
         │    Pedro, Sofia│
         │  - Gera texto  │
         │  - Nenhum novo │
         └────────┬───────┘
                  │
                  ⋮
                  │
                  ▼
┌─────────────────────────────────────────┐
│  ROTEIRO FINAL                          │
│  Maria, João, Pedro, Sofia              │
│  (CONSTANTES DO INÍCIO AO FIM!)         │
└─────────────────────────────────────────┘
```

---

## 📚 ARQUIVOS ENVOLVIDOS

1. **`gemini_service.dart`**
   - Classe `_CharacterTracker` (linha 4679)
   - Método `_bootstrapCharacterTracker()` (linha 1654)
   - Método `_updateTrackerFromContextSnippet()` (linha 1714)
   - Método `_buildCharacterGuidance()` (linha 1793)
   - Método `_validateProtagonistName()` (linhas 4200+)
   - Método `_validateNameReuse()` (linhas 4300+)

2. **`name_generator_service.dart`**
   - Banco de dados de nomes válidos por idioma
   - Método `isValidName()` para validação

3. **`script_config.dart`**
   - Campos: `protagonistName`, `secondaryCharacterName`
   - Passados para o tracker no bootstrap

---

**Data:** 16 de Outubro de 2025  
**Sistema:** Gerador de Roteiro v1.5+  
**Arquivo de Referência:** `gemini_service.dart` (4.867 linhas)
