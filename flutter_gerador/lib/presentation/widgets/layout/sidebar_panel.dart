import 'package:flutter_gerador/data/services/gemini_service.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter/material.dart';



import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/presentation/providers/script_config_provider.dart';
import 'package:flutter_gerador/presentation/providers/script_generation_provider.dart';
import 'package:flutter_gerador/presentation/widgets/script_config/api_config_section.dart';
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
  final TextEditingController contextController = TextEditingController();

  String selectedModel = 'gemini-1.5-pro';
  String measureType = 'palavras';
  int quantity = 1000;
  late TextEditingController quantityController;
  String language = 'pt';
  String perspective = 'terceira';
  bool includeCallToAction = false;

  bool get isFormValid =>
      apiKeyController.text.isNotEmpty &&
      titleController.text.isNotEmpty &&
      contextController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController(text: quantity.toString());
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
      final config = ScriptConfig(
        apiKey: apiKeyController.text,
        model: selectedModel,
        title: titleController.text,
        context: contextController.text,
        measureType: measureType,
        quantity: quantity,
        language: language,
        perspective: perspective,
        includeCallToAction: includeCallToAction,
      );
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
        double sidebarWidth = constraints.maxWidth.clamp(260, 340);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
          child: SizedBox(
            width: sidebarWidth,
            child: ClipRect(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ApiConfigSection(
                      apiKeyController: apiKeyController,
                      selectedModel: selectedModel,
                      onModelChanged: (value) {
                        setState(() {
                          selectedModel = value ?? selectedModel;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ScriptSettingsSection(
                      titleController: titleController,
                      contextController: contextController,
                      measureType: measureType,
                      onMeasureTypeChanged: (value) {
                        setState(() {
                          measureType = value ?? measureType;
                          quantity = measureType == 'palavras' ? 1000 : 2000;
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
                          setState(() {
                            quantity = parsed;
                          });
                        }
                      },
                      language: language,
                      onLanguageChanged: (value) {
                        setState(() {
                          language = value ?? language;
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
                          // Chamada simplificada à Gemini para gerar contexto
                          final geminiService = GeminiService();
                          final config = ScriptConfig(
                            apiKey: apiKeyController.text,
                            model: selectedModel,
                            title: titleController.text,
                            context: '',
                            measureType: measureType,
                            quantity: 200,
                            language: language,
                            perspective: perspective,
                            includeCallToAction: false,
                          );
                          final result = await geminiService.generateScript(config, (_) {});
                          contextController.text = result.scriptText;
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao gerar contexto: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        setState(() => _isGeneratingContext = false);
                      },
                    ),
                    const SizedBox(height: 24),
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
            ),
          ),
        );
      },
    );
  }
}
