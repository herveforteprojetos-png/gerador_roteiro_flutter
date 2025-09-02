import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/data/services/gemini_service.dart';
import 'package:flutter_gerador/data/models/script_config.dart';
import 'package:flutter_gerador/presentation/providers/script_generation_provider.dart';
import 'package:flutter_gerador/core/constants/app_colors.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController apiKeyController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contextController = TextEditingController();
  
  String selectedModel = 'gemini-1.5-pro';
  bool _isGeneratingContext = false;

  bool get isFormValid =>
      apiKeyController.text.isNotEmpty &&
      titleController.text.isNotEmpty &&
      contextController.text.isNotEmpty;

  @override
  void dispose() {
    apiKeyController.dispose();
    titleController.dispose();
    contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(scriptGenerationProvider);
    final generationNotifier = ref.read(scriptGenerationProvider.notifier);

    void _generateScript() async {
      if (apiKeyController.text.isEmpty || apiKeyController.text.length < 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chave da API Gemini inválida ou ausente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final config = ScriptConfig(
        apiKey: apiKeyController.text,
        model: selectedModel,
        title: titleController.text,
        context: contextController.text,
        measureType: 'palavras',
        quantity: 5000,
        language: 'pt',
        perspective: 'terceira',
        includeCallToAction: false,
      );
      try {
        await generationNotifier.generateScript(config);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar roteiro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Column(
        children: [
          // HEADER HORIZONTAL FIXO NO TOPO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              border: Border(
                bottom: BorderSide(color: AppColors.fireOrange, width: 2),
              ),
            ),
            child: Row(
              children: [
                // Campo Chave da API (à esquerda)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chave da API Gemini',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.fireOrange,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: apiKeyController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Cole sua chave da API aqui...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.key, color: AppColors.fireOrange),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.fireOrange),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.fireOrange.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Dropdown Modelo (centro)
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modelo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.fireOrange,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedModel,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: AppColors.darkBackground,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.fireOrange),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.fireOrange.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'gemini-1.5-pro',
                            child: Text('Gemini 1.5 Pro'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedModel = value ?? selectedModel;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Campo Título (à direita)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Título do Roteiro',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.fireOrange,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Digite o título da sua história...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.title, color: AppColors.fireOrange),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.fireOrange),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.fireOrange.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // ÁREA PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: generationState.result != null && generationState.result!.scriptText.isNotEmpty
                  ? 
                  // ÁREA DE RESULTADO (quando gerado)
                  Column(
                    children: [
                      // Resultado do roteiro
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            border: Border.all(color: AppColors.fireOrange),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              generationState.result!.scriptText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Botão para nova geração
                      SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Reset do estado para permitir nova geração
                            generationNotifier.cancelGeneration();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.fireOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Gerar Novo Roteiro',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )
                  :
                  // TEXTAREA E BOTÃO GERAR (estado inicial)
                  Column(
                    children: [
                      // Campo Contexto (textarea grande)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contexto do Roteiro',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.fireOrange,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: TextField(
                                controller: contextController,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Descreva o enredo, personagens principais, cenário, tom da história...\n\nExemplo:\n- Gênero: Ficção científica\n- Protagonista: Jovem cientista\n- Cenário: Futuro distópico\n- Conflito: Descoberta de conspiração...',
                                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.fireOrange),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.fireOrange.withOpacity(0.5)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.fireOrange, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Botão Gerar Roteiro (centralizado)
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: generationState.isGenerating || !isFormValid ? null : _generateScript,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.fireOrange,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: generationState.isGenerating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Gerar Roteiro',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                      if (generationState.isGenerating)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: OutlinedButton(
                            onPressed: () {
                              generationNotifier.cancelGeneration();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Cancelar Geração'),
                          ),
                        ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
