import 'package:flutter/material.dart';
import '../../data/models/field_help.dart';

class TemplatesModal extends StatelessWidget {
  final List<ConfigTemplate> templates;
  final Function(Map<String, dynamic>) onApplyTemplate;
  
  const TemplatesModal({
    super.key,
    required this.templates,
    required this.onApplyTemplate,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  '🎯 Combinações Recomendadas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha uma configuração pronta ou inspire-se para criar a sua:',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            
            // Templates List
            Expanded(
              child: ListView.separated(
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildTemplateCard(context, templates[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTemplateCard(BuildContext context, ConfigTemplate template) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            '${template.emoji} ${template.title}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            template.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          
          // Config items
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: template.config.entries.map((entry) {
              return _buildConfigChip(entry.key, entry.value);
            }).toList(),
          ),
          
          // Result preview
          if (template.resultPreview != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📝 ${template.resultPreview}',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
          
          // Avoids
          if (template.avoids != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  '⚠️ Evita:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
                ...template.avoids!.map((avoid) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      avoid,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
          
          // Apply button
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                onApplyTemplate(template.config);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Configuração aplicada com sucesso!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Aplicar Esta Configuração'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConfigChip(String key, dynamic value) {
    String label = _getConfigLabel(key, value);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        '✅ $label',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[900],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  String _getConfigLabel(String key, dynamic value) {
    switch (key) {
      case 'perspective':
        return 'Perspectiva: ${_getPerspectiveLabel(value)}';
      case 'narrativeStyle':
        return 'Estilo: ${_getStyleLabel(value)}';
      case 'tema':
        return 'Tema: $value';
      case 'subtema':
        return 'Subtema: $value';
      case 'localizacao':
        return 'Localização: $value';
      case 'genre':
        return 'Tipo: ${_getGenreLabel(value)}';
      default:
        return '$key: $value';
    }
  }
  
  String _getPerspectiveLabel(String value) {
    switch (value) {
      case 'primeira_pessoa_mulher_idosa': return 'Primeira Pessoa Mulher Idosa';
      case 'primeira_pessoa_mulher_jovem': return 'Primeira Pessoa Mulher Jovem';
      case 'primeira_pessoa_homem_idoso': return 'Primeira Pessoa Homem Idoso';
      case 'primeira_pessoa_homem_jovem': return 'Primeira Pessoa Homem Jovem';
      case 'terceira_pessoa': return 'Terceira Pessoa';
      default: return value;
    }
  }
  
  String _getStyleLabel(String value) {
    switch (value) {
      case 'reflexivo_memorias': return 'Reflexivo e Memórias';
      case 'epico_periodo': return 'Épico de Época';
      case 'educativo_curioso': return 'Educativo e Curioso';
      case 'acao_rapida': return 'Ação Rápida';
      case 'lirico_poetico': return 'Lírico e Poético';
      case 'ficcional_livre': return 'Livre';
      default: return value;
    }
  }
  
  String _getGenreLabel(String value) {
    switch (value) {
      case 'western': return 'Western';
      case 'business': return 'Business';
      case 'family': return 'Family';
      default: return value;
    }
  }
}
