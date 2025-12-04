# 🎭 Sistema de Geração de Nomes - Documentação Completa

> **Versão:** v7.6.54  
> **Data:** Dezembro 2025  
> **Arquivo Principal:** `gemini_service.dart`

---

## 📊 Ordem de Execução

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. INÍCIO DA GERAÇÃO (generateScript)                              │
├─────────────────────────────────────────────────────────────────────┤
│  ↓                                                                  │
│  2. BOOTSTRAP DO TRACKER (_bootstrapCharacterTracker)               │
│     • Analisa título para extrair HINTS (pistas de nomes)           │
│     • Ex: "John's Revenge" → hint "John" para protagonista          │
│  ↓                                                                  │
│  3. GERAÇÃO DA SINOPSE COMPRIMIDA (_generateCompressedSynopsis)     │
│     • Prompt inclui LISTA DE NOMES SUGERIDOS do NameGeneratorService│
│     • Gemini escolhe nomes desta lista para criar a sinopse         │
│  ↓                                                                  │
│  4. GERAÇÃO DO BLOCO 1 (_generateContentBlockWithRetry)             │
│     • Prompt inclui novamente LISTA DE NOMES SUGERIDOS              │
│     • Gemini introduz personagens (usando nomes da lista)           │
│  ↓                                                                  │
│  5. EXTRAÇÃO PÓS-BLOCO (_extractCharactersFromResponse)             │
│     • Regex detecta nomes mencionados no texto gerado               │
│     • Registra no _CharacterTracker com papel (protagonista, etc)   │
│  ↓                                                                  │
│  6. DETECÇÃO DO PROTAGONISTA (_detectAndRegisterProtagonist)        │
│     • Identifica primeiro nome válido como protagonista             │
│     • Armazena em tracker._detectedProtagonistName                  │
│  ↓                                                                  │
│  7. BLOCOS 2-N (loop)                                               │
│     • Prompt inclui LEMBRETE DE NOMES JÁ USADOS (trackerInfo)       │
│     • "✅ Maria = protagonista, ✅ João = marido"                    │
│     • Gemini DEVE usar estes nomes, não inventar novos              │
│  ↓                                                                  │
│  8. VALIDAÇÃO CONTÍNUA                                              │
│     • Cada bloco: verifica se nomes são consistentes                │
│     • Se nome novo para papel existente → ERRO + regeneração        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Componentes Detalhados

### 1. NameGeneratorService (7000+ nomes)

**Arquivo:** `lib/data/services/name_generator_service.dart`

```dart
// Banco de dados organizado por:
// - Idioma (pt, en, es, fr, de, it, ja, ko, zh, ar, hi, ru)
// - Gênero (masculino, feminino, neutro)
// - Faixa etária (jovem, adulto, maduro, idoso)

// Método principal usado nos prompts:
NameGeneratorService.getNameListForPrompt(
  language: 'en',        // Idioma do roteiro
  gender: 'feminino',    // Detectado do tema/título
  ageGroup: 'maduro',    // Baseado no tema
  count: 15,             // Quantidade de sugestões
);
// Retorna: "Emily, Sarah, Jessica, Amanda, Rachel..."
```

#### Idiomas Suportados:
| Código | Idioma | Exemplos Femininos | Exemplos Masculinos |
|--------|--------|-------------------|---------------------|
| `pt` | Português | Maria, Ana, Juliana | João, Pedro, Carlos |
| `en` | Inglês | Emily, Sarah, Jessica | Michael, David, James |
| `es` | Espanhol | María, Carmen, Ana | José, Carlos, Miguel |
| `fr` | Francês | Marie, Sophie, Claire | Jean, Pierre, Louis |
| `de` | Alemão | Anna, Maria, Sophie | Hans, Karl, Michael |
| `it` | Italiano | Maria, Anna, Giulia | Marco, Luca, Giuseppe |
| `ja` | Japonês | Yuki, Sakura, Hana | Takeshi, Kenji, Hiroshi |
| `ko` | Coreano | Ji-yeon, Min-ji, Soo-ah | Min-jun, Ji-hoon, Sung-min |
| `zh` | Chinês | Mei, Li, Xiao | Wei, Jun, Ming |
| `ar` | Árabe | Fatima, Aisha, Layla | Ahmed, Mohammed, Omar |
| `hi` | Hindi | Priya, Ananya, Devi | Raj, Arjun, Vikram |
| `ru` | Russo | Natasha, Olga, Anna | Ivan, Dmitri, Alexei |

