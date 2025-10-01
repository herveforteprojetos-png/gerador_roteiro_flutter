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
  String _selectedPosition = 'end';
  bool _isGenerating = false;
  List<String> _generatedCtas = [];

  final Map<String, String> _positionLabels = {
    'beginning': 'Início do roteiro',
    'middle': 'Meio do roteiro', 
    'end': 'Final do roteiro',
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gerador de CTAs',
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
              'O sistema analisará automaticamente o tom e pessoa narrativa do seu roteiro para gerar CTAs que se integram naturalmente ao conteúdo.',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            
            // Seleção de posição
            const Text(
              'Posição do CTA:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            // Radio buttons mais compactos
            Column(
              children: _positionLabels.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RadioListTile<String>(
                  title: Text(
                    entry.value,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  value: entry.key,
                  groupValue: _selectedPosition,
                  onChanged: (value) {
                    setState(() {
                      _selectedPosition = value!;
                      _generatedCtas.clear(); // Limpa CTAs anteriores
                    });
                  },
                  activeColor: AppColors.fireOrange,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  dense: true,
                ),
              )).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Botão para gerar CTAs
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateCtas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.fireOrange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isGenerating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Gerando CTAs...', style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : const Text(
                        'Gerar CTAs',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
            
            // Preview dos CTAs gerados
            if (_generatedCtas.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'CTAs Gerados:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Container expandido para o preview
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    border: Border.all(color: AppColors.fireOrange.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _generatedCtas.asMap().entries.map((entry) {
                        final index = entry.key;
                        final cta = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800]?.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.fireOrange.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CTA ${index + 1}:',
                                  style: TextStyle(
                                    color: AppColors.fireOrange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cta,
                                  style: TextStyle(
                                    color: Colors.grey[200],
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _generateCtas,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.fireOrange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Regenerar',
                        style: TextStyle(color: AppColors.fireOrange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyCtas,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fireOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Aplicar ao Roteiro',
                        style: TextStyle(color: Colors.white),
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

  Future<void> _generateCtas() async {
    setState(() {
      _isGenerating = true;
      _generatedCtas.clear();
    });

    try {
      final scriptState = ref.read(scriptGenerationProvider);
      if (scriptState.result?.scriptText == null) {
        throw Exception('Nenhum roteiro encontrado para gerar CTAs');
      }

      // Chama o método do provider para gerar CTAs
      final ctas = await ref.read(scriptGenerationProvider.notifier)
          .generateCtas(scriptState.result!.scriptText, _selectedPosition);

      setState(() {
        _generatedCtas = ctas;
      });
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

  void _applyCtas() {
    try {
      ref.read(scriptGenerationProvider.notifier)
          .applyCtasToScript(_generatedCtas, _selectedPosition);
      
      if (mounted) {
        // Mostra onde os CTAs foram inseridos
        final positionText = _positionLabels[_selectedPosition] ?? _selectedPosition;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_generatedCtas.length} CTA(s) aplicado(s) na posição: $positionText'),
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