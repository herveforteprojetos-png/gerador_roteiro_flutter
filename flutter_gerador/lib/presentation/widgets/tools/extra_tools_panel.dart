import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/extra_tools_provider.dart';
import '../../providers/generation_config_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../download/download_manager.dart';

class ExtraToolsPanel extends ConsumerWidget {
  final String scriptText;

  const ExtraToolsPanel({
    super.key,
    required this.scriptText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extraState = ref.watch(extraToolsProvider);
    final extraNotifier = ref.read(extraToolsProvider.notifier);
    final config = ref.watch(generationConfigProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        border: Border.all(color: AppColors.fireOrange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header do painel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fireOrange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.fireOrange.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.build_circle,
                  color: AppColors.fireOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ferramentas Extras',
                  style: TextStyle(
                    color: AppColors.fireOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Lista de ferramentas
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Botão SRT
                  _buildToolButton(
                    context: context,
                    icon: Icons.subtitles,
                    title: 'Gerar SRT',
                    description: 'Legendas para vídeo',
                    isLoading: extraState.isGeneratingSRT,
                    onPressed: config.apiKey.isEmpty
                        ? null
                        : () => _generateAndShow(
                              context,
                              ref,
                              () => extraNotifier.generateSRTSubtitles(config, scriptText),
                              'Legendas SRT Geradas',
                              'Arquivo SRT para legendas de vídeo',
                              extraState.generatedSRT,
                            ),
                  ),
                  const SizedBox(height: 12),

                  // Botão YouTube
                  _buildToolButton(
                    context: context,
                    icon: Icons.video_library,
                    title: 'Desc. YouTube',
                    description: 'Descrição otimizada',
                    isLoading: extraState.isGeneratingYouTube,
                    onPressed: config.apiKey.isEmpty
                        ? null
                        : () => _generateAndShow(
                              context,
                              ref,
                              () => extraNotifier.generateYouTubeDescription(config, scriptText),
                              'Descrição YouTube Gerada',
                              'Descrição otimizada para SEO e engajamento',
                              extraState.generatedYouTube,
                            ),
                  ),
                  const SizedBox(height: 12),

                  // Botão Prompts Extras
                  _buildToolButton(
                    context: context,
                    icon: Icons.lightbulb,
                    title: 'Prompts Extras',
                    description: 'Ideias e expansões',
                    isLoading: extraState.isGeneratingPrompts,
                    onPressed: config.apiKey.isEmpty
                        ? null
                        : () => _generateAndShow(
                              context,
                              ref,
                              () => extraNotifier.generateAdditionalPrompts(config, scriptText),
                              'Prompts Adicionais Gerados',
                              'Ideias para expandir o conteúdo em diferentes formatos',
                              extraState.generatedPrompts,
                            ),
                  ),

                  const Spacer(),

                  // Botão Limpar Todas as Ferramentas
                  OutlinedButton.icon(
                    onPressed: () {
                      extraNotifier.clearAll();
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Limpar Tudo'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withOpacity(0.7)),
                      foregroundColor: Colors.red.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: onPressed == null 
              ? Colors.grey.withOpacity(0.5)
              : AppColors.fireOrange.withOpacity(0.7)
          ),
          foregroundColor: onPressed == null 
            ? Colors.grey
            : AppColors.fireOrange,
          backgroundColor: onPressed == null 
            ? Colors.grey.withOpacity(0.1)
            : AppColors.fireOrange.withOpacity(0.05),
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          children: [
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.fireOrange),
                    ),
                  )
                : Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: onPressed == null 
                        ? Colors.grey
                        : Colors.white.withOpacity(0.7),
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

  Future<void> _generateAndShow(
    BuildContext context,
    WidgetRef ref,
    Future<String> Function() generator,
    String title,
    String description,
    String? existingContent,
  ) async {
    try {
      String content;
      if (existingContent != null) {
        content = existingContent;
      } else {
        content = await generator();
      }

      if (context.mounted) {
        await DownloadManager.showDownloadDialog(
          context: context,
          title: title,
          content: content,
          fileName: _getFileName(title),
          fileExtension: _getFileExtension(title),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFileName(String title) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    if (title.contains('SRT')) {
      return 'legendas_$timestamp';
    } else if (title.contains('YouTube')) {
      return 'descricao_youtube_$timestamp';
    } else if (title.contains('Roteiro')) {
      return 'roteiro_detalhado_$timestamp';
    } else if (title.contains('Análise')) {
      return 'analise_personagens_$timestamp';
    } else if (title.contains('Contexto')) {
      return 'contexto_historico_$timestamp';
    } else if (title.contains('Diálogos')) {
      return 'dialogos_extras_$timestamp';
    }
    
    return 'conteudo_gerado_$timestamp';
  }

  String _getFileExtension(String title) {
    if (title.contains('SRT')) {
      return 'srt';
    } else if (title.contains('YouTube')) {
      return 'txt';
    } else {
      return 'txt';
    }
  }
}
