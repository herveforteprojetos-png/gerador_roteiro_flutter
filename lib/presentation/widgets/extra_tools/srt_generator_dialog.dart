import 'package:flutter/material.dart';

class SrtGeneratorDialog extends StatelessWidget {
  final TextEditingController scriptController;
  final VoidCallback onGenerateSrt;

  const SrtGeneratorDialog({super.key, required this.scriptController, required this.onGenerateSrt});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gerar SRT'),
      content: TextField(
        controller: scriptController,
        maxLines: 8,
        decoration: const InputDecoration(
          labelText: 'Texto do roteiro',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: onGenerateSrt,
          child: const Text('Gerar SRT'),
        ),
      ],
    );
  }
}
