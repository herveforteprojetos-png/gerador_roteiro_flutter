import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/data/services/gemini_service.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';
import 'package:flutter_gerador/presentation/providers/script_generation_provider.dart';
import 'package:flutter_gerador/presentation/providers/generation_config_provider.dart';
import 'package:flutter_gerador/presentation/providers/auxiliary_tools_provider.dart';
import 'package:flutter_gerador/presentation/widgets/script_output/generation_progress_view.dart';
import 'package:flutter_gerador/presentation/widgets/layout/expanded_header_widget.dart';
import 'package:flutter_gerador/presentation/widgets/tools/extra_tools_panel.dart';
import 'package:flutter_gerador/presentation/widgets/download/download_manager.dart';
import 'package:flutter_gerador/core/theme/app_colors.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController contextController = TextEditingController();
  bool _isGeneratingContext = false;

  @override
  void dispose() {
    contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(scriptGenerationProvider);
    final generationNotifier = ref.read(scriptGenerationProvider.notifier);
    final config = ref.watch(generationConfigProvider);
    final configNotifier = ref.read(generationConfigProvider.notifier);
    final auxiliaryState = ref.watch(auxiliaryToolsProvider);

    // Listener para contexto gerado automaticamente
    ref.listen(auxiliaryToolsProvider, (previous, current) {
      if (previous?.generatedContext != current.generatedContext && 
          current.generatedContext != null &&
          contextController.text.isEmpty) {
        contextController.text = current.generatedContext!;
      }
    });

    void _generateScript() async {
      if (!configNotifier.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, preencha todos os campos obrigatórios.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final scriptConfig = ScriptConfig(
        apiKey: config.apiKey,
        model: config.model,
        title: config.title,
        context: contextController.text.isNotEmpty ? contextController.text : 'Gerar contexto automaticamente',
        measureType: config.measureType,
        quantity: config.quantity,
        language: config.language,
        perspective: config.perspective,
        includeCallToAction: config.includeCallToAction,
      );

      try {
        await generationNotifier.generateScript(scriptConfig);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar roteiro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Column(
        children: [
          // HEADER HORIZONTAL EXPANDIDO
          const ExpandedHeaderWidget(),
          
          // ÁREA PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: generationState.isGenerating
                  ?
                  // PROGRESSO DE GERAÇÃO
                  GenerationProgressView(
                    progress: generationState.progress ?? GenerationProgress(
                      percentage: 0.0,
                      currentPhase: 'Preparando...',
                      phaseIndex: 0,
                      totalPhases: 6,
                      currentBlock: 0,
                      totalBlocks: 10,
                      logs: ['Iniciando geração...'],
                      wordsGenerated: 0,
                    ),
                    onCancel: () {
                      generationNotifier.cancelGeneration();
                    },
                  )
                  : generationState.result != null && generationState.result!.scriptText.isNotEmpty
                  ? 
                  // ÁREA DE RESULTADO COM PAINEL DE FERRAMENTAS
                  Container(
                    height: MediaQuery.of(context).size.height - 300, // Altura fixa para evitar overflow
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resultado do roteiro (área principal)
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: double.infinity,
                            child: Column(
                              children: [
                                // Resultado do roteiro
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    margin: const EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      border: Border.all(color: AppColors.fireOrange),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: SingleChildScrollView(
                                      child: SelectableText(
                                        generationState.result!.scriptText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Métricas do roteiro
                                Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  child: _buildScriptMetrics(generationState.result!.scriptText),
                                ),
                                const SizedBox(height: 16),
                                // Botões de ação (copiar e download)
                                Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  child: _buildActionButtons(generationState.result!.scriptText),
                                ),
                                const SizedBox(height: 16),
                                // Botão para nova geração
                                Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  child: SizedBox(
                                    width: 200,
                                    height: 45,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Reset do estado para permitir nova geração
                                        generationNotifier.cancelGeneration();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.fireOrange,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                      child: const Text(
                                        'Gerar Novo Roteiro',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Painel de Ferramentas Extras
                        Container(
                          width: 280,
                          height: double.infinity,
                          child: ExtraToolsPanel(scriptText: generationState.result!.scriptText),
                        ),
                      ],
                    ),
                  )
                  :
                  // TEXTAREA E BOTÃO GERAR (estado inicial)
                  Column(
                    children: [
                      // Campo Contexto (textarea grande)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contexto do Roteiro',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.fireOrange,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: TextField(
                                controller: contextController,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Descreva o enredo, personagens principais, cenário, tom da história...\n\nExemplo:\n- Gênero: Ficção científica\n- Protagonista: Jovem cientista\n- Cenário: Futuro distópico\n- Conflito: Descoberta de conspiração...',
                                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.fireOrange),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.fireOrange.withOpacity(0.5)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Botão Gerar Roteiro (centralizado)
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: generationState.isGenerating || !configNotifier.isValid ? null : _generateScript,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.fireOrange,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: generationState.isGenerating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Gerar Roteiro',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                      if (generationState.isGenerating)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
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
        ],
      ),
    );
  }

  Widget _buildScriptMetrics(String scriptText) {
    final characterCount = scriptText.length;
    final wordCount = scriptText.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fireOrange.withOpacity(0.1),
              border: Border.all(color: AppColors.fireOrange.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetricCard(
                      icon: Icons.text_fields,
                      label: 'Caracteres',
                      value: characterCount.toString(),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.fireOrange.withOpacity(0.3),
                    ),
                    _buildMetricCard(
                      icon: Icons.article,
                      label: 'Palavras',
                      value: wordCount.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.fireOrange,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: AppColors.fireOrange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String scriptText) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _copyToClipboard(scriptText),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar Roteiro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _downloadScript(scriptText),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.fireOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Roteiro copiado para a área de transferência!'),
          backgroundColor: AppColors.fireOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _downloadScript(String scriptText) async {
    final config = ref.read(generationConfigProvider);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = config.title.isNotEmpty 
        ? '${config.title.replaceAll(RegExp(r'[^\w\s-]'), '')}_$timestamp'
        : 'roteiro_$timestamp';

    await DownloadManager.showDownloadDialog(
      context: context,
      title: 'Roteiro Gerado',
      content: scriptText,
      fileName: fileName,
      fileExtension: 'txt',
    );
  }
}
