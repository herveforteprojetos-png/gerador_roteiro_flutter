import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/data/models/generation_progress.dart';
import 'package:flutter_gerador/presentation/providers/script_generation_provider.dart';
import 'package:flutter_gerador/presentation/providers/generation_config_provider.dart';
import 'package:flutter_gerador/presentation/providers/auxiliary_tools_provider.dart';
import 'package:flutter_gerador/presentation/widgets/script_output/generation_progress_view.dart';
import 'package:flutter_gerador/presentation/widgets/layout/expanded_header_widget.dart';
import 'package:flutter_gerador/presentation/widgets/tools/extra_tools_panel.dart';
import 'package:flutter_gerador/presentation/widgets/download/download_manager.dart';
import 'package:flutter_gerador/core/theme/app_colors.dart';
import 'package:flutter_gerador/core/services/storage_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _scriptScrollController = ScrollController();
  bool _isScriptScrollLocked = true; // Começa bloqueado
  bool _isHoveringScriptArea = false; // Para efeito visual

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _scriptScrollController.dispose();
    super.dispose();
  }

  /// Carrega as configurações salvas
  Future<void> _loadSavedSettings() async {
    try {
      final configNotifier = ref.read(generationConfigProvider.notifier);

      // Carregar chave API
      final savedApiKey = await StorageService.getApiKey();
      if (savedApiKey != null && savedApiKey.isNotEmpty) {
        configNotifier.updateApiKey(savedApiKey);
      }

      // Carregar modelo selecionado
      final savedModel = await StorageService.getSelectedModel();
      if (savedModel != null) {
        configNotifier.updateModel(savedModel);
      }

      // Carregar preferências do usuário
      final preferences = await StorageService.getUserPreferences();
      configNotifier.updateQuantity(preferences['quantity'] ?? 2000);
      configNotifier.updateMeasureType(
        preferences['measureType'] ?? 'palavras',
      );
      configNotifier.updateLanguage(preferences['language'] ?? 'Português');
      configNotifier.updatePerspective(
        preferences['perspective'] ?? 'terceira',
      );
      configNotifier.updatePersonalizedTheme(
        preferences['personalizedTheme'] ?? '',
      );
      configNotifier.updateUsePersonalizedTheme(
        preferences['usePersonalizedTheme'] ?? false,
      );
    } catch (e) {
      debugPrint('Erro ao carregar configurações salvas: $e');
    }
  }

  /// Salva a chave API e preferências quando alteradas
  Future<void> _saveSettings() async {
    final config = ref.read(generationConfigProvider);

    if (config.apiKey.isNotEmpty) {
      await StorageService.saveApiKey(config.apiKey);
      await StorageService.saveSelectedModel(config.model);
      await StorageService.saveUserPreferences(
        language: config.language,
        perspective: config.perspective,
        measureType: config.measureType,
        quantity: config.quantity,
        personalizedTheme: config.personalizedTheme,
        usePersonalizedTheme: config.usePersonalizedTheme,
      );
    }
  }

  /// Gera o roteiro com base nas configurações
  void _generateScript() async {
    debugPrint('\n');
    debugPrint(
      '????????????????????????????????????????????????????????????????????????????????????????',
    );
    debugPrint('?? HOME_PAGE: _generateScript() CHAMADO');
    debugPrint(
      '????????????????????????????????????????????????????????????????????????????????????????',
    );

    final config = ref.read(generationConfigProvider);
    final generationNotifier = ref.read(scriptGenerationProvider.notifier);

    debugPrint('?? HOME_PAGE: Validando configuração...');

    // Validação direta do estado (não do notifier.isValid que pode estar desatualizado)
    final isValid =
        config.apiKey.isNotEmpty &&
        config.title.isNotEmpty &&
        config.quantity > 0;

    if (!isValid) {
      debugPrint('? HOME_PAGE: Configuração INVÁLIDA');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('? HOME_PAGE: Configuração VÁLIDA');

    // ?? DEBUG: Verificando language antes de usar config
    debugPrint('?? HOME_PAGE: config.language = "${config.language}"');
    debugPrint(
      '?? HOME_PAGE: config.language.codeUnits = ${config.language.codeUnits}',
    );

    // Usar a configuração atual sem modificações
    final finalConfig = config;

    // ?? DEBUG: Verificando language depois de criar final config
    debugPrint(
      '?? HOME_PAGE: finalConfig.language = "${finalConfig.language}"',
    );
    debugPrint(
      '?? HOME_PAGE: finalConfig.language.codeUnits = ${finalConfig.language.codeUnits}',
    );

    try {
      debugPrint(
        '??? HOME_PAGE: Chamando generationNotifier.generateScript()...',
      );

      await generationNotifier.generateScript(finalConfig);

      debugPrint('? HOME_PAGE: generationNotifier.generateScript() retornou');

      await _saveSettings(); // Salvar configurações após geração bem-sucedida

      debugPrint('?? HOME_PAGE: Configurações salvas');
    } catch (e) {
      debugPrint('? HOME_PAGE: EXCEÇÃO capturada: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar roteiro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    debugPrint('?? HOME_PAGE: _generateScript() FINALIZADO');
    debugPrint(
      '????????????????????????????????????????????????????????????????????????????????????????',
    );
    debugPrint('\n');
  }

  /// Alterna o bloqueio do scroll do roteiro
  void _toggleScriptScrollLock() {
    print(
      '?? Alternando scroll lock de $_isScriptScrollLocked para ${!_isScriptScrollLocked}',
    );
    setState(() {
      _isScriptScrollLocked = !_isScriptScrollLocked;
    });
    print('? Novo estado: $_isScriptScrollLocked');
  }

  Future<void> _showExpandedScriptEditor(
    BuildContext context,
    String scriptText,
  ) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _ExpandedScriptDialog(initialText: scriptText);
      },
    );

    // Se o usuário salvou, atualizar o resultado
    if (result != null) {
      // Atualizar o resultado do script no provider
      ref.read(scriptGenerationProvider.notifier).updateScriptText(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(scriptGenerationProvider);
    final generationNotifier = ref.read(scriptGenerationProvider.notifier);
    final config = ref.watch(
      generationConfigProvider,
    ); // ? WATCH o estado para reagir a mudanças
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SingleChildScrollView(
        controller: _mainScrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // HEADER COMPACTO
            const ExpandedHeaderWidget(),

            // ÁREA PRINCIPAL UNIFICADA
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SEÇÃO: PROGRESSO OU RESULTADO
                  if (generationState.isGenerating)
                    GenerationProgressView(
                      progress:
                          generationState.progress ??
                          GenerationProgress(
                            percentage: 0.0,
                            currentPhase: 'Preparando...',
                            phaseIndex: 0,
                            totalPhases: 6,
                            currentBlock: 0,
                            totalBlocks: 10,
                            logs: ['Iniciando geração...'],
                            wordsGenerated: 0,
                          ),
                      onCancel: () => generationNotifier.cancelGeneration(),
                    )
                  else if (generationState.result != null &&
                      generationState.result!.scriptText.isNotEmpty)
                    Column(
                      children: [
                        // RESULTADO DO ROTEIRO
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.article,
                                        color: AppColors.fireOrange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Roteiro Gerado',
                                        style: TextStyle(
                                          color: AppColors.fireOrange,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Botão de expandir roteiro
                                  IconButton(
                                    onPressed: () => _showExpandedScriptEditor(
                                      context,
                                      generationState.result!.scriptText,
                                    ),
                                    icon: Icon(
                                      Icons.open_in_full,
                                      color: AppColors.fireOrange,
                                      size: 20,
                                    ),
                                    tooltip: 'Expandir e editar roteiro',
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.fireOrange
                                          .withValues(alpha: 0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 320,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  border: Border.all(
                                    color:
                                        _isHoveringScriptArea &&
                                            !_isScriptScrollLocked
                                        ? Colors.green.withValues(alpha: 0.6)
                                        : _isScriptScrollLocked
                                        ? Colors.red.withValues(alpha: 0.4)
                                        : AppColors.fireOrange.withValues(alpha: 0.3),
                                    width: _isHoveringScriptArea ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: MouseRegion(
                                  onEnter: (_) => setState(
                                    () => _isHoveringScriptArea = true,
                                  ),
                                  onExit: (_) => setState(
                                    () => _isHoveringScriptArea = false,
                                  ),
                                  child: Stack(
                                    children: [
                                      // Área do roteiro com scroll controlado
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: NotificationListener<ScrollNotification>(
                                          onNotification:
                                              (
                                                ScrollNotification notification,
                                              ) {
                                                // Se estiver bloqueado, não permite scroll
                                                return _isScriptScrollLocked;
                                              },
                                          child: Scrollbar(
                                            controller: _scriptScrollController,
                                            thumbVisibility:
                                                !_isScriptScrollLocked,
                                            child: SingleChildScrollView(
                                              controller:
                                                  _scriptScrollController,
                                              physics: _isScriptScrollLocked
                                                  ? const NeverScrollableScrollPhysics()
                                                  : const ClampingScrollPhysics(),
                                              scrollDirection: Axis.vertical,
                                              child: SelectableText(
                                                generationState
                                                    .result!
                                                    .scriptText,
                                                style: TextStyle(
                                                  color: _isScriptScrollLocked
                                                      ? Colors.white
                                                            .withValues(alpha: 0.7)
                                                      : Colors.white,
                                                  fontSize: 14,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Botão de cadeado estilo moderno
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          elevation: 4,
                                          child: InkWell(
                                            onTap: _toggleScriptScrollLock,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: _isScriptScrollLocked
                                                    ? const Color(
                                                        0xFF2D1B1B,
                                                      ) // Fundo escuro para vermelho
                                                    : const Color(
                                                        0xFF1B2D1B,
                                                      ), // Fundo escuro para verde
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _isScriptScrollLocked
                                                      ? const Color(
                                                          0xFFFF4444,
                                                        ) // Vermelho vibrante
                                                      : const Color(
                                                          0xFF44FF44,
                                                        ), // Verde vibrante
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        (_isScriptScrollLocked
                                                                ? const Color(
                                                                    0xFFFF4444,
                                                                  )
                                                                : const Color(
                                                                    0xFF44FF44,
                                                                  ))
                                                            .withValues(alpha: 0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Tooltip(
                                                message: _isScriptScrollLocked
                                                    ? 'Clique para DESBLOQUEAR o scroll'
                                                    : 'Clique para BLOQUEAR o scroll',
                                                child: Icon(
                                                  _isScriptScrollLocked
                                                      ? Icons.lock
                                                      : Icons.lock_open,
                                                  color: _isScriptScrollLocked
                                                      ? const Color(
                                                          0xFFFF6666,
                                                        ) // Vermelho claro
                                                      : const Color(
                                                          0xFF66FF66,
                                                        ), // Verde claro
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Indicador de status minimalista
                                      Positioned(
                                        bottom: 12,
                                        left: 12,
                                        child: AnimatedOpacity(
                                          opacity: _isHoveringScriptArea
                                              ? 1.0
                                              : 0.7,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _isScriptScrollLocked
                                                  ? const Color(
                                                      0xFF2D1B1B,
                                                    ).withValues(alpha: 0.9)
                                                  : const Color(
                                                      0xFF1B2D1B,
                                                    ).withValues(alpha: 0.9),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _isScriptScrollLocked
                                                    ? const Color(
                                                        0xFFFF4444,
                                                      ).withValues(alpha: 0.7)
                                                    : const Color(
                                                        0xFF44FF44,
                                                      ).withValues(alpha: 0.7),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _isScriptScrollLocked
                                                      ? Icons.block
                                                      : Icons.mouse,
                                                  color: _isScriptScrollLocked
                                                      ? const Color(0xFFFF6666)
                                                      : const Color(0xFF66FF66),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _isScriptScrollLocked
                                                      ? 'BLOQUEADO'
                                                      : 'SCROLLÁVEL',
                                                  style: TextStyle(
                                                    color: _isScriptScrollLocked
                                                        ? const Color(
                                                            0xFFFF6666,
                                                          )
                                                        : const Color(
                                                            0xFF66FF66,
                                                          ),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Overlay leve quando bloqueado (NÃO bloqueia cliques)
                                      if (_isScriptScrollLocked)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            ignoring:
                                                true, // IMPORTANTE: ignora todos os cliques no overlay
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF000000,
                                                ).withValues(alpha: 0.05),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // MÉTRICAS
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: _buildScriptMetrics(
                            generationState.result!.scriptText,
                          ),
                        ),

                        // BOTÕES DE AÇÃO
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: _buildActionButtons(
                            generationState.result!.scriptText,
                          ),
                        ),

                        // BOTÃO NOVA GERAÇÃO
                        Row(
                          children: [
                            // Ferramentas Extras (lado esquerdo)
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 400,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  border: Border.all(
                                    color: AppColors.fireOrange.withValues(alpha: 
                                      0.3,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ExtraToolsPanel(
                                  scriptText:
                                      generationState.result!.scriptText,
                                ),
                              ),
                            ),
                            // Botão Gerar Novo (lado direito)
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 400,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      color: AppColors.fireOrange,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Pronto para\ncriar outro\nroteiro?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          generationNotifier.cancelGeneration();
                                          ref
                                              .read(
                                                auxiliaryToolsProvider.notifier,
                                              )
                                              .clearContext();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.fireOrange,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Gerar Novo Roteiro',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    // BOTÃO GERAR ROTEIRO (estado inicial)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: SizedBox(
                          width: 250,
                          height: 60,
                          child: ElevatedButton(
                            onPressed:
                                generationState.isGenerating ||
                                    !(config.apiKey.isNotEmpty &&
                                        config.title.isNotEmpty &&
                                        config.quantity > 0)
                                ? null
                                : _generateScript,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.fireOrange,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: generationState.isGenerating
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Gerar Roteiro',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScriptMetrics(String scriptText) {
    final characterCount = scriptText.length;
    final wordCount = scriptText
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fireOrange.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.fireOrange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetricCard(
            icon: Icons.text_fields,
            label: 'Caracteres',
            value: characterCount.toString(),
          ),
          Container(
            width: 1,
            height: 30,
            color: AppColors.fireOrange.withValues(alpha: 0.3),
          ),
          _buildMetricCard(
            icon: Icons.article,
            label: 'Palavras',
            value: wordCount.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.fireOrange, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.fireOrange,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
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
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _downloadScript(scriptText),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.fireOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

// Widget separado para o dialog expandido de edição de roteiro
class _ExpandedScriptDialog extends StatefulWidget {
  final String initialText;

  const _ExpandedScriptDialog({required this.initialText});

  @override
  State<_ExpandedScriptDialog> createState() => _ExpandedScriptDialogState();
}

class _ExpandedScriptDialogState extends State<_ExpandedScriptDialog> {
  late TextEditingController expandedController;
  int characterCount = 0;
  int wordCount = 0;

  @override
  void initState() {
    super.initState();
    expandedController = TextEditingController(text: widget.initialText);
    _updateCounts();
    expandedController.addListener(_updateCounts);
  }

  @override
  void dispose() {
    expandedController.removeListener(_updateCounts);
    expandedController.dispose();
    super.dispose();
  }

  void _updateCounts() {
    setState(() {
      characterCount = expandedController.text.length;
      wordCount = expandedController.text
          .trim()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fireOrange, width: 2),
        ),
        child: Column(
          children: [
            // Header do modal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.fireOrange.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: AppColors.fireOrange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Editor Expandido - Roteiro Gerado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Contadores dinâmicos
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.fireOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$characterCount chars',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 12,
                          color: AppColors.fireOrange.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$wordCount palavras',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Editor de texto expandido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: expandedController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Edite seu roteiro aqui...\n\n?? Este editor expandido permite:\n\n• Editar o roteiro gerado com facilidade\n• Ver todo o texto de uma só vez\n• Fazer correções e ajustes precisos\n• Acompanhar contadores de caracteres e palavras\n• Usar Ctrl+A para selecionar tudo\n• Usar Ctrl+Z para desfazer\n• Usar Ctrl+F para buscar texto\n\nFaça os ajustes necessários! ?',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                      height: 1.4,
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.fireOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.fireOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.fireOrange,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
            ),
            // Botões de ação
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  // Informações adicionais
                  Expanded(
                    child: Text(
                      'Faça os ajustes necessários no seu roteiro e salve as alterações',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  // Botões
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(expandedController.text),
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Salvar Alterações'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fireOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
