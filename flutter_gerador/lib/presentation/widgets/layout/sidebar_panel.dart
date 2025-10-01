import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/generation_config.dart';
import 'package:flutter_gerador/data/models/localization_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gerador/core/utils/color_extensions.dart';
import 'package:flutter_gerador/core/services/storage_service.dart';

// NOTE: Este arquivo não é mais utilizado após migração para layout horizontal
// Mantido para referência histórica - Layout original com sidebar lateral

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/presentation/providers/script_generation_provider.dart';
import 'package:flutter_gerador/presentation/providers/auxiliary_tools_provider.dart';
import 'package:flutter_gerador/presentation/widgets/script_config/script_settings_section.dart';
import 'package:flutter_gerador/presentation/widgets/script_config/generation_button.dart';


class SidebarPanel extends ConsumerStatefulWidget {
  const SidebarPanel({super.key});

  @override
  ConsumerState<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends ConsumerState<SidebarPanel> {
  bool _isGeneratingContext = false;
  final TextEditingController apiKeyController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController localizacaoController = TextEditingController();
  final TextEditingController contextController = TextEditingController();

  String selectedModel = 'gemini-2.5-pro';
  String selectedTema = 'História';
  String measureType = 'palavras';
  int quantity = 2000;
  late TextEditingController quantityController;
  String language = 'Português';
  String perspective = 'terceira_pessoa';
  bool includeCallToAction = false;

  bool get isFormValid =>
      apiKeyController.text.isNotEmpty &&
      titleController.text.isNotEmpty &&
      localizacaoController.text.isNotEmpty &&
      contextController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController(text: quantity.toString());
    _loadSavedSettings();
  }

  /// Carrega as configurações salvas
  Future<void> _loadSavedSettings() async {
    try {
      // Carregar chave API
      final savedApiKey = await StorageService.getApiKey();
      if (savedApiKey != null && savedApiKey.isNotEmpty) {
        apiKeyController.text = savedApiKey;
      }

      // Carregar modelo selecionado
      final savedModel = await StorageService.getSelectedModel();
      if (savedModel != null) {
        selectedModel = savedModel;
      }

      // Carregar preferências do usuário
      final preferences = await StorageService.getUserPreferences();
      
      setState(() {
        language = preferences['language'] ?? 'Português';
        perspective = preferences['perspective'] ?? 'terceira_pessoa';
        measureType = preferences['measureType'] ?? 'palavras';
        quantity = preferences['quantity'] ?? 2000;
        includeCallToAction = preferences['includeCta'] ?? false;
        quantityController.text = quantity.toString();
      });
    } catch (e) {
      // Se houver erro ao carregar, usar valores padrão
      debugPrint('Erro ao carregar configurações salvas: $e');
    }
  }

  /// Salva a chave API quando alterada
  Future<void> _saveApiKey() async {
    if (apiKeyController.text.isNotEmpty) {
      await StorageService.saveApiKey(apiKeyController.text);
      await StorageService.saveSelectedModel(selectedModel);
    }
  }

