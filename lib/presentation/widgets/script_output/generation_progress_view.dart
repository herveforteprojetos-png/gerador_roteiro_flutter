import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class GenerationProgressView extends StatelessWidget {
  final int progress;
  final int generatedBlocks;
  final int wordCount;
  final String currentPhase;
  final List<String> logs;
  final VoidCallback onCancel;

  const GenerationProgressView({
    super.key,
    required this.progress,
    required this.generatedBlocks,
    required this.wordCount,
    required this.currentPhase,
    required this.logs,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 400,
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.fireOrange),
              ),
              const SizedBox(height: 8),
              Text('$progress% Concluído', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MetricCard(title: 'Blocos Gerados', value: '$generatedBlocks'),
            const SizedBox(width: 16),
            MetricCard(title: 'Palavras', value: '$wordCount'),
            const SizedBox(width: 16),
            MetricCard(title: 'Fase', value: currentPhase),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          width: 600,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.fireOrange),
          ),
          child: ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  logs[index],
                  style: TextStyle(
                    color: Colors.green[400],
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            foregroundColor: Colors.red,
          ),
          child: const Text('Cancelar Geração'),
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  const MetricCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
