import 'package:flutter/material.dart';

class ScenarioPromptDialog extends StatelessWidget {
  final TextEditingController scenarioController;
  final VoidCallback onGeneratePrompt;

  const ScenarioPromptDialog({
    super.key,
    required this.scenarioController,
    required this.onGeneratePrompt,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Prompt de Cenário'),
      content: TextField(
        controller: scenarioController,
        decoration: const InputDecoration(
          labelText: 'Descrição do cenário',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: onGeneratePrompt,
          child: const Text('Gerar Prompt'),
        ),
      ],
    );
  }
}
