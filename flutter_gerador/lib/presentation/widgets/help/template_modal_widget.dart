import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/data/models/field_help.dart';
import 'package:flutter_gerador/data/constants/help_content.dart';
import 'package:flutter_gerador/core/theme/app_colors.dart';
import 'package:flutter_gerador/presentation/providers/generation_config_provider.dart';

/// Modal com templates de configuração pré-definidos
class TemplateModalWidget extends ConsumerWidget {
  const TemplateModalWidget({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TemplateModalWidget(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 800),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.fireOrange.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
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
                  Expanded(
                    child: Text(
                      '🎯 Combinações Recomendadas',
                      style: TextStyle(
                        color: AppColors.fireOrange,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Escolha um caso de uso para preencher automaticamente os campos:',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ),

            // Templates list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: HelpContent.templates.length,
                itemBuilder: (context, index) {
                  final template = HelpContent.templates[index];
                  return _buildTemplateCard(context, ref, template);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    WidgetRef ref,
    ConfigTemplate template,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fireOrange.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Text(template.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    template.title,
                    style: TextStyle(
                      color: AppColors.fireOrange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  template.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // Configuration details
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: template.config.entries.map((entry) {
                    return _buildConfigChip(entry.key, entry.value.toString());
                  }).toList(),
                ),

                // Result preview
                if (template.resultPreview != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📝 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            template.resultPreview!,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Avoids
                if (template.avoids != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⚠️ ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            'Evita automaticamente: ${template.avoids!.join(", ")}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Apply button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _applyTemplate(context, ref, template);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fireOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Aplicar Esta Configuração',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigChip(String key, String value) {
    // Format key for display
    String displayKey = key;
    switch (key) {
      case 'perspective':
        displayKey = 'Perspectiva';
        break;
      case 'narrativeStyle':
        displayKey = 'Estilo';
        break;
      case 'tema':
        displayKey = 'Tema';
        break;
      case 'subtema':
        displayKey = 'Subtema';
        break;
      case 'localizacao':
        displayKey = 'Localização';
        break;
      case 'genre':
        displayKey = 'Gênero';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅ ', style: TextStyle(fontSize: 12)),
          Text(
            '$displayKey: ',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _applyTemplate(
    BuildContext context,
    WidgetRef ref,
    ConfigTemplate template,
  ) {
    final configNotifier = ref.read(generationConfigProvider.notifier);
    final config = template.config;

    // Apply each configuration
    if (config.containsKey('perspective')) {
      configNotifier.updatePerspective(config['perspective']);
    }

    if (config.containsKey('narrativeStyle')) {
      configNotifier.updateNarrativeStyle(config['narrativeStyle']);
    }

    if (config.containsKey('tema')) {
      configNotifier.updateTema(config['tema']);
    }

    if (config.containsKey('subtema')) {
      configNotifier.updateSubtema(config['subtema']);
    }

    if (config.containsKey('localizacao')) {
      configNotifier.updateLocalizacao(config['localizacao']);
    }

    // Close modal
    Navigator.of(context).pop();

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(template.emoji),
            const SizedBox(width: 8),
            Expanded(child: Text('Configuração "${template.title}" aplicada!')),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
