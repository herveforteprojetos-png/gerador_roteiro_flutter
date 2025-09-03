import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/generation_config_provider.dart';
import '../../providers/auxiliary_tools_provider.dart';
import '../../../data/models/generation_config.dart';
import '../../../core/theme/app_colors.dart';

class ExpandedHeaderWidget extends ConsumerStatefulWidget {
  const ExpandedHeaderWidget({super.key});

  @override
  ConsumerState<ExpandedHeaderWidget> createState() => _ExpandedHeaderWidgetState();
}

class _ExpandedHeaderWidgetState extends ConsumerState<ExpandedHeaderWidget> {
  late TextEditingController apiKeyController;
  late TextEditingController titleController;

  @override
  void initState() {
    super.initState();
    apiKeyController = TextEditingController();
    titleController = TextEditingController();
  }

  @override
  void dispose() {
    apiKeyController.dispose();
    titleController.dispose();
    super.dispose();
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
          // Primeira linha: API Key, Modelo, Título
          _buildFirstRow(config, configNotifier),
          const Divider(color: Colors.grey, height: 1),
          // Segunda linha: Medida, Idioma, Perspectiva, CTA, Botões
          _buildSecondRow(config, configNotifier),
        ],
      ),
    );
  }

  Widget _buildFirstRow(GenerationConfig config, GenerationConfigNotifier configNotifier) {
    return Padding(
      padding: const EdgeInsets.all(20),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Medida com Slider
              Container(
                width: 200,
                child: _buildMeasureSection(config, configNotifier),
              ),
              const SizedBox(width: 12),
              // Idioma
              Container(
                width: 100,
                child: _buildLanguageDropdown(config, configNotifier),
              ),
              const SizedBox(width: 12),
              // Perspectiva
              Container(
                width: 180,
                child: _buildPerspectiveDropdown(config, configNotifier),
              ),
              const SizedBox(width: 12),
              // Checkbox CTA
              Container(
                width: 120,
                child: _buildCallToActionCheckbox(config, configNotifier),
              ),
              const SizedBox(width: 12),
              // Botões Auxiliares
              _buildAuxiliaryButtons(config, auxiliaryState, auxiliaryNotifier),
              const SizedBox(width: 12),
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
    final isValidApiKey = config.apiKey.isNotEmpty && config.apiKey.length > 20;
    
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
            suffixIcon: isValidApiKey 
              ? Container(
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
                )
              : null,
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isValidApiKey ? Colors.green : AppColors.fireOrange,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isValidApiKey 
                  ? Colors.green.withOpacity(0.7) 
                  : AppColors.fireOrange.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isValidApiKey ? Colors.green : AppColors.fireOrange,
                width: 2,
              ),
            ),
          ),
          onChanged: configNotifier.updateApiKey,
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
              value: 'gemini-1.5-pro',
              child: Text('Gemini 1.5 Pro'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20), // Espaço para alinhar com outros campos
        OutlinedButton.icon(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAuxiliaryButtons(
    GenerationConfig config, 
    AuxiliaryToolsState auxiliaryState, 
    AuxiliaryToolsNotifier auxiliaryNotifier
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20), // Espaço para alinhar com outros campos
        Row(
          children: [
            // Botão Gerar Contexto Auto
            OutlinedButton.icon(
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            // Botão Gerar Prompt Imagem
            OutlinedButton.icon(
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
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