---

### 2. _CharacterTracker (Rastreador de Consistência)

**Localização:** `gemini_service.dart` (linha ~8001)

```dart
class _CharacterTracker {
  // Armazenamento principal
  Set<String> _confirmedNames = {};           // Nomes já usados
  Map<String, String> _characterRoles = {};   // nome → papel
  Map<String, String> _roleToName = {};       // papel → nome (reverso)
  String? _detectedProtagonistName;           // Protagonista detectado
  
  // Métodos principais:
  bool addName(String name, {String? role});  // Registra novo nome
  String? getRole(String name);               // Busca papel de um nome
  String? getNameForRole(String role);        // Busca nome de um papel
  String? getProtagonistName();               // Retorna protagonista
  String getCharacterMapping();               // Lista formatada
  List<String> get confirmedNames;            // Lista de nomes
  Map<String, String> get roleToNameMap;      // Mapa papel→nome
}
```

#### Funcionalidades de Validação:

1. **Anti-Duplicação:** Impede mesmo nome para papéis diferentes
2. **Anti-Reuso de Papel:** Impede papel ter múltiplos nomes
3. **Detecção de Similaridade:** Bloqueia "Arthur" vs "Arthur Evans"
4. **Histórico:** Mantém notas sobre cada personagem

---

### 3. Prompt para Gemini (Bloco 1)

```
NOMES SUGERIDOS PARA PERSONAGENS:
• Femininos (protagonista): Emily, Sarah, Jessica, Amanda, Rachel, 
  Michelle, Stephanie, Nicole, Jennifer, Christina, Elizabeth, 
  Katherine, Victoria, Alexandra, Caroline
• Masculinos (secundários): Michael, David, James, Robert, William,
  Christopher, Daniel, Matthew, Anthony, Joseph, Andrew, Joshua,
  Nicholas, Ryan, Brandon

REGRA CRÍTICA: Escolha nomes APENAS desta lista acima!
Não invente nomes genéricos como "the woman" ou "the man".
Cada personagem DEVE ter um nome próprio único.
```

---

### 4. Prompt para Gemini (Blocos 2+)

```
🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨
🔥🔥🔥 LEMBRETE CRÍTICO DE CONSISTÊNCIA DE NOMES 🔥🔥🔥

📋 PERSONAGENS DESTA HISTÓRIA (USE SEMPRE ESTES NOMES):

   ✅ Emily = protagonista/narradora
   ✅ Michael = marido traidor
   ✅ Jessica = amante

❌ PROIBIDO MUDAR ESTES NOMES! ❌

🔴 A PROTAGONISTA/NARRADORA SE CHAMA: Emily
   → Quando ela fala de si mesma: "I" ou "me"
   → Quando outros falam dela: "Emily"
   → NUNCA mude para Sarah, Jessica, Amanda, etc!

📌 MAPEAMENTO PAPEL → NOME (CONSULTE SEMPRE):
   • protagonista → Emily
   • marido → Michael
   • amante → Jessica

⚠️ SE VOCÊ TROCAR UM NOME, O ROTEIRO SERÁ REJEITADO! ⚠️
🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨
```

---

## 🔄 Fluxo Visual Simplificado

```
NameGeneratorService          _CharacterTracker           Gemini AI
      │                              │                        │
      │  getNameListForPrompt()      │                        │
      ├──────────────────────────────┼───────────────────────>│
      │  "Emily, Sarah, Jessica..."  │     (Lista no prompt)  │
      │                              │                        │
      │                              │    Gera texto com      │
      │                              │    "Emily walked..."   │
      │                              │<───────────────────────┤
      │                              │                        │
      │                              │  extractCharacters()   │
      │                              ├────────────────────────┤
      │                              │  addName("Emily",      │
      │                              │    role:"protagonista")│
      │                              │                        │
      │                              │    Bloco 2+ prompt:    │
      │                              │    "USE Emily, não     │
      │                              │     mude o nome!"      │
      │                              ├───────────────────────>│
      │                              │                        │
```