  /// Salva as preferências do usuário
  Future<void> _saveUserPreferences() async {
    await StorageService.saveUserPreferences(
      language: language,
      perspective: perspective,
      measureType: measureType,
      quantity: quantity,
      includeCta: includeCallToAction,
    );
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(scriptGenerationProvider);
    final generationNotifier = ref.read(scriptGenerationProvider.notifier);

    void _generateScript() async {
      if (apiKeyController.text.isEmpty || apiKeyController.text.length < 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chave da API Gemini inválida ou ausente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Validação para localização
      if (localizacaoController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Por favor, preencha onde a história se passa.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // 🚨 DEBUG: Verificando language antes de criar ScriptConfig (SIDEBAR)
      debugPrint('🚨 SIDEBAR_PANEL: language = "$language"');
      debugPrint('🚨 SIDEBAR_PANEL: language.codeUnits = ${language.codeUnits}');
      
      final config = GenerationConfig(
        apiKey: apiKeyController.text,
        model: selectedModel,
        title: titleController.text,
        tema: selectedTema,
        subtema: 'Narrativa Básica', // Valor padrão para compatibilidade
        localizacao: localizacaoController.text,
        context: contextController.text,
        measureType: measureType,
        quantity: quantity,
        language: language,
        perspective: perspective,
        includeCallToAction: includeCallToAction,
        includeFinalCta: false, // Valor padrão para compatibilidade
        localizationLevel: LocalizationLevel.national, // Valor padrão
      );

      // 🚨 DEBUG: Verificando language depois de criar GenerationConfig (SIDEBAR)
      debugPrint('🚨 SIDEBAR_PANEL: config.language = "${config.language}"');
      debugPrint('🚨 SIDEBAR_PANEL: config.language.codeUnits = ${config.language.codeUnits}');
      try {
        await generationNotifier.generateScript(config);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar roteiro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: 380,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              right: BorderSide(color: Colors.orange.o(0.5), width: 2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Configurações em linha horizontal no topo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ScriptSettingsSection(
                    apiKeyController: apiKeyController,
                    selectedModel: selectedModel,
                    onModelChanged: (value) {
                      setState(() {
                        selectedModel = value ?? selectedModel;
                      });
                    },
                    titleController: titleController,
                    selectedTema: selectedTema,
                    onTemaChanged: (value) {
                      setState(() {
                        selectedTema = value ?? selectedTema;
                      });
                    },
                    localizacaoController: localizacaoController,
                    contextController: contextController,
                    measureType: measureType,
                    onMeasureTypeChanged: (value) {
                      setState(() {
                        measureType = value ?? measureType;
                        quantity = measureType == 'palavras' ? 2000 : 5000;
                        quantityController.text = quantity.toString();
                      });
                    },
                    quantity: quantity,
                    quantityController: quantityController,
                    onQuantityChanged: (value) {
                      setState(() {
                        quantity = value.toInt();
                        quantityController.text = quantity.toString();
                      });
                    },
                    onQuantityFieldChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        // Validar limites baseados no tipo de medida
                        final minLimit = measureType == 'palavras' ? 500 : 1000;
                        final maxLimit = measureType == 'palavras' ? 14000 : 100000;
                        
                        if (parsed >= minLimit && parsed <= maxLimit) {
                          setState(() {
                            quantity = parsed;
                          });
                        } else {
                          // Mostrar aviso sobre limites
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Limite: $minLimit a $maxLimit ${measureType}'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    language: language,
                    onLanguageChanged: (value) {
                      setState(() {
                        // Converter códigos de idioma para nomes completos
                        switch (value) {
                          case 'pt':
                            language = 'Português';
                            break;
                          case 'en':
                            language = 'Inglês';
                            break;
                          case 'es-mx':
                            language = 'Espanhol(mexicano)';
                            break;
                          case 'fr':
                            language = 'Francês';
                            break;
                          case 'de':
                            language = 'Alemão';
                            break;
                          case 'it':
                            language = 'Italiano';
                            break;
                          case 'pl':
                            language = 'Polonês';
                            break;
                          case 'bg':
                            language = 'Búlgaro';
                            break;
                          case 'ru':
                            language = 'Russo';
                            break;
                          case 'hr':
                            language = 'Croata';
                            break;
                          case 'tr':
                            language = 'Turco';
                            break;
                          case 'ro':
                            language = 'Romeno';
                            break;
                          default:
                            language = value ?? language;
                        }
                      });
                    },
                    perspective: perspective,
                    onPerspectiveChanged: (value) {
                      setState(() {
                        perspective = value ?? perspective;
                      });
                    },
                    includeCallToAction: includeCallToAction,
                    onIncludeCallToActionChanged: (value) {
                      setState(() {
                        includeCallToAction = value ?? false;
                      });
                    },
                    onGenerateContext: _isGeneratingContext ? null : () async {
                      if (titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Preencha o título para gerar o contexto automaticamente.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setState(() => _isGeneratingContext = true);
                      try {
                        final config = GenerationConfig(
                          apiKey: apiKeyController.text,
                          model: selectedModel,
                          title: titleController.text,
                          language: language,
                          perspective: perspective,
                          quantity: quantity,
                          measureType: measureType,
                        );
                        
                        // Usar o provider correto para gerar contexto
                        final auxiliaryNotifier = ref.read(auxiliaryToolsProvider.notifier);
                        final context = await auxiliaryNotifier.generateContext(config);
                        contextController.text = context;
                      } catch (e) {
                        // Melhorar mensagem de erro
                        String errorMessage;
                        final errorStr = e.toString().toLowerCase();
                        
                        if (errorStr.contains('503')) {
                          errorMessage = '🔄 Servidor temporariamente indisponível. Tente em alguns minutos.';
                        } else if (errorStr.contains('429')) {
                          errorMessage = '⏱️ Muitas solicitações. Aguarde um momento.';
                        } else if (errorStr.contains('timeout') || errorStr.contains('connection')) {
                          errorMessage = '🌐 Problema de conexão. Verifique sua internet.';
                        } else if (errorStr.contains('api')) {
                          errorMessage = '🔑 Verifique sua chave API nas configurações.';
                        } else {
                          errorMessage = '❌ Erro inesperado. Tente novamente.';
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                      setState(() => _isGeneratingContext = false);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Campo de roteiro gerado embaixo, ocupando toda a largura
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black.o(0.05),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Text(
                      generationState.result?.scriptText == null || generationState.result!.scriptText.isEmpty
                          ? 'Nenhum roteiro gerado ainda.'
                          : generationState.result!.scriptText,
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GenerationButton(
                  isFormValid: isFormValid,
                  isGenerating: generationState.isGenerating,
                  onPressed: _generateScript,
                ),
                if (generationState.isGenerating)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: OutlinedButton(
                      onPressed: () {
                        generationNotifier.cancelGeneration();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Cancelar Geração'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
