import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/presentation/widgets/script_output/generation_progress_view.dart';
import 'package:flutter_gerador/presentation/widgets/script_output/script_result_view.dart';
import 'package:flutter_gerador/presentation/providers/script_generation_provider.dart';

class MainContentArea extends ConsumerStatefulWidget {
  const MainContentArea({super.key});

  @override
  ConsumerState<MainContentArea> createState() => _MainContentAreaState();
}

class _MainContentAreaState extends ConsumerState<MainContentArea> {
  // 🚀 OTIMIZAÇÃO: Controller persistente evita recriação a cada rebuild
  late final TextEditingController _scriptController;

  @override
  void initState() {
    super.initState();
    _scriptController = TextEditingController();
  }

  @override
  void dispose() {
    _scriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scriptGenerationProvider);
    
    // 🚀 OTIMIZAÇÃO: Atualizar controller apenas quando resultado mudar
    if (state.result != null && _scriptController.text != state.result!.scriptText) {
      _scriptController.text = state.result!.scriptText;
    }

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
        scriptController: _scriptController,
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
