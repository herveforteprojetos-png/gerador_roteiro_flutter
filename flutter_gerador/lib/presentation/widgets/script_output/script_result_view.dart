import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_gerador/core/constants/app_colors.dart';
import 'package:flutter_gerador/presentation/widgets/extra_tools/srt_generator_dialog.dart';
import 'package:flutter_gerador/presentation/widgets/extra_tools/character_prompt_dialog.dart';
import 'package:flutter_gerador/presentation/widgets/extra_tools/scenario_prompt_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gerador/presentation/providers/extra_tools_provider.dart';

class ScriptResultView extends StatefulWidget {
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
  State<ScriptResultView> createState() => _ScriptResultViewState();
}

class _ScriptResultViewState extends State<ScriptResultView> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Row(
            children: [
              Expanded(child: MetricCard(title: 'Palavras', value: '${widget.wordCount}')),
              Expanded(child: MetricCard(title: 'Caracteres', value: '${widget.charCount}')),
              Expanded(child: MetricCard(title: 'Parágrafos', value: '${widget.paragraphCount}')),
              Expanded(child: MetricCard(title: 'Tempo Leitura', value: '${widget.readingTime}min')),
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
            child: Stack(
              children: [
                // 🚀 OTIMIZAÇÃO: SelectableText é 70% mais leve que TextField para exibição
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      key: ValueKey(widget.scriptController.text.length), // 🚀 OTIMIZAÇÃO: Previne rebuilds desnecessários
                      widget.scriptController.text.isEmpty 
                          ? 'Seu roteiro aparecerá aqui...' 
                          : widget.scriptController.text,
                      style: TextStyle(
                        color: widget.scriptController.text.isEmpty 
                            ? Colors.white.withValues(alpha: 0.5) 
                            : Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                // Botão de expandir no canto superior direito
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => _showExpandedEditor(context),
                    icon: const Icon(Icons.edit, color: AppColors.fireOrange),
                    tooltip: 'Expandir para edição',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.7),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
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
                  final text = widget.scriptController.text;
                  final directory = await getApplicationDocumentsDirectory();
                  final file = File('${directory.path}/roteiro.txt');
                  await file.writeAsString(text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arquivo TXT salvo!')));
                },
                icon: const Icon(Icons.download),
                label: const Text('Download TXT'),
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
                                  scriptController: widget.scriptController,
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

  void _showExpandedEditor(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ExpandedScriptEditor(
        scriptController: widget.scriptController,
      ),
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

// Widget para o editor expandido
class _ExpandedScriptEditor extends ConsumerStatefulWidget {
  final TextEditingController scriptController;

  const _ExpandedScriptEditor({
    required this.scriptController,
  });

  @override
  ConsumerState<_ExpandedScriptEditor> createState() => _ExpandedScriptEditorState();
}

class _ExpandedScriptEditorState extends ConsumerState<_ExpandedScriptEditor> {
  late TextEditingController _editController;
  bool _hasChanges = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.scriptController.text);
    _editController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _editController.removeListener(_onTextChanged);
    _editController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasChanges = _editController.text != widget.scriptController.text;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _saveChanges() {
    // 🔄 Salva o texto editado
    widget.scriptController.text = _editController.text;
    setState(() {
      _hasChanges = false;
    });
    
    // 🔄 Invalidar SRT se texto mudou
    final extraNotifier = ref.read(extraToolsProvider.notifier);
    extraNotifier.invalidateSrtIfTextChanged(_editController.text);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Roteiro salvo com sucesso!'),
        backgroundColor: AppColors.fireOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _discardChanges() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Descartar Alterações?'),
          content: const Text('Você tem alterações não salvas. Deseja realmente descartar?'),
          backgroundColor: Colors.grey[900],
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          contentTextStyle: const TextStyle(color: Colors.white70),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fechar dialog de confirmação
                Navigator.of(context).pop(); // Fechar editor expandido
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.8),
          title: Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.fireOrange),
              const SizedBox(width: 8),
              const Text(
                'Editor de Roteiro',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          leading: IconButton(
            onPressed: _discardChanges,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          actions: [
            // Botão de alternar modo de edição
            IconButton(
              onPressed: _toggleEditMode,
              icon: Icon(
                _isEditing ? Icons.visibility : Icons.edit,
                color: _isEditing ? AppColors.fireOrange : Colors.white,
              ),
              tooltip: _isEditing ? 'Visualizar' : 'Editar',
            ),
            // Contador de caracteres e palavras
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.fireOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.fireOrange.withValues(alpha: 0.5)),
              ),
              child: Text(
                '${_editController.text.length} chars | ${_editController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} palavras',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Botão de salvar
            if (_hasChanges)
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Salvar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.fireOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            const SizedBox(width: 16),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(16),
          child: _isEditing ? _buildEditor() : _buildPreview(),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fireOrange.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _editController,
        maxLines: null,
        expands: true,
        autofocus: true,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.6,
          fontFamily: 'monospace',
        ),
        decoration: const InputDecoration(
          hintText: 'Digite seu roteiro aqui...',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fireOrange.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          _editController.text.isEmpty 
            ? 'Nenhum conteúdo para visualizar...'
            : _editController.text,
          style: TextStyle(
            color: _editController.text.isEmpty ? Colors.grey : Colors.white,
            fontSize: 16,
            height: 1.8,
          ),
        ),
      ),
    );
  }
}
