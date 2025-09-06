import 'package:flutter/material.dart';
import 'package:flutter_gerador/core/theme/app_colors.dart';
import 'package:flutter_gerador/data/services/srt_service.dart';

class SrtGeneratorDialog extends StatefulWidget {
  final TextEditingController scriptController;
  final Function(String) onGenerateSrt;

  const SrtGeneratorDialog({
    super.key, 
    required this.scriptController, 
    required this.onGenerateSrt
  });

  @override
  State<SrtGeneratorDialog> createState() => _SrtGeneratorDialogState();
}

class _SrtGeneratorDialogState extends State<SrtGeneratorDialog> {
  int wordsPerMinute = 160;
  int maxCharactersPerSubtitle = 80;
  int maxLinesPerSubtitle = 2;
  double minDisplayTime = 1.5;
  double maxDisplayTime = 7.0;
  double gapBetweenSubtitles = 0.3;
  bool isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Row(
        children: [
          Icon(Icons.subtitles, color: AppColors.fireOrange),
          const SizedBox(width: 8),
          const Text('Configurações SRT', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Velocidade de fala
              _buildConfigSlider(
                'Velocidade de Fala (palavras/min)',
                wordsPerMinute.toDouble(),
                100, 300,
                (value) => setState(() => wordsPerMinute = value.round()),
                '$wordsPerMinute ppm',
              ),
              const SizedBox(height: 16),
              
              // Caracteres por legenda
              _buildConfigSlider(
                'Máximo de Caracteres por Legenda',
                maxCharactersPerSubtitle.toDouble(),
                40, 120,
                (value) => setState(() => maxCharactersPerSubtitle = value.round()),
                '$maxCharactersPerSubtitle chars',
              ),
              const SizedBox(height: 16),
              
              // Linhas por legenda
              _buildConfigSlider(
                'Máximo de Linhas por Legenda',
                maxLinesPerSubtitle.toDouble(),
                1, 3,
                (value) => setState(() => maxLinesPerSubtitle = value.round()),
                '$maxLinesPerSubtitle linhas',
              ),
              const SizedBox(height: 16),
              
              // Tempo mínimo de exibição
              _buildConfigSlider(
                'Tempo Mínimo de Exibição (seg)',
                minDisplayTime,
                0.5, 5.0,
                (value) => setState(() => minDisplayTime = value),
                '${minDisplayTime.toStringAsFixed(1)}s',
              ),
              const SizedBox(height: 16),
              
              // Tempo máximo de exibição
              _buildConfigSlider(
                'Tempo Máximo de Exibição (seg)',
                maxDisplayTime,
                3.0, 15.0,
                (value) => setState(() => maxDisplayTime = value),
                '${maxDisplayTime.toStringAsFixed(1)}s',
              ),
              const SizedBox(height: 16),
              
              // Intervalo entre legendas
              _buildConfigSlider(
                'Intervalo Entre Legendas (seg)',
                gapBetweenSubtitles,
                0.0, 2.0,
                (value) => setState(() => gapBetweenSubtitles = value),
                '${gapBetweenSubtitles.toStringAsFixed(1)}s',
              ),
              const SizedBox(height: 24),
              
              // Preview das configurações
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.fireOrange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview das Configurações:',
                      style: TextStyle(
                        color: AppColors.fireOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Velocidade: $wordsPerMinute palavras/min\n'
                      '• Máx. chars: $maxCharactersPerSubtitle\n'
                      '• Máx. linhas: $maxLinesPerSubtitle\n'
                      '• Tempo: ${minDisplayTime.toStringAsFixed(1)}s - ${maxDisplayTime.toStringAsFixed(1)}s\n'
                      '• Intervalo: ${gapBetweenSubtitles.toStringAsFixed(1)}s',
                      style: TextStyle(color: Colors.grey[300], fontSize: 12),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            // Restaurar configurações padrão
            setState(() {
              wordsPerMinute = 160;
              maxCharactersPerSubtitle = 80;
              maxLinesPerSubtitle = 2;
              minDisplayTime = 1.5;
              maxDisplayTime = 7.0;
              gapBetweenSubtitles = 0.3;
            });
          },
          child: const Text('Restaurar Padrão'),
        ),
        ElevatedButton(
          onPressed: isGenerating ? null : _generateSrt,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.fireOrange,
          ),
          child: isGenerating 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Gerar SRT'),
        ),
      ],
    );
  }

  Widget _buildConfigSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String displayValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.fireOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  color: AppColors.fireOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / (max > 10 ? 10 : 0.1)).round(),
          activeColor: AppColors.fireOrange,
          inactiveColor: Colors.grey[600],
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _generateSrt() async {
    if (widget.scriptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um roteiro primeiro')),
      );
      return;
    }

    setState(() => isGenerating = true);

    try {
      final srtContent = SrtService.generateSrt(
        widget.scriptController.text,
        wordsPerMinute: wordsPerMinute,
        maxCharactersPerSubtitle: maxCharactersPerSubtitle,
        maxLinesPerSubtitle: maxLinesPerSubtitle,
        minDisplayTime: minDisplayTime,
        maxDisplayTime: maxDisplayTime,
        gapBetweenSubtitles: gapBetweenSubtitles,
      );

      widget.onGenerateSrt(srtContent);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar SRT: $e')),
      );
    } finally {
      setState(() => isGenerating = false);
    }
  }
}
