import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/presentation/providers/extra_tools_provider.dart';
import 'package:flutter_gerador/presentation/providers/generation_config_provider.dart';
import '../../providers/auxiliary_tools_provider.dart';
import 'package:flutter_gerador/core/theme/app_colors.dart';
import '../download/download_manager.dart';
import 'package:flutter_gerador/core/utils/color_extensions.dart';
import '../dialogs/cta_config_dialog.dart';

class ExtraToolsPanel extends ConsumerWidget {
  final String scriptText;
  final TextEditingController? contextController;

  const ExtraToolsPanel({
    super.key,
    required this.scriptText,
    this.contextController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extraState = ref.watch(extraToolsProvider);
    final extraNotifier = ref.read(extraToolsProvider.notifier);
    final config = ref.watch(generationConfigProvider);

    // 🔄 Verificar automaticamente se o SRT precisa ser invalidado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      extraNotifier.invalidateSrtIfTextChanged(scriptText);
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        border: Border.all(color: AppColors.fireOrange.o(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header do painel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fireOrange.o(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.fireOrange.o(0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.build_circle, color: AppColors.fireOrange, size: 20),
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Botão SRT
                    _buildToolButton(
                      context: context,
                      icon: Icons.subtitles,
                      title: extraState.isSrtValid
                          ? 'Gerar SRT'
                          : 'Atualizar SRT',
                      description: extraState.isSrtValid
                          ? 'Legendas para vídeo'
                          : 'SRT precisa ser atualizado',
                      isLoading: extraState.isGeneratingSRT,
                      needsUpdate:
                          !extraState.isSrtValid &&
                          extraState.generatedSRT != null,
                      onPressed: config.apiKey.isEmpty
                          ? null
                          : () => _generateAndShow(
                              context,
                              ref,
                              () => extraNotifier.generateSRTSubtitles(
                                config,
                                scriptText,
                              ),
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
                              () => extraNotifier.generateYouTubeDescription(
                                config,
                                scriptText,
                              ),
                              'Descrição YouTube Gerada',
                              'Descrição otimizada para SEO e engajamento',
                              extraState.generatedYouTube,
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Botão Prompt Protagonista
                    _buildToolButton(
                      context: context,
                      icon: Icons.person,
                      title: 'Prompt Protagonista',
                      description: 'Personagem principal',
                      isLoading: extraState.isGeneratingPrompts,
                      onPressed: config.apiKey.isEmpty
                          ? null
                          : () => _generateAndShow(
                              context,
                              ref,
                              () => extraNotifier.generateProtagonistPrompt(
                                config,
                                scriptText,
                              ),
                              'Prompt do Protagonista Gerado',
                              'Prompt em inglês para gerar imagem do protagonista no Midjourney',
                              extraState.generatedPrompts,
                            ),
                    ),
                    const SizedBox(height: 12),

                    // 🎬 v7.6.13: Botão Prompt Cenas Principais (4 cenas cinematográficas)
                    _buildToolButton(
                      context: context,
                      icon: Icons.movie_filter,
                      title: 'Prompt Cenas Principais',
                      description:
                          '4 cenas cinematográficas com múltiplos personagens',
                      isLoading: extraState.isGeneratingScenario,
                      onPressed: config.apiKey.isEmpty
                          ? null
                          : () => _generateAndShow(
                              context,
                              ref,
                              () => extraNotifier.generateKeyScenes(
                                config,
                                scriptText,
                              ),
                              'Prompts das Cenas Principais Gerados',
                              '4 cenas cinematográficas principais com múltiplos personagens',
                              extraState.generatedScenario,
                            ),
                    ),

                    const SizedBox(height: 12),

                    // Botão CTAs Personalizados
                    _buildToolButton(
                      context: context,
                      icon: Icons.campaign,
                      title: 'Gerar 3 CTAs',
                      description: 'Início, Meio e Fim de uma vez',
                      isLoading: false,
                      onPressed: () => _openCtaDialog(context, ref),
                    ),

                    const SizedBox(height: 24),

                    // Botão Limpar Todas as Ferramentas
                    OutlinedButton.icon(
                      onPressed: () {
                        extraNotifier.clearAll();
                        // Limpar também o campo de contexto se disponível
                        if (contextController != null) {
                          contextController!.clear();
                        }
                        // Limpar também o contexto gerado automaticamente
                        final auxiliaryNotifier = ref.read(
                          auxiliaryToolsProvider.notifier,
                        );
                        auxiliaryNotifier.clearContext();
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Limpar Tudo'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.o(0.7)),
                        foregroundColor: Colors.red.o(0.8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
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
    bool needsUpdate = false, // 🔄 Novo parâmetro
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: onPressed == null
                ? Colors.grey.o(0.5)
                : needsUpdate
                ? Colors.orange.o(0.8) // 🔄 Destaque quando precisa atualizar
                : AppColors.fireOrange.o(0.7),
          ),
          foregroundColor: onPressed == null
              ? Colors.grey
              : needsUpdate
              ? Colors
                    .orange // 🔄 Cor diferente quando precisa atualizar
              : AppColors.fireOrange,
          backgroundColor: onPressed == null
              ? Colors.grey.o(0.1)
              : needsUpdate
              ? Colors.orange.o(
                  0.1,
                ) // 🔄 Fundo diferente quando precisa atualizar
              : AppColors.fireOrange.o(0.05),
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          children: [
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.fireOrange,
                      ),
                    ),
                  )
                : Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // 🔄 Ícone de aviso quando precisa atualizar
                      if (needsUpdate) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: onPressed == null
                          ? Colors.grey
                          : Colors.white.o(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

      // 🔄 Para SRT, sempre verificar se é válido antes de usar conteúdo existente
      final extraState = ref.read(extraToolsProvider);
      final isSrtRequest = title.contains('SRT');

      if (existingContent != null && (!isSrtRequest || extraState.isSrtValid)) {
        // Use conteúdo existente apenas se não for SRT ou se SRT for válido
        content = existingContent;
      } else {
        // Regenera sempre se for SRT inválido ou se não há conteúdo
        content = await generator();
      }

      if (context.mounted) {
        await DownloadManager.showDownloadDialog(
          context: context,
          title: title,
          content: content,
          fileName: _sanitizeFileName(title),
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

  String _getFileExtension(String title) {
    if (title.contains('SRT')) {
      return 'srt';
    } else if (title.contains('YouTube')) {
      return 'txt';
    } else {
      return 'txt';
    }
  }

  String _sanitizeFileName(String title) {
    final sanitized = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\- ]'), '')
        .replaceAll(' ', '_')
        .replaceAll('__', '_');

    // Usar o tamanho da string já processada para evitar RangeError
    return sanitized.substring(0, sanitized.length.clamp(0, 40));
  }

  void _openCtaDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const CtaConfigDialog(),
      barrierDismissible: false,
    );
  }
}
