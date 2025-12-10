// 🏗️ v7.6.75: CharacterGuidanceBuilder - Módulo SOLID para construção de guidance
// Extrai lógica de _buildCharacterGuidance e _extractCharacterHintsFromTitle do GeminiService
// Princípio: Single Responsibility - apenas construção de guidance de personagens

import 'package:flutter/foundation.dart';
import '../../../models/script_config.dart';
import '../../prompts/base_rules.dart';
import '../tracking/character_tracker.dart';
import '../validation/name_validator.dart';

/// Construtor de guidance para personagens estabelecidos
/// Responsável por:
/// - Construir texto de guidance para o prompt
/// - Extrair hints de personagens do título
class CharacterGuidanceBuilder {
  /// Constrói o texto de guidance para personagens estabelecidos
  /// [config] - Configuração do roteiro com nomes de personagens
  /// [tracker] - Tracker com nomes confirmados ao longo da geração
  static String buildGuidance(ScriptConfig config, CharacterTracker tracker) {
    final lines = <String>[];
    final baseNames = <String>{};

    final protagonist = config.protagonistName.trim();
    if (protagonist.isNotEmpty) {
      final translatedProtagonist = BaseRules.translateFamilyTerms(
        config.language,
        protagonist,
      );
      lines.add(
        '- Protagonista: "$translatedProtagonist" → mantenha exatamente este nome e sua função.',
      );
      baseNames.add(protagonist.toLowerCase());
    }

    final secondary = config.secondaryCharacterName.trim();
    if (secondary.isNotEmpty) {
      final translatedSecondary = BaseRules.translateFamilyTerms(
        config.language,
        secondary,
      );
      lines.add(
        '- Personagem secundário: "$translatedSecondary" → preserve o mesmo nome em todos os blocos.',
      );
      baseNames.add(secondary.toLowerCase());
    }

    final additional =
        tracker.confirmedNames
            .where((n) => !baseNames.contains(n.toLowerCase()))
            .toList()
          ..sort((a, b) => a.compareTo(b));

    for (final name in additional) {
      // 🔧 CORRIGIDO: Adicionar personagens mencionados (não são hints de narrador)
      if (name.startsWith('PERSONAGEM MENCIONADO')) {
        // Remover marcador e traduzir termo familiar antes de adicionar ao prompt
        final cleanName = name.replaceFirst('PERSONAGEM MENCIONADO: ', '');
        final translatedName = BaseRules.translateFamilyTerms(
          config.language,
          cleanName,
        );
        lines.add(
          '- Personagem mencionado: $translatedName (manter como referência familiar)',
        );
      } else {
        final translatedName = BaseRules.translateFamilyTerms(
          config.language,
          name,
        );
        lines.add(
          '- Personagem estabelecido: "$translatedName" → não altere este nome nem invente apelidos.',
        );
      }
    }

    if (lines.isEmpty) return '';

    return 'PERSONAGENS ESTABELECIDOS:\n${lines.join('\n')}\nNunca substitua esses nomes por variações ou apelidos.\n';
  }

  /// Extrai hints de personagens do título e contexto
  /// Detecta: 1) Relações familiares e 2) Nomes próprios mencionados
  /// 🔧 CORRIGIDO: Extrair hints de gênero/relações APENAS como contexto, NÃO como narrador
  static Set<String> extractHintsFromTitle(String title, String context) {
    final hints = <String>{};
    if (title.trim().isEmpty) return hints;

    final titleLower = title.toLowerCase();
    final contextLower = context.toLowerCase();

    // 🎯 DETECTAR: 1) Relações familiares e 2) Nomes próprios mencionados no título

    // 1º RELAÇÕES FAMILIARES
    final charactersInTitle = {
      'mãe': 'PERSONAGEM MENCIONADO: Mãe',
      'pai': 'PERSONAGEM MENCIONADO: Pai',
      'filho': 'PERSONAGEM MENCIONADO: Filho',
      'filha': 'PERSONAGEM MENCIONADO: Filha',
      'esposa': 'PERSONAGEM MENCIONADO: Esposa',
      'marido': 'PERSONAGEM MENCIONADO: Marido',
      'irmã': 'PERSONAGEM MENCIONADO: Irmã',
      'irmão': 'PERSONAGEM MENCIONADO: Irmão',
      'avó': 'PERSONAGEM MENCIONADO: Avó',
      'avô': 'PERSONAGEM MENCIONADO: Avô',
      'tia': 'PERSONAGEM MENCIONADO: Tia',
      'tio': 'PERSONAGEM MENCIONADO: Tio',
    };

    for (final entry in charactersInTitle.entries) {
      if (titleLower.contains(entry.key) || contextLower.contains(entry.key)) {
        hints.add(entry.value);
        if (kDebugMode) {
          debugPrint(
            '🎭 Personagem detectado no título: ${entry.key} → ${entry.value}',
          );
        }
      }
    }

    // 2º NOMES PRÓPRIOS MENCIONADOS NO TÍTULO
    // Detectar padrões como: "Você é Michael?" ou "chamado João" ou "nome: Maria"
    final namePatterns = [
      RegExp(
        r'(?:é|chamad[oa]|nome:|sou)\s+([A-ZÁÉÍÓÚÀÂÃÊÔÇ][a-záéíóúàâãêôç]+(?:\s+[A-ZÁÉÍÓÚÀÂÃÊÔÇ][a-záéíóúàâãêôç]+)?)',
        caseSensitive: false,
      ),
      RegExp(r'"([A-ZÁÉÍÓÚÀÂÃÊÔÇ][a-záéíóúàâãêôç]+)"'), // Nomes entre aspas
      RegExp(
        r'protagonista\s+([A-ZÁÉÍÓÚÀÂÃÊÔÇ][a-záéíóúàâãêôç]+)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in namePatterns) {
      for (final match in pattern.allMatches(title)) {
        final name = match.group(1)?.trim() ?? '';
        if (NameValidator.looksLikePersonName(name) && name.length >= 3) {
          hints.add('NOME MENCIONADO NO TÍTULO: $name');
          if (kDebugMode) {
            debugPrint('🏷️ Nome próprio detectado no título: $name');
          }
        }
      }
    }

    return hints;
  }
}
