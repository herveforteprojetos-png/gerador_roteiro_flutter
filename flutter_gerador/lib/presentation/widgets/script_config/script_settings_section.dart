import 'package:flutter/material.dart';
import 'package:flutter_gerador/core/constants/app_colors.dart';
import 'package:flutter_gerador/core/constants/app_strings.dart';

class ScriptSettingsSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contextController;
  final String measureType;
  final ValueChanged<String?> onMeasureTypeChanged;
  final int quantity;
  final TextEditingController quantityController;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<String> onQuantityFieldChanged;
  final String language;
  final ValueChanged<String?> onLanguageChanged;
  final String perspective;
  final ValueChanged<String?> onPerspectiveChanged;
  final bool includeCallToAction;
  final ValueChanged<bool?> onIncludeCallToActionChanged;
  final VoidCallback? onGenerateContext;

  const ScriptSettingsSection({
    super.key,
    required this.titleController,
    required this.contextController,
    required this.measureType,
    required this.onMeasureTypeChanged,
    required this.quantity,
    required this.quantityController,
    required this.onQuantityChanged,
    required this.onQuantityFieldChanged,
    required this.language,
    required this.onLanguageChanged,
    required this.perspective,
    required this.onPerspectiveChanged,
    required this.includeCallToAction,
    required this.onIncludeCallToActionChanged,
    this.onGenerateContext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.scriptTitleLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.title),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.contextLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: contextController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Descreva o enredo, personagens principais, cenário...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onGenerateContext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fireOrange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Icon(Icons.auto_awesome, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.measureLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: measureType,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'palavras', child: Text('Palavras')),
                    DropdownMenuItem(value: 'caracteres', child: Text('Caracteres')),
                  ],
                  onChanged: onMeasureTypeChanged,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.quantityLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onQuantityFieldChanged,
                  ),
                ),
                Slider(
                  value: quantity.toDouble(),
                  min: measureType == 'palavras' ? 500 : 2000,
                  max: measureType == 'palavras' ? 14000 : 100000,
                  divisions: 40,
                  activeColor: AppColors.fireOrange,
                  onChanged: onQuantityChanged,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.languageLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: language,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'de', child: Text('Alemão')),
                    DropdownMenuItem(value: 'bg', child: Text('Búlgaro')),
                    DropdownMenuItem(value: 'es-mx', child: Text('Espanhol Mexicano')),
                    DropdownMenuItem(value: 'fr', child: Text('Francês')),
                    DropdownMenuItem(value: 'en', child: Text('Inglês')),
                    DropdownMenuItem(value: 'it', child: Text('Italiano')),
                    DropdownMenuItem(value: 'pl', child: Text('Polonês')),
                    DropdownMenuItem(value: 'pt', child: Text('Português')),
                    DropdownMenuItem(value: 'tr', child: Text('Turco')),
                    DropdownMenuItem(value: 'ro', child: Text('Romeno')),
                  ],
                  onChanged: onLanguageChanged,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perspectiva Narrativa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: perspective,
                  decoration: const InputDecoration(
                    isDense: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'terceira',
                      child: Text('Terceira Pessoa', style: TextStyle(fontSize: 16)),
                    ),
                    DropdownMenuItem(
                      value: 'primeira_homem_idoso',
                      child: Text('Primeira pessoa Homem idoso', style: TextStyle(fontSize: 16)),
                    ),
                    DropdownMenuItem(
                      value: 'primeira_homem_jovem',
                      child: Text('Primeira pessoa Homem Jovem de 25 a 40', style: TextStyle(fontSize: 16)),
                    ),
                    DropdownMenuItem(
                      value: 'primeira_mulher_idosa',
                      child: Text('Primeira pessoa Mulher Idosa', style: TextStyle(fontSize: 16)),
                    ),
                    DropdownMenuItem(
                      value: 'primeira_mulher_jovem',
                      child: Text('Primeira pessoa Mulher jovem de 25 a 40', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                  onChanged: onPerspectiveChanged,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 180,
            child: CheckboxListTile(
              title: Text(AppStrings.callToActionLabel),
              value: includeCallToAction,
              activeColor: AppColors.fireOrange,
              onChanged: onIncludeCallToActionChanged,
            ),
          ),
        ],
      ),
    );
  }
}
