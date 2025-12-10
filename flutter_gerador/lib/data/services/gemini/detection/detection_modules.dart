// Barrel export para módulos de detecção do Gemini Service.
//
// Agrupa os módulos responsáveis por:
// - Detecção de duplicação de texto
// - Limpeza de texto gerado
// - Rastreamento de nomes de personagens
//
// Uso:
// ```dart
// import 'package:flutter_gerador/data/services/gemini/detection/detection_modules.dart';
// ```

export 'duplication_detector.dart';
// text_cleaner usa a versão do duplication_detector para filterDuplicateParagraphsIsolate
export 'text_cleaner.dart' hide filterDuplicateParagraphsIsolate;
export 'name_tracker.dart';
