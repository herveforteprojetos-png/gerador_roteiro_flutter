/// 📦 Scripting Modules - Barrel Export
///
/// Este arquivo exporta todos os módulos de scripting
/// criados na refatoração SOLID do GeminiService v7.6.64
///
/// Módulos incluídos:
/// - LlmClient: Comunicação com APIs de LLM (Gemini)
/// - PromptBuilder: Construção de prompts para geração
/// - WorldStateManager: Gerenciamento do estado do mundo
/// - ScriptValidator: Validação de roteiros
library scripting;

export 'llm_client.dart';
export 'prompt_builder.dart';
export 'world_state_manager.dart';
export 'script_validator.dart';
