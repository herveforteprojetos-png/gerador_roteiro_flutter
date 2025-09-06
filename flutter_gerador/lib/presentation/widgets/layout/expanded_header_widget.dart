import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../providers/generation_config_provider.dart';
import '../../providers/auxiliary_tools_provider.dart';
import '../../../data/models/generation_config.dart';
import '../../../data/services/api_validation_service.dart';
import '../../../core/theme/app_colors.dart';

class ExpandedHeaderWidget extends ConsumerStatefulWidget {
  const ExpandedHeaderWidget({super.key});

  @override
  ConsumerState<ExpandedHeaderWidget> createState() => _ExpandedHeaderWidgetState();
}

class _ExpandedHeaderWidgetState extends ConsumerState<ExpandedHeaderWidget> {
  late TextEditingController apiKeyController;
  late TextEditingController titleController;
  
  // Estados de validação da API
  ValidationState _validationState = ValidationState.initial;
  String? _validationErrorMessage;
  Timer? _validationTimer;

  @override
  void initState() {
    super.initState();
    apiKeyController = TextEditingController();
    titleController = TextEditingController();
    
    // Adicionar listener para validação em tempo real
    apiKeyController.addListener(_onApiKeyChanged);
  }

  @override
  void dispose() {
    apiKeyController.removeListener(_onApiKeyChanged);
    apiKeyController.dispose();
    titleController.dispose();
    _validationTimer?.cancel();
    super.dispose();
  }

