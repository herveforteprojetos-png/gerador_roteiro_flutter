// 🔧 v7.6.101: Módulo de Validação de Personagens (SOLID - SRP)
// Extraído de gemini_service.dart para Single Responsibility

import 'package:flutter/foundation.dart';

import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/debug_log.dart';
import 'package:flutter_gerador/data/services/gemini/tracking/character_tracker.dart';
import 'name_validator.dart';
import 'name_constants.dart';
import 'role_patterns.dart';
import 'relationship_patterns.dart';

/// Função de log global (mantida para compatibilidade)
void _log(String message, {String level = 'info'}) {
  if (kDebugMode) {
    final prefix = level == 'critical'
        ? '🚨'
        : (level == 'warning' ? '⚠️' : 'ℹ️');
    debugPrint('$prefix $message');
  }
}

/// 🎯 Módulo de Validação de Personagens
/// Responsável por validar consistência de nomes e papéis
class CharacterValidation {
  final DebugLogManager _debugLogger;

  CharacterValidation(this._debugLogger);

  /// 🎯 v7.6.17: Detecta e registra o nome da protagonista no Bloco 1
  void detectAndRegisterProtagonist(
    String generatedText,
    ScriptConfig config,
    CharacterTracker tracker,
  ) {
    final configName = config.protagonistName.trim();
    if (configName.isEmpty) return;

    final names = NameValidator.extractNamesFromText(generatedText);

    if (names.contains(configName)) {
      tracker.setProtagonistName(configName);
      if (kDebugMode) {
        debugPrint('✅ Bloco 1: Protagonista "$configName" confirmada');
      }
    } else {
      final validNames = names
          .where((n) => NameValidator.looksLikePersonName(n))
          .toList();
      if (validNames.isNotEmpty) {
        final detectedName = validNames.first;
        tracker.setProtagonistName(detectedName);
        if (kDebugMode) {
          debugPrint(
            '⚠️ Bloco 1: Nome configurado "$configName" não usado, '
            'detectado "$detectedName" como protagonista',
          );
        }
      }
    }
  }

  /// 🔍 v7.6.17: Valida se protagonista manteve o mesmo nome
  /// Retorna true se mudança detectada (bloco deve ser rejeitado)
  bool detectProtagonistNameChange(
    String generatedText,
    ScriptConfig config,
    CharacterTracker tracker,
    int blockNumber,
  ) {
    if (blockNumber == 1) return false;

    final registeredName = tracker.getProtagonistName();
    if (registeredName == null) return false;

    final currentNames = NameValidator.extractNamesFromText(generatedText);
    final protagonistPresent = currentNames.contains(registeredName);

    final otherValidNames = currentNames
        .where(
          (n) => n != registeredName && NameValidator.looksLikePersonName(n),
        )
        .toList();

    if (!protagonistPresent && otherValidNames.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Bloco $blockNumber: Protagonista "$registeredName" ausente!',
        );
        debugPrint('   Nomes encontrados: ${otherValidNames.join(", ")}');
        debugPrint('   🔄 Possível mudança de nome!');
      }

      _debugLogger.error(
        'Mudança de protagonista detectada',
        blockNumber: blockNumber,
        details:
            'Esperado "$registeredName", encontrado ${otherValidNames.join(", ")}',
        metadata: {
          'protagonistaEsperada': registeredName,
          'nomesEncontrados': otherValidNames,
        },
      );

