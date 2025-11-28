import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/script_generation_provider.dart';
import '../../../core/theme/app_colors.dart';

class CtaConfigDialog extends ConsumerStatefulWidget {
  const CtaConfigDialog({super.key});

  @override
  ConsumerState<CtaConfigDialog> createState() => _CtaConfigDialogState();
}

class _CtaConfigDialogState extends ConsumerState<CtaConfigDialog> {
  bool _isGenerating = false;

  // Controladores para os 3 CTAs editáveis
  final TextEditingController _ctaBeginningController = TextEditingController();
  final TextEditingController _ctaMiddleController = TextEditingController();
  final TextEditingController _ctaEndController = TextEditingController();

  @override
  void dispose() {
    _ctaBeginningController.dispose();
    _ctaMiddleController.dispose();
    _ctaEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasGeneratedCtas =
        _ctaBeginningController.text.isNotEmpty ||
        _ctaMiddleController.text.isNotEmpty ||
        _ctaEndController.text.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gerador de CTAs Completo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Descrição
            Text(
              'Gere os 3 CTAs de uma vez (Início, Meio e Fim). O sistema analisará o tom e pessoa narrativa do roteiro para criar CTAs naturais. Você pode editar os textos antes de aplicar.',
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Botão para gerar os 3 CTAs
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateAllCtas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.fireOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isGenerating
                      ? 'Gerando os 3 CTAs...'
                      : 'Gerar 3 CTAs (Início + Meio + Fim)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Preview e edição dos CTAs gerados
            if (hasGeneratedCtas) ...[
              const SizedBox(height: 24),

              // Container expandido para os 3 CTAs editáveis
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CTA do Início
                      _buildCtaEditor(
                        title: 'CTA do Início',
                        controller: _ctaBeginningController,
                        icon: Icons.play_circle_outline,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 16),

                      // CTA do Meio
                      _buildCtaEditor(
                        title: 'CTA do Meio',
                        controller: _ctaMiddleController,
                        icon: Icons.timeline,
                        color: Colors.orange,
                      ),

                      const SizedBox(height: 16),

                      // CTA do Final
                      _buildCtaEditor(
                        title: 'CTA do Final',
                        controller: _ctaEndController,
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isGenerating ? null : _generateAllCtas,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.fireOrange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(
                        Icons.refresh,
                        color: AppColors.fireOrange,
                      ),
                      label: const Text(
                        'Regenerar Todos',
                        style: TextStyle(
                          color: AppColors.fireOrange,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _applyAllCtas,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fireOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Aplicar os 3 CTAs ao Roteiro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCtaEditor({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'O CTA aparecerá aqui após a geração...',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
              filled: true,
              fillColor: Colors.grey[850],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAllCtas() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final scriptState = ref.read(scriptGenerationProvider);
      if (scriptState.result?.scriptText == null) {
        throw Exception('Nenhum roteiro encontrado para gerar CTAs');
      }

      final scriptText = scriptState.result!.scriptText;

      // Gerar os 3 CTAs em paralelo
      final results = await Future.wait([
        ref
            .read(scriptGenerationProvider.notifier)
            .generateCtas(scriptText, 'beginning'),
        ref
            .read(scriptGenerationProvider.notifier)
            .generateCtas(scriptText, 'middle'),
        ref
            .read(scriptGenerationProvider.notifier)
            .generateCtas(scriptText, 'end'),
      ]);

      setState(() {
        // Preencher os controladores com os CTAs gerados
        _ctaBeginningController.text = results[0].isNotEmpty
            ? results[0].first
            : '';
        _ctaMiddleController.text = results[1].isNotEmpty
            ? results[1].first
            : '';
        _ctaEndController.text = results[2].isNotEmpty ? results[2].first : '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ 3 CTAs gerados com sucesso! Você pode editá-los antes de aplicar.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar CTAs: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _applyAllCtas() {
    try {
      // Coletar CTAs não vazios
      final ctas = <String>[];
      final positions = <String>[];

      if (_ctaBeginningController.text.trim().isNotEmpty) {
        ctas.add(_ctaBeginningController.text.trim());
        positions.add('beginning');
      }

      if (_ctaMiddleController.text.trim().isNotEmpty) {
        ctas.add(_ctaMiddleController.text.trim());
        positions.add('middle');
      }

      if (_ctaEndController.text.trim().isNotEmpty) {
        ctas.add(_ctaEndController.text.trim());
        positions.add('end');
      }

      if (ctas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum CTA para aplicar. Gere os CTAs primeiro.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Aplicar todos os CTAs de uma vez
      ref
          .read(scriptGenerationProvider.notifier)
          .applyCtasToScript(ctas, positions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${ctas.length} CTA(s) aplicado(s) ao roteiro com sucesso!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ver Roteiro',
              textColor: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aplicar CTAs: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