---

## ⚡ Pontos-Chave

| Aspecto | Como Funciona |
|---------|---------------|
| **Fonte dos nomes** | `NameGeneratorService` (único banco de dados) |
| **Quem escolhe** | Gemini escolhe da lista fornecida |
| **Quando registra** | Após cada bloco, via extração automática |
| **Como mantém consistência** | Tracker injeta lembrete em cada prompt |
| **Validação** | Se Gemini trocar nome → bloco é regenerado |
| **Interface do usuário** | NÃO tem campos para nomes (100% automático) |

---

## 📁 Arquivos Relacionados

| Arquivo | Função |
|---------|--------|
| `gemini_service.dart` | Lógica principal de geração |
| `name_generator_service.dart` | Banco de 7000+ nomes |
| `script_config.dart` | Configuração do roteiro |
| `auxiliary_tools_provider.dart` | Ferramentas auxiliares |

---

## 🔍 Métodos Principais

### `_bootstrapCharacterTracker()`
- **Quando:** Início da geração
- **O que faz:** Analisa título para extrair hints de nomes
- **Exemplo:** "John's Revenge" → registra "John" como hint

### `_generateCompressedSynopsis()`
- **Quando:** Antes do Bloco 1
- **O que faz:** Gera sinopse curta com nomes da lista
- **Inclui:** Lista de nomes sugeridos no prompt

### `_extractCharactersFromResponse()`
- **Quando:** Após cada bloco gerado
- **O que faz:** Usa regex para detectar nomes no texto
- **Registra:** Nome + papel no tracker

### `_detectAndRegisterProtagonist()`
- **Quando:** Após Bloco 1
- **O que faz:** Identifica primeiro nome válido como protagonista
- **Armazena:** Em `tracker._detectedProtagonistName`

### `getCharacterMapping()`
- **Quando:** Construção do prompt (Blocos 2+)
- **O que faz:** Retorna string formatada com todos os personagens
- **Formato:** "✅ Nome = papel"

---

## 🚨 Validações de Segurança

### 1. Anti-Duplicação de Nomes
```dart
// Se nome já existe com papel diferente → BLOQUEIA
if (_confirmedNames.contains(name)) {
  if (role != existingRole) {
    return false; // ERRO: mesmo nome, papel diferente
  }
}
```

### 2. Anti-Reuso de Papéis
```dart
// Se papel já tem nome diferente → BLOQUEIA
if (_roleToName.containsKey(normalizedRole)) {
  final existingName = _roleToName[normalizedRole];
  if (existingName != name) {
    return false; // ERRO: papel com múltiplos nomes
  }
}
```

### 3. Detecção de Similaridade
```dart
// Bloqueia variações: "Arthur" vs "Arthur Evans"
final nameWords = name.split(' ');
final existingWords = existingName.split(' ');
if (nameWords.any((w) => existingWords.contains(w))) {
  return true; // BLOQUEIA: sobreposição de palavras
}
```

---

## 📝 Histórico de Versões

| Versão | Mudança |
|--------|---------|
| v7.6.17 | Adicionado `_detectedProtagonistName` |
| v7.6.25 | Validação reversa (papel → nome único) |
| v7.6.30 | Detecção de similaridade de nomes |
| v7.6.35 | PostGenerationFixer para correção automática |
| v7.6.54 | Removido `config.protagonistName` (campo sempre vazio) |

---

## ✅ Resumo Final

O sistema de nomes é **100% automático**:

1. **Entrada:** Título + Tema + Idioma do roteiro
2. **Processamento:** NameGeneratorService fornece lista → Gemini escolhe → Tracker registra
3. **Saída:** Nomes consistentes ao longo de todo o roteiro

**Não existe interface do usuário para inserir nomes manualmente.** Todo o sistema depende do banco de dados de 7000+ nomes e da auto-detecção via regex após cada bloco gerado.
