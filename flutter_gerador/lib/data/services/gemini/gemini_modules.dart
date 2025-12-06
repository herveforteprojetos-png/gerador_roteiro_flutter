// Barrel file - Exporta todos os módulos para import único
// Módulos Gemini
export 'api/gemini_api_client.dart';
export 'utils/word_counter.dart';
export 'utils/similarity_calculator.dart';
export 'utils/text_filter.dart';
export 'validation/anti_repetition.dart';
export 'validation/name_validator.dart';
export 'validation/family_relations.dart';
export 'validation/post_generation_fixer.dart'; // 🆕 v7.6.35
export 'tracking/character_tracker.dart';
export 'progress/generation_progress_manager.dart';

// 🏗️ v7.6.67: Módulo de Estilos Narrativos
export 'prompts/narrative_styles.dart';

// Prompts (export com hide para evitar conflitos de classes com o tracker)
// export '../prompts/prompt_builder.dart'; // REMOVIDO: Arquivo deletado na limpeza v7.6.65
export '../prompts/base_rules.dart';
export '../prompts/structure_rules.dart';
export '../prompts/youtube_rules.dart';
export '../prompts/character_rules.dart'
    hide CharacterNote, CharacterHistory, CharacterTracker;

