
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter_gerador/core/constants/app_colors.dart';
import 'package:flutter_gerador/presentation/widgets/extra_tools/srt_generator_dialog.dart';
import 'package:flutter_gerador/presentation/widgets/extra_tools/character_prompt_dialog.dart';
import 'package:flutter_gerador/presentation/widgets/extra_tools/scenario_prompt_dialog.dart';

class ScriptResultView extends StatelessWidget {
  final int wordCount;
  final int charCount;
  final int paragraphCount;
  final int readingTime;
  final TextEditingController scriptController;
  final VoidCallback? onDownloadTxt;
  final VoidCallback? onDownloadFormatted;
  final BuildContext context;
  final VoidCallback onShowExtraTools;

  const ScriptResultView({
    super.key,
    required this.wordCount,
    required this.charCount,
    required this.paragraphCount,
    required this.readingTime,
    required this.scriptController,
    required this.onDownloadTxt,
    required this.onDownloadFormatted,
    required this.context,
    required this.onShowExtraTools,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          child: Row(
            children: [
              Expanded(child: MetricCard(title: 'Palavras', value: '$wordCount')),
              Expanded(child: MetricCard(title: 'Caracteres', value: '$charCount')),
              Expanded(child: MetricCard(title: 'Parágrafos', value: '$paragraphCount')),
              Expanded(child: MetricCard(title: 'Tempo Leitura', value: '${readingTime}min')),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.fireOrange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: scriptController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'Seu roteiro aparecerá aqui...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final text = scriptController.text;
                  final directory = await getApplicationDocumentsDirectory();
                  final file = File('${directory.path}/roteiro.txt');
                  await file.writeAsString(text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arquivo TXT salvo!')));
                },
                icon: const Icon(Icons.download),
                label: const Text('Download TXT'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.fireOrange),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final pdf = pw.Document();
                  pdf.addPage(
                    pw.Page(
                      build: (pw.Context context) => pw.Container(
                        child: pw.Text(scriptController.text),
                      ),
                    ),
                  );
                  final directory = await getApplicationDocumentsDirectory();
                  final file = File('${directory.path}/roteiro.pdf');
                  await file.writeAsBytes(await pdf.save());
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arquivo PDF salvo!')));
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.fireOrange),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return SimpleDialog(
                        title: const Text('Ferramentas Extras'),
                        children: [
                          SimpleDialogOption(
                            child: const Text('Gerar SRT'),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              showDialog(
                                context: context,
                                builder: (_) => SrtGeneratorDialog(
                                  scriptController: scriptController,
                                  onGenerateSrt: (srtContent) {
                                    // Criar um novo dialog para mostrar o resultado SRT
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('SRT Gerado'),
                                        content: SizedBox(
                                          width: 500,
                                          height: 400,
                                          child: SingleChildScrollView(
                                            child: SelectableText(
                                              srtContent,
                                              style: const TextStyle(fontFamily: 'monospace'),
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Fechar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              // Copiar para clipboard
                                              await Clipboard.setData(ClipboardData(text: srtContent));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('SRT copiado para a área de transferência!')),
                                              );
                                            },
                                            child: const Text('Copiar'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SimpleDialogOption(
                            child: const Text('Prompt de Personagem'),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              showDialog(
                                context: context,
                                builder: (_) => CharacterPromptDialog(
                                  characterController: TextEditingController(),
                                  onGeneratePrompt: () {
                                    // TODO: Implementar prompt de personagem
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            },
                          ),
                          SimpleDialogOption(
                            child: const Text('Prompt de Cenário'),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              showDialog(
                                context: context,
                                builder: (_) => ScenarioPromptDialog(
                                  scenarioController: TextEditingController(),
                                  onGeneratePrompt: () {
                                    // TODO: Implementar prompt de cenário
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.build),
                label: const Text('Ferramentas Extras'),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.fireOrange)),
              ),
            ],
          ),
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
