// Barrel export para módulos de infraestrutura do Gemini Service.
//
// Agrupa os módulos responsáveis por:
// - Rate limiting e controle de requisições
// - Circuit breaker para proteção contra falhas
// - Watchdog para timeouts
//
// Uso:
// ```dart
// import 'package:flutter_gerador/data/services/gemini/infra/infra_modules.dart';
// ```

export 'rate_limiter.dart';
