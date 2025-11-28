import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../providers/generation_config_provider.dart';
// import '../../providers/license_provider.dart'; // Removido - usando autenticação por senha
import '../../../data/models/generation_config.dart';
import '../../../data/models/localization_level.dart';
import '../../../data/services/api_validation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_system.dart';
import 'package:flutter_gerador/core/utils/color_extensions.dart';
import '../../../core/services/storage_service.dart';
// import '../../pages/license_page.dart' as custom_license; // Removido - usando autenticação por senha
import '../help/help_tooltip_widget.dart';
import '../help/help_popup_widget.dart';
import '../help/template_modal_widget.dart';
import '../../../data/constants/help_content.dart';

class ExpandedHeaderWidget extends ConsumerStatefulWidget {
  final TextEditingController? contextController;

  const ExpandedHeaderWidget({super.key, this.contextController});

  @override
  ConsumerState<ExpandedHeaderWidget> createState() =>
      _ExpandedHeaderWidgetState();
}

class _ExpandedHeaderWidgetState extends ConsumerState<ExpandedHeaderWidget> {
  late TextEditingController apiKeyController;
  late TextEditingController openAIKeyController; // 🤖 NOVO
  late TextEditingController titleController;
  late TextEditingController localizacaoController;

  // Estados de validação da API
  ValidationState _validationState = ValidationState.initial;
  String? _validationErrorMessage;
  Timer? _validationTimer;

  // Estado da expansão da configuração técnica
  bool _isTechnicalConfigExpanded =
      true; // ✅ Iniciar expandida para mostrar API Key

  // Estados de visibilidade das senhas
  bool _isGeminiKeyVisible = false;
  bool _isOpenAIKeyVisible = false;

  // Histórico de chaves API
  List<String> _apiKeyHistory = [];
  bool _showApiKeyHistory = false;

  @override
  void initState() {
    super.initState();
    apiKeyController = TextEditingController();
    openAIKeyController = TextEditingController(); // 🤖 NOVO
    titleController = TextEditingController();
    localizacaoController = TextEditingController();

    // Adicionar listeners para atualizar provider em tempo real
    apiKeyController.addListener(_onApiKeyChanged);
    openAIKeyController.addListener(_onOpenAIKeyChanged); // 🤖 NOVO
    titleController.addListener(() {
      print('📝 titleController listener: Título = "${titleController.text}"');
      ref
          .read(generationConfigProvider.notifier)
          .updateTitle(titleController.text);
      print('✅ Provider atualizado com Título');
    });

    // Carregar configurações salvas
    _loadSavedSettings();
  }

