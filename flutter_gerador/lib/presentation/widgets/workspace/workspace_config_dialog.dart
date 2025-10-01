import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/workspace_config.dart';
import '../../providers/workspace_config_provider.dart';
import 'package:flutter_gerador/core/utils/color_extensions.dart';

class WorkspaceConfigDialog extends ConsumerStatefulWidget {
  final String workspaceId;
  
  const WorkspaceConfigDialog({
    super.key,
    required this.workspaceId,
  });
  
  @override
  ConsumerState<WorkspaceConfigDialog> createState() => _WorkspaceConfigDialogState();
}

class _WorkspaceConfigDialogState extends ConsumerState<WorkspaceConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _apiKeyController;
  
  bool _isLoading = false;
  bool _showApiKey = false;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _apiKeyController = TextEditingController();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(workspaceConfigProvider(widget.workspaceId));
    
    return configAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AlertDialog(
        title: const Text('Erro'),
        content: Text('Erro ao carregar configurações: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
      data: (config) {
        // Inicializa os controllers com os dados carregados
        if (_nameController.text.isEmpty) {
          _nameController.text = config.workspaceName;
          _apiKeyController.text = config.apiKey ?? '';
        }
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Color(int.parse(WorkspaceConfig.getDefaultColor(widget.workspaceId).replaceFirst('#', '0xFF'))),
              ),
              const SizedBox(width: 8),
              Text('Configurações - Workspace ${widget.workspaceId}'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do Workspace
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Workspace',
                      prefixIcon: Icon(Icons.edit),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira um nome para o workspace';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // API Key
                  TextFormField(
                    controller: _apiKeyController,
                    obscureText: !_showApiKey,
                    decoration: InputDecoration(
                      labelText: 'Chave da API Gemini',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(_showApiKey ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _showApiKey = !_showApiKey),
                      ),
                      border: const OutlineInputBorder(),
                      helperText: 'Opcional: Se não preenchida, usará a configuração global',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Informações adicionais
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.o(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.o(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Informações:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('• Cada workspace mantém suas configurações independentes', style: TextStyle(fontSize: 12)),
                        Text('• A API Key é salva localmente para uso automático', style: TextStyle(fontSize: 12)),
                        Text('• Última atualização: ${_formatDate(config.lastUpdated)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveConfig,
              child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final configNotifier = ref.read(workspaceConfigProvider(widget.workspaceId).notifier);
      final currentConfig = ref.read(workspaceConfigProvider(widget.workspaceId)).asData?.value;
      
      if (currentConfig != null) {
        final updatedConfig = currentConfig.copyWith(
          workspaceName: _nameController.text.trim(),
          apiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
          lastUpdated: DateTime.now(),
        );
        
        await configNotifier.updateConfig(updatedConfig);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Configurações salvas para ${_nameController.text}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Retorna true para indicar que houve mudanças
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
