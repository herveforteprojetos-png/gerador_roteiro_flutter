import 'package:flutter/material.dart';
import 'package:flutter_gerador/core/utils/color_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workspace_sessions_provider.dart';
import '../providers/script_generation_multi_provider.dart';
import '../widgets/workspace/workspace_tabs_widget.dart';
import '../widgets/tools/extra_tools_panel.dart';
import '../../core/theme/app_colors.dart';

class MultiWorkspaceHomePage extends ConsumerStatefulWidget {
  const MultiWorkspaceHomePage({super.key});

  @override
  ConsumerState<MultiWorkspaceHomePage> createState() => _MultiWorkspaceHomePageState();
}

class _MultiWorkspaceHomePageState extends ConsumerState<MultiWorkspaceHomePage> {
  
  @override
  Widget build(BuildContext context) {
  ref.watch(workspaceSessionsProvider); // watch for rebuilds
    final workspaceNotifier = ref.read(workspaceSessionsProvider.notifier);
    final activeSession = workspaceNotifier.activeSession;
    
    if (activeSession == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Column(
        children: [
          // Barra de abas dos workspaces
          const WorkspaceTabsWidget(),
          
          // Conteúdo do workspace ativo
          Expanded(
            child: _buildWorkspaceContent(activeSession),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceContent(activeSession) {
    final generationState = ref.watch(scriptGenerationMultiProvider);
    final sessionGenerating = generationState.isGenerating(activeSession.id);
    final sessionResult = generationState.getResult(activeSession.id);
    final sessionError = generationState.getError(activeSession.id);
    
    return Row(
      children: [
        // Painel lateral de configuração (específico para o workspace ativo)
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: AppColors.darkBackground,
            border: Border(
              right: BorderSide(color: AppColors.fireOrange.o(0.3)),
            ),
          ),
          child: _buildWorkspaceConfigPanel(activeSession),
        ),
        
        // Área principal de conteúdo
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Cabeçalho do workspace ativo
                _buildWorkspaceHeader(activeSession),
                
                const SizedBox(height: 24),
                
                // Conteúdo principal baseado no estado
                Expanded(
                  child: _buildMainContent(activeSession, sessionGenerating, sessionResult, sessionError),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceConfigPanel(activeSession) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do painel
          Row(
            children: [
              Text(
                activeSession.statusIcon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activeSession.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            activeSession.statusText,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Formulário de configuração específico para esta sessão
          Expanded(
            child: _buildSessionConfigForm(activeSession),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionConfigForm(activeSession) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chave da API
          _buildSectionTitle('Chave da API Gemini'),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: activeSession.config.apiKey),
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Cole sua chave da API aqui...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.black.o(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange.o(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange),
              ),
              prefixIcon: Icon(Icons.key, color: AppColors.fireOrange),
            ),
            onChanged: (value) => _updateSessionConfig(activeSession, apiKey: value),
          ),
          
          const SizedBox(height: 20),
          
          // Modelo
          _buildSectionTitle('Modelo de IA'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: activeSession.config.model,
            style: const TextStyle(color: Colors.white),
            dropdownColor: AppColors.darkBackground,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.o(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange.o(0.5)),
              ),
            ),
            items: [
              'gemini-1.5-pro',
              'gemini-1.5-flash',
              'gemini-1.0-pro',
            ].map((model) => DropdownMenuItem(
              value: model,
              child: Text(model),
            )).toList(),
            onChanged: (value) => _updateSessionConfig(activeSession, model: value ?? activeSession.config.model),
          ),
          
          const SizedBox(height: 20),
          
          // Título
          _buildSectionTitle('Título do Roteiro'),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: activeSession.config.title),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ex: Aventura no Espaço',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.black.o(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange.o(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange),
              ),
            ),
            onChanged: (value) => _updateSessionConfig(activeSession, title: value),
          ),
          
          const SizedBox(height: 20),
          
          // Contexto
          _buildSectionTitle('Contexto da História'),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: activeSession.config.context),
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Descreva o contexto, personagens, ambiente...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.black.o(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange.o(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.fireOrange),
              ),
            ),
            onChanged: (value) => _updateSessionConfig(activeSession, context: value),
          ),
          
          const SizedBox(height: 24),
          
          // Botão Gerar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: activeSession.isConfigured ? () => _generateScript(activeSession) : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Gerar Roteiro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.fireOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.fireOrange,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildWorkspaceHeader(activeSession) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
  color: Colors.black.o(0.2),
        borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppColors.fireOrange.o(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.fireOrange.o(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.fireOrange.o(0.5)),
            ),
            child: Icon(
              Icons.workspace_premium,
              color: AppColors.fireOrange,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeSession.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Workspace ativo • ${activeSession.statusText}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          Text(
            activeSession.statusIcon,
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(activeSession, bool sessionGenerating, GenerationResult? sessionResult, String? sessionError) {
    if (sessionGenerating) {
      return _buildGenerationProgress(activeSession);
    }
    
    if (sessionResult != null) {
      return _buildResultView(sessionResult);
    }
    
    if (sessionError != null) {
      return _buildErrorView(sessionError);
    }
    
    return _buildWelcomeView(activeSession);
  }

  Widget _buildGenerationProgress(activeSession) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.fireOrange.o(0.1),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.fireOrange.o(0.3)),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.fireOrange),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Gerando roteiro...',
            style: TextStyle(
              color: AppColors.fireOrange,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Workspace: ${activeSession.name}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.o(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.fireOrange.o(0.2)),
            ),
            child: Text(
              'Usando modelo: ${activeSession.config.model}',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.o(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.o(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro na Geração',
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.red[200],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView(activeSession) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            color: AppColors.fireOrange,
            size: 64,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Bem-vindo ao ${activeSession.name}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            activeSession.isConfigured 
              ? 'Tudo configurado! Clique em "Gerar Roteiro" para começar.'
              : 'Configure sua chave API e preencha os campos para começar.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScriptMetrics(String scriptText) {
    final characterCount = scriptText.length;
    final wordCount = scriptText.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
  color: AppColors.fireOrange.o(0.1),
  border: Border.all(color: AppColors.fireOrange.o(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetricCard(
            icon: Icons.text_fields,
            label: 'Caracteres',
            value: characterCount.toString(),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.fireOrange.o(0.3),
          ),
          _buildMetricCard(
            icon: Icons.article,
            label: 'Palavras',
            value: wordCount.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.fireOrange,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: AppColors.fireOrange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.o(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _updateSessionConfig(activeSession, {
    String? apiKey,
    String? model,
    String? title,
    String? context,
    String? genre,
  }) {
    final updatedConfig = activeSession.config.copyWith(
      apiKey: apiKey,
      model: model,
      title: title,
      context: context,
      genre: genre,
    );
    
    ref.read(workspaceSessionsProvider.notifier).updateSessionConfig(
      activeSession.id,
      updatedConfig,
    );
  }

  void _generateScript(activeSession) {
    ref.read(scriptGenerationMultiProvider.notifier).generateScript(
      activeSession.id,
      activeSession.config,
    );
  }

  Widget _buildResultView(GenerationResult result) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Métricas do roteiro
          _buildScriptMetrics(result.scriptText!),
          
          const SizedBox(height: 24),
          
          // Texto do roteiro
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.o(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.fireOrange.o(0.3)),
            ),
            child: SelectableText(
              result.scriptText!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Ferramentas extras
          ExtraToolsPanel(scriptText: result.scriptText!),
        ],
      ),
    );
  }
}