  /// Carrega as configurações salvas
  Future<void> _loadSavedSettings() async {
    try {
      // Carregar histórico de chaves API
      _apiKeyHistory = await StorageService.getApiKeyHistory();

      // Carregar chave API atual
      final savedApiKey = await StorageService.getApiKey();
      if (savedApiKey != null && savedApiKey.isNotEmpty) {
        apiKeyController.text = savedApiKey;
        ref.read(generationConfigProvider.notifier).updateApiKey(savedApiKey);
      }

      // 🤖 Carregar chave OpenAI
      final savedOpenAIKey = await StorageService.getOpenAIKey();
      if (savedOpenAIKey != null && savedOpenAIKey.isNotEmpty) {
        openAIKeyController.text = savedOpenAIKey;
        ref.read(generationConfigProvider.notifier).updateOpenAIKey(savedOpenAIKey);
      }

      // Carregar modelo selecionado
      final savedModel = await StorageService.getSelectedModel();
      if (savedModel != null) {
        ref.read(generationConfigProvider.notifier).updateModel(savedModel);
      }

      // Carregar preferências do usuário
      final preferences = await StorageService.getUserPreferences();
      final configNotifier = ref.read(generationConfigProvider.notifier);

      // Carregar qualityMode salvo
      final qualityMode = preferences['qualityMode'] ?? 'pro';
      configNotifier.updateQualityMode(qualityMode);

      configNotifier.updateQuantity(preferences['quantity'] ?? 2000);
      configNotifier.updateMeasureType(
        preferences['measureType'] ?? 'palavras',
      );

      // Mapear valores antigos para valores válidos
      String language = preferences['language'] ?? 'Português';
      if (language == 'pt') language = 'Português';
      if (language == 'ru') language = 'Russo';
      if (!GenerationConfig.availableLanguages.contains(language)) {
        language = 'Português';
      }
      configNotifier.updateLanguage(language);

      String perspective = preferences['perspective'] ?? 'terceira_pessoa';
      if (perspective == 'terceira') perspective = 'terceira_pessoa';
      if (!GenerationConfig.availablePerspectives.contains(perspective)) {
        perspective = 'terceira_pessoa';
      }
      configNotifier.updatePerspective(perspective);

      configNotifier.updateLocalizationLevel(
        LocalizationLevel.values.firstWhere(
          (level) =>
              level.name == (preferences['localizationLevel'] ?? 'national'),
          orElse: () => LocalizationLevel.national,
        ),
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

  @override
  void dispose() {
    apiKeyController.removeListener(_onApiKeyChanged);
    apiKeyController.dispose();
    openAIKeyController.removeListener(_onOpenAIKeyChanged); // 🤖 NOVO
    openAIKeyController.dispose(); // 🤖 NOVO
    titleController.dispose();
    localizacaoController.dispose();
    _validationTimer?.cancel();
    super.dispose();
  }

  void _onApiKeyChanged() {
    // Cancelar timer anterior se existir
    _validationTimer?.cancel();

    final apiKey = apiKeyController.text.trim();

    // ✅ ATUALIZAR O PROVIDER IMEDIATAMENTE (para habilitar botão)
    print(
      '🔑 _onApiKeyChanged: API Key = "${apiKey}" (${apiKey.length} chars)',
    );
    ref.read(generationConfigProvider.notifier).updateApiKey(apiKey);
    print('✅ Provider atualizado com API Key');

    if (apiKey.isEmpty) {
      setState(() {
        _validationState = ValidationState.initial;
        _validationErrorMessage = null;
      });
      return;
    }

    // Iniciar novo timer de 1 segundo para evitar muitas requisições
    _validationTimer = Timer(const Duration(seconds: 1), () {
      _validateApiKey(apiKey);
    });
  }

  Future<void> _validateApiKey(String apiKey) async {
    setState(() {
      _validationState = ValidationState.validating;
      _validationErrorMessage = null;
    });

    try {
      final result = await ApiValidationService.validateGeminiApiKey(apiKey);

      if (mounted) {
        setState(() {
          if (result.isValid) {
            _validationState = ValidationState.valid;
            _validationErrorMessage = null;
            // ✅ Provider já foi atualizado em _onApiKeyChanged()
          } else {
            _validationState = ValidationState.invalid;
            _validationErrorMessage = result.errorMessage;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationState = ValidationState.invalid;
          _validationErrorMessage = 'Erro na validação: ${e.toString()}';
        });
      }
    }
  }

  void _onOpenAIKeyChanged() {
    final openAIKey = openAIKeyController.text.trim();
    print(
      '🤖 _onOpenAIKeyChanged: OpenAI Key = "${openAIKey.isEmpty ? "(vazia)" : "***${openAIKey.length} chars***"}"',
    );
    ref.read(generationConfigProvider.notifier).updateOpenAIKey(openAIKey);
    print('✅ Provider atualizado com OpenAI Key');
    
    // Salvar automaticamente
    if (openAIKey.isNotEmpty) {
      StorageService.saveOpenAIKey(openAIKey);
    }
  }

  /// Salva a chave API atual se ela for válida
  Future<void> _saveCurrentApiKey() async {
    final apiKey = apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite uma chave API antes de salvar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_validationState != ValidationState.valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A chave API deve ser válida antes de salvar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await StorageService.saveApiKey(apiKey);

      // Atualizar histórico local
      _apiKeyHistory = await StorageService.getApiKeyHistory();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chave API salva com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Seleciona uma chave do histórico
  void _selectApiKeyFromHistory(String apiKey) {
    apiKeyController.text = apiKey;
    setState(() {
      _showApiKeyHistory = false;
    });
    // Validar a chave selecionada
    _validateApiKey(apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(generationConfigProvider); // watch for rebuild
    final configNotifier = ref.read(generationConfigProvider.notifier);

    // ✅ Removido sincronização automática - os listeners cuidam disso
    // Sincronizar controllers com config causava loops infinitos

    return Container(
      width: double.infinity,
      decoration: AppDesignSystem.headerDecoration,
      child: Column(
        children: [
          // Barra de licença no topo
          Container(
            width: double.infinity,
            padding: AppDesignSystem.paddingHorizontalL.add(
              AppDesignSystem.paddingVerticalS,
            ),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gerador de Roteiros IA - Criado por @guidarkyoutube',
                  style: AppDesignSystem.caption.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                // _buildLicenseInfo(), // Removido - usando autenticação por senha
              ],
            ),
          ),
          // Primeira linha: CONFIGURAÇÃO TÉCNICA
          _buildTechnicalConfigSection(config, configNotifier),
          Divider(color: Colors.grey[700], height: 1),
          // Segunda linha: CONFIGURAÇÃO DE CONTEÚDO (sozinha)
          _buildContentConfigSection(config, configNotifier),
        ],
      ),
    );
  }

  Widget _buildTechnicalConfigSection(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Container(
      padding: AppDesignSystem.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção com botão expansível
          Row(
            children: [
              Icon(Icons.settings, color: AppColors.fireOrange, size: 16),
              AppDesignSystem.horizontalSpaceS,
              Text(
                'CONFIGURAÇÃO TÉCNICA',
                style: AppDesignSystem.headingSmall.copyWith(
                  color: AppColors.fireOrange,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  setState(() {
                    _isTechnicalConfigExpanded = !_isTechnicalConfigExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.fireOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, color: AppColors.fireOrange, size: 16),
                      const SizedBox(width: 4),
                      Icon(
                        _isTechnicalConfigExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.fireOrange,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Campos expansíveis da configuração técnica
          if (_isTechnicalConfigExpanded) ...[
            AppDesignSystem.verticalSpaceM,
            // Botão para configurar APIs
            _buildApiConfigButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildContentConfigSection(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Container(
      padding: AppDesignSystem.paddingL,
      child: Container(
        width: double.infinity,
        padding: AppDesignSystem.paddingL,
        decoration: AppDesignSystem.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da seção
            Row(
              children: [
                Icon(
                  Icons.edit_document,
                  color: AppColors.fireOrange,
                  size: 16,
                ),
                AppDesignSystem.horizontalSpaceS,
                Expanded(
                  child: Text(
                    'CONFIGURAÇÃO DO CONTEÚDO',
                    style: AppDesignSystem.headingSmall.copyWith(
                      color: AppColors.fireOrange,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                // Botão Ver Combinações
                ElevatedButton.icon(
                  onPressed: () => TemplateModalWidget.show(context),
                  icon: const Text('🎯', style: TextStyle(fontSize: 16)),
                  label: const Text('Ver Combinações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Colors.blue.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Campos da configuração de conteúdo (sempre visíveis)
            AppDesignSystem.verticalSpaceM,
            // Campo Título + Configurações de conteúdo
            Column(
              children: [
                // Campo Título
                _buildTitleField(configNotifier),
                AppDesignSystem.verticalSpaceS,
                // Checkbox: Começar com a frase do título
                _buildStartWithTitlePhraseCheckbox(config, configNotifier),
                AppDesignSystem.verticalSpaceM,
                // Linha com Tema e Subtema
                Row(
                  children: [
                    // Campo Tema
                    Expanded(
                      flex: 1,
                      child: config.usePersonalizedTheme
                          ? _buildCustomThemeField(config, configNotifier)
                          : _buildTemaDropdown(config, configNotifier),
                    ),
                    AppDesignSystem.horizontalSpaceM,
                    // Campo Subtema (apenas se não estiver usando tema personalizado E tema não for "Livre (Sem Tema)")
                    if (!config.usePersonalizedTheme &&
                        config.tema != 'Livre (Sem Tema)')
                      Expanded(
                        flex: 1,
                        child: _buildSubtemaDropdown(config, configNotifier),
                      ),
                  ],
                ),
                AppDesignSystem.verticalSpaceS,
                // Toggle para tema personalizado
                _buildThemeToggle(config, configNotifier),
                AppDesignSystem.verticalSpaceM,
                // Linha com Localização
                Row(
                  children: [
                    // Campo Localização
                    Expanded(
                      child: _buildLocalizacaoField(config, configNotifier),
                    ),
                  ],
                ),
                AppDesignSystem.verticalSpaceM,
                // Linha com Medida, Perspectiva, Idioma e Regionalismo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medida com Slider
                    Expanded(
                      flex: 2,
                      child: _buildMeasureSection(config, configNotifier),
                    ),
                    AppDesignSystem.horizontalSpaceL,
                    // Perspectiva
                    Expanded(
                      flex: 2,
                      child: _buildPerspectiveDropdown(config, configNotifier),
                    ),
                    AppDesignSystem.horizontalSpaceL,
                    // Idioma
                    Expanded(
                      flex: 1,
                      child: _buildLanguageDropdown(config, configNotifier),
                    ),
                    AppDesignSystem.horizontalSpaceL,
                    // Regionalismo
                    Expanded(
                      flex: 2,
                      child: _buildLocalizationLevelDropdown(
                        config,
                        configNotifier,
                      ),
                    ),
                  ],
                ),
                AppDesignSystem.verticalSpaceM,
                // Linha com Tipo de História (Genre) e Estilo Narrativo
                Row(
                  children: [
                    // Tipo de História
                    Expanded(
                      flex: 2,
                      child: _buildGenreDropdown(config, configNotifier),
                    ),
                    AppDesignSystem.horizontalSpaceL,
                    // Estilo de Narração
                    Expanded(
                      flex: 2,
                      child: _buildNarrativeStyleDropdown(
                        config,
                        configNotifier,
                      ),
                    ),
                    AppDesignSystem.horizontalSpaceL,
                    // Espaço vazio para manter alinhamento
                    Expanded(flex: 3, child: Container()),
                  ],
                ),
                AppDesignSystem.verticalSpaceS,
                // 📝 NOVO: Checkbox para prompt customizado
                _buildCustomPromptCheckbox(config, configNotifier),
                // 📝 NOVO: Campo de texto customizado (aparece apenas se checkbox ativado)
                _buildCustomPromptField(config, configNotifier),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Botão que abre o modal de configuração de APIs
  Widget _buildApiConfigButton() {
    final config = ref.watch(generationConfigProvider);
    final hasGeminiKey = apiKeyController.text.trim().isNotEmpty;
    final hasOpenAIKey = openAIKeyController.text.trim().isNotEmpty;
    final isGemini = config.selectedProvider == 'gemini';
    
    // Define o status visual baseado na seleção
    Color buttonColor;
    IconData buttonIcon;
    String buttonText;
    String subtitle;
    
    if (isGemini && hasGeminiKey) {
      buttonColor = AppColors.fireOrange;
      buttonIcon = Icons.auto_awesome;
      buttonText = 'Gemini 2.5 Pro Configurado';
      subtitle = 'API ativa e pronta para usar';
    } else if (!isGemini && hasOpenAIKey) {
      buttonColor = Colors.blue;
      buttonIcon = Icons.smart_toy;
      buttonText = 'GPT-4o Configurado';
      subtitle = 'API ativa e pronta para usar';
    } else {
      buttonColor = Colors.red;
      buttonIcon = Icons.error;
      buttonText = 'Configurar API';
      subtitle = 'Escolha e configure Gemini ou ChatGPT';
    }

    return InkWell(
      onTap: _showApiConfigDialog,
      borderRadius: BorderRadius.circular(AppDesignSystem.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppDesignSystem.borderRadius),
          border: Border.all(color: buttonColor, width: 2),
        ),
        child: Row(
          children: [
            Icon(buttonIcon, color: buttonColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    buttonText,
                    style: AppDesignSystem.bodyMedium.copyWith(
                      color: buttonColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppDesignSystem.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.settings, color: buttonColor, size: 20),
          ],
        ),
      ),
    );
  }

  /// Modal de configuração das APIs
  void _showApiConfigDialog() {
    final config = ref.read(generationConfigProvider);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Estado local para o modal
        String selectedProvider = config.selectedProvider;
        
        return StatefulBuilder(
          builder: (context, setState) {
            final isGemini = selectedProvider == 'gemini';
            
            return Dialog(
              backgroundColor: AppColors.darkBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignSystem.borderRadius),
              ),
              child: Container(
                width: 600,
                padding: AppDesignSystem.paddingXL,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Row(
                      children: [
                        Icon(Icons.vpn_key, color: AppColors.fireOrange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Configuração da API',
                            style: AppDesignSystem.headingMedium.copyWith(
                              color: AppColors.fireOrange,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Divider(color: Colors.grey.withOpacity(0.3), height: 32),
                    
                    // Texto explicativo
                    Text(
                      'Escolha qual API você deseja usar:',
                      style: AppDesignSystem.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppDesignSystem.verticalSpaceM,
                    
                    // Botões de seleção (Gemini OU OpenAI)
                    Row(
                      children: [
                        // Botão Gemini
                        Expanded(
                          child: _buildProviderSelectionButton(
                            isSelected: isGemini,
                            icon: Icons.auto_awesome,
                            title: 'Gemini',
                            subtitle: '2.5 Pro',
                            color: AppColors.fireOrange,
                            onTap: () {
                              setState(() {
                                selectedProvider = 'gemini';
                              });
                              ref.read(generationConfigProvider.notifier)
                                  .updateSelectedProvider('gemini');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Botão OpenAI
                        Expanded(
                          child: _buildProviderSelectionButton(
                            isSelected: !isGemini,
                            icon: Icons.smart_toy,
                            title: 'ChatGPT',
                            subtitle: 'GPT-4o',
                            color: Colors.blue,
                            onTap: () {
                              setState(() {
                                selectedProvider = 'openai';
                              });
                              ref.read(generationConfigProvider.notifier)
                                  .updateSelectedProvider('openai');
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    AppDesignSystem.verticalSpaceL,
                    
                    // Campo da API selecionada
                    if (isGemini)
                      _buildDialogApiKeyField(
                        title: 'Chave da API Gemini',
                        subtitle: 'Gemini 2.5 Pro',
                        controller: apiKeyController,
                        icon: Icons.auto_awesome,
                        iconColor: AppColors.fireOrange,
                        isVisible: _isGeminiKeyVisible,
                        onToggleVisibility: () {
                          setState(() {
                            _isGeminiKeyVisible = !_isGeminiKeyVisible;
                          });
                        },
                      )
                    else
                      _buildDialogApiKeyField(
                        title: 'Chave da API OpenAI',
                        subtitle: 'GPT-4o - Custo: ~\$0.15 USD/roteiro 10K palavras',
                        controller: openAIKeyController,
                        icon: Icons.smart_toy,
                        iconColor: Colors.blue,
                        isVisible: _isOpenAIKeyVisible,
                        onToggleVisibility: () {
                          setState(() {
                            _isOpenAIKeyVisible = !_isOpenAIKeyVisible;
                          });
                        },
                      ),
                    
                    AppDesignSystem.verticalSpaceL,
                    
                    // Botão Fechar
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.fireOrange,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: Text(
                          'Fechar',
                          style: AppDesignSystem.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Botão de seleção de provider (Gemini ou OpenAI)
  Widget _buildProviderSelectionButton({
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesignSystem.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppDesignSystem.borderRadius),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppDesignSystem.bodyMedium.copyWith(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppDesignSystem.caption.copyWith(
                color: isSelected ? color.withOpacity(0.7) : Colors.grey,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(Icons.check_circle, color: color, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  /// Campo de API key dentro do dialog
  Widget _buildDialogApiKeyField({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    final hasKey = controller.text.trim().isNotEmpty;
    final borderColor = hasKey ? Colors.green : iconColor.withOpacity(0.5);
    
    // Suffix icon com botão de visibilidade E check
    Widget suffixIcon = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botão de mostrar/ocultar
        IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: onToggleVisibility,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
        ),
        // Check se tiver chave válida
        if (hasKey) ...[
          const SizedBox(width: 4),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 10),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppDesignSystem.bodyMedium.copyWith(
                color: iconColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppDesignSystem.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: AppDesignSystem.fieldHeight,
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            style: AppDesignSystem.bodyMedium,
            decoration: AppDesignSystem.getInputDecoration(
              hint: 'Cole sua chave aqui...',
            ).copyWith(
              prefixIcon: Icon(Icons.vpn_key, color: iconColor, size: 18),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDesignSystem.borderRadius),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDesignSystem.borderRadius),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDesignSystem.borderRadius),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeyField(GenerationConfigNotifier configNotifier) {
    // final config = ref.watch(generationConfigProvider);

    // Determinar cor e ícone baseado no estado de validação
    Color borderColor;
    Widget? suffixIcon;

    switch (_validationState) {
      case ValidationState.initial:
        borderColor = AppColors.fireOrange;
        suffixIcon = null;
        break;
      case ValidationState.validating:
        borderColor = Colors.orange;
        suffixIcon = Tooltip(
          message: 'Validando chave da API...',
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        );
        break;
      case ValidationState.valid:
        borderColor = Colors.green;
        suffixIcon = Tooltip(
          message: 'Chave da API válida ✓',
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 10),
          ),
        );
        break;
      case ValidationState.invalid:
        borderColor = Colors.red;
        suffixIcon = Tooltip(
          message: _validationErrorMessage ?? 'Chave da API inválida',
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 10),
          ),
        );
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Chave da API Gemini',
              style: AppDesignSystem.labelMedium.copyWith(
                color: AppColors.fireOrange,
              ),
            ),
            const Spacer(),
            // Botão do histórico
            if (_apiKeyHistory.isNotEmpty)
              InkWell(
                onTap: () {
                  setState(() {
                    _showApiKeyHistory = !_showApiKeyHistory;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.fireOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        color: AppColors.fireOrange,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Histórico',
                        style: AppDesignSystem.caption.copyWith(
                          color: AppColors.fireOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // Botão salvar
            InkWell(
              onTap: _saveCurrentApiKey,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _validationState == ValidationState.valid
                      ? Colors.green.withOpacity(0.2)
                      : AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _validationState == ValidationState.valid
                        ? Colors.green
                        : AppColors.fireOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.save,
                      color: _validationState == ValidationState.valid
                          ? Colors.green
                          : AppColors.fireOrange,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Salvar',
                      style: AppDesignSystem.caption.copyWith(
                        color: _validationState == ValidationState.valid
                            ? Colors.green
                            : AppColors.fireOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        AppDesignSystem.verticalSpaceS,
        // Dropdown do histórico (se visível)
        if (_showApiKeyHistory && _apiKeyHistory.isNotEmpty) ...[
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(AppDesignSystem.borderRadius),
              border: Border.all(color: AppColors.fireOrange.withOpacity(0.3)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _apiKeyHistory.length,
              itemBuilder: (context, index) {
                final key = _apiKeyHistory[index];
                final maskedKey = '${key.substring(0, 8)}...*****';

                return InkWell(
                  onTap: () => _selectApiKeyFromHistory(key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: index < _apiKeyHistory.length - 1
                          ? Border(
                              bottom: BorderSide(
                                color: AppColors.fireOrange.withOpacity(0.2),
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.key, color: AppColors.fireOrange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            maskedKey,
                            style: AppDesignSystem.bodySmall.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 16),
                          onPressed: () async {
                            await StorageService.removeApiKeyFromHistory(key);
                            _apiKeyHistory =
                                await StorageService.getApiKeyHistory();
                            setState(() {});
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          AppDesignSystem.verticalSpaceS,
        ],
        SizedBox(
          height: AppDesignSystem.fieldHeight,
          child: TextField(
            controller: apiKeyController,
            obscureText: true,
            style: AppDesignSystem.bodyMedium,
            decoration:
                AppDesignSystem.getInputDecoration(
                  hint: 'Cole sua chave da API aqui...',
                ).copyWith(
                  prefixIcon: Icon(
                    Icons.key,
                    color: AppColors.fireOrange,
                    size: 18,
                  ),
                  suffixIcon: suffixIcon,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.borderRadius,
                    ),
                    borderSide: BorderSide(color: borderColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.borderRadius,
                    ),
                    borderSide: BorderSide(color: borderColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.borderRadius,
                    ),
                    borderSide: BorderSide(color: borderColor, width: 1),
                  ),
                ),
            // Removemos o onChanged daqui pois agora usamos o listener
          ),
        ),
      ],
    );
  }

  /// 🤖 Campo para OpenAI API Key (usado como fallback quando Gemini está indisponível)
  Widget _buildOpenAIKeyField() {
    // Verifica se há chave configurada
    final hasKey = openAIKeyController.text.trim().isNotEmpty;
    final borderColor = hasKey ? Colors.green : Colors.blue.withOpacity(0.3);
    
    // Ícone de status (checkmark verde se configurado)
    Widget? suffixIcon;
    if (hasKey) {
      suffixIcon = Tooltip(
        message: 'OpenAI configurado ✓',
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 10),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.smart_toy, size: 16, color: hasKey ? Colors.green : Colors.blue),
            const SizedBox(width: 6),
            Text(
              hasKey ? '🤖 OpenAI Configurado (Fallback Ativo)' : '🤖 OpenAI API Key (Fallback Opcional)',
              style: AppDesignSystem.labelMedium.copyWith(
                color: hasKey ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'GPT-4o será usado automaticamente quando Gemini retornar erro 503.\n'
                  'Custo aproximado: \$0.15 USD por roteiro de 10K palavras.',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: (hasKey ? Colors.green : Colors.blue).withOpacity(0.7),
              ),
            ),
          ],
        ),
        AppDesignSystem.verticalSpaceS,
        SizedBox(
          height: AppDesignSystem.fieldHeight,
          child: TextField(
            controller: openAIKeyController,
            obscureText: true,
            style: AppDesignSystem.bodyMedium,
            decoration: AppDesignSystem.getInputDecoration(
              hint: 'sk-proj-... (usado quando Gemini está indisponível)',
            ).copyWith(
              prefixIcon: Icon(
                Icons.vpn_key,
                color: hasKey ? Colors.green : Colors.blue,
                size: 18,
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.borderRadius,
                ),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.borderRadius,
                ),
                borderSide: BorderSide(color: hasKey ? Colors.green : Colors.blue, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.borderRadius,
                ),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelDropdown(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modelo IA',
          style: AppDesignSystem.labelMedium.copyWith(
            color: AppColors.fireOrange,
          ),
        ),
        AppDesignSystem.verticalSpaceS,
        SizedBox(
          height: AppDesignSystem.fieldHeight,
          child: DropdownButtonFormField<String>(
            initialValue: config.qualityMode,
            style: AppDesignSystem.bodyMedium,
            dropdownColor: AppColors.darkBackground,
            decoration: AppDesignSystem.getInputDecoration(
              hint: 'Selecione o modelo',
            ),
            items: const [
              DropdownMenuItem(value: 'pro', child: Text('🧠 Pro')),
              DropdownMenuItem(value: 'flash', child: Text('⚡ Flash')),
            ],
            onChanged: (value) {
              if (value != null) {
                configNotifier.updateQualityMode(value);
                StorageService.saveUserPreferences(qualityMode: value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField(GenerationConfigNotifier configNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Título do Roteiro',
          style: AppDesignSystem.labelMedium.copyWith(
            color: AppColors.fireOrange,
          ),
        ),
        AppDesignSystem.verticalSpaceS,
        SizedBox(
          height: AppDesignSystem.fieldHeight,
          child: TextField(
            controller: titleController,
            style: AppDesignSystem.bodyMedium,
            decoration:
                AppDesignSystem.getInputDecoration(
                  hint: 'Digite o título da sua história...',
                ).copyWith(
                  prefixIcon: Icon(
                    Icons.title,
                    color: AppColors.fireOrange,
                    size: 18,
                  ),
                ),
            // onChanged removido - usando listener em initState
          ),
        ),
      ],
    );
  }

  Widget _buildTemaDropdown(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return HelpTooltipWidget(
      message: HelpContent.tooltips['theme']!.text,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.fireOrange,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: config.tema,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            dropdownColor: AppColors.darkBackground,
            decoration: InputDecoration(
              hintText: 'Selecione um tema...',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              prefixIcon: Icon(
                Icons.category,
                color: AppColors.fireOrange,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.fireOrange.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
              ),
            ),
            items: const [
              // 🎯 MODO LIVRE (SEM TEMA)
              DropdownMenuItem(
                value: 'Livre (Sem Tema)',
                child: Text('🆓 Livre (Sem Tema)'),
              ),

              // Narrativas Dramáticas e Intensas
              DropdownMenuItem(value: 'Vingança', child: Text('🔥 Vingança')),
              DropdownMenuItem(value: 'Traição', child: Text('💔 Traição')),
              DropdownMenuItem(value: 'Redenção', child: Text('✨ Redenção')),
              DropdownMenuItem(value: 'Justiça', child: Text('⚖️ Justiça')),
              DropdownMenuItem(
                value: 'Sacrifício',
                child: Text('🙏 Sacrifício'),
              ),
              DropdownMenuItem(
                value: 'Poder e Corrupção',
                child: Text('👑 Poder e Corrupção'),
              ),
              DropdownMenuItem(
                value: 'Sobrevivência',
                child: Text('🛡️ Sobrevivência'),
              ),
              DropdownMenuItem(
                value: 'Família Disfuncional',
                child: Text('🏠 Família Disfuncional'),
              ),
              DropdownMenuItem(
                value: 'Segredos Obscuros',
                child: Text('🔐 Segredos Obscuros'),
              ),
              DropdownMenuItem(
                value: 'Ascensão e Queda',
                child: Text('📈 Ascensão e Queda'),
              ),

              // Gêneros Clássicos
              DropdownMenuItem(
                value: 'Mistério/Suspense',
                child: Text('🔍 Mistério/Suspense'),
              ),
              DropdownMenuItem(
                value: 'Terror/Sobrenatural',
                child: Text('👻 Terror/Sobrenatural'),
              ),
              DropdownMenuItem(
                value: 'Ficção Científica',
                child: Text('🚀 Ficção Científica'),
              ),
              DropdownMenuItem(
                value: 'Drama/Romance',
                child: Text('💕 Drama/Romance'),
              ),
              DropdownMenuItem(
                value: 'Comédia/Humor',
                child: Text('😄 Comédia/Humor'),
              ),
              DropdownMenuItem(
                value: 'Ação/Aventura',
                child: Text('⚡ Ação/Aventura'),
              ),

              // Temas Educativos
              DropdownMenuItem(value: 'História', child: Text('📚 História')),
              DropdownMenuItem(value: 'Ciência', child: Text('🔬 Ciência')),
              DropdownMenuItem(value: 'Saúde', child: Text('💊 Saúde')),
              DropdownMenuItem(
                value: 'Tecnologia',
                child: Text('💻 Tecnologia'),
              ),
              DropdownMenuItem(value: 'Natureza', child: Text('🌱 Natureza')),
              DropdownMenuItem(
                value: 'Biografias',
                child: Text('👤 Biografias'),
              ),
              DropdownMenuItem(
                value: 'Curiosidades',
                child: Text('🤔 Curiosidades'),
              ),
              DropdownMenuItem(
                value: 'Viagens/Lugares',
                child: Text('🌍 Viagens/Lugares'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                configNotifier.updateTema(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubtemaDropdown(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    final subtemasDisponiveis = GenerationConfig.getSubtemasForTema(
      config.tema,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subtema',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.fireOrange,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: subtemasDisponiveis.contains(config.subtema)
              ? config.subtema
              : subtemasDisponiveis.first,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          dropdownColor: AppColors.darkBackground,
          decoration: InputDecoration(
            hintText: 'Selecione um subtema...',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
            prefixIcon: Icon(
              Icons.subdirectory_arrow_right,
              color: AppColors.fireOrange,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.fireOrange.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
            ),
          ),
          items: subtemasDisponiveis.map<DropdownMenuItem<String>>((
            String subtema,
          ) {
            return DropdownMenuItem<String>(
              value: subtema,
              child: Text(
                subtema,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              configNotifier.updateSubtema(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCustomThemeField(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tema Personalizado',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.fireOrange,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Digite seu tema personalizado...',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
            prefixIcon: Icon(Icons.edit, color: AppColors.fireOrange, size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.fireOrange.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
            ),
          ),
          onChanged: configNotifier.updatePersonalizedTheme,
          controller: TextEditingController(text: config.personalizedTheme)
            ..selection = TextSelection.collapsed(
              offset: config.personalizedTheme.length,
            ),
        ),
        const SizedBox(height: 16),
        // Subtema Principal
        Text(
          'Subtema Principal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.fireOrange,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText:
                'Ex: Irmãos recebem milhões, protagonista recebe item sem valor...',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
            prefixIcon: Icon(
              Icons.subdirectory_arrow_right,
              color: AppColors.fireOrange,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.fireOrange.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
            ),
          ),
          maxLines: 2,
          onChanged: configNotifier.updatePersonalizedSubtheme,
          controller: TextEditingController(text: config.personalizedSubtheme)
            ..selection = TextSelection.collapsed(
              offset: config.personalizedSubtheme.length,
            ),
        ),
        const SizedBox(height: 16),
        // Subtema Secundário
        Text(
          'Subtema Secundário',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.fireOrange,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText:
                'Ex: Item aparentemente inútil esconde fortuna secreta...',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
            prefixIcon: Icon(
              Icons.double_arrow,
              color: AppColors.fireOrange,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.fireOrange.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
            ),
          ),
          maxLines: 2,
          onChanged: configNotifier.updatePersonalizedSecondarySubtheme,
          controller:
              TextEditingController(text: config.personalizedSecondarySubtheme)
                ..selection = TextSelection.collapsed(
                  offset: config.personalizedSecondarySubtheme.length,
                ),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.fireOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            config.usePersonalizedTheme ? Icons.edit : Icons.list,
            color: AppColors.fireOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              config.usePersonalizedTheme
                  ? 'Usando tema personalizado'
                  : 'Usando tema predefinido',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: config.usePersonalizedTheme,
            onChanged: configNotifier.updateUsePersonalizedTheme,
            activeThumbColor: AppColors.fireOrange,
            activeTrackColor: AppColors.fireOrange.withOpacity(0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalizacaoField(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return HelpTooltipWidget(
      message: HelpContent.tooltips['location']!.text,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onde se passa a história:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.fireOrange,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: localizacaoController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'Ex: Tokyo, Japão / Sertão da Bahia / Nova York / Interior de Minas...',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              prefixIcon: Icon(
                Icons.location_on,
                color: AppColors.fireOrange,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.black.o(0.3),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange.o(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
              ),
            ),
            onChanged: configNotifier.updateLocalizacao,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasureSection(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medida',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.fireOrange,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        // Dropdown de tipo de medida com mesmo estilo dos outros
        DropdownButtonFormField<String>(
          initialValue: config.measureType,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          dropdownColor: AppColors.darkBackground,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.o(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange.o(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 1),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'palavras',
              child: Text(
                'Palavras',
                style: TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'caracteres',
              child: Text(
                'Caracteres',
                style: TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              configNotifier.updateMeasureType(value);
              // Salvar preferência
              StorageService.saveUserPreferences(measureType: value);
            }
          },
        ),
        const SizedBox(height: 8),
        // Slider de quantidade
        Column(
          children: [
            Slider(
              value: config.quantity.toDouble(),
              min: configNotifier.minQuantity.toDouble(),
              max: configNotifier.maxQuantity.toDouble(),
              divisions: 20,
              activeColor: AppColors.fireOrange,
              inactiveColor: AppColors.fireOrange.o(0.3),
              onChanged: (value) {
                configNotifier.updateQuantity(value.toInt());
                // Salvar preferência
                StorageService.saveUserPreferences(quantity: value.toInt());
              },
            ),
            Text(
              '${config.quantity} ${config.measureType}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Idioma',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.fireOrange,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: config.language,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          dropdownColor: AppColors.darkBackground,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.o(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange.o(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 1),
            ),
          ),
          items: GenerationConfig.availableLanguages.map((language) {
            return DropdownMenuItem(
              value: language,
              child: Text(
                GenerationConfig.languageLabels[language] ?? language,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              configNotifier.updateLanguage(value);
              // Salvar preferência
              String langCode;
              switch (value) {
                case 'Português':
                  langCode = 'pt';
                  break;
                case 'Russo':
                  langCode = 'ru';
                  break;
                case 'Coreano (한국어)':
                  langCode = 'ko';
                  break;
                default:
                  langCode = value.toLowerCase();
              }
              StorageService.saveUserPreferences(language: langCode);
            }
          },
        ),
      ],
    );
  }

  Widget _buildGenreDropdown(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título com botão de ajuda
        Row(
          children: [
            Expanded(
              child: Text(
                'Tipo de História',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.fireOrange,
                  fontSize: 14,
                ),
              ),
            ),
            // Botão de informação
            HelpTooltipWidget(
              message: HelpContent.tooltips['genre']!.text,
              child: IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                color: Colors.blue,
                onPressed: () {
                  HelpPopupWidget.show(context, HelpContent.genreHelp);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          initialValue: config.genre,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          dropdownColor: AppColors.darkBackground,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.o(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange.o(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 1),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Normal (usar nomes do idioma)',
                style: TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'western',
              child: Text(
                '🤠 Western/Faroeste',
                style: TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'business',
              child: Text(
                '💼 Corporativo (Em breve)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'family',
              child: Text(
                '👨‍👩‍👧‍👦 Familiar (Em breve)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (value) {
            // Bloquear seleção de opções "Em breve"
            if (value == 'business' || value == 'family') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Esta opção estará disponível em breve!'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            configNotifier.updateGenre(value);
          },
        ),
      ],
    );
  }

  Widget _buildLocalizationLevelDropdown(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título com botão de ajuda
        Row(
          children: [
            Expanded(
              child: Text(
                'Regionalismo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.fireOrange,
                  fontSize: 14,
                ),
              ),
            ),
            // Botão de informação
            HelpTooltipWidget(
              message: HelpContent.tooltips['localizationLevel']!.text,
              child: IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                color: Colors.blue,
                onPressed: () {
                  HelpPopupWidget.show(
                    context,
                    HelpContent.localizationLevelHelp,
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<LocalizationLevel>(
          initialValue: config.localizationLevel,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          dropdownColor: AppColors.darkBackground,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.o(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange.o(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 1),
            ),
          ),
          items: LocalizationLevel.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Tooltip(
                message: level.description,
                child: Text(
                  level.displayName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              configNotifier.updateLocalizationLevel(value);
              // Salvar preferência
              StorageService.saveUserPreferences(localizationLevel: value.name);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPerspectiveDropdown(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título com botão de ajuda
        Row(
          children: [
            Expanded(
              child: Text(
                'Perspectiva Narrativa',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.fireOrange,
                  fontSize: 14,
                ),
              ),
            ),
            // Botão de informação
            HelpTooltipWidget(
              message: HelpContent.tooltips['perspective']!.text,
              child: IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                color: Colors.blue,
                onPressed: () {
                  HelpPopupWidget.show(context, HelpContent.perspectiveHelp);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: config.perspective,
          style: const TextStyle(color: Colors.white, fontSize: 11),
          dropdownColor: AppColors.darkBackground,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.o(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange.o(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 1),
            ),
          ),
          items: GenerationConfig.availablePerspectives.map((perspective) {
            return DropdownMenuItem(
              value: perspective,
              child: Text(
                GenerationConfig.perspectiveLabels[perspective] ?? perspective,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.visible,
                maxLines: 2,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              configNotifier.updatePerspective(value);
              // Salvar preferência
              StorageService.saveUserPreferences(perspective: value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildStartWithTitlePhraseCheckbox(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return HelpTooltipWidget(
      message: HelpContent.tooltips['startWithTitle']!.text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: config.startWithTitlePhrase,
                onChanged: (bool? value) {
                  configNotifier.updateStartWithTitlePhrase(value ?? false);
                },
                activeColor: AppColors.fireOrange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  configNotifier.updateStartWithTitlePhrase(
                    !config.startWithTitlePhrase,
                  );
                },
                child: Text(
                  'Começar o roteiro com a frase do título',
                  style: AppDesignSystem.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrativeStyleDropdown(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título com botão de ajuda
        Row(
          children: [
            Expanded(
              child: Text(
                'Estilo de Narração',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.fireOrange,
                  fontSize: 14,
                ),
              ),
            ),
            // Botão de informação
            HelpTooltipWidget(
              message: HelpContent.tooltips['narrativeStyle']!.text,
              child: IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                color: Colors.blue,
                onPressed: () {
                  HelpPopupWidget.show(context, HelpContent.narrativeStyleHelp);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: config.narrativeStyle,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          dropdownColor: AppColors.darkBackground,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: AppColors.fireOrange.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 1),
            ),
          ),
          items: GenerationConfig.availableNarrativeStyles.map((style) {
            return DropdownMenuItem(
              value: style,
              child: Text(
                GenerationConfig.narrativeStyleLabels[style]!,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              configNotifier.updateNarrativeStyle(value);
            }
          },
        ),
      ],
    );
  }

  // 📝 NOVO: Checkbox para habilitar prompt customizado
  Widget _buildCustomPromptCheckbox(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: config.useCustomPrompt
            ? AppColors.fireOrange.withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: config.useCustomPrompt
              ? AppColors.fireOrange.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: config.useCustomPrompt,
              onChanged: (bool? value) {
                configNotifier.updateUseCustomPrompt(value ?? false);
              },
              activeColor: AppColors.fireOrange,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () {
                configNotifier.updateUseCustomPrompt(!config.useCustomPrompt);
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_suggest,
                    size: 16,
                    color: AppColors.fireOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Modo Avançado: Prompt Customizado',
                    style: AppDesignSystem.bodySmall.copyWith(
                      color: config.useCustomPrompt
                          ? AppColors.fireOrange
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: config.useCustomPrompt
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botão de ajuda
          IconButton(
            icon: const Icon(Icons.help_outline, size: 16),
            color: AppColors.textSecondary,
            onPressed: () {
              _showCustomPromptHelp();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Ver exemplos e guia de uso',
          ),
        ],
      ),
    );
  }

  // 📝 NOVO: Campo de texto para prompt customizado
  Widget _buildCustomPromptField(
    GenerationConfig config,
    GenerationConfigNotifier configNotifier,
  ) {
    if (!config.useCustomPrompt) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fireOrange.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.fireOrange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note,
                size: 18,
                color: AppColors.fireOrange,
              ),
              const SizedBox(width: 8),
              Text(
                'Instruções Personalizadas',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppColors.fireOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showCustomPromptHelp,
                icon: const Icon(Icons.lightbulb_outline, size: 14),
                label: const Text(
                  'Ver Exemplos',
                  style: TextStyle(fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.fireOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: config.customPrompt)
              ..selection = TextSelection.collapsed(
                offset: config.customPrompt.length,
              ),
            maxLines: 4,
            style: AppDesignSystem.bodyMedium.copyWith(fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  'Ex: Foco em diálogos intensos. Protagonista advogada. Tom sério, sem humor.',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: AppColors.fireOrange,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: AppColors.darkBackground,
            ),
            onChanged: (value) {
              configNotifier.updateCustomPrompt(value);
            },
          ),
          const SizedBox(height: 6),
          Text(
            '⚠️ Avançado: Estas instruções serão adicionadas ao prompt da IA. Use apenas se souber o que está fazendo.',
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // 📝 NOVO: Modal com exemplos de prompts customizados
  void _showCustomPromptHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Row(
          children: [
            const Icon(Icons.lightbulb, color: AppColors.fireOrange),
            const SizedBox(width: 8),
            Text(
              'Guia de Prompts Customizados',
              style: AppDesignSystem.headingMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exemplos de Instruções Personalizadas:',
                  style: AppDesignSystem.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildExamplePrompt(
                  '🎭 Foco Dramático',
                  'Foco em diálogos intensos e emocionais. Protagonista advogada. Tom sério, sem humor. Muitas cenas de tribunal.',
                ),
                _buildExamplePrompt(
                  '😂 Tom Humorístico',
                  'Narrativa leve e divertida. Incluir piadas sutis e situações cômicas. Protagonista desastrado mas carismático.',
                ),
                _buildExamplePrompt(
                  '🌿 Estilo Poético',
                  'Linguagem lírica e poética. Usar metáforas da natureza (rios, árvores, estações). Ritmo contemplativo.',
                ),
                _buildExamplePrompt(
                  '⚡ Ação Rápida',
                  'Ritmo acelerado. Frases curtas e diretas. Muita ação física. Pouca reflexão interna. Tensão constante.',
                ),
                _buildExamplePrompt(
                  '🔍 Mistério Investigativo',
                  'Tom de suspense policial. Protagonista detetive. Incluir pistas sutis. Reviravoltas inesperadas no meio da história.',
                ),
                _buildExamplePrompt(
                  '❤️ Romance Intenso',
                  'Foco na relação entre protagonista e par romântico. Muitas cenas de interação emocional. Tom apaixonado.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.fireOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.tips_and_updates,
                            size: 16,
                            color: AppColors.fireOrange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Dicas:',
                            style: AppDesignSystem.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.fireOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Seja específico mas conciso\n'
                        '• Combine múltiplos aspectos se necessário\n'
                        '• Evite contradizer configurações base\n'
                        '• Teste e ajuste conforme necessário',
                        style: AppDesignSystem.bodySmall.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.fireOrange),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplePrompt(String title, String example) {
    final configNotifier = ref.read(generationConfigProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.darkSecondary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.fireOrange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppDesignSystem.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.fireOrange,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  configNotifier.updateCustomPrompt(example);
                  configNotifier.updateUseCustomPrompt(true);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.content_copy, size: 12),
                label: const Text('Usar', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.fireOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            example,
            style: AppDesignSystem.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
