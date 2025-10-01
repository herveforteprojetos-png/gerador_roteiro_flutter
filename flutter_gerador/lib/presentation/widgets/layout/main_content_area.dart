import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/presentation/widgets/script_output/generation_progress_view.dart';
import 'package:flutter_gerador/presentation/widgets/script_output/script_result_view.dart';
import 'package:flutter_gerador/presentation/providers/script_generation_provider.dart';

class MainContentArea extends ConsumerWidget {
  const MainContentArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scriptGenerationProvider);
    final scriptController = TextEditingController(text: state.result?.scriptText ?? '');

    if (state.isGenerating && state.progress != null) {
      final progress = state.progress!;
      return GenerationProgressView(
        progress: progress,
        onCancel: () {
          // TODO: Cancelar geração via provider
        },
      );
    } else if (state.result != null) {
      final result = state.result!;
      return ScriptResultView(
        wordCount: result.wordCount,
        charCount: result.charCount,
        paragraphCount: result.paragraphCount,
        readingTime: result.readingTime,
        scriptController: scriptController,
        onDownloadTxt: () {
          // TODO: Implementar download TXT
        },
        onDownloadFormatted: () {
          // TODO: Implementar download formatado
        },
        context: context,
        onShowExtraTools: () {},
      );
    } else {
      return const Center(
        child: Text('Nenhum roteiro gerado ainda.', style: TextStyle(color: Colors.white)),
      );
    }
  }
}