  void _onApiKeyChanged() {
    // Cancelar timer anterior se existir
    _validationTimer?.cancel();
    
    final apiKey = apiKeyController.text.trim();
    
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
            // Atualizar o provider apenas se a chave for válida
            ref.read(generationConfigProvider.notifier).updateApiKey(apiKey);
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

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(generationConfigProvider);
    final configNotifier = ref.read(generationConfigProvider.notifier);

    // Sincronizar controllers com estado
    if (apiKeyController.text != config.apiKey) {
      apiKeyController.text = config.apiKey;
    }
    if (titleController.text != config.title) {
      titleController.text = config.title;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.fireOrange, width: 2),
        ),
      ),
      child: Column(
        children: [
          // Primeira linha: CONFIGURAÇÃO TÉCNICA
          _buildTechnicalConfigSection(config, configNotifier),
          const Divider(color: Colors.grey, height: 1),
          // Segunda linha: CONFIGURAÇÃO DE CONTEÚDO + FERRAMENTAS
          _buildContentAndToolsSection(config, configNotifier),
        ],
      ),
    );
  }

  Widget _buildTechnicalConfigSection(GenerationConfig config, GenerationConfigNotifier configNotifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          Row(
            children: [
              Icon(Icons.settings, color: AppColors.fireOrange, size: 18),
              const SizedBox(width: 8),
              Text(
                'CONFIGURAÇÃO TÉCNICA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.fireOrange,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Campos da configuração técnica
          Row(
            children: [
              // Campo Chave da API
              Expanded(
                flex: 3,
                child: _buildApiKeyField(configNotifier),
              ),
              const SizedBox(width: 20),
              // Dropdown Modelo
              Expanded(
                flex: 1,
                child: _buildModelDropdown(config, configNotifier),
              ),
              const SizedBox(width: 20),
              // Dropdown Idioma
              Expanded(
                flex: 1,
                child: _buildLanguageDropdown(config, configNotifier),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentAndToolsSection(GenerationConfig config, GenerationConfigNotifier configNotifier) {
    final auxiliaryState = ref.watch(auxiliaryToolsProvider);
    final auxiliaryNotifier = ref.read(auxiliaryToolsProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), // Aumentei padding top de 0 para 16
      child: Row(
        children: [
          // Seção de Configuração de Conteúdo
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(20), // Aumentei padding de 16 para 20
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.fireOrange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título da seção
                  Row(
                    children: [
                      Icon(Icons.edit_document, color: AppColors.fireOrange, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'CONFIGURAÇÃO DO CONTEÚDO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.fireOrange,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Aumentei de 12 para 16
                  // Campo Título + Configurações de conteúdo
                  Column(
                    children: [
                      // Campo Título
                      _buildTitleField(configNotifier),
                      const SizedBox(height: 16), // Aumentei de 12 para 16
                      // Linha com Medida, Perspectiva e CTA
                      Row(
                        children: [
                          // Medida com Slider
                          Expanded(
                            flex: 2,
                            child: _buildMeasureSection(config, configNotifier),
                          ),
                          const SizedBox(width: 16),
                          // Perspectiva
                          Expanded(
                            flex: 1,
                            child: _buildPerspectiveDropdown(config, configNotifier),
                          ),
                          const SizedBox(width: 16),
                          // Checkbox CTA
                          Container(
                            width: 120,
                            child: _buildCallToActionCheckbox(config, configNotifier),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24), // Aumentei de 20 para 24
          // Seção de Ferramentas Auxiliares
          Container(
            padding: const EdgeInsets.all(20), // Aumentei padding de 16 para 20
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.fireOrange.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título da seção
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.fireOrange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'FERRAMENTAS AUXILIARES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.fireOrange,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Aumentei de 12 para 20
                // Botões das ferramentas
                Column(
                  children: [
                    _buildAuxiliaryButtons(config, auxiliaryState, auxiliaryNotifier),
                    const SizedBox(height: 16), // Aumentei de 12 para 16
                    _buildClearButton(configNotifier),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstRow(GenerationConfig config, GenerationConfigNotifier configNotifier) {
    return Padding(
      padding: const EdgeInsets.all(16), // Reduzido de 20 para 16
      child: Row(
        children: [
          // Campo Chave da API
          Expanded(
            flex: 3,
            child: _buildApiKeyField(configNotifier),
          ),
          const SizedBox(width: 20),
          // Dropdown Modelo
          Expanded(
            flex: 1,
            child: _buildModelDropdown(config, configNotifier),
          ),
          const SizedBox(width: 20),
          // Dropdown Idioma (movido da segunda linha)
          Expanded(
            flex: 1,
            child: _buildLanguageDropdown(config, configNotifier),
          ),
          const SizedBox(width: 20),
          // Campo Título
          Expanded(
            flex: 3,
            child: _buildTitleField(configNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondRow(GenerationConfig config, GenerationConfigNotifier configNotifier) {
    final auxiliaryState = ref.watch(auxiliaryToolsProvider);
    final auxiliaryNotifier = ref.read(auxiliaryToolsProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), // Reduzido padding bottom de 20 para 16
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Medida com Slider
              Container(
                width: 220, // Aumentado de 180 para 220 (mais espaço sem o idioma)
                child: _buildMeasureSection(config, configNotifier),
              ),
              const SizedBox(width: 24), // Aumentado para 24
              // Perspectiva
              Container(
                width: 180, // Aumentado de 160 para 180
                child: _buildPerspectiveDropdown(config, configNotifier),
              ),
              const SizedBox(width: 24), // Aumentado para 24
              // Checkbox CTA
              Container(
                width: 140, // Aumentado de 120 para 140
                child: _buildCallToActionCheckbox(config, configNotifier),
              ),
              const SizedBox(width: 28), // Aumentado para 28
              // Botões Auxiliares
              _buildAuxiliaryButtons(config, auxiliaryState, auxiliaryNotifier),
              const SizedBox(width: 28), // Aumentado para 28
              // Botão Limpar
              _buildClearButton(configNotifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyField(GenerationConfigNotifier configNotifier) {
    final config = ref.watch(generationConfigProvider);
    
    // Determinar cor e ícone baseado no estado de validação
    Color borderColor;
    Widget? suffixIcon;
    String? helperText;
    Color? helperTextColor;
    
    switch (_validationState) {
      case ValidationState.initial:
        borderColor = AppColors.fireOrange;
        suffixIcon = null;
        helperText = null;
        break;
      case ValidationState.validating:
        borderColor = Colors.orange;
        suffixIcon = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
        helperText = 'Validando chave da API...';
        helperTextColor = Colors.orange;
        break;
      case ValidationState.valid:
        borderColor = Colors.green;
        suffixIcon = Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 16,
          ),
        );
        helperText = 'Chave da API válida ✓';
        helperTextColor = Colors.green;
        break;
      case ValidationState.invalid:
        borderColor = Colors.red;
        suffixIcon = Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 16,
          ),
        );
        helperText = _validationErrorMessage ?? 'Chave da API inválida';
        helperTextColor = Colors.red;
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chave da API Gemini',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.fireOrange,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: apiKeyController,
          obscureText: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Cole sua chave da API aqui...',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
            prefixIcon: Icon(Icons.key, color: AppColors.fireOrange, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            helperText: helperText,
            helperStyle: TextStyle(
              color: helperTextColor,
              fontSize: 12,
            ),
          ),
          // Removemos o onChanged daqui pois agora usamos o listener
        ),
      ],
    );
  }

  Widget _buildModelDropdown(GenerationConfig config, GenerationConfigNotifier configNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modelo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.fireOrange,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: config.model,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          dropdownColor: AppColors.darkBackground,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'gemini-2.5-pro',
              child: Text('Gemini 2.5 Pro'),
            ),
            DropdownMenuItem(
              value: 'gemini-1.5-flash',
              child: Text('Gemini 1.5 Flash'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              configNotifier.updateModel(value);
            }
          },
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.fireOrange,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Digite o título da sua história...',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
            prefixIcon: Icon(Icons.title, color: AppColors.fireOrange, size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
            ),
          ),
          onChanged: configNotifier.updateTitle,
        ),
      ],
    );
  }

  Widget _buildMeasureSection(GenerationConfig config, GenerationConfigNotifier configNotifier) {
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
        Row(
          children: [
            // Dropdown de tipo de medida
            Expanded(
              child: DropdownButtonFormField<String>(
                value: config.measureType,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                dropdownColor: AppColors.darkBackground,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.fireOrange),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.fireOrange.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'palavras', child: Text('Palavras')),
                  DropdownMenuItem(value: 'caracteres', child: Text('Caracteres')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    configNotifier.updateMeasureType(value);
                  }
                },
              ),
            ),
          ],
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
              inactiveColor: AppColors.fireOrange.withOpacity(0.3),
              onChanged: (value) {
                configNotifier.updateQuantity(value.toInt());
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

  Widget _buildLanguageDropdown(GenerationConfig config, GenerationConfigNotifier configNotifier) {
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
          value: config.language,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          dropdownColor: AppColors.darkBackground,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange.withOpacity(0.5)),
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
            }
          },
        ),
      ],
    );
  }

  Widget _buildPerspectiveDropdown(GenerationConfig config, GenerationConfigNotifier configNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perspectiva Narrativa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.fireOrange,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: config.perspective,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          dropdownColor: AppColors.darkBackground,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.fireOrange.withOpacity(0.5)),
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
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              configNotifier.updatePerspective(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCallToActionCheckbox(GenerationConfig config, GenerationConfigNotifier configNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Call-to-Action',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.fireOrange,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: config.includeCallToAction,
          title: const Text(
            'Incluir CTA',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          activeColor: AppColors.fireOrange,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            configNotifier.updateIncludeCallToAction(value ?? false);
          },
        ),
      ],
    );
  }

  Widget _buildClearButton(GenerationConfigNotifier configNotifier) {
    return SizedBox(
      width: 200,
      child: OutlinedButton.icon(
        onPressed: () {
          configNotifier.clearAll();
          apiKeyController.clear();
          titleController.clear();
        },
        icon: const Icon(Icons.cleaning_services, size: 18),
        label: const Text('🧹 Limpar Tudo'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.fireOrange),
          foregroundColor: AppColors.fireOrange,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAuxiliaryButtons(
    GenerationConfig config, 
    AuxiliaryToolsState auxiliaryState, 
    AuxiliaryToolsNotifier auxiliaryNotifier
  ) {
    return Column(
      children: [
        // Botão Gerar Contexto Auto
        SizedBox(
          width: 200,
          child: OutlinedButton.icon(
            onPressed: auxiliaryState.isGeneratingContext || config.apiKey.isEmpty || config.title.isEmpty
                ? null
                : () async {
                    try {
                      await auxiliaryNotifier.generateContext(config);
                      if (auxiliaryState.generatedContext != null) {
                        _showGeneratedContentDialog(
                          context,
                          'Contexto Gerado',
                          auxiliaryState.generatedContext!,
                          'Contexto gerado automaticamente com base no título e configurações.',
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao gerar contexto: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            icon: auxiliaryState.isGeneratingContext
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: const Text('🤖 Gerar Contexto Auto'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.fireOrange),
              foregroundColor: AppColors.fireOrange,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 12), // Aumentei de 8 para 12
        // Botão Gerar Prompt Imagem
        SizedBox(
          width: 200,
          child: OutlinedButton.icon(
            onPressed: auxiliaryState.isGeneratingImagePrompt || config.apiKey.isEmpty || config.title.isEmpty
                ? null
                : () async {
                    try {
                      final context = auxiliaryState.generatedContext ?? 'Roteiro baseado no título: ${config.title}';
                      await auxiliaryNotifier.generateImagePrompt(config, context);
                      if (auxiliaryState.generatedImagePrompt != null) {
                        _showGeneratedContentDialog(
                          this.context,
                          'Prompt de Imagem Gerado',
                          auxiliaryState.generatedImagePrompt!,
                          'Prompt otimizado para geração de imagens com IA (DALL-E, Midjourney, etc.)',
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao gerar prompt: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            icon: auxiliaryState.isGeneratingImagePrompt
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image, size: 18),
            label: const Text('🎨 Gerar Prompt Imagem'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.fireOrange),
              foregroundColor: AppColors.fireOrange,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  void _showGeneratedContentDialog(
    BuildContext context,
    String title,
    String content,
    String description,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.darkBackground,
          title: Text(
            title,
            style: TextStyle(color: AppColors.fireOrange, fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: 600,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      border: Border.all(color: AppColors.fireOrange.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Fechar',
                style: TextStyle(color: AppColors.fireOrange),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conteúdo copiado para área de transferência'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.fireOrange),
                foregroundColor: AppColors.fireOrange,
              ),
              child: const Text('Copiar'),
            ),
          ],
        );
      },
    );
  }
}
