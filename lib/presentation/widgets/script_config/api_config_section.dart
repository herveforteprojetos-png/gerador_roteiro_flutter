import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class ApiConfigSection extends StatelessWidget {
  final TextEditingController apiKeyController;
  final String selectedModel;
  final ValueChanged<String?> onModelChanged;

  const ApiConfigSection({
    super.key,
    required this.apiKeyController,
    required this.selectedModel,
    required this.onModelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: apiKeyController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: AppStrings.apiKeyLabel,
            prefixIcon: Icon(Icons.key, color: AppColors.fireOrange),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedModel,
          decoration: InputDecoration(labelText: AppStrings.modelLabel),
          items: const [
            DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('Gemini 1.5 Pro')),
            DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('Gemini 1.5 Flash')),
          ],
          onChanged: onModelChanged,
        ),
      ],
    );
  }
}
