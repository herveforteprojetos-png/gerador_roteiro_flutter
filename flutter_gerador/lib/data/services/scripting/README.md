# 🏗️ Scripting Modules - Arquitetura SOLID

## Visão Geral

Este diretório contém os módulos refatorados do `GeminiService` seguindo princípios SOLID.
A refatoração visa transformar o "God Class" original (~9500 linhas) em componentes modulares e testáveis.

## Módulos

### 1. `LlmClient` (llm_client.dart)
**Responsabilidade Única**: Comunicação com APIs de LLM (Gemini)

```dart
final llmClient = LlmClient(instanceId: 'main');
final response = await llmClient.generateText(
  apiKey: apiKey,
  model: 'gemini-2.5-flash',
  prompt: 'Escreva uma história...',
  maxTokens: 8192,
);
```

**Métodos principais**:
- `generateText()` - Geração de texto simples
- `generateJson()` - Geração com parsing JSON automático
- `getModelForQuality()` - Seleção de modelo por qualidade

### 2. `PromptBuilder` (prompt_builder.dart)
**Responsabilidade Única**: Construção de prompts para geração de roteiros

```dart
final prompt = PromptBuilder.buildBlockPrompt(
  config: scriptConfig,
  blockNumber: 1,
  totalBlocks: 10,
  previousContext: '...',
);
```

**Métodos principais**:
- `buildBlockPrompt()` - Prompt completo para um bloco
- `getPerspectiveInstruction()` - Instrução de perspectiva narrativa
- `getPacingInstruction()` - Instrução de ritmo/pacing
- `getArchetype()` - Arquétipo da história

### 3. `WorldStateManager` (world_state_manager.dart)
**Responsabilidade Única**: Gerenciamento do estado do mundo da história

```dart
final worldManager = WorldStateManager(llmClient: llmClient);
await worldManager.generateCompressedSynopsis(
  tema: 'Terror psicológico',
  title: 'A Casa Abandonada',
  protagonistName: 'Maria',
  language: 'pt-BR',
  apiKey: apiKey,
  qualityMode: QualityMode.flash,
);
```

**Classes**:
- `WorldState` - Estado completo (personagens, inventário, fatos)
- `WorldCharacter` - Dados de um personagem
- `WorldStateManager` - Orquestrador do estado

### 4. `ScriptValidator` (script_validator.dart)
**Responsabilidade Única**: Validação de coerência título↔história

```dart
final validator = ScriptValidator();
final isValid = await validator.validateTitleCoherence(
  generatedText: scriptText,
  originalTitle: 'Terror na Floresta',
  language: 'pt-BR',
);
```

**Métodos principais**:
- `validateTitleCoherenceRigorous()` - Validação rigorosa
- `translateKeywordsToTargetLang()` - Tradução de keywords

## Arquitetura

```
GeminiService (Coordinator)
    │
    ├── LlmClient (Comunicação)
    │       └── Dio HTTP Client
    │
    ├── PromptBuilder (Prompts)
    │       └── Templates & Rules
    │
    ├── WorldStateManager (Estado)
    │       └── WorldState, WorldCharacter
    │
    └── ScriptValidator (Validação)
            └── Coerência título/história
```

## Status da Migração

| Componente | Status | Descrição |
|------------|--------|-----------|
| LlmClient | ✅ Criado | Pronto para uso |
| PromptBuilder | ✅ Criado | Pronto para uso |
| WorldStateManager | ✅ Criado | Pronto para uso |
| ScriptValidator | ✅ Criado | Pronto para uso |
| Integração GeminiService | 🔄 Parcial | Módulos inicializados |
| Migração chamadas internas | ⏳ Pendente | Próxima fase |
| Remoção código legado | ⏳ Pendente | Após testes |

## Uso

```dart
import 'package:flutter_gerador/data/services/scripting/scripting_modules.dart';

// Todos os módulos disponíveis via barrel export
final llm = LlmClient(instanceId: 'test');
final world = WorldStateManager(llmClient: llm);
final validator = ScriptValidator();
```

## Próximos Passos

1. **Migração Gradual**: Substituir chamadas `_makeApiRequest` por `_llmClient.generateText()`
2. **Migração WorldState**: Usar `WorldStateManager` em vez de `_WorldState` interno
3. **Testes Unitários**: Adicionar testes para cada módulo
4. **Remoção Legacy**: Remover código duplicado após validação

## Versão

- Criado em: v7.6.64
- Última atualização: Dezembro 2024
