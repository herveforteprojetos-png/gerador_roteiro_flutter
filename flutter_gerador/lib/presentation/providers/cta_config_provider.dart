import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/cta_config.dart';
import '../../data/services/gemini_service.dart';
import 'script_config_provider.dart';

/// Provider for CTA configuration management
class CtaConfigNotifier extends StateNotifier<CtaConfig> {
  final Ref ref;
  
  CtaConfigNotifier(this.ref) : super(CtaConfig.empty()) {
    _loadConfiguration();
  }

  /// Storage key for CTA configuration
  static const String _storageKey = 'cta_config';

  /// Load CTA configuration from storage
  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null) {
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        state = CtaConfig.fromJson(jsonData);
      } else {
        // Initialize with default configuration if no saved config exists
        state = CtaConfig.withDefaults();
        await _saveConfiguration();
      }
    } catch (e) {
      // If loading fails, use default configuration
      state = CtaConfig.withDefaults();
      await _saveConfiguration();
    }
  }

  /// Save current configuration to storage
  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // Handle save error silently for now
      // In production, you might want to show a snackbar or log the error
    }
  }

  /// Toggle global CTA enable/disable
  Future<void> toggleEnabled() async {
    state = state.copyWith(isEnabled: !state.isEnabled);
    await _saveConfiguration();
  }

  /// Add a new automatic CTA
  Future<void> addAutomaticCta({
    required String title,
    required CtaPosition position,
    int? customPositionPercentage,
  }) async {
    if (!state.canAddMore) {
      throw Exception('Máximo de ${state.maxCtas} CTAs atingido');
    }

    final newCta = CtaItem.createAutomatic(
      title: title,
      position: position,
      customPositionPercentage: customPositionPercentage,
    );

    state = state.addCta(newCta);
    await _saveConfiguration();
  }

  /// Add a new manual CTA
  Future<void> addManualCta({
    required String title,
    required String content,
    required CtaPosition position,
    int? customPositionPercentage,
  }) async {
    if (!state.canAddMore) {
      throw Exception('Máximo de ${state.maxCtas} CTAs atingido');
    }

    final newCta = CtaItem.createManual(
      title: title,
      content: content,
      position: position,
      customPositionPercentage: customPositionPercentage,
    );

    state = state.addCta(newCta);
    await _saveConfiguration();
  }

  /// Update an existing CTA
  Future<void> updateCta(String ctaId, CtaItem updatedCta) async {
    state = state.updateCta(ctaId, updatedCta);
    await _saveConfiguration();
  }

  /// Remove a CTA
  Future<void> removeCta(String ctaId) async {
    state = state.removeCta(ctaId);
    await _saveConfiguration();
  }

  /// Toggle CTA enabled state
  Future<void> toggleCtaEnabled(String ctaId) async {
    final cta = state.ctas.firstWhere((c) => c.id == ctaId);
    final updatedCta = cta.copyWith(isEnabled: !cta.isEnabled);
    await updateCta(ctaId, updatedCta);
  }

  /// Update CTA content (for automatic CTAs after generation)
  Future<void> updateCtaContent(String ctaId, String content) async {
    final cta = state.ctas.firstWhere((c) => c.id == ctaId);
    final updatedCta = cta.copyWith(content: content);
    await updateCta(ctaId, updatedCta);
  }

  /// Update CTA position
  Future<void> updateCtaPosition(String ctaId, CtaPosition position, {int? customPositionPercentage}) async {
    final cta = state.ctas.firstWhere((c) => c.id == ctaId);
    final updatedCta = cta.copyWith(
      position: position,
      customPositionPercentage: customPositionPercentage,
    );
    await updateCta(ctaId, updatedCta);
  }

  /// Update CTA generation type
  Future<void> updateCtaGenerationType(String ctaId, CtaGenerationType generationType) async {
    final cta = state.ctas.firstWhere((c) => c.id == ctaId);
    final updatedCta = cta.copyWith(
      generationType: generationType,
      // Clear content if switching to automatic
      content: generationType == CtaGenerationType.automatic ? '' : cta.content,
    );
    await updateCta(ctaId, updatedCta);
  }

  /// Reorder CTAs
  Future<void> reorderCtas(int oldIndex, int newIndex) async {
    final ctas = List<CtaItem>.from(state.ctas);
    
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    final cta = ctas.removeAt(oldIndex);
    ctas.insert(newIndex, cta);
    
    state = state.copyWith(ctas: ctas);
    await _saveConfiguration();
  }

  /// Clear all CTAs
  Future<void> clearAllCtas() async {
    state = state.copyWith(ctas: []);
    await _saveConfiguration();
  }

  /// Reset to default configuration
  Future<void> resetToDefault() async {
    state = CtaConfig.withDefaults();
    await _saveConfiguration();
  }

  /// Duplicate a CTA
  Future<void> duplicateCta(String ctaId) async {
    if (!state.canAddMore) {
      throw Exception('Máximo de ${state.maxCtas} CTAs atingido');
    }

    final originalCta = state.ctas.firstWhere((c) => c.id == ctaId);
    final now = DateTime.now();
    
    final duplicatedCta = CtaItem(
      id: 'cta_${now.millisecondsSinceEpoch}',
      isEnabled: originalCta.isEnabled,
      title: '${originalCta.title} (Cópia)',
      content: originalCta.content,
      position: originalCta.position,
      generationType: originalCta.generationType,
      customPositionPercentage: originalCta.customPositionPercentage,
      createdAt: now,
      updatedAt: now,
    );

    state = state.addCta(duplicatedCta);
    await _saveConfiguration();
  }

  /// Get CTAs by position
  List<CtaItem> getCtasByPosition(CtaPosition position) {
    return state.enabledCtas.where((cta) => cta.position == position).toList();
  }

  /// Get CTAs that need generation
  List<CtaItem> getCtasNeedingGeneration() {
    return state.ctasNeedingGeneration;
  }

  /// Check if position is available (for validation)
  bool isPositionAvailable(CtaPosition position) {
    if (position == CtaPosition.custom) return true;
    return !state.enabledCtas.any((cta) => cta.position == position);
  }

  /// Import CTA configuration from JSON
  Future<void> importConfiguration(Map<String, dynamic> jsonData) async {
    try {
      final importedConfig = CtaConfig.fromJson(jsonData);
      state = importedConfig;
      await _saveConfiguration();
    } catch (e) {
      throw Exception('Erro ao importar configuração: $e');
    }
  }

  /// Export current configuration to JSON
  Map<String, dynamic> exportConfiguration() {
    return state.toJson();
  }
  /// Generate automatic CTAs based on script content
  Future<void> generateAutomaticCtas({
    required String scriptContent,
    required String apiKey,
    String? customTheme,
  }) async {
    try {
      // Get CTAs that need generation (automatic type with empty content)
      final ctasToGenerate = state.ctasNeedingGeneration;
      
      if (ctasToGenerate.isEmpty) return;
      
      // Map CTA positions to types for Gemini
      final ctaTypes = <String>[];
      final ctaIdMap = <String, String>{};
      
      for (final cta in ctasToGenerate) {
        String ctaType;
        switch (cta.position) {
          case CtaPosition.beginning:
            ctaType = 'subscription';
            break;
          case CtaPosition.middle:
            ctaType = 'engagement';
            break;
          case CtaPosition.end:
            final isLastCta = ctasToGenerate.where((c) => c.position == CtaPosition.end).length == 1;
            ctaType = isLastCta ? 'final' : 'pre_conclusion';
            break;
          case CtaPosition.custom:
            // Determine type based on custom position percentage
            final percentage = cta.customPositionPercentage ?? 50;
            if (percentage <= 25) {
              ctaType = 'subscription';
            } else if (percentage <= 50) {
              ctaType = 'engagement';
            } else if (percentage <= 80) {
              ctaType = 'pre_conclusion';
            } else {
              ctaType = 'final';
            }
            break;
        }
        
        ctaTypes.add(ctaType);
        ctaIdMap[ctaType] = cta.id;
      }
      
      // Generate CTAs using Gemini
      final geminiService = GeminiService();
      final scriptConfig = ref.read(scriptConfigProvider);
      
      print('🎯 [CTA Provider] Gerando CTAs - Tipos solicitados: $ctaTypes');
      print('🎯 [CTA Provider] Mapa de IDs: $ctaIdMap');
      
      // 🎯 v7.6.51: Pipeline Modelo Único - usar mesmo modelo do config
      final generatedCtas = await geminiService.generateCtasForScript(
        scriptContent: scriptContent,
        apiKey: apiKey,
        ctaTypes: ctaTypes,
        customTheme: customTheme,
        language: scriptConfig.language,
        perspective: scriptConfig.perspective, // ⚡ PASSAR PERSPECTIVA CONFIGURADA
        qualityMode: scriptConfig.qualityMode, // 🎯 v7.6.51: Pipeline Modelo Único
      );
      
      print('🎯 [CTA Provider] CTAs recebidos do Gemini: ${generatedCtas.keys.toList()}');
      print('🎯 [CTA Provider] Total de CTAs: ${generatedCtas.length}');
      generatedCtas.forEach((key, value) {
        print('🎯 [CTA Provider] $key: ${value.substring(0, value.length > 50 ? 50 : value.length)}...');
      });
      
      // Update CTAs with generated content
      final updatedCtas = <CtaItem>[];
      for (final cta in state.ctas) {
        if (ctasToGenerate.any((c) => c.id == cta.id)) {
          // Find the generated content for this CTA
          String? generatedContent;
          for (final entry in ctaIdMap.entries) {
            if (entry.value == cta.id && generatedCtas.containsKey(entry.key)) {
              generatedContent = generatedCtas[entry.key];
              print('✅ [CTA Provider] Match encontrado: ${entry.key} → ${cta.title}');
              break;
            }
          }
          
          if (generatedContent != null) {
            print('✅ [CTA Provider] Atualizando CTA "${cta.title}" com conteúdo gerado');
            updatedCtas.add(cta.copyWith(content: generatedContent));
          } else {
            print('⚠️ [CTA Provider] Nenhum conteúdo gerado para CTA "${cta.title}"');
            updatedCtas.add(cta);
          }
        } else {
          updatedCtas.add(cta);
        }
      }
      
      state = state.copyWith(ctas: updatedCtas);
      await _saveConfiguration();
      
    } catch (e) {
      // Handle generation error - could show user feedback
      throw Exception('Erro ao gerar CTAs automáticos: ${e.toString()}');
    }
  }

  /// Generate content for a specific CTA
  Future<void> generateCtaContent({
    required String ctaId,
    required String scriptContent,
    required String apiKey,
    String? customTheme,
  }) async {
    try {
      final cta = state.ctas.firstWhere((c) => c.id == ctaId);
      
      // Determine CTA type based on position
      String ctaType;
      switch (cta.position) {
        case CtaPosition.beginning:
          ctaType = 'subscription';
          break;
        case CtaPosition.middle:
          ctaType = 'engagement';
          break;
        case CtaPosition.end:
          ctaType = 'final';
          break;
        case CtaPosition.custom:
          final percentage = cta.customPositionPercentage ?? 50;
          if (percentage <= 30) {
            ctaType = 'subscription';
          } else if (percentage <= 70) {
            ctaType = 'engagement';
          } else {
            ctaType = 'final';
          }
          break;
      }
      
      // Generate single CTA
      final geminiService = GeminiService();
      final scriptConfig = ref.read(scriptConfigProvider);
      // 🎯 v7.6.51: Pipeline Modelo Único - usar mesmo modelo do config
      final generatedCtas = await geminiService.generateCtasForScript(
        scriptContent: scriptContent,
        apiKey: apiKey,
        ctaTypes: [ctaType],
        customTheme: customTheme,
        language: scriptConfig.language,
        perspective: scriptConfig.perspective, // ⚡ PASSAR PERSPECTIVA CONFIGURADA
        qualityMode: scriptConfig.qualityMode, // 🎯 v7.6.51: Pipeline Modelo Único
      );
      
      final generatedContent = generatedCtas[ctaType];
      if (generatedContent != null) {
        await updateCtaContent(ctaId, generatedContent);
      }
      
    } catch (e) {
      throw Exception('Erro ao gerar conteúdo do CTA: ${e.toString()}');
    }
  }

  /// Batch generate all automatic CTAs that need content
  Future<void> regenerateAllAutomaticCtas({
    required String scriptContent,
    required String apiKey,
    String? customTheme,
  }) async {
    // Set all automatic CTAs to empty content to trigger regeneration
    final updatedCtas = state.ctas.map((cta) {
      if (cta.generationType == CtaGenerationType.automatic) {
        return cta.copyWith(content: '');
      }
      return cta;
    }).toList();
    
    state = state.copyWith(ctas: updatedCtas);
    
    // Generate new content for all automatic CTAs
    await generateAutomaticCtas(
      scriptContent: scriptContent,
      apiKey: apiKey,
      customTheme: customTheme,
    );
  }
}

/// Provider for CTA configuration
final ctaConfigProvider = StateNotifierProvider<CtaConfigNotifier, CtaConfig>((ref) {
  return CtaConfigNotifier(ref);
});

/// Provider for enabled CTAs only
final enabledCtasProvider = Provider<List<CtaItem>>((ref) {
  final config = ref.watch(ctaConfigProvider);
  return config.enabledCtas;
});

/// Provider for CTAs needing generation
final ctasNeedingGenerationProvider = Provider<List<CtaItem>>((ref) {
  final config = ref.watch(ctaConfigProvider);
  return config.ctasNeedingGeneration;
});

/// Provider for checking if more CTAs can be added
final canAddMoreCtasProvider = Provider<bool>((ref) {
  final config = ref.watch(ctaConfigProvider);
  return config.canAddMore;
});

/// Provider for available CTA slots
final availableCtaSlotsProvider = Provider<int>((ref) {
  final config = ref.watch(ctaConfigProvider);
  return config.availableSlots;
});