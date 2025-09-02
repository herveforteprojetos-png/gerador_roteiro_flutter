import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class ScriptSettingsSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contextController;
  final String measureType;
  final ValueChanged<String?> onMeasureTypeChanged;
  final int quantity;
  final ValueChanged<double> onQuantityChanged;
  final String language;
  final ValueChanged<String?> onLanguageChanged;
  final bool includeCallToAction;
  final ValueChanged<bool?> onIncludeCallToActionChanged;

  const ScriptSettingsSection({
    super.key,
    required this.titleController,
    required this.contextController,
    required this.measureType,
    required this.onMeasureTypeChanged,
    required this.quantity,
    required this.onQuantityChanged,
    required this.language,
    required this.onLanguageChanged,
    required this.includeCallToAction,
    required this.onIncludeCallToActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: AppStrings.scriptTitleLabel,
            prefixIcon: const Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: contextController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: AppStrings.contextLabel,
            hintText: 'Descreva o enredo, personagens principais, cenário...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: measureType,
          decoration: InputDecoration(labelText: AppStrings.measureLabel),
          items: const [
            DropdownMenuItem(value: 'palavras', child: Text('Palavras')),
            DropdownMenuItem(value: 'caracteres', child: Text('Caracteres')),
          ],
          onChanged: onMeasureTypeChanged,
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppStrings.quantityLabel}: $quantity'),
            Slider(
              value: quantity.toDouble(),
              min: measureType == 'palavras' ? 500 : 2000,
              max: measureType == 'palavras' ? 5000 : 20000,
              divisions: 20,
              activeColor: AppColors.fireOrange,
              onChanged: onQuantityChanged,
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: language,
          decoration: InputDecoration(labelText: AppStrings.languageLabel),
          items: const [
            DropdownMenuItem(value: 'pt', child: Text('Português')),
            DropdownMenuItem(value: 'en', child: Text('Inglês')),
          ],
          onChanged: onLanguageChanged,
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: Text(AppStrings.callToActionLabel),
          value: includeCallToAction,
          activeColor: AppColors.fireOrange,
          onChanged: onIncludeCallToActionChanged,
        ),
      ],
    );
  }
}
