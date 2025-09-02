import 'package:flutter/material.dart';

class CharacterPromptDialog extends StatelessWidget {
  final TextEditingController characterController;
  final VoidCallback onGeneratePrompt;

  const CharacterPromptDialog({super.key, required this.characterController, required this.onGeneratePrompt});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Prompt de Personagem'),
      content: TextField(
        controller: characterController,
        decoration: const InputDecoration(
          labelText: 'Nome ou descrição do personagem',
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
