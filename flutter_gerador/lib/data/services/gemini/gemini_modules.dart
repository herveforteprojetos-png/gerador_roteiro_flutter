// Barrel file - Exporta todos os módulos para import único
// Módulos Gemini
export 'api/gemini_api_client.dart';
export 'utils/word_counter.dart';
export 'utils/similarity_calculator.dart';
export 'utils/text_filter.dart';
export 'validation/anti_repetition.dart';
export 'validation/name_validator.dart';
export 'validation/family_relations.dart';
export 'tracking/character_tracker.dart';
export 'progress/generation_progress_manager.dart';

// Prompts (export com hide para evitar conflitos de classes com o tracker)
export '../prompts/prompt_builder.dart';
export '../prompts/base_rules.dart';
export '../prompts/structure_rules.dart';
export '../prompts/youtube_rules.dart';
export '../prompts/character_rules.dart'
    hide CharacterNote, CharacterHistory, CharacterTracker;