      return true;
    }

    return false;
  }

  /// 🔍 VALIDAÇÃO CRÍTICA: Detecta reutilização de nomes
  /// Retorna true se validação passou, false se detectou erro crítico
  bool validateProtagonistName(
    String generatedText,
    ScriptConfig config,
    int blockNumber,
  ) {
    final protagonistName = config.protagonistName.trim();
    if (protagonistName.isEmpty) return true;

    // Detectar auto-apresentações com nomes errados
    final nameIntroPatterns = [
      RegExp(r'my name is ([A-Z][a-z]+)', caseSensitive: false),
      RegExp(r"i'm ([A-Z][a-z]+)", caseSensitive: false),
      RegExp(r'call me ([A-Z][a-z]+)', caseSensitive: false),
      RegExp(r"i am ([A-Z][a-z]+)", caseSensitive: false),
    ];

    for (final pattern in nameIntroPatterns) {
      final match = pattern.firstMatch(generatedText);
      if (match != null) {
        final introducedName = match.group(1);
        if (introducedName != null &&
            introducedName.toLowerCase() != protagonistName.toLowerCase()) {
          _log(
            '🚨 ERRO CRÍTICO: AUTO-APRESENTAÇÃO COM NOME ERRADO!',
            level: 'critical',
          );
          _log(
            '   ❌ Protagonista configurada: "$protagonistName"',
            level: 'critical',
          );
          _log(
            '   ❌ Nome na auto-apresentação: "$introducedName"',
            level: 'critical',
          );
          _log('   📝 Trecho: "${match.group(0)}"', level: 'critical');
          _log('   🔄 BLOCO SERÁ REJEITADO E REGENERADO', level: 'critical');
          return false;
        }
      }
    }

    // Lista de nomes suspeitos
    final suspiciousNames = [
      'Wanessa',
      'Carla',
      'Beatriz',
      'Fernanda',
      'Juliana',
      'Mariana',
      'Patrícia',
      'Roberta',
      'Silvia',
      'Tatiana',
      'Carlos',
      'Eduardo',
      'Fernando',
      'Gustavo',
      'Henrique',
      'Leonardo',
      'Marcelo',
      'Rafael',
      'Rodrigo',
      'Thiago',
      'Hannah',
      'Laura',
      'Jessica',
      'Sarah',
      'Emily',
      'Emma',
      'Olivia',
      'Sophia',
      'Michael',
      'David',
      'James',
      'John',
      'Robert',
    ];

    final hasProtagonist = generatedText.contains(protagonistName);

    for (final suspiciousName in suspiciousNames) {
      if (suspiciousName.toLowerCase() == protagonistName.toLowerCase()) {
        continue;
      }

      if (generatedText.contains(suspiciousName)) {
        _debugLogger.error(
          "Troca de nome detectada: '$suspiciousName'",
          blockNumber: blockNumber,
          details:
              "Protagonista deveria ser '$protagonistName' mas encontrei '$suspiciousName'",
          metadata: {
            'protagonista': protagonistName,
            'nomeEncontrado': suspiciousName,
          },
        );

        _log(
          '🚨 ERRO CRÍTICO DETECTADO NO BLOCO $blockNumber:',
          level: 'critical',
        );
        _log(
          '   ❌ Protagonista deveria ser: "$protagonistName"',
          level: 'critical',
        );
        _log(
          '   ❌ Mas encontrei nome suspeito: "$suspiciousName"',
          level: 'critical',
        );
        _log('   🔄 BLOCO SERÁ REJEITADO E REGENERADO', level: 'critical');
        return false;
      }
    }

    if (!hasProtagonist && blockNumber <= 2) {
      _debugLogger.warning(
        "Protagonista ausente",
        details: "'$protagonistName' não apareceu no bloco $blockNumber",
        metadata: {'bloco': blockNumber, 'protagonista': protagonistName},
      );
      debugPrint(
        '⚠️ AVISO: Protagonista "$protagonistName" não apareceu no bloco $blockNumber',
      );
    } else if (hasProtagonist) {
      _debugLogger.validation(
        "Protagonista validada",
        blockNumber: blockNumber,
        details: "'$protagonistName' presente no bloco",
        metadata: {'protagonista': protagonistName},
      );
    }

    return true;
  }

  /// 🔍 v7.6.22: VALIDAÇÃO DE RELACIONAMENTOS FAMILIARES
  /// Retorna true se relacionamentos são consistentes, false se há erros
  bool validateFamilyRelationships(String text, int blockNumber) {
    if (text.isEmpty) return true;

    final Map<String, Map<String, Set<String>>> relationships = {};
    final patterns = RelationshipPatterns.allRelationPatterns;

    for (final entry in patterns.entries) {
      final relationType = entry.key;
      final pattern = entry.value;

      for (final match in pattern.allMatches(text)) {
        final name = match.group(1);
        if (name != null) {
          relationships.putIfAbsent('protagonist', () => {});
          relationships['protagonist']!.putIfAbsent(relationType, () => {});
          relationships['protagonist']![relationType]!.add(name);
        }
      }
    }

    bool hasError = false;

    final brotherInLaw = relationships['protagonist']?['cunhado'] ?? {};
    final sisterInLaw = relationships['protagonist']?['cunhada'] ?? {};
    final husband = relationships['protagonist']?['marido'] ?? {};
    final wife = relationships['protagonist']?['esposa'] ?? {};
    final brother = relationships['protagonist']?['irmão'] ?? {};
    final sister = relationships['protagonist']?['irmã'] ?? {};

    for (final inLaw in [...brotherInLaw, ...sisterInLaw]) {
      if (husband.isEmpty &&
          wife.isEmpty &&
          brother.isEmpty &&
          sister.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ ERRO: $inLaw é cunhado/cunhada mas não há cônjuge nem irmãos!',
          );
        }
        hasError = true;
      }
    }

    final fatherInLaw = relationships['protagonist']?['sogro'] ?? {};
    final motherInLaw = relationships['protagonist']?['sogra'] ?? {};

    if (fatherInLaw.isNotEmpty || motherInLaw.isNotEmpty) {
      if (husband.isEmpty && wife.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ ERRO: Tem sogro/sogra mas protagonista não tem cônjuge!',
          );
        }
        hasError = true;
      }
    }

    final sonInLaw = relationships['protagonist']?['genro'] ?? {};
    final daughterInLaw = relationships['protagonist']?['nora'] ?? {};

    if (sonInLaw.isNotEmpty || daughterInLaw.isNotEmpty) {
      final hasChildren = text.contains(
        RegExp(
          r'meu filho|minha filha|my son|my daughter',
          caseSensitive: false,
        ),
      );
      if (!hasChildren) {
        if (kDebugMode) {
          debugPrint('⚠️ ERRO: Tem genro/nora mas não menciona filhos!');
        }
        hasError = true;
      }
    }

    final grandson = relationships['protagonist']?['neto'] ?? {};
    final granddaughter = relationships['protagonist']?['neta'] ?? {};

    // 🔧 v7.6.148: Relaxar validação em blocos avançados (6+)
    // Relações familiares já estabelecidas em blocos anteriores
    if ((grandson.isNotEmpty || granddaughter.isNotEmpty) && blockNumber < 6) {
      final hasChildren = text.contains(
        RegExp(
          r'meu filho|minha filha|my son|my daughter',
          caseSensitive: false,
        ),
      );
      if (!hasChildren) {
        if (kDebugMode) {
          debugPrint('⚠️ ERRO: Tem neto/neta mas não menciona filhos!');
        }
        hasError = true;
      }
    }

    if (hasError && kDebugMode) {
      debugPrint(
        '❌ BLOCO $blockNumber REJEITADO: Relacionamentos familiares inconsistentes!',
      );
    }

    return !hasError;
  }

  /// 🔍 v7.6.28-34: Valida se há nomes duplicados em papéis diferentes
  /// Retorna TRUE se houver conflito (bloco deve ser rejeitado)
  bool validateUniqueNames(
    String blockText,
    CharacterTracker tracker,
    int blockNumber,
  ) {
    if (blockText.trim().isEmpty) return false;

    final namesInBlock = NameValidator.extractNamesFromText(blockText);

    for (final name in namesInBlock) {
      // VALIDAÇÃO 1: MESMO NOME em PAPÉIS DIFERENTES
      if (tracker.hasName(name)) {
        final currentRole = RolePatterns.extractRoleForName(name, blockText);
        final previousRole = tracker.getRole(name);

        if (currentRole != null && previousRole != null) {
          final normalizedCurrent = RolePatterns.normalizeRoleSelective(
            currentRole,
          );
          final normalizedPrevious = RolePatterns.normalizeRoleSelective(
            previousRole,
          );

          if (normalizedCurrent != normalizedPrevious &&
              normalizedCurrent != 'indefinido' &&
              normalizedPrevious != 'indefinido') {
            if (kDebugMode) {
              debugPrint('⚠️ v7.6.28: NOME DUPLICADO: "$name"');
              debugPrint('   Papel anterior: "$previousRole"');
              debugPrint('   Papel atual: "$currentRole"');
            }

            _debugLogger.error(
              "Nome duplicado em papéis diferentes - Bloco $blockNumber",
              blockNumber: blockNumber,
              details:
                  "Nome '$name': anterior '$previousRole', atual '$currentRole'",
              metadata: {
                'nome': name,
                'papelAnterior': previousRole,
                'papelAtual': currentRole,
              },
            );

            return true;
          }
        }
      }

      // VALIDAÇÃO 2: MESMO PAPEL em NOMES DIFERENTES
      final currentRole = RolePatterns.extractRoleForName(name, blockText);

      if (currentRole != null && currentRole != 'indefinido') {
        final normalizedCurrent = RolePatterns.normalizeRoleSelective(
          currentRole,
        );

        for (final existingName in tracker.confirmedNames) {
          if (existingName.toLowerCase() == name.toLowerCase()) continue;

          final existingRole = tracker.getRole(existingName);
          if (existingRole == null) continue;

          final normalizedExisting = RolePatterns.normalizeRoleSelective(
            existingRole,
          );

          final uniqueRoles = {
            'protagonista',
            'protagonist',
            'main character',
            'narradora',
            'narrador',
            'narrator',
            'hero',
            'heroine',
            'herói',
            'heroína',
          };

          if (normalizedCurrent == normalizedExisting) {
            bool isCriticalRole = uniqueRoles.any(
              (r) =>
                  normalizedCurrent.contains(r) ||
                  normalizedExisting.contains(r),
            );

            if (isCriticalRole) {
              if (kDebugMode) {
                debugPrint('⚠️ v7.6.32: PAPEL DUPLICADO: "$currentRole"');
                debugPrint('   Nome anterior: "$existingName"');
                debugPrint('   Nome atual: "$name"');
              }

              _debugLogger.error(
                "Papel duplicado com nomes diferentes - Bloco $blockNumber",
                blockNumber: blockNumber,
                details:
                    "Papel '$currentRole': anterior '$existingName', atual '$name'",
                metadata: {
                  'papel': currentRole,
                  'nomeAnterior': existingName,
                  'nomeAtual': name,
                },
              );

              return true;
            }
          }
        }
      }

      // VALIDAÇÃO 3: PAPÉIS POSSESSIVOS SINGULARES
      final possessiveSingularPattern = RegExp(
        r'\b(?:my|nossa)\s+(?:executive\s+assistant|personal\s+assistant|financial\s+advisor|real\s+estate\s+agent|estate\s+planner|tax\s+advisor|makeup\s+artist|physical\s+therapist|occupational\s+therapist|speech\s+therapist|au\s+pair|dalai\s+lama|vice[-\s]president|lawyer|attorney|doctor|therapist|accountant|agent|boss|mentor|partner|adviser|advisor|consultant|coach|teacher|tutor|counselor|psychologist|psychiatrist|dentist|surgeon|specialist|physician|nurse|caregiver|assistant|secretary|manager|supervisor|director|ceo|cfo|cto|president|chairman|investor|banker|auditor|notary|mediator|arbitrator|investigator|detective|officer|sergeant|captain|lieutenant|judge|magistrate|prosecutor|defender|guardian|curator|executor|trustee|beneficiary|architect|engineer|contractor|builder|designer|decorator|landscaper|gardener|housekeeper|maid|butler|chef|cook|driver|chauffeur|pilot|navigator|guide|translator|interpreter|editor|publisher|producer|publicist|stylist|hairdresser|barber|beautician|esthetician|masseuse|trainer|nutritionist|dietitian|pharmacist|optometrist|veterinarian|groomer|walker|sitter|nanny|governess|babysitter|midwife|doula|chiropractor|acupuncturist|hypnotist|healer|shaman|priest|pastor|minister|rabbi|imam|monk|nun|chaplain|deacon|elder|bishop|archbishop|cardinal|pope|guru|sensei|sifu|master|grandmaster)(?![a-z])',
        caseSensitive: false,
      );

      final possessiveMatches = possessiveSingularPattern.allMatches(blockText);

      for (final match in possessiveMatches) {
        final possessiveRole = match
            .group(0)
            ?.replaceFirst(
              RegExp(r'\b(?:my|nossa)\s+', caseSensitive: false),
              '',
            )
            .toLowerCase()
            .trim();

        if (possessiveRole == null || possessiveRole.isEmpty) continue;

        for (final existingName in tracker.confirmedNames) {
          if (existingName.toLowerCase() == name.toLowerCase()) continue;

          final existingRole = tracker.getRole(existingName);
          if (existingRole == null) continue;

          final normalizedExisting = RolePatterns.normalizeRoleSelective(
            existingRole,
          ).toLowerCase();
          final possessiveRoleNormalized = possessiveRole.replaceAll(
            RegExp(r'\s+'),
            ' ',
          );

          if (normalizedExisting.contains(possessiveRoleNormalized) ||
              possessiveRoleNormalized.contains(
                normalizedExisting.split(' ').last,
              )) {
            if (kDebugMode) {
              debugPrint(
                '⚠️ v7.6.34: PAPEL POSSESSIVO DUPLICADO: "my $possessiveRole"',
              );
              debugPrint('   Nome anterior: "$existingName"');
              debugPrint('   Nome atual: "$name"');
            }

            _debugLogger.error(
              "Papel possessivo singular duplicado - Bloco $blockNumber",
              blockNumber: blockNumber,
              details:
                  "'my $possessiveRole': anterior '$existingName', atual '$name'",
              metadata: {
                'papelPossessivo': possessiveRole,
                'nomeAnterior': existingName,
                'nomeAtual': name,
              },
            );

            return true;
          }
        }
      }
    }

    return false;
  }

  /// 🔍 Valida reutilização de nomes (debug/logging)
  void validateNameReuse(
    String generatedText,
    CharacterTracker tracker,
    int blockNumber,
  ) {
    final namePattern = RegExp(
      r'\b([A-ZÀÁÂÃÄÅÇÈÉÊËÌÍÎÏa-zàáâãäåçèéêëìíîï]{2,})\b',
    );
    final foundNames = <String>{};

    for (final match in namePattern.allMatches(generatedText)) {
      final name = match.group(1)?.trim();
      if (name != null && NameValidator.looksLikePersonName(name)) {
        foundNames.add(name);
      }
    }

    for (final name in foundNames) {
      if (tracker.hasName(name)) {
        final existingRole = tracker.getRole(name);
        final currentRole = RolePatterns.extractRoleForName(
          name,
          generatedText,
        );

        if (currentRole != null) {
          if (existingRole == null || existingRole == 'indefinido') {
            if (kDebugMode) {
              debugPrint(
                '📝 Nome "$name" definido como $currentRole (bloco $blockNumber)',
              );
            }
          } else if (!RolePatterns.areRolesEquivalent(
            currentRole,
            existingRole,
          )) {
            _debugLogger.error(
              "Reutilização de nome: '$name'",
              blockNumber: blockNumber,
              details:
                  "Papel anterior: $existingRole, Papel atual: $currentRole",
              metadata: {
                'nome': name,
                'papelAnterior': existingRole,
                'papelAtual': currentRole,
              },
            );

            if (kDebugMode) {
              debugPrint('❌ ERRO: Nome "$name" reutilizado!');
              debugPrint('   Papel anterior: $existingRole');
              debugPrint('   Papel atual: $currentRole');
            }
          }
        }
      }
    }

    _debugLogger.validation(
      "Validação de reutilização completa",
      blockNumber: blockNumber,
      details: "${foundNames.length} nomes verificados",
      metadata: {'nomesVerificados': foundNames.length},
    );
  }

  /// 🔍 Valida relações familiares (debug/logging)
  void validateFamilyRelations(String generatedText, int blockNumber) {
    final namePattern = RegExp(
      r'\b([A-ZÀÁÂÃÄÅÇÈÉÊËÌÍÎÏ][a-zàáâãäåçèéêëìíîï]{2,})\b',
    );
    final names = <String>{};

    for (final match in namePattern.allMatches(generatedText)) {
      final name = match.group(1)?.trim();
      if (name != null && NameValidator.looksLikePersonName(name)) {
        names.add(name);
      }
    }

    for (final name in names) {
      final role = RolePatterns.extractRoleForName(name, generatedText);
      if (role != null && kDebugMode) {
        debugPrint(
          '📝 Nome "$name" detectado como: $role (bloco $blockNumber)',
        );
      }
    }
  }

  // 🔧 v7.6.102: Extraído de gemini_service.dart
  /// 🔍 Detecta mudanças de nomes de personagens no texto gerado
  /// Retorna lista de mudanças detectadas com papel, nome antigo e novo
  List<Map<String, String>> detectCharacterNameChanges(
    String generatedText,
    CharacterTracker tracker,
    int blockNumber,
  ) {
    final changes = <Map<String, String>>[];

    // Padrões de relações familiares para detectar personagens
    final relationPatterns = {
      'pai': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Pp]ai(?:,)?\s+([A-ZÀÁÂÃÉÊÍÓÔÕÚÇ][a-zàáâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'mãe': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Mm]ãe(?:,)?\s+([A-ZÀÁÂÃÉÊÍÓÔÕÚÇ][a-zàáâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'marido': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:marido|esposo)(?:,)?\s+([A-ZÀÁÂÃÉÊÍÓÔÕÚÇ][a-zàáâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'esposa': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:esposa|mulher)(?:,)?\s+([A-ZÀÁÂÃÉÊÍÓÔÕÚÇ][a-zàáâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'filho': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Ff]ilho(?:,)?\s+([A-ZÀÁÂÃÉÊÍÓÔÕÚÇ][a-zàáâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'filha': RegExp(
        r'(?:minha|sua|nossa|a)\s+[Ff]ilha(?:,)?\s+([A-ZÀÁÂÃÉÊÍÓÔÕÚÇ][a-zàáâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'irmão': RegExp(
        r'(?:meu|seu|nosso|o)\s+(?:irmão|irmao)(?:,)?\s+([A-ZÀÁÂÃÉÊÍÓÔÕÚÇ][a-zàáâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'irmã': RegExp(
        r'(?:minha|sua|nossa|a)\s+(?:irmã|irma)(?:,)?\s+([A-ZÀÁÂÃÉÊÍÓÔÕÚÇ][a-zàáâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'advogado': RegExp(
        r'(?:meu|seu|nosso|o)\s+[Aa]dvogad[oa](?:,)?\s+([A-ZÀÁÂÃÉÊÍÓÔÕÚÇ][a-zàáâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
      'investigador': RegExp(
        r'(?:o|um)\s+[Ii]nvestigador(?:,)?\s+([A-ZÀÁÂÃÉÊÍÓÔÕÚÇ][a-zàáâãéêíóôõúç]+)',
        caseSensitive: false,
      ),
    };

    // Para cada papel rastreado, verificar se o nome mudou
    for (final entry in relationPatterns.entries) {
      final role = entry.key;
      final pattern = entry.value;
      final matches = pattern.allMatches(generatedText);

      for (final match in matches) {
        final newName = match.group(1)?.trim();
        if (newName == null || !NameValidator.looksLikePersonName(newName)) {
          continue;
        }

        // Verificar se este papel já tem um nome no tracker
        final existingName = tracker.getNameForRole(role);

        if (existingName != null && existingName != newName) {
          // ⚠️ MUDANÇA DETECTADA!
          changes.add({
            'role': role,
            'oldName': existingName,
            'newName': newName,
          });

          if (kDebugMode) {
            debugPrint(
              '⚠️ MUDANÇA DE NOME: "$role" era "$existingName" → agora "$newName"!',
            );
          }
        }
      }
    }

    return changes;
  }

  // 🔧 v7.6.103: Extraído de gemini_service.dart
  /// 🔧 Atualiza tracker com nomes do snippet, RETORNA FALSE se houve conflito de papel
  bool updateTrackerFromContextSnippet(
    CharacterTracker tracker,
    ScriptConfig config,
    String snippet,
  ) {
    if (snippet.trim().isEmpty) return true; // Snippet vazio = sem erro

    bool hasRoleConflict = false;

    final existingLower = tracker.confirmedNames
        .map((n) => n.toLowerCase())
        .toSet();
    final locationLower = config.localizacao.trim().toLowerCase();
    final candidateCounts = NameValidator.extractNamesFromSnippet(snippet);

    candidateCounts.forEach((name, count) {
      final normalized = name.toLowerCase();
      if (existingLower.contains(normalized)) return;

      if (locationLower.isNotEmpty && normalized == locationLower) return;
      if (NameConstants.isStopword(normalized)) return;

      // v7.6.63: Validação estrutural (aceita nomes do LLM)
      if (!NameValidator.isLikelyName(name)) {
        if (kDebugMode) {
          debugPrint('Tracker ignorou texto invalido: "$name"');
        }
        return;
      }

      // ✅ CORREÇÃO BUG ALBERTO: Extrair papel antes de adicionar
      final role = RolePatterns.extractRoleForName(name, snippet);

      if (role != null) {
        final success = tracker.addName(name, role: role);
        if (kDebugMode) {
          if (success) {
            debugPrint(
              '✅ Tracker adicionou personagem COM PAPEL: "$name" = "$role" (ocorrências: $count)',
            );
          } else {
            debugPrint('❌ CONFLITO DE PAPEL detectado!');
            debugPrint('   Nome: "$name"');
            debugPrint('   Papel tentado: "$role"');
            hasRoleConflict = true;
          }
        }
      } else {
        tracker.addName(name, role: 'indefinido');
        if (kDebugMode) {
          debugPrint(
            '📝 Tracker adicionou personagem SEM PAPEL: "$name" (indefinido - ocorrências: $count)',
          );
        }
      }
      if (kDebugMode) {
        debugPrint(
          '📝 Tracker adicionou personagem detectado: $name (ocorrências: $count)',
        );
      }
    });

    return !hasRoleConflict; // ✅ true = OK, ❌ false = ERRO
  }
}
