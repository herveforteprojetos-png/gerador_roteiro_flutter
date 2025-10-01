import 'package:flutter_gerador/data/models/script_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';
import 'package:flutter_gerador/data/services/gemini_service.dart';
import 'package:flutter_gerador/data/models/generation_config.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter/foundation.dart';
import 'cta_config_provider.dart';
import 'generation_config_provider.dart';
import 'script_config_provider.dart';
import '../../data/utils/cta_inserter.dart';

class ScriptGenerationState {
  final bool isGenerating;
  final GenerationProgress? progress;
  final ScriptResult? result;

  ScriptGenerationState({
    this.isGenerating = false,
    this.progress,
    this.result,
  });
}

class ScriptGenerationNotifier extends StateNotifier<ScriptGenerationState> {
  final GeminiService geminiService;
  final Ref ref;
  bool _cancelRequested = false;

  ScriptGenerationNotifier(this.geminiService, this.ref) : super(ScriptGenerationState());

  Future<void> generateScript(GenerationConfig config) async {
    if (kDebugMode) {
      debugPrint('\n');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎬 PROVIDER: generateScript() CHAMADO');
      debugPrint('   API Key: ${config.apiKey.substring(0, 10)}...');
      debugPrint('   Tema: ${config.tema}');
      debugPrint('   Quantidade: ${config.quantity} ${config.measureType}');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('\n');
    }
    
    // CORREÇÃO: Reset completo de estado antes de nova geração
    _cancelRequested = false;
    geminiService.resetState(); // Reset do estado interno do service
    
    // Limpar resultado anterior e definir estado inicial
    state = ScriptGenerationState(
      isGenerating: true,
      progress: null,
      result: null,
    );
    
    if (kDebugMode) {
      debugPrint('📊 PROVIDER: Estado inicial definido (isGenerating: true)');
    }
    
    try {
      if (kDebugMode) {
        debugPrint('🚀 PROVIDER: Chamando geminiService.generateScript()...');
      }
      
      final result = await geminiService.generateScript(
        ScriptConfig.fromGenerationConfig(config), 
        (progress) {
        if (_cancelRequested) return;
        
        if (kDebugMode) {
          debugPrint('📈 PROVIDER: Progresso recebido: ${progress.currentPhase}');
        }
        
        state = ScriptGenerationState(
          isGenerating: true,
          progress: progress,
        );
      });
      
      if (kDebugMode) {
        debugPrint('✅ PROVIDER: geminiService.generateScript() retornou');
        debugPrint('   Resultado: ${result.scriptText.length} caracteres');
        debugPrint('   Sucesso: ${result.success}');
        if (!result.success) {
          debugPrint('   ❌ ERRO: ${result.errorMessage}');
        }
      }
      
      if (!_cancelRequested) {
        // Gerar CTAs automáticos se habilitados
        ScriptResult finalResult = result;
        
        try {
          final ctaConfig = ref.read(ctaConfigProvider);
          if (ctaConfig.isEnabled && ctaConfig.ctasNeedingGeneration.isNotEmpty) {
            // Gerar CTAs automáticos
            final ctaNotifier = ref.read(ctaConfigProvider.notifier);
            final generationConfig = ref.read(generationConfigProvider);
            
            await ctaNotifier.generateAutomaticCtas(
              scriptContent: result.scriptText,
              apiKey: config.apiKey,
              customTheme: generationConfig.usePersonalizedTheme ? generationConfig.personalizedTheme : null,
            );
            
            // Inserir CTAs no roteiro
            final updatedCtaConfig = ref.read(ctaConfigProvider);
            final enabledCtas = updatedCtaConfig.enabledCtas
                .where((cta) => cta.content.isNotEmpty)
                .toList();
            
            if (enabledCtas.isNotEmpty) {
              final scriptWithCtas = CtaInserter.insertCtasIntoScript(
                scriptContent: result.scriptText,
                ctas: enabledCtas,
              );
              
              finalResult = ScriptResult(
                scriptText: scriptWithCtas,
                wordCount: _countWords(scriptWithCtas),
                charCount: scriptWithCtas.length,
                paragraphCount: scriptWithCtas.split('\n\n').length,
                readingTime: (_countWords(scriptWithCtas) / 200).ceil(), // ~200 wpm
                generationTime: result.generationTime,
                model: result.model,
                hasCtaIntegration: true,
              );
            }
          }
        } catch (e) {
          // Se a geração/inserção de CTAs falhar, use o resultado original
          if (kDebugMode) debugPrint('Erro ao processar CTAs: $e');
          // Manter resultado original se CTAs falharem
        }
        
        state = ScriptGenerationState(
          isGenerating: false,
          progress: null, // Limpar progresso
          result: finalResult,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PROVIDER: EXCEÇÃO CAPTURADA');
        debugPrint('   Erro: $e');
        debugPrint('   Stack trace:');
        debugPrint('$e');
      }
      
      if (!_cancelRequested) {
        state = ScriptGenerationState(
          isGenerating: false,
          progress: null, // Limpar progresso
          result: ScriptResult.error(
            errorMessage: 'Erro na geração: ${e.toString()}',
          ),
        );
      }
    } finally {
      if (kDebugMode) {
        debugPrint('🏁 PROVIDER: finally block executado');
      }
      // CORREÇÃO: Garantir que sempre resetamos o estado cancelado
      if (!_cancelRequested) {
        _cancelRequested = false;
      }
    }
  }

  void cancelGeneration() {
    if (kDebugMode) debugPrint('Cancelling generation...');
    _cancelRequested = true;
    geminiService.cancel(); // Chamar cancelamento no serviço
    state = ScriptGenerationState(isGenerating: false);
  }
  
  void forceReset() {
    if (kDebugMode) debugPrint('Force resetting generation state...');
    _cancelRequested = false;
    geminiService.resetState(); // Reset do service também
    state = ScriptGenerationState(
      isGenerating: false,
      progress: null,
      result: null,
    );
  }
  
  void clearResult() {
    if (kDebugMode) debugPrint('Clearing previous result...');
    if (state.isGenerating) return; // Não limpar se estiver gerando
    
    state = ScriptGenerationState(
      isGenerating: false,
      progress: null,
      result: null,
    );
  }

  /// Update the script text while preserving other result data
  void updateScriptText(String newScriptText) {
    if (state.result != null) {
      final updatedResult = ScriptResult(
        scriptText: newScriptText,
        wordCount: _countWords(newScriptText),
        charCount: newScriptText.length,
        paragraphCount: state.result!.paragraphCount,
        readingTime: state.result!.readingTime,
        success: state.result!.success,
        errorMessage: state.result!.errorMessage,
        generationTime: state.result!.generationTime,
        model: state.result!.model,
        hasCtaIntegration: state.result!.hasCtaIntegration,
      );
      
      state = ScriptGenerationState(
        isGenerating: false,
        progress: state.progress,
        result: updatedResult,
      );
    }
  }

  /// Apply CTAs to the current script
  void applyCtasToScript(List<String> ctas, dynamic position) {
    if (state.result != null && ctas.isNotEmpty) {
      String scriptWithCtas = state.result!.scriptText;
      
      // Handle both single position (String) and multiple positions (List<String>)
      if (position is String) {
        // Single position for all CTAs
        for (final cta in ctas) {
          scriptWithCtas = _insertCtaAtPosition(scriptWithCtas, cta, position);
        }
      } else if (position is List<String>) {
        // Multiple positions - apply CTAs based on positions
        for (int i = 0; i < ctas.length && i < position.length; i++) {
          final cta = ctas[i];
          final pos = position[i];
          
          scriptWithCtas = _insertCtaAtPosition(scriptWithCtas, cta, pos);
        }
      }
      
      // Update the script with CTAs
      updateScriptText(scriptWithCtas);
    }
  }
  
  /// Insert CTA at specific position in script
  String _insertCtaAtPosition(String script, String cta, String position) {
    final lines = script.split('\n');
    // Formato limpo e destacado sem emoticons
    final ctaWithMarkers = '\n▶ CTA - ${_getPositionLabel(position).toUpperCase()}\n$cta\n';
    
    switch (position.toLowerCase()) {
      case 'beginning':
        // CORRIGIDO: Inserir após conclusão do primeiro parágrafo ou introdução
        // Procurar pela primeira linha vazia após texto para inserir CTA mais cedo
        int insertIndex = 1;
        for (int i = 1; i < lines.length && i < 8; i++) { // Primeiras 8 linhas para aparecer mais cedo
          if (lines[i].trim().isEmpty && lines[i-1].trim().isNotEmpty) {
            insertIndex = i + 1;
            break;
          }
          // Se não encontrar linha vazia, inserir após a terceira linha de texto
          if (i == 3 && lines[i].trim().isNotEmpty) {
            insertIndex = i + 1;
            break;
          }
        }
        lines.insert(insertIndex, ctaWithMarkers);
        break;
        
      case 'middle':
        // Mantém posicionamento no meio (está bem posicionado)
        final middleIndex = (lines.length * 0.5).round();
        lines.insert(middleIndex, ctaWithMarkers);
        break;
        
      case 'end':
        // CORRIGIDO: Inserir sempre no final absoluto do roteiro
        lines.add(ctaWithMarkers);
        break;
    }
    
    return lines.join('\n');
  }
  
  /// Get position label for display
  String _getPositionLabel(String position) {
    switch (position.toLowerCase()) {
      case 'beginning':
        return 'INÍCIO DO ROTEIRO';
      case 'middle':
        return 'MEIO DO ROTEIRO';
      case 'end':
        return 'FINAL DO ROTEIRO';
      default:
        return position.toUpperCase();
    }
  }
  
  /// Generate CTAs based on script content and position
  Future<List<String>> generateCtas(String scriptText, String position) async {
    try {
      // Get API key from generation config
      // Get generation config for language
      final generationConfig = ref.read(generationConfigProvider);
      if (generationConfig.apiKey.isEmpty) {
        throw Exception('Chave da API não configurada');
      }
      
      debugPrint('🎯 [Script Provider] Gerando CTAs para posição: $position');
      
      // Map position to specific CTA types usando os tipos corretos que o parser espera
      List<String> ctaTypes = [];
      switch (position) {
        case 'beginning':
          // CTA de início: Inscrição
          ctaTypes = ['subscription'];
          break;
        case 'middle':
          // CTA de meio: Engajamento
          ctaTypes = ['engagement'];
          break;
        case 'end':
          // CTA de final: Final
          ctaTypes = ['final'];
          break;
        default:
          ctaTypes = ['final'];
      }
      
      debugPrint('🎯 [Script Provider] Tipos de CTA mapeados: $ctaTypes');
      
      // Generate CTAs using Gemini service
      final ctaMap = await geminiService.generateCtasForScript(
        scriptContent: scriptText,
        apiKey: generationConfig.apiKey,
        ctaTypes: ctaTypes,
        language: generationConfig.language,
      );
      
      debugPrint('🎯 [Script Provider] CTAs recebidos: ${ctaMap.keys.toList()}');
      debugPrint('🎯 [Script Provider] Total: ${ctaMap.length}');
      
      // Convert map to list
      final ctaList = ctaMap.values.toList();
      debugPrint('✅ [Script Provider] Retornando ${ctaList.length} CTA(s)');
      return ctaList;
    } catch (e) {
      debugPrint('❌ [Script Provider] Error generating CTAs: $e');
      rethrow;
    }
  }

  /// Count words in text
  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
}

// Provider singleton global (simplificado para evitar conflitos)
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(instanceId: 'global_singleton');
});

// Provider para workspace padrão (compatibilidade)
final defaultGeminiServiceProvider = Provider<GeminiService>((ref) {
  return ref.watch(geminiServiceProvider);
});

final scriptGenerationProvider = StateNotifierProvider<ScriptGenerationNotifier, ScriptGenerationState>((ref) {
  return ScriptGenerationNotifier(ref.watch(defaultGeminiServiceProvider), ref);
});

// REMOVIDO: workspaceScriptGenerationProvider para evitar conflitos
// Agora usa apenas o provider global, workspaceId é usado apenas para UI
