import 'package:flutter/material.dart';
import 'package:flutter_gerador/core/constants/app_colors.dart';
import 'package:flutter_gerador/core/constants/app_strings.dart';

class ScriptSettingsSection extends StatelessWidget {
  final TextEditingController apiKeyController;
  final String selectedModel;
  final ValueChanged<String?> onModelChanged;
  final TextEditingController titleController;
  final String selectedTema;
  final ValueChanged<String?> onTemaChanged;
  final TextEditingController localizacaoController;
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
    required this.apiKeyController,
    required this.selectedModel,
    required this.onModelChanged,
    required this.titleController,
    required this.selectedTema,
    required this.onTemaChanged,
    required this.localizacaoController,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chave da API Gemini',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: apiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.key),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modelo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedModel,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'gemini-2.5-pro', child: Text('Gemini 2.5 Pro 🏆 (Qualidade Máxima - Único Disponível)')),
                      ],
                      onChanged: onModelChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
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
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tema',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedTema,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'História',
                        'Ciência',
                        'Saúde',
                        'Tecnologia',
                        'Natureza',
                        'Mistério/Suspense',
                        'Terror/Sobrenatural',
                        'Ficção Científica',
                        'Drama/Romance',
                        'Comédia/Humor',
                        'Curiosidades',
                        'Biografias',
                        'Viagens/Lugares',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: onTemaChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Onde se passa a história:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: localizacaoController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.location_on),
                        hintText: 'Ex: Tokyo, Japão / Sertão da Bahia...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
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
                        hintText: 'Descreva o enredo...',
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
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
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
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.quantityLabel} ($quantity/${measureType == 'palavras' ? '14k' : '100k'})',
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
                      min: measureType == 'palavras' ? 500 : 1000,
                      max: measureType == 'palavras' ? 14000 : 100000,
                      divisions: measureType == 'palavras' ? 27 : 99,
                      activeColor: AppColors.fireOrange,
                      onChanged: onQuantityChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
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
                        DropdownMenuItem(value: 'ru', child: Text('Russo')),
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
                width: 160,
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
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'terceira_pessoa',
                          child: Text('Terceira Pessoa'),
                        ),
                        DropdownMenuItem(
                          value: 'primeira_pessoa_homem_idoso',
                          child: Text('1ª P. Homem Idoso'),
                        ),
                        DropdownMenuItem(
                          value: 'primeira_pessoa_homem_jovem',
                          child: Text('1ª P. Homem Jovem'),
                        ),
                        DropdownMenuItem(
                          value: 'primeira_pessoa_mulher_idosa',
                          child: Text('1ª P. Mulher Idosa'),
                        ),
                        DropdownMenuItem(
                          value: 'primeira_pessoa_mulher_jovem',
                          child: Text('1ª P. Mulher Jovem'),
                        ),
                      ],
                      onChanged: onPerspectiveChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Call-to-Action',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: includeCallToAction,
                            activeColor: AppColors.fireOrange,
                            onChanged: onIncludeCallToActionChanged,
                          ),
                          Text('Incluir CTA'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
