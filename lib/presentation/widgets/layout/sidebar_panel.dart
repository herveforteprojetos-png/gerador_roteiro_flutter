import 'package:flutter/material.dart';



import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/script_config_provider.dart';
import '../../providers/script_generation_provider.dart';


class SidebarPanel extends ConsumerStatefulWidget {
  const SidebarPanel({super.key});

  @override
  ConsumerState<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends ConsumerState<SidebarPanel> {
  final TextEditingController apiKeyController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contextController = TextEditingController();

  String selectedModel = 'gemini-1.5-pro';
  String measureType = 'palavras';
  int quantity = 1000;
  String language = 'pt';
  bool includeCallToAction = false;

  bool get isFormValid =>
      apiKeyController.text.isNotEmpty &&
      titleController.text.isNotEmpty &&
      contextController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(scriptGenerationProvider);
    final generationNotifier = ref.read(scriptGenerationProvider.notifier);

    void _generateScript() {
      final config = ScriptConfig(
        apiKey: apiKeyController.text,
        model: selectedModel,
        title: titleController.text,
        context: contextController.text,
        measureType: measureType,
        quantity: quantity,
        language: language,
        includeCallToAction: includeCallToAction,
      );
      generationNotifier.generateScript(config);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
              });
            },
            quantity: quantity,
            onQuantityChanged: (value) {
              setState(() {
                quantity = value.toInt();
              });
            },
            language: language,
            onLanguageChanged: (value) {
              setState(() {
                language = value ?? language;
              });
            },
            includeCallToAction: includeCallToAction,
            onIncludeCallToActionChanged: (value) {
              setState(() {
                includeCallToAction = value ?? false;
              });
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
    );
  }
}
