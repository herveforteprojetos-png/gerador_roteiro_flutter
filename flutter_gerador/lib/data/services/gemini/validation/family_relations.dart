import 'package:flutter/foundation.dart';
import 'package:flutter_gerador/data/services/gemini/validation/name_validator.dart';

/// 👨‍👩‍👧‍👦 Validador de relações familiares - detecta inconsistências
class FamilyRelationsValidator {
  /// Valida relações familiares em um texto
  /// Detecta inconsistências como "meu pai Francisco" e "meu marido Francisco"
  static void validate(
    String generatedText,
    int blockNumber, {
    void Function(String, String)? onError,
  }) {
    // Extrair nomes mencionados no texto
    final names = NameValidator.extractNamesFromText(generatedText);

    // Para cada nome, verificar se aparece com múltiplas relações conflitantes
    for (final name in names) {
      final relations = _findRelationsForName(name, generatedText);

      if (relations.length < 2) continue;

      // 🚨 DETECTAR CONFLITOS: Mesmo nome com relações incompatíveis
      final conflicts = _detectRelationConflicts(relations);

      if (conflicts.isNotEmpty) {
        final errorMessage =
            "Nome '$name' aparece como: ${relations.join(', ')}\n"
            "Conflito: ${conflicts.join(', ')}";

        if (onError != null) {
          onError("Confusão em relação familiar: '$name'", errorMessage);
        }

        if (kDebugMode) {
          debugPrint(
            '🚨🚨🚨 ERRO CRÍTICO DE RELAÇÃO FAMILIAR - BLOCO $blockNumber 🚨🚨🚨',
          );
          debugPrint('   ❌ Nome "$name" tem relações conflitantes!');
          debugPrint('   📋 Relações encontradas: ${relations.join(", ")}');
          debugPrint('   ⚠️ Conflitos: ${conflicts.join(", ")}');
          debugPrint(
            '   💡 SOLUÇÃO: Definir claramente se é pai, marido, filho, etc.',
          );
          debugPrint('🚨🚨🚨 FIM DO ALERTA DE RELAÇÃO FAMILIAR 🚨🚨🚨');
        }
      }
    }
  }

  /// Encontra todas as relações familiares de um nome em um texto
  static List<String> _findRelationsForName(String name, String text) {
    final relations = <String>[];

    // Padrões de relações familiares
    final relationPatterns = {
      'pai': RegExp(
        '(?:meu|seu|nosso|o)\\s+[Pp]ai(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'mãe': RegExp(
        '(?:minha|sua|nossa|a)\\s+[Mm]ãe(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'marido': RegExp(
        '(?:meu|seu|nosso|o)\\s+(?:marido|esposo)(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'esposa': RegExp(
        '(?:minha|sua|nossa|a)\\s+(?:esposa|mulher)(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'filho': RegExp(
        '(?:meu|seu|nosso|o)\\s+[Ff]ilho(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'filha': RegExp(
        '(?:minha|sua|nossa|a)\\s+[Ff]ilha(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'irmão': RegExp(
        '(?:meu|seu|nosso|o)\\s+(?:irmão|irmao)(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'irmã': RegExp(
        '(?:minha|sua|nossa|a)\\s+(?:irmã|irma)(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'tio': RegExp(
        '(?:meu|seu|o)\\s+[Tt]io(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'tia': RegExp(
        '(?:minha|sua|a)\\s+[Tt]ia(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'avô': RegExp(
        '(?:meu|seu|o)\\s+avô(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'avó': RegExp(
        '(?:minha|sua|a)\\s+avó(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'neto': RegExp(
        '(?:meu|seu|o)\\s+neto(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'neta': RegExp(
        '(?:minha|sua|a)\\s+neta(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'sogro': RegExp(
        '(?:meu|seu|o)\\s+sogro(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'sogra': RegExp(
        '(?:minha|sua|a)\\s+sogra(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'cunhado': RegExp(
        '(?:meu|seu|o)\\s+cunhado(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'cunhada': RegExp(
        '(?:minha|sua|a)\\s+cunhada(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'genro': RegExp(
        '(?:meu|seu|o)\\s+genro(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'nora': RegExp(
        '(?:minha|sua|a)\\s+nora(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'primo': RegExp(
        '(?:meu|seu|o)\\s+primo(?:,)?\\s+$name',
        caseSensitive: false,
      ),
      'prima': RegExp(
        '(?:minha|sua|a)\\s+prima(?:,)?\\s+$name',
        caseSensitive: false,
      ),
    };

    // Verificar quais relações aparecem para este nome
    for (final entry in relationPatterns.entries) {
      if (entry.value.hasMatch(text)) {
        relations.add(entry.key);
      }
    }

    return relations;
  }

  /// Detecta conflitos entre relações familiares
  /// Retorna lista de descrições de conflitos encontrados
  static List<String> _detectRelationConflicts(List<String> relations) {
    final conflicts = <String>[];

    if (relations.length < 2) {
      return conflicts; // Sem conflito se há apenas 1 relação
    }

    // Grupos de relações mutuamente exclusivas
    final exclusiveGroups = [
      {
        'pai',
        'marido',
        'filho',
        'irmão',
        'tio',
        'avô',
        'neto',
        'sogro',
        'cunhado',
        'genro',
        'primo',
      },
      {
        'mãe',
        'esposa',
        'filha',
        'irmã',
        'tia',
        'avó',
        'neta',
        'sogra',
        'cunhada',
        'nora',
        'prima',
      },
      {'pai', 'mãe'}, // Pais não podem ser a mesma pessoa
      {'marido', 'esposa'}, // Cônjuges não podem ser a mesma pessoa
      {'filho', 'pai'}, // Filho não pode ser pai do narrador
      {'filha', 'mãe'}, // Filha não pode ser mãe do narrador
      {'avô', 'neto'}, // Avô não pode ser neto
      {'avó', 'neta'}, // Avó não pode ser neta
      {'sogro', 'genro'}, // Sogro não pode ser genro
      {'sogra', 'nora'}, // Sogra não pode ser nora
    ];

    for (final group in exclusiveGroups) {
      final found = relations.where((r) => group.contains(r)).toList();
      if (found.length > 1) {
        conflicts.add('${found.join(" + ")} são incompatíveis');
      }
    }

    return conflicts;
  }

  /// Valida se o mesmo nome de família não está sendo usado duas vezes
  /// Exemplo: "Mônica" (protagonista) e "minha irmã Mônica" = ERRO
  static bool hasDuplicateFamilyName(
    String name,
    String role,
    Map<String, String> existingNames,
  ) {
    if (existingNames.containsKey(name)) {
      final existingRole = existingNames[name];
      if (existingRole != role) {
        if (kDebugMode) {
          debugPrint('🚨 NOME DE FAMÍLIA DUPLICADO:');
          debugPrint('   Nome: "$name"');
          debugPrint('   Papel existente: "$existingRole"');
          debugPrint('   Novo papel: "$role"');
          debugPrint(
            '   ⚠️ Membros da mesma família não podem ter o mesmo nome!',
          );
        }
        return true;
      }
    }
    return false;
  }
}
